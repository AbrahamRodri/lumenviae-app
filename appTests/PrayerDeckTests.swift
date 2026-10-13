//
//  PrayerDeckTests.swift
//  appTests
//
//  A prayer's page deals through the set it was opened from: an order's
//  prayers from an order's page, a topic's from a topic's page, and the
//  prayer's own topic from any other door. And the dots under a card
//  show a long set 24 at a time, held inside it at either end.
//

import Foundation
import Testing

@testable import app

struct PrayerDeckTests {

    private let day = Date(timeIntervalSince1970: 1_791_900_000)

    @Test func aPrayerOpenedFromAnOrderDealsThroughTheOrder() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let ids = order.prayerIDs(day)
        let deck = PrayerDeck.of(ids[2], in: .order(order.id, at: 2), on: day)

        #expect(deck.ids == ids)
        #expect(deck.start == 2)
        #expect(deck.name == "BEFORE CONFESSION")
        #expect(deck.doorName == "Before Confession")
        // Back already goes to the order, so the All door goes back too
        #expect(deck.topicToOpen == nil)
    }

    @Test func aPrayerOpensAtThePlaceTapped() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let ids = order.prayerIDs(day)
        let last = ids.count - 1
        #expect(PrayerDeck.of(ids[last], in: .order(order.id, at: last), on: day).start == last)
    }

    @Test func aPlaceThatNoLongerHoldsThePrayerFallsBackToItsFirst() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let ids = order.prayerIDs(day)
        let deck = PrayerDeck.of(ids[1], in: .order(order.id, at: 99), on: day)
        #expect(deck.start == 1)
    }

    @Test func aPrayerOpenedFromATopicDealsThroughTheTopic() throws {
        let mass = try #require(PrayerBook.chapter("mass"))
        let id = mass.prayerIDs[1]
        let deck = PrayerDeck.of(id, in: .topic(mass.id), on: day)

        #expect(deck.ids == mass.prayerIDs)
        #expect(deck.start == 1)
        #expect(deck.topicToOpen == nil)
    }

    @Test func aPrayerOpenedFromElsewhereDealsThroughItsOwnTopic() throws {
        let home = try #require(PrayerBook.homeChapter(of: "hail_holy_queen"))
        let deck = PrayerDeck.of("hail_holy_queen", in: nil, on: day)

        #expect(deck.ids == home.prayerIDs)
        #expect(deck.start == home.prayerIDs.firstIndex(of: "hail_holy_queen"))
        #expect(deck.name == home.topic.uppercased())
        // Opened from elsewhere, the All door opens the topic
        #expect(deck.topicToOpen == home.id)
    }

    @Test func aDragDealsTheWayItWentWhenFarEnoughOrFlung() {
        // A third of the width, either way
        #expect(DealDirection.of(dx: -120, flung: -120, width: 337, hasNext: true, hasPrevious: true) == .next)
        #expect(DealDirection.of(dx: 120, flung: 120, width: 337, hasNext: true, hasPrevious: true) == .previous)
        // Short, but flung on the same way
        #expect(DealDirection.of(dx: -40, flung: -260, width: 337, hasNext: true, hasPrevious: true) == .next)
    }

    @Test func aDragComesBackWhenShortFlungBackOrTowardNoCard() {
        // Short and not flung
        #expect(DealDirection.of(dx: -60, flung: -80, width: 337, hasNext: true, hasPrevious: true) == nil)
        // Dragged left, flicked back right
        #expect(DealDirection.of(dx: -60, flung: 300, width: 337, hasNext: true, hasPrevious: true) == nil)
        // Far enough, but there is no card that way
        #expect(DealDirection.of(dx: -200, flung: -200, width: 337, hasNext: false, hasPrevious: true) == nil)
        #expect(DealDirection.of(dx: 200, flung: 200, width: 337, hasNext: true, hasPrevious: false) == nil)
        #expect(DealDirection.of(dx: 0, flung: 400, width: 337, hasNext: true, hasPrevious: true) == nil)
    }

    @Test func theDotsShowASmallSetWhole() {
        #expect(PlaceDots.visibleRange(count: 5, current: 2) == 0...4)
        #expect(PlaceDots.visibleRange(count: 24, current: 23) == 0...23)
        #expect(PlaceDots.visibleRange(count: 1, current: 0) == 0...0)
    }

    @Test func theDotsShowALongSet24AroundThisOne() {
        #expect(PlaceDots.visibleRange(count: 32, current: 0) == 0...23)
        #expect(PlaceDots.visibleRange(count: 32, current: 16) == 4...27)
        #expect(PlaceDots.visibleRange(count: 32, current: 31) == 8...31)
    }
}
