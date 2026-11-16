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

@Suite struct AngelusTapTests {
    @Test func theBellOpensTheAngelusOverOrdinaryPages() {
        #expect(AppRouter.angelusTapOpens(over: []))
        #expect(AppRouter.angelusTapOpens(over: [.explore, .missal, nil]))
    }

    @Test func theBellNeverTakesAPrayerUnderWay() {
        #expect(!AppRouter.angelusTapOpens(over: [.guidedRosary(.joyful)]))
        #expect(!AppRouter.angelusTapOpens(over: [.explore, .completion]))
    }
}

/// The widgets' links: each path opens its page over Home
@Suite struct AppLinkPathTests {
    private func opened(_ link: String) throws -> AppRouter {
        let router = AppRouter()
        router.switchTo(.prayers)
        router.push(.spiritualReading)
        router.open(try #require(URL(string: link)))
        return router
    }

    @Test(arguments: [
        ("lumenviae://home", AppRouter.LinkDestination.home),
        ("lumenviae://rosary/today", .todaysMysteries),
        ("lumenviae://rosary/continue", .continueRosary),
        ("lumenviae://novena/undoer_of_knots", .novena(id: "undoer_of_knots")),
        ("lumenviae://missal/today", .missalToday),
        ("lumenviae://prayer/angelus", .prayer(id: "angelus")),
        ("lumenviae://record", .record),
        ("lumenviae://office/now", .officeNow),
        ("lumenviae://consecration/today", .consecrationToday),
        ("lumenviae:rosary/today", .todaysMysteries),
        ("LUMENVIAE://Rosary/Today", .todaysMysteries),
        ("lumenviae://rosary", .home),
        ("lumenviae://rosary/tomorrow", .home),
        ("lumenviae://novena", .home),
        ("lumenviae://nowhere/at/all", .home),
    ])
    func eachPathIsRead(_ link: String, _ destination: AppRouter.LinkDestination) throws {
        #expect(AppRouter.destination(of: try #require(URL(string: link))) == destination)
    }

    @Test func anotherSchemeHasNoDestination() throws {
        #expect(AppRouter.destination(of: try #require(URL(string: "https://lumenviae.org/rosary/today"))) == nil)
    }

    @Test func rosaryTodayOpensTodaysMysteries() throws {
        let router = try opened("lumenviae://rosary/today")
        #expect(router.selectedTab == .home)
        #expect(router.routes == [.meditationSelection(category: ScheduleService.categoryForToday())])
    }

    @Test func novenaOpensItsPage() throws {
        #expect(try opened("lumenviae://novena/undoer_of_knots").routes == [.novena(id: "undoer_of_knots")])
    }

    @Test func aNovenaWithNoPageStaysHome() throws {
        // St Joseph's is in the book but not prayed with the Rosary: no page
        let router = try opened("lumenviae://novena/st_joseph")
        #expect(router.selectedTab == .home)
        #expect(router.path.isEmpty)
    }

    @Test func missalTodayOpensTheMass() throws {
        #expect(try opened("lumenviae://missal/today").routes == [.missal])
    }

    @Test func recordOpensThePrayerRecord() throws {
        #expect(try opened("lumenviae://record").routes == [.prayerRecord])
    }

    @Test func officeNowOpensTheHours() throws {
        #expect(try opened("lumenviae://office/now").routes == [.office])
    }

    @Test func consecrationTodayTurnsToItsTab() throws {
        let router = try opened("lumenviae://consecration/today")
        #expect(router.selectedTab == .consecration)
        #expect(router.path.isEmpty)
    }

    @Test func theAngelusIsPrayedAsTheBellOpensIt() throws {
        let router = try opened("lumenviae://prayer/angelus")
        #expect(router.shortcutRequest == .angelus)
        #expect(router.path.isEmpty)
    }

    @Test func aPrayerOpensOnThePrayAlong() throws {
        #expect(try opened("lumenviae://prayer/memorare").routes == [.devotionPrayer(id: "memorare")])
    }

    @Test func anUnknownPrayerStaysHome() throws {
        let router = try opened("lumenviae://prayer/no_such_prayer")
        #expect(router.selectedTab == .home)
        #expect(router.path.isEmpty)
    }

    @Test func rosaryContinueTakesUpTheRosaryOrOpensTodaysMysteries() throws {
        let router = try opened("lumenviae://rosary/continue")
        if let request = router.shortcutRequest {
            #expect([.todaysRosary, .scripturalRosary, .rosaryAloud, .sevenSorrows].contains(request))
        } else {
            #expect(router.routes == [.meditationSelection(category: ScheduleService.categoryForToday())])
        }
    }

    @Test func aLinkPathLeavesAPrayerAlone() throws {
        let router = AppRouter()
        router.push(.guidedRosary(.joyful))
        router.open(try #require(URL(string: "lumenviae://missal/today")))
        #expect(router.routes == [.guidedRosary(.joyful)])
    }
}
