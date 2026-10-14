//
//  LibraryContentTests.swift
//  appTests
//
//  The Prayer Book's words and the chant library read from the server's
//  documents: the copies the app ships hold together and are what the
//  book and the library show; a kept copy is read before the shipped one,
//  and a broken or partial one never; the server is asked for the whole
//  only when its version differs; and the chants' files are kept only
//  when their hash is right, played from the phone once here and
//  streamed until then.
//

import CryptoKit
import Foundation
import Testing

@testable import app

// MARK: - A stub server

final class LibraryStubProtocol: URLProtocol, @unchecked Sendable {

    struct Answer {
        var status: Int = 200
        var body = Data()
        var error: URLError?
    }

    nonisolated(unsafe) static var handler: (URLRequest) -> Answer = { _ in Answer() }
    nonisolated(unsafe) static var requests: [URLRequest] = []
    private static let lock = NSLock()

    static func reset(_ handler: @escaping (URLRequest) -> Answer) {
        lock.withLock {
            self.handler = handler
            requests = []
        }
    }

    static var requested: [URLRequest] { lock.withLock { requests } }

    static var session: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LibraryStubProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let answer = Self.lock.withLock {
            Self.requests.append(request)
            return Self.handler(request)
        }
        if let error = answer.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: answer.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: answer.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private func temporaryDirectory(_ name: String = #function) throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("LibraryContentTests-\(name.filter(\.isLetter))-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func shippedBook() throws -> PrayerBookDocument {
    try #require(LibraryContent.prayerBookStore.seed)
}

private func shippedLibrary() throws -> ChantLibraryDocument {
    try #require(LibraryContent.chantLibraryStore.seed)
}

private func encoded<T: Encodable>(_ value: T) throws -> Data {
    try LibraryDocumentCoding.encoder().encode(value)
}

/// A JSON:API body with `attributes` as its resource's attributes
private func jsonAPI<T: Encodable>(_ type: String, _ attributes: T) throws -> Data {
    let object = try JSONSerialization.jsonObject(with: encoded(attributes))
    return try JSONSerialization.data(withJSONObject: ["data": ["type": type, "id": "current", "attributes": object]])
}

private func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

// MARK: - The shipped copies

@MainActor
struct LibraryContentSeedTests {

    @Test func theShippedCopiesHoldTogether() throws {
        let book = try shippedBook()
        let library = try shippedLibrary()
        #expect(book.problem == nil)
        #expect(library.problem == nil)
        #expect(book.prayers.count == 152)
        #expect(book.chapters.count == 18)
        #expect(library.groups.count == 12)
        #expect(library.chants.count == 104)
    }

    /// The book shows every field of its document, and the app sets every
    /// chapter the document has
    @Test func theBookIsTheDocument() throws {
        let book = LibraryContent.prayerBook
        #expect(PrayerBook.prayers.count == book.prayers.count)
        for written in book.prayers {
            let prayer = try #require(PrayerBook.prayer(written.id))
            #expect(prayer.title == written.title)
            #expect(prayer.latinTitle == written.latinTitle)
            #expect(prayer.origin == written.origin)
            #expect(prayer.note == written.note)
            #expect(prayer.english == written.english)
            #expect(prayer.latin == written.latin)
            #expect(prayer.listTitle == (written.listTitle ?? written.title))
            #expect(prayer.searchWords == written.searchWords)
        }
        #expect(PrayerBook.chapters.map(\.id) == book.chapters.map(\.id))
        for (chapter, written) in zip(PrayerBook.chapters, book.chapters) {
            #expect(PrayerBook.layouts[chapter.id] != nil, "\(chapter.id) has no layout")
            #expect(chapter.epigraph == written.note)
            #expect(chapter.prayerIDs == written.prayerIDs)
            #expect(chapter.sections.map(\.title) == written.sections.map(\.title))
            #expect(chapter.sections.map(\.prayerIDs) == written.sections.map(\.prayerIDs))
        }
        #expect(PrayerBook.englishNames["memorare"] == "Remember, O most gracious Virgin Mary")
    }

    @Test func theCatalogIsTheDocument() throws {
        let library = LibraryContent.chantLibrary
        #expect(ChantCatalog.all.map(\.id) == library.chants.map(\.id))
        #expect(ChantCatalog.groups.map(\.id) == library.groups.map(\.id))
        for (chant, written) in zip(ChantCatalog.all, library.chants) {
            #expect(chant.lines.count == written.lines.count)
            #expect(chant.duration == written.duration)
            #expect(chant.audio.url?.absoluteString == written.audio.url)
            #expect(chant.audio.sha256 == written.audio.sha256)
            #expect(chant.score.map(\.asset.sha256) == written.score.map(\.sha256))
        }
    }
}

// MARK: - The kept copy

@MainActor
struct LibraryDocumentStoreTests {

    private func store(in directory: URL) -> LibraryDocumentStore<PrayerBookDocument> {
        LibraryDocumentStore(
            name: "prayer_book",
            seedURL: LibraryContent.prayerBookStore.seedURL,
            cacheURL: directory.appendingPathComponent("prayer_book.json")
        )
    }

    @Test func withNothingKeptTheShippedCopyIsRead() throws {
        let store = store(in: try temporaryDirectory())
        #expect(store.kept == nil)
        #expect(store.current() == (try shippedBook()))
    }

    @Test func aKeptCopyIsReadBeforeTheShippedOne() throws {
        let store = store(in: try temporaryDirectory())
        var newer = try shippedBook()
        newer.version = "abcdef0123456789"
        newer.updatedAt = "2099-01-01T00:00:00Z"
        newer.prayers[0].note = "A corrected note"
        try store.keep(encoded(newer))
        #expect(store.current()?.version == "abcdef0123456789")
        #expect(store.current()?.prayers[0].note == "A corrected note")
    }

    @Test func aShippedCopyNewerThanTheKeptOneWins() throws {
        let store = store(in: try temporaryDirectory())
        var older = try shippedBook()
        older.version = "0000000000000000"
        older.updatedAt = "2000-01-01T00:00:00Z"
        try store.keep(encoded(older))
        #expect(store.current()?.version == (try shippedBook()).version)
    }

    @Test func aBrokenOrPartialCopyIsNeverKept() throws {
        let store = store(in: try temporaryDirectory())
        var good = try shippedBook()
        good.version = "1111111111111111"
        try store.keep(encoded(good))

        // Cut off half way
        let whole = try encoded(good)
        #expect(throws: (any Error).self) { try store.keep(whole.prefix(whole.count / 2)) }
        // Decodes, but a chapter names a prayer the book lacks
        var broken = good
        broken.version = "2222222222222222"
        broken.chapters[0].prayerIDs.append("no_such_prayer")
        #expect(throws: LibraryContent.Failure.self) { try store.keep(encoded(broken)) }

        #expect(store.kept?.version == "1111111111111111")
    }

    @Test func aKeptCopySpoiledOnDiskFallsBackToTheShippedOne() throws {
        let directory = try temporaryDirectory()
        let store = store(in: directory)
        try Data("{\"prayers\": [".utf8).write(to: store.cacheURL)
        #expect(store.current() == (try shippedBook()))
    }
}

// MARK: - Asking the server

@MainActor
@Suite(.serialized)
struct LibraryContentSyncTests {

    private func sync(in directory: URL, defaults: UserDefaults) -> LibraryContentSync {
        LibraryContentSync(
            session: LibraryStubProtocol.session,
            baseURL: "https://api.test/api",
            defaults: defaults,
            prayerBookStore: LibraryDocumentStore(
                name: "prayer_book", seedURL: LibraryContent.prayerBookStore.seedURL,
                cacheURL: directory.appendingPathComponent("prayer_book.json")),
            chantLibraryStore: LibraryDocumentStore(
                name: "chant_library", seedURL: LibraryContent.chantLibraryStore.seedURL,
                cacheURL: directory.appendingPathComponent("chant_library.json"))
        )
    }

    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "LibraryContentSyncTests.\(UUID().uuidString)")!
    }

    /// The server answers with `book` and `library`, bare or whole as asked
    private func serve(book: PrayerBookDocument, library: ChantLibraryDocument) {
        LibraryStubProtocol.reset { request in
            let url = request.url!.absoluteString
            let whole = url.contains("fields")
            do {
                if url.contains("/v2/prayer-book") {
                    let body =
                        whole
                        ? try jsonAPI("prayer_book", book)
                        : try jsonAPI("prayer_book", ["version": book.version, "updated_at": book.updatedAt])
                    return .init(body: body)
                }
                if url.contains("/v2/chant-library") {
                    let body =
                        whole
                        ? try jsonAPI("chant_library", library)
                        : try jsonAPI("chant_library", ["version": library.version, "updated_at": library.updatedAt])
                    return .init(body: body)
                }
            } catch {}
            return .init(status: 404)
        }
    }

    @Test func aNewVersionIsFetchedWholeAndKept() async throws {
        let directory = try temporaryDirectory()
        var book = try shippedBook()
        book.version = "feedfacefeedface"
        book.updatedAt = "2099-01-01T00:00:00Z"
        var library = try shippedLibrary()
        library.version = "cafebabecafebabe"
        library.updatedAt = "2099-01-01T00:00:00Z"
        serve(book: book, library: library)

        let sync = sync(in: directory, defaults: defaults())
        var kept: ChantLibraryDocument?
        sync.onChantLibraryKept = { kept = $0 }
        await sync.refresh()

        #expect(
            LibraryDocumentStore<PrayerBookDocument>.read(directory.appendingPathComponent("prayer_book.json"))?.version
                == "feedfacefeedface")
        #expect(kept?.version == "cafebabecafebabe")
        let asked = LibraryStubProtocol.requested.compactMap(\.url?.absoluteString)
        #expect(asked.contains { $0.contains("fields%5Bprayer_book%5D") || $0.contains("fields[prayer_book]") })
    }

    @Test func theSameVersionIsNotFetchedAgain() async throws {
        let directory = try temporaryDirectory()
        var book = try shippedBook()
        book.version = "feedfacefeedface"
        var library = try shippedLibrary()
        library.version = "cafebabecafebabe"
        serve(book: book, library: library)
        let sync = sync(in: directory, defaults: defaults())
        await sync.refresh()

        LibraryStubProtocol.reset { _ in .init() }
        serve(book: book, library: library)
        await sync.refresh()
        let asked = LibraryStubProtocol.requested.compactMap(\.url?.absoluteString)
        #expect(asked.count == 2, "only the two bare documents: \(asked)")
        #expect(!asked.contains { $0.contains("fields") })
    }

    @Test func aBadAnswerKeepsTheOldCopy() async throws {
        let directory = try temporaryDirectory()
        var book = try shippedBook()
        book.version = "1111111111111111"
        var library = try shippedLibrary()
        library.version = "2222222222222222"
        serve(book: book, library: library)
        let defaults = defaults()
        let sync = sync(in: directory, defaults: defaults)
        await sync.refresh()

        // A new version whose whole document is broken
        LibraryStubProtocol.reset { request in
            let url = request.url!.absoluteString
            if url.contains("fields") { return .init(body: Data("{\"data\":{\"attributes\":{\"prayers\":[]".utf8)) }
            return .init(body: (try? jsonAPI("x", ["version": "9999999999999999"])) ?? Data())
        }
        await sync.refresh()
        #expect(
            LibraryDocumentStore<PrayerBookDocument>.read(directory.appendingPathComponent("prayer_book.json"))?.version
                == "1111111111111111")
        #expect(
            LibraryDocumentStore<ChantLibraryDocument>.read(directory.appendingPathComponent("chant_library.json"))?
                .version
                == "2222222222222222")
    }

    @Test func itAsksOnceADayUnlessLaunching() async throws {
        let defaults = defaults()
        let now = Date()
        defaults.set(now.addingTimeInterval(-3600), forKey: LibraryContentSync.checkedKey)
        LibraryStubProtocol.reset { _ in .init(status: 500) }
        let sync = sync(in: try temporaryDirectory(), defaults: defaults)
        sync.refreshIfDue(now: now)
        try await Task.sleep(for: .milliseconds(200))
        #expect(LibraryStubProtocol.requested.isEmpty)
    }

    @Test func attributesAreReadFromTheJSONAPIEnvelope() throws {
        let body = try jsonAPI("prayer_book", ["version": "abc"])
        let attributes = try LibraryContentSync.attributesData(of: body)
        let object = try JSONSerialization.jsonObject(with: attributes) as? [String: String]
        #expect(object?["version"] == "abc")
    }
}

// MARK: - The chants' files

@MainActor
@Suite(.serialized)
struct ChantAssetStoreTests {

    private func file(_ data: Data, url: String = "https://files.test/chants/audio/x.m4a") -> ChantFile {
        ChantFile(url: URL(string: url), bytes: data.count, sha256: sha256(data), fileExtension: "m4a")
    }

    private func store(_ directory: URL) -> ChantAssetStore {
        ChantAssetStore(directory: directory, sessions: (LibraryStubProtocol.session, LibraryStubProtocol.session))
    }

    @Test func aFileNotHereStreamsAndOnceHereIsPlayedFromThePhone() async throws {
        let directory = try temporaryDirectory()
        let data = Data("a recording".utf8)
        let recording = file(data)
        let store = store(directory)
        #expect(store.localURL(for: recording) == nil)
        #expect(store.playableURL(for: recording) == recording.url)

        LibraryStubProtocol.reset { _ in .init(body: data) }
        let fetched = await store.fetchNow(recording)
        #expect(fetched == directory.appendingPathComponent(recording.localName))
        #expect(store.playableURL(for: recording) == fetched)
        #expect(try Data(contentsOf: try #require(fetched)) == data)
    }

    @Test func aFileWhoseHashIsWrongIsNeverKept() async throws {
        let directory = try temporaryDirectory()
        let recording = file(Data("the real recording".utf8))
        LibraryStubProtocol.reset { _ in .init(body: Data("something else".utf8)) }
        let store = store(directory)
        await #expect(throws: ChantAssetError.checksumMismatch) {
            try await ChantAssetStore.download(recording, session: LibraryStubProtocol.session, into: directory)
        }
        #expect(await store.fetchNow(recording) == nil)
        #expect(store.localURL(for: recording) == nil)
        #expect(ChantAssetStore.names(in: directory).isEmpty)
    }

    @Test func filesNoChantNamesAreLetGo() throws {
        let directory = try temporaryDirectory()
        let keep = Data("kept".utf8)
        let drop = Data("dropped".utf8)
        let store = store(directory)
        for data in [keep, drop] {
            let source = directory.appendingPathComponent("source")
            try data.write(to: source)
            try store.adopt(source, as: file(data))
            try FileManager.default.removeItem(at: source)
        }
        store.prune(keeping: [file(keep)])
        #expect(store.localURL(for: file(keep)) != nil)
        #expect(store.localURL(for: file(drop)) == nil)
        #expect(ChantAssetStore.names(in: directory) == [file(keep).localName])
    }

    @Test func fetchingAllCountsWhatCouldNotBeHad() async throws {
        let directory = try temporaryDirectory()
        let store = store(directory)
        let chants = Array(ChantCatalog.all.prefix(2))
        LibraryStubProtocol.reset { _ in .init(status: 404) }
        let failed = await store.fetchAll(chants)
        #expect(failed == store.missingFiles(of: chants).count)
        #expect(store.savedCount(of: chants) == 0)
    }

    /// A chant the server adds that the app has not curated still stands
    /// in its section, is found by search, and has a kind
    @Test func anUncuratedChantStillAppears() throws {
        var library = try shippedLibrary()
        var newcomer = library.chants[0]
        newcomer.id = "o_quam_suavis"
        newcomer.latinTitle = "O quam suavis est"
        newcomer.englishTitle = "How Sweet, O Lord"
        library.chants.append(newcomer)
        library.groups[0].parts[0].chantIDs.append("o_quam_suavis")
        #expect(library.problem == nil)

        let chants = library.chants.map(Chant.init(document:))
        let groups = ChantCatalog.groups
        let index = ChantCatalogIndex(chants: chants, groups: groups)
        let chant = try #require(index.chants["o_quam_suavis"])
        #expect(chant.form == .hymn)
        #expect(index.foldedTitles.contains { $0.chant.id == "o_quam_suavis" && $0.latin.contains("quam suavis") })
        #expect(library.groups[0].parts[0].chantIDs.contains("o_quam_suavis"))
    }
}
