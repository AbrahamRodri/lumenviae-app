//
//  MeditationSelectionViewModel.swift
//  app
//
//  Manages state and data loading for the meditation selection screen.
//

import Foundation

/// ViewModel for the Select Meditation screen
@Observable
final class MeditationSelectionViewModel {
    // MARK: - Published State

    /// The mystery category we're selecting meditations for
    let category: MysteryCategory

    /// Available meditation sets for this category
    var meditationSets: [MeditationSetSummary] = []

    /// Loading state for the list
    var isLoading = false

    /// Loading state for fetching a full set
    var isLoadingSet = false

    /// Error message if loading fails
    var errorMessage: String?

    // MARK: - Dependencies

    private let apiService: APIService

    // MARK: - Initialization

    init(category: MysteryCategory, apiService: APIService = .shared) {
        self.category = category
        self.apiService = apiService
    }

    // MARK: - Computed Properties

    /// Display title for the category
    var categoryTitle: String {
        "\(category.displayName) Mysteries"
    }

    /// Subtitle showing days prayed
    var categorySubtitle: String {
        category.daysPrayed
    }

    // MARK: - Data Loading

    /// Load available meditation sets for this category
    @MainActor
    func loadMeditationSets() async {
        guard meditationSets.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            meditationSets = try await apiService.fetchMeditationSets(category: category)
        } catch {
            errorMessage = "Failed to load meditation sets"
        }

        isLoading = false
    }

    /// Load a complete meditation set with all meditations
    /// - Parameter id: The meditation set ID to load
    /// - Returns: The full MeditationSet with meditations
    @MainActor
    func loadFullMeditationSet(id: Int) async throws -> MeditationSet {
        isLoadingSet = true
        defer { isLoadingSet = false }

        do {
            return try await apiService.fetchMeditationSet(id: id)
        } catch {
            // Fallback to mock data
            return MockDataService.meditationSet(for: category)
        }
    }
}
