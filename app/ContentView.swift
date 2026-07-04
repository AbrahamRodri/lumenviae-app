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

    private var shouldShowTabBar: Bool {
        router.path.isEmpty && !isConsecrationNavigating
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

            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: Bindable(router).selectedTab,
                    isLoadingPrayer: isStartingPrayer,
                    onPrayNow: startTodaysPrayer
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
    }

    // MARK: - Quick Prayer

    /// Starts today's Rosary directly from the Pray button: resolves the
    /// weekday's mystery category and picks a random meditation set from
    /// the prefetched cache (falling back to the built-in traditional set),
    /// then goes straight to prayer — no selection screens.
    private func startTodaysPrayer() {
        guard !isStartingPrayer, router.path.isEmpty else { return }
        isStartingPrayer = true

        let category = ScheduleService.categoryForToday()

        Task {
            defer { isStartingPrayer = false }

            let meditationSet = await MeditationCacheService.shared.randomSet(for: category)

            // The load may have taken a while (cold API) — only navigate if
            // the user hasn't already pushed a different screen. Appending
            // to the path mid-transition is what caused intermittent
            // crashes when rapidly entering and exiting prayer.
            guard router.path.isEmpty else { return }

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
            ConsecrationTabView(onNavigationChange: { isNavigating in
                isConsecrationNavigating = isNavigating
            })
        case .journal:
            JournalView()
        case .progress:
            PrayerProgressView()
        case .account:
            AccountView()
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

        case .prayerSession:
            if let meditationSet = router.loadedMeditationSet {
                MysteryPrayerView(meditationSet: meditationSet)
            } else {
                ProgressView("Loading...")
                    .tint(AppColors.gold)
            }

        case .completion:
            if let meditationSet = router.loadedMeditationSet {
                PrayerCompletionView(meditationSet: meditationSet)
            } else {
                ProgressView("Loading...")
                    .tint(AppColors.gold)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
