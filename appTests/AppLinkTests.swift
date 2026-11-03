//
//  AppLinkTests.swift
//  Lumen Viae Tests
//
//  A lumenviae:// link, as an App Store In-App Event opens the app with,
//  goes to Home, unless a prayer is under way; a link of another scheme
//  changes nothing.
//

import Foundation
import SwiftUI
import Testing

@testable import app

@MainActor
struct AppLinkTests {

    /// A router turned to the Prayers tab with a page pushed over it
    private func routerAwayFromHome() -> AppRouter {
        let router = AppRouter()
        router.switchTo(.prayers)
        router.push(.spiritualReading)
        return router
    }

    @Test func theAppRegistersTheScheme() throws {
        let types = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes.contains(AppRouter.linkScheme))
    }

    @Test(arguments: ["lumenviae://home", "lumenviae://anything/else?x=1", "LumenViae://", "lumenviae:home"])
    func everyLinkOpensHome(_ link: String) throws {
        let router = routerAwayFromHome()
        router.open(try #require(URL(string: link)))
        #expect(router.selectedTab == .home)
        #expect(router.path.isEmpty)
    }

    /// Going Home lets go of the prayer the router was carrying, as Home
    /// does after a prayer
    @Test func goingHomeClearsThePrayerState() throws {
        let router = routerAwayFromHome()
        router.selectedCategory = .joyful
        router.open(try #require(URL(string: "lumenviae://home")))
        #expect(router.selectedCategory == nil)
        #expect(router.pendingPrayer == nil)
        #expect(router.completedPrayer == nil)
    }

    /// A prayer being prayed, or the screen that closes it, is never
    /// taken away by a link: the app only comes forward where it is
    @Test(arguments: [
        AppRoute.prayerSession(meditationSetId: 1),
        .scripturalRosaryPrayer(ScripturalRosaryLaunch(category: .joyful)),
        .guidedRosary(.joyful),
        .prayAlong(PrayAlongLaunch(orderID: nil, prayerIDs: ["memorare"], title: "Prayers")),
        .completion,
    ])
    func aLinkLeavesAPrayerAlone(_ route: AppRoute) throws {
        let router = AppRouter()
        router.switchTo(.prayers)
        router.push(.spiritualReading)
        router.push(route)
        router.open(try #require(URL(string: "lumenviae://home")))
        #expect(router.selectedTab == .prayers)
        #expect(router.path.count == 2)
    }

    @Test(arguments: ["https://lumenviae.org/home", "mailto:someone@example.com"])
    func anotherSchemeChangesNothing(_ link: String) throws {
        let router = routerAwayFromHome()
        router.open(try #require(URL(string: link)))
        #expect(router.selectedTab == .prayers)
        #expect(router.path.count == 1)
    }
}
