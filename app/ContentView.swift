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
        }
        .sheet(isPresented: $showPrayEditor) {
            PrayButtonEditorSheet()
                .environment(UserSettings.shared)
                .presentationBackground(AppColors.background)
        }
    }

    // MARK: - Shortcuts

    /// Performs a devotional act — from the Pray button's tap, its tray,
    /// or anything that asks the router (`AppRouter.run`): the Chapel's
    /// focus and Today rows, a library reading's Pray door.
    private func perform(_ shortcut: PrayerShortcut) {
        switch shortcut {
        case .todaysRosary:
            startPrayer(category: ScheduleService.categoryForToday())

        case .sevenSorrows:
            startPrayer(category: .sevenSorrows)

        case .scripturalRosary:
            // Straight to the day's mysteries, as Today's Rosary goes —
            // the title page, where the mysteries are chosen, is Explore's
            // door, not the Pray button's
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
            // One identity per lesson: Continue swaps a lesson for the
            // next in one tick, which would otherwise update the page in
            // place — still scrolled, and never appearing to be marked
            RosaryLessonView(lesson: lesson).id(lesson)

        case .scripture:
            MysteriesInScriptureView()

        case .mysteryInScripture(let category, let order):
            MysteryPassageView(category: category, order: order)

        case .marianLibrary:
            MarianLibraryView()

        case .libraryReading(let id):
            LibraryReadingView(entryID: id)

        case .devotionPrayer(let id):
            DevotionPrayerView(prayerID: id)

        case .carloAcutis:
            CarloAcutisView()

        case .spiritualReading:
            SpiritualReadingView()

        case .libraryBook(let id):
            LibraryBookView(bookID: id)

        case .libraryChapter(let bookID, let chapterIndex):
            LibraryChapterReaderView(bookID: bookID, chapterIndex: chapterIndex)

        case .scripturalRosary:
            ScripturalRosaryView()

        case .rosaryAloud:
            ScripturalRosaryView(form: .plain)

        // A player, like the meditation's: it hides the bar and carries
        // its own way out
        case .scripturalRosaryPrayer(let launch):
            ScripturalRosaryPrayerView(launch: launch)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
