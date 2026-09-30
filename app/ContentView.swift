//
//  ContentView.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

// MARK: - ContentView
struct ContentView: View {

    /// The first step onboarding's last button named — today's Rosary, or
    /// the guide to praying it — taken once, as the app first appears, and
    /// cleared as it is taken so no later appearance takes it again
    var onboardingFirstStep: Binding<OnboardingFirstStep?> = .constant(nil)

    @State private var router = AppRouter()
    @State private var isConsecrationNavigating: Bool = false

    /// Guards the Pray button against double-taps while a set loads
    @State private var isStartingPrayer = false

    /// The Pray button's press-and-hold tray
    @State private var showPrayTray = false

    /// The act chosen in the tray, run once the tray has finished
    /// leaving — an act that presents its own sheet (the Mass, the
    /// Office) must not present into a dismissal.
    @State private var pendingTrayShortcut: PrayerShortcut?

    /// The tray asked for its editor; opened once the tray has left.
    @State private var pendingTrayArrange = false

    /// The Pray button's own editor (quick tap + hold menu)
    @State private var showPrayEditor = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Bumped each time the Consecration tab is chosen; its veil answers
    @State private var consecrationArrivals = 0

    /// A version's notes, owed to someone who knew the version before;
    /// and the door chosen in them, taken once the sheet has left
    @State private var whatsNewRelease: WhatsNewRelease?
    @State private var pendingWhatsNewRoute: AppRoute?

    /// A new reader's first look at the home page (`FirstUseTour`).
    /// Computed, so the memberwise init keeps its one argument.
    private var firstUseTour: FirstUseTour { FirstUseTour.shared }

    private var shouldShowTabBar: Bool {
        router.path.isEmpty && !isConsecrationNavigating && !router.chapelArranging
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            NavigationStack(path: $router.path) {
                // The destination table must hang off a structurally stable
                // view. Attached directly to the tab `switch`, iOS can drop
                // the registration when the root re-evaluates during a pop
                // transition — the next push then fails with "no matching
                // navigationDestination" and the screen won't open again.
                ZStack {
                    // The ground the tabs turn over. While one page has
                    // dipped and the next has not yet risen, nothing else
                    // is opaque here — and the stack's own background is
                    // white, which showed as a grey flash on every switch
                    AppColors.appGradient
                        .ignoresSafeArea()

                    tabContent
                }
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
            }
            // Under the tour the page is dimmed and takes no touch, and
            // VoiceOver may not wander onto it either: the tour's card is
            // the one place to be, whatever its modal trait reaches
            .accessibilityHidden(firstUseTour.isRunning)

            // The consecration tab hosts its OWN NavigationStack. Nesting
            // it inside the outer stack's root silently drops the outer
            // stack's destination table — after visiting the tab, every
            // push rendered the white "missing destination" placeholder
            // until the app was relaunched. It must live as a sibling.
            if router.selectedTab == .consecration {
                ConsecrationTabView(onNavigationChange: { isNavigating in
                    isConsecrationNavigating = isNavigating
                })
                // Never faded: this view holds its own NavigationStack,
                // whose system background is white, and fading the whole
                // stack blended that white over the dark ground as a
                // grey flash. It arrives whole, from under a veil of the
                // app's ground that lifts — the same beat as `tabTurn`
                // without any alpha over the stack
                .transition(.identity)
                .overlay {
                    AppColors.appGradient
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .keyframeAnimator(initialValue: 1.0, trigger: consecrationArrivals) { view, opacity in
                            view.opacity(opacity)
                        } keyframes: { _ in
                            MoveKeyframe(1)
                            CubicKeyframe(0, duration: 0.2)
                        }
                }
            }

            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: Bindable(router).selectedTab,
                    isLoadingPrayer: isStartingPrayer,
                    onPrayNow: { perform(UserSettings.shared.prayQuickAction) },
                    onPrayHold: { showPrayTray = true }
                )
                    .ignoresSafeArea(.all, edges: .bottom)
                    .opacity(shouldShowTabBar ? 1 : 0)
                    .offset(y: shouldShowTabBar ? 0 : 100)
                    .animation(Motion.panel, value: shouldShowTabBar)
            }
            .accessibilityHidden(firstUseTour.isRunning)

            if firstUseTour.isRunning {
                FirstUseTourOverlay(tour: firstUseTour)
                    .transition(.opacity)
            }
        }
        // A tab change turns like a page — see `tabTurn`. The transaction
        // only needs to be animated; each side carries its own timing
        .animation(.easeOut(duration: 0.2), value: router.selectedTab)
        .environment(router)
        .onChange(of: router.selectedTab) { _, newTab in
            if newTab != .consecration {
                isConsecrationNavigating = false
            } else {
                consecrationArrivals += 1
            }
        }
        .onChange(of: router.shortcutRequest) { _, request in
            guard let request else { return }
            router.shortcutRequest = nil
            perform(request)
        }
        // The Angelus bell's notification, tapped: straight to the Angelus
        .onChange(of: PrayerBookStore.shared.angelusRequested, initial: true) { _, requested in
            guard requested else { return }
            PrayerBookStore.shared.angelusRequested = false
            // Never beneath a pray-along already open, or its first-time
            // question: the bell has been heard, and the prayer is kept.
            // A pray-along lives only on this stack, so at its root none
            // is open, whatever the book was told
            guard router.path.isEmpty || !PrayerBookStore.shared.isPrayingAlong else { return }
            perform(.angelus)
        }
        .task {
            // Cleared before the wait, as it is taken, so no later
            // appearance — another window on the same app state — finds a
            // step left to take again
            guard let step = onboardingFirstStep.wrappedValue else { return }
            onboardingFirstStep.wrappedValue = nil
            // After the introduction's fade, so the first page is seen
            // arriving rather than skipped
            try? await Task.sleep(for: .milliseconds(450))
            step.perform(with: router)
        }
        .sheet(isPresented: $showPrayTray, onDismiss: {
            if let shortcut = pendingTrayShortcut {
                pendingTrayShortcut = nil
                perform(shortcut)
            }
            if pendingTrayArrange {
                pendingTrayArrange = false
                showPrayEditor = true
            }
        }) {
            PrayShortcutTray(
                pendingShortcut: $pendingTrayShortcut,
                pendingArrange: $pendingTrayArrange
            )
            .environment(UserSettings.shared)
            // The tray opens as tall as it measures (`fittedSheetDetent`)
            .presentationBackground(AppColors.background)
            // A sheet takes its text size from the phone, not from the
            // root, so it carries the app's cap itself
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showPrayEditor) {
            PrayButtonEditorSheet()
                .environment(UserSettings.shared)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        // What's New, or a new reader's tour: each once, on the home page
        // itself and never over a prayer, so asked again whenever the
        // home page comes back into view
        .task { await presentFirstLook(after: .milliseconds(900)) }
        .onChange(of: router.path.isEmpty) { _, isEmpty in
            if isEmpty {
                Task { await presentFirstLook(after: .milliseconds(600)) }
            } else if firstUseTour.isRunning {
                // Something opened over the home page with the tour up —
                // the Angelus bell's notification, a shortcut. The tour
                // never stands over a prayer; it waits for home again.
                firstUseTour.pause()
            }
        }
        .onChange(of: router.selectedTab) { _, tab in
            if tab == .home { Task { await presentFirstLook(after: .milliseconds(400)) } }
        }
        .sheet(item: $whatsNewRelease, onDismiss: {
            guard let route = pendingWhatsNewRoute else { return }
            pendingWhatsNewRoute = nil
            router.push(route)
        }) { release in
            WhatsNewSheet(release: release) { route in
                pendingWhatsNewRoute = route
                whatsNewRelease = nil
            }
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    /// Shows what is owed, once the home page has settled: a version's
    /// notes to someone updating, or the tour to a new reader
    private func presentFirstLook(after wait: Duration) async {
        try? await Task.sleep(for: wait)
        // Not while a Rosary is loading either: the introduction's "Pray
        // Today's Rosary" fetches its set before it pushes, and on a cold
        // server the tour began first and the prayer opened under it
        guard router.path.isEmpty, router.selectedTab == .home, !router.chapelArranging,
              !showPrayTray, !showPrayEditor, whatsNewRelease == nil,
              !isStartingPrayer, !firstUseTour.isRunning else { return }
        if let release = WhatsNewStore.shared.due {
            WhatsNewStore.shared.markSeen()
            whatsNewRelease = release
        } else if firstUseTour.isDue {
            withAnimation(Motion.crossfade) { firstUseTour.begin() }
        }
    }

    // MARK: - Shortcuts

    /// Performs a devotional act — from the Pray button's tap, its tray,
    /// or anything that asks the router (`AppRouter.run`): the Chapel's
    /// focus and Today rows, a library reading's Pray door.
    private func perform(_ shortcut: PrayerShortcut) {
        // The Consecration tab stands above this stack with a stack of its
        // own, so an act pushed here while it was chosen — the Pray
        // button there, the Angelus bell tapped — went on beneath it,
        // unseen, and took the tab bar with it
        if shortcut != .consecration, router.selectedTab == .consecration {
            router.selectedTab = .home
        }
        // A Rosary of this act's form, left off today, is taken up where it
        // stopped. Begun again, its first save erased the place unasked.
        if let session = PrayerResumeService.shared.continuation(for: shortcut) {
            continueRosary(session, orBegin: shortcut)
            return
        }
        begin(shortcut)
    }

    /// Takes up an unfinished Rosary. If its set cannot be loaded — away
    /// from a signal, never saved for offline — the act begins as it
    /// always has, rather than the button doing nothing.
    private func continueRosary(_ session: InProgressPrayer, orBegin shortcut: PrayerShortcut) {
        guard !isStartingPrayer, router.path.isEmpty else { return }
        isStartingPrayer = true

        Task {
            let resumed = await router.resume(session)
            isStartingPrayer = false
            if !resumed { begin(shortcut) }
        }
    }

    /// Runs an act from its beginning
    private func begin(_ shortcut: PrayerShortcut) {
        switch shortcut {
        case .todaysRosary:
            startPrayer(category: ScheduleService.categoryForToday())

        case .sevenSorrows:
            startPrayer(category: .sevenSorrows)

        case .scripturalRosary:
            // Straight to the day's mysteries, as Today's Rosary goes —
            // its own page, where the mysteries are chosen, is the
            // mysteries' page's door, not the Pray button's
            guard router.path.isEmpty else { return }
            router.push(.scripturalRosaryPrayer(
                ScripturalRosaryLaunch(category: ScheduleService.categoryForToday())
            ))

        case .rosaryAloud:
            // The same: the day's mysteries, and the voice begins
            guard router.path.isEmpty else { return }
            router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(
                category: ScheduleService.categoryForToday(),
                form: .plain
            )))

        case .chooseMeditation:
            guard router.path.isEmpty else { return }
            router.selectedTab = .home
            router.navigateToMeditationSelection(category: ScheduleService.categoryForToday())

        case .mass:
            router.push(.missal)

        case .office:
            router.push(.office)

        case .consecration:
            router.selectedTab = .consecration

        // The Prayer Book's orders of the day, straight to prayer
        case .morningPrayers, .angelus, .nightPrayers:
            if let id = shortcut.prayerOrderID, let order = PrayerBook.order(id) {
                router.push(.prayAlong(.order(order)))
            }
        }
    }

    // MARK: - Quick Prayer

    /// Starts a Rosary directly: picks a random meditation set for the
    /// category from the prefetched cache (falling back to the built-in
    /// traditional set), then goes straight to prayer — no selection
    /// screens.
    private func startPrayer(category: MysteryCategory) {
        guard !isStartingPrayer, router.path.isEmpty else { return }
        isStartingPrayer = true

        let generation = router.generation

        Task {
            defer { isStartingPrayer = false }

            let meditationSet = await MeditationCacheService.shared.randomSet(for: category)

            // The load may have taken a while (cold API) — only navigate if
            // navigation hasn't moved since the tap. The generation token
            // catches any change, including push-and-return to the same
            // depth, which a plain isEmpty check would miss.
            guard router.generation == generation else { return }

            router.navigateToPrayerSession(meditationSet: meditationSet)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .home:
            HomeView()
                .transition(tabTurn)
        case .consecration:
            // Rendered as a sibling of the NavigationStack (see body) —
            // its own stack must never nest inside this one.
            AppColors.background
                .ignoresSafeArea()
                .transition(tabTurn)
        case .journal:
            JournalView()
                .transition(tabTurn)
        case .progress:
            PrayerProgressView()
                .transition(tabTurn)
        case .chapel:
            MyChapelView()
                .transition(tabTurn)
        }
    }

    /// How a tab changes: the page leaving dips into the background
    /// first, quickly, and only then does the page arriving rise into
    /// place — a fade *through* the ground rather than a crossfade.
    /// Two full pages fading over each other ghosted Home's painting
    /// through the Chapel's ledger for a quarter of a second; a hard
    /// cut is what iOS does itself and reads as a jolt on a page whose
    /// sections then drift in. This is the beat between: the whole turn
    /// is under a quarter of a second and nothing is ever seen twice.
    /// Under Reduce Motion the arriving page only fades.
    private var tabTurn: AnyTransition {
        let rise: AnyTransition = reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6))
        return .asymmetric(
            insertion: rise.animation(.easeOut(duration: 0.18).delay(0.06)),
            removal: .opacity.animation(.easeIn(duration: 0.08))
        )
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .allMysteries:
            AllMysteriesView()

        case .meditationSelection(let category):
            SelectMeditationView(category: category)

        case .meditationSetDetail(let summary):
            MeditationSetDetailView(summary: summary)

        case .prayerSession:
            if let launch = router.pendingPrayer {
                MysteryPrayerView(launch: launch)
            } else {
                ProgressView("Loading...")
                    .tint(AppColors.gold)
            }

        case .completion:
            if let completed = router.completedPrayer {
                PrayerCompletionView(completed: completed)
            } else {
                ProgressView("Loading...")
                    .tint(AppColors.gold)
            }

        case .settings:
            AccountView()

        case .about:
            AboutView()

        case .explore:
            ExploreView()

        // Content pages that slide in. Each carries its own toolbar
        // chrome (a gold Back in place of the hidden system button), so
        // the bar must stay — hiding it would take their Back with it.
        case .missal:
            DailyMissalView()

        case .missalDay(let date):
            DailyMissalView(openingOn: date)

        case .office:
            DivineOfficeView()

        case .trueDevotion:
            TrueDevotionView()

        case .trueDevotionBook:
            TrueDevotionReaderView()

        case .howToPray:
            HowToPrayRosaryView()

        case .guidedRosary(let category):
            GuidedRosaryView(category: category)

        case .rosaryLesson(let lesson):
            // One identity per lesson pushed from the course's path.
            // Continue turns to the next lesson inside the page itself
            // (`RosaryLessonView.turnPage`), never by swapping routes
            RosaryLessonView(lesson: lesson).id(lesson)

        case .scripture:
            MysteriesInScriptureView()

        case .mysteryInScripture(let category, let order):
            MysteryPassageView(category: category, order: order)

        case .marianLibrary:
            MarianLibraryView()

        case .libraryReading(let id):
            LibraryReadingView(entryID: id)

        // Every door to a prayer in the app opens it in the Prayer Book,
        // where it can be kept, prayed aloud, and learned by heart
        case .devotionPrayer(let id):
            BookPrayerView(prayerID: id)

        case .carloAcutis:
            CarloAcutisView()

        case .spiritualReading:
            SpiritualReadingView()

        case .libraryBook(let id):
            LibraryBookView(bookID: id)

        case .libraryChapter(let bookID, let chapterIndex):
            LibraryChapterReaderView(bookID: bookID, chapterIndex: chapterIndex)

        case .scripturalRosary(let category):
            ScripturalRosaryView(category: category)

        case .rosaryAloud(let category):
            ScripturalRosaryView(category: category, form: .plain)

        // A player, like the meditation's: it hides the bar and carries
        // its own way out
        case .scripturalRosaryPrayer(let launch):
            ScripturalRosaryPrayerView(launch: launch)

        case .prayerBook:
            PrayerBookView()

        case .prayerBookChapter(let id):
            // One identity per chapter pushed. The foot turns to the next
            // chapter inside the page itself (`PrayerBookChapterView.turn`),
            // never by swapping routes
            PrayerBookChapterView(chapterID: id).id(id)

        case .prayerOrder(let id):
            PrayerOrderView(orderID: id)

        // A player, like the Rosary's
        case .prayAlong(let launch):
            PrayAlongView(launch: launch)

        case .chantLibrary:
            ChantLibraryView()

        case .chant(let id):
            ChantView(chantID: id)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
