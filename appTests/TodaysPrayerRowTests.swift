//
//  TodaysPrayerRowTests.swift
//  appTests
//
//  What Home's Today's Prayer rows say in each state: the consecration
//  before, ahead of, during, on and after its last day, and made; which
//  record the row shows; the hour's order at each of its hours, prayed
//  and not; the Office's hour and when it ends; the Mass before and
//  after its feast is known. Every moment is fixed, so a run across
//  midnight reads the same.
//

import Foundation
import Testing

@testable import app

@Suite("Today's Prayer rows")
struct TodaysPrayerRowTests {

    /// 13 October 2026 (ordinary time) by default, or another day of
    /// 2026, at the given hour and minute
    private func moment(month: Int = 10, day: Int = 13, hour: Int = 9, minute: Int = 30) throws -> Date {
        try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)))
    }

    /// A consecration whose Day 1 is `offset` days from the fixed morning
    private func consecration(startingDaysFromNow offset: Int) throws -> (ConsecrationProgress, Date) {
        let now = try moment()
        let start = try #require(Calendar.current.date(byAdding: .day, value: offset, to: now))
        return (ConsecrationProgress(startDate: start), now)
    }

    private func store(_ name: String) throws -> PrayerBookStore {
        let suite = "TodaysPrayerRowTests.\(name)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return PrayerBookStore(defaults: defaults)
    }

    // MARK: Consecration to Mary

    @Test func consecrationNotBegun() throws {
        let row = TodaysPrayerRow.consecration(nil, now: try moment())
        #expect(row.fact == "BEGIN")
        #expect(row.painting == "glorious_coronation")
        #expect(!row.isPrayed)
    }

    @Test func consecrationChosenAhead() throws {
        let (progress, now) = try consecration(startingDaysFromNow: 6)
        let row = TodaysPrayerRow.consecration(progress, now: now)
        #expect(row.fact == "BEGINS OCT 19")
        #expect(!row.isPrayed)
        // Its line is said to VoiceOver too
        #expect(row.spoken.contains(row.subtitle))
    }

    @Test func consecrationUnderWay() throws {
        let (progress, now) = try consecration(startingDaysFromNow: -11)
        let row = TodaysPrayerRow.consecration(progress, now: now)
        #expect(row.fact == "DAY 12 OF 33")
        #expect(!row.isPrayed)

        progress.completeDay(12)
        let prayed = TodaysPrayerRow.consecration(progress, now: now)
        #expect(prayed.isPrayed)
        #expect(prayed.subtitle == ConsecrationData.day(12)?.title)
        #expect(prayed.spoken.hasSuffix("prayed today"))
    }

    /// The day of consecration is never "DAY 34 OF 33"
    @Test func consecrationDay() throws {
        let (progress, now) = try consecration(startingDaysFromNow: -33)
        #expect(TodaysPrayerRow.consecration(progress, now: now).fact == "THE DAY OF CONSECRATION")
    }

    /// Past the day of consecration with the act not yet made, the row
    /// says it is ready, never that it is late, and never that today is the day
    @Test func consecrationPastItsDay() throws {
        let (progress, now) = try consecration(startingDaysFromNow: -40)
        let row = TodaysPrayerRow.consecration(progress, now: now)
        #expect(row.fact == "READY TO CONSECRATE")
        #expect(!row.isPrayed)
    }

    /// Made, the row keeps its seal rather than turning back to BEGIN
    @Test func consecrationMade() throws {
        let (progress, now) = try consecration(startingDaysFromNow: -33)
        progress.completeDay(34)
        let row = TodaysPrayerRow.consecration(progress, now: now)
        #expect(row.fact == "CONSECRATED TODAY")
        #expect(row.isPrayed)
    }

    /// A consecration made today is the row's for the rest of the day; one
    /// made yesterday is done, and the row invites a new one
    @Test func consecrationShownOnlyTheDayItIsMade() throws {
        let (progress, now) = try consecration(startingDaysFromNow: -33)
        progress.completeDay(34)

        progress.completedAt = now
        #expect(TodaysPrayerRow.shownConsecration(among: [progress], at: now) === progress)

        progress.completedAt = Calendar.current.date(byAdding: .day, value: -1, to: now)
        #expect(TodaysPrayerRow.shownConsecration(among: [progress], at: now) == nil)
    }

    /// A preparation under way is shown before a finished one
    @Test func consecrationUnderWayIsShownFirst() throws {
        let (made, now) = try consecration(startingDaysFromNow: -60)
        made.completeDay(34)
        made.completedAt = now
        let (underWay, _) = try consecration(startingDaysFromNow: -2)
        #expect(TodaysPrayerRow.shownConsecration(among: [made, underWay], at: now) === underWay)
    }

    // MARK: The hour's prayers

    @Test func hourOrderAtEachHour() throws {
        let store = try store("hours")
        let morning = TodaysPrayerRow.hourOrder(at: try moment(hour: 9), store: store)
        #expect(morning.name == "Morning Prayers")
        #expect(morning.fact == "ON WAKING")

        let noon = TodaysPrayerRow.hourOrder(at: try moment(hour: 12, minute: 30), store: store)
        #expect(noon.name == "The Angelus")
        #expect(noon.fact == "AT NOON")
        #expect(!noon.isPrayed)

        let night = TodaysPrayerRow.hourOrder(at: try moment(hour: 21), store: store)
        #expect(night.name == "Night Prayers")
        #expect(night.fact == "AT BEDTIME")
        #expect(night.subtitle == PrayerBook.daySummary(of: PrayerBook.dayOrder(at: try moment(hour: 21))))
    }

    @Test func hourOrderPrayed() throws {
        let store = try store("prayed")
        let nine = try moment(hour: 9)
        store.markOffered(PrayerBook.morningOrderID, on: nine)
        let row = TodaysPrayerRow.hourOrder(at: nine, store: store)
        #expect(row.isPrayed)
        #expect(row.fact == "PRAYED")
        #expect(row.spoken.hasSuffix("prayed today"))
    }

    @Test func nightPrayersPrayed() throws {
        let store = try store("night")
        let evening = try moment(hour: 21)
        store.markOffered(PrayerBook.nightOrderID, on: evening)
        let row = TodaysPrayerRow.hourOrder(at: evening, store: store)
        #expect(row.isPrayed)
        #expect(row.fact == "PRAYED")
    }

    /// Half past midnight still belongs to the evening before: Night
    /// Prayers said then are that evening's, and stay prayed
    @Test func halfPastMidnightCountsForTheEveningBefore() throws {
        let store = try store("midnight")
        store.markOffered(PrayerBook.nightOrderID, on: try moment(hour: 21))
        let row = TodaysPrayerRow.hourOrder(at: try moment(day: 14, hour: 0), store: store)
        #expect(row.name == "Night Prayers")
        #expect(row.isPrayed)
    }

    /// The Angelus is the bell's: one said at noon is prayed until the
    /// evening bell, which then asks for its own
    @Test func angelusPrayedAtNoonIsNotTheEvenings() throws {
        let store = try store("angelus")
        store.markOffered(PrayerBook.angelusOrderID, on: try moment(hour: 12, minute: 5))
        #expect(TodaysPrayerRow.hourOrder(at: try moment(hour: 12, minute: 30), store: store).isPrayed)
        let evening = TodaysPrayerRow.hourOrder(at: try moment(hour: 18, minute: 30), store: store)
        #expect(!evening.isPrayed)
        #expect(evening.fact == "AT 6 PM")
    }

    @Test func angelusInEastertideIsQueenOfHeaven() throws {
        let row = TodaysPrayerRow.hourOrder(
            at: try moment(month: 4, day: 14, hour: 12, minute: 30), store: try store("easter"))
        #expect(row.name == "Queen of Heaven")
        #expect(row.painting == "glorious_resurrection")
    }

    // MARK: The Hours of Prayer

    @Test func officeSaysWhenTheHourEnds() {
        #expect(TodaysPrayerRow.office(.terce).fact == "NOW · UNTIL NOON")
        #expect(TodaysPrayerRow.office(.sext).fact == "NOW · UNTIL TWO")
        #expect(TodaysPrayerRow.office(.compline).fact == "NOW · UNTIL MIDNIGHT")
        #expect(TodaysPrayerRow.office(.matins).fact == "NOW · UNTIL FIVE")
        #expect(TodaysPrayerRow.office(.terce).subtitle == "Mid-Morning Prayer (Terce)")
        // Millet's Angelus, the Prayer Book's own painting for the day's prayers
        #expect(TodaysPrayerRow.office(.terce).painting == "topic_daily_prayers")
    }

    // MARK: Today's Mass

    @Test func massBeforeAndAfterItsFeast() {
        let unknown = TodaysPrayerRow.mass(TodayInChurch())
        #expect(unknown.fact == nil)
        #expect(unknown.subtitle == "Prayers and readings for today")
        // The Mass at Bolsena, the Prayer Book's own painting for the Mass
        #expect(unknown.painting == "topic_holy_mass")

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
