//
//  PrayerDayTests.swift
//  Lumen Viae Tests
//
//  The prayer day, which turns at four in the morning: the turn itself,
//  a Rosary said after midnight counting for the evening it closes, both
//  changes of the clocks, and streaks, the week row and the Pray button's
//  Continue built on it.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayerDayTests {

    /// A fixed calendar in a zone that changes its clocks, so the device's
    /// own settings never move a day. In 2026 New York springs forward at
    /// 2 AM on Sunday 8 March and falls back at 2 AM on Sunday 1 November.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 1
        return calendar
    }()

    private func moment(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func midnight(_ month: Int, _ day: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func prayerDay(of date: Date) -> Date {
        PrayerDay.day(of: date, calendar: calendar)
    }

    // MARK: - The Turn

    @Test func turnsAtFourNotMidnight() {
        #expect(PrayerDay.beginsAtHour == PrayerBook.dayBeginsAtHour)
        #expect(prayerDay(of: moment(10, 1, 3, 59)) == midnight(9, 30))
        #expect(prayerDay(of: moment(10, 1, 4, 0)) == midnight(10, 1))
        #expect(prayerDay(of: moment(10, 1, 23, 59)) == midnight(10, 1))
        #expect(prayerDay(of: moment(10, 2, 0, 0)) == midnight(10, 1))
    }

    @Test func halfPastTwelveCountsForTheEveningBefore() {
        // Wednesday 30 September, 12:30 AM: Tuesday's
        #expect(prayerDay(of: moment(9, 30, 0, 30)) == midnight(9, 29))
        #expect(PrayerDay.isSameDay(moment(9, 29, 21, 0), moment(9, 30, 0, 30), calendar: calendar))
        #expect(!PrayerDay.isSameDay(moment(9, 30, 0, 30), moment(9, 30, 4, 30), calendar: calendar))
    }

    @Test func todayIsTheDayBeforeUntilFour() {
        let late = moment(10, 2, 1, 15)
        #expect(PrayerDay.today(now: late, calendar: calendar) == midnight(10, 1))
        #expect(PrayerDay.isToday(midnight(10, 1), now: late, calendar: calendar))
        #expect(!PrayerDay.isToday(midnight(10, 2), now: late, calendar: calendar))
        // Any instant on the day's date names it
        #expect(PrayerDay.isToday(moment(10, 1, 12), now: late, calendar: calendar))
    }

    @Test func aDayRunsFromFourToFour() {
        let interval = PrayerDay.interval(of: midnight(10, 1), calendar: calendar)
        #expect(interval.start == moment(10, 1, 4))
        #expect(interval.end == moment(10, 2, 4))
        #expect(interval.duration == 24 * 3600)
    }

    @Test func nextTurnIsTheComingFour() {
        #expect(PrayerDay.nextTurn(after: moment(10, 1, 23), calendar: calendar) == moment(10, 2, 4))
        #expect(PrayerDay.nextTurn(after: moment(10, 2, 2), calendar: calendar) == moment(10, 2, 4))
        #expect(PrayerDay.nextTurn(after: moment(10, 2, 4), calendar: calendar) == moment(10, 3, 4))
    }

    // MARK: - The Clocks Changing

    @Test func springingForwardLeavesTheTurnAtFour() {
        // 2 AM does not happen on 8 March: 1:30 and 3:30 are both still
        // Saturday's, and four begins Sunday
        #expect(prayerDay(of: moment(3, 8, 1, 30)) == midnight(3, 7))
        #expect(prayerDay(of: moment(3, 8, 3, 30)) == midnight(3, 7))
        #expect(prayerDay(of: moment(3, 8, 4, 0)) == midnight(3, 8))

        let saturday = PrayerDay.interval(of: midnight(3, 7), calendar: calendar)
        #expect(saturday.start == moment(3, 7, 4))
        #expect(saturday.end == moment(3, 8, 4))
        #expect(saturday.duration == 23 * 3600)
        #expect(PrayerDay.nextTurn(after: moment(3, 8, 1, 30), calendar: calendar) == moment(3, 8, 4))
    }

    @Test func fallingBackLeavesTheTurnAtFour() {
        // 1:30 AM on 1 November happens twice; both are Saturday's
        let firstHalfPastOne = moment(11, 1, 1, 30)
        let secondHalfPastOne = firstHalfPastOne.addingTimeInterval(3600)
        #expect(calendar.component(.hour, from: secondHalfPastOne) == 1)
        #expect(prayerDay(of: firstHalfPastOne) == midnight(10, 31))
        #expect(prayerDay(of: secondHalfPastOne) == midnight(10, 31))
        #expect(prayerDay(of: moment(11, 1, 4, 0)) == midnight(11, 1))

        let saturday = PrayerDay.interval(of: midnight(10, 31), calendar: calendar)
        #expect(saturday.start == moment(10, 31, 4))
        #expect(saturday.end == moment(11, 1, 4))
        #expect(saturday.duration == 25 * 3600)
    }

    @Test func aStreakCrossesBothChangesOfTheClocks() {
        let spring = PrayerHistoryService.prayerDays(of: [
            moment(3, 7, 21), moment(3, 8, 21), moment(3, 9, 21)
        ], calendar: calendar)
        #expect(PrayerHistoryService.longestStreak(in: spring, calendar: calendar) == 3)

        let autumn = PrayerHistoryService.prayerDays(of: [
            moment(10, 31, 21), moment(11, 1, 21), moment(11, 2, 21)
        ], calendar: calendar)
        #expect(PrayerHistoryService.longestStreak(in: autumn, calendar: calendar) == 3)
        #expect(PrayerHistoryService.currentStreak(
            in: autumn, today: prayerDay(of: moment(11, 3, 1)), calendar: calendar
        ) == 3)
    }

    // MARK: - Streaks from Late Nights

    @Test func lateNightRosariesBuildAStreak() {
        // Each Rosary finished after midnight belongs to the evening
        // before: 1, 2 and 3 October, and one on the evening of the 4th
        let days = PrayerHistoryService.prayerDays(of: [
            moment(10, 2, 0, 30),
            moment(10, 3, 0, 45),
            moment(10, 4, 1, 10),
            moment(10, 4, 23, 0)
        ], calendar: calendar)
        #expect(days == [midnight(10, 1), midnight(10, 2), midnight(10, 3), midnight(10, 4)])

        let today = prayerDay(of: moment(10, 5, 1, 0))
        #expect(today == midnight(10, 4))
        #expect(PrayerHistoryService.currentStreak(in: days, today: today, calendar: calendar) == 4)
        #expect(PrayerHistoryService.longestStreak(in: days, calendar: calendar) == 4)

        // Counted at midnight, the same four Rosaries fall on three days
        let calendarDays = Set([
            moment(10, 2, 0, 30), moment(10, 3, 0, 45), moment(10, 4, 1, 10), moment(10, 4, 23, 0)
        ].map { calendar.startOfDay(for: $0) })
        #expect(calendarDays.count == 3)
    }

    @Test func twoRosariesEitherSideOfMidnightAreOneDay() {
        let days = PrayerHistoryService.prayerDays(of: [
            moment(10, 1, 23, 50), moment(10, 2, 0, 10)
        ], calendar: calendar)
        #expect(days == [midnight(10, 1)])
    }

    @Test func aStreakHoldsUntilFourTheMorningAfter() {
        let days = PrayerHistoryService.prayerDays(of: [moment(10, 1, 20)], calendar: calendar)

        // At three on the 3rd it is still the 2nd's day: nothing prayed
        // yet, and the 1st's prayer keeps the streak alive
        let beforeFour = prayerDay(of: moment(10, 3, 3))
        #expect(PrayerHistoryService.currentStreak(in: days, today: beforeFour, calendar: calendar) == 1)

        // At four the 3rd begins, and the 2nd went by
        let atFour = prayerDay(of: moment(10, 3, 4))
        #expect(PrayerHistoryService.currentStreak(in: days, today: atFour, calendar: calendar) == 0)
    }

    // MARK: - The Week Row

    @Test func halfPastTwelveOnSundayIsStillSaturdaysWeek() {
        // Sunday 4 October, 12:30 AM: Saturday the 3rd's day, in the week
        // of 27 September
        let days = PrayerHistoryService.prayerDays(of: [moment(10, 4, 0, 30)], calendar: calendar)
        let today = prayerDay(of: moment(10, 4, 0, 30))
        let week = PrayerHistoryService.weekStatus(in: days, today: today, calendar: calendar)

        #expect(week.count == 7)
        #expect(week.first?.date == midnight(9, 27))
        #expect(week.last?.date == midnight(10, 3))
        #expect(week.last?.didPray == true)
        #expect(week.dropLast().allSatisfy { !$0.didPray })
    }

    // MARK: - Continuing from the Pray Button

    @Test func aRosaryLeftBeforeMidnightIsStillContinuedAfterIt() {
        let left = InProgressPrayer(
            kind: .meditationSet,
            meditationSetId: 1,
            setName: "A Set",
            category: MysteryCategory.joyful.rawValue,
            mysteryIndex: 2,
            beadIndex: 0,
            startedAt: moment(10, 1, 23, 0),
            accumulatedSeconds: 600,
            savedAt: moment(10, 1, 23, 30)
        )
        #expect(left.isContinued(by: .todaysRosary, now: moment(10, 2, 0, 30), calendar: calendar))
        #expect(!left.isContinued(by: .todaysRosary, now: moment(10, 2, 4, 30), calendar: calendar))
    }
}
