//
//  WidgetSnapshotTests.swift
//  Lumen Viae Tests
//
//  The widgets' snapshot: what it says of the Rosary left off, the
//  novenas, the prayer record and the consecration, how a widget finds
//  the day and the hour in it, and that the store writes it only when it
//  changes, asking the widgets to redraw each time.
//

import Foundation
import Testing
import UIKit
@testable import app

@MainActor
struct WidgetSnapshotTests {

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Chicago")!
        return c
    }()

    /// Noon on Wednesday 18 Nov 2026 plus `days`
    private func day(_ days: Int, hour: Int = 12) -> Date {
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: hour))!
        return calendar.date(byAdding: .day, value: days, to: start)!
    }

    private func prayerDay(_ days: Int) -> Date { PrayerDay.day(of: day(days), calendar: calendar) }

    private func snapshot(
        resume: InProgressPrayer? = nil,
        novenas: [String: NovenaProgress] = [:],
        prayerDays: Set<Date> = [],
        consecration: ConsecrationProgress? = nil,
        now: Date? = nil
    ) -> WidgetSnapshot {
        WidgetSnapshot.make(
            resume: resume, novenas: novenas,
            novenaInfo: { $0 == "st_joseph" ? .init(name: "St Joseph", painting: "devotion_st_joseph") : nil },
            prayerDays: prayerDays, consecration: consecration, liturgicalDay: { _ in nil },
            spanish: false, now: now ?? day(0), calendar: calendar
        )
    }

    private func today(_ snapshot: WidgetSnapshot) -> WidgetSnapshot.Day {
        snapshot.days[0]
    }

    @Test func anEmptyAppSaysNothingIsUnderWay() {
        let empty = snapshot()
        #expect(empty.rosary == nil)
        #expect(today(empty).novenas.isEmpty)
        #expect(today(empty).consecration == nil)
        #expect(today(empty).record.daysInARow == 0)
        #expect(!today(empty).record.prayedToday)
        #expect(today(empty).record.week == Array(repeating: false, count: 7))
    }

    @Test func itRunsEightDaysFromToday() {
        let days = snapshot().days
        #expect(days.count == WidgetSnapshot.daysKept)
        #expect(days.first?.date == "2026-11-18")
        #expect(days.last?.date == "2026-11-25")
    }

    @Test func eachDayNamesItsOwnMysteries() {
        let days = snapshot().days
        for (offset, day) in days.enumerated() {
            let category = ScheduleService.category(for: self.day(offset), calendar: calendar)
            #expect(day.mysteries.category == category.rawValue)
            #expect(day.mysteries.names.count == MysteryData.mysteries(for: category).count)
            #expect(day.mysteries.paintings.count == day.mysteries.names.count)
        }
    }

    @Test func theRosaryLeftOffIsWhereTheHandStopped() {
        let left = InProgressPrayer(
            kind: .scripturalRosary, meditationSetId: 0, setName: "Ignored",
            category: "sorrowful", mysteryIndex: 3, beadIndex: 6,
            startedAt: day(0), accumulatedSeconds: 300, savedAt: day(0)
        )
        let rosary = snapshot(resume: left).rosary
        #expect(rosary?.category == "sorrowful")
        #expect(rosary?.form == "scriptural_rosary")
        #expect(rosary?.setName == "")
        #expect(rosary?.mysteryIndex == 3)
        #expect(rosary?.beadIndex == 6)
        #expect(rosary?.painting == "sorrowful_carrying")
        #expect(rosary?.placeLine == "4th mystery")
        #expect(rosary?.beadLine == "Hail Mary 6 of 10")
        #expect(rosary?.hailMarys == 10)
        #expect(rosary?.prayerDay == "2026-11-18")
    }

    @Test func theRosaryLeftOffIsShownOnlyOnItsPrayerDay() {
        let left = InProgressPrayer(
            kind: .meditationSet, meditationSetId: 1, setName: "Liguori",
            category: "joyful", mysteryIndex: 0, beadIndex: 2,
            startedAt: day(0, hour: 23), accumulatedSeconds: 60, savedAt: day(0, hour: 23)
        )
        let snap = snapshot(resume: left, now: day(0, hour: 23))
        #expect(snap.rosaryLeftOff(at: day(1, hour: 1), calendar: calendar) != nil, "half past midnight is still the evening's")
        #expect(snap.rosaryLeftOff(at: day(1, hour: 5), calendar: calendar) == nil)
    }

    @Test func aNovenaUnderWayNamesTodaysDay() {
        var joseph = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-3), calendar: calendar)
        joseph.prayed = [1, 2, 3]
        let novena = today(snapshot(novenas: ["st_joseph": joseph])).novenas.first
        #expect(novena?.name == "St Joseph")
        #expect(novena?.painting == "devotion_st_joseph")
        #expect(novena?.todaysDay == 4)
        #expect(novena?.currentDay == 4)
        #expect(novena?.prayedToday == false)
        #expect(novena?.prayedDays == [1, 2, 3])
        #expect(novena?.dayLine == "Day 4 of 9")
        #expect(novena?.statusLine == "Not yet prayed today")
    }

    @Test func aNovenaPrayedTodaySaysSoAndTomorrowAsksTheNext() {
        var joseph = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-3), calendar: calendar)
        joseph.prayed = [1, 2, 3, 4]
        let days = snapshot(novenas: ["st_joseph": joseph]).days
        #expect(days[0].novenas.first?.todaysDay == nil)
        #expect(days[0].novenas.first?.prayedToday == true)
        #expect(days[0].novenas.first?.statusLine == "Prayed today")
        #expect(days[1].novenas.first?.todaysDay == 5)
        #expect(days[1].novenas.first?.prayedToday == false)
    }

    @Test func aFinishedNovenaIsNotShown() {
        var done = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-8), calendar: calendar)
        done.prayed = Set(1...9)
        #expect(today(snapshot(novenas: ["st_joseph": done])).novenas.isEmpty)
    }

    @Test func aNovenaTheBookNoLongerHoldsIsNotShown() {
        var knots = NovenaProgress(novenaID: "undoer_of_knots", length: 9, beginning: day(-3), calendar: calendar)
        knots.prayed = [1, 2, 3]
        #expect(today(snapshot(novenas: ["undoer_of_knots": knots])).novenas.isEmpty)
        #expect(!snapshot(novenas: ["undoer_of_knots": knots]).days.contains { !$0.novenas.isEmpty })
    }

    @Test func theRecordCountsDaysInARowAndThisWeek() {
        // Wednesday prayed, and Monday and Tuesday before it
        let record = today(snapshot(prayerDays: [prayerDay(0), prayerDay(-1), prayerDay(-2), prayerDay(-10)])).record
        #expect(record.daysInARow == 3)
        #expect(record.prayedToday)
        #expect(record.line == "3 days in a row")
        #expect(record.week == [false, true, true, true, false, false, false])
        #expect(record.todayInWeek == 3)
    }

    @Test func theConsecrationNamesItsDay() {
        let progress = ConsecrationProgress(startDate: day(-11))
        let days = snapshot(consecration: progress).days
        let consecration = days[0].consecration
        #expect(consecration?.hasBegun == true)
        #expect(consecration?.dayNumber == 12)
        #expect(consecration?.dayLine == "Day 12 of 33")
        #expect(consecration?.dayTitle == ConsecrationData.day(12)?.title)
        #expect(consecration?.todayPrayed == false)
        #expect(days[1].consecration?.dayNumber == 13)
    }

    @Test func aConsecrationChosenAheadSaysWhenItBegins() {
        let progress = ConsecrationProgress(startDate: day(5))
        let consecration = today(snapshot(consecration: progress)).consecration
        #expect(consecration?.hasBegun == false)
        #expect(consecration?.beginsLine == "Begins 23 November")
        #expect(consecration?.feastLine == "For the feast of 26 December")
    }

    @Test func aWidgetFindsTheDayAndTheHourByTheClock() {
        let snap = snapshot()
        #expect(snap.day(at: day(2), calendar: calendar)?.date == "2026-11-20")
        #expect(snap.day(at: day(30), calendar: calendar)?.date == "2026-11-25", "past the last day, the last one kept")
        #expect(snap.prayerDay(at: day(1, hour: 2), calendar: calendar)?.date == "2026-11-18")
        #expect(snap.hour(at: day(0, hour: 17), calendar: calendar)?.churchName == "Vespers")
        #expect(snap.hour(at: day(0, hour: 2), calendar: calendar)?.churchName == "Matins")
    }

    @Test func everyPaintingNamedIsInTheAppsCatalog() {
        var joseph = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-3), calendar: calendar)
        joseph.prayed = [1]
        let names = snapshot(novenas: ["st_joseph": joseph], consecration: ConsecrationProgress(startDate: day(-11))).paintingNames
        for name in names {
            #expect(UIImage(named: name) != nil, "\(name) is not in the asset catalog")
        }
    }

    @Test func theStoreWritesOnlyWhatChanged() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-snapshot-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var reloads = 0
        let store = WidgetSnapshotStore(directory: directory, reloadWidgets: { reloads += 1 })

        let first = snapshot()
        #expect(store.write(first))
        #expect(!store.write(first), "the same snapshot is not written again")
        #expect(reloads == 1)
        #expect(WidgetSnapshotStore.read(from: directory) == first)

        let prayed = snapshot(prayerDays: [prayerDay(0)])
        #expect(store.write(prayed))
        #expect(reloads == 2)
        #expect(WidgetSnapshotStore.read(from: directory) == prayed)
    }

    @Test func withNoAppGroupNothingIsWritten() {
        var reloads = 0
        let store = WidgetSnapshotStore(directory: nil, reloadWidgets: { reloads += 1 })
        #expect(!store.write(snapshot()))
        #expect(reloads == 0)
    }
}
