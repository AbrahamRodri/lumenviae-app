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

    /// A chant library that would send the app somewhere it should not go,
    /// or keep a file it cannot check, is refused
    @Test func aChantLibraryThatDoesNotHoldTogetherIsRefused() throws {
        let good = try shippedLibrary()
        #expect(good.problem == nil)
        var bad = good
        bad.chants[0].audio.url = "http://insecure.test/a.m4a"
        #expect(bad.problem != nil)
        bad = good
        bad.chants[0].audio.sha256 = String(repeating: "z", count: 64)
        #expect(bad.problem != nil)
        bad = good
        bad.chants[0].score[0].url = nil
        #expect(bad.problem != nil)
        bad = good
        bad.chants[0].sourceURL = "javascript:alert(1)"
        #expect(bad.problem != nil)
        bad = good
        bad.chants[1].id = bad.chants[0].id
        #expect(bad.problem != nil)
        bad = good
        bad.groups[0].parts[0].chantIDs.append("no_such_chant")
        #expect(bad.problem != nil)
        bad = good
        bad.chants[0].groupID = "no_such_group"
        #expect(bad.problem != nil)
        bad = good
        bad.chants = []
        #expect(bad.problem != nil)
    }

    /// A book without a topic the app names is refused, and the app's
    /// layouts name exactly the topics it requires
    @Test func aBookMissingANamedTopicIsRefused() throws {
        #expect(Set(PrayerBook.layouts.keys) == PrayerBookDocument.namedChapterIDs)
        var book = try shippedBook()
        book.chapters.removeAll { $0.id == "our_lady" }
        #expect(book.problem != nil)
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
        book.updatedAt = "2099-01-01T00:00:00Z"
        var library = try shippedLibrary()
        library.version = "cafebabecafebabe"
        library.updatedAt = "2099-01-01T00:00:00Z"
        serve(book: book, library: library)
        let sync = sync(in: directory, defaults: defaults())
        await sync.refresh()
        #expect(LibraryStubProtocol.requested.contains { $0.url?.absoluteString.contains("fields") == true })

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
        book.updatedAt = "2099-01-01T00:00:00Z"
        var library = try shippedLibrary()
        library.version = "2222222222222222"
        library.updatedAt = "2099-01-01T00:00:00Z"
        serve(book: book, library: library)
        let defaults = defaults()
        let sync = sync(in: directory, defaults: defaults)
        await sync.refresh()

        // A new version whose whole document is broken
        LibraryStubProtocol.reset { request in
            let url = request.url!.absoluteString
            if url.contains("fields") { return .init(body: Data("{\"data\":{\"attributes\":{\"prayers\":[]".utf8)) }
            return .init(
                body: (try? jsonAPI("x", ["version": "9999999999999999", "updated_at": "2100-01-01T00:00:00Z"]))
                    ?? Data())
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

    /// The shipped copies carry the server's version, so a phone with
    /// them asks for nothing more while the server has not changed
    @Test func theShippedVersionIsNotFetchedAgain() async throws {
        let book = try shippedBook()
        let library = try shippedLibrary()
        #expect(book.version?.count == 16)
        #expect(library.version?.count == 16)
        serve(book: book, library: library)
        await sync(in: try temporaryDirectory(), defaults: defaults()).refresh()
        #expect(!LibraryStubProtocol.requested.contains { $0.url?.absoluteString.contains("fields") == true })
    }

    /// A server copy dated no later than the phone's is never fetched,
    /// whatever its version: it would never be read
    @Test func anOlderServerCopyIsNotFetched() async throws {
        var book = try shippedBook()
        book.version = "0123456789abcdef"
        book.updatedAt = "2000-01-01T00:00:00Z"
        var library = try shippedLibrary()
        library.version = "fedcba9876543210"
        library.updatedAt = "2000-01-01T00:00:00Z"
        serve(book: book, library: library)
        let directory = try temporaryDirectory()
        await sync(in: directory, defaults: defaults()).refresh()
        #expect(!LibraryStubProtocol.requested.contains { $0.url?.absoluteString.contains("fields") == true })
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("prayer_book.json").path))
    }

    /// A server document refused once is not fetched again until the
    /// server changes its version
    @Test func aRefusedVersionIsNotFetchedAgain() async throws {
        let directory = try temporaryDirectory()
        let defaults = defaults()
        LibraryStubProtocol.reset { request in
            let url = request.url!.absoluteString
            if url.contains("fields") { return .init(body: Data("{\"data\":{\"attributes\":{\"prayers\":[]".utf8)) }
            return .init(
                body: (try? jsonAPI("x", ["version": "9999999999999999", "updated_at": "2100-01-01T00:00:00Z"]))
                    ?? Data())
        }
        let sync = sync(in: directory, defaults: defaults)
        await sync.refresh()
        let first = LibraryStubProtocol.requested.filter { $0.url?.absoluteString.contains("fields") == true }.count
        #expect(first == 2)
        LibraryStubProtocol.reset { request in
            .init(
                body: (try? jsonAPI("x", ["version": "9999999999999999", "updated_at": "2100-01-01T00:00:00Z"]))
                    ?? Data())
        }
        await sync.refresh()
        #expect(!LibraryStubProtocol.requested.contains { $0.url?.absoluteString.contains("fields") == true })
    }

    @Test func atLaunchItAsksWhateverTheDay() async throws {
        let defaults = defaults()
        defaults.set(Date(), forKey: LibraryContentSync.checkedKey)
        serve(book: try shippedBook(), library: try shippedLibrary())
        let sync = sync(in: try temporaryDirectory(), defaults: defaults)
        sync.refreshIfDue(force: true)
        try await waitForRequests(2)
        #expect(LibraryStubProtocol.requested.count >= 2)
    }

    @Test func aDayLaterItAsksAgain() async throws {
        let defaults = defaults()
        let now = Date()
        defaults.set(now.addingTimeInterval(-LibraryContentSync.interval - 60), forKey: LibraryContentSync.checkedKey)
        serve(book: try shippedBook(), library: try shippedLibrary())
        let sync = sync(in: try temporaryDirectory(), defaults: defaults)
        sync.refreshIfDue(now: now)
        try await waitForRequests(2)
        #expect(LibraryStubProtocol.requested.count >= 2)
        // Answered, the day is marked
        for _ in 0..<50 where (defaults.object(forKey: LibraryContentSync.checkedKey) as? Date) != now {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(defaults.object(forKey: LibraryContentSync.checkedKey) as? Date == now)
    }

    private func waitForRequests(_ count: Int) async throws {
        for _ in 0..<100 where LibraryStubProtocol.requested.count < count {
            try await Task.sleep(for: .milliseconds(20))
        }
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

    /// A store of its own, its catalog one chant, so no run it begins
    /// outlives the test
    private func store(_ directory: URL) -> ChantAssetStore {
        let small = Array(ChantCatalog.all.prefix(1))
        return ChantAssetStore(
            directory: directory, sessions: (LibraryStubProtocol.session, LibraryStubProtocol.session),
            defaults: UserDefaults(suiteName: "ChantAssetStoreTests.\(UUID().uuidString)")!,
            catalog: { small })
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
        LibraryStubProtocol.reset { _ in .init(body: Data("the fake recording".utf8)) }
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

    @Test func aFileWhoseSizeIsWrongIsNeverKept() async throws {
        let directory = try temporaryDirectory()
        let data = Data("the recording".utf8)
        let wrongSize = ChantFile(url: file(data).url, bytes: data.count + 1, sha256: sha256(data), fileExtension: "m4a")
        LibraryStubProtocol.reset { _ in .init(body: data) }
        await #expect(throws: ChantAssetError.sizeMismatch) {
            try await ChantAssetStore.download(wrongSize, session: LibraryStubProtocol.session, into: directory)
        }
        #expect(ChantAssetStore.names(in: directory).isEmpty)
    }

    /// Two asking for one file at once share one download
    @Test func aFileIsDownloadedOnceForEveryoneWhoAsks() async throws {
        let directory = try temporaryDirectory()
        let data = Data("a page of sheet music".utf8)
        let page = file(data)
        LibraryStubProtocol.reset { _ in .init(body: data) }
        let store = store(directory)
        async let first = store.fetchNow(page)
        async let second = store.fetchNow(page)
        let (a, b) = await (first, second)
        #expect(a != nil && a == b)
        #expect(LibraryStubProtocol.requested.count == 1)
        #expect(ChantAssetStore.names(in: directory) == [page.localName])
    }

    @Test func onlyTheNetworkGoneStopsARun() {
        #expect(ChantAssetStore.stopsTheRun(URLError(.notConnectedToInternet)))
        #expect(ChantAssetStore.stopsTheRun(URLError(.networkConnectionLost)))
        #expect(ChantAssetStore.stopsTheRun(URLError(.cancelled)))
        #expect(!ChantAssetStore.stopsTheRun(URLError(.timedOut)))
        #expect(!ChantAssetStore.stopsTheRun(ChantAssetError.badStatus(404)))
        #expect(!ChantAssetStore.stopsTheRun(ChantAssetError.checksumMismatch))
    }

    /// Offline, a run asks for the first few files and stops; a timeout
    /// lets it go on to every file
    @Test func aRunStopsWhenOfflineAndGoesOnPastATimeout() async throws {
        let chants = Array(ChantCatalog.all.prefix(6))
        let offline = store(try temporaryDirectory())
        LibraryStubProtocol.reset { _ in .init(error: URLError(.notConnectedToInternet)) }
        let missing = offline.missingFiles(of: chants).count
        #expect(await offline.fetchAll(chants) == missing)
        #expect(LibraryStubProtocol.requested.count <= ChantAssetStore.parallel)

        let slow = store(try temporaryDirectory())
        LibraryStubProtocol.reset { _ in .init(error: URLError(.timedOut)) }
        #expect(await slow.fetchAll(chants) == missing)
        #expect(LibraryStubProtocol.requested.count == missing)
    }

    /// The Wi-Fi run fetches every file the catalog and a newer kept
    /// library name, and lets go of the rest
    @Test func theBackgroundRunFetchesWhatTheLibrariesNeed() async throws {
        let directory = try temporaryDirectory()
        let store = store(directory)
        let stray = Data("a file no chant names".utf8)
        let source = directory.appendingPathComponent("source")
        try stray.write(to: source)
        try store.adopt(source, as: file(stray))
        try FileManager.default.removeItem(at: source)

        // Every file the server is asked for answers with the bytes its
        // hash names: the shipped scores the tests keep
        let pages = Dictionary(ScoreFixtures.urls.map { ($0.deletingPathExtension().lastPathComponent, $0) },
                               uniquingKeysWith: { first, _ in first })
        let chants = ChantCatalog.all.filter { chant in chant.score.allSatisfy { pages[$0.file] != nil } }
            .map { chant in
                // Recordings stand in as the chant's first page, so the
                // run has real bytes for every file it is asked for
                Chant(id: chant.id, groupID: chant.groupID, latinTitle: chant.latinTitle,
                      englishTitle: chant.englishTitle, setting: chant.setting, detail: chant.detail,
                      prayerIDs: chant.prayerIDs, duration: chant.duration, score: chant.score,
                      audio: chant.score[0].asset, sourceURL: chant.sourceURL)
            }
        try #require(!chants.isEmpty)
        let byURL = Dictionary(chants.flatMap(\.score).compactMap { part in
            part.asset.url.flatMap { url in pages[part.file].map { (url, $0) } }
        }, uniquingKeysWith: { first, _ in first })
        LibraryStubProtocol.reset { request in
            guard let url = request.url, let local = byURL[url], let data = try? Data(contentsOf: local) else {
                return .init(status: 404)
            }
            return .init(body: data)
        }

        store.syncInBackground(chants)
        await store.waitForRun()
        #expect(store.savedCount(of: chants) == chants.count)
        #expect(store.localURL(for: file(stray)) == nil)
    }

    /// A newer library kept from the server has its files fetched now,
    /// though no chant of this launch's catalog names them, and they stay
    /// through the run's clearing out
    @Test func aNewerLibrarysFilesAreFetchedAndKept() async throws {
        let directory = try temporaryDirectory()
        let store = store(directory)
        let stray = Data("a file no chant names".utf8)
        let source = directory.appendingPathComponent("source")
        try stray.write(to: source)
        try store.adopt(source, as: file(stray))
        try FileManager.default.removeItem(at: source)

        let recording = Data("a recording only the newer library names".utf8)
        let page = Data("a page only the newer library names".utf8)
        var newer = try shippedLibrary()
        var newcomer = newer.chants[0]
        newcomer.id = "newcomer"
        newcomer.audio = .init(url: "https://files.test/new/newcomer.m4a", bytes: recording.count, sha256: sha256(recording))
        newcomer.score = [.init(file: "newcomer-page", caption: "Newcomer", aspectRatio: 1,
                                url: "https://files.test/new/newcomer.lvscore", bytes: page.count, sha256: sha256(page))]
        newer.chants = [newcomer]
        let newFiles = Chant(document: newcomer).files

        LibraryStubProtocol.reset { request in
            switch request.url?.absoluteString {
            case "https://files.test/new/newcomer.m4a": return .init(body: recording)
            case "https://files.test/new/newcomer.lvscore": return .init(body: page)
            default: return .init(status: 404)
            }
        }
        store.libraryKept(newer)
        await store.waitForRun()
        #expect(newFiles.allSatisfy { store.localURL(for: $0) != nil })
        #expect(store.localURL(for: file(stray)) == nil)

        // A later run over the catalog alone keeps them
        store.syncInBackground()
        #expect(newFiles.allSatisfy { store.localURL(for: $0) != nil })
        await store.waitForRun()
    }

    /// An older version of a chant's recording stays, and plays, until the
    /// newer has come down
    @Test func anOlderRecordingPlaysUntilTheNewerIsHere() throws {
        let directory = try temporaryDirectory()
        let store = store(directory)
        let old = Data("the first recording".utf8)
        let new = Data("the corrected recording".utf8)
        let oldFile = ChantFile(url: URL(string: "https://files.test/a-1.m4a"), bytes: old.count,
                                sha256: sha256(old), fileExtension: "m4a", key: "audio:a")
        let newFile = ChantFile(url: URL(string: "https://files.test/a-2.m4a"), bytes: new.count,
                                sha256: sha256(new), fileExtension: "m4a", key: "audio:a")
        let source = directory.appendingPathComponent("source")
        try old.write(to: source)
        try store.adopt(source, as: oldFile)

        store.prune(keeping: [newFile])
        #expect(store.localURL(for: newFile) == nil)
        #expect(store.playableURL(for: newFile) == directory.appendingPathComponent(oldFile.localName))

        try new.write(to: source)
        try store.adopt(source, as: newFile)
        try FileManager.default.removeItem(at: source)
        store.prune(keeping: [newFile])
        #expect(store.playableURL(for: newFile) == directory.appendingPathComponent(newFile.localName))
        #expect(ChantAssetStore.names(in: directory) == [newFile.localName])
    }

    /// Back on Wi-Fi from cellular, the run takes up its files
    @Test func wifiAgainStartsTheRun() async throws {
        let store = store(try temporaryDirectory())
        LibraryStubProtocol.reset { _ in .init(status: 404) }
        store.connectionChanged(online: true, expensive: true)
        #expect(store.reconnections == 0)
        await store.waitForRun()
        #expect(LibraryStubProtocol.requested.isEmpty, "nothing on cellular")

        store.connectionChanged(online: true, expensive: false)
        await store.waitForRun()
        #expect(!LibraryStubProtocol.requested.isEmpty, "Wi-Fi again: the run begins")

        store.connectionChanged(online: false)
        store.connectionChanged(online: true)
        #expect(store.reconnections == 1)
        await store.waitForRun()
    }

    /// A catalog that could not be read lets go of nothing
    @Test func anEmptyCatalogLetsGoOfNothing() throws {
        let directory = try temporaryDirectory()
        let store = store(directory)
        let data = Data("kept".utf8)
        let source = directory.appendingPathComponent("source")
        try data.write(to: source)
        try store.adopt(source, as: file(data))
        store.syncInBackground([])
        #expect(store.localURL(for: file(data)) != nil)
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
        let index = ChantCatalogIndex(chants: chants, groups: ChantCatalog.groups(from: library))
        let chant = try #require(index.chants["o_quam_suavis"])
        #expect(chant.form == .hymn)
        #expect(index.foldedTitles.contains { $0.chant.id == "o_quam_suavis" && $0.latin.contains("quam suavis") })
        // What the section's page lists, as it reads it
        let section = try #require(index.groups[library.groups[0].id])
        #expect(section.parts.flatMap { index.chants(in: $0) }.map(\.id).contains("o_quam_suavis"))
    }
}
