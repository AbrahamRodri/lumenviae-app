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

    /// Which prayer the snapshot belongs to. Optional because snapshots
    /// written before the Scriptural Rosary existed carry no kind, and
    /// every one of them was a meditation set.
    enum Kind: String, Codable {
        case meditationSet = "meditation_set"
        case scripturalRosary = "scriptural_rosary"
    }

    let kind: Kind?

    /// True for a Scriptural Rosary, which resumes on its own screen
    var isScripturalRosary: Bool { kind == .scripturalRosary }

    /// Meditation set ID (negative = bundled local set, 0 = built-in
    /// fallback). Meaningless for a Scriptural Rosary, which has no set.
    let meditationSetId: Int

    /// Set name for display ("St. Louis de Montfort")
    let setName: String

    /// Raw category string ("sorrowful")
    let category: String

    /// 0-based index of the mystery the user was on
    let mysteryIndex: Int

    /// The bead of that decade the hand was on — 0 the Our Father, then
    /// each Hail Mary, then the Glory Be. Optional because snapshots
    /// written before the beads were walked carry none, and every one
    /// of them began its decade on the Our Father.
    let beadIndex: Int?

    /// When the devotion originally began (display only — never used
    /// for duration, which would count interruption gaps as prayer)
    let startedAt: Date

    /// Seconds actually spent praying across all segments so far
    let accumulatedSeconds: Int

    /// When this snapshot was last written (drives expiry)
    let savedAt: Date
}

// MARK: - PrayerResumeService

@Observable
final class PrayerResumeService {

    static let shared = PrayerResumeService()

    /// Backing storage; expiry is enforced in the `inProgress` accessor so
    /// a long-suspended process can't surface a days-old card.
    private var snapshot: InProgressPrayer?

    /// The unfinished session, if one exists and hasn't expired.
    var inProgress: InProgressPrayer? {
        guard let snapshot else { return nil }
        guard Date().timeIntervalSince(snapshot.savedAt) <= Self.expiry else {
            return nil
        }
        return snapshot
    }

    private static let storageKey = "prayerResume.inProgress"

    /// A session older than this is quietly dropped — nobody resumes the
    /// 3rd mystery two days later.
    private static let expiry: TimeInterval = 24 * 60 * 60

    private init() {
        load()
    }

    // MARK: - API

    /// Records the user's current position; called as the prayer advances.
    func save(
        kind: InProgressPrayer.Kind = .meditationSet,
        setId: Int,
        setName: String,
        category: String,
        mysteryIndex: Int,
        beadIndex: Int = 0,
        startedAt: Date,
        accumulatedSeconds: Int
    ) {
        let snapshot = InProgressPrayer(
            kind: kind,
            meditationSetId: setId,
            setName: setName,
            category: category,
            mysteryIndex: mysteryIndex,
            beadIndex: beadIndex,
            startedAt: startedAt,
            accumulatedSeconds: accumulatedSeconds,
            savedAt: Date()
        )
        self.snapshot = snapshot
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    /// Clears the snapshot — on completion, or when the user dismisses it.
    func clear() {
        snapshot = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let stored = try? JSONDecoder().decode(InProgressPrayer.self, from: data) else {
            // Missing or unreadable (schema change): drop any stale blob
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
            return
        }
        if Date().timeIntervalSince(stored.savedAt) > Self.expiry {
            clear()
        } else {
            snapshot = stored
        }
    }
}
