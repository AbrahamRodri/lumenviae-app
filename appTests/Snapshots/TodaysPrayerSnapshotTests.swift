//
//  TodaysPrayerSnapshotTests.swift
//  appTests
//
//  Home's Today's Prayer section on the page gradient, in its states:
//  no consecration begun, a consecration under way with today's day
//  prayed, the hour's prayers prayed, and the app's largest text. On a
//  fixed morning with a known feast, a consecration store in memory and
//  a Prayer Book store of the test's own, so nothing the simulator has
//  prayed shows through.
//

import SwiftData
import SwiftUI
import Testing

@testable import app

@Suite(
    "Today's Prayer snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct TodaysPrayerSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    /// Tuesday 13 October 2026, half past nine: the hour of Morning
    /// Prayers and of Terce
    private let morning: Date = {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 10
        parts.day = 13
        parts.hour = 9
        parts.minute = 30
        return Calendar.current.date(from: parts)!
    }()

    /// The feast of the day as the missal serves it
    private let today = TodayInChurch(
        proper: MissalProper(
            info: MissalInfo(
                id: nil, title: "St. Edward", description: nil, date: nil, rank: 3, colors: ["w"],
                tempora: nil, tags: nil, commemorations: nil
            ),
            sections: []
        )
    )

    private func store(_ name: String) throws -> PrayerBookStore {
        let suite = "TodaysPrayerSnapshotTests.\(name)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return PrayerBookStore(defaults: defaults)
    }

    /// An in-memory store, holding a consecration begun eleven days ago
    /// (so today is Day 12) when asked for one
    private func consecrations(dayTwelvePrayed: Bool?) throws -> ModelContainer {
        let container = try ModelContainer(
            for: ConsecrationProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        if let dayTwelvePrayed {
            let start = Calendar.current.date(byAdding: .day, value: -11, to: Date())!
            let progress = ConsecrationProgress(startDate: start)
            if dayTwelvePrayed { progress.completeDay(12) }
            container.mainContext.insert(progress)
            try container.mainContext.save()
        }
        return container
    }

    private func screen(store: PrayerBookStore, container: ModelContainer) -> some View {
        ZStack(alignment: .top) {
            AppColors.appGradient.ignoresSafeArea()

            TodaysPrayerSection(today: today, store: store, now: morning)
                .padding(.horizontal, 20)
                .padding(.top, 24)
        }
        .modelContainer(container)
    }

    @Test func notBegun() throws {
        ScreenSnapshot.assertScreen(
            screen(store: try store("notBegun"), container: try consecrations(dayTwelvePrayed: nil)),
            named: "todays-prayer-not-begun"
        )
    }

    @Test func consecrationDayPrayed() throws {
        ScreenSnapshot.assertScreen(
            screen(store: try store("dayPrayed"), container: try consecrations(dayTwelvePrayed: true)),
            named: "todays-prayer-day-prayed"
        )
    }

    @Test func hourPrayed() throws {
        let store = try store("hourPrayed")
        store.markOffered(PrayerBook.morningOrderID, on: morning)
        ScreenSnapshot.assertScreen(
            screen(store: store, container: try consecrations(dayTwelvePrayed: false)),
            named: "todays-prayer-hour-prayed"
        )
    }

    /// The app's largest text: names take a second line, nothing is cut
    @Test func largestText() throws {
        ScreenSnapshot.assertScreen(
            screen(store: try store("largest"), container: try consecrations(dayTwelvePrayed: true))
                .dynamicTypeSize(DynamicTypeSize.appMaximum),
            named: "todays-prayer-largest-text"
        )
    }
}
