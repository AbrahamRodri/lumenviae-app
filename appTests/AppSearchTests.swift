//
//  AppSearchTests.swift
//  Lumen Viae Tests
//
//  The one search: the kind it was opened from leads, the best match
//  stands once above its section, the chips are the sections found, and
//  the bundled kinds are found with no network.
//

import Foundation
import Testing

@testable import app

@MainActor
struct AppSearchTests {

    // MARK: - Order

    @Test func sectionsFollowExploreWhenNoKindLeads() {
        #expect(AppSearch.sectionOrder(for: .everywhere) == AppSearch.Kind.allCases)
    }

    @Test func theOriginsKindLeadsAndTheRestKeepTheirOrder() {
        let fromPrayers = AppSearch.sectionOrder(for: .prayers)
        #expect(fromPrayers.first == .prayers)
        let rest = AppSearch.Kind.allCases.filter { $0 != .prayers && $0 != .chants }
        #expect(Array(fromPrayers.dropFirst(2)) == rest)

        let fromChant = AppSearch.sectionOrder(for: .chant)
        #expect(fromChant.first == .chants)
        #expect(Set(fromChant) == Set(AppSearch.Kind.allCases))
    }

    // MARK: - Closeness

    @Test func closenessRanksExactOverStartOverWordOverWithin() {
        #expect(AppSearch.closeness(of: "Salve Regina", to: "salve regina") == .exact)
        #expect(AppSearch.closeness(of: "Salve Regina", to: "salve") == .start)
        #expect(AppSearch.closeness(of: "Hail, Holy Queen", to: "queen") == .wordStart)
        #expect(AppSearch.closeness(of: "Salvete", to: "lvet") == .within)
        #expect(AppSearch.closeness(of: "Memorare", to: "queen") == .none)
    }

    @Test func closenessFoldsAccentsAndLigatures() {
        #expect(AppSearch.closeness(of: "Regina Cæli", to: "regina caeli") == .exact)
        #expect(AppSearch.closeness(of: "Misericórdiæ", to: "misericordiae") == .exact)
    }

    // MARK: - From Prayers and from Chant

    @Test func fromPrayersAPrayerIsTheBestMatchAndPrayersLead() {
        let results = AppSearch.results(for: "queen", from: .prayers)
        #expect(results.best?.kind == .prayers)
        #expect(results.kinds.first == .prayers)
        #expect(results.kinds.contains(.chants))
    }

    @Test func fromChantAChantIsTheBestMatchAndChantsLead() {
        let results = AppSearch.results(for: "queen", from: .chant)
        #expect(results.best?.kind == .chants)
        #expect(results.kinds.first == .chants)
        #expect(results.kinds.contains(.prayers))
    }

    @Test func theSameWordsFindTheSameThingsFromEitherPage() {
        let fromPrayers = AppSearch.results(for: "salve", from: .prayers)
        let fromChant = AppSearch.results(for: "salve", from: .chant)
        let ids = { (r: AppSearch.Results) in
            Set(r.sections.flatMap { $0.hits.map(\.id) } + [r.best?.id].compactMap { $0 })
        }
        #expect(ids(fromPrayers) == ids(fromChant))
    }

    @Test func theBestMatchStandsOnceAndIsCounted() {
        let results = AppSearch.results(for: "queen", from: .chant)
        guard let best = results.best else {
            Issue.record("queen found no best match")
            return
        }
        let listed = results.sections.flatMap { $0.hits.map(\.id) }
        #expect(!listed.contains(best.id))
        let inSection = results.sections.first { $0.kind == best.kind }?.hits.count ?? 0
        #expect(results.count(of: best.kind) == inSection + 1)
    }

    // MARK: - From anywhere

    @Test func fromAnywhereTheClosestNameIsTheBest() {
        // "Memorare" is a prayer's name and a chant's: both exact, so the
        // kind that stands first in Explore's order, Prayers, wins the tie
        let results = AppSearch.results(for: "memorare", from: .everywhere)
        #expect(results.best?.kind == .prayers)
        #expect(results.kinds.first == .prayers)
    }

    @Test func fromPrayersTheAngelusIsAPrayerNotAChant() {
        // The Daily Prayers topic answers "angelus" by its other words and
        // stands first among the prayers; the card must still be the
        // Angelus prayer or its order, never the Angelus chant
        for word in ["angelus", "night prayers", "morning prayers"] {
            let results = AppSearch.results(for: word, from: .prayers)
            #expect(results.best?.kind == .prayers, "\(word) gave \(results.best?.id ?? "no card")")
            if case .topic = results.best { Issue.record("\(word): a topic found by its other words took the card") }
        }
    }

    @Test func aChantIsFoundByItsSungWords() {
        // A line of the Salve Regina that no title holds
        let results = AppSearch.results(for: "spes nostra", from: .chant)
        let chants = ([results.best].compactMap { $0 } + results.sections.flatMap(\.hits))
            .filter { $0.kind == .chants }
        #expect(chants.contains { $0.id.hasPrefix("chant:salve_regina") })
        // Found only in its words, it is no card
        if case .chant = results.best { Issue.record("a chant found in its words took the card") }
    }

    @Test func fromEitherPageTheOtherPagesKindComesSecond() {
        #expect(Array(AppSearch.sectionOrder(for: .prayers).prefix(2)) == [.prayers, .chants])
        #expect(Array(AppSearch.sectionOrder(for: .chant).prefix(2)) == [.chants, .prayers])
    }

    @Test func theCardsKindLeadsTheChips() {
        let page = AppSearch.Page(id: "office", title: "Hours of Prayer", matchText: "office")
        let chant = ChantCatalog.all.first { $0.latinTitle == "Salve Regina" }!
        // From Home the pages section stands before the chants, but the
        // chant is the card, so its chip comes first
        let results = AppSearch.shape(
            [.pages: [.page(page)], .chants: [.chant(chant)]], needle: "salve", origin: .everywhere)
        #expect(results.best?.kind == .chants)
        #expect(results.kinds == [.chants, .pages])
    }

    // MARK: - Readings and meditation sets

    private static func reading(_ id: String, _ title: String, _ detail: String) -> LibraryReading {
        LibraryReading(id: id, title: title, detail: detail, paragraphs: [], quote: nil)
    }

    private static let shelf = ReadingShelf(
        id: "test", icon: "lv-rose", title: "Where Mary Appeared", marginLabel: "", subtitle: "",
        entries: [reading("lourdes", "Lourdes", "1858 · Bernadette"), reading("fatima", "Fátima", "1917")]
    )

    @Test func aReadingIsFoundByTitleOrDatingLineFolded() {
        let byTitle = AppSearch.readingHits("fatima", shelves: [Self.shelf])
        #expect(byTitle.map(\.id) == ["reading:fatima"])
        let byDetail = AppSearch.readingHits("bernadette", shelves: [Self.shelf])
        #expect(byDetail.map(\.id) == ["reading:lourdes"])
    }

    @Test func aShelfsTitleAnswersOnlyWhenNoReadingDoes() {
        let hits = AppSearch.readingHits("appeared", shelves: [Self.shelf])
        #expect(hits.count == 2)
        #expect(AppSearch.readingHits("lourdes", shelves: [Self.shelf]).count == 1)
    }

    @Test func archivedShelvesAreLeftOut() {
        #expect(AppSearch.defaultShelves.allSatisfy { !ArchivedPages.hides(shelf: $0) })
    }

    @Test func aMeditationSetIsFoundByAuthorAndByTheLabelTheShelfShows() {
        let set = MeditationSetSummary(
            id: 9, name: "The Gospel Read Slowly", category: "joyful", description: nil,
            labels: ["Scriptural"], author: "St. Thérèse"
        )
        #expect(AppSearch.matches(set, needle: "therese"))
        #expect(AppSearch.matches(set, needle: "scriptural"))
        #expect(AppSearch.matches(set, needle: AppSearch.fold("Gospel")))
        #expect(AppSearch.matches(set, needle: "joyful"))
        #expect(!AppSearch.matches(set, needle: "sorrowful"))
    }

    @Test func aMysteryIsFoundByItsOwnName() {
        let results = AppSearch.results(for: "coronation", from: .everywhere)
        let all = [results.best].compactMap { $0 } + results.sections.flatMap(\.hits)
        #expect(
            all.contains {
                if case .mystery(let m) = $0 { return m.name.contains("Coronation") }
                return false
            })
    }

    @Test func aDevotionIsFoundByItsTitle() {
        let results = AppSearch.results(for: "sorrowful", from: .everywhere)
        let all = [results.best].compactMap { $0 } + results.sections.flatMap(\.hits)
        #expect(all.contains { $0.id == "mysteries:sorrowful" })
    }

    // MARK: - Shaping hits of one's own

    @Test func aLeadingKindWithNothingFoundGivesWayToTheClosestElsewhere() {
        let chant = ChantCatalog.all.first { $0.latinTitle == "Salve Regina" }!
        let results = AppSearch.shape([.chants: [.chant(chant)]], needle: "salve", origin: .prayers)
        #expect(results.best?.id == "chant:\(chant.id)")
        #expect(results.sections.isEmpty)
        #expect(results.kinds == [.chants])
        #expect(results.count(of: .chants) == 1)
    }

    @Test func aHitFoundOnlyInItsWordsIsNeverTheCard() {
        let page = AppSearch.Page(id: "missal", title: "Today's Mass", matchText: "missal propers")
        let results = AppSearch.shape([.pages: [.page(page)]], needle: "propers", origin: .everywhere)
        #expect(results.best == nil)
        #expect(results.sections.map(\.kind) == [.pages])
    }

    @Test func pagesAreFoundByTitleOrWords() {
        let pages = [
            AppSearch.Page(id: "missal", title: "Today's Mass", matchText: "missal propers 1962"),
            AppSearch.Page(id: "office", title: "Hours of Prayer", matchText: "divine office breviary"),
        ]
        let results = AppSearch.results(for: "breviary", from: .everywhere, pages: pages)
        let found = [results.best].compactMap { $0 } + results.sections.flatMap(\.hits)
        #expect(found.map(\.id).contains("page:office"))
        #expect(!found.map(\.id).contains("page:missal"))
    }

    @Test func emptyWordsFindNothing() {
        #expect(AppSearch.results(for: "   ", from: .chant).isEmpty)
    }
}
