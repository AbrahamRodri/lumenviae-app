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
                tabContent
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }

            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: Bindable(router).selectedTab,
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
    /// weekday's mystery category, loads its first meditation set (falling
    /// back to the built-in traditional set), and goes straight to prayer —
    /// no selection screens.
    private func startTodaysPrayer() {
        guard !isStartingPrayer, router.path.isEmpty else { return }
        isStartingPrayer = true

        let category = ScheduleService.categoryForToday()

        Task {
            defer { isStartingPrayer = false }

            let meditationSet: MeditationSet
            do {
                let summaries = try await APIService.shared.fetchMeditationSets(category: category)
                if let first = summaries.first {
                    meditationSet = try await APIService.shared.fetchMeditationSet(id: first.id)
                } else {
                    meditationSet = MockDataService.meditationSet(for: category)
                }
            } catch {
                meditationSet = MockDataService.meditationSet(for: category)
            }

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
