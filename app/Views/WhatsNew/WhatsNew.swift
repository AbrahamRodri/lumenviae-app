//
//  WhatsNew.swift
//  Lumen Viae
//
//  What a version added, shown once to someone who knew the version
//  before it: after launch, on the home page, never over a prayer. A new
//  install never sees it — the introduction and the first-use tour meet
//  it instead — so the notes are only ever news.
//
//  To write the next version's notes, add a `WhatsNewRelease` to `all`
//  whose `version` is the new MARKETING_VERSION exactly ("4.1"). A
//  version with no entry shows nothing, a point release included, and
//  its number is still recorded as seen. Someone who skips a version sees
//  only the notes of the one they arrive at.
//

import Foundation

// MARK: - WhatsNewItem

/// One thing a version added: its own name, one plain line, and the door
/// straight to it.
struct WhatsNewItem: Identifiable {
    let icon: String
    let title: String
    let detail: String
    let route: AppRoute

    var id: String { title }
}

// MARK: - WhatsNewRelease

/// A version's notes. Few items, the app's own names, what each is
/// before anything about it, and no counts or durations.
struct WhatsNewRelease: Identifiable {
    let version: String
    let items: [WhatsNewItem]

    var id: String { version }

    static let all: [WhatsNewRelease] = [
        WhatsNewRelease(version: "4.0", items: [
            WhatsNewItem(
                icon: "ch-praying-hands",
                title: "The Prayer Book",
                detail: "The Church's common prayers, set out for the hour of the day, to pray aloud or in silence",
                route: .prayerBook
            ),
            WhatsNewItem(
                icon: "ph-music-note",
                title: "The Chant Library",
                detail: "The Church's own songs in Gregorian chant, each with its recording and its score",
                route: .chantLibrary
            ),
            WhatsNewItem(
                icon: PrayerShortcut.rosaryAloud.icon,
                title: "The Holy Rosary",
                detail: "Every prayer of the Rosary said aloud, in the voice you choose, at the speed you set",
                // Today's mysteries: the notes are decided at launch and
                // shown the same day
                route: .rosaryAloud(ScheduleService.categoryForToday())
            ),
            WhatsNewItem(
                icon: "lv-rosary",
                title: "How to Pray the Rosary",
                detail: "A short course for someone new to it, then Your First Rosary, a prayer at a time",
                route: .howToPray
            )
            // The Scriptural Rosary and the narration voices came in 3.0
            // (CHANGELOG.md), so they are no news to someone arriving
            // from it
        ])
    ]

    static func release(for version: String) -> WhatsNewRelease? {
        all.first { $0.version == version }
    }
}

// MARK: - WhatsNewStore

/// Whether this launch owes someone a version's notes, and the record that
/// it has paid them.
@Observable
final class WhatsNewStore {

    static let shared = WhatsNewStore()

    private static let lastVersionKey = "whatsNew.lastVersionSeen"

    /// The notes this launch owes, until they are shown
    private(set) var due: WhatsNewRelease?

    private init() {}

    /// Decided once, at launch, before the introduction can finish: an
    /// install that had not finished it by now is new, and its first
    /// version's notes are not news to it.
    func decideAtLaunch() {
        let defaults = UserDefaults.standard
        let current = Bundle.main.appVersion
        guard defaults.string(forKey: Self.lastVersionKey) != current else { return }

        guard defaults.bool(forKey: "hasSeenOnboarding"),
              let release = WhatsNewRelease.release(for: current) else {
            defaults.set(current, forKey: Self.lastVersionKey)
            return
        }
        due = release
    }

    /// Records the notes as seen the moment they are shown: once, whether
    /// or not they are read to the end.
    func markSeen() {
        guard let due else { return }
        UserDefaults.standard.set(due.version, forKey: Self.lastVersionKey)
        self.due = nil
    }
}
