//
//  StreakMilestoneTests.swift
//  Lumen Viae Tests
//
//  The streak's milestones: in order, each reached on exactly its day,
//  the next one ahead and the last one behind found from any streak,
//  progress between them never leaving 0...1, every badge's glyph in
//  the catalog, and every title led by its number.
//

import Testing
import UIKit
@testable import app

@MainActor
struct StreakMilestoneTests {

    @Test func theMilestonesRunInOrderWithNoDayTwice() {
        let days = StreakMilestone.all.map(\.days)
        #expect(days == days.sorted())
        #expect(Set(days).count == days.count)
    }

    @Test func aMilestoneIsReachedOnItsDayAndNoOther() {
        for milestone in StreakMilestone.all {
            #expect(StreakMilestone.milestone(reachedAt: milestone.days) == milestone)
            #expect(StreakMilestone.milestone(reachedAt: milestone.days + 1)?.days != milestone.days)
        }
        #expect(StreakMilestone.milestone(reachedAt: 0) == nil)
        #expect(StreakMilestone.milestone(reachedAt: 10) == nil)
    }

    @Test func theNextAndTheLatestStandEitherSideOfTheStreak() {
        #expect(StreakMilestone.next(after: 0)?.days == 3)
        #expect(StreakMilestone.latest(achievedBy: 0) == nil)
        #expect(StreakMilestone.next(after: 9)?.days == 33)
        #expect(StreakMilestone.latest(achievedBy: 9)?.days == 9)
        #expect(StreakMilestone.next(after: 365) == nil)
        #expect(StreakMilestone.latest(achievedBy: 1000)?.days == 365)
    }

    @Test func progressStaysBetweenZeroAndOne() {
        for streak in 0...400 {
            let progress = StreakMilestone.progressTowardNext(streak: streak)
            #expect((0...1).contains(progress), "streak \(streak): \(progress)")
        }
        #expect(StreakMilestone.progressTowardNext(streak: 9) == 0)
        #expect(StreakMilestone.progressTowardNext(streak: 500) == 1)
    }

    @Test func everyTitleLeadsWithItsNumber() {
        for milestone in StreakMilestone.all {
            #expect(milestone.title.hasPrefix("\(milestone.days) days"))
        }
        #expect(StreakMilestone.milestone(reachedAt: 9)?.title == "9 days · a novena")
        #expect(StreakMilestone.milestone(reachedAt: 33)?.title == "33 days")
    }

    @Test func everyBadgeGlyphIsInTheCatalog() {
        for milestone in StreakMilestone.all {
            #expect(UIImage(named: milestone.icon) != nil, "\(milestone.icon)")
        }
    }
}
