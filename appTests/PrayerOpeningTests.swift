//
//  PrayerOpeningTests.swift
//  appTests
//
//  Every door to one prayer opens the pray-along screen: the prayer
//  alone, or, from an order's page, the order from the prayer tapped.
//

import Foundation
import Testing

@testable import app

struct PrayerOpeningTests {

    private let day = Date(timeIntervalSince1970: 1_791_900_000)

    /// Easter Monday, 2026: the Angelus gives way to Queen of Heaven
    private let eastertide = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 6, hour: 12))!

    @Test func aPrayerOpenedAloneIsPrayedAlone() throws {
        let launch = PrayAlongLaunch.opening("memorare", from: nil, on: day)
        #expect(launch.orderID == nil)
        #expect(launch.prayerIDs == ["memorare"])
        #expect(launch.startIndex == 0)
        #expect(launch.title == PrayerBook.prayer("memorare")?.title)
    }

    @Test func aPrayerOpenedFromATopicIsPrayedAlone() throws {
        let mass = try #require(PrayerBook.chapter("mass"))
        let id = mass.prayerIDs[1]
        let launch = PrayAlongLaunch.opening(id, from: .topic(mass.id), on: day)
        #expect(launch.orderID == nil)
        #expect(launch.prayerIDs == [id])
    }

    @Test func aPrayerOpenedFromAnOrderPraysTheOrderFromIt() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let ids = order.prayerIDs(day)
        let launch = PrayAlongLaunch.opening(ids[2], from: .order(order.id, at: 2), on: day)
        #expect(launch.orderID == order.id)
        #expect(launch.prayerIDs == ids)
        #expect(launch.startIndex == 2)
    }

    @Test func aPlaceThatNoLongerHoldsThePrayerFallsBackToItsFirst() throws {
        let order = try #require(PrayerBook.order("before_confession"))
        let ids = order.prayerIDs(day)
        #expect(PrayAlongLaunch.opening(ids[1], from: .order(order.id, at: 99), on: day).startIndex == 1)
        #expect(PrayAlongLaunch.opening(ids[2], from: .order(order.id, at: 0), on: day).startIndex == 2)
    }

    @Test func theDayReachesTheOrder() throws {
        let angelus = try #require(PrayerBook.order(PrayerBook.angelusOrderID))
        let ids = angelus.prayerIDs(eastertide)
        let at = try #require(ids.firstIndex(of: "regina_caeli"))
        let launch = PrayAlongLaunch.opening("regina_caeli", from: .order(angelus.id, at: at), on: eastertide)
        #expect(launch.title == "Queen of Heaven")
        #expect(launch.startIndex == at)
    }

    @Test func anUnknownOrderFallsBackToThePrayerAlone() {
        let launch = PrayAlongLaunch.opening("memorare", from: .order("no_such_order", at: 0), on: day)
        #expect(launch.orderID == nil)
        #expect(launch.prayerIDs == ["memorare"])
    }

    @Test func anOrderBegunAtARowStartsThere() throws {
        let night = try #require(PrayerBook.order(PrayerBook.nightOrderID))
        let count = night.prayers(on: day).count
        #expect(PrayAlongLaunch.order(night, on: day, startingAt: 3).startIndex == 3)
        #expect(PrayAlongLaunch.order(night, on: day, startingAt: 99).startIndex == count - 1)
        #expect(PrayAlongLaunch.order(night, on: day, startingAt: -1).startIndex == 0)
    }

    /// The order's page numbers its rows by the prayers that resolve, and
    /// the screen counts the same prayers, in every season
    @Test func everyOrdersIDsAreAllPrayers() {
        for date in [day, eastertide] {
            for order in PrayerBook.orders {
                #expect(order.prayers(on: date).map(\.id) == order.prayerIDs(date), "\(order.id)")
            }
        }
    }

    @Test func aPrayerOutsideTheBookStillResolves() {
        #expect(PrayAlongLaunch.resolve("no_such_prayer") == nil)
        #expect(PrayAlongLaunch.resolve("memorare") != nil)
    }
}
