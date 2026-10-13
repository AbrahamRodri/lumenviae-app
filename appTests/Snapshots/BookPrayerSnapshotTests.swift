//
//  BookPrayerSnapshotTests.swift
//  appTests
//
//  A prayer's own page, on a Prayer Book store of the test's own, so
//  nothing the simulator has learned shows through: a prayer with a
//  chant and the order it is said in, its end with the steps along its
//  topic, a litany's end clear of the foot, a prayer learned by heart
//  with the ribbon's words in the origin's place, the app's largest
//  text, and a prayer that cannot be found. Drawn without the
//  NavigationStack, as an order's page is, so the bar's Back, language
//  and ribbon are not drawn here.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Prayer page snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct BookPrayerSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    private func store(_ name: String) throws -> PrayerBookStore {
        let suite = "BookPrayerSnapshotTests.\(name)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let store = PrayerBookStore(defaults: defaults)
        // Prayed in silence, so the foot names no voice
        store.praysAloud = false
        return store
    }

    @Test func chantAndOrder() throws {
        let store = try store("chant")
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_holy_queen", store: store),
            named: "prayer-page-chant-top"
        )
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_holy_queen", store: store, opensAtEnd: true),
            named: "prayer-page-chant-end"
        )
    }

    /// The litany's last invocations clear the fixed foot
    @Test func longPrayerEnd() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "litany_loreto", store: try store("long"), opensAtEnd: true),
            named: "prayer-page-litany-end"
        )
    }

    @Test func learnedWithRibbonNote() throws {
        let store = try store("learned")
        store.setByHeart("hail_mary", true)
        ScreenSnapshot.assertScreen(
            // The longest thing the ribbon says, which takes a second line
            BookPrayerView(
                prayerID: "hail_mary",
                store: store,
                showingNote: "Saved. Find it under Saved on the Prayers tab."
            ),
            named: "prayer-page-learned-note"
        )
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_mary", store: store),
            named: "prayer-page-learned"
        )
    }

    @Test func largestText() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "sub_tuum", store: try store("large"))
                .dynamicTypeSize(DynamicTypeSize.appMaximum),
            named: "prayer-page-xlarge"
        )
    }

    @Test func notFound() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "no_such_prayer", store: try store("missing")),
            named: "prayer-page-not-found"
        )
    }
}
