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

    /// The day the pages are drawn on, as the main screens' are, so which
    /// orders say a prayer never turns with the season the suite runs in
    private let day = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 15))!

    @Test func chantAndOrder() throws {
        let store = try store("chant")
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_holy_queen", store: store, date: day),
            named: "prayer-page-chant-top"
        )
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_holy_queen", store: store, date: day, opensAtEnd: true),
            named: "prayer-page-chant-end"
        )
    }

    /// The litany's last invocations clear the fixed foot
    @Test func longPrayerEnd() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "litany_loreto", store: try store("long"), date: day, opensAtEnd: true),
            named: "prayer-page-litany-end"
        )
    }

    /// The card dealt a third of the way toward the next prayer: leaning
    /// as it goes, the next card rising beneath it
    @Test func dealingToTheNext() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_holy_queen", store: try store("deal"), date: day, turnedBy: -120),
            named: "prayer-page-dealing"
        )
    }

    /// Opened from Before Confession's third prayer: the card names the
    /// order and its place in it, not the prayer's own topic
    @Test func openedFromAnOrder() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let id = order.prayerIDs(day)[2]
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: id, set: .order(order.id, at: 2), store: try store("order"), date: day),
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
                date: day,
                showingNote: "Saved. Find it under Saved on the Prayers tab."
            ),
            named: "prayer-page-learned-note"
        )
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "hail_mary", store: store, date: day),
            named: "prayer-page-learned"
        )
    }

    @Test func largestText() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "sub_tuum", store: try store("large"), date: day)
                .dynamicTypeSize(DynamicTypeSize.appMaximum),
            named: "prayer-page-xlarge"
        )
    }

    @Test func notFound() throws {
        ScreenSnapshot.assertScreen(
            BookPrayerView(prayerID: "no_such_prayer", store: try store("missing"), date: day),
            named: "prayer-page-not-found"
        )
    }
}
