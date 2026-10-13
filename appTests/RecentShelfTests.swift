//
//  RecentShelfTests.swift
//  Lumen Viae Tests
//
//  Explore's shelves start from their defaults and take in what the
//  reader uses: the least important default gives way first, the most
//  important last, the reader's own lead marked recent, and the shelf
//  never grows or repeats. Also the Prayers shelf's own ranking, and the
//  recents the Prayer Book keeps for it.
//

import Foundation
import Testing

@testable import app

@MainActor
struct RecentShelfTests {

    private let defaults = ["mass", "confession", "communion", "meals"]

    private func items(_ slots: [RecentShelf.Slot<String>]) -> [String] { slots.map(\.item) }

    @Test func aFreshShelfIsItsDefaults() {
        let slots = RecentShelf.fill(defaults: defaults, recents: [])
        #expect(items(slots) == defaults)
        #expect(slots.allSatisfy { !$0.isRecent })
    }

    @Test func eachRecentPushesOutTheLeastImportantDefault() {
        let one = RecentShelf.fill(defaults: defaults, recents: ["memorare"])
        #expect(items(one) == ["memorare", "mass", "confession", "communion"])
        #expect(one.first?.isRecent == true)

        let two = RecentShelf.fill(defaults: defaults, recents: ["loreto", "memorare"])
        #expect(items(two) == ["loreto", "memorare", "mass", "confession"])
    }

    @Test func theMostImportantDefaultGoesLast() {
        let three = RecentShelf.fill(defaults: defaults, recents: ["a", "b", "c"])
        #expect(items(three) == ["a", "b", "c", "mass"])

        let full = RecentShelf.fill(defaults: defaults, recents: ["a", "b", "c", "d", "e"])
        #expect(items(full) == ["a", "b", "c", "d"])
        #expect(full.allSatisfy { $0.isRecent })
    }

    @Test func aDefaultUsedLatelyLeadsWithoutRepeating() {
        let slots = RecentShelf.fill(defaults: defaults, recents: ["communion", "memorare", "communion"])
        #expect(items(slots) == ["communion", "memorare", "mass", "confession"])
        #expect(slots.filter(\.isRecent).map(\.item) == ["communion", "memorare"])
    }

    // MARK: Explore's Prayers shelf

    @Test func beforeMassLeadsTheDefaults() {
        let ranked = ExploreShelves.prayerDefaults.map(\.stored)
        #expect(ranked.first == "order:before_mass")
        #expect(Set(ranked) == Set(PrayerBook.occasionOrders.map { "order:\($0.id)" }))
    }

    @Test func theDaysHoursAndUnknownPrayersStayOffTheShelf() {
        let recents: [PrayerBookStore.RecentPrayer] = [
            .order(PrayerBook.nightOrderID), .prayer("no_such_prayer"), .prayer("memorare"),
        ]
        let slots = ExploreShelves.prayerSlots(recents: recents)
        #expect(slots.count == ExploreShelves.prayerDefaults.count)
        #expect(slots.first == RecentShelf.Slot(item: .prayer("memorare"), isRecent: true))
        #expect(!slots.contains { $0.item == .order(PrayerBook.nightOrderID) })
    }

    // MARK: The Prayer Book's recents

    @Test func thePrayerBookKeepsWhatWasPrayedLatestFirstEachOnce() {
        let suite = "RecentShelfTests.\(UUID().uuidString)"
        let stored = UserDefaults(suiteName: suite)!
        defer { stored.removePersistentDomain(forName: suite) }

        let book = PrayerBookStore(defaults: stored)
        let memorare = PrayerBook.prayer("memorare")!
        book.notePrayed(.prayer(memorare))
        book.notePrayed(.order(PrayerBook.order("before_mass")!))
        book.notePrayed(.prayer(memorare))
        #expect(book.recent == [.prayer("memorare"), .order("before_mass")])

        // A launch of several prayers that is no order is not one thing
        book.notePrayed(PrayAlongLaunch(orderID: nil, prayerIDs: ["memorare", "angelus"], title: "Prayers"))
        #expect(book.recent.count == 2)

        for index in 0..<12 { book.notePrayed(.prayer("p\(index)")) }
        #expect(book.recent.count == PrayerBookStore.recentLimit)
        #expect(book.recent.first == .prayer("p11"))

        #expect(PrayerBookStore(defaults: stored).recent == book.recent)
    }
}
