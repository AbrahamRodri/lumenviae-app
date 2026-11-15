//
//  SpanishShortCreditTests.swift
//  appTests
//
//  In Spanish a long source is cut short under the title and given whole
//  at the foot, as English does (api #277); a Spanish origin with no
//  short credit stands under the title alone.
//

import Foundation
import Testing

@testable import app

struct SpanishShortCreditTests {

    private var translations: [String: PrayerBookTranslations.Translation] {
        guard let url = Bundle.main.url(forResource: "prayer_book.es", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let book = try? JSONDecoder().decode(PrayerBookTranslations.self, from: data)
        else { return [:] }
        return Dictionary(book.translations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    @Test func aLongSpanishSourceIsShortUnderTheTitleAndWholeAtTheFoot() throws {
        let english = try #require(PrayerBook.prayer("efficacious_novena"))
        let spanish = PrayerBook.inSpanish(english, translations: translations, spanish: true)
        let short = try #require(spanish.shortCredit)
        #expect(spanish.creditUnderTitle == short)
        #expect(spanish.creditAtFoot == spanish.origin)
        #expect(short != english.shortCredit)
    }

    @Test func theShippedCopyCarriesSeventeen() {
        #expect(translations.values.filter { $0.shortCredit != nil }.count == 17)
    }

    @Test func aTranslationWithoutOneDecodes() throws {
        let json = #"{"id":"x","title":"X","text":"Amén.","origin":"Breve"}"#
        let translation = try JSONDecoder().decode(PrayerBookTranslations.Translation.self, from: Data(json.utf8))
        #expect(translation.shortCredit == nil)
    }
}
