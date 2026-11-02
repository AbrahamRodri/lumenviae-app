//
//  AppLinkTests.swift
//  Lumen Viae Tests
//
//  A lumenviae:// link, as an App Store In-App Event opens the app with,
//  goes to Home from wherever the reader is; a link of another scheme
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
        router.push(.howToPray)
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

    @Test(arguments: ["https://lumenviae.org/home", "mailto:someone@example.com"])
    func anotherSchemeChangesNothing(_ link: String) throws {
        let router = routerAwayFromHome()
        router.open(try #require(URL(string: link)))
        #expect(router.selectedTab == .prayers)
        #expect(router.path.count == 1)
    }
}
