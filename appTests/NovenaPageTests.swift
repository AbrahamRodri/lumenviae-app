//
//  NovenaPageTests.swift
//  Lumen Viae
//
//  The novena page's own rules: what Begin tomorrow begins, each day's
//  state on its row, and the sentence over the days left open.
//

import Foundation
import Testing

@testable import app

@MainActor
struct NovenaPageTests {

    private func at(_ hour: Int, _ minute: Int = 0, day: Int = 14) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    /// Begin tomorrow begins on tomorrow's prayer day at any hour: its
    /// midnight once named today, since the day turns at four
    @Test(arguments: [1, 9, 15, 21, 23])
    func beginTomorrowBeginsTomorrow(hour: Int) {
        let now = at(hour)
        let start = NovenaPageView.tomorrowsStart(after: now)
        let progress = NovenaProgress(novenaID: "n", length: 9, beginning: start)
        #expect(progress.dayNumber(on: now) == 0)
        #expect(
            progress.dayNumber(on: PrayerDay.adding(days: 1, to: PrayerDay.day(of: now)).addingTimeInterval(13 * 3600))
                == 1)
        if case .underWay(let today, let open) = progress.standing(on: now) {
            #expect(today == nil)
            #expect(open.isEmpty)
        } else {
            Issue.record("a novena set to begin tomorrow stands under way, with nothing to pray today")
        }
    }

    @Test func eachDayHasItsState() {
        var progress = NovenaProgress(novenaID: "n", length: 9, beginning: at(12, day: 11))
        progress.markPrayed(1)
        progress.markPrayed(2)
        let now = at(18, day: 14)  // Day 4
        #expect(NovenaPageView.dayState(1, progress: progress, now: now) == .prayed)
        #expect(NovenaPageView.dayState(3, progress: progress, now: now) == .open)
        #expect(NovenaPageView.dayState(4, progress: progress, now: now) == .today)
        #expect(NovenaPageView.dayState(5, progress: progress, now: now) == .ahead)
        #expect(NovenaPageView.dayState(4, progress: nil, now: now) == .none)
    }

    @Test func theOpenDaysAreSaidInOneSentence() {
        #expect(
            NovenaPageView.openSentence([3], next: 4)
                == "Day 3 is still open. You can pray it now, or go on with Day 4.")
        #expect(NovenaPageView.openSentence([3], next: nil) == "Day 3 is still open. You can pray it now.")
        #expect(
            NovenaPageView.openSentence([3, 4], next: 5)
                == "Days 3 and 4 are still open. You can pray them now, or go on with Day 5.")
    }

    /// No dash is today's before Day 1, nor in Welcome back, whose card
    /// names the day she was on
    @Test func noDashIsTodaysBeforeDayOneOrInWelcomeBack() {
        let now = at(18)
        let tomorrow = NovenaProgress(
            novenaID: "n", length: 9, beginning: NovenaPageView.tomorrowsStart(after: now))
        #expect(NovenaPageView.hereDay(tomorrow, length: 9, on: now) == 0)

        var away = NovenaProgress(novenaID: "n", length: 9, beginning: at(12, day: 9))
        away.markPrayed(1)
        away.markPrayed(2)
        #expect(NovenaPageView.isWelcomeBack(away, on: now))
        #expect(NovenaPageView.hereDay(away, length: 9, on: now) == 0)

        var underWay = NovenaProgress(novenaID: "n", length: 9, beginning: at(12, day: 11))
        for day in 1...3 { underWay.markPrayed(day) }
        #expect(NovenaPageView.hereDay(underWay, length: 9, on: now) == 4)
    }
}
