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

    private func translation(origin: String, foot: String?) -> PrayerBookTranslations.Translation {
        var translation = PrayerBookTranslations.Translation(
            id: "test_prayer", title: "Título", text: "Amén.", aiTranslated: nil)
        translation.origin = origin
        translation.footCredit = foot
        return translation
    }

    /// The Spanish foot is the book's own line: the source of the Spanish
    /// wording alone where only that is a credit
    @Test func theSpanishFootIsTheBooksOwnLine() {
        let english = prayer(origin: "Western Church · 13th–16th century", originCredit: false)
        let angelus = translation(
            origin: "Iglesia de Occidente, siglos XIII a XVI · según el Compendio del Catecismo de la Iglesia Católica",
            foot: "Según el Compendio del Catecismo de la Iglesia Católica")
        let spanish = PrayerBook.inSpanish(english, translations: ["test_prayer": angelus], spanish: true)
        #expect(spanish.creditAtFoot == "Según el Compendio del Catecismo de la Iglesia Católica")
    }

    /// Where the book gives Spanish foot lines, a translation without one
    /// has no foot (the team's own translations)
    @Test func aTeamTranslationHasNoFoot() {
        let english = prayer(origin: "Western Church · 9th century", originCredit: false)
        let team = translation(origin: "Iglesia de Occidente, siglo IX · traducción del equipo", foot: nil)
        let other = translation(origin: "La Misa · según Lefebvre", foot: "La Misa · según Lefebvre")
        let spanish = PrayerBook.inSpanish(
            english, translations: ["test_prayer": team, "other": other], spanish: true)
        #expect(spanish.creditAtFoot == nil)
    }

    /// A book from before the Spanish foot lines shows the whole Spanish
    /// origin, whatever the English twin says: a missing field never hides a credit
    @Test func aBookFromBeforeTheSpanishFootLinesShowsTheSource() {
        let english = prayer(origin: "Western Church · 13th–16th century", originCredit: false)
        let older = translation(origin: "Iglesia de Occidente · según el Compendio", foot: nil)
        let spanish = PrayerBook.inSpanish(english, translations: ["test_prayer": older], spanish: true)
        #expect(spanish.creditAtFoot == "Iglesia de Occidente · según el Compendio")
    }

    @Test func theSpanishDocumentReadsTheFootLine() throws {
        let json = #"{"id":"x","title":"X","text":"Amén.","origin":"o","foot_credit":"Según el Compendio"}"#
        let decoded = try JSONDecoder().decode(PrayerBookTranslations.Translation.self, from: Data(json.utf8))
        #expect(decoded.footCredit == "Según el Compendio")
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
