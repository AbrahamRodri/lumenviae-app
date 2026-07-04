//
//  MeditationSelectionViewModel.swift
//  Lumen Viae
//
//  State for the meditation selection screen: loads the list of meditation
//  sets for a category, then the full set when the user picks one.
//
//  Browsing is label-driven: sets may carry descriptive labels from the API
//  (e.g., ["Saints", "Marian"]). Labels become filter chips the user can
//  combine, and the unfiltered list is grouped by each set's first label.
//  Until the API sends labels, the picker is a simple flat list.
//

import Foundation

@Observable
final class MeditationSelectionViewModel {

    // MARK: - State

    /// The mystery category we're showing meditation options for
    let category: MysteryCategory

    /// Available meditation sets (summaries, without full content)
    var meditationSets: [MeditationSetSummary] = []

    /// Labels the user has toggled on; sets must match all of them
    var selectedLabels: Set<String> = []

    /// Whether the initial list is loading
    var isLoading = false

    /// Whether a specific set is being loaded (after user taps)
    var isLoadingSet = false

    /// Error message if loading fails (nil on success)
    var errorMessage: String?

    // MARK: - Dependencies

    private let apiService: APIService
    private let favorites: FavoritesService

    // MARK: - Initialization

    init(
        category: MysteryCategory,
        apiService: APIService? = nil,
        favorites: FavoritesService? = nil,
        preloadedSets: [MeditationSetSummary] = []
    ) {
        self.category = category
        self.apiService = apiService ?? .shared
        self.favorites = favorites ?? .shared
        self.meditationSets = preloadedSets
    }

    // MARK: - Labels

    /// Every distinct label across the loaded sets, in first-appearance
    /// order so the API controls curation.
    var allLabels: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for set in meditationSets {
            for label in set.labels ?? [] where seen.insert(label).inserted {
                ordered.append(label)
            }
        }
        return ordered
    }

    /// Whether the catalog carries labels at all (drives chips visibility)
    var hasLabels: Bool { !allLabels.isEmpty }

    func isSelected(_ label: String) -> Bool {
        selectedLabels.contains(label)
    }

    func toggleLabel(_ label: String) {
        if selectedLabels.contains(label) {
            selectedLabels.remove(label)
        } else {
            selectedLabels.insert(label)
        }
    }

    func clearLabels() {
        selectedLabels.removeAll()
    }

    // MARK: - Filtering & Grouping

    /// Sets matching every selected label (all sets when nothing is selected)
    var filteredSets: [MeditationSetSummary] {
        guard !selectedLabels.isEmpty else { return meditationSets }
        return meditationSets.filter { set in
            selectedLabels.isSubset(of: Set(set.labels ?? []))
        }
    }

    /// Favorited sets within the current filter — pinned above everything
    var favoriteSets: [MeditationSetSummary] {
        filteredSets.filter { favorites.isFavorite($0.id) }
    }

    /// One displayable group of sets. A nil title renders without a header.
    struct Section: Identifiable {
        let title: String?
        let sets: [MeditationSetSummary]
        var id: String { title ?? "•unlabeled" }
    }

    /// Non-favorited sets arranged for display:
    /// - Filter active (or no labels in catalog): one flat, untitled section.
    /// - Browsing all with labels: grouped by primary label in
    ///   first-appearance order; unlabeled sets close the list under "More".
    var sections: [Section] {
        let remaining = filteredSets.filter { !favorites.isFavorite($0.id) }

        guard selectedLabels.isEmpty, hasLabels else {
            return remaining.isEmpty ? [] : [Section(title: nil, sets: remaining)]
        }

        var order: [String] = []
        var grouped: [String: [MeditationSetSummary]] = [:]
        var unlabeled: [MeditationSetSummary] = []

        for set in remaining {
            if let primary = set.primaryLabel {
                if grouped[primary] == nil { order.append(primary) }
                grouped[primary, default: []].append(set)
            } else {
                unlabeled.append(set)
            }
        }

        var result = order.map { Section(title: $0, sets: grouped[$0] ?? []) }
        if !unlabeled.isEmpty {
            result.append(Section(title: result.isEmpty ? nil : "More", sets: unlabeled))
        }
        return result
    }

    /// True when an active filter matches nothing — drives the empty state
    var filterCameUpEmpty: Bool {
        !selectedLabels.isEmpty && filteredSets.isEmpty
    }

    // MARK: - Favorites

    func isFavorite(_ set: MeditationSetSummary) -> Bool {
        favorites.isFavorite(set.id)
    }

    func toggleFavorite(_ set: MeditationSetSummary) {
        favorites.toggle(set.id)
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
