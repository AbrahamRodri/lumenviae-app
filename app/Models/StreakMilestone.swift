//
//  StreakMilestone.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  STREAK MILESTONES - DEVOTIONAL REWARDS FOR CONSISTENT PRAYER
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Milestones follow real devotional structures of the Church rather than
//  arbitrary numbers — a 9-day streak completes a Novena, a 33-day streak
//  mirrors St. Louis de Montfort's consecration period, 54 days completes
//  the traditional 54-Day Rosary Novena.
//
//  Design rule: milestones celebrate and invite — they are never used to
//  guilt the user about what might be lost.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

/// A named devotional milestone reached by praying a number of consecutive days.
struct StreakMilestone: Identifiable, Equatable {
    /// Days of consecutive prayer required
    let days: Int

    /// Devotional name, e.g. "Novena"
    let name: String

    /// SF Symbol shown on the milestone badge
    let icon: String

    /// Short celebratory line shown when the milestone is reached
    let blessing: String

    var id: Int { days }

    // MARK: - All Milestones

    /// Ordered by days ascending.
    static let all: [StreakMilestone] = [
        StreakMilestone(
            days: 3,
            name: "Triduum",
            icon: "3.circle",
            blessing: "Three days of prayer, after the ancient rhythm of the Church."
        ),
        StreakMilestone(
            days: 7,
            name: "A Faithful Week",
            icon: "sun.max",
            blessing: "Seven days — every mystery of the week visited in prayer."
        ),
        StreakMilestone(
            days: 9,
            name: "Novena",
            icon: "9.circle",
            blessing: "Nine days of unbroken devotion, in the tradition of the Apostles in the Upper Room."
        ),
        StreakMilestone(
            days: 33,
            name: "Consecration",
            icon: "crown",
            blessing: "Thirty-three days — the length of St. Louis de Montfort's total consecration."
        ),
        StreakMilestone(
            days: 54,
            name: "54-Day Novena",
            icon: "rosette",
            blessing: "The great Rosary Novena complete — 27 days in petition, 27 in thanksgiving."
        ),
        StreakMilestone(
            days: 100,
            name: "Hundredfold",
            icon: "leaf",
            blessing: "Some seed fell on good soil and brought forth fruit a hundredfold."
        ),
        StreakMilestone(
            days: 365,
            name: "A Year of Grace",
            icon: "sparkles",
            blessing: "A full year of daily prayer. Ad majorem Dei gloriam."
        )
    ]

    // MARK: - Lookup

    /// The milestone earned exactly at this streak, if any.
    /// Used to trigger the one-time celebration on the completion screen.
    static func milestone(reachedAt streak: Int) -> StreakMilestone? {
        all.first { $0.days == streak }
    }

    /// The next milestone ahead of this streak, if any.
    /// Used for the goal-gradient line on the streak card
    /// ("Novena — 3 days away").
    static func next(after streak: Int) -> StreakMilestone? {
        all.first { $0.days > streak }
    }

    /// The most recent milestone already achieved, if any.
    static func latest(achievedBy streak: Int) -> StreakMilestone? {
        all.last { $0.days <= streak }
    }

    /// Progress (0...1) from the previous milestone toward the next one.
    /// Gives the streak card's progress bar a satisfying "almost there" feel.
    static func progressTowardNext(streak: Int) -> Double {
        guard let next = next(after: streak) else { return 1.0 }
        let previousDays = latest(achievedBy: streak)?.days ?? 0
        let span = Double(next.days - previousDays)
        guard span > 0 else { return 1.0 }
        return Double(streak - previousDays) / span
    }
}
