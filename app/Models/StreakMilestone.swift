//
//  StreakMilestone.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  STREAK MILESTONES - DEVOTIONAL REWARDS FOR CONSISTENT PRAYER
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Milestones follow real devotional structures of the Church rather than
//  arbitrary numbers — a 9-day streak completes a novena, a 33-day streak
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

    /// What the Church calls a run of this length, in plain words, where
    /// it has a name: "a novena". Never shown alone, only after the days.
    let meaning: String?

    /// The glyph on the milestone badge (`AppIcon`): the count's numeral,
    /// or a named devotion's sign
    let icon: String

    /// Short celebratory line shown when the milestone is reached
    let blessing: String

    var id: Int { days }

    /// The milestone as it is named, led by its number: "9 days". The
    /// blessing beneath it says what the Church calls it, and why.
    var name: String { "\(days) days" }

    /// "9 days · a novena": the number, then the Church's name for it, for
    /// a line that has no blessing beneath it to explain
    var title: String { meaning.map { "\(name) · \($0)" } ?? name }

    // MARK: - All Milestones

    /// Ordered by days ascending.
    static let all: [StreakMilestone] = [
        StreakMilestone(
            days: 3,
            meaning: "a triduum",
            icon: "ph-number-circle-three",
            blessing: "Three days in a row: a triduum, the Church's ancient three days of prayer."
        ),
        StreakMilestone(
            days: 7,
            meaning: "a faithful week",
            icon: "ph-number-circle-seven",
            blessing: "Seven days — every mystery of the week visited in prayer."
        ),
        StreakMilestone(
            days: 9,
            meaning: "a novena",
            icon: "ph-number-circle-nine",
            blessing: "Nine days in a row: a novena, as the Apostles prayed for nine days before Pentecost."
        ),
        StreakMilestone(
            days: 33,
            meaning: nil,
            icon: "ch-consecration",
            blessing: "Thirty-three days, as long as St. Louis de Montfort's Consecration to Mary."
        ),
        StreakMilestone(
            days: 54,
            meaning: "a Rosary novena",
            icon: "lv-rosary",
            blessing: "The great Rosary novena complete: 27 days asking, and 27 giving thanks."
        ),
        StreakMilestone(
            days: 100,
            meaning: nil,
            icon: "lv-wheat",
            blessing: "Some seed fell on good soil and brought forth fruit a hundredfold."
        ),
        StreakMilestone(
            days: 365,
            meaning: "a year of grace",
            icon: "ch-chi-rho",
            blessing: "A full year of daily prayer, for the greater glory of God."
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
    /// ("9 days · a novena · 3 days away").
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
