//
//  MeditationPickerTests.swift
//  Lumen Viae Tests
//
//  The mysteries' page's shelf of meditation sets: the filter's labels
//  as the API sends them, in first-seen order; a choice of labels
//  narrowing to sets that carry all of them; pinned sets lifted above
//  the rest; the rest grouped by their first label, a set without one
//  under More; and the shelf loaded from the server, with the bundled
//  Luminous set standing after it even when the server cannot be had.
//

import Foundation
import Testing
@testable import app

@MainActor
struct MeditationPickerTests {

    private func summary(_ id: Int, _ labels: [String]?) -> MeditationSetSummary {
        var json: [String: Any] = ["id": id, "name": "Set \(id)", "category": "joyful"]
        if let labels { json["labels"] = labels }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(MeditationSetSummary.self, from: data)
    }

    private func picker(_ sets: [MeditationSetSummary], pinned: Set<Int> = []) -> MeditationSelectionViewModel {
        MeditationSelectionViewModel(
            category: .joyful,
            apiService: APIService(session: StubProtocol.session),
            favorites: FavoritesService(previewFavorites: pinned),
            preloadedSets: sets
        )
    }

    private var shelf: [MeditationSetSummary] {
        [
            summary(1, ["Saints", "Considerations"]),
            summary(2, ["Scriptural"]),
            summary(3, ["Saints", "Contemplative"]),
            summary(4, nil),
            summary(5, ["Considerations", "Saints"])
        ]
    }

    @Test func theLabelsAreTheAPIsInFirstSeenOrder() {
        #expect(picker(shelf).allLabels == ["Saints", "Considerations", "Scriptural", "Contemplative"])
        #expect(!picker([summary(1, nil)]).hasLabels)
    }

    @Test func choosingLabelsNarrowsToSetsCarryingAllOfThem() {
        let vm = picker(shelf)
        vm.toggleLabel("Saints")
        #expect(vm.filteredSets.map(\.id) == [1, 3, 5])
        vm.toggleLabel("Considerations")
        #expect(vm.filteredSets.map(\.id) == [1, 5])
        #expect(vm.visibleSetCount == 2 && vm.totalSetCount == 5)
        vm.toggleLabel("Saints")
        #expect(vm.filteredSets.map(\.id) == [1, 5], "a second tap lets the label go")
        vm.clearLabels()
        #expect(!vm.isNarrowed)
        #expect(vm.filteredSets.count == 5)
    }

    @Test func aChoiceNoSetMeetsSaysSo() {
        let vm = picker(shelf)
        vm.toggleLabel("Scriptural")
        vm.toggleLabel("Saints")
        #expect(vm.cameUpEmpty)
        #expect(vm.sections.isEmpty)
    }

    @Test func unnarrowedTheShelfIsGroupedByFirstLabel() {
        let sections = picker(shelf).sections
        #expect(sections.map(\.title) == ["Saints", "Scriptural", "Considerations", "More"])
        #expect(sections.map { $0.sets.map(\.id) } == [[1, 3], [2], [5], [4]])
    }

    @Test func pinnedSetsStandAboveAndLeaveTheirGroups() {
        let vm = picker(shelf, pinned: [3, 4])
        #expect(vm.pinnedSets.map(\.id) == [3, 4])
        let grouped = vm.sections.flatMap { $0.sets.map(\.id) }
        #expect(!grouped.contains(3) && !grouped.contains(4))
        #expect(vm.sections.map(\.title) == ["Saints", "Scriptural", "Considerations"], "More is gone with its one set")
    }

    @Test func pinningIsATap() {
        let vm = picker(shelf)
        let set = shelf[1]
        #expect(!vm.isPinned(set))
        vm.togglePin(set)
        #expect(vm.isPinned(set))
        #expect(vm.pinnedSets.map(\.id) == [2])
    }

    @Test func narrowedTheShelfIsOneFlatList() {
        let vm = picker(shelf)
        vm.toggleLabel("Saints")
        #expect(vm.sections.count == 1)
        #expect(vm.sections.first?.title == nil)
    }

    @Test func aShelfWithNoLabelsIsOneUntitledList() {
        let vm = picker([summary(1, nil), summary(2, nil)])
        #expect(vm.sections.map(\.title) == [nil])
        #expect(vm.sections.first?.sets.count == 2)
    }
}

// Loading reaches the network, so it shares the stubbed network's one
// serialized suite rather than racing its other tests for the handler
extension APIClientTests {

    @Test func thePickerLoadsItsCategorysSets() async {
        StubProtocol.reset { _ in .init(body: #"{"data": [{"id": 8, "name": "Liguori", "category": "joyful", "description": null, "labels": ["Saints"]}]}"#) }
        let vm = MeditationSelectionViewModel(
            category: .joyful,
            apiService: APIService(session: StubProtocol.session),
            favorites: FavoritesService(previewFavorites: [])
        )
        await vm.loadMeditationSets()
        #expect(vm.meditationSets.map(\.id) == [8])
        #expect(vm.errorMessage == nil)
        #expect(!vm.isLoading)
        #expect(StubProtocol.requests.first?.url?.query == "category=joyful")
    }

    @Test func aShelfAlreadyLoadedIsNotAskedForAgain() async {
        StubProtocol.reset { _ in .init(body: #"{"data": []}"#) }
        let vm = MeditationSelectionViewModel(
            category: .joyful,
            apiService: APIService(session: StubProtocol.session),
            favorites: FavoritesService(previewFavorites: []),
            preloadedSets: [try! JSONDecoder().decode(MeditationSetSummary.self, from: Data(#"{"id": 1, "name": "A", "category": "joyful"}"#.utf8))]
        )
        await vm.loadMeditationSets()
        #expect(StubProtocol.requests.isEmpty)
    }

    @Test func theBundledLuminousSetStandsEvenWithNoServer() async {
        StubProtocol.reset { _ in .init(status: 503) }
        let vm = MeditationSelectionViewModel(
            category: .luminous,
            apiService: APIService(session: StubProtocol.session),
            favorites: FavoritesService(previewFavorites: [])
        )
        await vm.loadMeditationSets()
        #expect(vm.meditationSets.last?.id == LuminousMeditationData.summary.id)
        #expect(vm.errorMessage == nil, "a shelf with a set on it is no failure")
    }
}
