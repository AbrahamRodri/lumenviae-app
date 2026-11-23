//
//  ShortCreditTests.swift
//  appTests
//
//  A long source is cut short under the prayer's title and given whole at
//  its foot, as the website sets it; a short one stands under the title
//  alone, and nothing is said twice.
//

import Foundation
import Testing

@testable import app

struct ShortCreditTests {

    @Test func aLongSourceIsShortUnderTheTitleAndWholeAtTheFoot() throws {
        let prayer = try #require(PrayerBook.prayer("st_joseph_novena"))
        let short = try #require(prayer.shortCredit)
        #expect(prayer.creditUnderTitle == short)
        #expect(prayer.creditAtFoot == prayer.origin)
        #expect((prayer.origin ?? "").count > short.count)
    }

    @Test func anOriginWithNoAuthorStandsAtTheFootAlone() throws {
        let prayer = try #require(PrayerBook.prayer("memorare"))
        #expect(prayer.shortCredit == nil)
        #expect(prayer.creditUnderTitle == nil)
        #expect(prayer.creditAtFoot == prayer.origin)
    }

    @Test func theDocumentReadsTheShortCredit() throws {
        let json = #"{"id":"x","title":"X","english":"Amen.","origin":"A long source","short_credit":"Short"}"#
        let prayer = try JSONDecoder().decode(PrayerBookDocument.Prayer.self, from: Data(json.utf8))
        #expect(prayer.shortCredit == "Short")
        let without = #"{"id":"x","title":"X","english":"Amen."}"#
        #expect(try JSONDecoder().decode(PrayerBookDocument.Prayer.self, from: Data(without.utf8)).shortCredit == nil)
    }

    /// Only a real author is credited under the title (api #290): the four
    /// novenas whose author is named (the Undoer of Knots, a fifth, was
    /// taken off for copyright on 23 Nov 2026)
    @Test func fourPrayersCarryAShortCredit() {
        let carrying = LibraryContent.prayerBook.prayers.filter { $0.shortCredit != nil }
        #expect(
            Set(carrying.map(\.id)) == [
                "efficacious_novena", "st_therese_novena", "holy_spirit_novena",
                "st_joseph_novena",
            ])
        #expect(carrying.allSatisfy { ($0.origin ?? "").count > ($0.shortCredit ?? "").count })
    }
}
