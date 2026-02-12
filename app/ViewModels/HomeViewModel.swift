//
//  HomeViewModel.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  HOME VIEW MODEL - STATE & LOGIC FOR THE HOME SCREEN
//  ═══════════════════════════════════════════════════════════════════════════
//
//  ## What is a ViewModel?
//  A ViewModel is the "brain" behind a View. It handles:
//  - Loading data from services (API, database, etc.)
//  - Managing state (loading, errors, data)
//  - Business logic (what mystery to show today)
//
//  The View just displays what the ViewModel tells it to.
//  This separation makes code easier to test and maintain.
//
//  ## MVVM Architecture
//  ```
//  View (HomeView)
//    │
//    │ observes
//    ▼
//  ViewModel (HomeViewModel)
//    │
//    │ calls
//    ▼
//  Services (APIService, ScheduleService)
//  ```
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - HomeViewModel

/// Manages state and data loading for the Home screen.
///
/// ## @Observable
/// The `@Observable` macro (iOS 17+) makes this class observable by SwiftUI.
/// When any property changes, SwiftUI automatically re-renders views that
/// depend on it. This replaces the older `ObservableObject` + `@Published`.
///
/// ## final class
/// - `final`: Cannot be subclassed (slight performance benefit)
/// - `class`: Reference type, same instance shared across views
///
@Observable
final class HomeViewModel {

    // MARK: - State

    /// Today's mystery category based on traditional schedule.
    /// Set once during initialization and doesn't change.
    var todaysCategory: MysteryCategory

    /// Mysteries for today's category, fetched from API.
    /// Empty until `loadMysteries()` completes.
    var mysteries: [Mystery] = []

    /// All four mystery categories for the grid.
    /// Uses `CaseIterable` to get all enum cases.
    let allCategories: [MysteryCategory] = MysteryCategory.allCases

    /// Whether data is currently being fetched
    var isLoading = false

    /// Error message if the API call fails (nil on success)
    var errorMessage: String?

    // MARK: - Dependencies

    /// Service for making API requests
    private let apiService: APIService

    /// Service for determining today's mystery schedule.
    /// Using `.Type` because ScheduleService uses static methods.
    private let scheduleService: ScheduleService.Type

    // MARK: - Initialization

    /// Creates a new HomeViewModel.
    ///
    /// - Parameters:
    ///   - apiService: Service for API calls (defaults to shared singleton)
    ///   - scheduleService: Service for schedule logic (defaults to ScheduleService)
    ///
    /// ## Dependency Injection
    /// Parameters have default values but can be overridden for testing.
    /// This is called "dependency injection" - we "inject" dependencies
    /// rather than hard-coding them, making the class testable.
    init(
        apiService: APIService = .shared,
        scheduleService: ScheduleService.Type = ScheduleService.self
    ) {
        self.apiService = apiService
        self.scheduleService = scheduleService
        self.todaysCategory = scheduleService.categoryForToday()
    }

    // MARK: - Computed Properties

    /// The first mystery of today's set, shown in the featured card.
    /// Returns nil if mysteries haven't loaded yet.
    var featuredMystery: Mystery? {
        mysteries.first
    }

    /// Day label for the header (e.g., "WEDNESDAY PRAYER")
    var dayLabel: String {
        scheduleService.dayLabel
    }

    /// Today's inspirational quote from the mock data service
    var currentQuote: (text: String, author: String) {
        MockDataService.todaysQuote
    }

    // MARK: - Data Loading

    /// Loads mysteries for today's category from the API.
    ///
    /// ## @MainActor
    /// Ensures this function runs on the main thread.
    /// UI updates (isLoading, mysteries) must happen on main thread.
    ///
    /// ## Guard Statement
    /// The `guard mysteries.isEmpty else { return }` prevents
    /// reloading if data is already present. This is called
    /// "early return" and keeps the code flat (not deeply nested).
    @MainActor
    func loadMysteries() async {
        // Don't reload if we already have data
        guard mysteries.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            mysteries = try await apiService.fetchMysteries(category: todaysCategory)
        } catch {
            errorMessage = "Failed to load mysteries"
        }

        isLoading = false
    }

    /// Forces a reload of mysteries (clears cache first).
    ///
    /// Useful for pull-to-refresh functionality.
    @MainActor
    func refreshMysteries() async {
        mysteries = []
        await loadMysteries()
    }
}
