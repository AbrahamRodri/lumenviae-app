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

    /// A Spanish row with no flag of its own shows its source, whatever its
    /// English twin says: a missing flag never hides a credit
    @Test func aSpanishRowWithoutAFlagShowsItsSource() {
        var translation = PrayerBookTranslations.Translation(
            id: "test_prayer", title: "Título", text: "Amén.", aiTranslated: nil)
        translation.origin = "Iglesia de Occidente, siglos XIII a XVI"
        let english = prayer(origin: "Western Church · 13th–16th century", originCredit: false)
        let spanish = PrayerBook.inSpanish(english, translations: ["test_prayer": translation], spanish: true)
        #expect(spanish.creditAtFoot == translation.origin)
        translation.originCredit = false
        let flagged = PrayerBook.inSpanish(english, translations: ["test_prayer": translation], spanish: true)
        #expect(flagged.creditAtFoot == nil)
    }

    /// A Spanish origin can credit the book its Spanish wording comes from
    /// where the English origin is only a tradition and a century
    @Test func aSpanishOriginsOwnFlagComesFirst() throws {
        var translation = PrayerBookTranslations.Translation(
            id: "test_prayer", title: "Título", text: "Amén.", aiTranslated: nil)
        translation.origin = "Tradición de la Iglesia · según el Compendio del Catecismo"
        translation.originCredit = true
        let english = prayer(origin: "Western Church · 13th–16th century", originCredit: false)
        let spanish = PrayerBook.inSpanish(english, translations: ["test_prayer": translation], spanish: true)
        #expect(spanish.creditAtFoot == translation.origin)
        let json = #"{"id":"x","title":"X","text":"Amén.","origin":"según","origin_credit":true}"#
        let decoded = try JSONDecoder().decode(PrayerBookTranslations.Translation.self, from: Data(json.utf8))
        #expect(decoded.originCredit == true)
    }

    // MARK: - The shipped book

    @Test func theAngelusAndTheLitanyOfLoretoHaveNoFoot() throws {
        for id in ["angelus", "litany_loreto"] {
            let prayer = try #require(PrayerBook.prayer(id))
            #expect(prayer.originCredit == false)
            #expect(prayer.creditAtFoot == nil)
            #expect(prayer.origin != nil)
        }
    }

    @Test func aCreditedPrayerKeepsItsFoot() throws {
        let prayer = try #require(PrayerBook.prayer("st_joseph_novena"))
        #expect(prayer.originCredit == true)
        #expect(prayer.creditAtFoot == prayer.origin)
    }

    @Test func undoerOfKnotsNamesItsAuthorUnderTheTitle() throws {
        let prayer = try #require(PrayerBook.prayer("undoer_of_knots_novena"))
        #expect(prayer.creditUnderTitle == "Fr. Juan Ramón Celeiro")
        #expect(prayer.creditAtFoot == prayer.origin)
    }

    @Test func everyPrayerInTheShippedBookSaysWhetherItsOriginIsACredit() {
        #expect(LibraryContent.prayerBook.prayers.allSatisfy { $0.originCredit != nil })
    }
}
