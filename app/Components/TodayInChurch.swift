//
//  TodayInChurch.swift
//  Lumen Viae
//
//  Today's celebration — the feast, its class, and the vestment colour —
//  read once and shared by the two pages that say the day: the home
//  ledger and the Chapel's day strip.
//

import Foundation
import Observation

// MARK: - TodayInChurch

/// Today's celebration, loaded once for the home screen.
///
/// Deliberately not `MissalViewModel`: that one owns a reader — stepping
/// days, retry copy, a week of prefetch — and the home screen wants one
/// fact. A stored day is read first and answers instantly, because the
/// propers for a date never change once published.
///
/// Every failure is silent. This is the app's most important screen, and
/// a third-party outage must never make it look broken — the ledger
/// simply keeps its plain title and the Mass stays one tap away.
@Observable
final class TodayInChurch {

    private(set) var proper: MissalProper?

    private let api = MissalAPIService.shared
    private let diskCache = MissalCacheService.shared

    /// The feast, once known. Until then the ledger names the thing itself.
    var title: String {
        proper?.info.title ?? "The Mass of the Day"
    }

    /// "III class  ·  Red", whichever parts the day carries
    var meta: String? {
        let parts = [proper?.info.rankLabel, vestment?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    var vestment: MissalVestment? {
        proper?.info.colors?.first.flatMap { MissalVestment(rawValue: $0) }
    }

    /// The day the loaded proper belongs to, so a line that was correct
    /// last night can tell that it no longer is.
    private var loadedDay: String?

    @MainActor
    func load() async {
        let day = MissalAPIService.dayString(for: .now)
        // Keyed on the day rather than on "have we loaded": Home is the
        // launch tab and does not rebuild on foreground, so an app left
        // open overnight kept yesterday's feast, rank, and vestment
        // colour on screen while THE MASS opened the right one.
        guard proper == nil || loadedDay != day else { return }

        if let stored = diskCache.loadProper(for: day)?.first {
            proper = stored
            loadedDay = day
            return
        }

        guard let fetched = try? await api.fetchPropers(day: day), !fetched.isEmpty else { return }

        diskCache.saveProper(fetched, for: day)
        proper = fetched.first
        loadedDay = day
    }
}
