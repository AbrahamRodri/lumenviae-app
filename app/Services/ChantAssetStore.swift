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
import Network

// MARK: - ChantFile

/// A file the server keeps for a chant: a recording or a page of its score
nonisolated struct ChantFile: Hashable, Sendable {
    let url: URL?
    let bytes: Int
    let sha256: String
    /// "m4a" or "lvscore"
    let fileExtension: String
    /// What the file is, whatever its version: "audio:<chant id>",
    /// "score:<page name>". An older version kept under the same key
    /// plays until the newer is on the phone.
    var key: String = ""

    /// Its name on the phone: its hash, so the same file is kept once
    /// however many chants share it (the versicles, the collects)
    var localName: String { "\(sha256).\(fileExtension)" }
}

enum ChantAssetError: Error, Equatable {
    case noURL
    case sizeMismatch
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

    /// Counts the times the phone has come back online, so a page of
    /// sheet music that could not be had tries again
    private(set) var reconnections = 0

    @ObservationIgnored private var pathMonitor: NWPathMonitor?
    @ObservationIgnored private var wasOnline = true
    @ObservationIgnored private var wasExpensive = false

    /// The file kept for each key (`ChantFile.key`): when a newer version
    /// of a chant's recording is named, the one on the phone stays and is
    /// played until the newer has come down
    @ObservationIgnored private var keptByKey: [String: String]
    @ObservationIgnored private let defaults: UserDefaults
    static let keptKey = "chantAssets.keptByKey"

    /// A run asked for while one was under way, for these chants: begun
    /// when that one ends
    @ObservationIgnored private var runAgain: [Chant]?

    @ObservationIgnored private var run: Task<Void, Never>?
    /// One download a file on each kind of network, whoever asked for it
    /// (the Wi-Fi run, Save for Offline, a score's page): a second asker
    /// on the same session waits on the first. An asker allowed any
    /// network never waits on a Wi-Fi-only download, which may never come.
    @ObservationIgnored private var inFlight: [String: Task<URL, Error>] = [:]
    @ObservationIgnored private let wifiSession: URLSession
    @ObservationIgnored private let anySession: URLSession

    /// How many files a run fetches at once
    static let parallel = 3

    /// The chants a run without its own list fetches for: the catalog
    @ObservationIgnored private let catalog: () -> [Chant]

    init(
        directory: URL = ChantAssetStore.defaultDirectory,
        sessions: (wifi: URLSession, any: URLSession)? = nil,
        defaults: UserDefaults = .standard,
        catalog: (() -> [Chant])? = nil
    ) {
        self.directory = directory
        self.defaults = defaults
        self.catalog = catalog ?? { ChantCatalog.all }
        keptByKey = defaults.dictionary(forKey: Self.keptKey) as? [String: String] ?? [:]
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

    /// Watches the network, and when it comes back counts a reconnection
    /// and takes up the files a run could not finish. Started by the app
    /// at launch, never by the tests.
    func watchConnection() {
        guard pathMonitor == nil else { return }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            let expensive = path.isExpensive || path.isConstrained
            Task { @MainActor [weak self] in self?.connectionChanged(online: online, expensive: expensive) }
        }
        monitor.start(queue: DispatchQueue(label: "ChantAssetStore.path"))
        pathMonitor = monitor
    }

    /// Back online, a score that could not be had tries again; on Wi-Fi
    /// again (from none, or from cellular), the run takes up its files
    func connectionChanged(online: Bool, expensive: Bool = false) {
        defer {
            wasOnline = online
            wasExpensive = expensive
        }
        guard online else { return }
        if !wasOnline { reconnections += 1 }
        if !expensive, !wasOnline || wasExpensive { syncInBackground() }
    }

    nonisolated static func names(in directory: URL) -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return Set(names.filter { !$0.hasSuffix(".part") })
    }

    // MARK: Reading

    /// This very file on the phone, if it is here
    func localURL(for file: ChantFile) -> URL? {
        present.contains(file.localName) ? directory.appendingPathComponent(file.localName) : nil
    }

    /// This file on the phone, or else an older version of it still kept
    /// (a recording the server has since replaced)
    func bestLocalURL(for file: ChantFile) -> URL? {
        if let exact = localURL(for: file) { return exact }
        guard !file.key.isEmpty, let older = keptByKey[file.key], present.contains(older) else { return nil }
        return directory.appendingPathComponent(older)
    }

    /// What a player loads: the file on the phone (an older version of it
    /// if that is what is here), else the server's, which streams
    func playableURL(for file: ChantFile) -> URL? {
        bestLocalURL(for: file) ?? file.url
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
        let chants = chants ?? catalog()
        // A catalog that could not be read is no reason to let go of
        // every chant on the phone
        guard !chants.isEmpty else { return }
        let wanted = chants.flatMap(\.files) + upcoming
        prune(keeping: Set(wanted))
        guard run == nil else {
            runAgain = chants
            return
        }
        let missing = missing(wanted)
        guard !missing.isEmpty else { return }
        run = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            _ = await self.fetch(missing, session: self.wifiSession, progress: nil)
            self.run = nil
            if let next = self.runAgain {
                self.runAgain = nil
                self.syncInBackground(next)
            }
        }
    }

    /// Until the run under way, if any, has ended
    func waitForRun() async {
        while let run { await run.value }
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
    /// Offline, an older version of it kept on the phone; nil when there
    /// is none.
    func fetchNow(_ file: ChantFile) async -> URL? {
        if let url = try? await fetchOne(file, session: anySession) { return url }
        return bestLocalURL(for: file)
    }

    /// The file on the phone, fetching it first if it is not: through the
    /// one download of it under way, if there is one
    func fetchOne(_ file: ChantFile, session: URLSession) async throws -> URL {
        if let local = localURL(for: file) { return local }
        let name = file.localName
        let flight = "\(name)|\(ObjectIdentifier(session).hashValue)"
        let task: Task<URL, Error>
        if let pending = inFlight[flight] {
            task = pending
        } else {
            task = Task { [directory] in try await Self.download(file, session: session, into: directory) }
            inFlight[flight] = task
        }
        do {
            let url = try await task.value
            present.insert(name)
            remember(file)
            if inFlight[flight] == task { inFlight[flight] = nil }
            return url
        } catch {
            if inFlight[flight] == task { inFlight[flight] = nil }
            throw error
        }
    }

    /// Notes `file` as the one kept for its key, the version before it
    /// now free to go
    private func remember(_ file: ChantFile) {
        guard !file.key.isEmpty, keptByKey[file.key] != file.localName else { return }
        keptByKey[file.key] = file.localName
        defaults.set(keptByKey, forKey: Self.keptKey)
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

    /// Whether an error means the network itself is gone (offline, Wi-Fi
    /// lost, not allowed on this network) or the run was put down, when
    /// trying the next file is pointless. A timeout or a file the server
    /// would not give counts against that one file.
    nonisolated static func stopsTheRun(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        guard let error = error as? URLError else { return false }
        return [.notConnectedToInternet, .networkConnectionLost, .cancelled, .dataNotAllowed]
            .contains(error.code)
    }

    /// Files a few at a time; a run stops when the network itself is gone
    /// rather than try each file in turn. A file that fails (its hash, a
    /// timeout) is let go and the run goes on.
    private func fetch(_ files: [ChantFile], session: URLSession, progress: ((Int, Int) -> Void)?) async -> Int {
        var done = 0
        var failed = 0
        var queue = files[...]
        progress?(0, files.count)
        await withTaskGroup(of: (ChantFile, Error?).self) { group in
            var networkDown = false
            func startNext() {
                guard !networkDown, let file = queue.popFirst() else { return }
                group.addTask { [weak self] in
                    guard let self else { return (file, CancellationError()) }
                    do {
                        _ = try await self.fetchOne(file, session: session)
                        return (file, nil)
                    } catch {
                        return (file, error)
                    }
                }
            }
            for _ in 0..<Self.parallel { startNext() }
            while let (_, error) = await group.next() {
                done += 1
                if let error {
                    failed += 1
                    if Self.stopsTheRun(error) { networkDown = true }
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
    /// file whose size or hash is wrong is never kept. It is written
    /// under a name of its own (`<hash>.<uuid>.part`) and moved into
    /// place whole, so two writers never share a half-written file.
    nonisolated static func install(_ source: URL, as file: ChantFile, into directory: URL) throws -> URL {
        // Read from the disk, never a URL's cached resource values
        let size = (try? FileManager.default.attributesOfItem(atPath: source.path)[.size] as? Int) ?? -1
        guard size == file.bytes else { throw ChantAssetError.sizeMismatch }
        guard try sha256(of: source) == file.sha256.lowercased() else { throw ChantAssetError.checksumMismatch }
        let destination = directory.appendingPathComponent(file.localName)
        let staging = directory.appendingPathComponent("\(file.localName).\(UUID().uuidString).part")
        let manager = FileManager.default
        defer { try? manager.removeItem(at: staging) }
        try manager.copyItem(at: source, to: staging)
        do {
            try manager.moveItem(at: staging, to: destination)
        } catch where manager.fileExists(atPath: destination.path) {
            // Kept already by another writer: the same bytes, by its hash
        }
        return destination
    }

    /// For the tests and the tools: a file already on hand, kept as if
    /// fetched
    func adopt(_ source: URL, as file: ChantFile) throws {
        _ = try Self.install(source, as: file, into: directory)
        present.insert(file.localName)
        remember(file)
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
    /// and of any half-written one. An older version of a file `keeping`
    /// names stays until the newer is here, so a chant saved for offline
    /// never loses its recording to an update still waiting for Wi-Fi.
    func prune(keeping: Set<ChantFile>) {
        var names = Set(keeping.map(\.localName))
        for file in keeping where !present.contains(file.localName) {
            if !file.key.isEmpty, let older = keptByKey[file.key] { names.insert(older) }
        }
        let keys = Set(keeping.map(\.key))
        let forgotten = keptByKey.keys.filter { !keys.contains($0) }
        if !forgotten.isEmpty {
            for key in forgotten { keptByKey[key] = nil }
            defaults.set(keptByKey, forKey: Self.keptKey)
        }
        let manager = FileManager.default
        let all = (try? manager.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in all where !names.contains(name) {
            // A file being written is left to its writer; a half-written
            // one is let go only when nothing is being fetched
            if name.hasSuffix(".part"), !inFlight.isEmpty { continue }
            try? manager.removeItem(at: directory.appendingPathComponent(name))
        }
        present = present.intersection(names)
    }
}
