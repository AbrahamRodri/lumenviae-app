//
//  TodaysPrayerRowTests.swift
//  appTests
//
//  What Home's Today's Prayer rows say in each state: the consecration
//  before, ahead of, during and on its last day; the Office's hour and
//  when it ends; the Mass before and after its feast is known.
//

import Foundation
import Testing

@testable import app

@Suite("Today's Prayer rows")
struct TodaysPrayerRowTests {

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

    @Test func officeSaysWhenTheHourEnds() {
        #expect(TodaysPrayerRow.office(.terce).fact == "NOW · UNTIL NOON")
        #expect(TodaysPrayerRow.office(.sext).fact == "NOW · UNTIL 2 PM")
        #expect(TodaysPrayerRow.office(.compline).fact == "NOW · UNTIL MIDNIGHT")
        #expect(TodaysPrayerRow.office(.matins).fact == "NOW · UNTIL 5 AM")
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
