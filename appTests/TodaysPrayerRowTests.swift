//
//  TodaysPrayerRowTests.swift
//  appTests
//
//  What Home's Today's Prayer rows say in each state: the consecration
//  before, ahead of, during, on and after its last day, and made; the
//  hour's order at each of its hours, prayed and not; the Office's hour
//  and when it ends; the Mass before and after its feast is known.
//

import Foundation
import Testing

@testable import app

@Suite("Today's Prayer rows")
struct TodaysPrayerRowTests {

    /// 13 October 2026 (ordinary time) or 14 April 2026 (Eastertide) at
    /// the given hour and minute
    private func moment(month: Int = 10, day: Int = 13, hour: Int, minute: Int = 0) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)))
    }

    private func store(_ name: String) throws -> PrayerBookStore {
        let suite = "TodaysPrayerRowTests.\(name)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return PrayerBookStore(defaults: defaults)
    }

    @Test func consecrationNotBegun() {
        let row = TodaysPrayerRow.consecration(nil)
        #expect(row.fact == "BEGIN")
        #expect(row.painting == "glorious_coronation")
        #expect(!row.isPrayed)
    }

    @Test func consecrationChosenAhead() throws {
        let start = try #require(Calendar.current.date(byAdding: .day, value: 6, to: Date()))
        let row = TodaysPrayerRow.consecration(ConsecrationProgress(startDate: start))
        #expect(row.fact?.hasPrefix("BEGINS ") == true)
        #expect(!row.isPrayed)
    }

    @Test func consecrationUnderWay() throws {
        let start = try #require(Calendar.current.date(byAdding: .day, value: -11, to: Date()))
        let progress = ConsecrationProgress(startDate: start)
        #expect(TodaysPrayerRow.consecration(progress).fact == "DAY 12 OF 33")
        #expect(!TodaysPrayerRow.consecration(progress).isPrayed)

        progress.completeDay(12)
        let prayed = TodaysPrayerRow.consecration(progress)
        #expect(prayed.isPrayed)
        #expect(prayed.subtitle == ConsecrationData.day(12)?.title)
        #expect(prayed.spoken.hasSuffix("prayed today"))
    }

    /// The day of consecration is never "DAY 34 OF 33"
    @Test func consecrationDay() throws {
        let start = try #require(Calendar.current.date(byAdding: .day, value: -33, to: Date()))
        let row = TodaysPrayerRow.consecration(ConsecrationProgress(startDate: start))
        #expect(row.fact == "THE DAY OF CONSECRATION")
    }

    /// Past the day of consecration with the act not yet made, the row
    /// says it is ready, never that it is late, and never that today is the day
    @Test func consecrationPastItsDay() throws {
        let start = try #require(Calendar.current.date(byAdding: .day, value: -40, to: Date()))
        let row = TodaysPrayerRow.consecration(ConsecrationProgress(startDate: start))
        #expect(row.fact == "READY TO CONSECRATE")
        #expect(!row.isPrayed)
    }

    /// Made today, the row keeps its seal rather than turning back to BEGIN
    @Test func consecrationMade() throws {
        let start = try #require(Calendar.current.date(byAdding: .day, value: -33, to: Date()))
        let progress = ConsecrationProgress(startDate: start)
        progress.completeDay(34)
        let row = TodaysPrayerRow.consecration(progress)
        #expect(row.fact == "CONSECRATED TODAY")
        #expect(row.isPrayed)
    }

    /// A consecration chosen ahead says its line to VoiceOver too
    @Test func consecrationAheadIsSpokenWhole() throws {
        let start = try #require(Calendar.current.date(byAdding: .day, value: 6, to: Date()))
        let row = TodaysPrayerRow.consecration(ConsecrationProgress(startDate: start))
        #expect(row.spoken.contains(row.subtitle))
    }

    @Test func hourOrderAtEachHour() throws {
        let store = try store("hours")
        let morning = TodaysPrayerRow.hourOrder(at: try moment(hour: 9), store: store)
        #expect(morning.name == "Morning Prayers")
        #expect(morning.fact == "ON WAKING")

        let noon = TodaysPrayerRow.hourOrder(at: try moment(hour: 12, minute: 30), store: store)
        #expect(noon.name == "The Angelus")
        #expect(!noon.isPrayed)

        let night = TodaysPrayerRow.hourOrder(at: try moment(hour: 21), store: store)
        #expect(night.name == "Night Prayers")
        #expect(night.subtitle == PrayerBook.daySummary(of: PrayerBook.dayOrder(at: try moment(hour: 21))))
    }

    @Test func hourOrderPrayed() throws {
        let store = try store("prayed")
        let nine = try moment(hour: 9)
        store.markOffered(PrayerBook.morningOrderID, on: nine)
        let row = TodaysPrayerRow.hourOrder(at: nine, store: store)
        #expect(row.isPrayed)
        #expect(row.fact == "PRAYED")
        #expect(row.spoken.contains("prayed today"))
    }

    /// The Angelus is the bell's: one said at noon is prayed until the
    /// evening bell, which then asks for its own
    @Test func angelusPrayedAtNoonIsNotTheEvenings() throws {
        let store = try store("angelus")
        store.markOffered(PrayerBook.angelusOrderID, on: try moment(hour: 12, minute: 5))
        #expect(TodaysPrayerRow.hourOrder(at: try moment(hour: 12, minute: 30), store: store).isPrayed)
        let evening = TodaysPrayerRow.hourOrder(at: try moment(hour: 18, minute: 30), store: store)
        #expect(!evening.isPrayed)
        #expect(evening.fact != "PRAYED")
    }

    @Test func angelusInEastertideIsQueenOfHeaven() throws {
        let row = TodaysPrayerRow.hourOrder(at: try moment(month: 4, day: 14, hour: 12, minute: 30), store: try store("easter"))
        #expect(row.name == "Queen of Heaven")
        #expect(row.painting == "glorious_resurrection")
    }

    @Test func officeSaysWhenTheHourEnds() {
        #expect(TodaysPrayerRow.office(.terce).fact == "NOW · UNTIL NOON")
        #expect(TodaysPrayerRow.office(.sext).fact == "NOW · UNTIL TWO")
        #expect(TodaysPrayerRow.office(.compline).fact == "NOW · UNTIL MIDNIGHT")
        #expect(TodaysPrayerRow.office(.matins).fact == "NOW · UNTIL FIVE")
        #expect(TodaysPrayerRow.office(.terce).subtitle == "Mid-Morning Prayer (Terce)")
    }

    @Test func massBeforeAndAfterItsFeast() {
        let unknown = TodaysPrayerRow.mass(TodayInChurch())
        #expect(unknown.fact == nil)
        #expect(unknown.subtitle == "Prayers and readings for today")

        let known = TodaysPrayerRow.mass(
            TodayInChurch(
                proper: MissalProper(
                    info: MissalInfo(
                        id: nil, title: "St. Edward", description: nil, date: nil, rank: 3, colors: ["w"],
                        tempora: nil, tags: nil, commemorations: nil
                    ),
                    sections: []
                )
            )
        )
        #expect(known.subtitle == "St. Edward")
        #expect(known.fact == "LESSER FEAST · WHITE")
        #expect(known.mark == .silk(.white))
        #expect(!known.isPrayed)
    }
}
