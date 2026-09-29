//
//  ScheduleSeasonTests.swift
//  Lumen Viae Tests
//
//  The seasons the Sunday mysteries follow, computed on device: Easter
//  by the Meeus/Jones/Butcher rule, Lent from Ash Wednesday up to
//  Easter, Advent from the Sunday on or after November 27 through
//  December 24. The dates are the Church's published ones; the server's
//  `LumenViae.LiturgicalCalendar` must agree with every one of them.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ScheduleSeasonTests {

    /// A fixed calendar, so the device's own settings never move a day
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func season(_ year: Int, _ month: Int, _ day: Int) -> ScheduleService.Season {
        ScheduleService.season(for: self.day(year, month, day, hour: 12), calendar: calendar)
    }

    // MARK: - Easter

    @Test(arguments: [
        (1943, 4, 25),  // the latest Easter can fall
        (1961, 4, 2),
        (2000, 4, 23),
        (2008, 3, 23),
        (2019, 4, 21),
        (2024, 3, 31),
        (2025, 4, 20),
        (2026, 4, 5),
        (2027, 3, 28),
        (2038, 4, 25),
        (2285, 3, 22),  // the earliest, next after 1818
    ])
    func easterFallsOnTheChurchsDate(year: Int, month: Int, day: Int) {
        #expect(ScheduleService.easterSunday(year: year, calendar: calendar) == self.day(year, month, day))
    }

    @Test func easterIsAlwaysASundayBetweenMarch22AndApril25() {
        for year in 1900...2100 {
            let easter = ScheduleService.easterSunday(year: year, calendar: calendar)!
            #expect(calendar.component(.weekday, from: easter) == 1, "Easter \(year) is not a Sunday")
            #expect(easter >= day(year, 3, 22) && easter <= day(year, 4, 25), "Easter \(year) is out of range")
        }
    }

    // MARK: - Ash Wednesday

    @Test(arguments: [
        (2024, 2, 14),
        (2025, 3, 5),
        (2026, 2, 18),
        (2027, 2, 10),
    ])
    func ashWednesdayFallsOnTheChurchsDate(year: Int, month: Int, day: Int) {
        let ash = ScheduleService.ashWednesday(year: year, calendar: calendar)
        #expect(ash == self.day(year, month, day))
        #expect(ash.map { calendar.component(.weekday, from: $0) } == 4)
    }

    // MARK: - Advent

    @Test(arguments: [
        (2021, 11, 28),
        (2022, 11, 27),  // November 27 is itself a Sunday
        (2023, 12, 3),   // as late as Advent begins
        (2024, 12, 1),
        (2025, 11, 30),
        (2026, 11, 29),
        (2027, 11, 28),
    ])
    func adventBeginsOnTheSundayOnOrAfterNovember27(year: Int, month: Int, day: Int) {
        let start = ScheduleService.adventStart(year: year, calendar: calendar)
        #expect(start == self.day(year, month, day))
        #expect(start.map { calendar.component(.weekday, from: $0) } == 1)
    }

    // MARK: - The Seasons' Bounds

    @Test func lentRunsFromAshWednesdayUpToEaster() {
        #expect(season(2026, 2, 17) == .ordinary)   // Shrove Tuesday
        #expect(season(2026, 2, 18) == .lent)       // Ash Wednesday
        #expect(season(2026, 3, 29) == .lent)       // Palm Sunday
        #expect(season(2026, 4, 4) == .lent)        // Holy Saturday
        #expect(season(2026, 4, 5) == .ordinary)    // Easter Sunday
    }

    @Test func adventRunsFromItsFirstSundayThroughChristmasEve() {
        #expect(season(2026, 11, 28) == .ordinary)
        #expect(season(2026, 11, 29) == .advent)
        #expect(season(2026, 12, 24) == .advent)
        #expect(season(2026, 12, 25) == .ordinary)  // Christmastide counts as ordinary here
    }

    @Test func aSeasonTurnsAtMidnightNotAtNoon() {
        let ashEve = calendar.date(from: DateComponents(year: 2026, month: 2, day: 17, hour: 23, minute: 59))!
        let ashMorning = calendar.date(from: DateComponents(year: 2026, month: 2, day: 18, hour: 0, minute: 1))!
        #expect(ScheduleService.season(for: ashEve, calendar: calendar) == .ordinary)
        #expect(ScheduleService.season(for: ashMorning, calendar: calendar) == .lent)
    }
}
