//
//  ChapelPagesAndTourTests.swift
//  Lumen Viae Tests
//
//  The reader's own pages and the Chapel's doors to them: the Prayer
//  Record and the journal pushed over the tab they were opened from,
//  the consecration shown once on the Chapel, the milestones still
//  ahead, and the first-use tour's stop at Consecrate.
//

import Foundation
import SwiftUI
import Testing
@testable import app

@MainActor
struct ChapelPagesAndTourTests {

    // MARK: The reader's own pages

    @Test func thePrayerRecordAndTheJournalArePushedOverTheTabTheyCameFrom() {
        let router = AppRouter()
        router.selectedTab = .chapel
        router.switchTo(.progress)
        #expect(router.selectedTab == .chapel, "the Chapel tab stays lit")
        #expect(router.topRoute == .prayerRecord)
        router.switchTo(.journal)
        #expect(router.topRoute == .journal)
        #expect(router.path.count == 2)
    }

    @Test func onlyTheReadersOwnPagesKeepTheTabBar() {
        #expect(AppRoute.prayerRecord.keepsTabBar)
        #expect(AppRoute.journal.keepsTabBar)
        #expect(!AppRoute.explore.keepsTabBar)
        #expect(!AppRoute.settings.keepsTabBar)
    }

    @Test func aTabTappedOverAPushedPageOpensItsOwnPage() {
        let router = AppRouter()
        router.selectedTab = .chapel
        router.push(.prayerRecord)
        router.switchTo(.home)
        #expect(router.path.isEmpty)
        #expect(router.selectedTab == .home)
    }

    // MARK: The consecration, once

    @Test func theConsecrationTileIsOnThePageOnlyWhileItIsOut() {
        let layout = ChapelPlacement.defaultLayout
        #expect(ChapelPlacement.isOnPage(.consecration, in: layout))
        let stowed = layout.map { placement in
            placement.tile == .consecration ? ChapelPlacement(tile: .consecration, span: placement.span, on: false) : placement
        }
        #expect(!ChapelPlacement.isOnPage(.consecration, in: stowed), "put away, the Today row comes back")
    }

    // MARK: Milestones ahead

    @Test func theMilestonesAheadAreTheNextOnesNearestFirst() {
        let ahead = StreakMilestone.ahead(of: 0)
        #expect(ahead.first?.days == StreakMilestone.next(after: 0)?.days)
        #expect(ahead.count == min(5, StreakMilestone.all.count))
        #expect(ahead.map(\.days) == ahead.map(\.days).sorted())
        #expect(StreakMilestone.ahead(of: 9).allSatisfy { $0.days > 9 })
    }

    @Test func pastTheLastMilestoneNothingIsAhead() {
        let last = StreakMilestone.all.last!.days
        #expect(StreakMilestone.ahead(of: last).isEmpty)
        #expect(StreakMilestone.ahead(of: last - 1).map(\.days) == [last])
    }

    // MARK: The tour

    @Test func theTourStopsAtConsecrateBetweenPrayersAndTheChapel() {
        let stops = FirstUseTourStop.allCases
        #expect(stops.count == 6)
        let consecration = stops.firstIndex(of: .consecration)!
        #expect(stops[consecration - 1] == .prayers)
        #expect(stops[consecration + 1] == .chapel)
        #expect(FirstUseTourStop.consecration.words.contains("33-day"))
    }
}
