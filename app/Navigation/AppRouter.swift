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

    /// The same search, opened from a page's own glass (Prayers, Chant):
    /// the field ready, and that page's kind leading the results
    case search(from: AppSearch.Origin)

    /// The reader's own pages: the Prayer Record (streak, calendar,
    /// milestones) and the journal. Pushed over the tab they were opened
    /// from, with the gold Back, so the tab stays lit and Back returns to
    /// where the reader was; they were tabs of their own, reached with
    /// no Back and no tab lit. The tab bar stays up beneath them.
    case prayerRecord
    case journal

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
    /// One prayer — the Litany, a hymn, a prayer of the Rosary — opened
    /// on the pray-along screen (`PrayAlongLaunch.opening`), by the id
    /// `PrayerBook.prayer` looks up. `set` is the topic or order it was
    /// opened from: from an order, the order is prayed from that prayer
    /// on; otherwise the prayer is prayed alone.
    case devotionPrayer(id: String, set: PrayerSet? = nil)
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

    /// The Scriptural Rosary: its own page, opened from a mysteries'
    /// page with those mysteries chosen (its Mysteries row changes them),
    /// and the prayer itself. Everything the prayer needs is Hashable, so
    /// it rides in the path rather than out of band.
    case scripturalRosary(MysteryCategory)
    case scripturalRosaryPrayer(ScripturalRosaryLaunch)

    /// The Holy Rosary's page — every prayer said aloud, nothing read
    /// between (it was the Rosary Aloud). It prays on the Scriptural
    /// Rosary's screens (`ScripturalRosaryLaunch.form`), so only the door
    /// is its own.
    case rosaryAloud(MysteryCategory)

    /// The Prayer Book: its title page, which opens on the order of
    /// prayer for the hour it is — the Prayers tab's root, to which
    /// `push(.prayerBook)` turns; one of its chapters; and an order of
    /// prayer's own page — Morning Prayers, Before Confession. A single
    /// prayer has no page of its own: `devotionPrayer(id:)`, which every
    /// door to a prayer uses, opens it to be prayed.
    case prayerBook
    case prayerBookChapter(id: String)
    case prayerOrder(id: String)

    /// The prayers the reader has saved with Save in the pray-along's
    /// menu, reached from the Saved shortcut on Prayers
    case prayerBookSaved

    /// The reader's own prayers and playlists, from the My Prayers shelf
    /// on Prayers, and one playlist's page
    case myPrayers
    case myPlaylist(id: UUID)

    /// Prayers said one after another on a screen of their own, aloud or
    /// in silence. A player: it hides the bar and carries its own way out.
    case prayAlong(PrayAlongLaunch)

    /// The Chant Library — every chant the app carries, with its
    /// recording and its score — and one chant's own page, where it is
    /// heard, read and practised.
    case chantLibrary
    case chant(id: String)

    /// The reader's own chants: favourites, chants learned and the sets
    /// they made, opened on one shelf (`ChantSavedShelf`)
    case chantSaved(ChantSavedShelf)

    /// The sung sets: an index of the occasions
    /// (`ChantLibraryData.occasions`), each opening its own page
    case chantSets

    /// One sung set on its own page: an occasion, or a set the reader made
    case chantSet(ChantSetSubject)

    /// Every chant under its topic, one topic, or the Mass of the Angels
    case chantBrowse(ChantBrowseScope)
}

extension AppRoute {
    /// Whether the tab bar stays up over this page: the reader's own
    /// pages, which were tabs and are reached from the Chapel's tiles, so
    /// the Chapel tab stays lit beneath them. Every other pushed page
    /// takes the whole glass.
    var keepsTabBar: Bool {
        switch self {
        case .prayerRecord, .journal: return true
        default: return false
        }
    }
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
            // A push the router did not make, or a pop, leaves the record
            // of routes the length of the path: an unknown page is nil
            if routes.count > path.count {
                routes.removeLast(routes.count - path.count)
            }
            while routes.count < path.count { routes.append(nil) }
        }
    }

    /// The routes on the stack, as far as the router knows them, kept the
    /// length of `path`, which is type-erased and cannot be read back.
    /// The app-wide chant player reads the last to stand aside on the
    /// pages that carry their own transport or a prayer.
    private(set) var routes: [AppRoute?] = []

    /// The page on top of the stack, when the router pushed it
    var topRoute: AppRoute? { routes.last ?? nil }

    /// In a debug build, a chant's page named at launch stands pushed over
    /// the tab, for screenshots a simulator cannot tap to:
    /// `SIMCTL_CHILD_LUMEN_VIAE_CHANT=salve_regina_simple xcrun simctl launch …`,
    /// and a book of the Spiritual Reading shelf the same way with
    /// `LUMEN_VIAE_BOOK=imitation-of-christ`.
    init() {
        #if DEBUG
        if let id = ProcessInfo.processInfo.environment["LUMEN_VIAE_CHANT"], !id.isEmpty {
            path.append(AppRoute.chant(id: id))
            routes = [.chant(id: id)]
        } else if let id = ProcessInfo.processInfo.environment["LUMEN_VIAE_BOOK"], !id.isEmpty {
            path.append(AppRoute.libraryBook(id: id))
            routes = [.libraryBook(id: id)]
        } else if let spec = ProcessInfo.processInfo.environment["LUMEN_VIAE_ROUTE"],
                  let (route, launch) = AppRouter.launchRoute(spec) {
            pendingPrayer = launch
            if case .meditationSelection(let category) = route { selectedCategory = category }
            path.append(route)
            routes = [route]
        }
        #endif
    }

    #if DEBUG
    /// A page named at launch by `LUMEN_VIAE_ROUTE`, for the App Store
    /// screenshots (`Tools/AppStore/screenshots`): `missal`, `office`,
    /// `howToPray`, `explore`, `spiritualReading`, `allMysteries`,
    /// `mysteries:<category>`, `scripturalRosary:<category>`,
    /// `rosaryAloud:<category>`, `scripturalRosaryPrayer:<category>[:<mystery>[:<bead>]]`,
    /// `rosaryAloudPrayer:<category>[:<mystery>[:<bead>]]`,
    /// `prayer:<category>[:<mystery>[:<bead>]]` (the category's bundled
    /// meditation set), `prayerOrder:<id>`, `guidedRosary:<category>` and
    /// `rosaryLesson:<n>`. Categories are `MysteryCategory` raw values.
    static func launchRoute(_ spec: String) -> (AppRoute, PrayerLaunch?)? {
        let parts = spec.split(separator: ":").map(String.init)
        guard let name = parts.first else { return nil }
        let category = parts.count > 1 ? MysteryCategory(rawValue: parts[1]) : nil
        let mystery = parts.count > 2 ? Int(parts[2]) ?? 0 : 0
        let bead = parts.count > 3 ? Int(parts[3]) ?? 0 : 0
        switch (name, category) {
        case ("missal", _): return (.missal, nil)
        case ("office", _): return (.office, nil)
        case ("howToPray", _): return (.howToPray, nil)
        case ("explore", _): return (.explore, nil)
        case ("spiritualReading", _): return (.spiritualReading, nil)
        case ("allMysteries", _): return (.allMysteries, nil)
        case ("mysteries", let c?): return (.meditationSelection(category: c), nil)
        case ("scripturalRosary", let c?): return (.scripturalRosary(c), nil)
        case ("rosaryAloud", let c?): return (.rosaryAloud(c), nil)
        case ("guidedRosary", let c?): return (.guidedRosary(c), nil)
        case ("scripturalRosaryPrayer", let c?), ("rosaryAloudPrayer", let c?):
            let form: SpokenForm = name == "rosaryAloudPrayer" ? .plain : .scriptural
            return (.scripturalRosaryPrayer(ScripturalRosaryLaunch(
                category: c, form: form, startIndex: mystery, startBead: bead)), nil)
        case ("prayer", let c?):
            guard let set = BundledMeditationSets.all.first(where: { $0.category == c.rawValue }) else { return nil }
            return (.prayerSession(meditationSetId: set.id),
                    PrayerLaunch(meditationSet: set, startIndex: mystery, startBead: bead))
        case ("prayerOrder", _) where parts.count > 1: return (.prayerOrder(id: parts[1]), nil)
        case ("myPrayers", _): return (.myPrayers, nil)
        case ("rosaryLesson", _): return (.rosaryLesson(parts.count > 1 ? Int(parts[1]) ?? 0 : 0), nil)
        default: return nil
        }
    }
    #endif

    /// Appends a route to the path and records it
    private func append(_ route: AppRoute) {
        path.append(route)
        if !routes.isEmpty { routes[routes.count - 1] = route }
    }

    /// Monotonic token identifying the current navigation state.
    private(set) var generation = 0

    /// The currently selected bottom tab.
    ///
    /// Lives on the router (not ContentView-local state) so any view can
    /// switch tabs — e.g. Today's Prayer's consecration row turns to the Consecration tab.
    var selectedTab: AppTab = AppRouter.launchTab {
        didSet {
            // Leaving the Chapel ends its arranging, for the same reason
            // a push does — and `switchTo` from the root never touches
            // `path`, so this is the only place that sees it.
            if oldValue != selectedTab { endChapelArranging() }
        }
    }

    /// The tab the app opens on: home, or in a debug build the tab named
    /// at launch, for screenshots and checks a simulator cannot tap to:
    /// `SIMCTL_CHILD_LUMEN_VIAE_TAB=prayers xcrun simctl launch …`
    static var launchTab: AppTab {
        #if DEBUG
        if let name = ProcessInfo.processInfo.environment["LUMEN_VIAE_TAB"],
           let tab = AppTab.allCases.first(where: { "\($0)" == name }) {
            return tab == .chapel && ArchivedPages.chapel ? .chant : tab
        }
        #endif
        return .home
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
    /// of doors, or the coach ribbon and the foot. Idempotent. Under
    /// Reduce Motion the change carries no animation, so the tiles do not
    /// fold nor the rows slide to their places; the Chapel fades in what
    /// arrives on transitions of its own.
    func beginChapelArranging(reduceMotion: Bool) {
        guard !chapelArranging else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
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
        append(AppRoute.allMysteries)
    }

    func navigateToSettings() {
        append(AppRoute.settings)
    }

    func navigateToExplore() {
        append(AppRoute.explore)
    }

    /// Pushes any content destination. The named helpers above predate
    /// this; new pages ride it directly.
    ///
    /// The Prayer Book has a tab of its own, so a door to it — home's hour
    /// row, Explore, the Chapel's tile, an order's page — turns to that
    /// tab rather than stacking a second copy of the book on this one.
    /// So does a door to the Chant Library while Chant has a tab.
    ///
    /// An archived page (`ArchivedPages`) is never pushed: its doors stand
    /// down, and this is the backstop for one that was missed.
    func push(_ route: AppRoute) {
        if ArchivedPages.hides(route) { return }
        if route == .prayerBook {
            switchTo(.prayers)
            return
        }
        // The Chant Library has a tab of its own while the Chapel is
        // archived, and is turned to the same way
        if route == .chantLibrary && AppTab.barTabs.contains(.chant) {
            switchTo(.chant)
            return
        }
        append(route)
    }

    func navigateToMeditationSelection(category: MysteryCategory) {
        selectedCategory = category
        append(AppRoute.meditationSelection(category: category))
    }

    func navigateToMeditationSetDetail(_ summary: MeditationSetSummary) {
        append(AppRoute.meditationSetDetail(summary: summary))
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
        append(AppRoute.prayerSession(meditationSetId: meditationSet.id))
    }

    /// Shows the completion screen in place of the prayer session, so a
    /// finished Rosary can't be navigated back into and recorded twice.
    func navigateToCompletion(_ completed: CompletedPrayer) {
        completedPrayer = completed
        if !path.isEmpty {
            path.removeLast()
        }
        append(AppRoute.completion)
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
    ///
    /// The Prayer Record and the journal are no longer turned to as tabs
    /// but pushed (`AppRoute.prayerRecord`, `.journal`): a door that still
    /// asks for their tab is answered with the push.
    func switchTo(_ tab: AppTab) {
        switch tab {
        case .progress: push(.prayerRecord); return
        case .journal: push(.journal); return
        // The Chapel archived, a door that still asks for it opens Chant,
        // which stands in its place in the bar
        case .chapel where ArchivedPages.chapel: switchTo(.chant); return
        default: break
        }
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
