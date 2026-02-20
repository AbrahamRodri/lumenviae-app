//
//  ConsecrationViewModel.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION VIEW MODEL - STATE MANAGEMENT FOR 33-DAY CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Manages all state and logic for the 33-Day Consecration feature:
//  - Progress tracking (current day, completed days)
//  - Prayer flow state (current prayer index)
//  - Journal entry management
//  - Data persistence via SwiftData
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftUI
import SwiftData

// MARK: - ConsecrationViewModel

@Observable
final class ConsecrationViewModel {

    // MARK: - State Properties

    /// Current active consecration progress (nil if none started)
    var progress: ConsecrationProgress?

    /// The day currently being viewed/completed
    var currentDay: ConsecrationDay?

    /// Current prayer index during prayer flow (0-based)
    var currentPrayerIndex: Int = 0

    /// Text being entered in the journal
    var journalText: String = ""

    /// Loading state
    var isLoading: Bool = false

    /// Error message if something goes wrong
    var errorMessage: String?

    // MARK: - Private Properties

    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    /// Whether there's an active (non-completed) consecration
    var hasActiveConsecration: Bool {
        guard let progress = progress else { return false }
        return !progress.isCompleted
    }

    /// Today's day number based on start date (1-34)
    var todaysDayNumber: Int {
        progress?.currentDayNumber ?? 1
    }

    /// The current phase based on today's day
    var currentPhase: ConsecrationPhase? {
        ConsecrationPhase.phase(for: todaysDayNumber)
    }

    /// Prayers for the current day (based on phase)
    var prayersForToday: [ConsecrationPrayer] {
        guard let phase = currentPhase else { return [] }
        return ConsecrationData.prayers(for: phase)
    }

    /// Overall progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        progress?.progressPercentage ?? 0.0
    }

    /// Number of completed days
    var completedDaysCount: Int {
        progress?.completedDays.count ?? 0
    }

    /// Days remaining in the consecration
    var daysRemaining: Int {
        progress?.daysRemaining ?? 34
    }

    /// The current prayer being displayed
    var currentPrayer: ConsecrationPrayer? {
        guard currentPrayerIndex < prayersForToday.count else { return nil }
        return prayersForToday[currentPrayerIndex]
    }

    /// Whether there's a next prayer available
    var hasNextPrayer: Bool {
        currentPrayerIndex < prayersForToday.count - 1
    }

    /// Total number of prayers for today
    var totalPrayers: Int {
        prayersForToday.count
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Model Context

    /// Set the SwiftData model context
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Progress Management

    /// Load existing progress from SwiftData
    func loadProgress() {
        guard let context = modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<ConsecrationProgress>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let results = try context.fetch(descriptor)
            progress = results.first
            loadCurrentDay()
        } catch {
            errorMessage = "Failed to load progress: \(error.localizedDescription)"
        }
    }

    /// Start a new consecration
    func startConsecration(on date: Date) {
        guard let context = modelContext else { return }

        let newProgress = ConsecrationProgress(startDate: date)
        context.insert(newProgress)

        do {
            try context.save()
            progress = newProgress
            loadCurrentDay()
        } catch {
            errorMessage = "Failed to start consecration: \(error.localizedDescription)"
        }
    }

    /// Load the day data for the current day number
    func loadCurrentDay() {
        currentDay = ConsecrationData.day(todaysDayNumber)
        currentPrayerIndex = 0
        journalText = ""

        // Load existing journal entry if any
        loadJournalEntry(for: todaysDayNumber)
    }

    /// Load a specific day
    func loadDay(_ dayNumber: Int) {
        guard canAccessDay(dayNumber) else { return }
        currentDay = ConsecrationData.day(dayNumber)
        currentPrayerIndex = 0

        // Load existing journal entry if any
        loadJournalEntry(for: dayNumber)
    }

    /// Check if user can access a specific day
    func canAccessDay(_ day: Int) -> Bool {
        progress?.canAccessDay(day) ?? false
    }

    /// Check if a day has been completed
    func isDayCompleted(_ dayNumber: Int) -> Bool {
        progress?.isDayCompleted(dayNumber) ?? false
    }

    // MARK: - Prayer Flow

    /// Advance to the next prayer
    /// Returns true if advanced, false if no more prayers
    func nextPrayer() -> Bool {
        if hasNextPrayer {
            currentPrayerIndex += 1
            return true
        }
        return false
    }

    /// Reset prayer index to start
    func resetPrayers() {
        currentPrayerIndex = 0
    }

    // MARK: - Day Completion

    /// Complete the current day with a journal entry
    func completeDay(journalEntry: String) {
        guard let context = modelContext,
              let day = currentDay,
              let progress = progress else { return }

        // Save journal entry
        saveJournalEntry(journalEntry, for: day.dayNumber)

        // Mark day as complete
        progress.completeDay(day.dayNumber)

        do {
            try context.save()
        } catch {
            errorMessage = "Failed to complete day: \(error.localizedDescription)"
        }
    }

    // MARK: - Journal Management

    /// Load existing journal entry for a day
    private func loadJournalEntry(for dayNumber: Int) {
        guard let context = modelContext else { return }

        let consecrationTypeRaw = JournalEntryType.consecration.rawValue
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate {
                $0.entryTypeRaw == consecrationTypeRaw && $0.consecrationDay == dayNumber
            }
        )

        do {
            let results = try context.fetch(descriptor)
            journalText = results.first?.text ?? ""
        } catch {
            journalText = ""
        }
    }

    /// Save journal entry for a day
    private func saveJournalEntry(_ content: String, for dayNumber: Int) {
        guard let context = modelContext,
              let phase = ConsecrationPhase.phase(for: dayNumber) else { return }

        // Check for existing entry
        let consecrationTypeRaw = JournalEntryType.consecration.rawValue
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate {
                $0.entryTypeRaw == consecrationTypeRaw && $0.consecrationDay == dayNumber
            }
        )

        do {
            let results = try context.fetch(descriptor)
            if let existing = results.first {
                existing.text = content
            } else {
                let newEntry = JournalEntry(
                    text: content,
                    consecrationDay: dayNumber,
                    consecrationPhase: phase
                )
                context.insert(newEntry)
            }
            try context.save()
        } catch {
            errorMessage = "Failed to save journal: \(error.localizedDescription)"
        }
    }

    // MARK: - Reset

    /// Reset the view model state (e.g., when leaving the tab)
    func reset() {
        currentPrayerIndex = 0
        journalText = ""
        errorMessage = nil
    }

    // MARK: - Debug Methods (Testing Only)

    #if DEBUG
    /// Advance the start date by 1 day to simulate moving to the next day
    func debugAdvanceDay() {
        guard let context = modelContext,
              let progress = progress else { return }

        // Move start date back by 1 day (which advances the current day)
        if let newStartDate = Calendar.current.date(byAdding: .day, value: -1, to: progress.startDate) {
            progress.startDate = newStartDate
            do {
                try context.save()
                loadCurrentDay()
            } catch {
                errorMessage = "Debug: Failed to advance day"
            }
        }
    }

    /// Reset/delete the current consecration to start fresh
    func debugResetConsecration() {
        guard let context = modelContext,
              let progress = progress else { return }

        context.delete(progress)

        do {
            try context.save()
            self.progress = nil
            self.currentDay = nil
            self.journalText = ""
            self.currentPrayerIndex = 0
        } catch {
            errorMessage = "Debug: Failed to reset consecration"
        }
    }
    #endif
}
