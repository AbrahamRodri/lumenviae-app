//
//  ChantViewSnapshotTests.swift
//  appTests
//
//  A chant's own page, its Now Playing, drawn with the player at rest on
//  a shelf of the test's own, so nothing the simulator has learned or
//  kept shows through: the top of the page, its foot, a chant under way
//  and a favourite, one learned, a chant with no prayer and no other
//  setting, the page for a chant that cannot be found, and the top at
//  the app's largest text. The bar's Back and ⋯ are not drawn here.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Chant page snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct ChantViewSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
        // The score is read from disk off the main actor; read once, it
        // is drawn at once, so the window is never caught empty
        for id in ["salve_regina_simple", "quem_terra"] {
            for part in ChantCatalog.chant(id)?.score ?? [] {
                _ = await ChantScoreStore.shared.load(part.file)
            }
        }
    }

    private func shelf(_ name: String) throws -> ChantShelfStore {
        let defaults = try #require(UserDefaults(suiteName: "ChantViewSnapshotTests.\(name)"))
        defaults.removePersistentDomain(forName: "ChantViewSnapshotTests.\(name)")
        return ChantShelfStore(defaults: defaults)
    }

    /// Drawn without its NavigationStack, as an order's page is: in the
    /// test's hosting controller a stack under this page's painted head
    /// drew nothing below the bar, so the bar's Back and ⋯ are not drawn
    private func page(_ chantID: String, shelf: ChantShelfStore, atFoot: Bool = false) -> some View {
        ChantView(chantID: chantID, shelf: shelf, opensAtFoot: atFoot)
    }

    @Test func top() throws {
        ScreenSnapshot.assertScreen(page("salve_regina_simple", shelf: try shelf("top")), named: "chant-page-top")
    }

    @Test func foot() throws {
        ScreenSnapshot.assertScreen(
            page("salve_regina_simple", shelf: try shelf("foot"), atFoot: true),
            named: "chant-page-foot"
        )
    }

    @Test func underWayAndFavourite() throws {
        let shelf = try shelf("underWay")
        shelf.setStep(.readAlong, for: "salve_regina_simple")
        shelf.toggleFavorite("salve_regina_simple")
        ScreenSnapshot.assertScreen(
            page("salve_regina_simple", shelf: shelf, atFoot: true),
            named: "chant-page-under-way-foot"
        )
        ScreenSnapshot.assertScreen(page("salve_regina_simple", shelf: shelf), named: "chant-page-favourite-top")
    }

    @Test func learned() throws {
        let shelf = try shelf("learned")
        shelf.markLearned("salve_regina_simple")
        ScreenSnapshot.assertScreen(
            page("salve_regina_simple", shelf: shelf, atFoot: true),
            named: "chant-page-learned-foot"
        )
    }

    @Test func noPrayerNoOtherSetting() throws {
        ScreenSnapshot.assertScreen(
            page("quem_terra", shelf: try shelf("bare"), atFoot: true),
            named: "chant-page-no-doors-foot"
        )
    }

    @Test func notFound() throws {
        ScreenSnapshot.assertScreen(page("no_such_chant", shelf: try shelf("missing")), named: "chant-page-not-found")
    }

    @Test func largestText() throws {
        ScreenSnapshot.assertScreen(
            page("salve_regina_simple", shelf: try shelf("large"))
                .dynamicTypeSize(DynamicTypeSize.appMaximum),
            named: "chant-page-top-xlarge"
        )
    }
}
