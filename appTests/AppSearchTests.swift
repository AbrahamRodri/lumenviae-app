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
        #expect(Array(fromPrayers.dropFirst()) == AppSearch.Kind.allCases.filter { $0 != .prayers })

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
        // section that stands first in Explore's order wins the tie
        let results = AppSearch.results(for: "memorare", from: .everywhere)
        #expect(results.best != nil)
        #expect(results.best.map { AppSearch.closeness(of: $0.names.first ?? "", to: "memorare") } == .exact)
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
