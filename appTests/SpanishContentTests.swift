//
//  SpanishContentTests.swift
//  appTests
//
//  The Rosary's prayers and the mysteries in Spanish (iOS 2c): the bundled
//  copy of the api's files, Spanish in English's place only in a Spanish
//  app, the AI line, and the Prayer Book's Spanish falling back to English
//  when the server has none.
//

import Foundation
import Testing

@testable import app

struct SpanishContentTests {

    // MARK: - The bundled copy

    @Test func everyRosaryPrayerHasItsSpanish() {
        let ids = Set(RosaryPrayers.english.map(\.id))
        #expect(ids.count == 12)
        #expect(Set(SpanishContent.prayers.keys) == ids)
        for (id, prayer) in SpanishContent.prayers {
            #expect(!prayer.title.isEmpty && !prayer.text.isEmpty, "\(id) is empty")
        }
    }

    @Test func everyMysteryHasItsSpanishNameAndFruit() {
        let keys = Set(
            MysteryCategory.allCases.flatMap { category in
                MysteryData.mysteries(for: category).map { "\($0.category)_\($0.order)" }
            })
        #expect(keys.count == 27)
        #expect(Set(SpanishContent.mysteries.keys) == keys)
        #expect(Set(MysteryData.englishFruits.keys) == keys)
    }

    @Test func onlyTheSevenSorrowsClosingPrayerIsMarkedAsAITranslated() {
        let marked = SpanishContent.prayers.filter { $0.value.aiTranslated }.map(\.key)
        #expect(marked == ["sorrows_closing_prayer"])
    }

    // MARK: - Spanish in English's place

    @Test func aSpanishAppSaysThePrayerInSpanishBesideTheSameLatin() throws {
        let english = try #require(RosaryPrayers.english.first { $0.id == "hail_mary" })
        let spanish = SpanishContent.vernacular(english, spanish: true)
        #expect(spanish.englishTitle == "Ave María")
        #expect(spanish.content.english.hasPrefix("Dios te salve, María, llena eres de gracia"))
        #expect(spanish.content.latin == english.content.latin)
        #expect(spanish.latinTitle == english.latinTitle)
        #expect(!spanish.aiTranslated)
    }

    @Test func anEnglishAppIsUnchanged() throws {
        let english = try #require(RosaryPrayers.english.first { $0.id == "our_father" })
        let same = SpanishContent.vernacular(english, spanish: false)
        #expect(same.englishTitle == english.englishTitle)
        #expect(same.content.english == english.content.english)
        // The tests host an English app
        #expect(RosaryPrayers.all.map(\.englishTitle) == RosaryPrayers.english.map(\.englishTitle))
        #expect(RosaryPrayerText.gloryBe.english == RosaryPrayerText.englishGloryBe.english)
    }

    @Test func theGloryBeAndTheFatimaPrayerByID() {
        let gloryBe = SpanishContent.vernacular(RosaryPrayerText.englishGloryBe, id: "glory_be", spanish: true)
        #expect(gloryBe.english.hasPrefix("Gloria al Padre"))
        #expect(gloryBe.latin == RosaryPrayerText.englishGloryBe.latin)
        let fatima = SpanishContent.vernacular(RosaryPrayerText.englishFatimaPrayer, id: "fatima_prayer", spanish: true)
        #expect(fatima.english.hasPrefix("Oh Jesús mío"))
    }

    @Test func theChapletsClosingPrayerCarriesItsMark() throws {
        let english = try #require(RosaryPrayers.english.first { $0.id == "sorrows_closing_prayer" })
        #expect(SpanishContent.vernacular(english, spanish: true).aiTranslated)
        #expect(!SpanishContent.vernacular(english, spanish: false).aiTranslated)
    }

    @Test func mysteryNamesAndFruitsFollowTheLanguage() {
        #expect(
            SpanishContent.mysteryName("The Annunciation", key: "joyful_1", spanish: true)
                == "La encarnación del Hijo de Dios")
        #expect(SpanishContent.mysteryName("The Annunciation", key: "joyful_1", spanish: false) == "The Annunciation")
        #expect(SpanishContent.fruit("Humility", key: "joyful_1", spanish: true) == "Humildad")
        #expect(SpanishContent.mysteryName("Unknown", key: "nowhere_9", spanish: true) == "Unknown")
    }

    /// A mystery is stored and sent in English whatever the app shows, so a
    /// copy cached in a Spanish app reads right after a switch to English
    @Test func aMysteryIsEncodedUnderItsEnglishName() throws {
        let mystery = Mystery(
            id: 1, name: "The Annunciation", category: "joyful", order: 1,
            description: nil, scriptureReference: "Luke 1:26-38")
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(mystery)) as? [String: Any]
        #expect(json?["name"] as? String == "The Annunciation")
        let decoded = try JSONDecoder().decode(Mystery.self, from: JSONEncoder().encode(mystery))
        #expect(decoded.storedName == "The Annunciation")
        #expect(decoded.name == "The Annunciation")
    }

    // MARK: - The AI line

    @Test func theAILineStandsUnderTheMarkedPrayerInSpanishOnly() {
        #expect(AITranslationNote.note(for: "sorrows_closing_prayer", spanish: true) != nil)
        #expect(AITranslationNote.note(for: "sorrows_closing_prayer", spanish: false) == nil)
        #expect(AITranslationNote.note(for: "hail_mary", spanish: true) == nil)
    }

    // MARK: - The Prayer Book

    private func bookPrayer(_ id: String, english: String = "English words") -> BookPrayer {
        BookPrayer(
            id: id, title: "English title", latinTitle: "Titulus", origin: nil, note: nil,
            english: english, latin: "Verba latina")
    }

    /// A server with no Spanish for the book (before it serves `lang=es`, or
    /// a prayer it has not translated): the prayer stays English, whole
    @Test func aBookPrayerWithNoSpanishFallsBackToEnglish() {
        let prayer = PrayerBook.inSpanish(bookPrayer("anima_christi"), translations: [:], spanish: true)
        #expect(prayer.title == "English title")
        #expect(prayer.english == "English words")
        #expect(prayer.latin == "Verba latina")
    }

    @Test func theServersSpanishIsLaidOverTheEnglish() {
        let translation = PrayerBookTranslations.Translation(
            id: "anima_christi", title: "Alma de Cristo", text: "Alma de Cristo, santifícame.", aiTranslated: nil)
        let prayer = PrayerBook.inSpanish(
            bookPrayer("anima_christi"), translations: ["anima_christi": translation], spanish: true)
        #expect(prayer.title == "Alma de Cristo")
        #expect(prayer.english == "Alma de Cristo, santifícame.")
        #expect(prayer.latin == "Verba latina")
        #expect(
            PrayerBook.inSpanish(
                bookPrayer("anima_christi"), translations: ["anima_christi": translation], spanish: false
            ).title == "English title")
    }

    /// Before the server's book has Spanish, the Rosary's prayers the book
    /// prints still read in the Rosary's bundled Spanish
    @Test func theRosarysPrayersInTheBookUseTheBundledSpanish() {
        let prayer = PrayerBook.inSpanish(bookPrayer("memorare"), translations: [:], spanish: true)
        #expect(prayer.title == "Acordaos")
        #expect(prayer.english.hasPrefix("Acordaos, oh piadosísima Virgen María"))
    }

    @Test func aDocumentWithoutTranslationsDecodesAsNone() throws {
        let document = try JSONDecoder().decode(
            PrayerBookTranslations.self, from: Data(#"{"version":"abc","updated_at":"2026-11-03T00:00:00Z"}"#.utf8))
        #expect(document.translations.isEmpty)
        #expect(document.problem == nil)
        let twice = PrayerBookTranslations(translations: [
            .init(id: "a", title: "A", text: "a", aiTranslated: nil),
            .init(id: "a", title: "A", text: "a", aiTranslated: nil),
        ])
        #expect(twice.problem != nil)
    }
}

// MARK: - The Spanish book's sync

/// In the sync suite, which owns the stub server and runs one test at a
/// time
extension LibraryContentSyncTests {

    private func spanishDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpanishPrayerBookSyncTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func spanishSync(in directory: URL, spanish: Bool) -> LibraryContentSync {
        LibraryContentSync(
            session: LibraryStubProtocol.session,
            baseURL: "https://api.test/api",
            defaults: UserDefaults(suiteName: "SpanishPrayerBookSyncTests.\(UUID().uuidString)")!,
            prayerBookStore: LibraryDocumentStore(
                name: "prayer_book", seedURL: LibraryContent.prayerBookStore.seedURL,
                cacheURL: directory.appendingPathComponent("prayer_book.json")),
            chantLibraryStore: LibraryDocumentStore(
                name: "chant_library", seedURL: LibraryContent.chantLibraryStore.seedURL,
                cacheURL: directory.appendingPathComponent("chant_library.json")),
            prayerBookSpanishStore: LibraryDocumentStore(
                name: "prayer_book.es", seedURL: nil,
                cacheURL: directory.appendingPathComponent("prayer_book.es.json")),
            spanish: spanish
        )
    }

    private func spanishBody(_ attributes: [String: Any]) -> Data {
        let document: [String: Any] = ["data": ["type": "prayer_book", "id": "prayer_book", "attributes": attributes]]
        return (try? JSONSerialization.data(withJSONObject: document)) ?? Data()
    }

    private func spanishKept(in directory: URL) -> PrayerBookTranslations? {
        LibraryDocumentStore<PrayerBookTranslations>.read(directory.appendingPathComponent("prayer_book.es.json"))
    }

    @Test func aSpanishAppFetchesTheBooksSpanishAndKeepsItApart() async throws {
        let directory = try spanishDirectory()
        LibraryStubProtocol.reset { request in
            let url = request.url!.absoluteString
            guard url.contains("lang=es") else { return .init(status: 404) }
            if url.contains("fields") {
                return .init(
                    body: self.spanishBody([
                        "version": "es-1", "updated_at": "2099-01-01T00:00:00Z",
                        "translations": [["id": "anima_christi", "title": "Alma de Cristo", "text": "Alma de Cristo"]],
                    ]))
            }
            return .init(body: self.spanishBody(["version": "es-1", "updated_at": "2099-01-01T00:00:00Z"]))
        }
        await spanishSync(in: directory, spanish: true).refresh()
        let kept = try #require(spanishKept(in: directory))
        #expect(kept.version == "es-1")
        #expect(kept.byID["anima_christi"]?.title == "Alma de Cristo")
        let asked = LibraryStubProtocol.requested.compactMap(\.url?.absoluteString)
        #expect(asked.contains { $0.contains("lang=es") && $0.contains("translations") })
    }

    /// The api before it serves the book's Spanish: the Spanish request is
    /// refused, nothing Spanish is kept, and the book reads English
    @Test func aServerWithoutSpanishLeavesTheBookEnglish() async throws {
        let directory = try spanishDirectory()
        LibraryStubProtocol.reset { request in
            let url = request.url!.absoluteString
            if url.contains("lang=es"), url.contains("fields") { return .init(status: 400) }
            return .init(body: self.spanishBody(["version": "en-1", "updated_at": "2026-01-01T00:00:00Z"]))
        }
        await spanishSync(in: directory, spanish: true).refresh()
        #expect(spanishKept(in: directory) == nil)
        let prayer = PrayerBook.inSpanish(
            BookPrayer(
                id: "anima_christi", title: "Soul of Christ", latinTitle: nil, origin: nil, note: nil,
                english: "Soul of Christ, sanctify me.", latin: nil),
            translations: spanishKept(in: directory)?.byID ?? [:], spanish: true)
        #expect(prayer.title == "Soul of Christ")
    }

    @Test func anEnglishAppNeverAsksForSpanish() async throws {
        let directory = try spanishDirectory()
        LibraryStubProtocol.reset { _ in
            .init(body: self.spanishBody(["version": "en-1", "updated_at": "2026-01-01T00:00:00Z"]))
        }
        await spanishSync(in: directory, spanish: false).refresh()
        #expect(!LibraryStubProtocol.requested.contains { $0.url?.absoluteString.contains("lang=") == true })
    }
}
