//
//  SpanishOverlayTests.swift
//  appTests
//
//  The meditations and the Consecration in Spanish: the server's Spanish
//  laid over the English by key, English left whole wherever there is no
//  Spanish, and the shapes the api sends (docs/IOS_API_CONTRACT.md,
//  sections 13 and 14).
//

import Foundation
import Testing

@testable import app

struct MeditationSpanishTests {

    private func meditation(
        _ id: Int, title: String? = "The Annunciation", audio: String? = "https://example.com/a.mp3"
    )
        -> Meditation
    {
        Meditation(
            id: id, title: title, content: "English text \(id)", author: "St. Alphonsus", source: "The Glories of Mary",
            audioUrl: audio, mystery: nil)
    }

    private let spanish = [
        MeditationTranslation(id: 1, title: "La Anunciación", content: "Texto en español", aiTranslated: true),
        MeditationTranslation(id: 2, title: nil, content: "Otro texto", aiTranslated: nil),
    ]

    @Test func englishIsUnchanged() {
        let english = [meditation(1), meditation(2)]
        #expect(MeditationTranslation.overlay(english, with: spanish, spanish: false) == english)
    }

    @Test func spanishTakesTitleAndTextTogether() throws {
        let laid = try #require(
            MeditationTranslation.overlay([meditation(1), meditation(2)], with: spanish, spanish: true))
        #expect(laid[0].title == "La Anunciación")
        #expect(laid[0].content == "Texto en español")
        #expect(laid[0].isSpanish)
        #expect(laid[0].aiTranslated)
        // The English has a title, the Spanish none: the Spanish's nil
        // stands, never the English title over Spanish words
        #expect(laid[1].title == nil)
        #expect(laid[1].isSpanish)
        #expect(!laid[1].aiTranslated)
        // The recording and the byline stay the meditation's own
        #expect(laid[0].audioUrl == "https://example.com/a.mp3")
        #expect(laid[0].author == "St. Alphonsus")
    }

    /// A translation that arrived with no text is no translation: the
    /// English stays, title and all
    @Test func anEmptySpanishTextKeepsTheEnglish() throws {
        let empty = [MeditationTranslation(id: 1, title: "La Anunciación", content: "", aiTranslated: true)]
        let laid = try #require(MeditationTranslation.overlay([meditation(1)], with: empty, spanish: true))
        #expect(laid == [meditation(1)])
        #expect(laid[0].isSpanish == false)
    }

    /// The tests run in English: a set is asked for exactly as before
    @Test func anEnglishAppAsksForNoLanguage() {
        #expect(!MeditationTranslation.isActive)
        #expect(MeditationTranslation.requestLanguage == nil)
    }

    @Test func aMeditationWithNoSpanishStaysEnglish() throws {
        let laid = try #require(MeditationTranslation.overlay([meditation(3)], with: spanish, spanish: true))
        #expect(laid[0] == meditation(3))
        #expect(!laid[0].isSpanish)
    }

    @Test func theSetDecodesTheSpanishAndKeepsBothOnDisk() throws {
        let json = """
            {"id": 48, "name": "St. Alphonsus", "category": "sevenSorrows", "description": null, "labels": ["Saints"],
             "meditations": [{"id": 1, "title": "The Prophecy", "content": "English", "audio_url": null}],
             "translations": [{"id": 1, "title": "La profecía", "content": "Español", "ai_translated": true}]}
            """
        let set = try JSONDecoder().decode(MeditationSet.self, from: Data(json.utf8))
        #expect(set.englishMeditations?.first?.content == "English")
        #expect(set.translations?.first?.title == "La profecía")
        let stored = try JSONDecoder().decode(MeditationSet.self, from: JSONEncoder().encode(set))
        #expect(stored.englishMeditations?.first?.content == "English")
        #expect(stored.translations?.first?.content == "Español")
    }

    @Test func aSetWithoutLangHasNoTranslations() throws {
        let json = """
            {"id": 7, "name": "Sheen", "category": "joyful", "description": null, "labels": null,
             "meditations": [{"id": 9, "title": null, "content": "English", "audio_url": null}]}
            """
        let set = try JSONDecoder().decode(MeditationSet.self, from: Data(json.utf8))
        #expect(set.translations == nil)
        #expect(set.meditations?.first?.content == "English")
    }

    @Test func theNoteUnderASpanishMeditation() {
        var marked = meditation(1)
        marked.isSpanish = true
        marked.aiTranslated = true
        #expect(
            MeditationLanguageNote.lines(for: marked) == [AITranslationNote.line, MeditationLanguageNote.voiceLine])

        var copiedSilent = meditation(2, audio: nil)
        copiedSilent.isSpanish = true
        #expect(MeditationLanguageNote.lines(for: copiedSilent).isEmpty)

        #expect(MeditationLanguageNote.lines(for: meditation(3)).isEmpty)
        #expect(MeditationLanguageNote.lines(for: nil).isEmpty)
    }

    @Test func theVoiceLineHasItsSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let es = try #require(Bundle(path: path))
        #expect(
            es.localizedString(forKey: "The voice reads the meditation in English.", value: nil, table: nil)
                == "La voz lee la meditación en inglés.")
    }
}

struct BundledMeditationSpanishTests {

    @Test func everyBundledMeditationHasItsSpanishAndNoOther() {
        let bundledIDs = Set(BundledMeditationSets.all.flatMap { $0.englishMeditations ?? [] }.map(\.id))
        let spanishIDs = MeditationTranslation.bundled.map(\.id)
        #expect(bundledIDs.count == 27)
        #expect(Set(spanishIDs) == bundledIDs)
        #expect(spanishIDs.count == Set(spanishIDs).count)
        let allWritten = MeditationTranslation.bundled.allSatisfy { !$0.content.isEmpty && $0.title == nil }
        #expect(allWritten)
    }

    @Test func onlyTheLuminousSetIsMarked() {
        let marked = Set(MeditationTranslation.bundled.filter { $0.aiTranslated == true }.map(\.id))
        let luminous = Set((LuminousMeditationData.set.englishMeditations ?? []).map(\.id))
        #expect(marked == luminous)
    }

    @Test func eachSetCarriesItsOwnSpanish() {
        for set in BundledMeditationSets.all {
            let own = Set((set.englishMeditations ?? []).map(\.id))
            #expect(Set((set.translations ?? []).map(\.id)) == own)
        }
    }

    @Test func aBundledSetReadsInSpanish() throws {
        let set = try #require(BundledMeditationSets.byID[SorrowfulEmmerichMeditationData.setID])
        let laid = try #require(MeditationTranslation.overlay(set.englishMeditations, with: set.translations, spanish: true))
        let allSpanish = laid.allSatisfy(\.isSpanish)
        #expect(allSpanish)
        // The reviewed correction of the 1865 print
        #expect(laid[0].content.contains("sobrenaturalmente"))
        #expect(laid[0].source?.contains("1865") == true)
        // English keeps its own words
        #expect(set.englishMeditations?[0].content == SorrowfulEmmerichMeditationData.set.englishMeditations?[0].content)
    }

    @Test func aMeditationWithNoSourceGetsNone() throws {
        let set = try #require(BundledMeditationSets.byID[LuminousMeditationData.setID])
        let laid = try #require(MeditationTranslation.overlay(set.englishMeditations, with: set.translations, spanish: true))
        let allMarkedWithNoSource = laid.allSatisfy { $0.source == nil && $0.aiTranslated }
        #expect(allMarkedWithNoSource)
    }
}

struct ConsecrationSpanishTests {

    private let document = """
        {"version": "abc", "updated_at": "2026-11-04T15:39:00Z",
         "translations": {
           "phases": [{"id": "preparatory", "name": "Días 1-12", "subtitle": "Desprenderse del mundo"}],
           "days": [{"number": 1, "title": "El espíritu del mundo", "journal_prompt": "¿Qué te ata al mundo?",
                     "ai_translated": true,
                     "readings": [{"order": 1, "title": "Mateo 5, 1-19", "text": "Viendo Jesús las gentes...",
                                   "source": "Biblia de Torres Amat"}]}],
           "prayers": [{"id": "veni_creator", "title": "Ven, Espíritu Creador", "text": "Ven, Espíritu Creador...",
                        "ai_translated": true}],
           "feasts": []}}
        """

    private func spanish() throws -> ConsecrationTranslations {
        try JSONDecoder().decode(ConsecrationTranslations.self, from: Data(document.utf8))
    }

    @Test func theApiShapeDecodesAndHoldsTogether() throws {
        let es = try spanish()
        #expect(es.version == "abc")
        #expect(es.days.count == 1)
        #expect(es.prayers.count == 1)
        #expect(es.problem == nil)
    }

    @Test func englishAsksForNothingAndDecodesEmpty() throws {
        let json = #"{"version": "x", "translations": {"phases": [], "days": [], "prayers": [], "feasts": []}}"#
        let es = try JSONDecoder().decode(ConsecrationTranslations.self, from: Data(json.utf8))
        #expect(es.days.isEmpty && es.prayers.isEmpty)
        #expect(es.problem == nil)
    }

    @Test func aDocumentThatDoesNotHoldTogetherIsRefused() {
        let twice = ConsecrationTranslations(days: [
            .init(number: 3, title: "a", journalPrompt: nil),
            .init(number: 3, title: "b", journalPrompt: nil),
        ])
        #expect(twice.problem != nil)
        #expect(ConsecrationTranslations(days: [.init(number: 40, title: "a", journalPrompt: nil)]).problem != nil)
    }

    @Test func theDayTakesItsSpanishByKey() throws {
        let english = try #require(ConsecrationData.day(1))
        let day = ConsecrationSpanish.vernacular(english, from: try spanish())
        #expect(day.title == "El espíritu del mundo")
        #expect(day.journalPrompt == "¿Qué te ata al mundo?")
        #expect(day.readings[0].title == "Mateo 5, 1-19")
        #expect(day.readings[0].source == "Biblia de Torres Amat")
        // A reading the Spanish does not list stays English, whole
        if english.readings.count > 1 {
            #expect(day.readings[1] == english.readings[1])
        }
        #expect(day.readings.count == english.readings.count)
    }

    /// Empty Spanish fields fall back to the English, field by field: a
    /// day's title and question, a reading, a prayer
    @Test func emptySpanishFallsBackToTheEnglish() throws {
        let json = """
            {"version": "e", "translations": {"phases": [], "feasts": [],
             "days": [{"number": 1, "title": "", "journal_prompt": "",
                       "readings": [{"order": 1, "title": "Mateo 5", "text": "", "source": "Torres Amat"}]}],
             "prayers": [{"id": "veni_creator", "title": "Ven, Espíritu Creador", "text": ""}]}}
            """
        let es = try JSONDecoder().decode(ConsecrationTranslations.self, from: Data(json.utf8))
        let english = try #require(ConsecrationData.day(1))
        let day = ConsecrationSpanish.vernacular(english, from: es)
        #expect(day.title == english.title)
        #expect(day.journalPrompt == english.journalPrompt)
        #expect(day.readings == english.readings)

        let prayer = ConsecrationPrayer(id: "veni_creator", title: "Come, Holy Ghost", latinTitle: "Veni Creator", content: "Come, Holy Ghost")
        #expect(ConsecrationSpanish.vernacular(prayer, from: es) == prayer)
    }

    @Test func aDayWithNoSpanishIsUnchanged() throws {
        let english = try #require(ConsecrationData.day(2))
        let es = try spanish()
        #expect(ConsecrationSpanish.vernacular(english, from: es) == english)
        #expect(ConsecrationSpanish.vernacular(english, from: ConsecrationTranslations()) == english)
    }

    @Test func theMarksAreRead() throws {
        let es = try spanish()
        #expect(ConsecrationSpanish.dayIsAITranslated(1, in: es))
        #expect(!ConsecrationSpanish.dayIsAITranslated(2, in: es))
        #expect(!ConsecrationSpanish.readingIsAITranslated(day: 1, order: 1, in: es))
        #expect(ConsecrationSpanish.prayerIsAITranslated("veni_creator", in: es))
    }

    @Test func aPrayerKeepsItsLatin() throws {
        let english = try #require(BilingualConsecrationPrayers.allPrayers["veni_creator"])
        let prayer = ConsecrationSpanish.vernacular(english, from: try spanish())
        #expect(prayer.englishTitle == "Ven, Espíritu Creador")
        #expect(prayer.content.english == "Ven, Espíritu Creador...")
        #expect(prayer.content.latin == english.content.latin)
        #expect(prayer.latinTitle == english.latinTitle)
        #expect(prayer.aiTranslated)
    }

    @Test func theTestsReadTheEnglish() {
        // The app hosting the tests reads nothing kept from the server
        #expect(LibraryContent.consecrationSpanish.days.isEmpty)
    }
}
