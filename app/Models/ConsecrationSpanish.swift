//
//  ConsecrationSpanish.swift
//  app
//
//  The Consecration in a Spanish app: the server's Spanish
//  (`LibraryContent.consecrationSpanish`, from
//  `GET /api/v2/consecration?lang=es`) laid over the bundled English by key.
//  A day's title and journal question, each of its readings by order, and
//  each prayer by id; whatever has no Spanish, or the whole document while
//  the server has sent none, stays English as it is today. The Latin is
//  never touched. Nothing here is narrated.
//

import Foundation

enum ConsecrationSpanish {

    // MARK: - Days

    /// The day as a Spanish app shows it
    static func vernacular(
        _ day: ConsecrationDay,
        from spanish: ConsecrationTranslations = LibraryContent.consecrationSpanish
    ) -> ConsecrationDay {
        guard let es = spanish.dayByNumber[day.dayNumber] else { return day }
        let readings = Dictionary(es.readings.map { ($0.order, $0) }, uniquingKeysWith: { first, _ in first })
        return ConsecrationDay(
            dayNumber: day.dayNumber,
            phase: day.phase,
            title: nonEmpty(es.title) ?? day.title,
            readings: day.readings.map { reading in
                // A reading is Spanish whole, citation, text and edition,
                // or English whole
                guard let es = readings[reading.order], !es.text.isEmpty else { return reading }
                return ConsecrationReading(order: reading.order, title: es.title, text: es.text, source: es.source)
            },
            journalPrompt: nonEmpty(es.journalPrompt) ?? day.journalPrompt
        )
    }

    /// Whether a day's title and journal question are the team's
    /// translation
    static func dayIsAITranslated(
        _ number: Int, in spanish: ConsecrationTranslations = LibraryContent.consecrationSpanish
    ) -> Bool {
        spanish.dayByNumber[number]?.aiTranslated == true
    }

    /// Whether a reading's Spanish is the team's translation
    static func readingIsAITranslated(
        day number: Int, order: Int, in spanish: ConsecrationTranslations = LibraryContent.consecrationSpanish
    ) -> Bool {
        spanish.dayByNumber[number]?.readings.first(where: { $0.order == order })?.aiTranslated == true
    }

    // MARK: - Prayers

    /// A prayer with Latin, its Spanish in English's place
    static func vernacular(
        _ prayer: BilingualConsecrationPrayer,
        from spanish: ConsecrationTranslations = LibraryContent.consecrationSpanish
    ) -> BilingualConsecrationPrayer {
        guard let es = spanish.prayerByID[prayer.id], !es.text.isEmpty else { return prayer }
        var swapped = BilingualConsecrationPrayer(
            id: prayer.id,
            englishTitle: es.title,
            latinTitle: prayer.latinTitle,
            englishContent: es.text,
            latinContent: prayer.content.latin
        )
        swapped.aiTranslated = es.aiTranslated == true
        return swapped
    }

    /// A prayer in English alone, its Spanish in its place
    static func vernacular(
        _ prayer: ConsecrationPrayer,
        from spanish: ConsecrationTranslations = LibraryContent.consecrationSpanish
    ) -> ConsecrationPrayer {
        guard let es = spanish.prayerByID[prayer.id], !es.text.isEmpty else { return prayer }
        return ConsecrationPrayer(id: prayer.id, title: es.title, latinTitle: prayer.latinTitle, content: es.text)
    }

    /// Whether a prayer's Spanish is the team's translation
    static func prayerIsAITranslated(
        _ id: String, in spanish: ConsecrationTranslations = LibraryContent.consecrationSpanish
    ) -> Bool {
        spanish.prayerByID[id]?.aiTranslated == true
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return text
    }
}
