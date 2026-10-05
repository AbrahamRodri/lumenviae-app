//
//  OfficeHoursTests.swift
//  Lumen Viae Tests
//
//  The Office's clock and ranks: which canonical hour each clock hour
//  falls in (one boundary table, `beginsAtClockHour`, which the ledger,
//  the arch and `CanonicalClock` all read), how the hours wrap, what the
//  arch says of when the present hour lapses, and how the engine's Latin
//  class is read and named in the Missal's words.
//

import Testing
@testable import app

@MainActor
struct OfficeHoursTests {

    // MARK: - The Present Hour

    @Test func everyClockHourFallsInTheHourWhoseBoundaryPrecedesIt() {
        let expected: [CanonicalHour] = [
            .matins, .matins, .matins, .matins, .matins,   // 0–4
            .lauds, .lauds,                                // 5–6
            .prime, .prime,                                // 7–8
            .terce, .terce, .terce,                        // 9–11
            .sext, .sext,                                  // 12–13
            .nones, .nones,                                // 14–15
            .vespers, .vespers, .vespers,                  // 16–18
            .compline, .compline, .compline, .compline, .compline  // 19–23
        ]
        for clockHour in 0..<24 {
            #expect(CanonicalHour.present(atClockHour: clockHour) == expected[clockHour],
                    "clock hour \(clockHour)")
        }
    }

    @Test func eachHourIsPresentAtItsOwnBoundary() {
        for hour in CanonicalHour.allCases {
            #expect(CanonicalHour.present(atClockHour: hour.beginsAtClockHour) == hour)
        }
    }

    @Test func theBoundariesRunInTheHoursOrder() {
        let boundaries = CanonicalHour.allCases.map(\.beginsAtClockHour)
        #expect(boundaries == boundaries.sorted())
        #expect(Set(boundaries).count == boundaries.count)
        #expect(boundaries.first == 0)
    }

    // MARK: - Wrapping

    @Test func complineIsFollowedByMatinsButHasNoNext() {
        #expect(CanonicalHour.compline.following == .matins)
        #expect(CanonicalHour.compline.next == nil)
        #expect(CanonicalHour.matins.previous == nil)
    }

    @Test func followingAndNextAgreeWithinTheDay() {
        for hour in CanonicalHour.allCases where hour != .compline {
            #expect(hour.next == hour.following)
            #expect(hour.following.previous == hour)
        }
    }

    // MARK: - When an Hour Lapses

    @Test func theArchSaysWhenTheHourLapsesInWords() {
        #expect(CanonicalHour.terce.lapses == "until Midday Prayer at noon")
        #expect(CanonicalHour.compline.lapses == "until Night Vigil at midnight")
        #expect(CanonicalHour.matins.lapses == "until Dawn Prayer at five")
        #expect(CanonicalHour.vespers.lapses == "until Bedtime Prayer at seven")
    }

    // MARK: - The Engine's Class

    @Test(arguments: [
        ("I. classis", OfficeRank.first),
        ("II. classis", .second),
        ("III. classis", .third),
        ("IV. classis", .fourth),
        ("  iii. classis ", .third),
        ("II", .second),
        ("Feria", .feria),
        ("", .feria)
    ])
    func theLatinClassIsRead(text: String, rank: OfficeRank) {
        #expect(OfficeRank(text) == rank)
    }

    @Test func noRankIsAFeria() {
        #expect(OfficeRank(nil) == .feria)
    }

    @Test func theClassIsNamedInTheMissalsWords() {
        #expect(OfficeRank.first.englishLabel == "Great Feast")
        #expect(OfficeRank.second.englishLabel == "Feast")
        #expect(OfficeRank.third.englishLabel == "Lesser Feast")
        #expect(OfficeRank.feria.englishLabel == "Weekday")
    }

    @Test func aFeriaSaysItsSeason() {
        #expect(OfficeRank.feria.plainLabel(title: "Quadragesimæ") == "Lenten Weekday")
        #expect(OfficeRank.feria.plainLabel(title: "Hebdomadæ I Adventus") == "Advent Weekday")
    }

    @Test func greaterFeastsBurnBrighterAndAFeriaNotAtAll() {
        let ranks: [OfficeRank] = [.first, .second, .third, .fourth, .feria]
        let opacities = ranks.map(\.markOpacity)
        #expect(opacities == opacities.sorted(by: >))
        #expect(OfficeRank.feria.markOpacity == 0)
    }
}
