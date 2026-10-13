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
        #expect(ranked.count == PrayerBook.occasionOrders.count)
        #expect(Set(ranked) == Set(PrayerBook.occasionOrders.map { "order:\($0.id)" }))
    }

    @Test func unknownPrayersStayOffTheShelf() {
        let recents: [PrayerBookStore.RecentPrayer] = [
            .prayer("no_such_prayer"), .order("no_such_order"), .prayer("memorare"),
        ]
        let slots = ExploreShelves.prayerSlots(recents: recents)
        #expect(slots.count == ExploreShelves.prayerDefaults.count)
        #expect(slots.first == RecentShelf.Slot(item: .prayer("memorare"), isRecent: true))
        #expect(slots.filter { $0.isRecent }.count == 1)
    }

    // MARK: Explore's Chant tiles

    @Test func theChantTilesKeepTheirDefaultsUntilSomethingIsSung() {
        let fresh = ExploreShelves.chantSlots(recentIDs: [])
        #expect(fresh.map(\.item) == [.massOfTheAngels, .sets])

        // Sets of Chants gives way before the Mass of the Angels
        let one = ExploreShelves.chantSlots(recentIDs: ["adoro_te", "no_such_chant"])
        #expect(one.map(\.item) == [.chant("adoro_te"), .massOfTheAngels])

        let two = ExploreShelves.chantSlots(recentIDs: ["salve_regina_simple", "no_such_chant", "adoro_te", "salve_regina_solemn"])
        #expect(two.map(\.item) == [.chant("salve_regina_simple"), .chant("adoro_te")])
        #expect(two.allSatisfy { $0.isRecent })
    }

    @Test func aRecentChantSaysItsSettingWhereItsTitlesDoNot() {
        let simple = ChantCatalog.chant("salve_regina_simple")!
        let solemn = ChantCatalog.chant("salve_regina_solemn")!
        #expect(simple.englishTitle == solemn.englishTitle)
        #expect(ExploreShelves.recentChantNote(simple) != ExploreShelves.recentChantNote(solemn))
        #expect(ExploreShelves.recentChantNote(simple).hasPrefix("Recent"))
    }

    // MARK: The Prayer Book's recents

    private func freshBook() -> (PrayerBookStore, UserDefaults, String) {
        let suite = "RecentShelfTests.\(UUID().uuidString)"
        let stored = UserDefaults(suiteName: suite)!
        return (PrayerBookStore(defaults: stored), stored, suite)
    }

    @Test func thePrayerBookKeepsWhatWasPrayedLatestFirstEachOnce() {
        let (book, stored, suite) = freshBook()
        defer { stored.removePersistentDomain(forName: suite) }

        let memorare = PrayerBook.prayer("memorare")!
        book.notePrayed(launch: .prayer(memorare))
        book.notePrayed(launch: .order(PrayerBook.order("before_mass")!))
        book.notePrayed(launch: .prayer(memorare))
        #expect(book.recent == [.prayer("memorare"), .order("before_mass")])

        // A launch of several prayers that is no order is not one thing
        book.notePrayed(launch: PrayAlongLaunch(orderID: nil, prayerIDs: ["memorare", "angelus"], title: "Prayers"))
        #expect(book.recent.count == 2)

        for index in 0..<12 { book.notePrayed(.prayer("p\(index)")) }
        #expect(book.recent.count == PrayerBookStore.recentLimit)
        #expect(book.recent.first == .prayer("p11"))

        #expect(PrayerBookStore(defaults: stored).recent == book.recent)
    }

    @Test func theDaysHoursAreNeverKept() {
        let (book, stored, suite) = freshBook()
        defer { stored.removePersistentDomain(forName: suite) }

        for id in [PrayerBook.morningOrderID, PrayerBook.angelusOrderID, PrayerBook.nightOrderID] {
            book.notePrayed(launch: .order(PrayerBook.order(id)!))
        }
        book.notePrayed(.prayer("angelus"))
        book.notePrayed(.prayer("regina_caeli"))
        #expect(book.recent.isEmpty)
    }

    @Test func aStoredListKeepsWhatItCanRead() {
        let (_, stored, suite) = freshBook()
        defer { stored.removePersistentDomain(forName: suite) }

        stored.set(["order:visit", "prayer:", "nonsense", "hymn:te_deum", ":memorare", "prayer:memorare"],
                   forKey: "prayerBook.recent")
        #expect(PrayerBookStore(defaults: stored).recent == [.order("visit"), .prayer("memorare")])
        #expect(PrayerBookStore.RecentPrayer(stored: "prayer:a:b") == .prayer("a:b"))
    }
}
