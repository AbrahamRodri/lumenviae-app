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
        /// The Rosary Aloud, which prays on the Scriptural Rosary's
        /// screens and must come back as itself, not as a verse a bead
        case rosaryAloud = "rosary_aloud"
    }

    let kind: Kind?

    /// True for a Scriptural Rosary, which resumes on its own screen
    var isScripturalRosary: Bool { kind == .scripturalRosary }

    /// The form a Rosary prayed on the Scriptural Rosary's screens comes
    /// back in; nil for a meditation set's
    var spokenForm: SpokenForm? {
        switch kind {
        case .scripturalRosary: return .scriptural
        case .rosaryAloud: return .plain
        case .meditationSet, nil: return nil
        }
    }

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

    /// The prayer a Rosary said aloud had reached in its script, so it
    /// resumes there rather than at the start of the bead. Nil for a
    /// Rosary prayed by hand, and in snapshots written before the
    /// spoken Rosary.
    var spokenStep: SpokenStep? = nil

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
        // The voice's place in the script is kept across the bead's own
        // saves while a spoken Rosary of this same prayer is running; a
        // Rosary prayed by hand has no place in a script
        let previous = self.snapshot
        let samePrayer = previous.map {
            $0.kind ?? .meditationSet == kind && $0.meditationSetId == setId && $0.category == category
        } ?? false
        let step = spokenStepIsLive && samePrayer ? previous?.spokenStep : nil

        let fresh = InProgressPrayer(
            kind: kind,
            meditationSetId: setId,
            setName: setName,
            category: category,
            mysteryIndex: mysteryIndex,
            beadIndex: beadIndex,
            spokenStep: step,
            startedAt: startedAt,
            accumulatedSeconds: accumulatedSeconds,
            savedAt: Date()
        )
        write(fresh)
    }

    // MARK: - The Rosary Said Aloud

    /// Whether a spoken Rosary is running in this launch, keeping the
    /// snapshot's `spokenStep` current
    private var spokenStepIsLive = false

    /// The spoken Rosary has begun a step. Kept on the snapshot of the
    /// same prayer, if the prayer has saved one yet; the opening prayers,
    /// said before the first bead, leave nothing to resume.
    func updateSpokenStep(
        _ step: SpokenStep,
        kind: InProgressPrayer.Kind,
        setId: Int,
        category: String
    ) {
        spokenStepIsLive = true
        guard var current = snapshot,
              current.kind ?? .meditationSet == kind,
              current.meditationSetId == setId,
              current.category == category,
              current.spokenStep != step else { return }
        current.spokenStep = step
        write(current)
    }

    /// The spoken Rosary has stopped. Leaving the screen keeps the step
    /// to resume at; turning praying aloud off forgets it, since the
    /// hand now keeps the place.
    func endSpokenSteps(forgettingStep: Bool) {
        spokenStepIsLive = false
        guard forgettingStep, var current = snapshot, current.spokenStep != nil else { return }
        current.spokenStep = nil
        write(current)
    }

    /// The step a resumed Rosary said aloud stopped on: only for the same
    /// prayer, in the decade being resumed, and no earlier than its bead.
    func spokenStep(
        kind: InProgressPrayer.Kind,
        setId: Int,
        category: String,
        mysteryIndex: Int,
        beadIndex: Int
    ) -> SpokenStep? {
        guard let current = inProgress,
              current.kind ?? .meditationSet == kind,
              current.meditationSetId == setId,
              current.category == category,
              let step = current.spokenStep,
              step.mystery == mysteryIndex,
              step.bead >= beadIndex else { return nil }
        return step
    }

    private func write(_ snapshot: InProgressPrayer) {
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
