//
//  MeditationSetDetailViewModel.swift
//  Lumen Viae
//
//  State for one meditation set's detail screen — the step between the
//  picker and the Rosary.
//
//  The screen shows what the picker already knew (name, labels,
//  description), what the devotion itself supplies (the scenes, in
//  order), and what the full set adds once it lands (the voice behind
//  it, the first meditation). The full set loads behind the page so
//  "Pray" is instant. Concurrent loads of one set — the screen's own and
//  a "Pray" tap during it — are shared by MeditationSetResolver.
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
    private let offline: OfflineContentService

    // MARK: - Initialization

    init(
        summary: MeditationSetSummary,
        favorites: FavoritesService? = nil,
        offline: OfflineContentService? = nil,
        preloadedSet: MeditationSet? = nil
    ) {
        self.summary = summary
        self.favorites = favorites ?? .shared
        self.offline = offline ?? .shared
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

    /// The set's own painting, when the API carries one. The summary has
    /// it already, so the frontispiece is right from the first frame; the
    /// full set only fills in for a summary that predates artwork. Nil
    /// means the plate shows the category's painting — `SetArtworkView`
    /// owns that fallback.
    var artwork: SetArtwork? {
        summary.artwork ?? fullSet?.artwork
    }

    /// "Christ Carrying the Cross  ·  El Greco  ·  c. 1580" — the plate's
    /// caption, when the painting came with one. Nil for a bundled
    /// fallback, which is uncredited as it always was.
    var artworkCredit: String? {
        artwork?.attribution?.creditLine
    }

    // MARK: - Pinning

    var isPinned: Bool { favorites.isFavorite(summary.id) }

    func togglePin() { favorites.toggle(summary.id) }

    // MARK: - What the set walks through

    /// The meditations, named and in the order they will be prayed.
    ///
    /// The set's own titles once it is in hand — a meditation that
    /// carries a title of its own says that, and one that doesn't falls
    /// back to its mystery. Before the set lands these are the
    /// category's bundled mysteries, since which scenes a category holds
    /// is doctrine rather than content and needs no round trip to a cold
    /// server.
    var entryTitles: [String] {
        let loaded = (fullSet?.meditations ?? []).map(\.displayTitle)
        if !loaded.isEmpty { return loaded }
        guard let category else { return [] }
        return MysteryData.mysteries(for: category).map(\.name)
    }

    // MARK: - Attribution

    /// The book the meditations were drawn from, when the API can say so
    /// for the whole set. The set's own `source` is the set's byline, or
    /// the meditations' when every one agrees — a set of mixed voices
    /// sends null, and the page says nothing rather than borrowing the
    /// first meditation's book for all five. The summary carries it, so
    /// the line is there before the full set lands.
    var sourceTitle: String? {
        (summary.source ?? fullSet?.source).flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Who wrote them, on the same terms — suppressed when it only
    /// repeats the set's own name, which is the common case for a set
    /// named after its author ("Blessed Fulton J. Sheen" / "Bishop
    /// Fulton J. Sheen").
    var authorName: String? {
        guard let author = summary.author ?? fullSet?.author, !author.isEmpty else { return nil }
        let inAuthor = Self.distinctiveWords(author)
        guard !inAuthor.isEmpty else { return nil }
        return inAuthor.isSubset(of: Self.distinctiveWords(name)) ? nil : author
    }

    var hasAttribution: Bool { sourceTitle != nil || authorName != nil }

    /// Titles and honorifics carry no identity — two names that differ
    /// only by "Blessed" and "Bishop" are the same person, and the page
    /// should say them once.
    private static let honorifics: Set<String> = [
        "st", "ste", "saint", "bl", "blessed", "ven", "venerable",
        "pope", "bishop", "archbishop", "cardinal", "fr", "father",
        "sr", "sister", "br", "brother", "servant", "god", "the", "of",
        "doctor", "dom", "mother", "de", "la", "du"
    ]

    private static func distinctiveWords(_ s: String) -> Set<String> {
        Set(
            s.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 1 && !honorifics.contains($0) }
        )
    }

    // MARK: - Offline

    /// Where this set stands on the device, or nil while the set is still
    /// loading — what a set weighs offline isn't knowable until the
    /// narrations it carries are known.
    ///
    /// Read straight through to the service on every access rather than
    /// cached, so a page left open still tells the truth after the whole
    /// library is wiped from Account.
    var offlineState: OfflineContentService.SetOfflineState? {
        guard let fullSet else { return nil }
        return offline.offlineState(for: fullSet)
    }

    /// Saves the set, or removes it if it's already saved. A save in
    /// flight is left alone — cancelling mid-download would leave a
    /// half-saved set claiming to be prayable offline.
    @MainActor
    func toggleOfflineCopy() async {
        guard let fullSet else { return }

        switch offline.offlineState(for: fullSet) {
        case .saved:
            offline.removeSet(fullSet)
        case .available, .failed:
            await offline.downloadSet(fullSet)
        case .saving:
            break
        }
    }

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
