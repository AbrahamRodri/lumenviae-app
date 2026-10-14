//
//  LibraryContent.swift
//  Lumen Viae
//
//  Where the Prayer Book's words and the Chant Library's catalog come
//  from. The server keeps both (`GET /api/v2/prayer-book`,
//  `GET /api/v2/chant-library`); the app ships a copy of each as its
//  starting point (`Resources/Library/`), so it opens at once and prays
//  with no signal, and keeps the newest copy the server has given it in
//  Application Support/Content.
//
//  A copy is read once, the first time the book or the library is
//  opened, and stands for the life of the app: the book's search, the
//  library's lookups and its shelves are built from it once. A newer copy
//  fetched while the app is open is kept on disk and read at the next
//  launch. A copy that does not decode, or does not hold together (an id
//  twice, a chapter naming a prayer the book lacks), is never kept, and
//  never read.
//

import Foundation

// MARK: - LibraryDocument

/// What the two documents share: the server's fingerprint and the day of
/// its last change, and a check that the content holds together
nonisolated protocol LibraryDocument: Codable, Sendable {
    var version: String? { get }
    var updatedAt: String? { get }
    /// Nil when the document holds together; otherwise what is wrong
    var problem: String? { get }
}

extension PrayerBookDocument: LibraryDocument {
    /// The topics the app names by id (`PrayerBook.layouts`, the Prayers
    /// page's Mary shelf, the Saved page's First Prayers): a book that
    /// lacks one is refused, so no page reaches for a topic that is gone
    nonisolated static let namedChapterIDs: Set<String> = [
        "first", "day", "short", "mass", "penance", "sacrament", "holy_ghost", "our_lord", "our_lady",
        "st_joseph", "saints", "seasons", "thanks", "litanies", "church", "sick", "departed", "needs",
    ]

    nonisolated var problem: String? {
        guard !prayers.isEmpty, !chapters.isEmpty else { return "empty" }
        let ids = Set(prayers.map(\.id))
        guard ids.count == prayers.count else { return "a prayer id twice" }
        let chapterIDs = Set(chapters.map(\.id))
        guard chapterIDs.count == chapters.count else { return "a chapter id twice" }
        if let missing = Self.namedChapterIDs.subtracting(chapterIDs).sorted().first {
            return "no chapter \(missing), which the app names"
        }
        for chapter in chapters {
            let named = chapter.prayerIDs + chapter.sections.flatMap(\.prayerIDs)
            if let missing = named.first(where: { !ids.contains($0) }) {
                return "\(chapter.id) names \(missing), which the book lacks"
            }
        }
        if let empty = prayers.first(where: { $0.english.isEmpty }) { return "\(empty.id) has no words" }
        return nil
    }
}

extension ChantLibraryDocument: LibraryDocument {
    nonisolated var problem: String? {
        guard !chants.isEmpty, !groups.isEmpty else { return "empty" }
        let ids = Set(chants.map(\.id))
        guard ids.count == chants.count else { return "a chant id twice" }
        let groupIDs = Set(groups.map(\.id))
        guard groupIDs.count == groups.count else { return "a group id twice" }
        for group in groups {
            if let missing = group.parts.flatMap(\.chantIDs).first(where: { !ids.contains($0) }) {
                return "\(group.id) names \(missing), which the library lacks"
            }
        }
        for chant in chants {
            guard groupIDs.contains(chant.groupID) else { return "\(chant.id) is in no known group" }
            guard Self.isFile(url: chant.audio.url, sha256: chant.audio.sha256) else {
                return "\(chant.id) has no recording"
            }
            if chant.score.contains(where: { !Self.isFile(url: $0.url, sha256: $0.sha256) }) {
                return "\(chant.id) has a score page with no file"
            }
            guard Self.isHTTPS(chant.sourceURL) else { return "\(chant.id) has no source page" }
        }
        return nil
    }

    /// A file the app may fetch: an https URL and a SHA-256 in hex
    nonisolated static func isFile(url: String?, sha256: String) -> Bool {
        guard let url, isHTTPS(url) else { return false }
        return sha256.count == 64 && sha256.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    nonisolated static func isHTTPS(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "https" && url.host?.isEmpty == false
    }
}

// MARK: - LibraryDocumentStore

/// One document's two copies: the one shipped in the app and the one
/// kept from the server
nonisolated struct LibraryDocumentStore<Document: LibraryDocument>: Sendable {
    /// "prayer_book", "chant_library": the seed's name and the kept copy's
    let name: String
    let seedURL: URL?
    let cacheURL: URL

    init(name: String, bundle: Bundle = .main, directory: URL = LibraryContent.directory) {
        self.name = name
        seedURL = bundle.url(forResource: name, withExtension: "json")
        cacheURL = directory.appendingPathComponent("\(name).json")
    }

    init(name: String, seedURL: URL?, cacheURL: URL) {
        self.name = name
        self.seedURL = seedURL
        self.cacheURL = cacheURL
    }

    /// A document read from `url`, or nil if it is missing, does not
    /// decode, or does not hold together
    static func read(_ url: URL?) -> Document? {
        guard let url, let data = try? Data(contentsOf: url),
            let document = try? JSONDecoder().decode(Document.self, from: data),
            document.problem == nil
        else { return nil }
        return document
    }

    var seed: Document? { Self.read(seedURL) }
    var kept: Document? { Self.read(cacheURL) }

    /// The copy to read: the kept one, unless the app shipped a newer one
    /// since it was kept (an update whose seed is later than the server's
    /// last copy on this phone)
    func current() -> Document? {
        let seed = self.seed
        guard let kept else { return seed }
        guard let seed else { return kept }
        return Self.isNewer(seed, than: kept) ? seed : kept
    }

    static func isNewer(_ a: Document, than b: Document) -> Bool {
        guard let first = a.updatedAt.flatMap(LibraryContent.date(from:)),
            let second = b.updatedAt.flatMap(LibraryContent.date(from:))
        else { return false }
        return first > second
    }

    /// Keeps `data` as the newest copy if it decodes and holds together,
    /// and says what it kept. A copy that fails leaves the old one.
    @discardableResult
    func keep(_ data: Data) throws -> Document {
        let document = try JSONDecoder().decode(Document.self, from: data)
        if let problem = document.problem { throw LibraryContent.Failure.invalid(name, problem) }
        try FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try LibraryDocumentCoding.encoder().encode(document).write(to: cacheURL, options: .atomic)
        LibraryContent.excludeFromBackup(cacheURL.deletingLastPathComponent())
        return document
    }
}

// MARK: - LibraryContent

nonisolated enum LibraryContent {

    enum Failure: Error, Equatable {
        case invalid(String, String)
    }

    /// Application Support/Content, kept out of the phone's backup: the
    /// server has it all
    static let directory: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Content", isDirectory: true)
    }()

    static let prayerBookStore = LibraryDocumentStore<PrayerBookDocument>(name: "prayer_book")
    static let chantLibraryStore = LibraryDocumentStore<ChantLibraryDocument>(name: "chant_library")

    /// Whether the app was launched to host the unit tests, which read
    /// the shipped copies alone: never what a simulator kept from the
    /// server
    static let hostsTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    /// The book and the library as this launch reads them. The shipped
    /// copy is checked by the tests, so the app always has one.
    static let prayerBook: PrayerBookDocument = {
        guard let document = hostsTests ? prayerBookStore.seed : prayerBookStore.current() else {
            assertionFailure("No Prayer Book: the app's prayer_book.json is missing or broken")
            return PrayerBookDocument(prayers: [], chapters: [])
        }
        return document
    }()

    static let chantLibrary: ChantLibraryDocument = {
        guard let document = hostsTests ? chantLibraryStore.seed : chantLibraryStore.current() else {
            assertionFailure("No chant library: the app's chant_library.json is missing or broken")
            return ChantLibraryDocument(groups: [], chants: [])
        }
        return document
    }()

    static func date(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    static func excludeFromBackup(_ url: URL) {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }
}

// MARK: - LibraryContentSync

/// Asks the server whether the book or the library has changed, and keeps
/// the newer copy when it has: at every launch, and on coming back to the
/// app once a day has passed since it last asked. The question is the
/// bare document (its version alone); the whole is fetched only when the
/// version differs from the copy on this phone.
@MainActor
final class LibraryContentSync {

    static let shared = LibraryContentSync()

    private let session: URLSession
    private let baseURL: String
    private let defaults: UserDefaults
    private let prayerBookStore: LibraryDocumentStore<PrayerBookDocument>
    private let chantLibraryStore: LibraryDocumentStore<ChantLibraryDocument>
    private var running: Task<Void, Never>?

    /// Told of a newer chant library kept, so its files can be fetched
    /// before the next launch reads it
    var onChantLibraryKept: ((ChantLibraryDocument) -> Void)?

    static let checkedKey = "libraryContent.lastChecked"
    static let interval: TimeInterval = 24 * 60 * 60

    init(
        session: URLSession? = nil,
        baseURL: String = APIService.baseURL,
        defaults: UserDefaults = .standard,
        prayerBookStore: LibraryDocumentStore<PrayerBookDocument> = LibraryContent.prayerBookStore,
        chantLibraryStore: LibraryDocumentStore<ChantLibraryDocument> = LibraryContent.chantLibraryStore
    ) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 20
            config.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: config)
        }
        self.baseURL = baseURL
        self.defaults = defaults
        self.prayerBookStore = prayerBookStore
        self.chantLibraryStore = chantLibraryStore
    }

    /// At launch (`force`), or on coming back once a day has passed
    func refreshIfDue(force: Bool = false, now: Date = Date()) {
        guard running == nil else { return }
        if !force, let last = defaults.object(forKey: Self.checkedKey) as? Date,
            now.timeIntervalSince(last) < Self.interval
        {
            return
        }
        running = Task { [weak self] in
            guard let self else { return }
            await self.refresh(now: now)
            self.running = nil
        }
    }

    /// Both documents, one after the other. A failure of either leaves
    /// its kept copy as it was, and is asked again next time.
    func refresh(now: Date = Date()) async {
        var allAnswered = true
        do {
            try await refresh(
                prayerBookStore, path: "prayer-book", type: "prayer_book",
                fields: "version,updated_at,prayers,chapters")
        } catch {
            allAnswered = false
        }
        do {
            if let kept = try await refresh(
                chantLibraryStore, path: "chant-library", type: "chant_library",
                fields: "version,updated_at,groups,chants")
            {
                onChantLibraryKept?(kept)
            }
        } catch {
            allAnswered = false
        }
        if allAnswered { defaults.set(now, forKey: Self.checkedKey) }
    }

    /// The newer document kept, or nil when the phone's copy is current
    @discardableResult
    func refresh<Document: LibraryDocument>(
        _ store: LibraryDocumentStore<Document>, path: String, type: String, fields: String
    ) async throws -> Document? {
        let bare = try await attributes(of: "\(baseURL)/v2/\(path)", as: Version.self)
        let onPhone = await Self.stamp(on: store)
        guard let version = bare.version, version != onPhone.version else { return nil }
        // A version this phone already fetched and refused (it did not
        // hold together) is not fetched again until the server changes it
        let refusedKey = Self.refusedKey(path)
        guard defaults.string(forKey: refusedKey) != version else { return nil }
        // A server copy no newer than the phone's (an app update shipped a
        // later one) is not fetched: it would never be read
        if let theirs = bare.updatedAt.flatMap(LibraryContent.date(from:)),
           let ours = onPhone.updatedAt.flatMap(LibraryContent.date(from:)),
           theirs <= ours {
            return nil
        }

        var components = URLComponents(string: "\(baseURL)/v2/\(path)")
        components?.queryItems = [URLQueryItem(name: "fields[\(type)]", value: fields)]
        guard let url = components?.url else { throw URLError(.badURL) }
        let data = try await body(of: url)
        do {
            let kept = try await Self.keep(data, in: store)
            defaults.removeObject(forKey: refusedKey)
            return kept
        } catch {
            // It arrived whole and would not do: not JSON, not the
            // document, or not holding together
            defaults.set(version, forKey: refusedKey)
            throw error
        }
    }

    /// Where a refused version of a document is remembered
    static func refusedKey(_ path: String) -> String { "libraryContent.refused.\(path)" }

    /// The version and date of the copy on the phone, read off the main
    /// actor: a document is up to a megabyte of JSON
    @concurrent
    nonisolated static func stamp<Document: LibraryDocument>(
        on store: LibraryDocumentStore<Document>
    ) async -> (version: String?, updatedAt: String?) {
        let current = store.current()
        return (current?.version, current?.updatedAt)
    }

    @concurrent
    nonisolated static func keep<Document: LibraryDocument>(
        _ body: Data, in store: LibraryDocumentStore<Document>
    ) async throws -> Document {
        try store.keep(attributesData(of: body))
    }

    private struct Version: Decodable {
        let version: String?
        let updatedAt: String?

        enum CodingKeys: String, CodingKey {
            case version
            case updatedAt = "updated_at"
        }
    }

    private func attributes<T: Decodable>(of urlString: String, as: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        return try JSONDecoder().decode(T.self, from: Self.attributesData(of: try await body(of: url)))
    }

    private func body(of url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(statusCode: http.statusCode, code: nil)
        }
        return data
    }

    /// The `data.attributes` object of a JSON:API document, as bytes
    nonisolated static func attributesData(of body: Data) throws -> Data {
        guard let root = try JSONSerialization.jsonObject(with: body) as? [String: Any],
            let data = root["data"] as? [String: Any],
            let attributes = data["attributes"] as? [String: Any]
        else { throw LibraryContent.Failure.invalid("response", "no data.attributes") }
        return try JSONSerialization.data(withJSONObject: attributes)
    }
}
