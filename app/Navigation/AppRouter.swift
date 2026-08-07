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

// MARK: - PrayerLaunch

/// Everything a prayer session needs at launch, carried out-of-band because
/// NavigationStack paths hold Hashable values only. One struct instead of
/// parallel optionals so setting and clearing is atomic.
struct PrayerLaunch {
    let meditationSet: MeditationSet

    /// 0-based mystery index to start at (non-zero when resuming)
    var startIndex: Int = 0

    /// Seconds already prayed in earlier segments of a resumed session
    var priorSeconds: Int = 0

    /// When the devotion originally began (display/snapshot continuity)
    var startedAt: Date = Date()
}

// MARK: - AppRouter

/// App-wide navigation state. Injected via `.environment(router)` in ContentView.
@Observable
final class AppRouter {

    // MARK: - Navigation State

    /// Any mutation (push, pop, system back-swipe) bumps `generation`:
    /// NavigationPath is a value type, so every change lands in didSet.
    /// Async flows capture the generation before awaiting and refuse to
    /// navigate if it moved — a stale response must never mutate the stack.
    var path = NavigationPath() {
        didSet { generation &+= 1 }
    }

    /// Monotonic token identifying the current navigation state.
    private(set) var generation = 0

    /// The currently selected bottom tab.
    ///
    /// Lives on the router (not ContentView-local state) so any view can
    /// switch tabs — e.g. the home header's streak flame jumps to Progress.
    var selectedTab: AppTab = .home

    /// Currently selected mystery category, persisted across the navigation flow.
    var selectedCategory: MysteryCategory?

    /// The pending prayer session's payload (set, start position, timing).
    var pendingPrayer: PrayerLaunch?

    /// How long the just-finished session took, for the completion screen
    /// to record. Carried the same way as `pendingPrayer`.
    var completedSessionDuration: Int?

    // MARK: - Navigation Actions

    func navigateToAllMysteries() {
        path.append(AppRoute.allMysteries)
    }

    func navigateToMeditationSelection(category: MysteryCategory) {
        selectedCategory = category
        path.append(AppRoute.meditationSelection(category: category))
    }

    func navigateToPrayerSession(
        meditationSet: MeditationSet,
        startAtIndex: Int = 0,
        priorSeconds: Int = 0,
        startedAt: Date? = nil
    ) {
        pendingPrayer = PrayerLaunch(
            meditationSet: meditationSet,
            startIndex: startAtIndex,
            priorSeconds: priorSeconds,
            startedAt: startedAt ?? Date()
        )
        path.append(AppRoute.prayerSession(meditationSetId: meditationSet.id))
    }

    /// Shows the completion screen in place of the prayer session, so a
    /// finished Rosary can't be navigated back into and recorded twice.
    func navigateToCompletion(durationSeconds: Int? = nil) {
        completedSessionDuration = durationSeconds
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(AppRoute.completion)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Returns to the home screen and clears stored navigation state.
    func popToRoot() {
        // Mutate in place rather than replacing the NavigationPath object;
        // swapping the whole path mid-transition can desync the stack's
        // internal destination bookkeeping.
        path.removeLast(path.count)
        selectedCategory = nil
        pendingPrayer = nil
        completedSessionDuration = nil
    }
}
