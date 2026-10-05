//
//  PrayerBookStoreTests.swift
//  Lumen Viae Tests
//
//  What the Prayers tab keeps for the reader, on a defaults suite of
//  its own so nothing of theirs is touched: prayers saved with the
//  ribbon (newest first, a second tap letting go), prayers learned by
//  heart, an order prayed counted for its prayer day — the evening's
//  Night Prayers said after midnight still the evening's — and all of
//  it there again when the app next opens.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayerBookStoreTests {

    private let suiteName = "PrayerBookStoreTests.\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    private func store() -> PrayerBookStore { PrayerBookStore(defaults: defaults) }

    private var someIDs: [String] {
        Array(PrayerBook.prayers.keys.sorted().prefix(3))
    }

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: Saved

    @Test func aRibbonSavesAPrayerNewestFirst() {
        let book = store()
        let ids = someIDs
        book.toggleRibbon(ids[0])
        book.toggleRibbon(ids[1])
        #expect(book.ribbons == [ids[1], ids[0]])
        #expect(book.isKept(ids[0]))
        #expect(book.keptPrayers.map(\.id) == [ids[1], ids[0]])
    }

    @Test func aSecondTapLetsTheRibbonGo() {
        let book = store()
        let id = someIDs[0]
        book.toggleRibbon(id)
        book.toggleRibbon(id)
        #expect(!book.isKept(id))
        #expect(book.ribbons.isEmpty)
    }

    @Test func aSavedPrayerTheBookNoLongerHoldsIsPassedOver() {
        let book = store()
        book.toggleRibbon("a_prayer_since_withdrawn")
        book.toggleRibbon(someIDs[0])
        #expect(book.keptPrayers.map(\.id) == [someIDs[0]])
    }

    // MARK: Learned by heart

    @Test func aPrayerIsLearnedAndUnlearned() {
        let book = store()
        let id = someIDs[2]
        #expect(!book.isByHeart(id))
        book.setByHeart(id, true)
        book.setByHeart(id, true)
        #expect(book.isByHeart(id))
        #expect(book.byHeart.count == 1)
        book.setByHeart(id, false)
        #expect(!book.isByHeart(id))
    }

    // MARK: Prayed

    @Test func anOrderPrayedCountsForItsPrayerDay() {
        let book = store()
        book.markOffered(PrayerBook.morningOrderID, on: at(2026, 10, 4, 7))
        #expect(book.wasOffered(PrayerBook.morningOrderID, on: at(2026, 10, 4, 21)))
        #expect(!book.wasOffered(PrayerBook.morningOrderID, on: at(2026, 10, 5, 7)), "the next day asks again")
        #expect(!book.wasOffered(PrayerBook.nightOrderID, on: at(2026, 10, 4, 21)), "one order is not another")
    }

    @Test func nightPrayersAfterMidnightAreTheEveningsOwn() {
        let book = store()
        book.markOffered(PrayerBook.nightOrderID, on: at(2026, 10, 5, 0, 30))
        #expect(book.wasOffered(PrayerBook.nightOrderID, on: at(2026, 10, 4, 22)))
        #expect(book.wasOffered(PrayerBook.nightOrderID, on: at(2026, 10, 5, 3, 59)))
        #expect(!book.wasOffered(PrayerBook.nightOrderID, on: at(2026, 10, 5, 4)), "the day turns at four")
    }

    @Test func theMomentPrayedIsKeptBesideTheDay() {
        let book = store()
        let moment = at(2026, 10, 4, 12, 5)
        #expect(book.lastOffered(PrayerBook.angelusOrderID) == nil)
        book.markOffered(PrayerBook.angelusOrderID, on: moment)
        #expect(book.lastOffered(PrayerBook.angelusOrderID) == moment)
    }

    // MARK: Kept

    @Test func everythingIsThereWhenTheAppNextOpens() {
        let first = store()
        let ids = someIDs
        first.toggleRibbon(ids[0])
        first.setByHeart(ids[1], true)
        first.markOffered(PrayerBook.morningOrderID, on: at(2026, 10, 4, 7))
        first.chooseAloud(false)

        let next = store()
        #expect(next.ribbons == [ids[0]])
        #expect(next.isByHeart(ids[1]))
        #expect(next.wasOffered(PrayerBook.morningOrderID, on: at(2026, 10, 4, 18)))
        #expect(next.lastOffered(PrayerBook.morningOrderID) == at(2026, 10, 4, 7))
        #expect(next.praysAloud == false)
        #expect(next.hasChosenAloud)
    }

    @Test func aNewReaderHasNothingSavedAndHasNotBeenAsked() {
        let book = store()
        #expect(book.ribbons.isEmpty)
        #expect(book.byHeart.isEmpty)
        #expect(book.praysAloud, "Aloud is the default shown")
        #expect(!book.hasChosenAloud, "but the book will still ask")
        #expect(!book.angelusBell)
    }
}
