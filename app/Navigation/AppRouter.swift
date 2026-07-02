//
//  AppRouter.swift
//  Lumen Viae
//
//  Centralized navigation via NavigationStack:
//  Home → SelectMeditationView → MysteryPrayerView → PrayerCompletionView → Home.
//

import SwiftUI

// MARK: - AppRoute

/// All navigation destinations that can be pushed onto the NavigationStack.
enum AppRoute: Hashable {
    /// All mysteries view (View All screen including Luminous)
    case allMysteries

    /// Meditation selection screen for a specific category
    case meditationSelection(category: MysteryCategory)

    /// Prayer session (requires meditation set to be loaded first)
    case prayerSession(meditationSetId: Int)

    /// Completion screen shown after finishing all mysteries
    case completion
}

// MARK: - AppRouter

/// App-wide navigation state. Injected via `.environment(router)` in ContentView.
@Observable
final class AppRouter {

    // MARK: - Navigation State

    var path = NavigationPath()

    /// Currently selected mystery category, persisted across the navigation flow.
    var selectedCategory: MysteryCategory?

    /// The full meditation set with all meditations loaded.
    /// Stored here (not in the route) because NavigationStack paths hold
    /// Hashable values, and both the prayer and completion screens need it.
    var loadedMeditationSet: MeditationSet?

    // MARK: - Navigation Actions

    func navigateToAllMysteries() {
        path.append(AppRoute.allMysteries)
    }

    func navigateToMeditationSelection(category: MysteryCategory) {
        selectedCategory = category
        path.append(AppRoute.meditationSelection(category: category))
    }

    func navigateToPrayerSession(meditationSet: MeditationSet) {
        loadedMeditationSet = meditationSet
        path.append(AppRoute.prayerSession(meditationSetId: meditationSet.id))
    }

    func navigateToCompletion() {
        path.append(AppRoute.completion)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Returns to the home screen and clears stored navigation state.
    func popToRoot() {
        path = NavigationPath()
        selectedCategory = nil
        loadedMeditationSet = nil
    }
}
