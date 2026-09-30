//
//  TodaysMysteriesGlyphTests.swift
//  Lumen Viae Tests
//
//  Today's Mysteries wears the day's mysteries' own emblem, as the
//  schedule chosen and the season on a Sunday name them; every other act
//  keeps its own sign, whatever the day.
//

import Foundation
import Testing
@testable import app

@MainActor
struct TodaysMysteriesGlyphTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func glyph(on date: Date, _ schedule: MysterySchedule) -> String {
        PrayerShortcut.chooseMeditation.icon(
            today: ScheduleService.category(for: date, calendar: calendar, schedule: schedule)
        )
    }

    @Test func wearsTheDaysOwnEmblem() {
        for category in MysteryCategory.allCategories {
            #expect(PrayerShortcut.chooseMeditation.icon(today: category) == category.iconName, "\(category)")
        }
    }

    @Test func everyOtherActKeepsItsOwnSign() {
        for shortcut in PrayerShortcut.allCases where shortcut != .chooseMeditation {
            let glyphs = Set(MysteryCategory.allCategories.map { shortcut.icon(today: $0) })
            #expect(glyphs.count == 1, "\(shortcut) changed with the day")
        }
    }

    /// Thursday 1 and Saturday 3 October 2026: the two days the schedules part
    @Test func followsTheScheduleChosen() {
        let thursday = day(2026, 10, 1), saturday = day(2026, 10, 3)
        #expect(glyph(on: thursday, .traditional) == "lv-star")
        #expect(glyph(on: thursday, .modern) == "lv-jordan")
        #expect(glyph(on: saturday, .traditional) == "lv-banner")
        #expect(glyph(on: saturday, .modern) == "lv-star")
    }

    /// A Sunday in Ordinary Time, the first of Advent 2026, and one in the
    /// Lent of 2027
    @Test(arguments: MysterySchedule.allCases)
    func aSundayFollowsTheSeason(_ schedule: MysterySchedule) {
        #expect(glyph(on: day(2026, 10, 4), schedule) == "lv-banner")
        #expect(glyph(on: day(2026, 11, 29), schedule) == "lv-star")
        #expect(glyph(on: day(2027, 3, 7), schedule) == "lv-crown-of-thorns")
    }
}
