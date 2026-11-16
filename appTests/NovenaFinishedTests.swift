//
//  NovenaFinishedTests.swift
//  appTests
//
//  A finished novena says when it was prayed (design's FINISHED.md, 16 Nov
//  2026): Day 1's and the last day's own dates, kept through a pick-up,
//  and counted back for a history entry kept before they were.
//

import Foundation
import Testing

@testable import app

@Suite("A finished novena")
@MainActor
struct NovenaFinishedTests {
    private let calendar = Calendar.current

    private func date(_ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func store() -> NovenaStore {
        let defaults = UserDefaults(suiteName: "novena-finished-\(UUID().uuidString)")!
        return NovenaStore(defaults: defaults, schedulesNotifications: false)
    }

    @Test func theDatesReadAsOneSpan() {
        #expect(NovenaSpan.range(from: date(11, 16), to: date(11, 24), calendar: calendar) == "November 16 to 24")
        #expect(
            NovenaSpan.range(from: date(11, 28), to: date(12, 6), calendar: calendar) == "November 28 to December 6")
        #expect(NovenaSpan.prayedLine("November 16 to 24") == "Prayed November 16 to 24")
        #expect(NovenaSpan.finishLine("del 16 al 24 de noviembre") == "Del 16 al 24 de noviembre")
        #expect(NovenaSpan.spoken(length: 9, range: "November 16 to 24") == "Nine days prayed, November 16 to 24.")
        #expect(NovenaSpan.lastPrayed(date(11, 24)) == "Last prayed November 24")
    }

    @Test func dayOneIsKeptThroughAPickUp() {
        var p = NovenaProgress(novenaID: "n", length: 9, beginning: date(11, 16), calendar: calendar)
        p.markPrayed(1)
        p.pickUp(on: date(11, 20), calendar: calendar)
        #expect(p.anchorDay == 2)
        #expect(p.firstDay == PrayerDay.day(of: date(11, 16), calendar: calendar))
        p.beginAgain(on: date(11, 22), calendar: calendar)
        #expect(p.firstDay == PrayerDay.day(of: date(11, 22), calendar: calendar))
    }

    @Test func anOlderEntryCountsDayOneBackFromItsLastDay() {
        let entry = FinishedNovena(novenaID: "n", finished: date(11, 24, hour: 21), intention: nil)
        #expect(entry.lastDate(calendar: calendar) == PrayerDay.day(of: date(11, 24), calendar: calendar))
        #expect(entry.firstDate(length: 9, calendar: calendar) == PrayerDay.day(of: date(11, 16), calendar: calendar))
    }

    #if DEBUG
        @Test func finishingKeepsBothDatesAndTheIntention() {
            let store = store()
            let novena = NovenaDayContext.debugKnots
            store.begin(novena, on: date(11, 16), intention: "For my family", now: date(11, 16))
            for day in 1...9 { store.markPrayed(day, of: novena, now: date(11, 15 + day)) }
            let finished = store.lastFinished(novena.id)
            #expect(store.progress[novena.id] == nil)
            #expect(finished?.intention == "For my family")
            #expect(finished?.firstDay == PrayerDay.day(of: date(11, 16)))
            #expect(finished?.lastDay == PrayerDay.day(of: date(11, 24)))
        }
    #endif
}
