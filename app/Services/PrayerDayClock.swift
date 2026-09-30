//
//  PrayerDayClock.swift
//  Lumen Viae
//
//  Today's prayer day (`PrayerDay`), held where a page can watch it, so
//  what the Chapel and the Prayer Record say about today rolls over at
//  four in the morning while they are open. A body that reads `Date()`
//  only re-reads it when something else redraws it, and the Chapel went
//  on saying a Rosary was offered today until a prayer or a scroll
//  happened to redraw it.
//
//  Built as `CanonicalClock` is: it sleeps to the turn rather than
//  ticking, and is refreshed whenever the app comes back to the
//  foreground, since a task asleep through a suspension may wake late.
//

import Foundation
import Observation

@Observable
final class PrayerDayClock {

    static let shared = PrayerDayClock()

    /// Today's prayer day, named by its calendar date's midnight
    private(set) var today: Date

    @ObservationIgnored private var rollover: Task<Void, Never>?

    private init() {
        today = PrayerDay.today()
        scheduleRollover()
    }

    /// Re-reads the day. Called at the turn by the sleeping task, and by
    /// the app coming back to the foreground.
    func refresh() {
        let present = PrayerDay.today()
        if present != today {
            today = present
        }
        scheduleRollover()
    }

    /// Sleeps to the next turn: one wake a day
    private func scheduleRollover() {
        rollover?.cancel()
        let now = PrayerDay.now
        let seconds = max(1, PrayerDay.nextTurn(after: now).timeIntervalSince(now))

        rollover = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }
}
