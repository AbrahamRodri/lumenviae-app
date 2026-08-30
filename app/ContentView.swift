//
//  ContentView.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

// MARK: - ContentView
struct ContentView: View {

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
                    .animation(.easeInOut(duration: 0.25), value: shouldShowTabBar)
            }
        }
        .environment(router)
        .onChange(of: router.selectedTab) { _, newTab in
            if newTab != .consecration {
                isConsecrationNavigating = false
            }
        }
        .onChange(of: router.shortcutRequest) { _, request in
            guard let request else { return }
            router.shortcutRequest = nil
            perform(request)
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
            .presentationDetents([.height(PrayShortcutTray.height(for: UserSettings.shared))])
        }
        .sheet(isPresented: $showPrayEditor) {
            PrayButtonEditorSheet()
                .environment(UserSettings.shared)
        }
    }

    // MARK: - Shortcuts

    /// Performs a devotional act — from the Pray button's tap, its tray,
    /// or a Rule of Prayer row on the Me page.
    private func perform(_ shortcut: PrayerShortcut) {
        switch shortcut {
        case .todaysRosary:
            startPrayer(category: ScheduleService.categoryForToday())

        case .sevenSorrows:
            startPrayer(category: .sevenSorrows)

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
        case .consecration:
            // Rendered as a sibling of the NavigationStack (see body) —
            // its own stack must never nest inside this one.
            AppColors.background
                .ignoresSafeArea()
        case .journal:
            JournalView()
        case .progress:
            PrayerProgressView()
        case .chapel:
            MyChapelView()
        }
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
            if let meditationSet = router.pendingPrayer?.meditationSet {
                PrayerCompletionView(meditationSet: meditationSet)
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

        case .office:
            DivineOfficeView()

        case .trueDevotion:
            TrueDevotionView()

        case .trueDevotionBook:
            TrueDevotionReaderView()

        case .howToPray:
            HowToPrayRosaryView()

        case .scripture:
            MysteriesInScriptureView()

        case .marianLibrary:
            MarianLibraryView()

        case .carloAcutis:
            CarloAcutisView()

        case .spiritualReading:
            SpiritualReadingView()

        case .libraryBook(let id):
            LibraryBookView(bookID: id)

        case .libraryChapter(let bookID, let chapterIndex):
            LibraryChapterReaderView(bookID: bookID, chapterIndex: chapterIndex)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
