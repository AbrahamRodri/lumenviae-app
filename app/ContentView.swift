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
    @State private var selectedTab: AppTab = .home
    //@State private var isConsecrationNavigating: Bool = false

    private var shouldShowTabBar: Bool {
        router.path.isEmpty 
        // && !isConsecrationNavigating
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
                CustomTabBar(selectedTab: $selectedTab)
                    .ignoresSafeArea(.all, edges: .bottom)
                    .opacity(shouldShowTabBar ? 1 : 0)
                    .offset(y: shouldShowTabBar ? 0 : 100)
                    .animation(.easeInOut(duration: 0.25), value: shouldShowTabBar)
            }
        }
        .environment(router)
        // Hidden for v1.0 — consecration feature not yet complete
//        .onChange(of: selectedTab) { _, newTab in
//            if newTab != .consecration {
//                isConsecrationNavigating = false
//            }
//        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        // Hidden for v1.0 — consecration feature not yet complete
//        case .consecration:
//            ConsecrationTabView(onNavigationChange: { isNavigating in
//                isConsecrationNavigating = isNavigating
//            })
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
