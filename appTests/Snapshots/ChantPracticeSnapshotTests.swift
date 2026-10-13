//
//  ChantPracticeSnapshotTests.swift
//  appTests
//
//  The chant practice's path, where it opens: the chant's painting and
//  the four steps, drawn for a chant not yet begun on a shelf of its own,
//  so nothing the simulator has practised shows through. The singing
//  screen reads the player and is not drawn here.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Chant practice snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantPracticeSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    @Test func practicePath() throws {
        let chant = try #require(ChantCatalog.chant("kyrie_de_angelis"))
        let defaults = try #require(UserDefaults(suiteName: "ChantPracticeSnapshotTests"))
        defaults.removePersistentDomain(forName: "ChantPracticeSnapshotTests")

        let view = ChantPracticeView(chant: chant, shelf: ChantShelfStore(defaults: defaults))
        ScreenSnapshot.assertScreen(view, named: "chant-practice-path")
    }
}
