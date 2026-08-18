//
//  ConsecrationViewModel.swift
//  Lumen Viae
//
//  State and logic for the 33-Day Consecration: progress tracking,
//  prayer flow, and journal entries, persisted via SwiftData.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - ConsecrationViewModel

@Observable
final class ConsecrationViewModel {

    // MARK: - State Properties

    /// Current active consecration progress (nil if none started)
    var progress: ConsecrationProgress?

    /// Most recently completed consecration, if any. Lets the intro screen
    /// honor a finished journey instead of pretending it never happened.
    var completedProgress: ConsecrationProgress?

    /// The day currently being viewed/completed
    var currentDay: ConsecrationDay?

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

    // The prayer-flow state that used to live here (currentPrayerIndex,
    // prayersForToday, currentPrayer, hasNextPrayer, totalPrayers,
    // nextPrayer, resetPrayers) is gone. Nothing read it — the flow owns
    // its own index — and `prayersForToday` resolved through
    // `ConsecrationData.prayers(for:)`, the lookup that silently drops
    // every prayer living only in the bilingual set. For the Preparatory
    // period that is all four of them, so the property would have
    // returned an empty list to anything that ever trusted it.

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
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let results = try context.fetch(descriptor)
            progress = results.first { !$0.isCompleted }
            completedProgress = results.first { $0.isCompleted }

            // Claim any reflections written before entries were scoped, so
            // the day lookups below can match on id alone.
            backfillUnscopedJournalEntries(against: results)

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

    /// Start a new consecration with today counting as a specific day (1-34).
    ///
    /// Backdates the start date so `currentDayNumber` resolves to `dayNumber`
    /// today. Useful for joining mid-preparation (e.g., following along in a
    /// book) or catching up to a feast day that is fewer than 33 days away.
    func startConsecration(startingAt dayNumber: Int) {
        let clamped = min(max(dayNumber, 1), 34)
        let backdatedStart = Calendar.current.date(
            byAdding: .day,
            value: -(clamped - 1),
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
        startConsecration(on: backdatedStart)
    }

    /// Load the day data for the current day number
    func loadCurrentDay() {
        currentDay = ConsecrationData.day(todaysDayNumber)
        journalText = ""

        // Load existing journal entry if any
        loadJournalEntry(for: todaysDayNumber)
    }

    /// Load a specific day
    func loadDay(_ dayNumber: Int) {
        guard canAccessDay(dayNumber) else { return }
        currentDay = ConsecrationData.day(dayNumber)

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

    // MARK: - Day Completion

    /// Complete a specific day with a journal entry. The day number comes
    /// from the view that collected the reflection, not from `currentDay`,
    /// so a stale or missing `currentDay` can never complete the wrong day.
    func completeDay(dayNumber: Int, journalEntry: String) {
        guard let context = modelContext,
              let progress = progress else { return }

        // Save journal entry
        saveJournalEntry(journalEntry, for: dayNumber)

        // Mark day as complete
        progress.completeDay(dayNumber)

        // Finishing Day 34 completes the consecration: surface it right
        // away so the intro screen shows the completed banner without
        // needing to leave and re-enter the tab.
        if progress.isCompleted {
            completedProgress = progress
        }

        do {
            try context.save()
        } catch {
            errorMessage = "Failed to complete day: \(error.localizedDescription)"
        }
    }

    /// Save a reflection without keeping the day. The day's index can
    /// carry the user from the reflection back to a prayer mid-sentence,
    /// and that move must never cost them what they had written.
    func saveReflectionDraft(_ content: String, for dayNumber: Int) {
        saveJournalEntry(content, for: dayNumber)
        journalText = content
    }

    // MARK: - Journal Management

    /// The reflection for one day of the *active* consecration.
    ///
    /// Scoped by `consecrationId`, not day number alone: a repeat journey
    /// would otherwise open the previous one's Day N and overwrite it.
    private func entryDescriptor(for dayNumber: Int, in consecrationId: UUID) -> FetchDescriptor<JournalEntry> {
        let consecrationTypeRaw = JournalEntryType.consecration.rawValue
        return FetchDescriptor<JournalEntry>(
            predicate: #Predicate {
                $0.entryTypeRaw == consecrationTypeRaw
                    && $0.consecrationDay == dayNumber
                    && $0.consecrationId == consecrationId
            }
        )
    }

    /// Load existing journal entry for a day
    private func loadJournalEntry(for dayNumber: Int) {
        guard let context = modelContext, let progress else {
            journalText = ""
            return
        }

        do {
            let results = try context.fetch(entryDescriptor(for: dayNumber, in: progress.id))
            journalText = results.first?.text ?? ""
        } catch {
            journalText = ""
        }
    }

    /// Save journal entry for a day. Blank reflections are skipped: they
    /// would render as empty cards in the Journal tab, and overwriting an
    /// existing entry with blank text on a review pass would lose it.
    private func saveJournalEntry(_ content: String, for dayNumber: Int) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let context = modelContext,
              let progress,
              let phase = ConsecrationPhase.phase(for: dayNumber) else { return }

        do {
            let results = try context.fetch(entryDescriptor(for: dayNumber, in: progress.id))
            if let existing = results.first {
                existing.text = content
            } else {
                let newEntry = JournalEntry(
                    text: content,
                    consecrationDay: dayNumber,
                    consecrationPhase: phase,
                    consecrationId: progress.id
                )
                context.insert(newEntry)
            }
            try context.save()
        } catch {
            errorMessage = "Failed to save journal: \(error.localizedDescription)"
        }
    }

    /// Assigns pre-scoping reflections to the consecration they were
    /// written during.
    ///
    /// Entries predating `consecrationId` carry none, and a day number
    /// alone can't tell two journeys apart. Each is matched to the
    /// consecration whose 34-day window contains its creation date, and
    /// otherwise to the earliest consecration — before this change only one
    /// could exist at a time, so an unmatched entry belongs to the first.
    /// Runs once: after it, no consecration entry has a nil id.
    private func backfillUnscopedJournalEntries(against allProgress: [ConsecrationProgress]) {
        guard let context = modelContext, !allProgress.isEmpty else { return }

        let consecrationTypeRaw = JournalEntryType.consecration.rawValue
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate {
                $0.entryTypeRaw == consecrationTypeRaw && $0.consecrationId == nil
            }
        )

        guard let orphans = try? context.fetch(descriptor), !orphans.isEmpty else { return }

        let calendar = Calendar.current
        let oldest = allProgress.min { $0.startDate < $1.startDate }

        for entry in orphans {
            let owner = allProgress.first { progress in
                let start = calendar.startOfDay(for: progress.startDate)
                guard let end = calendar.date(byAdding: .day, value: 34, to: start) else { return false }
                return entry.createdAt >= start && entry.createdAt < end
            }
            entry.consecrationId = (owner ?? oldest)?.id
        }

        try? context.save()
    }

    // MARK: - Reset

    /// Reset the view model state (e.g., when leaving the tab)
    func reset() {
        journalText = ""
        errorMessage = nil
    }

    /// Delete the active consecration so the user can start over — a
    /// wrong feast pick or an abandoned attempt shouldn't lock the tab
    /// for 34 days. Journal reflections written along the way are kept.
    func abandonConsecration() {
        guard let context = modelContext,
              let progress = progress else { return }

        context.delete(progress)

        do {
            try context.save()
            self.progress = nil
            self.currentDay = nil
            self.journalText = ""
        } catch {
            errorMessage = "Failed to reset consecration: \(error.localizedDescription)"
        }
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
        abandonConsecration()
    }
    #endif
}
