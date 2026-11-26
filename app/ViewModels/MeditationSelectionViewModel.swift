//
//  MeditationSelectionViewModel.swift
//  Lumen Viae
//
//  State for the meditation picker: loads the list of meditation sets
//  for a category and narrows it for display.
//
//  Browsing is label-driven: sets may carry descriptive labels from the
//  API (e.g., ["Saints", "Scriptural"]). Labels become the chips in the
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

    /// Whether the initial list is loading. It begins true when nothing
    /// is preloaded, so the page's first frames, drawn while it slides in
    /// and before its `.task` runs, show the spinner and not "No
    /// meditations · Try again", which flashed and then jumped to the
    /// spinner and the shelf (ios-review, App Store preview, 16 Nov 2026)
    var isLoading: Bool

    /// Error message if loading fails (nil on success)
    var errorMessage: String?

    /// Whether the shelf holds only the built-in set because the server's
    /// could not be reached and none were downloaded: the page then says
    /// that more come with a connection
    private(set) var showsOnlyBuiltIn = false

    // MARK: - Dependencies

    private let apiService: APIService
    private let favorites: FavoritesService

    /// The sets this session last loaded for each set of mysteries, so a
    /// page opened again shows them at once (nil: none kept, as in tests
    /// that bring their own service)
    private let sessionCache: MeditationSetsSessionCache?

    /// Whether the list on show came from the session's copy and still
    /// owes a quiet refresh
    private var owesRefresh = false

    // MARK: - Initialization

    init(
        category: MysteryCategory,
        apiService: APIService? = nil,
        favorites: FavoritesService? = nil,
        preloadedSets: [MeditationSetSummary] = [],
        sessionCache: MeditationSetsSessionCache? = nil
    ) {
        self.category = category
        self.apiService = apiService ?? .shared
        self.favorites = favorites ?? .shared
        // The live page keeps the session's copy; a test with a service of
        // its own keeps none unless it brings one
        self.sessionCache = sessionCache ?? (apiService == nil ? .shared : nil)
        // Opened again in the same session, the page shows what it loaded
        // last time at once and refreshes quietly behind it, rather than a
        // spinner for the fetch on every open (ios-review, App Store
        // preview, 17 Nov 2026)
        let kept = preloadedSets.isEmpty ? self.sessionCache?.sets(for: category) : nil
        let shown = kept ?? preloadedSets
        self.meditationSets = shown
        self.owesRefresh = kept != nil
        self.isLoading = shown.isEmpty
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
            result.append(Section(title: result.isEmpty ? nil : String(
                localized: "More",
                comment: "Mysteries' page: heading over the meditation sets that carry no kind, closing the list"
            ), sets: unlabeled))
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
    /// The bundled sets stand only when nothing else can: with no signal
    /// and nothing downloaded, so the picker still has something to pray
    /// with. Beside the server's they read as the same set twice
    /// (Abraham, 17 Nov 2026: "maybe these are the built-in ones if so
    /// just get rid of these like we shouldn't be showing these").
    @MainActor
    func loadMeditationSets() async {
        guard meditationSets.isEmpty else {
            if owesRefresh { await refreshQuietly() }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            meditationSets = try await apiService.fetchMeditationSets(category: category)
            sessionCache?.keep(meditationSets, for: category)
        } catch {
            // Downloaded offline content keeps the picker honest and usable
            if let stored = OfflineContentService.shared.storedSummaries(category: category) {
                meditationSets = stored
            } else {
                errorMessage = String(
                    localized: "Couldn't load the meditations. Check your connection and try again.",
                    comment: "Mysteries' page: shown when the meditation sets could not be loaded"
                )
            }
        }

        // The bundled set for these mysteries stands only when there is no
        // other: no signal and nothing downloaded
        showsOnlyBuiltIn = meditationSets.isEmpty
        if meditationSets.isEmpty {
            meditationSets = BundledMeditationSets.summaries(for: category)
        }
        errorMessage = nil

        isLoading = false
    }

    /// The fetch behind a list shown from the session's copy: no spinner,
    /// and on failure (offline) the list on show stays
    @MainActor
    private func refreshQuietly() async {
        owesRefresh = false
        guard let fresh = try? await apiService.fetchMeditationSets(category: category), !fresh.isEmpty else { return }
        sessionCache?.keep(fresh, for: category)
        if fresh != meditationSets { meditationSets = fresh }
        showsOnlyBuiltIn = false
    }

    /// Clears the loaded list and fetches again (drives the Retry button).
    @MainActor
    func retry() async {
        meditationSets = []
        await loadMeditationSets()
    }
}

/// The meditation sets loaded this session, by set of mysteries and the
/// language they were asked in. Kept in memory only: a new launch fetches
/// again, and downloaded sets stay `OfflineContentService`'s.
@MainActor
final class MeditationSetsSessionCache {
    static let shared = MeditationSetsSessionCache()

    private var stored: [String: [MeditationSetSummary]] = [:]

    private func key(_ category: MysteryCategory) -> String {
        "\(category.rawValue)|\(MeditationTranslation.requestLanguage ?? "en")"
    }

    func sets(for category: MysteryCategory) -> [MeditationSetSummary]? {
        stored[key(category)].flatMap { $0.isEmpty ? nil : $0 }
    }

    func keep(_ sets: [MeditationSetSummary], for category: MysteryCategory) {
        guard !sets.isEmpty else { return }
        stored[key(category)] = sets
    }
}
