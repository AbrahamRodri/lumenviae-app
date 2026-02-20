//
//  ConsecrationProgress.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION PROGRESS - SWIFTDATA MODEL FOR TRACKING 33-DAY PROGRESS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Tracks the user's progress through the 33-Day Total Consecration.
//  Stores the start date and completed days, enabling:
//  - Auto-calculation of current day based on start date
//  - Progress persistence across app sessions
//  - Multiple consecration attempts (only one active at a time)
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftData

// MARK: - ConsecrationProgress

/// Tracks progress through the 33-Day Consecration journey.
///
/// ## SwiftData
/// The `@Model` macro makes this class persistable with SwiftData.
///
/// ## Key Behavior
/// - `currentDayNumber` is computed from the start date
/// - Days automatically advance at midnight
/// - User cannot skip ahead - must complete days in order
///
@Model
final class ConsecrationProgress {

    // MARK: - Properties

    /// Unique identifier for this consecration attempt
    var id: UUID

    /// The date the consecration began
    var startDate: Date

    /// Array of day numbers that have been completed (1-34)
    /// Stored as comma-separated string for SwiftData compatibility
    var completedDaysRaw: String

    /// Whether the entire consecration has been completed (all 34 days)
    var isCompleted: Bool

    /// When the consecration was completed (Day 34 finished)
    var completedAt: Date?

    /// When this record was created
    var createdAt: Date

    // MARK: - Computed Properties

    /// The day numbers that have been completed
    var completedDays: Set<Int> {
        get {
            guard !completedDaysRaw.isEmpty else { return [] }
            let days = completedDaysRaw.split(separator: ",").compactMap { Int($0) }
            return Set(days)
        }
        set {
            completedDaysRaw = newValue.sorted().map(String.init).joined(separator: ",")
        }
    }

    /// What day should show today (based on start date)
    /// Returns 1-34, capped at 34
    var currentDayNumber: Int {
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let daysSinceStart = calendar.dateComponents([.day], from: startOfStartDate, to: startOfToday).day ?? 0
        return min(max(daysSinceStart + 1, 1), 34)
    }

    /// The current phase based on the current day
    var currentPhase: ConsecrationPhase? {
        ConsecrationPhase.phase(for: currentDayNumber)
    }

    /// Progress percentage through the entire consecration (0.0 to 1.0)
    var progressPercentage: Double {
        Double(completedDays.count) / 34.0
    }

    /// The highest day number that has been completed
    var highestCompletedDay: Int {
        completedDays.max() ?? 0
    }

    /// Whether the user can access a specific day
    /// User can access today and any past days, but not future days
    func canAccessDay(_ dayNumber: Int) -> Bool {
        dayNumber <= currentDayNumber
    }

    /// Whether a specific day has been completed
    func isDayCompleted(_ dayNumber: Int) -> Bool {
        completedDays.contains(dayNumber)
    }

    /// The next day that needs to be completed
    /// Returns nil if all days are completed
    var nextIncompleteDay: Int? {
        for day in 1...34 {
            if !completedDays.contains(day) && canAccessDay(day) {
                return day
            }
        }
        return nil
    }

    // MARK: - Initialization

    /// Creates a new consecration progress record.
    ///
    /// - Parameter startDate: The date to begin the consecration
    init(startDate: Date = Date()) {
        self.id = UUID()
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.completedDaysRaw = ""
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
    }

    // MARK: - Methods

    /// Mark a day as completed
    func completeDay(_ dayNumber: Int) {
        guard dayNumber >= 1, dayNumber <= 34 else { return }
        var days = completedDays
        days.insert(dayNumber)
        completedDays = days

        // Check if this completes the entire consecration
        if dayNumber == 34 {
            isCompleted = true
            completedAt = Date()
        }
    }

    /// Calculate the consecration end date (Day 34)
    var expectedCompletionDate: Date {
        Calendar.current.date(byAdding: .day, value: 33, to: startDate) ?? startDate
    }

    /// Days remaining until completion
    var daysRemaining: Int {
        34 - completedDays.count
    }
}
