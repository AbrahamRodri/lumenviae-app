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

    @Test func aShortSourceStandsUnderTheTitleAlone() throws {
        let prayer = try #require(PrayerBook.prayer("memorare"))
        #expect(prayer.shortCredit == nil)
        #expect(prayer.creditUnderTitle == prayer.origin)
        #expect(prayer.creditAtFoot == nil)
    }

    @Test func theDocumentReadsTheShortCredit() throws {
        let json = #"{"id":"x","title":"X","english":"Amen.","origin":"A long source","short_credit":"Short"}"#
        let prayer = try JSONDecoder().decode(PrayerBookDocument.Prayer.self, from: Data(json.utf8))
        #expect(prayer.shortCredit == "Short")
        let without = #"{"id":"x","title":"X","english":"Amen."}"#
        #expect(try JSONDecoder().decode(PrayerBookDocument.Prayer.self, from: Data(without.utf8)).shortCredit == nil)
    }

    @Test func elevenPrayersCarryAShortCredit() {
        let carrying = LibraryContent.prayerBook.prayers.filter { $0.shortCredit != nil }
        #expect(carrying.count == 11)
        #expect(carrying.allSatisfy { ($0.origin ?? "").count > ($0.shortCredit ?? "").count })
    }
}
