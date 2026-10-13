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
        /// The door's glyph, which its row wears
        var icon: String = "ph-book-open"
    }

    /// One thing found
    enum Hit: Identifiable {
        case mysteries(MysteryCategory)
        case mystery(Mystery)
        case page(Page)
        case reading(shelf: ReadingShelf, reading: LibraryReading)
        case topic(PrayerBookChapter)
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
            case .topic(let chapter): return "topic:\(chapter.id)"
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
            case .topic, .order, .prayer: return .prayers
            case .chant: return .chants
            case .meditationSet: return .meditations
            }
        }

        /// The names it is known by on a day, for judging how well it
        /// matches: an order of prayer goes by its day's name
        func names(on date: Date) -> [String] {
            switch self {
            case .mysteries(let category): return [category.devotionTitle]
            case .mystery(let mystery): return [mystery.name]
            case .page(let page): return [page.title]
            case .reading(_, let reading): return [reading.title]
            case .topic(let chapter): return [chapter.topic, chapter.title]
            case .order(let order): return [order.title(on: date), order.latinTitle]
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
        /// The day the search was made for, whose names its orders of
        /// prayer are drawn with
        var date = Date()

        /// The best card's scroll id; a section's is its kind's raw value
        static let bestScrollID = "best"

        /// Nothing searched for, or nothing found
        static let empty = Results(best: nil, sections: [])

        var isEmpty: Bool { best == nil && sections.isEmpty }

        /// Where the page stands before it is scrolled: the card, else
        /// the first section (`AppSearchResultsView`'s scroll ids)
        var firstScrollID: String? {
            if best != nil { return Self.bestScrollID }
            return sections.first?.kind.rawValue
        }

        /// The kinds that found something, in the page's order: the
        /// chips. The best match's kind stands first, as its card does,
        /// and counts though its section may be empty without it.
        var kinds: [Kind] {
            var kinds = sections.map(\.kind)
            if let best {
                kinds.removeAll { $0 == best.kind }
                kinds.insert(best.kind, at: 0)
            }
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
    /// away; `date` the day whose names the orders of prayer go by
    /// (Queen of Heaven for the Angelus in Eastertide).
    static func results(
        for query: String,
        from origin: Origin,
        sets: [MeditationSetSummary] = [],
        pages: [Page] = [],
        shelves: [ReadingShelf] = defaultShelves,
        on date: Date = Date()
    ) -> Results {
        let needle = SearchText.needle(query)
        guard !needle.isEmpty else { return Results(best: nil, sections: []) }

        var found: [Kind: [Hit]] = [:]
        found[.mysteries] = mysteryHits(needle)
        found[.pages] = pages.filter { SearchText.fold("\($0.title) \($0.matchText)").contains(needle) }.map(Hit.page)
        found[.readings] = readingHits(needle, shelves: shelves)
        // A topic the words name (Prayers to Mary), then an order of
        // prayer (Visiting Jesus in Church), then the prayers, as the
        // Prayers page once set its own search
        found[.prayers] =
            PrayerBook.topics(matching: needle).prefix(2).map(Hit.topic)
            + orderHits(needle, on: date).prefix(3).map(Hit.order)
            + PrayerBook.search(needle).map(Hit.prayer)
        found[.chants] = chantHits(needle)
        found[.meditations] = sets.filter { matches($0, needle: needle) }.map(Hit.meditationSet)

        return shape(found, needle: needle, origin: origin, on: date)
    }

    /// The orders of prayer the words name, by the book's own search and
    /// by the name the order goes by on the day, which the book's search
    /// does not know: in Eastertide "queen of heaven" is the Angelus
    static func orderHits(_ needle: String, on date: Date) -> [PrayerOrder] {
        let searched = PrayerBook.searchOrders(needle)
        let found = Set(searched.map(\.id))
        let seasonal = PrayerBook.orders.filter { order in
            !found.contains(order.id) && SearchText.fold(order.title(on: date)).contains(needle)
        }
        return searched + seasonal
    }

    /// Chants by their names, then by the prayer they sing and by a line
    /// of what is sung, as the Chant Library's own search found them.
    /// Found only in their words, they are never the best match.
    static func chantHits(_ needle: String) -> [Hit] {
        var seen = Set<String>()
        let byName = ChantCatalog.search(needle)
        let byPrayer = ChantSearch.chants(singingPrayerMatching: needle)
        let byWords = ChantSearch.chants(withWordsMatching: needle)
        return (byName + byPrayer + byWords)
            .filter { seen.insert($0.id).inserted }
            .map(Hit.chant)
    }

    /// Orders what was found: picks the best, and puts the leading
    /// kind's section first. Split from the finding so it can be tested
    /// with hits of one's own.
    static func shape(_ found: [Kind: [Hit]], needle: String, origin: Origin, on date: Date = Date()) -> Results {
        let order = sectionOrder(for: origin)
        let best = bestMatch(in: found, needle: needle, order: order, origin: origin, on: date)

        let sections: [Section] = order.compactMap { kind in
            let hits = (found[kind] ?? []).filter { $0.id != best?.id }
            return hits.isEmpty ? nil : Section(kind: kind, hits: hits)
        }
        return Results(best: best, sections: sections, date: date)
    }

    /// The sections' order: the leading kind, then the other page's
    /// kind (Chants after Prayers, Prayers after Chants), then the rest
    /// as Explore sets them
    static func sectionOrder(for origin: Origin) -> [Kind] {
        guard let lead = origin.leadingKind else { return Kind.allCases }
        let second: Kind = lead == .prayers ? .chants : .prayers
        return [lead, second] + Kind.allCases.filter { $0 != lead && $0 != second }
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
        let name = SearchText.fold(name)
        let needle = SearchText.fold(needle)
        guard !needle.isEmpty else { return .none }
        if name == needle { return .exact }
        if name.hasPrefix(needle) { return .start }
        let words = name.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(needle) }) { return .wordStart }
        return name.contains(needle) ? .within : .none
    }

    /// The card at the top. Opened from Prayers or Chant, the hit of
    /// that kind whose name answers closest; from anywhere else, or when
    /// no name of that kind answers, the closest of every kind, a tie
    /// going to the kind and then the hit that stands first. A hit found
    /// only by its words or other names (the Daily Prayers topic for
    /// "angelus") is never the best: a card says "this is what you
    /// meant". It once looked at each kind's first hit alone, and that
    /// topic, standing first, gave "angelus" from Prayers a chant's card.
    static func bestMatch(
        in found: [Kind: [Hit]], needle: String, order: [Kind], origin: Origin, on date: Date = Date()
    ) -> Hit? {
        if let lead = origin.leadingKind, let closest = closest(in: found[lead] ?? [], to: needle, on: date) {
            return closest.hit
        }
        var best: (hit: Hit, closeness: Closeness)?
        for kind in order {
            guard let closest = closest(in: found[kind] ?? [], to: needle, on: date) else { continue }
            if closest.closeness > (best?.closeness ?? .none) { best = closest }
        }
        return best?.hit
    }

    /// The hit whose name answers closest, the first winning a tie; nil
    /// when no name answers at all
    private static func closest(in hits: [Hit], to needle: String, on date: Date) -> (hit: Hit, closeness: Closeness)? {
        var best: (hit: Hit, closeness: Closeness)?
        for hit in hits {
            let closeness = closenessOfBest(hit, to: needle, on: date)
            if closeness > (best?.closeness ?? .none) { best = (hit, closeness) }
        }
        return best
    }

    private static func closenessOfBest(_ hit: Hit, to needle: String, on date: Date) -> Closeness {
        hit.names(on: date).map { closeness(of: $0, to: needle) }.max() ?? .none
    }

    // MARK: - The kinds Explore found itself
    //
    // Each takes the words already folded (`SearchText.needle`), and folds what it
    // matches them against, so "therese" finds Thérèse and "caeli" Cæli.

    /// The reading shelves search looks in: every one not put away
    static var defaultShelves: [ReadingShelf] {
        LibraryReadings.shelves.filter { !ArchivedPages.hides(shelf: $0) }
    }

    /// A devotion by its name or what it is about, and a single mystery
    /// by its name. A devotion found by name stands before its mysteries.
    static func mysteryHits(_ needle: String) -> [Hit] {
        let categories = MysteryCategory.allCases.filter {
            SearchText.fold($0.devotionTitle).contains(needle) || SearchText.fold($0.subtitle).contains(needle)
        }
        // A mystery opens its devotion's page, so one with none is no hit
        let mysteries = MysteryCategory.allCases.flatMap { MysteryData.mysteries(for: $0) }
            .filter { $0.mysteryCategory != nil && SearchText.fold($0.name).contains(needle) }
        return categories.map(Hit.mysteries) + mysteries.map(Hit.mystery)
    }

    /// A reading by its title or its dating line. A shelf's own title
    /// answers only when no reading does: matched as well, "carlo"
    /// listed every one of St. Carlo's readings and buried the one asked
    /// for.
    static func readingHits(_ needle: String, shelves: [ReadingShelf]) -> [Hit] {
        let shelved = shelves.flatMap { shelf in shelf.entries.map { (shelf, $0) } }
        let named = shelved.filter { SearchText.fold($0.1.title).contains(needle) || SearchText.fold($0.1.detail).contains(needle) }
        let hits = named.isEmpty ? shelved.filter { SearchText.fold($0.0.title).contains(needle) } : named
        return hits.map { Hit.reading(shelf: $0.0, reading: $0.1) }
    }

    /// A meditation set by its name, author, source, labels (by the word
    /// the shelf shows as well as the one the server stores) or devotion
    static func matches(_ summary: MeditationSetSummary, needle: String) -> Bool {
        let words =
            [summary.name, summary.author, summary.source,
             MysteryCategory(rawValue: summary.category)?.devotionTitle]
            .compactMap { $0 }
            + (summary.labels ?? []).flatMap { [$0, MeditationLabel.displayName($0)] }
        return words.contains { SearchText.fold($0).contains(needle) }
    }
}
