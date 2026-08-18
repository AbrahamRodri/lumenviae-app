//
//  MeditationSelectionViewModel.swift
//  Lumen Viae
//
//  State for the meditation picker: loads the list of meditation sets
//  for a category and narrows it for display.
//
//  Browsing is label-driven: sets may carry descriptive labels from the
//  API (e.g., ["Saints", "Marian"]). Labels become the chips in the
//  picker's filter tray — any number, combined; a set must carry all of
//  them — and the unfiltered shelf is grouped by each set's first label.
//  Pinned sets are lifted above whatever is showing. Until the API sends
//  labels, the picker is a simple flat shelf.
//
//  Loading a full set (with its meditations) happens on the set's own
//  detail screen — see MeditationSetDetailViewModel.
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

    /// Whether the catalog carries labels at all (drives the filter button)
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

    /// True while anything is narrowing the shelf — drives the count line
    var isNarrowed: Bool { !selectedLabels.isEmpty }

    var visibleSetCount: Int { filteredSets.count }
    var totalSetCount: Int { meditationSets.count }

    /// Pinned sets within the current filter — lifted above everything
    var pinnedSets: [MeditationSetSummary] {
        filteredSets.filter { favorites.isFavorite($0.id) }
    }

    /// One displayable group of sets. A nil title renders without a header.
    struct Section: Identifiable {
        let title: String?
        let sets: [MeditationSetSummary]
        var id: String { title ?? "•unlabeled" }
    }

    /// Unpinned sets arranged for display:
    /// - Narrowed (or no labels in catalog): one flat, untitled section.
    /// - Browsing everything: grouped by primary label in first-appearance
    ///   order; unlabeled sets close the list under "More".
    var sections: [Section] {
        let remaining = filteredSets.filter { !favorites.isFavorite($0.id) }

        guard !isNarrowed, hasLabels else {
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

    /// True when the narrowing matches nothing — drives the empty state
    var cameUpEmpty: Bool { isNarrowed && filteredSets.isEmpty }

    // MARK: - Pinning

    func isPinned(_ set: MeditationSetSummary) -> Bool {
        favorites.isFavorite(set.id)
    }

    func togglePin(_ set: MeditationSetSummary) {
        favorites.toggle(set.id)
    }

    // MARK: - Data Loading

    /// Loads the list of available meditation sets for this category.
    ///
    /// Only loads once - subsequent calls are no-ops if data exists.
    ///
    /// Luminous has no server content yet, so the bundled traditional set
    /// is always prepended — even when the API call fails, the picker
    /// still has something to pray with.
    @MainActor
    func loadMeditationSets() async {
        guard meditationSets.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            meditationSets = try await apiService.fetchMeditationSets(category: category)
        } catch {
            // Downloaded offline content keeps the picker honest and usable
            if let stored = OfflineContentService.shared.storedSummaries(category: category) {
                meditationSets = stored
            } else {
                errorMessage = "Can't reach Lumen Viae — the server may be waking up."
            }
        }

        if category == .luminous {
            meditationSets.insert(LuminousMeditationData.summary, at: 0)
            errorMessage = nil
        }

        isLoading = false
    }

    /// Clears the loaded list and fetches again (drives the Retry button).
    @MainActor
    func retry() async {
        meditationSets = []
        await loadMeditationSets()
    }
}
