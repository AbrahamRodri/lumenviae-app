//
//  MeditationSetDetailViewModel.swift
//  Lumen Viae
//
//  State for one meditation set's detail screen — the step between the
//  picker and the Rosary.
//
//  The screen shows what the picker already knew (name, labels,
//  description) and loads the full set behind it, both for the opening
//  of the first mystery and so that "Pray with these meditations" is
//  instant. Concurrent loads of one set — the screen's own and a "Pray"
//  tap during it — are shared by MeditationSetResolver.
//

import SwiftUI

@Observable
final class MeditationSetDetailViewModel {

    // MARK: - State

    /// What the picker knew about the set
    let summary: MeditationSetSummary

    /// The complete set, once resolved (bundled → API → offline)
    private(set) var fullSet: MeditationSet?

    // MARK: - Dependencies

    private let favorites: FavoritesService

    // MARK: - Initialization

    init(
        summary: MeditationSetSummary,
        favorites: FavoritesService? = nil,
        preloadedSet: MeditationSet? = nil
    ) {
        self.summary = summary
        self.favorites = favorites ?? .shared
        self.fullSet = preloadedSet
    }

    // MARK: - Identity

    var category: MysteryCategory? { summary.mysteryCategory }

    var name: String { summary.name }

    var description: String? {
        summary.description.flatMap { $0.isEmpty ? nil : $0 }
    }

    var labels: [String] { summary.labels ?? [] }

    /// Where the set sits: "Sorrowful Mysteries · Tuesday, Friday"
    var contextLine: String? {
        guard let category else { return nil }
        return "\(category.devotionTitle)  ·  \(category.daysPrayed)"
    }

    /// The painting behind the title. The API has no artwork per set yet,
    /// so this borrows the category's own card painting; when a set
    /// carries its own image this is where it takes over.
    var artworkName: String {
        category?.cardImageName ?? MysteryCategory.joyful.cardImageName
    }

    var artworkAlignment: Alignment {
        category?.cardImageAlignment ?? .center
    }

    // MARK: - Pinning

    var isPinned: Bool { favorites.isFavorite(summary.id) }

    func togglePin() { favorites.toggle(summary.id) }

    // MARK: - The Opening

    /// The first meditation of the set — the taste of its voice
    var firstMeditation: Meditation? { fullSet?.meditations?.first }

    /// The first meditation in full, as the page previews it. Nil until
    /// the set loads, and nil for a set whose first meditation is empty —
    /// the one rule for "is there a preview", so the page never has to
    /// decide for itself.
    var previewText: String? {
        guard let content = firstMeditation?.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return content
    }

    /// The mystery the preview is drawn from, for the line under the
    /// heading. Falls back to the ordinal when the mystery has no name of
    /// its own to lend.
    var previewSubject: String {
        if let name = firstMeditation?.mystery?.name, !name.isEmpty { return name }
        return firstMysteryLabel
    }

    /// "The First Sorrowful Mystery" — or, for the chaplet, "The First
    /// Sorrow of Mary"
    var firstMysteryLabel: String {
        category?.mysteryLabel(ordinal: 1) ?? "The First Mystery"
    }

    /// Whether there is anything to pray with. A set the API returned
    /// without meditations must not start a Rosary of no decades.
    var hasMeditations: Bool {
        guard let fullSet else { return true }   // unknown until loaded
        return !(fullSet.meditations ?? []).isEmpty
    }

    // MARK: - Loading

    /// Whether the full set is being fetched
    private(set) var isLoading = false

    /// Set when the fetch failed; drives the inline retry
    private(set) var loadFailed = false

    /// Loads the full set for the opening and warms it for praying. Safe
    /// to call more than once; a set already loaded is not fetched again,
    /// and a load already running is shared by the resolver.
    @MainActor
    func load() async {
        guard fullSet == nil else { return }
        _ = try? await resolve()
    }

    /// The full set, resolving it if needed. Throws so the caller can
    /// offer a retry — the prayer flow must never start with a
    /// substituted set under this set's name.
    @MainActor
    func resolve() async throws -> MeditationSet {
        if let fullSet { return fullSet }

        isLoading = true
        loadFailed = false
        defer { isLoading = false }

        do {
            let set = try await MeditationSetResolver.resolve(
                id: summary.id,
                categoryHint: summary.category
            )
            fullSet = set
            return set
        } catch {
            loadFailed = true
            throw error
        }
    }
}
