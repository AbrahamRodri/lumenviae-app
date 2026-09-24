//
//  AppRouter.swift
//  Lumen Viae
//
//  Centralized navigation via NavigationStack:
//  Home → SelectMeditationView → MeditationSetDetailView → MysteryPrayerView
//       → PrayerCompletionView → Home.
//

import SwiftUI

// MARK: - AppRoute

/// All navigation destinations that can be pushed onto the NavigationStack.
enum AppRoute: Hashable {
    /// All mysteries view (View All screen including Luminous)
    case allMysteries

    /// Meditation selection screen for a specific category
    case meditationSelection(category: MysteryCategory)

    /// One meditation set, read before it is prayed: what it is and how
    /// the first mystery opens. Loads the full set on the way.
    case meditationSetDetail(summary: MeditationSetSummary)

    /// Prayer session (requires meditation set to be loaded first)
    case prayerSession(meditationSetId: Int)

    /// Completion screen shown after finishing all mysteries
    case completion

    /// Settings — every toggle and preference — pushed from the home
    /// masthead's faders
    case settings

    /// The app's colophon: about, introduction, privacy, help, feedback.
    /// Pushed from the home masthead's ⓘ.
    case about

    /// Explore: search and browse everything, from the home masthead's
    /// search glass
    case explore

    // Content destinations — pages, not tasks, so they slide in from
    // the right rather than pulling up as sheets. Each draws its own
    // Back pill and pops via `dismiss`.
    case missal
    case office
    /// Montfort's devotion in summary — what it is, its marks, the false
    /// devotions, the ejaculatory prayers. A topic page, not the book.
    case trueDevotion
    /// The book itself, set like every other book on the shelf. Kept
    /// apart from `trueDevotion` because a book cover must open a book:
    /// a reader who taps the cloth wants the text, not an article about
    /// it.
    case trueDevotionBook
    case howToPray
    /// A whole Rosary a step at a time, every word on the page and the
    /// bead under the fingers drawn — for someone praying it for the
    /// first time
    case guidedRosary(MysteryCategory)
    /// One lesson of How to Pray: 0 the beads and the order, 1 the
    /// prayers, 2 the mysteries
    case rosaryLesson(Int)
    case scripture
    /// One mystery's passage of Scripture, stepped in place through its
    /// set — reached from In Scripture
    case mysteryInScripture(category: MysteryCategory, order: Int)
    case marianLibrary
    /// One short reading of the library — a Marian Library entry, a
    /// chapter of St. Carlo's life — by its id (`LibraryReadings`),
    /// stepped in place along its shelf
    case libraryReading(id: String)
    /// A prayer the library leads to — the Litany, a hymn, a prayer of
    /// the Rosary — on a page of its own, by the id `DevotionPrayers.find`
    /// looks up
    case devotionPrayer(id: String)
    /// The Missal opened on a given day rather than today — a feast
    /// named elsewhere in the app
    case missalDay(Date)
    case carloAcutis

    /// The Spiritual Reading shelf, one of its books, and one chapter.
    /// Books ride as catalog ids — the parsed content is loaded (and
    /// cached) by LibraryService, never carried through the path.
    case spiritualReading
    case libraryBook(id: String)
    case libraryChapter(bookID: String, chapterIndex: Int)

    /// The Scriptural Rosary: its title page, where the mysteries are
    /// chosen, and the prayer itself. Everything the prayer needs is
    /// Hashable, so it rides in the path rather than out of band.
    case scripturalRosary
    case scripturalRosaryPrayer(ScripturalRosaryLaunch)

    /// The Rosary Aloud's title page. It prays on the Scriptural Rosary's
    /// screens (`ScripturalRosaryLaunch.form`), so only the door is its own.
    case rosaryAloud
}

// MARK: - ScripturalRosaryLaunch

/// Everything the Scriptural Rosary needs at launch: which mysteries,
/// and — resuming — where it stood and how long it had been prayed.
struct ScripturalRosaryLaunch: Hashable {
    let category: MysteryCategory

    /// What the beads carry: a verse each, or the prayer itself said
    /// aloud. Defaults to the Scriptural Rosary, whose doors came first.
    var form: SpokenForm = .scriptural

    /// 0-based mystery index to start at (non-zero when resuming)
    var startIndex: Int = 0

    /// The bead of that decade to start on (non-zero when resuming)
    var startBead: Int = 0

    /// Seconds already prayed in earlier segments of a resumed session
    var priorSeconds: Int = 0

    /// When the devotion originally began (display/snapshot continuity)
    var startedAt: Date = Date()
}

// MARK: - SpokenForm

/// The two devotions the Scriptural Rosary's screens pray. They share
/// a title page, a player, the strand and the spoken Rosary beneath
/// it, and differ in what a Hail Mary bead holds.
enum SpokenForm: String, Hashable, Codable {
    /// A verse of Scripture for every Hail Mary, the Rosary said aloud
    /// only if `UserSettings.prayAloud` is on
    case scriptural

    /// The Rosary Aloud: every prayer said by the voice, the beads
    /// moving with it, and the prayer being said set in full on its bead.
    /// Aloud whatever the setting, since that is the whole of it.
    case plain
}

// MARK: - CompletedPrayer

/// What a finished prayer was, for the completion screen to record and
/// to set its scene by: the mysteries, and the name the record keeps —
/// a meditation set's, or the Scriptural Rosary's. One value instead of
/// the set itself, because the Scriptural Rosary has no set.
struct CompletedPrayer {
    let category: MysteryCategory?

    /// How the Prayer Record names what was prayed
    let devotionName: String

    /// Seconds actually spent praying, or nil when not timed
    let durationSeconds: Int?
}

// MARK: - PrayerLaunch

/// Everything a prayer session needs at launch, carried out-of-band because
/// NavigationStack paths hold Hashable values only. One struct instead of
/// parallel optionals so setting and clearing is atomic.
struct PrayerLaunch {
    let meditationSet: MeditationSet

    /// 0-based mystery index to start at (non-zero when resuming)
    var startIndex: Int = 0

    /// The bead of that decade to start on (non-zero when resuming)
    var startBead: Int = 0

    /// Seconds already prayed in earlier segments of a resumed session
    var priorSeconds: Int = 0

    /// When the devotion originally began (display/snapshot continuity)
    var startedAt: Date = Date()
}

// MARK: - AppRouter

/// App-wide navigation state. Injected via `.environment(router)` in ContentView.
@Observable
final class AppRouter {

    // MARK: - Navigation State

    /// Any mutation (push, pop, system back-swipe) bumps `generation`:
    /// NavigationPath is a value type, so every change lands in didSet.
    /// Async flows capture the generation before awaiting and refuse to
    /// navigate if it moved — a stale response must never mutate the stack.
    var path = NavigationPath() {
        didSet {
            generation &+= 1
            // Arrange mode borrows the tab bar's place, so it must never
            // outlive the page that owns it. `onDisappear` cannot be
            // trusted to end it — it doesn't fire when a root screen is
            // torn out from under a pushed one, which is exactly what a
            // push from the Chapel does — and a stranded `true` hides the
            // bar app-wide with no gesture that brings it back.
            endChapelArranging()
        }
    }

    /// Monotonic token identifying the current navigation state.
    private(set) var generation = 0

    /// The currently selected bottom tab.
    ///
    /// Lives on the router (not ContentView-local state) so any view can
    /// switch tabs — e.g. the Chapel's Prayer Streak tile jumps to Progress.
    var selectedTab: AppTab = .home {
        didSet {
            // Leaving the Chapel ends its arranging, for the same reason
            // a push does — and `switchTo` from the root never touches
            // `path`, so this is the only place that sees it.
            if oldValue != selectedTab { endChapelArranging() }
        }
    }

    /// Currently selected mystery category, persisted across the navigation flow.
    var selectedCategory: MysteryCategory?

    /// The pending prayer session's payload (set, start position, timing).
    var pendingPrayer: PrayerLaunch?

    /// The just-finished prayer, for the completion screen to record.
    /// Carried the same way as `pendingPrayer`.
    var completedPrayer: CompletedPrayer?

    /// A devotional act asked for from anywhere — a Rule of Prayer row,
    /// the Pray button's tray. ContentView watches this, performs it
    /// (some acts present sheets only it can own), and clears it.
    var shortcutRequest: PrayerShortcut?

    /// Whether the Chapel page is in arrange mode. Lives on the router
    /// because ContentView owns the tab bar, and while arranging the
    /// bar's place belongs to the Chapel's tray.
    ///
    /// The router — not the page — is what guarantees it ends: any
    /// navigation clears it, so no route out of the Chapel can leave the
    /// tab bar hidden.
    var chapelArranging = false

    /// Ends arrange mode if it is running. Idempotent, and safe to call
    /// from a property observer.
    private func endChapelArranging() {
        guard chapelArranging else { return }
        chapelArranging = false
    }

    /// Begins arrange mode from wherever on the Chapel it is asked for —
    /// a hold on the page, on a tile, on the quiet parts of a tile full
    /// of doors, or the coach ribbon and the foot. Idempotent.
    func beginChapelArranging() {
        guard !chapelArranging else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            chapelArranging = true
        }
    }

    /// Requests a devotional act. Runs on the next router observation
    /// tick, wherever the user currently is.
    func run(_ shortcut: PrayerShortcut) {
        shortcutRequest = shortcut
    }

    // MARK: - Navigation Actions

    func navigateToAllMysteries() {
        path.append(AppRoute.allMysteries)
    }

    func navigateToSettings() {
        path.append(AppRoute.settings)
    }

    func navigateToExplore() {
        path.append(AppRoute.explore)
    }

    /// Pushes any content destination. The named helpers above predate
    /// this; new pages ride it directly.
    func push(_ route: AppRoute) {
        path.append(route)
    }

    func navigateToMeditationSelection(category: MysteryCategory) {
        selectedCategory = category
        path.append(AppRoute.meditationSelection(category: category))
    }

    func navigateToMeditationSetDetail(_ summary: MeditationSetSummary) {
        path.append(AppRoute.meditationSetDetail(summary: summary))
    }

    func navigateToPrayerSession(
        meditationSet: MeditationSet,
        startAtIndex: Int = 0,
        startAtBead: Int = 0,
        priorSeconds: Int = 0,
        startedAt: Date? = nil
    ) {
        pendingPrayer = PrayerLaunch(
            meditationSet: meditationSet,
            startIndex: startAtIndex,
            startBead: startAtBead,
            priorSeconds: priorSeconds,
            startedAt: startedAt ?? Date()
        )
        path.append(AppRoute.prayerSession(meditationSetId: meditationSet.id))
    }

    /// Shows the completion screen in place of the prayer session, so a
    /// finished Rosary can't be navigated back into and recorded twice.
    func navigateToCompletion(_ completed: CompletedPrayer) {
        completedPrayer = completed
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(AppRoute.completion)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Goes to a tab from wherever the user is, clearing the stack first.
    ///
    /// Setting `selectedTab` alone only works from a page sitting at the
    /// root: from a pushed one — Explore, say — the tab changes silently
    /// underneath a screen that stays put, and the user meets the new tab
    /// later, when they tap Back for something else.
    func switchTo(_ tab: AppTab) {
        if !path.isEmpty {
            path.removeLast(path.count)
        }
        selectedTab = tab
    }

    /// Returns to the home screen and clears stored navigation state.
    func popToRoot() {
        // Mutate in place rather than replacing the NavigationPath object;
        // swapping the whole path mid-transition can desync the stack's
        // internal destination bookkeeping.
        path.removeLast(path.count)
        selectedCategory = nil
        pendingPrayer = nil
        completedPrayer = nil
    }
}
