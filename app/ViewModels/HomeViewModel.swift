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
    let todaysCategory: MysteryCategory

    /// Mysteries for today's category - loaded from local data instantly.
    let mysteries: [Mystery]

    /// All four mystery categories for the grid.
    let allCategories: [MysteryCategory] = MysteryCategory.allCases

    /// Whether data is currently being fetched (always false now - data is local)
    let isLoading = false

    // MARK: - Dependencies

    /// Service for determining today's mystery schedule.
    private let scheduleService: ScheduleService.Type

    // MARK: - Initialization

    /// Creates a new HomeViewModel.
    ///
    /// Mystery data is loaded instantly from local storage - no API needed.
    /// The API is only used later for meditation text and audio.
    init(scheduleService: ScheduleService.Type = ScheduleService.self) {
        self.scheduleService = scheduleService
        self.todaysCategory = scheduleService.categoryForToday()
        self.mysteries = MysteryData.mysteries(for: todaysCategory)
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
}
