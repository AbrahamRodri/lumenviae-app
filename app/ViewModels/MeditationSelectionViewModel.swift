//
//  MeditationSelectionViewModel.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MEDITATION SELECTION VIEW MODEL
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Manages state for the meditation selection screen, where users choose
//  which meditation style to use for their prayer.
//
//  ## Available Meditation Styles
//  - Traditional Meditations
//  - St. Louis de Montfort
//  - Scriptural Rosary
//  - (More can be added via the API)
//
//  ## Data Flow
//  1. Load list of meditation sets (summaries, no content)
//  2. User taps a set
//  3. Load full meditation set with all 5 meditations
//  4. Navigate to prayer session
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - MeditationSelectionViewModel

/// Manages state for the meditation selection screen.
///
/// Handles two API calls:
/// 1. `loadMeditationSets()` - Get list of available sets for a category
/// 2. `loadFullMeditationSet(id:)` - Get complete set when user selects one
///
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

    /// Creates a ViewModel for the given category.
    ///
    /// - Parameters:
    ///   - category: The mystery category to show sets for
    ///   - apiService: Service for API calls (defaults to shared)
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

    /// Loads a complete meditation set with all meditations.
    ///
    /// Called when the user taps a meditation set card.
    /// Falls back to mock data if the API call fails.
    ///
    /// - Parameter id: The meditation set ID to load
    /// - Returns: Full MeditationSet with meditations array
    ///
    /// ## defer { }
    /// The `defer` block runs when the function exits, regardless of
    /// how it exits (return, throw, etc.). This ensures `isLoadingSet`
    /// is always set back to false.
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
