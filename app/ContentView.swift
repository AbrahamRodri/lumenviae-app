//
//  ContentView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Stack with tab content
                NavigationStack(path: $router.path) {
                    tabContent
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }

                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .environment(router)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .journal:
            PlaceholderView(title: "Journal")
        case .progress:
            PlaceholderView(title: "Progress")
        case .account:
            AccountView()
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
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

// MARK: - Placeholder View

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.gold.opacity(0.5))

                Text(title)
                    .font(AppFonts.headlineFont(24))
                    .foregroundColor(AppColors.cream)

                Text("Coming Soon")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
