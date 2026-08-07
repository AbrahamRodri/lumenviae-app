//
//  ConsecrationPhase.swift
//  Lumen Viae
//
//  The phases of the 33-Day Total Consecration (St. Louis de Montfort):
//  Preparatory (Days 1-12), Knowledge of Self (13-19), Knowledge of Mary
//  (20-26), Knowledge of Jesus (27-33), Consecration Day (34). Each phase
//  has its own focus, daily prayers, and colors.
//

import Foundation
import SwiftUI

enum ConsecrationPhase: String, Codable, CaseIterable, Hashable {

    case preparatory       // Days 1-12: Emptying of worldly spirit
    case knowledgeOfSelf   // Days 13-19: Week 1
    case knowledgeOfMary   // Days 20-26: Week 2
    case knowledgeOfJesus  // Days 27-33: Week 3
    case consecrationDay   // Day 34: The Act of Consecration

    // MARK: - Display Properties

    /// Human-readable name for the phase
    var displayName: String {
        switch self {
        case .preparatory:
            return "Preparatory Period"
        case .knowledgeOfSelf:
            return "Week One"
        case .knowledgeOfMary:
            return "Week Two"
        case .knowledgeOfJesus:
            return "Week Three"
        case .consecrationDay:
            return "Consecration Day"
        }
    }

    /// Subtitle describing the focus of the phase
    var subtitle: String {
        switch self {
        case .preparatory:
            return "Emptying Oneself of the Spirit of the World"
        case .knowledgeOfSelf:
            return "Knowledge of Self"
        case .knowledgeOfMary:
            return "Knowledge of the Blessed Virgin"
        case .knowledgeOfJesus:
            return "Knowledge of Jesus Christ"
        case .consecrationDay:
            return "Total Consecration to Jesus through Mary"
        }
    }

    // MARK: - Day Range

    /// The range of days (1-34) that belong to this phase
    var dayRange: ClosedRange<Int> {
        switch self {
        case .preparatory:
            return 1...12
        case .knowledgeOfSelf:
            return 13...19
        case .knowledgeOfMary:
            return 20...26
        case .knowledgeOfJesus:
            return 27...33
        case .consecrationDay:
            return 34...34
        }
    }

    /// Number of days in this phase
    var dayCount: Int {
        dayRange.count
    }

    // MARK: - Visual Styling

    /// Tint colors layered OVER the theme's own gradient (never a
    /// standalone background, which would freeze one theme's palette) —
    /// a quiet hue journey: penitential violet-navy, deep navy, Marian
    /// blue, then warming toward gold as the consecration nears.
    var gradientColors: [Color] {
        switch self {
        case .preparatory:
            // Emptying of self: dark violet-tinged navy
            return [Color(hex: "#1D1832"), Color(hex: "#100D1F")]
        case .knowledgeOfSelf:
            // Introspection: deep navy
            return [Color(hex: "#141E38"), Color(hex: "#0C1222")]
        case .knowledgeOfMary:
            // Marian blue cast
            return [Color(hex: "#16264D"), Color(hex: "#0D142A")]
        case .knowledgeOfJesus:
            // Warming toward gold
            return [Color(hex: "#2A2318"), Color(hex: "#14101E")]
        case .consecrationDay:
            // Rich dark gold, matching the mystery-card gradient family
            return [Color(hex: "#3D3522"), Color(hex: "#1A1408")]
        }
    }

    /// Accent for progress indicators — the active theme's gold, quietly
    /// brightening as the 33 days advance. Reads through AppColors so all
    /// three themes stay coherent.
    var accentColor: Color {
        switch self {
        case .preparatory:
            return AppColors.gold.opacity(0.6)
        case .knowledgeOfSelf:
            return AppColors.gold.opacity(0.75)
        case .knowledgeOfMary:
            return AppColors.gold.opacity(0.9)
        case .knowledgeOfJesus:
            return AppColors.gold
        case .consecrationDay:
            return AppColors.goldLight
        }
    }

    // MARK: - Prayer Set

    /// IDs of prayers for this phase (same prayers each day within the phase)
    var prayerIds: [String] {
        switch self {
        case .preparatory:
            return [
                "veni_creator",
                "ave_maris_stella",
                "magnificat",
                "glory_be"
            ]
        case .knowledgeOfSelf:
            return [
                "litany_holy_ghost",
                "litany_loreto",
                "ave_maris_stella"
            ]
        case .knowledgeOfMary:
            return [
                "litany_holy_ghost",
                "litany_loreto",
                "ave_maris_stella",
                "st_louis_prayer_mary",
                "rosary"
            ]
        case .knowledgeOfJesus:
            return [
                "litany_holy_ghost",
                "ave_maris_stella",
                "litany_holy_name",
                "st_louis_prayer_jesus",
                "o_jesus_living_in_mary"
            ]
        case .consecrationDay:
            return [
                "act_of_consecration"
            ]
        }
    }

    // MARK: - Static Helpers

    /// Get the phase for a given day number (1-34)
    static func phase(for dayNumber: Int) -> ConsecrationPhase? {
        for phase in allCases {
            if phase.dayRange.contains(dayNumber) {
                return phase
            }
        }
        return nil
    }
}
