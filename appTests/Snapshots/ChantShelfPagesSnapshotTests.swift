//
//  ChantShelfPagesSnapshotTests.swift
//  appTests
//
//  The pages SEE ALL opens: All Chants' painted contents, a shelf whose
//  chants hang paintings of their own (Songs to Mary), a numbered shelf
//  (the Mass of the Angels), a topic with its strip of parts (the
//  seasons), and the sung sets with two of the reader's own.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Chant shelf pages snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantShelfPagesSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    private func browse(_ scope: ChantBrowseScope) -> some View {
        NavigationStack {
            ChantBrowsePage(scope: scope)
        }
    }

    @Test func allChants() {
        ScreenSnapshot.assertScreen(browse(.all), named: "chant-shelf-all")
    }

    @Test func songsToMary() {
        ScreenSnapshot.assertScreen(browse(.songsToMary), named: "chant-shelf-songs-to-mary")
    }

    @Test func massOfTheAngels() {
        ScreenSnapshot.assertScreen(browse(.massOfTheAngels), named: "chant-shelf-mass-of-the-angels")
    }

    @Test func aTopicWithParts() {
        ScreenSnapshot.assertScreen(browse(.group("seasons")), named: "chant-shelf-seasons")
    }

    @Test func sungSets() {
        let suite = "ChantShelfPagesSnapshotTests.sets"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let shelf = ChantShelfStore(defaults: defaults)
        let hour = shelf.newSet(named: "Thursday holy hour", with: "o_salutaris")
        shelf.addChant("tantum_ergo", to: hour.id)
        _ = shelf.newSet(named: "Night prayer")
        let view = NavigationStack { ChantSetsPage(shelf: shelf) }
        ScreenSnapshot.assertScreen(view, named: "chant-shelf-sung-sets")
    }
}
