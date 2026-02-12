//
//  AppRouter.swift
//  app
//
//  Manages navigation state for the app using NavigationStack.
//  Provides type-safe navigation between screens.
//

import SwiftUI

/// Navigation destinations for the prayer flow
enum AppRoute: Hashable {
    case meditationSelection(category: MysteryCategory)
    case prayerSession(meditationSetId: Int)
    case completion
}

/// Manages app navigation state
@Observable
final class AppRouter {
    /// The navigation path for NavigationStack
    var path = NavigationPath()

    /// Currently selected mystery category (for passing between screens)
    var selectedCategory: MysteryCategory?

    /// Loaded meditation set (for prayer session and completion screens)
    var loadedMeditationSet: MeditationSet?

    // MARK: - Navigation Actions

    /// Navigate to meditation selection for a category
    func navigateToMeditationSelection(category: MysteryCategory) {
        selectedCategory = category
        path.append(AppRoute.meditationSelection(category: category))
    }

    /// Navigate to prayer session with a loaded meditation set
    func navigateToPrayerSession(meditationSet: MeditationSet) {
        loadedMeditationSet = meditationSet
        path.append(AppRoute.prayerSession(meditationSetId: meditationSet.id))
    }

    /// Navigate to completion screen
    func navigateToCompletion() {
        path.append(AppRoute.completion)
    }

    /// Pop back one screen
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Return to home (clear navigation stack)
    func popToRoot() {
        path = NavigationPath()
        selectedCategory = nil
        loadedMeditationSet = nil
    }
}
