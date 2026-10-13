//
//  PrayAlongSnapshotTests.swift
//  appTests
//
//  The pray-along page in silence, on a book of the test's own that has
//  been told to keep silent, so it neither asks its question nor speaks:
//  an order part-way through, with NEXT at its foot; a prayer opened
//  alone, whose only prayer is its last, with AMEN; and the Angelus, an
//  order of one prayer bearing its name, whose head says PRAYERS rather
//  than the title beneath it again. Aloud the page reads
//  the player and the network, and is not drawn here.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Pray along snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct PrayAlongSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    private func silentStore(_ suite: String) throws -> PrayerBookStore {
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let store = PrayerBookStore(defaults: defaults)
        store.chooseAloud(false)
        return store
    }

    @Test func orderInSilence() throws {
        let morning = try #require(PrayerBook.order(PrayerBook.morningOrderID))
        var launch = PrayAlongLaunch.order(morning)
        launch.startIndex = 5
        let view = PrayAlongView(launch: launch, store: try silentStore("PrayAlongSnapshotTests.order"))
        ScreenSnapshot.assertScreen(view, named: "pray-along-order")
    }

    /// An order of one prayer bearing its name: the head says PRAYERS,
    /// never THE ANGELUS over The Angelus. The day is fixed outside
    /// Eastertide, so the order is the Angelus and not the Queen of Heaven.
    @Test func angelusInSilence() throws {
        let angelus = try #require(PrayerBook.order(PrayerBook.angelusOrderID))
        let day = try #require(DateComponents(calendar: .current, year: 2026, month: 10, day: 12).date)
        let view = PrayAlongView(
            launch: .order(angelus, on: day),
            store: try silentStore("PrayAlongSnapshotTests.angelus")
        )
        ScreenSnapshot.assertScreen(view, named: "pray-along-angelus")
    }

    @Test func singlePrayerInSilence() throws {
        let hailMary = try #require(PrayerBook.prayer("hail_mary"))
        let view = PrayAlongView(launch: .prayer(hailMary), store: try silentStore("PrayAlongSnapshotTests.single"))
        ScreenSnapshot.assertScreen(view, named: "pray-along-single")
    }
}
