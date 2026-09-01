//
//  CanonicalClock.swift
//  Lumen Viae
//
//  Which canonical hour it is, right now — the one fact the home ledger
//  and the Office landing both stand on, and the one thing on either
//  page that goes stale by the clock rather than by the day.
//
//  Deliberately not computed afresh in a view body. Both surfaces read
//  the same value, both must roll over at the same moment, and a body
//  that reads `Date()` only re-reads it when something else happens to
//  redraw — so at noon the arch said Terce until the user scrolled.
//
//  Purely local. The hours of the day are not fetched, so this keeps
//  working in a chapel with no signal, which is the whole point of
//  lifting the present hour onto the page.
//

import Foundation
import Observation

@Observable
final class CanonicalClock {

    static let shared = CanonicalClock()

    /// The hour whose traditional time holds this moment
    private(set) var hour: CanonicalHour

    /// When the present hour lapses — held so a view can name it
    private(set) var rollsOverAt: Date

    @ObservationIgnored private var rollover: Task<Void, Never>?
    @ObservationIgnored private let calendar = Calendar.current

    private init() {
        let now = Date()
        hour = CanonicalHour.present(atClockHour: Calendar.current.component(.hour, from: now))
        rollsOverAt = Self.nextBoundary(after: now, calendar: Calendar.current)
        scheduleRollover()
    }

    /// Re-reads the clock. Called on the boundary by the sleeping task,
    /// and by any page coming back to the foreground — a task asleep
    /// through a suspension may wake late, and the answer must be right
    /// the instant the page is seen, not a second afterwards.
    func refresh() {
        let now = Date()
        let present = CanonicalHour.present(atClockHour: calendar.component(.hour, from: now))
        if present != hour {
            hour = present
        }
        rollsOverAt = Self.nextBoundary(after: now, calendar: calendar)
        scheduleRollover()
    }

    // MARK: - Rollover

    /// Sleeps to the next boundary rather than ticking. Eight wakes a
    /// day, not one a minute.
    private func scheduleRollover() {
        rollover?.cancel()
        let seconds = max(1, rollsOverAt.timeIntervalSinceNow)

        rollover = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    /// The next moment at which the present hour gives way. Derived from
    /// `beginsAtClockHour`, so it can never disagree with which hour the
    /// ledger marks as present.
    private static func nextBoundary(after now: Date, calendar: Calendar) -> Date {
        let present = CanonicalHour.present(atClockHour: calendar.component(.hour, from: now))
        let target = present.following.beginsAtClockHour

        guard var candidate = calendar.date(bySettingHour: target, minute: 0, second: 0, of: now) else {
            return now.addingTimeInterval(3600)
        }
        // Compline gives way to Matins at midnight, which is tomorrow's
        // — and a day that springs forward can leave the boundary behind
        // us too.
        if candidate <= now {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate.addingTimeInterval(86400)
        }
        return candidate
    }
}
