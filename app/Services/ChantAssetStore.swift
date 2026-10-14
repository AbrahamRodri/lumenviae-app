//
//  ChantAssetStore.swift
//  Lumen Viae
//
//  The chants' recordings and sheet music, kept on the phone. They are
//  not in the app (about 100 MB of it): the server keeps them, at
//  content-addressed URLs, and after the first launch they come down by
//  themselves on Wi-Fi, a few at a time, into Application Support/Chants,
//  out of the phone's backup. Each is checked against its SHA-256 before
//  it is kept, and named by it, so a changed file is a new file and an
//  old one is let go when no chant names it any more.
//
//  Until a recording is here, a chant streams from the server; a score
//  not yet here is fetched when its chant's page opens. A run broken off
//  (Wi-Fi lost, the app closed) keeps what it finished and takes up the
//  rest the next time the app comes to the front.
//

import CryptoKit
import Foundation

// MARK: - ChantFile

/// A file the server keeps for a chant: a recording or a page of its score
nonisolated struct ChantFile: Hashable, Sendable {
    let url: URL?
    let bytes: Int
    let sha256: String
    /// "m4a" or "lvscore"
    let fileExtension: String

    /// Its name on the phone: its hash, so the same file is kept once
    /// however many chants share it (the versicles, the collects)
    var localName: String { "\(sha256).\(fileExtension)" }
}

enum ChantAssetError: Error, Equatable {
    case noURL
    case checksumMismatch
    case badStatus(Int)
}

// MARK: - ChantAssetStore

@MainActor
@Observable
final class ChantAssetStore {

    static let shared = ChantAssetStore()

    nonisolated static let defaultDirectory: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Chants", isDirectory: true)
    }()

    let directory: URL

    /// The names of the files on the phone
    private(set) var present: Set<String>

    /// Whether a run is fetching files now
    private(set) var isFetching = false

    @ObservationIgnored private var run: Task<Void, Never>?
    @ObservationIgnored private var scoreFetches: [String: Task<URL?, Never>] = [:]
    @ObservationIgnored private let wifiSession: URLSession
    @ObservationIgnored private let anySession: URLSession

    /// How many files a run fetches at once
    static let parallel = 3

    init(directory: URL = ChantAssetStore.defaultDirectory, sessions: (wifi: URLSession, any: URLSession)? = nil) {
        self.directory = directory
        if let sessions {
            wifiSession = sessions.wifi
            anySession = sessions.any
        } else {
            let wifi = URLSessionConfiguration.default
            // Wi-Fi only: never cellular or a hotspot, nor Low Data Mode
            wifi.allowsExpensiveNetworkAccess = false
            wifi.allowsConstrainedNetworkAccess = false
            wifi.timeoutIntervalForRequest = 30
            wifiSession = URLSession(configuration: wifi)
            let any = URLSessionConfiguration.default
            any.timeoutIntervalForRequest = 30
            anySession = URLSession(configuration: any)
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        LibraryContent.excludeFromBackup(directory)
        present = Self.names(in: directory)
    }

    nonisolated static func names(in directory: URL) -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return Set(names.filter { !$0.hasSuffix(".part") })
    }

    // MARK: Reading

    /// The file on the phone, if it is here
    func localURL(for file: ChantFile) -> URL? {
        present.contains(file.localName) ? directory.appendingPathComponent(file.localName) : nil
    }

    /// What a player loads: the file on the phone, else the server's,
    /// which streams
    func playableURL(for file: ChantFile) -> URL? {
        localURL(for: file) ?? file.url
    }

    /// A chant is saved when its recording and every page of its score
    /// are on the phone
    func isSaved(_ chant: Chant) -> Bool {
        chant.files.allSatisfy { present.contains($0.localName) }
    }

    func savedCount(of chants: [Chant]) -> Int {
        chants.filter(isSaved).count
    }

    // MARK: Fetching

    /// The files of a newer library kept from the server this session,
    /// which the next launch reads: fetched now, and never let go
    @ObservationIgnored var upcoming: [ChantFile] = []

    /// Notes a newer library kept, and fetches what it needs
    func libraryKept(_ document: ChantLibraryDocument) {
        upcoming = document.chants.map { Chant(document: $0) }.flatMap(\.files)
        syncInBackground()
    }

    /// Fetches, on Wi-Fi, every file the catalog (and a newer one kept)
    /// needs that is not here, and lets go of every file neither names.
    /// A run under way is left to finish; the next call takes up what it
    /// could not.
    func syncInBackground(_ chants: [Chant]? = nil) {
        let wanted = (chants ?? ChantCatalog.all).flatMap(\.files) + upcoming
        prune(keeping: Set(wanted))
        guard run == nil else { return }
        let missing = missing(wanted)
        guard !missing.isEmpty else { return }
        run = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            _ = await self.fetch(missing, session: self.wifiSession, progress: nil)
            self.run = nil
        }
    }

    /// Fetches every file `chants` need on any network, the reader having
    /// asked for it (Settings, Save for Offline). Says how many could not
    /// be fetched.
    func fetchAll(_ chants: [Chant], progress: ((Int, Int) -> Void)? = nil) async -> Int {
        let missing = missingFiles(of: chants)
        guard !missing.isEmpty else {
            progress?(1, 1)
            return 0
        }
        return await fetch(missing, session: anySession, progress: progress)
    }

    /// One file now, on any network: a score whose page has been opened.
    /// Nil when it cannot be had (offline).
    func fetchNow(_ file: ChantFile) async -> URL? {
        if let local = localURL(for: file) { return local }
        if let pending = scoreFetches[file.localName] { return await pending.value }
        let task = Task<URL?, Never> { [directory, anySession] in
            try? await Self.download(file, session: anySession, into: directory)
        }
        scoreFetches[file.localName] = task
        let url = await task.value
        scoreFetches[file.localName] = nil
        if url != nil { present.insert(file.localName) }
        return url
    }

    func missingFiles(of chants: [Chant]) -> [ChantFile] {
        missing(chants.flatMap(\.files))
    }

    private func missing(_ files: [ChantFile]) -> [ChantFile] {
        var seen = Set<String>()
        return files.filter { file in
            file.url != nil && !present.contains(file.localName) && seen.insert(file.localName).inserted
        }
    }

    /// Files a few at a time; a run stops at the first failure of the
    /// network itself (Wi-Fi gone) rather than try each file in turn. A
    /// file that fails its checksum is let go and the run goes on.
    private func fetch(_ files: [ChantFile], session: URLSession, progress: ((Int, Int) -> Void)?) async -> Int {
        isFetching = true
        defer { isFetching = false }
        var done = 0
        var failed = 0
        var queue = files[...]
        progress?(0, files.count)
        await withTaskGroup(of: (ChantFile, Result<URL, Error>).self) { group in
            var networkDown = false
            func startNext() {
                guard !networkDown, let file = queue.popFirst() else { return }
                group.addTask { [directory] in
                    do {
                        return (file, .success(try await Self.download(file, session: session, into: directory)))
                    } catch {
                        return (file, .failure(error))
                    }
                }
            }
            for _ in 0..<Self.parallel { startNext() }
            while let (file, result) = await group.next() {
                done += 1
                switch result {
                case .success:
                    present.insert(file.localName)
                case .failure(let error):
                    failed += 1
                    if error is URLError { networkDown = true }
                }
                progress?(done, files.count)
                startNext()
            }
        }
        // Whatever was never begun counts as not fetched
        return failed + queue.count
    }

    /// Fetches one file into `directory` under its hash's name, checked
    /// against its size and SHA-256 before it is kept
    @concurrent
    nonisolated static func download(_ file: ChantFile, session: URLSession, into directory: URL) async throws -> URL {
        guard let url = file.url else { throw ChantAssetError.noURL }
        let (temporary, response) = try await session.download(from: url)
        defer { try? FileManager.default.removeItem(at: temporary) }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ChantAssetError.badStatus(http.statusCode)
        }
        return try install(temporary, as: file, into: directory)
    }

    /// Moves a file into `directory` if it is the one `file` names; a
    /// file whose hash or size is wrong is never kept
    nonisolated static func install(_ source: URL, as file: ChantFile, into directory: URL) throws -> URL {
        guard try sha256(of: source) == file.sha256.lowercased() else { throw ChantAssetError.checksumMismatch }
        let destination = directory.appendingPathComponent(file.localName)
        let staging = directory.appendingPathComponent(file.localName + ".part")
        let manager = FileManager.default
        try? manager.removeItem(at: staging)
        try manager.copyItem(at: source, to: staging)
        if manager.fileExists(atPath: destination.path) { try manager.removeItem(at: destination) }
        try manager.moveItem(at: staging, to: destination)
        return destination
    }

    /// For the tests and the tools: a file already on hand, kept as if
    /// fetched
    func adopt(_ source: URL, as file: ChantFile) throws {
        _ = try Self.install(source, as: file, into: directory)
        present.insert(file.localName)
    }

    /// Read a megabyte at a time, so a long recording is never held whole
    nonisolated static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// Lets go of every file on the phone that none of `keeping` names,
    /// and of any half-written one
    func prune(keeping: Set<ChantFile>) {
        let names = Set(keeping.map(\.localName))
        let manager = FileManager.default
        let all = (try? manager.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in all where !names.contains(name) {
            // A file being written by a run under way is left to it
            if name.hasSuffix(".part"), run != nil { continue }
            try? manager.removeItem(at: directory.appendingPathComponent(name))
        }
        present = present.intersection(names)
    }
}
