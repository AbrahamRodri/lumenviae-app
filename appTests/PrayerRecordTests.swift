//
//  PrayerRecordTests.swift
//  Lumen Viae Tests
//
//  The Prayer Record kept by `PrayerHistoryService` on a SwiftData store
//  held in memory: Rosaries recorded and counted, by set; a day's
//  Rosaries found by the prayer day they fall in; the streak running
//  back from today, or from yesterday while today is not yet prayed —
//  never broken at the first hour of a day not yet lived — the longest
//  run remembered; and the week drawn Sunday to Saturday.
//

import Foundation
import SwiftData
import Testing
@testable import app

@MainActor
struct PrayerRecordTests {

    private let container: ModelContainer
    private let context: ModelContext
    private let history: PrayerHistoryService

    init() throws {
        container = try ModelContainer(
            for: PrayerSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        history = PrayerHistoryService(modelContext: context)
    }

    /// Noon on the prayer day this many days before today's, well inside
    /// its four-to-four whatever the hour the tests run at
    private func noon(daysAgo: Int) -> Date {
        let day = PrayerDay.adding(days: -daysAgo, to: PrayerDay.today())
        return Calendar.current.date(byAdding: .hour, value: 12, to: day)!
    }

    private func prayed(daysAgo: Int, _ category: MysteryCategory = .joyful) {
        context.insert(PrayerSession(category: category, completedAt: noon(daysAgo: daysAgo),
                                     durationSeconds: 1200, meditationType: nil))
        try? context.save()
    }

    @Test func anEmptyRecordCountsNothing() {
        #expect(history.totalRosaries() == 0)
        #expect(history.currentStreak() == 0)
        #expect(history.longestStreak() == 0)
        #expect(!history.hasPrayedToday())
        #expect(history.weeklyPrayerStatus().allSatisfy { !$0.didPray })
    }

    @Test func aRosaryRecordedNowIsTodays() {
        history.recordSession(category: .sorrowful, durationSeconds: 900, meditationType: "The Scriptural Rosary")
        #expect(history.totalRosaries() == 1)
        #expect(history.hasPrayedToday())
        #expect(history.currentStreak() == 1)
        let session = history.allSessions().first
        #expect(session?.category == .sorrowful)
        #expect(session?.meditationType == "The Scriptural Rosary")
    }

    @Test func rosariesAreCountedBySet() {
        prayed(daysAgo: 0, .joyful)
        prayed(daysAgo: 1, .joyful)
        prayed(daysAgo: 2, .sevenSorrows)
        let counts = history.rosariesByCategory()
        #expect(counts[.joyful] == 2)
        #expect(counts[.sevenSorrows] == 1)
        #expect(counts[.luminous] == 0)
        #expect(counts.count == MysteryCategory.allCases.count, "every set counted, none left out")
    }

    @Test func aDaysRosariesAreThatPrayerDaysAlone() {
        prayed(daysAgo: 0)
        prayed(daysAgo: 0, .glorious)
        prayed(daysAgo: 1)
        #expect(history.sessions(onPrayerDay: PrayerDay.today()).count == 2)
        #expect(history.sessions(on: noon(daysAgo: 1)).count == 1)
        #expect(history.sessions(on: noon(daysAgo: 5)).isEmpty)
    }

    @Test func allSessionsComeNewestFirst() {
        prayed(daysAgo: 3)
        prayed(daysAgo: 0)
        prayed(daysAgo: 1)
        let dates = history.allSessions().map(\.completedAt)
        #expect(dates == dates.sorted(by: >))
    }

    @Test func theStreakRunsBackFromToday() {
        for day in 0...4 { prayed(daysAgo: day) }
        #expect(history.currentStreak() == 5)
    }

    @Test func aStreakHoldsWhileTodayIsNotYetPrayed() {
        for day in 1...3 { prayed(daysAgo: day) }
        #expect(!history.hasPrayedToday())
        #expect(history.currentStreak() == 3, "today still asks; the run is not yet broken")
    }

    @Test func aDayMissedEndsTheRunButIsNeverCounted() {
        prayed(daysAgo: 0)
        prayed(daysAgo: 1)
        // two days ago left unprayed
        for day in 3...9 { prayed(daysAgo: day) }
        #expect(history.currentStreak() == 2)
        #expect(history.longestStreak() == 7, "the longest run is remembered")
    }

    @Test func twoRosariesInADayAreOneDayOfTheStreak() {
        prayed(daysAgo: 0)
        prayed(daysAgo: 0)
        prayed(daysAgo: 1)
        #expect(history.totalRosaries() == 3)
        #expect(history.currentStreak() == 2)
    }

    @Test func aRunThatEndedBeforeYesterdayIsNoCurrentStreak() {
        for day in 2...6 { prayed(daysAgo: day) }
        #expect(history.currentStreak() == 0)
        #expect(history.longestStreak() == 5)
    }

    @Test func theWeekIsSevenDaysWithTodayAmongThem() {
        prayed(daysAgo: 0)
        let week = history.weeklyPrayerStatus()
        #expect(week.count == 7)
        let today = PrayerDay.today()
        #expect(week.contains { $0.date == today && $0.didPray })
        #expect(week.filter(\.didPray).count == 1)
        #expect(week.first.map { Calendar.current.component(.weekday, from: $0.date) } == Calendar.current.firstWeekday)
    }

    @Test func aRangeOfDaysFindsWhatFallsInIt() {
        prayed(daysAgo: 10)
        prayed(daysAgo: 5)
        prayed(daysAgo: 1)
        let found = history.sessions(from: noon(daysAgo: 6), to: noon(daysAgo: 1))
        #expect(found.count == 2, "both ends included")
    }
}
