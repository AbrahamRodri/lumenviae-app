//
//  OriginCreditTests.swift
//  appTests
//
//  A prayer's foot names its source only where the source credits someone
//  or something real; a tradition and a century alone is not said on the
//  page (Abraham, 17 Nov 2026). The book says which (`origin_credit`, api
//  #290), and a Spanish prayer follows its English twin.
//

import Foundation
import Testing

@testable import app

struct OriginCreditTests {

    private func prayer(origin: String?, originCredit: Bool?) -> BookPrayer {
        BookPrayer(
            id: "test_prayer", title: "Title", latinTitle: nil, origin: origin, originCredit: originCredit,
            note: nil, english: "Amen.", latin: nil)
    }

    @Test func aCreditStandsAtTheFoot() {
        let credited = prayer(origin: "Fr. Lawrence G. Lovasik, S.V.D. · as printed by EWTN", originCredit: true)
        #expect(credited.creditAtFoot == credited.origin)
    }

    @Test func aTraditionAndACenturyAloneIsNotSaid() {
        let tradition = prayer(origin: "Western Church · 13th–16th century", originCredit: false)
        #expect(tradition.creditAtFoot == nil)
        // The origin itself is kept, for the Sources page and the share text
        #expect(tradition.origin == "Western Church · 13th–16th century")
    }

    @Test func aBookFromBeforeTheFlagKeepsTheFoot() {
        let older = prayer(origin: "St Bernard of Clairvaux · 12th century", originCredit: nil)
        #expect(older.creditAtFoot == older.origin)
    }

    @Test func theDocumentReadsTheFlag() throws {
        let json = #"{"id":"x","title":"X","english":"Amen.","origin":"Western Church","origin_credit":false}"#
        let decoded = try JSONDecoder().decode(PrayerBookDocument.Prayer.self, from: Data(json.utf8))
        #expect(decoded.originCredit == false)
        let without = #"{"id":"x","title":"X","english":"Amen."}"#
        #expect(try JSONDecoder().decode(PrayerBookDocument.Prayer.self, from: Data(without.utf8)).originCredit == nil)
        let again = try JSONDecoder().decode(
            PrayerBookDocument.Prayer.self, from: JSONEncoder().encode(decoded))
        #expect(again.originCredit == false)
    }

    @Test func spanishFollowsItsEnglishTwin() {
        var translation = PrayerBookTranslations.Translation(
            id: "test_prayer", title: "Título", text: "Amén.", aiTranslated: nil)
        translation.origin = "Iglesia de Occidente, siglos XIII a XVI"
        let english = prayer(origin: "Western Church · 13th–16th century", originCredit: false)
        let spanish = PrayerBook.inSpanish(english, translations: ["test_prayer": translation], spanish: true)
        #expect(spanish.origin == translation.origin)
        #expect(spanish.creditAtFoot == nil)
        let credited = PrayerBook.inSpanish(
            prayer(origin: "Fr. Juan Ramón Celeiro", originCredit: true),
            translations: ["test_prayer": translation], spanish: true)
        #expect(credited.creditAtFoot == translation.origin)
    }
}
