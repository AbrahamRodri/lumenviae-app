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

    /// Each item opens its own page, so the page names it
    var id: AppRoute { route }
}

// MARK: - WhatsNewRelease

/// A version's notes. Few items, the app's own names, what each is
/// before anything about it, and no counts or durations.
struct WhatsNewRelease: Identifiable {
    let version: String
    let items: [WhatsNewItem]

    var id: String { version }

    static let all: [WhatsNewRelease] = [
        WhatsNewRelease(version: "4.2", items: [
            WhatsNewItem(
                icon: "lv-rosary",
                title: String(
                    localized: "A Simpler Rosary",
                    comment: "What's New sheet: name of a 4.2 change, the Rosary prayed on one simple screen"
                ),
                detail: String(
                    localized: "One screen that prays aloud and lights each line; tap a mystery to move, mute the voice to read along, or choose No Meditation",
                    comment: "What's New sheet: one plain line under A Simpler Rosary, saying what it is; No Meditation is the way to pray named on the mysteries' page"
                ),
                // Today's mysteries' page, where the Rosary and No
                // Meditation stand
                route: .meditationSelection(category: ScheduleService.categoryForToday())
            ),
            WhatsNewItem(
                icon: "ph-globe",
                title: String(
                    localized: "Lumen Viae in Spanish (beta)",
                    comment: "What's New sheet: name of a 4.2 change, the app in Spanish, as a beta"
                ),
                detail: String(
                    localized: "With your iPhone in Spanish: the screens, the Rosary, the prayers, the meditations, the Consecration and the Divine Office. The voice that reads is still English",
                    comment: "What's New sheet: one plain line under Lumen Viae in Spanish (beta), saying what is in Spanish and what is not"
                ),
                // Settings, where the App Language row stands
                route: .settings
            )
        ]),
        WhatsNewRelease(version: "4.1", items: [
            WhatsNewItem(
                icon: "ph-note-pencil",
                title: String(
                    localized: "My Prayers",
                    comment: "What's New sheet: name of a new feature, My Prayers, the reader's own prayers and playlists"
                ),
                detail: String(
                    localized: "Write your own prayers and gather them into playlists, each with a painting or a photo of your own",
                    comment: "What's New sheet: one plain line under My Prayers, the reader's own prayers and playlists, saying what it is"
                ),
                route: .myPrayers
            )
        ]),
        WhatsNewRelease(version: "4.0", items: [
            WhatsNewItem(
                icon: "lv-prayer-book",
                title: String(
                    localized: "Prayers",
                    comment: "What's New sheet: name of a new feature, Prayers, the Prayer Book tab"
                ),
                // The Journal gave Prayers its place in the bar. Every row
                // here is a door, and the Journal is a tab, not a page, so
                // where it opens now is said in this row's line
                detail: String(
                    localized: "The Church's common prayers, in the tab bar where the Journal was; the Journal now opens from Settings and after each Rosary",
                    comment: "What's New sheet: one plain line under Prayers, the Prayer Book tab, saying what it is"
                ),
                // Turns to the Prayers tab (`AppRouter.push`)
                route: .prayerBook
            ),
            WhatsNewItem(
                icon: "ph-music-note",
                title: String(
                    localized: "The Chant Library",
                    comment: "What's New sheet: name of a new feature, the Chant Library"
                ),
                detail: String(
                    localized: "The Church's own songs in Gregorian chant, each with a recording and sheet music",
                    comment: "What's New sheet: one plain line under the Chant Library, saying what it is"
                ),
                route: .chantLibrary
            ),
            WhatsNewItem(
                icon: PrayerShortcut.rosaryAloud.icon,
                // The form's name as the Rosary's own screens say it
                // (`ScripturalRosaryViewModel.displayName`)
                title: String(
                    localized: "The Audio Rosary",
                    comment: "What's New sheet: name of a new feature, the Audio Rosary, every prayer said aloud"
                ),
                detail: String(
                    localized: "Listen to every prayer of the Rosary, in the voice you choose, at the speed you set",
                    comment: "What's New sheet: one plain line under the Audio Rosary, every prayer said aloud, saying what it is"
                ),
                // Today's mysteries: the notes are decided at launch and
                // shown the same day
                route: .rosaryAloud(ScheduleService.categoryForToday())
            ),
            WhatsNewItem(
                icon: "lv-rosary",
                title: String(
                    localized: "How to Pray the Rosary",
                    comment: "What's New sheet: name of a new feature, How to Pray the Rosary, the beginner's course"
                ),
                detail: String(
                    localized: "A short course for someone new to it, then a guided first Rosary, one prayer at a time",
                    comment: "What's New sheet: one plain line under How to Pray the Rosary, the beginner's course, saying what it is"
                ),
                route: .howToPray
            )
            // The Scriptural Rosary and the narration voices came in 3.0
            // (CHANGELOG.md), so they are no news to someone arriving
            // from it
        ])
    ]

    /// A version's notes, without a row whose page is archived
    /// (`ArchivedPages`); a version left with none shows nothing
    static func release(for version: String) -> WhatsNewRelease? {
        guard let release = all.first(where: { $0.version == version }) else { return nil }
        let items = release.items.filter { !ArchivedPages.hides($0.route) }
        return items.isEmpty ? nil : WhatsNewRelease(version: release.version, items: items)
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
