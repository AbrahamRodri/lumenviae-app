//
//  ConsecrationProgress.swift
//  Lumen Viae
//
//  SwiftData model tracking 33-Day Consecration progress. The current day
//  is computed from the start date (advancing at midnight), and days must
//  be completed in order.
//

import Foundation
import SwiftData

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

    /// Whether Day 1 has come. A consecration can be chosen ahead of its
    /// feast and wait for its first day; until then it is scheduled, and
    /// no day of it is open (`currentDayNumber` holds at 1 meanwhile).
    func hasBegun(asOf now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: startDate) <= calendar.startOfDay(for: now)
    }

    /// Whether the user can access a specific day
    /// User can access today and any past days, but not future days,
    /// and none at all before Day 1 has come
    func canAccessDay(_ dayNumber: Int) -> Bool {
        hasBegun() && dayNumber <= currentDayNumber
    }

    /// Whether a specific day has been completed
    func isDayCompleted(_ dayNumber: Int) -> Bool {
        completedDays.contains(dayNumber)
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

}
