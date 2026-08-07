//
//  PrayerResumeService.swift
//  Lumen Viae
//
//  Remembers where an unfinished Rosary left off so an interruption —
//  a phone call, a knock at the door, a force-quit — doesn't discard a
//  15-minute devotion. The prayer flow saves its position as the user
//  advances; Home offers to continue; completion clears it.
//
//  Only lightweight identifiers are stored. On resume, the meditation
//  set itself is re-resolved (bundled set, offline fallback, or API).
//

import Foundation

// MARK: - InProgressPrayer

/// A snapshot of an unfinished Rosary session.
struct InProgressPrayer: Codable, Equatable {
    /// Meditation set ID (negative = bundled local set, 0 = offline fallback)
    let meditationSetId: Int

    /// Set name for display ("St. Louis de Montfort")
    let setName: String

    /// Raw category string ("sorrowful")
    let category: String

    /// 0-based index of the mystery the user was on
    let mysteryIndex: Int

    /// When the session originally started (drives recorded duration)
    let startedAt: Date

    /// When this snapshot was last written (drives expiry)
    let savedAt: Date
}

// MARK: - PrayerResumeService

@Observable
final class PrayerResumeService {

    static let shared = PrayerResumeService()

    /// The unfinished session, if one exists and hasn't expired.
    private(set) var inProgress: InProgressPrayer?

    private static let storageKey = "prayerResume.inProgress"

    /// A session older than this is quietly dropped — nobody resumes the
    /// 3rd mystery two days later.
    private static let expiry: TimeInterval = 24 * 60 * 60

    private init() {
        load()
    }

    // MARK: - API

    /// Records the user's current position; called as the prayer advances.
    func save(setId: Int, setName: String, category: String, mysteryIndex: Int, startedAt: Date) {
        let snapshot = InProgressPrayer(
            meditationSetId: setId,
            setName: setName,
            category: category,
            mysteryIndex: mysteryIndex,
            startedAt: startedAt,
            savedAt: Date()
        )
        inProgress = snapshot
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    /// Clears the snapshot — on completion, or when the user dismisses it.
    func clear() {
        inProgress = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(InProgressPrayer.self, from: data) else {
            return
        }
        if Date().timeIntervalSince(snapshot.savedAt) > Self.expiry {
            clear()
        } else {
            inProgress = snapshot
        }
    }
}
