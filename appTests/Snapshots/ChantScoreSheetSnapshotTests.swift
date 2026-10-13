//
//  ChantScoreSheetSnapshotTests.swift
//  appTests
//
//  The score sheet as its three doors open it: with the floating player
//  (a chant's page) and without (a practice, a consecration day), for a
//  short hymn that once floated down the sheet and for Salve Regina,
//  whose three parts keep their captions. The player is at rest, holding
//  no chant, so the thread stands at its start beside the chant's length.
//  The sheet is drawn full screen rather than presented, so the status
//  bar's dark band stands above the painting and there is no drag
//  indicator; both are the presentation's, not the sheet's.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Chant score sheet snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantScoreSheetSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
        // The engravings read from disk ahead, so each is drawn at once
        // rather than faded in after the snapshot is taken
        for id in ["ut_queant_laxis", "salve_regina_simple"] {
            for part in ChantCatalog.chant(id)?.score ?? [] {
                _ = await ChantScoreStore.shared.load(part.file)
            }
        }
    }

    @Test func shortChantWithPlayer() throws {
        let chant = try #require(ChantCatalog.chant("ut_queant_laxis"))
        ScreenSnapshot.assertScreen(ChantScoreSheet(chant: chant), named: "score-sheet-short-player")
    }

    @Test func shortChantWithoutPlayer() throws {
        let chant = try #require(ChantCatalog.chant("ut_queant_laxis"))
        ScreenSnapshot.assertScreen(
            ChantScoreSheet(chant: chant, showsTransport: false),
            named: "score-sheet-short-alone"
        )
    }

    @Test func partsWithPlayer() throws {
        let chant = try #require(ChantCatalog.chant("salve_regina_simple"))
        ScreenSnapshot.assertScreen(ChantScoreSheet(chant: chant), named: "score-sheet-parts-player")
    }

    @Test func partsWithoutPlayer() throws {
        let chant = try #require(ChantCatalog.chant("salve_regina_simple"))
        ScreenSnapshot.assertScreen(
            ChantScoreSheet(chant: chant, showsTransport: false),
            named: "score-sheet-parts-alone"
        )
    }
}
