//
//  AdventPrayerPlaceTests.swift
//  Lumen Viae Tests
//
//  The O Antiphons open at today's antiphon and the Advent wreath's
//  collects at this week's Sunday, in every language the page sets them
//  in, and both open at the top out of season.
//

import Foundation
import Testing

@testable import app

@MainActor
struct AdventPrayerPlaceTests {

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 20)))
    }

    private func stanzas(_ id: String, _ language: PrayerLanguage) throws -> [String] {
        let prayer = try #require(PrayerBook.prayer(id))
        return PrayAlongView.stanzas(prayer.content(for: language))
    }

    @Test(arguments: [PrayerLanguage.english, .latin, .both, .latinUnderEnglish])
    func theAntiphonsOpenAtTodaysAntiphon(_ language: PrayerLanguage) throws {
        let text = try stanzas(AdventPrayerPlace.antiphonsID, language)
        for date in 17...23 {
            let place = try #require(
                AdventPrayerPlace.stanza(of: AdventPrayerPlace.antiphonsID, in: text, on: try day(2026, 12, date)))
            #expect(AdventPrayerPlace.isHeading(text[place]))
            // The antiphon under the heading is the day's: the 18th is O Adonai
            if date == 18 { #expect(text[place + 1].contains("Adonai")) }
            if date == 21 { #expect(text[place + 1].contains("Day-Spring") || text[place + 1].contains("Oriens")) }
        }
    }

    @Test func theAntiphonsOpenAtTheTopOutOfTheirDays() throws {
        let text = try stanzas(AdventPrayerPlace.antiphonsID, .english)
        for date in [try day(2026, 12, 16), try day(2026, 12, 24), try day(2026, 6, 18)] {
            #expect(AdventPrayerPlace.stanza(of: AdventPrayerPlace.antiphonsID, in: text, on: date) == nil)
        }
    }

    @Test func theCollectsOpenAtThisWeeksSunday() throws {
        let text = try stanzas(AdventPrayerPlace.wreathID, .english)
        // Advent 2026 begins Sunday 29 November
        let weeks: [(Date, String)] = [
            (try day(2026, 11, 29), "First Sunday"),
            (try day(2026, 12, 5), "First Sunday"),
            (try day(2026, 12, 6), "Second Sunday"),
            (try day(2026, 12, 13), "Third Sunday"),
            (try day(2026, 12, 20), "Fourth Sunday"),
            (try day(2026, 12, 24), "Fourth Sunday"),
        ]
        for (date, sunday) in weeks {
            let place = try #require(AdventPrayerPlace.stanza(of: AdventPrayerPlace.wreathID, in: text, on: date))
            #expect(text[place].contains(sunday), "\(date)")
        }
    }

    @Test func theCollectsOpenAtTheTopOutsideAdvent() throws {
        let text = try stanzas(AdventPrayerPlace.wreathID, .english)
        for date in [try day(2026, 11, 28), try day(2026, 12, 25)] {
            #expect(AdventPrayerPlace.stanza(of: AdventPrayerPlace.wreathID, in: text, on: date) == nil)
        }
    }

    @Test func anyOtherPrayerOpensAtTheTop() throws {
        let text = try stanzas("memorare", .english)
        #expect(AdventPrayerPlace.stanza(of: "memorare", in: text, on: try day(2026, 12, 18)) == nil)
    }
}
