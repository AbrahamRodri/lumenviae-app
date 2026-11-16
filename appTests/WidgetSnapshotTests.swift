//
//  WidgetSnapshotTests.swift
//  Lumen Viae Tests
//
//  The widgets' snapshot: what it says of the Rosary left off, the
//  novenas, the prayer record and the consecration, and that the store
//  writes it only when it changes, asking the widgets to redraw each time.
//

import Foundation
import Testing
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
            resume: resume, novenas: novenas, novenaName: { $0 == "st_joseph" ? "St Joseph" : nil },
            prayerDays: prayerDays, consecration: consecration, liturgicalDay: nil,
            now: now ?? day(0), calendar: calendar
        )
    }

    @Test func anEmptyAppSaysNothingIsUnderWay() {
        let empty = snapshot()
        #expect(empty.rosary == nil)
        #expect(empty.novenas.isEmpty)
        #expect(empty.consecration == nil)
        #expect(empty.record == .init(daysInARow: 0, prayedToday: false, thisWeek: []))
    }

    @Test func theRosaryLeftOffIsWhereTheHandStopped() {
        let left = InProgressPrayer(
            kind: .scripturalRosary, meditationSetId: 0, setName: "Ignored",
            category: "sorrowful", mysteryIndex: 2, beadIndex: 6,
            startedAt: day(0), accumulatedSeconds: 300, savedAt: day(0)
        )
        let rosary = snapshot(resume: left).rosary
        #expect(rosary?.category == "sorrowful")
        #expect(rosary?.form == "scriptural_rosary")
        #expect(rosary?.setName == "")
        #expect(rosary?.mysteryIndex == 2)
        #expect(rosary?.beadIndex == 6)
    }

    @Test func aNovenaUnderWayNamesTodaysDay() {
        var joseph = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-3), calendar: calendar)
        joseph.prayed = [1, 2, 3]
        let novena = snapshot(novenas: ["st_joseph": joseph]).novenas.first
        #expect(novena?.name == "St Joseph")
        #expect(novena?.todaysDay == 4)
        #expect(novena?.currentDay == 4)
        #expect(novena?.prayedToday == false)
        #expect(novena?.prayedDays == [1, 2, 3])
    }

    @Test func aNovenaPrayedTodaySaysSo() {
        var joseph = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-3), calendar: calendar)
        joseph.prayed = [1, 2, 3, 4]
        let novena = snapshot(novenas: ["st_joseph": joseph]).novenas.first
        #expect(novena?.todaysDay == nil)
        #expect(novena?.prayedToday == true)
    }

    @Test func aFinishedNovenaIsNotShown() {
        var done = NovenaProgress(novenaID: "st_joseph", length: 9, beginning: day(-8), calendar: calendar)
        done.prayed = Set(1...9)
        #expect(snapshot(novenas: ["st_joseph": done]).novenas.isEmpty)
    }

    @Test func theRecordCountsDaysInARowAndThisWeek() {
        // Wednesday prayed, and Monday and Tuesday before it
        let record = snapshot(prayerDays: [prayerDay(0), prayerDay(-1), prayerDay(-2), prayerDay(-10)]).record
        #expect(record.daysInARow == 3)
        #expect(record.prayedToday)
        #expect(record.thisWeek == [prayerDay(-2), prayerDay(-1), prayerDay(0)])
    }

    @Test func theConsecrationNamesItsDay() {
        let progress = ConsecrationProgress(startDate: day(-11))
        let consecration = snapshot(consecration: progress).consecration
        #expect(consecration?.hasBegun == true)
        #expect(consecration?.dayNumber == 12)
        #expect(consecration?.dayTitle == ConsecrationData.day(12)?.title)
        #expect(consecration?.todayPrayed == false)
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
