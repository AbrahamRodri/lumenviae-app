//
//  ContentView.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  ═══════════════════════════════════════════════════════════════════════════
//  ROOT VIEW - THE MAIN CONTAINER FOR THE ENTIRE APP
//  ═══════════════════════════════════════════════════════════════════════════
//
//  ContentView is the root view of the app. It manages:
//  1. Tab navigation (Home, Journal, Progress, Account)
//  2. The NavigationStack for deep navigation (prayer flow)
//  3. Injecting the AppRouter into the environment
//
//  ## View Hierarchy
//  ```
//  ContentView
//  ├── NavigationStack (handles push/pop navigation)
//  │   └── Tab Content (HomeView, JournalView, etc.)
//  │       └── Pushed Views (SelectMeditationView, MysteryPrayerView, etc.)
//  └── CustomTabBar (bottom tabs)
//  ```
//
//  ## Navigation Strategy
//  We use TWO navigation mechanisms:
//  1. **Tabs**: Switch between main sections (Home, Journal, etc.)
//  2. **NavigationStack**: Push/pop within a section (Home → Select → Prayer)
//
//  The tab bar hides during the prayer flow to provide a distraction-free
//  prayer experience.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - ContentView

/// The root view that contains the tab bar and navigation stack.
///
/// This view is responsible for:
/// - Managing which tab is currently selected
/// - Providing the `AppRouter` to all child views via `.environment()`
/// - Hiding the tab bar during prayer sessions
///
/// ## SwiftUI Concepts Used
///
/// ### @State
/// `@State` creates local, mutable state that SwiftUI watches for changes.
/// When the value changes, SwiftUI re-renders the view.
/// - Use `@State` for simple values owned by THIS view
/// - Mark as `private` since state should only be modified by this view
///
/// ### @ViewBuilder
/// `@ViewBuilder` lets you return different view types from a computed
/// property or function. Without it, Swift would complain that you're
/// returning different types in each `case` branch.
///
/// ### NavigationStack
/// iOS 16+ navigation container that manages a stack of views.
/// - `path`: Binding to NavigationPath that tracks the navigation stack
/// - `.navigationDestination`: Maps route types to destination views
///
struct ContentView: View {

    // MARK: - State

    /// The app's navigation router, shared with all child views.
    ///
    /// Using `@State` here makes ContentView the "owner" of the router.
    /// Child views access it via `@Environment(AppRouter.self)`.
    @State private var router = AppRouter()

    /// Currently selected tab in the bottom navigation.
    @State private var selectedTab: AppTab = .home

    // MARK: - Computed Properties

    /// Whether the tab bar should be visible.
    ///
    /// We hide the tab bar during the prayer flow (when navigating into
    /// SelectMeditationView, MysteryPrayerView, or PrayerCompletionView)
    /// to create a distraction-free prayer experience.
    ///
    /// The `path.isEmpty` check determines if we're on a root tab view
    /// (show tab bar) or in a pushed navigation (hide tab bar).
    private var shouldShowTabBar: Bool {
        router.path.isEmpty
    }

    // MARK: - Body

    var body: some View {
        // ZStack layers views on top of each other (back to front)
        ZStack {
            // Layer 1: App background color (fills entire screen)
            AppColors.background
                .ignoresSafeArea()

            // Layer 2: Main content with tab bar
            VStack(spacing: 0) {
                // NavigationStack: Container for push/pop navigation
                // The `path` binding syncs with router.path for programmatic navigation
                NavigationStack(path: $router.path) {
                    // The currently selected tab's content
                    tabContent
                        // Register navigation destinations for type-safe routing
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }

                // Custom tab bar at the bottom (hidden during prayer flow)
                if shouldShowTabBar {
                    CustomTabBar(selectedTab: $selectedTab)
                        .ignoresSafeArea(.all, edges: .bottom)
                }
            }
        }
        // Inject router into environment so child views can access it
        // via @Environment(AppRouter.self)
        .environment(router)
    }

    // MARK: - Tab Content

    /// Returns the view for the currently selected tab.
    ///
    /// `@ViewBuilder` allows returning different view types from each case.
    /// Without it, we'd need to wrap everything in `AnyView`, which is
    /// less performant and loses type information.
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .journal:
            PlaceholderView(title: "Journal")
        case .progress:
            PrayerProgressView()
        case .account:
            AccountView()
        }
    }

    // MARK: - Navigation Destinations

    /// Maps navigation routes to their destination views.
    ///
    /// This is called by NavigationStack when a route is pushed onto the path.
    /// Each case handles a different part of the prayer flow.
    ///
    /// - Parameter route: The route to navigate to
    /// - Returns: The view to display for that route
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .meditationSelection(let category):
            SelectMeditationView(category: category)

        case .prayerSession:
            // Router stores the loaded meditation set before navigating
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

// MARK: - PlaceholderView

/// A simple placeholder view for tabs that aren't implemented yet.
///
/// This provides visual feedback that the section exists but is
/// "Coming Soon". Used for Journal and Progress tabs.
struct PlaceholderView: View {
    /// The title to display (e.g., "Journal", "Progress")
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

// MARK: - Preview

#Preview {
    ContentView()
}
