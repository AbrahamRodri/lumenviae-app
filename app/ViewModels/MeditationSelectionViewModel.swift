//
//  MeditationSelectionViewModel.swift
//  Lumen Viae
//
//  State for the meditation selection screen: loads the list of meditation
//  sets for a category, then the full set when the user picks one.
//

import Foundation

@Observable
final class MeditationSelectionViewModel {

    // MARK: - State

    /// The mystery category we're showing meditation options for
    let category: MysteryCategory

    /// Available meditation sets (summaries, without full content)
    var meditationSets: [MeditationSetSummary] = []

    /// Whether the initial list is loading
    var isLoading = false

    /// Whether a specific set is being loaded (after user taps)
    var isLoadingSet = false

    /// Error message if loading fails (nil on success)
    var errorMessage: String?

    // MARK: - Dependencies

    private let apiService: APIService

    // MARK: - Initialization

    init(category: MysteryCategory, apiService: APIService = .shared) {
        self.category = category
        self.apiService = apiService
    }

    // MARK: - Computed Properties

    /// Title for the screen header (e.g., "Joyful Mysteries")
    var categoryTitle: String {
        "\(category.displayName) Mysteries"
    }

    /// Subtitle showing traditional days (e.g., "Monday, Saturday")
    var categorySubtitle: String {
        category.daysPrayed
    }

    // MARK: - Data Loading

    /// Loads the list of available meditation sets for this category.
    ///
    /// Only loads once - subsequent calls are no-ops if data exists.
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

    /// Loads a complete meditation set when the user taps a set card.
    /// Falls back to mock data if the API call fails.
    @MainActor
    func loadFullMeditationSet(id: Int) async throws -> MeditationSet {
        isLoadingSet = true
        defer { isLoadingSet = false }

        do {
            return try await apiService.fetchMeditationSet(id: id)
        } catch {
            // Fallback to mock data for offline support
            return MockDataService.meditationSet(for: category)
        }
    }
}
