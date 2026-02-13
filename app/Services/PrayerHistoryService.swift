//
//  PrayerHistoryService.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  PRAYER HISTORY SERVICE - MANAGES PRAYER SESSION DATA & STATISTICS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  This service handles all prayer history operations:
//  - Recording completed prayer sessions
//  - Calculating streaks
//  - Computing statistics (totals, by category, by time period)
//
//  Uses SwiftData for persistence with the PrayerSession model.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftData

// MARK: - PrayerHistoryService

/// Service for managing prayer session history and statistics.
///
/// ## Usage
/// ```swift
/// @Environment(\.modelContext) private var modelContext
/// let service = PrayerHistoryService(modelContext: modelContext)
/// service.recordSession(category: .joyful)
/// ```
///
@Observable
final class PrayerHistoryService {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recording Sessions

    /// Records a completed prayer session.
    ///
    /// - Parameters:
    ///   - category: The mystery category that was prayed
    ///   - durationSeconds: How long the session took (optional)
    ///   - meditationType: The meditation style used (optional)
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

    /// Fetches sessions completed on a specific date.
    func sessions(on date: Date) -> [PrayerSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<PrayerSession> { session in
            session.completedAt >= startOfDay && session.completedAt < endOfDay
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

    /// Number of Rosaries completed this week.
    func rosariesThisWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return 0
        }
        return sessions(from: weekStart, to: today).count
    }

    /// Number of Rosaries completed this month.
    func rosariesThisMonth() -> Int {
        let calendar = Calendar.current
        let today = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return 0
        }
        return sessions(from: monthStart, to: today).count
    }

    // MARK: - Streak Calculation

    /// Current consecutive days of prayer.
    ///
    /// A streak counts consecutive days where at least one Rosary was completed.
    /// Today counts if a prayer was done today; otherwise streak starts from yesterday.
    func currentStreak() -> Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var streak = 0

        // Check if prayed today
        let todaySessions = sessions(on: currentDate)
        if todaySessions.isEmpty {
            // No prayer today - check if there's a streak ending yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return 0
            }
            currentDate = yesterday
        }

        // Count consecutive days backwards
        while true {
            let daySessions = sessions(on: currentDate)
            if daySessions.isEmpty {
                break
            }
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }

    /// Longest streak ever achieved.
    func longestStreak() -> Int {
        let sessions = allSessions()
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current

        // Get unique prayer dates
        var prayerDates = Set<Date>()
        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.completedAt)
            prayerDates.insert(dayStart)
        }

        // Sort dates
        let sortedDates = prayerDates.sorted()

        var longestStreak = 1
        var currentStreak = 1

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

    /// Returns prayer status for the current week.
    ///
    /// - Returns: Array of 7 tuples (date, didPray) for Sun-Sat
    func weeklyPrayerStatus() -> [(date: Date, didPray: Bool)] {
        let calendar = Calendar.current
        let today = Date()

        // Get start of week (Sunday)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        var result: [(date: Date, didPray: Bool)] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }
            let didPray = !sessions(on: date).isEmpty
            result.append((date: date, didPray: didPray))
        }

        return result
    }
}
