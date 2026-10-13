//
//  BookPrayerSnapshotTests.swift
//  appTests
//
//  A prayer's own page, its holy card, on a Prayer Book store of the
//  test's own, so nothing the simulator has learned shows through: a
//  prayer with a chant and the order it is said in, the card's end with
//  its place in the topic, a litany's end, a card part way through its
//  deal, a prayer learned by heart with the ribbon's words at the head of
//  the card, the app's largest text, and a prayer that cannot be found. Drawn without the
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

    /// The card dealt a third of the way toward the next prayer: leaning
    /// as it goes, the next card rising beneath it
    @Test func dealingToTheNext() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_holy_queen", store: try store("deal"), turnedBy: -120),
            named: "prayer-page-dealing"
        )
    }

    /// Opened from Before Confession's third prayer: the card names the
    /// order and its place in it, not the prayer's own topic
    @Test func openedFromAnOrder() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let id = order.prayerIDs(Date())[2]
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: id, set: .order(order.id, at: 2), store: try store("order")),
            named: "prayer-page-from-order"
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
