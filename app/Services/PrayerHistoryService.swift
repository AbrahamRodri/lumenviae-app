//
//  PrayerHistoryService.swift
//  Lumen Viae
//
//  Records completed prayer sessions and computes streaks and statistics,
//  persisted via SwiftData (PrayerSession model).
//
//  Every day here is a prayer day (`PrayerDay`), turning at four in the
//  morning: a Rosary finished at half past twelve counts for the evening
//  before, as Night Prayers said then do. Sessions are stored with the
//  moment they ended and counted into days on read, so nothing stored
//  changes.
//

import Foundation
import SwiftData

@Observable
final class PrayerHistoryService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recording Sessions

    /// Records a completed prayer session.
    func recordSession(
        category: MysteryCategory,
        durationSeconds: Int? = nil,
        meditationType: String? = nil
    ) {
        let session = PrayerSession(
            category: category,
            completedAt: Date(),
            durationSeconds: durationSeconds,
            meditationType: meditationType
        )
        modelContext.insert(session)
        try? modelContext.save()
    }

    // MARK: - Fetching Sessions

    /// Fetches all prayer sessions, most recent first.
    func allSessions() -> [PrayerSession] {
        let descriptor = FetchDescriptor<PrayerSession>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Fetches the sessions of the prayer day `date` falls in: at 12:30 AM,
    /// the evening before's.
    func sessions(on date: Date) -> [PrayerSession] {
        sessions(onPrayerDay: PrayerDay.day(of: date))
    }

    /// Fetches the sessions of a prayer day, named by its calendar date
    /// (`PrayerDay.day(of:)`): from four that morning to four the next.
    func sessions(onPrayerDay day: Date) -> [PrayerSession] {
        let interval = PrayerDay.interval(of: day)
        let start = interval.start
        let end = interval.end

        let predicate = #Predicate<PrayerSession> { session in
            session.completedAt >= start && session.completedAt < end
        }
        let descriptor = FetchDescriptor<PrayerSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Fetches sessions within a date range.
    func sessions(from startDate: Date, to endDate: Date) -> [PrayerSession] {
        let predicate = #Predicate<PrayerSession> { session in
            session.completedAt >= startDate && session.completedAt <= endDate
        }
        let descriptor = FetchDescriptor<PrayerSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Statistics

    /// Total number of Rosaries completed.
    func totalRosaries() -> Int {
        let descriptor = FetchDescriptor<PrayerSession>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Number of Rosaries completed for each category.
    func rosariesByCategory() -> [MysteryCategory: Int] {
        let sessions = allSessions()
        var counts: [MysteryCategory: Int] = [:]

        for category in MysteryCategory.allCases {
            counts[category] = sessions.filter { $0.categoryRaw == category.rawValue }.count
        }

        return counts
    }

    /// Whether at least one Rosary was completed today (the prayer day).
    func hasPrayedToday() -> Bool {
        !sessions(onPrayerDay: PrayerDay.today()).isEmpty
    }

    // MARK: - Streak Calculation

    /// The distinct prayer days on which at least one Rosary was completed,
    /// each named by its calendar date's midnight.
    ///
    /// One fetch, then set membership. The day-at-a-time walk this replaced
    /// issued a separate predicate query per day, so a long streak cost
    /// hundreds of round trips every time a screen asked for it.
    private func prayerDays() -> Set<Date> {
        Self.prayerDays(of: allSessions().map(\.completedAt))
    }

    /// Current consecutive days of prayer.
    func currentStreak() -> Int {
        Self.currentStreak(in: prayerDays(), today: PrayerDay.today())
    }

    /// Longest streak ever achieved.
    func longestStreak() -> Int {
        Self.longestStreak(in: prayerDays())
    }

    // MARK: Pure

    /// The prayer days a set of moments fall on
    nonisolated static func prayerDays(of instants: [Date], calendar: Calendar = .current) -> Set<Date> {
        Set(instants.map { PrayerDay.day(of: $0, calendar: calendar) })
    }

    /// The consecutive prayer days ending today, or yesterday if nothing
    /// has been prayed yet today: a streak is not broken until today's day
    /// turns, at four tomorrow morning.
    nonisolated static func currentStreak(
        in days: Set<Date>,
        today: Date,
        calendar: Calendar = .current
    ) -> Int {
        guard !days.isEmpty else { return 0 }

        var currentDate = calendar.startOfDay(for: today)

        // No prayer today: a streak may still be running that ended yesterday.
        if !days.contains(currentDate) {
            currentDate = PrayerDay.adding(days: -1, to: currentDate, calendar: calendar)
        }

        var streak = 0
        while days.contains(currentDate) {
            streak += 1
            currentDate = PrayerDay.adding(days: -1, to: currentDate, calendar: calendar)
        }

        return streak
    }

    /// The longest run of consecutive prayer days
    nonisolated static func longestStreak(in days: Set<Date>, calendar: Calendar = .current) -> Int {
        let sortedDates = days.sorted()
        guard !sortedDates.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        // Counted in calendar days between the days' midnights, so a day
        // the clocks change on is still one day
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    // MARK: - Weekly Calendar Data

    /// Returns prayer status for the current week: the week, Sunday to
    /// Saturday, that holds today's prayer day — at 12:30 AM on a Sunday,
    /// still the week that Saturday closes.
    ///
    /// - Returns: Array of 7 tuples (date, didPray) for Sun-Sat, each date
    ///   a prayer day named by its calendar date's midnight
    func weeklyPrayerStatus() -> [(date: Date, didPray: Bool)] {
        Self.weekStatus(in: prayerDays(), today: PrayerDay.today())
    }

    /// The week holding `today`, Sunday to Saturday, each day marked
    /// prayed or not
    nonisolated static func weekStatus(
        in days: Set<Date>,
        today: Date,
        calendar: Calendar = .current
    ) -> [(date: Date, didPray: Bool)] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        return (0..<7).map { offset in
            let date = PrayerDay.adding(days: offset, to: weekStart, calendar: calendar)
            return (date: date, didPray: days.contains(date))
        }
    }
}
