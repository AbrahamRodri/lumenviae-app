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

    /// The breviary's day, read only in a Spanish app: the Missal's titles
    /// are English, so there the feast is named as the Hours of Prayer name
    /// it, in Latin, never in English
    private(set) var office: OfficeDay?

    private let spanish: Bool

    private let api = MissalAPIService.shared
    private let diskCache = MissalCacheService.shared

    /// A day already known, for previews and snapshots; the app starts
    /// empty and loads
    init(proper: MissalProper? = nil, office: OfficeDay? = nil, spanish: Bool = SpanishContent.isActive) {
        self.proper = proper
        self.office = office
        self.spanish = spanish
    }

    /// The feast, once known. Until then the ledger names the thing itself.
    /// In Spanish, the Hours of Prayer's own name for the day
    /// (`OfficeViewModel.feastTitle`), so Home's Mass row and that page
    /// never name one feast in two languages.
    var title: String {
        let untitled = String(localized: "Today's Mass", comment: "The day's Mass, named before its feast is known")
        guard spanish else { return proper?.info.title ?? untitled }
        return OfficeViewModel.feastTitle(
            missal: proper?.info.title, breviary: office?.celebration?.title,
            rank: office?.celebration?.rank, spanish: true
        ) ?? untitled
    }

    /// Whether `title` names the feast yet, rather than the Mass itself:
    /// in Spanish only once the breviary's day has come
    var namesFeast: Bool {
        spanish ? office?.celebration?.title != nil : proper != nil
    }

    /// "Feast  ·  Red vestments", whichever parts the day carries — the
    /// rank in plain words (`DayRank`), the colour never bare
    var meta: String? {
        let parts = [rank, vestment?.plainName].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    /// "Great Feast", "Feast", "Lesser Feast", "Weekday" — the word
    /// Home's Mass row and the Chapel set beside the day's silk
    var rank: String? {
        proper?.info.rankLabel
    }

    /// The day as VoiceOver says it, colour included even where the
    /// screen shows it only as a dot: "Feast, red vestments"
    var spokenMeta: String? {
        let parts = [rank, vestment?.plainName.lowercased()].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
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
        guard proper == nil || loadedDay != day || (spanish && office == nil) else { return }

        // A new day lets go of the last one's feast before it looks for
        // its own: kept while the store missed and the fetch failed, it
        // set yesterday's feast beside today's date until a load came good
        if loadedDay != day {
            proper = nil
            office = nil
            loadedDay = nil
        }
        // In Spanish the breviary's day is asked for beside the Missal,
        // never before it: our /office engine sleeps when idle, and the
        // rank and vestment once waited on it waking
        async let breviary: Void = loadOffice(day: day)
        async let missal: Void = loadProper(day: day)
        _ = await (breviary, missal)
    }

    /// The Missal's propers for the day: the disk first, then Missale Meum
    @MainActor
    private func loadProper(day: String) async {
        if let stored = diskCache.loadProper(for: day)?.first {
            proper = stored
            loadedDay = day
            return
        }

        guard let fetched = try? await api.fetchPropers(day: day), !fetched.isEmpty else { return }

        diskCache.saveProper(fetched, for: day)

        // A fetch asked before midnight and answered after it is still
        // that day's feast, kept on disk for it, but no longer today's:
        // set here, it would stand over the new day's until the next load
        guard MissalAPIService.dayString(for: .now) == day else { return }
        proper = fetched.first
        loadedDay = day
    }

    /// The breviary's day for the Spanish title: the disk first, then our
    /// own /office API. A day the API cannot give leaves the Missal's
    /// name out, and the row says "Today's Mass" rather than English.
    @MainActor
    private func loadOffice(day: String) async {
        guard spanish, office?.date != day else { return }
        if let stored = OfficeCacheService.shared.loadDay(for: day) {
            office = stored
            return
        }
        guard let fetched = try? await OfficeAPIService.shared.fetchDay(day: day) else { return }
        OfficeCacheService.shared.saveDay(fetched, for: day)
        guard MissalAPIService.dayString(for: .now) == day else { return }
        office = fetched
    }
}
