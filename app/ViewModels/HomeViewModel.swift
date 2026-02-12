//
//  HomeViewModel.swift
//  app
//
//  Manages state and data loading for the Home screen.
//

import Foundation

/// ViewModel for the Home screen
@Observable
final class HomeViewModel {
    // MARK: - Published State

    /// Today's mystery category based on traditional schedule
    var todaysCategory: MysteryCategory

    /// Mysteries for today's category (from API or mock)
    var mysteries: [Mystery] = []

    /// All mystery categories for the grid
    let allCategories: [MysteryCategory] = MysteryCategory.allCases

    /// Loading state
    var isLoading = false

    /// Error message if loading fails
    var errorMessage: String?

    // MARK: - Dependencies

    private let apiService: APIService
    private let scheduleService: ScheduleService.Type

    // MARK: - Initialization

    init(
        apiService: APIService = .shared,
        scheduleService: ScheduleService.Type = ScheduleService.self
    ) {
        self.apiService = apiService
        self.scheduleService = scheduleService
        self.todaysCategory = scheduleService.categoryForToday()
    }

    // MARK: - Computed Properties

    /// The first mystery of today's set (featured on home)
    var featuredMystery: Mystery? {
        mysteries.first
    }

    /// Day label (e.g., "WEDNESDAY PRAYER")
    var dayLabel: String {
        scheduleService.dayLabel
    }

    /// Today's inspirational quote
    var currentQuote: (text: String, author: String) {
        MockDataService.todaysQuote
    }

    // MARK: - Data Loading

    /// Load mysteries for today's category
    @MainActor
    func loadMysteries() async {
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

    /// Refresh mysteries (force reload)
    @MainActor
    func refreshMysteries() async {
        mysteries = []
        await loadMysteries()
    }
}
