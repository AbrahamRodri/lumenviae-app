//
//  AppSearch.swift
//  Lumen Viae
//
//  The one search the app has. Explore's field, the Prayers page's glass
//  and the Chant page's glass all open it; what differs is only where it
//  was opened from (`AppSearch.Origin`), which decides the kind the
//  results lead with.
//
//  The page it builds (the "one app search" design, option E, Oct 2026):
//  the best match in the leading kind as one card, then a section per
//  kind, the leading kind's first, the rest in Explore's order. The kind
//  chips jump between those sections; they never filter.
//
//  Everything here is found on the device. Prayers, chants, mysteries
//  and readings are bundled, so a search in a chapel with no signal
//  finds them; the meditation sets are the server's, fetched by the page
//  and handed in. The finding itself is each area's own
//  (`PrayerBook.search`, `PrayerBook.searchOrders`, `ChantCatalog.search`);
//  this file only gathers, orders and picks the best.
//

import Foundation

enum AppSearch {

    /// Where the search was opened from
    enum Origin: Hashable {
        /// Home's glass and Explore: no kind leads
        case everywhere
        case prayers
        case chant

        /// The kind the results lead with, if any
        var leadingKind: Kind? {
            switch self {
            case .everywhere: return nil
            case .prayers: return .prayers
            case .chant: return .chants
            }
        }
    }

    /// The kinds of thing the search finds, in Explore's order: the order
    /// the sections take when no kind leads
    enum Kind: String, CaseIterable, Identifiable {
        case mysteries
        case pages
        case readings
        case prayers
        case chants
        case meditations

        var id: String { rawValue }

        /// The section's heading and the chip's word
        var title: String {
            switch self {
            case .mysteries: return "Rosary Mysteries"
            case .pages: return "Pages"
            case .readings: return "Readings"
            case .prayers: return "Prayers"
            case .chants: return "Chants"
            case .meditations: return "Meditations"
            }
        }

        /// The chip's word, where the heading is too long for one
        var chipTitle: String {
            self == .mysteries ? "Mysteries" : title
        }
    }

    /// A door of the app found by name (the Missal, How to Pray…). The
    /// page knows what each opens; the search knows only its words.
    struct Page: Hashable {
        let id: String
        let title: String
        let matchText: String
    }

    /// One thing found
    enum Hit: Identifiable {
        case mysteries(MysteryCategory)
        case mystery(Mystery)
        case page(Page)
        case reading(shelf: ReadingShelf, reading: LibraryReading)
        case order(PrayerOrder)
        case prayer(BookPrayer)
        case chant(Chant)
        case meditationSet(MeditationSetSummary)

        var id: String {
            switch self {
            case .mysteries(let category): return "mysteries:\(category.rawValue)"
            case .mystery(let mystery): return "mystery:\(mystery.category):\(mystery.order)"
            case .page(let page): return "page:\(page.id)"
            case .reading(_, let reading): return "reading:\(reading.id)"
            case .order(let order): return "order:\(order.id)"
            case .prayer(let prayer): return "prayer:\(prayer.id)"
            case .chant(let chant): return "chant:\(chant.id)"
            case .meditationSet(let summary): return "set:\(summary.id)"
            }
        }

        var kind: Kind {
            switch self {
            case .mysteries, .mystery: return .mysteries
            case .page: return .pages
            case .reading: return .readings
            case .order, .prayer: return .prayers
            case .chant: return .chants
            case .meditationSet: return .meditations
            }
        }

        /// The names it is known by, for judging how well it matches
        var names: [String] {
            switch self {
            case .mysteries(let category): return [category.devotionTitle]
            case .mystery(let mystery): return [mystery.name]
            case .page(let page): return [page.title]
            case .reading(_, let reading): return [reading.title]
            case .order(let order): return [order.title(on: Date()), order.latinTitle]
            case .prayer(let prayer): return [prayer.listTitle, prayer.title] + [prayer.latinTitle].compactMap { $0 }
            case .chant(let chant): return [chant.latinTitle, chant.englishTitle]
            case .meditationSet(let summary): return [summary.name]
            }
        }
    }

    struct Section: Identifiable {
        let kind: Kind
        let hits: [Hit]
        var id: Kind { kind }
    }

    struct Results {
        /// The best match, drawn as a card above the sections and left
        /// out of its own section
        let best: Hit?
        let sections: [Section]

        var isEmpty: Bool { best == nil && sections.isEmpty }

        /// The kinds that found something, in the page's order: the
        /// chips. The best match's kind counts though its section may
        /// be empty without it.
        var kinds: [Kind] {
            var kinds = sections.map(\.kind)
            if let best, !kinds.contains(best.kind) { kinds.insert(best.kind, at: 0) }
            return kinds
        }

        /// How many of a kind were found, the best match included
        func count(of kind: Kind) -> Int {
            let inSection = sections.first { $0.kind == kind }?.hits.count ?? 0
            return inSection + (best?.kind == kind ? 1 : 0)
        }
    }

    // MARK: - Searching

    /// Everything the words find, shaped for where the search began.
    /// `sets` are the meditation sets the page has fetched; `pages` the
    /// app's doors it can open; `shelves` the reading shelves not put
    /// away.
    static func results(
        for query: String,
        from origin: Origin,
        sets: [MeditationSetSummary] = [],
        pages: [Page] = [],
        shelves: [ReadingShelf] = defaultShelves
    ) -> Results {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return Results(best: nil, sections: []) }

        var found: [Kind: [Hit]] = [:]
        found[.mysteries] = mysteryHits(needle)
        found[.pages] =
            pages
            .filter { "\($0.title) \($0.matchText)".lowercased().contains(needle) }
            .map(Hit.page)
        found[.readings] = readingHits(needle, shelves: shelves)
        found[.prayers] =
            PrayerBook.searchOrders(needle).map(Hit.order)
            + PrayerBook.search(needle).map(Hit.prayer)
        found[.chants] = ChantCatalog.search(needle).map(Hit.chant)
        found[.meditations] = sets.filter { matches($0, needle: needle) }.map(Hit.meditationSet)

        return shape(found, needle: needle, origin: origin)
    }

    /// Orders what was found: picks the best, and puts the leading
    /// kind's section first. Split from the finding so it can be tested
    /// with hits of one's own.
    static func shape(_ found: [Kind: [Hit]], needle: String, origin: Origin) -> Results {
        let order = sectionOrder(for: origin)
        let best = bestMatch(in: found, needle: needle, order: order, origin: origin)

        let sections: [Section] = order.compactMap { kind in
            let hits = (found[kind] ?? []).filter { $0.id != best?.id }
            return hits.isEmpty ? nil : Section(kind: kind, hits: hits)
        }
        return Results(best: best, sections: sections)
    }

    /// The sections' order: the leading kind, then the rest as Explore
    /// sets them
    static func sectionOrder(for origin: Origin) -> [Kind] {
        guard let lead = origin.leadingKind else { return Kind.allCases }
        return [lead] + Kind.allCases.filter { $0 != lead }
    }

    // MARK: - The best match

    /// How well a name answers the words, best first
    enum Closeness: Int, Comparable {
        case none = 0
        /// The words are somewhere in the name
        case within
        /// A word of the name begins with them
        case wordStart
        /// The name begins with them
        case start
        /// The name is the words
        case exact

        static func < (lhs: Closeness, rhs: Closeness) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    static func closeness(of name: String, to needle: String) -> Closeness {
        let name = fold(name)
        let needle = fold(needle)
        guard !needle.isEmpty else { return .none }
        if name == needle { return .exact }
        if name.hasPrefix(needle) { return .start }
        let words = name.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(needle) }) { return .wordStart }
        return name.contains(needle) ? .within : .none
    }

    /// The card at the top. Opened from Prayers or Chant, the first of
    /// that kind, whose own search has already put the closest first;
    /// from anywhere else, or when that kind found nothing, the first of
    /// each kind that answers best by name, a tie going to the section
    /// that stands first. A hit found only in its words is never the
    /// best: a card says "this is what you meant".
    static func bestMatch(in found: [Kind: [Hit]], needle: String, order: [Kind], origin: Origin) -> Hit? {
        if let lead = origin.leadingKind, let first = found[lead]?.first,
            closenessOfBest(first, to: needle) > .none
        {
            return first
        }
        var best: (hit: Hit, closeness: Closeness)?
        for kind in order {
            guard let first = found[kind]?.first else { continue }
            let closeness = closenessOfBest(first, to: needle)
            if closeness > (best?.closeness ?? .none) { best = (first, closeness) }
        }
        return best?.hit
    }

    private static func closenessOfBest(_ hit: Hit, to needle: String) -> Closeness {
        hit.names.map { closeness(of: $0, to: needle) }.max() ?? .none
    }

    /// Case, accents and the ligatures folded away, so "caeli" answers
    /// Cæli as the areas' own searches do
    static func fold(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    }

    // MARK: - The kinds Explore found itself

    /// The reading shelves search looks in: every one not put away
    static var defaultShelves: [ReadingShelf] {
        LibraryReadings.shelves.filter { !ArchivedPages.hides(shelf: $0) }
    }

    /// A devotion by its name or what it is about, and a single mystery
    /// by its name. A devotion found by name stands before its mysteries.
    static func mysteryHits(_ needle: String) -> [Hit] {
        let categories = MysteryCategory.allCases.filter {
            $0.devotionTitle.lowercased().contains(needle)
                || $0.subtitle.lowercased().contains(needle)
        }
        let mysteries = MysteryCategory.allCases.flatMap { MysteryData.mysteries(for: $0) }
            .filter { fold($0.name).contains(fold(needle)) }
        return categories.map(Hit.mysteries) + mysteries.map(Hit.mystery)
    }

    /// A reading by its title or its dating line. A shelf's own title
    /// answers only when no reading does: matched as well, "carlo"
    /// listed every one of St. Carlo's readings and buried the one asked
    /// for.
    static func readingHits(_ needle: String, shelves: [ReadingShelf]) -> [Hit] {
        let shelved = shelves.flatMap { shelf in shelf.entries.map { (shelf, $0) } }
        let named = shelved.filter {
            $0.1.title.lowercased().contains(needle) || $0.1.detail.lowercased().contains(needle)
        }
        let hits = named.isEmpty ? shelved.filter { $0.0.title.lowercased().contains(needle) } : named
        return hits.map { Hit.reading(shelf: $0.0, reading: $0.1) }
    }

    /// A meditation set by its name, author, source, labels (by the word
    /// the shelf shows as well as the one the server stores) or devotion
    static func matches(_ summary: MeditationSetSummary, needle: String) -> Bool {
        if summary.name.lowercased().contains(needle) { return true }
        if let author = summary.author, author.lowercased().contains(needle) { return true }
        if let source = summary.source, source.lowercased().contains(needle) { return true }
        if let labels = summary.labels,
            labels.contains(where: {
                $0.lowercased().contains(needle) || MeditationLabel.displayName($0).lowercased().contains(needle)
            })
        {
            return true
        }
        if let category = MysteryCategory(rawValue: summary.category),
            category.devotionTitle.lowercased().contains(needle)
        {
            return true
        }
        return false
    }
}
