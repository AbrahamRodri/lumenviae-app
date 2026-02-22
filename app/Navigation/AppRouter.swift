//
//  AppRouter.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  APP ROUTER - CENTRALIZED NAVIGATION MANAGEMENT
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Manages navigation state for the entire app using SwiftUI's NavigationStack.
//  Provides type-safe, programmatic navigation between screens.
//
//  ## Why a Centralized Router?
//  1. **Decoupling**: Views don't need to know about other views
//  2. **Type Safety**: Routes are enums, not magic strings
//  3. **State Sharing**: Data can be passed between screens easily
//  4. **Deep Linking**: Easy to implement (push routes programmatically)
//
//  ## Navigation Flow
//  ```
//  Home
//    └── navigateToMeditationSelection(category)
//        └── SelectMeditationView
//            └── navigateToPrayerSession(meditationSet)
//                └── MysteryPrayerView
//                    └── navigateToCompletion()
//                        └── PrayerCompletionView
//                            └── popToRoot()
//                                └── Home
//  ```
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - AppRoute

/// Defines all possible navigation destinations in the app.
///
/// Each case represents a screen that can be pushed onto the NavigationStack.
/// Using an enum provides compile-time safety - typos are caught by the compiler.
///
/// ## Hashable Requirement
/// SwiftUI's NavigationStack requires route types to be Hashable.
/// Enums with Hashable associated values are automatically Hashable.
///
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

/// Manages app-wide navigation state.
///
/// Injected into the view hierarchy via `.environment(router)` in ContentView.
/// Child views access it via `@Environment(AppRouter.self) var router`.
///
/// ## @Observable
/// Makes navigation state changes trigger view updates.
/// When `path` changes, NavigationStack automatically animates transitions.
///
@Observable
final class AppRouter {

    // MARK: - Navigation State

    /// The navigation path for NavigationStack.
    ///
    /// This is the "stack" of screens. Each `.append()` pushes a new screen,
    /// `.removeLast()` pops one, and `= NavigationPath()` clears all.
    var path = NavigationPath()

    /// Currently selected mystery category.
    ///
    /// Stored here so it persists across the navigation flow.
    var selectedCategory: MysteryCategory?

    /// The full meditation set with all meditations loaded.
    ///
    /// Stored here because it's needed by both MysteryPrayerView
    /// and PrayerCompletionView. Loading once and sharing is more
    /// efficient than loading twice.
    var loadedMeditationSet: MeditationSet?

    // MARK: - Navigation Actions

    /// Navigates to the all mysteries view (View All screen).
    func navigateToAllMysteries() {
        path.append(AppRoute.allMysteries)
    }

    /// Navigates to the meditation selection screen for a category.
    ///
    /// - Parameter category: The mystery category to show sets for
    func navigateToMeditationSelection(category: MysteryCategory) {
        selectedCategory = category
        path.append(AppRoute.meditationSelection(category: category))
    }

    /// Navigates to the prayer session with a loaded meditation set.
    ///
    /// - Parameter meditationSet: The complete meditation set to pray
    ///
    /// The meditation set is stored in `loadedMeditationSet` because
    /// NavigationStack's path can only hold Hashable values, and we
    /// want the full set available to the destination view.
    func navigateToPrayerSession(meditationSet: MeditationSet) {
        loadedMeditationSet = meditationSet
        path.append(AppRoute.prayerSession(meditationSetId: meditationSet.id))
    }

    /// Navigates to the completion screen after finishing all mysteries.
    func navigateToCompletion() {
        path.append(AppRoute.completion)
    }

    /// Pops back one screen in the navigation stack.
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Returns to the home screen (clears entire navigation stack).
    ///
    /// Also clears stored state to ensure fresh start next time.
    func popToRoot() {
        path = NavigationPath()
        selectedCategory = nil
        loadedMeditationSet = nil
    }
}
