//
//  PrayerContinuationTests.swift
//  Lumen Viae Tests
//
//  Which unfinished Rosary the Pray button, its tray and the Chapel take
//  up rather than begin again over: the same form, left off today. A
//  meditation set of any mysteries is Today's Rosary's, the chaplet's is
//  Seven Sorrows', and the Scriptural and Holy Rosaries are their own.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayerContinuationTests {

    /// A fixed calendar, so the device's own settings never move a day
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private func rosary(
        _ kind: InProgressPrayer.Kind?,
        _ category: MysteryCategory,
        mystery: Int = 2,
        savedAt: Date
    ) -> InProgressPrayer {
        InProgressPrayer(
            kind: kind,
            meditationSetId: 12,
            setName: "St. Louis de Montfort",
            category: category.rawValue,
            mysteryIndex: mystery,
            beadIndex: 4,
            startedAt: savedAt.addingTimeInterval(-600),
            accumulatedSeconds: 540,
            savedAt: savedAt
        )
    }

    // MARK: - The act of each form

    @Test func aMeditationSetOfAnyMysteriesIsTodaysRosary() {
        for category in [MysteryCategory.joyful, .sorrowful, .glorious, .luminous] {
            #expect(rosary(.meditationSet, category, savedAt: at(29, 9)).act == .todaysRosary)
        }
    }

    @Test func theChapletsSetIsSevenSorrows() {
        #expect(rosary(.meditationSet, .sevenSorrows, savedAt: at(29, 9)).act == .sevenSorrows)
    }

    /// Snapshots written before the Scriptural Rosary carry no kind, and
    /// every one of them was a meditation set
    @Test func aSnapshotWithNoKindIsAMeditationSet() {
        #expect(rosary(nil, .joyful, savedAt: at(29, 9)).act == .todaysRosary)
        #expect(rosary(nil, .sevenSorrows, savedAt: at(29, 9)).act == .sevenSorrows)
    }

    @Test func theScripturalAndHolyRosariesAreTheirOwn() {
        #expect(rosary(.scripturalRosary, .joyful, savedAt: at(29, 9)).act == .scripturalRosary)
        #expect(rosary(.rosaryAloud, .joyful, savedAt: at(29, 9)).act == .rosaryAloud)
    }

    // MARK: - Taken up, or begun

    @Test func theSameFormLeftOffTodayIsTakenUp() {
        let session = rosary(.meditationSet, .sorrowful, savedAt: at(29, 7, 40))
        #expect(session.isContinued(by: .todaysRosary, now: at(29, 21), calendar: calendar))
    }

    @Test func anotherFormBeginsItsOwn() {
        let session = rosary(.scripturalRosary, .sorrowful, savedAt: at(29, 7))
        #expect(!session.isContinued(by: .todaysRosary, now: at(29, 8), calendar: calendar))
        #expect(!session.isContinued(by: .rosaryAloud, now: at(29, 8), calendar: calendar))
        #expect(session.isContinued(by: .scripturalRosary, now: at(29, 8), calendar: calendar))
    }

    @Test func theRosaryAndTheChapletNeverTakeUpEachOther() {
        let chaplet = rosary(.meditationSet, .sevenSorrows, savedAt: at(29, 7))
        let joyful = rosary(.meditationSet, .joyful, savedAt: at(29, 7))
        #expect(!chaplet.isContinued(by: .todaysRosary, now: at(29, 8), calendar: calendar))
        #expect(!joyful.isContinued(by: .sevenSorrows, now: at(29, 8), calendar: calendar))
    }

    /// Left last night, it is not today's once the prayer day has turned,
    /// at four: the act begins today's Rosary, and Home's card still
    /// offers last night's until it expires. Before four it is still
    /// tonight's, and is taken up.
    @Test func aRosaryLeftYesterdayIsNotTakenUp() {
        let session = rosary(.meditationSet, .glorious, savedAt: at(28, 23, 50))
        #expect(session.isContinued(by: .todaysRosary, now: at(29, 0, 10), calendar: calendar))
        #expect(!session.isContinued(by: .todaysRosary, now: at(29, 4, 10), calendar: calendar))
    }

    @Test func actsThatAreNotTheRosaryTakeUpNothing() {
        let session = rosary(.meditationSet, .joyful, savedAt: at(29, 7))
        for act in [PrayerShortcut.chooseMeditation, .mass, .office, .consecration,
                    .morningPrayers, .angelus, .nightPrayers] {
            #expect(!session.isContinued(by: act, now: at(29, 8), calendar: calendar))
        }
    }

    // MARK: - Where it stopped

    @Test func thePlaceIsSaidAsRunningText() {
        #expect(rosary(.meditationSet, .joyful, mystery: 2, savedAt: at(29, 7)).placeLabel == "Third Joyful Mystery")
        #expect(rosary(.meditationSet, .sevenSorrows, mystery: 3, savedAt: at(29, 7)).placeLabel == "Fourth Sorrow of Mary")
    }
}
