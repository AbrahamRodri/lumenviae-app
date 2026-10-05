//
//  SetPageAndHomeTests.swift
//  Lumen Viae Tests
//
//  A meditation set's own page as the reader sees it: its author named
//  only when the set's name does not already name them, its source, the
//  five (or seven) it walks through before and after the set is loaded,
//  the opening of its first meditation, its painting, and its pin. Then
//  home's grid: the week's sets, then the Seven Sorrows, today's among
//  them.
//

import Foundation
import Testing
@testable import app

@MainActor
struct SetPageTests {

    private func summary(id: Int = 12, name: String, category: String = "joyful",
                         description: String? = nil, author: String? = nil, source: String? = nil,
                         imageURL: String? = nil) -> MeditationSetSummary {
        var json: [String: Any] = ["id": id, "name": name, "category": category]
        if let description { json["description"] = description }
        if let author { json["author"] = author }
        if let source { json["source"] = source }
        if let imageURL { json["image_url"] = imageURL }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(MeditationSetSummary.self, from: data)
    }

    private func page(_ summary: MeditationSetSummary, set: MeditationSet? = nil, pinned: Set<Int> = []) -> MeditationSetDetailViewModel {
        MeditationSetDetailViewModel(summary: summary, favorites: FavoritesService(previewFavorites: pinned), preloadedSet: set)
    }

    private func fullSet(_ meditations: [Meditation]?, source: String? = nil) -> MeditationSet {
        MeditationSet(id: 12, name: "A Set", category: "joyful", description: nil, labels: nil,
                      meditations: meditations, source: source)
    }

    // MARK: Who and from where

    @Test func anAuthorTheNameAlreadyNamesIsNotSaidTwice() {
        #expect(page(summary(name: "St. Alphonsus Liguori", author: "St. Alphonsus Liguori")).authorName == nil)
        #expect(page(summary(name: "Saint Alphonsus Liguori", author: "St. Alphonsus Liguori")).authorName == nil,
                "honorifics are no difference")
    }

    @Test func anAuthorTheNameDoesNotNameIsSaid() {
        #expect(page(summary(name: "The Glories of Mary", author: "St. Alphonsus Liguori")).authorName == "St. Alphonsus Liguori")
        #expect(page(summary(name: "Sheen", author: "Fulton J. Sheen")).authorName == "Fulton J. Sheen")
        #expect(page(summary(name: "A Set", author: "")).authorName == nil)
    }

    @Test func theSourceComesFromTheSummaryOrTheLoadedSet() {
        #expect(page(summary(name: "A", source: "The Glories of Mary")).sourceTitle == "The Glories of Mary")
        #expect(page(summary(name: "A"), set: fullSet([], source: "Mystical City of God")).sourceTitle == "Mystical City of God")
        #expect(page(summary(name: "A", source: "")).sourceTitle == nil)
        #expect(!page(summary(name: "A")).hasAttribution)
    }

    @Test func anEmptyDescriptionIsNone() {
        #expect(page(summary(name: "A", description: "")).description == nil)
        #expect(page(summary(name: "A", description: "")).subtitle == nil)
    }

    @Test func theContextLineNamesTheMysteriesAndTheirDays() {
        let line = page(summary(name: "A", category: "sorrowful")).contextLine
        #expect(line?.hasPrefix("Sorrowful Mysteries  ·  ") == true)
        #expect(page(summary(name: "A", category: "unknown")).contextLine == nil)
    }

    // MARK: What it walks through

    @Test func beforeLoadingTheMysteriesAreListedByName() {
        let titles = page(summary(name: "A", category: "seven_sorrows")).entryTitles
        #expect(titles == MysteryData.mysteries(for: .sevenSorrows).map(\.name))
        #expect(titles.count == 7)
    }

    @Test func loadedTheMeditationsOwnTitlesStand() {
        let annunciation = MysteryData.mysteries(for: .joyful)[0]
        let set = fullSet([
            Meditation(id: 1, title: "Mary's Fiat", content: "…", author: nil, source: nil, audioUrl: nil, mystery: annunciation),
            Meditation(id: 2, title: nil, content: "…", author: nil, source: nil, audioUrl: nil, mystery: MysteryData.mysteries(for: .joyful)[1])
        ])
        #expect(page(summary(name: "A"), set: set).entryTitles == ["Mary's Fiat", "The Visitation"])
    }

    @Test func theOpeningIsTheFirstMeditation() {
        let annunciation = MysteryData.mysteries(for: .joyful)[0]
        let vm = page(summary(name: "A"), set: fullSet([
            Meditation(id: 1, title: nil, content: "Consider the Angel…", author: nil, source: nil, audioUrl: nil, mystery: annunciation)
        ]))
        #expect(vm.previewText == "Consider the Angel…")
        #expect(vm.previewSubject == "The Annunciation")
        #expect(vm.hasMeditations)
    }

    @Test func beforeLoadingTheOpeningIsTheFirstMysterysPlace() {
        let vm = page(summary(name: "A"))
        #expect(vm.previewText == nil)
        #expect(vm.previewSubject == "The First Joyful Mystery")
        #expect(vm.hasMeditations, "unknown until loaded is not empty")
    }

    @Test func aLoadedSetWithNoMeditationsSaysSo() {
        #expect(!page(summary(name: "A"), set: fullSet([])).hasMeditations)
        #expect(page(summary(name: "A"), set: fullSet([Meditation(id: 1, title: nil, content: "  ", author: nil, source: nil, audioUrl: nil, mystery: nil)])).previewText == nil)
    }

    // MARK: Painting and pin

    @Test func thePaintingIsTheSummarysOrTheSets() {
        #expect(page(summary(name: "A", imageURL: "https://example.org/a.jpg")).artwork?.url == "https://example.org/a.jpg")
        #expect(page(summary(name: "A")).artwork == nil)
    }

    @Test func theSetIsPinnedFromItsPage() {
        let vm = page(summary(id: 12, name: "A"))
        #expect(!vm.isPinned)
        vm.togglePin()
        #expect(vm.isPinned)
        #expect(page(summary(id: 12, name: "A"), pinned: [12]).isPinned)
    }
}

@MainActor
struct HomeGridTests {

    @Test func theGridIsTheWeeksSetsThenTheSevenSorrows() {
        let home = HomeViewModel()
        let grid = home.allCategories
        #expect(grid.last == .sevenSorrows)
        #expect(grid.filter { $0 == .sevenSorrows }.count == 1)
        #expect(Set(grid.dropLast()).isSubset(of: [.joyful, .sorrowful, .glorious, .luminous]))
        #expect(grid.count == 4 || grid.count == 5, "the 2×2 on Traditional; four and a full-width chaplet on Modern")
    }

    @Test func todaysMysteriesAreOnTheGrid() {
        let home = HomeViewModel()
        #expect(home.allCategories.contains(home.todaysCategory))
    }

    @Test func theDayHasALabelAndAQuote() {
        let home = HomeViewModel()
        #expect(!home.dayLabel.isEmpty)
        #expect(RosaryQuotes.all.contains(home.currentQuote))
    }
}
