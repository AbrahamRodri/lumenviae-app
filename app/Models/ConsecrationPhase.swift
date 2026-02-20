//
//  ConsecrationPhase.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION PHASE - REPRESENTS A PHASE OF THE 33-DAY CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  The 33-Day Total Consecration to Jesus through Mary (St. Louis de Montfort)
//  is divided into four phases, each with its own focus and set of prayers:
//
//  - Preparatory Period (Days 1-12): Emptying oneself of worldly spirit
//  - Week 1 (Days 13-19): Knowledge of Self
//  - Week 2 (Days 20-26): Knowledge of Mary
//  - Week 3 (Days 27-33): Knowledge of Jesus
//  - Consecration Day (Day 34): The Act of Consecration
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftUI

// MARK: - ConsecrationPhase

/// Represents a phase of the 33-Day Total Consecration.
///
/// Each phase has its own:
/// - Focus/theme for meditation
/// - Set of daily prayers (same prayers throughout the phase)
/// - Unique visual styling (colors)
///
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

    /// Gradient colors for this phase's visual theme
    var gradientColors: [Color] {
        switch self {
        case .preparatory:
            // Deep purple gradient
            return [Color(hex: "#4A1A6B"), Color(hex: "#2D1B4E")]
        case .knowledgeOfSelf:
            // Navy blue gradient
            return [Color(hex: "#1A365D"), Color(hex: "#1E3A5F")]
        case .knowledgeOfMary:
            // Blue to gold gradient
            return [Color(hex: "#1E40AF"), Color(hex: "#D4AF37")]
        case .knowledgeOfJesus:
            // Gold to cream gradient
            return [Color(hex: "#D4AF37"), Color(hex: "#F5F0E1")]
        case .consecrationDay:
            // Full gold gradient
            return [Color(hex: "#D4AF37"), Color(hex: "#E8C547")]
        }
    }

    /// Primary accent color for this phase
    var accentColor: Color {
        switch self {
        case .preparatory:
            return Color(hex: "#9B59B6")  // Purple accent
        case .knowledgeOfSelf:
            return Color(hex: "#3498DB")  // Blue accent
        case .knowledgeOfMary:
            return Color(hex: "#5DADE2")  // Light blue accent
        case .knowledgeOfJesus:
            return Color(hex: "#D4AF37")  // Gold accent
        case .consecrationDay:
            return Color(hex: "#E8C547")  // Bright gold
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
