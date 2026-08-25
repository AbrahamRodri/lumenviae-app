//
//  LibraryService.swift
//  Lumen Viae
//
//  Fetching and caching for the Spiritual Reading shelf. Its own
//  client, deliberately apart from APIService, for the same reason the
//  missal's is: Project Gutenberg and LibriVox are third parties, and
//  an outage of theirs must never look like a Lumen Viae failure.
//
//  Nothing is bundled. A book's text is fetched the first time it is
//  opened, cut into chapters on device, and the parsed result cached
//  in Application Support/Library (excluded from backup, versioned
//  filenames) — so a book once opened reads without a signal, and a
//  book never opened costs nothing.
//

import Foundation

// MARK: - LibraryError

enum LibraryError: LocalizedError {
    /// The text could not be fetched — a connection, a timeout, a 404
    case unreachable

    /// The text arrived but this edition could no longer be cut into
    /// chapters. Retrying re-downloads the whole book to fail the same
    /// way, so the two are kept apart: only one of them is worth a
    /// second attempt, and only one of them is the reader's network.
    case unreadable

    var title: String {
        switch self {
        case .unreachable: "Couldn't reach the library"
        case .unreadable: "This edition can't be opened"
        }
    }

    var detail: String {
        switch self {
        case .unreachable:
            "The text comes from Project Gutenberg the first time a book is opened. Check your connection and try again."
        case .unreadable:
            "Project Gutenberg's edition of this book has changed shape, so it can't be cut into chapters. It will return in a coming update."
        }
    }

    /// Whether trying again can change the answer.
    var isRetryable: Bool { self == .unreachable }

    var errorDescription: String? { detail }
}

// MARK: - LibraryService

final class LibraryService {

    static let shared = LibraryService()

    /// The book most recently read, kept so stepping chapters and
    /// popping back to the shelf don't re-read the disk. Only one: a
    /// parsed Imitation is 2,000-odd paragraph strings, and holding
    /// every book opened this session would keep the whole shelf
    /// resident behind a prayer screen that wants the memory.
    private var books: [String: LibraryBook] = [:]

    /// LibriVox track lists already loaded this session — small enough
    /// to keep for all four books.
    private var trackLists: [String: [LibriVoxSection]] = [:]

    /// Fetches in flight, so two openings of one book share a download
    /// rather than racing each other through Gutenberg's throttle.
    private var inFlightBooks: [String: Task<LibraryBook, Error>] = [:]
    private var inFlightTracks: [String: Task<[LibriVoxSection], Error>] = [:]

    /// Cache-parse version, carried in every filename so a change to
    /// the parsed shape — or a fixed parse — can never be read as the
    /// old one. Per-edition changes ride in `cacheKey` below rather than
    /// here: correcting one book's cutting rules must invalidate that
    /// book without discarding the other three.
    private static let cacheVersion = "v3"

    private let session: URLSession
    private let directory: URL

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 120
        session = URLSession(configuration: config)

        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("Library", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        pruneOrphans()
    }

    // MARK: - Cache keys

    /// A book's cache filename, carrying everything that decides what
    /// the parsed result looks like: the edition and its cutting rules,
    /// as well as the shelf-wide version. Swap a `gutenbergID` or fix a
    /// `chapterPattern` in the catalog and the old file is simply no
    /// longer asked for.
    private func cacheURL(prefix: String, info: LibraryBookInfo) -> URL {
        directory.appendingPathComponent(
            "\(prefix)_\(info.id)_\(Self.cacheVersion)_\(info.editionFingerprint).json"
        )
    }

    // MARK: - Books

    /// The parsed book: memory, then disk, then the network.
    func book(for info: LibraryBookInfo) async throws -> LibraryBook {
        if let loaded = books[info.id] { return loaded }
        if let running = inFlightBooks[info.id] { return try await running.value }

        let url = cacheURL(prefix: "book", info: info)
        let session = session
        let task = Task<LibraryBook, Error> {
            if let cached: LibraryBook = await Self.readJSON(at: url) { return cached }
            return try await Self.fetchAndParse(info: info, session: session, cacheURL: url)
        }
        inFlightBooks[info.id] = task
        defer { inFlightBooks[info.id] = nil }

        let loaded = try await task.value
        // One book resident at a time; the disk cache makes reopening
        // the previous one cheap.
        books = [info.id: loaded]
        return loaded
    }

    // MARK: - Recordings

    /// The LibriVox track list for a book — memory, disk, network.
    /// Only called for books whose catalog entry names a recording.
    func trackList(for info: LibraryBookInfo) async throws -> [LibriVoxSection] {
        guard let librivoxID = info.librivoxID else { return [] }
        if let loaded = trackLists[info.id] { return loaded }
        if let running = inFlightTracks[info.id] { return try await running.value }

        let url = cacheURL(prefix: "audio", info: info)
        let session = session
        let task = Task<[LibriVoxSection], Error> {
            if let cached: [LibriVoxSection] = await Self.readJSON(at: url) { return cached }
            return try await Self.fetchTrackList(
                librivoxID: librivoxID, session: session, cacheURL: url
            )
        }
        inFlightTracks[info.id] = task
        defer { inFlightTracks[info.id] = nil }

        let sections = try await task.value
        trackLists[info.id] = sections
        return sections
    }

    // MARK: - Pruning

    /// Sweeps cache files no current catalog entry asks for — earlier
    /// versions, retired editions, books dropped from the shelf. Without
    /// it every version bump strands its predecessor in Application
    /// Support, which iOS never purges and the user cannot reach.
    private func pruneOrphans() {
        let wanted = Set(LibraryCatalog.books.flatMap { info in
            [cacheURL(prefix: "book", info: info).lastPathComponent,
             cacheURL(prefix: "audio", info: info).lastPathComponent]
        })
        guard let files = try? FileManager.default.contentsOfDirectory(
            atPath: directory.path
        ) else { return }

        for file in files where !wanted.contains(file) {
            guard file.hasPrefix("book_") || file.hasPrefix("audio_") else { continue }
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(file))
        }
    }

    // MARK: - Off-main work

    // `nonisolated async` inherits the caller's isolation under
    // approachable concurrency, so these are `@concurrent`: a 600 KB
    // text fetch, the parse, and the disk writes must not run on the
    // main actor.

    @concurrent
    private nonisolated static func fetchAndParse(
        info: LibraryBookInfo,
        session: URLSession,
        cacheURL: URL
    ) async throws -> LibraryBook {
        let textURL = info.textURL
        let data: Data
        do {
            let (fetched, response) = try await session.data(from: textURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw LibraryError.unreachable
            }
            data = fetched
        } catch {
            throw LibraryError.unreachable
        }

        // Gutenberg serves UTF-8 today; Latin-1 is the one legacy shape
        // worth catching, because the lossy path would cache mojibake
        // rather than fail.
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? String(decoding: data, as: UTF8.self)
        let book = LibraryBookParser.parse(text: text, info: info)
        // A clean download the parser couldn't cut is not a network
        // failure, and retrying it only re-downloads the book.
        guard !book.chapters.isEmpty else { throw LibraryError.unreadable }

        if let encoded = try? JSONEncoder().encode(book) {
            try? encoded.write(to: cacheURL, options: .atomic)
        }
        return book
    }

    @concurrent
    private nonisolated static func fetchTrackList(
        librivoxID: Int,
        session: URLSession,
        cacheURL: URL
    ) async throws -> [LibriVoxSection] {
        guard let url = URL(string:
            "https://librivox.org/api/feed/audiobooks/?id=\(librivoxID)&extended=1&format=json"
        ) else { throw LibraryError.unreachable }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw LibraryError.unreachable
            }
            let decoded = try JSONDecoder().decode(LibriVoxResponse.self, from: data)
            let sections = (decoded.books.first?.sections ?? [])
                .filter { $0.listenURL?.isEmpty == false }
            // Never cache an empty ledger. LibriVox answers 200 with no
            // sections often enough, and a cached [] is read back first
            // on every launch — one bad reply would retire the book's
            // recording for good.
            guard !sections.isEmpty else { throw LibraryError.unreachable }
            if let encoded = try? JSONEncoder().encode(sections) {
                try? encoded.write(to: cacheURL, options: .atomic)
            }
            return sections
        } catch {
            throw LibraryError.unreachable
        }
    }

    @concurrent
    private nonisolated static func readJSON<T: Decodable>(at url: URL) async -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
