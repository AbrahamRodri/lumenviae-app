//
//  ReadingDayMeterTests.swift
//  Lumen Viae Tests
//
//  The day's reading measure: minutes with a reader open, chapters read
//  to their end, a goal line that never counts past the goal, a day's
//  figures let go when the day is over, and the stored measures read
//  whether they were saved as slugs or as their old sentences.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ReadingDayMeterTests {

    /// A clock the test moves by hand
    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    private let clock = Clock(Calendar.current.date(
        from: DateComponents(year: 2026, month: 10, day: 3, hour: 9))!)

    private func meter(_ defaults: UserDefaults? = nil) -> ReadingDayMeter {
        ReadingDayMeter(
            defaults: defaults ?? UserDefaults(suiteName: "ReadingDayMeterTests.\(UUID().uuidString)")!,
            now: { [clock] in clock.now }
        )
    }

    // MARK: - Minutes

    @Test func minutesCountWhileAReaderIsOpenAndStopWhenPaused() {
        let meter = meter()
        meter.enterReader()
        clock.now += 6 * 60
        #expect(meter.minutesToday == 6)
        meter.pause()
        clock.now += 60 * 60
        #expect(meter.minutesToday == 6)
    }

    @Test func resumeReArmsOnlyWhileAReaderIsOpen() {
        let meter = meter()
        meter.resume()
        clock.now += 10 * 60
        #expect(meter.minutesToday == 0)

        meter.enterReader()
        meter.pause()
        clock.now += 30 * 60
        meter.resume()
        clock.now += 4 * 60
        #expect(meter.minutesToday == 4)
    }

    @Test func aClockSetBackNeverCountsNegativeMinutes() {
        let meter = meter()
        meter.enterReader()
        clock.now -= 10 * 60
        #expect(meter.minutesToday == 0)
    }

    @Test func theGoalLineNeverCountsPastTheGoal() {
        let meter = meter()
        meter.enterReader()
        clock.now += 40 * 60
        #expect(meter.goalLine(for: .quarterHour) == "A quarter-hour of reading · 15 of 15 minutes so far")
        #expect(meter.fraction(toward: .quarterHour) == 1)
        #expect(meter.fraction(toward: .fewMinutes) == 1)
    }

    // MARK: - Chapters

    @Test func theChapterMeasureCountsChaptersReadToTheirEnd() {
        let meter = meter()
        #expect(meter.goalLine(for: .chapterADay) == "A chapter a day · not yet today")
        #expect(meter.fraction(toward: .chapterADay) == 0)
        meter.noteChapterFinished()
        #expect(meter.goalLine(for: .chapterADay) == "A chapter a day · one read today")
        meter.noteChapterFinished()
        #expect(meter.goalLine(for: .chapterADay) == "A chapter a day · 2 read today")
        #expect(meter.fraction(toward: .chapterADay) == 1)
    }

    // MARK: - The day

    @Test func yesterdaysFiguresAreLetGo() {
        let meter = meter()
        meter.noteChapterFinished()
        meter.enterReader()
        clock.now += 20 * 60
        meter.pause()
        clock.now += 24 * 60 * 60
        #expect(meter.chaptersToday == 0)
        #expect(meter.minutesToday == 0)
    }

    @Test func theDaysFiguresOutliveTheMeter() {
        let defaults = UserDefaults(suiteName: "ReadingDayMeterTests.\(UUID().uuidString)")!
        let first = meter(defaults)
        first.noteChapterFinished()
        first.enterReader()
        clock.now += 7 * 60
        first.pause()

        let again = meter(defaults)
        #expect(again.chaptersToday == 1)
        #expect(again.minutesToday == 7)
    }

    // MARK: - The stored measure

    @Test func aStoredMeasureIsReadAsASlugOrAsItsOldSentence() {
        for goal in ReadingGoal.allCases {
            #expect(ReadingGoal.stored(goal.rawValue) == goal)
            #expect(ReadingGoal.stored(goal.title) == goal)
        }
        #expect(ReadingGoal.stored("an hour a day") == nil)
    }

    @Test func onlyTheChapterMeasureHasNoMinutes() {
        #expect(ReadingGoal.allCases.filter { $0.minutes == nil } == [.chapterADay])
    }
}
