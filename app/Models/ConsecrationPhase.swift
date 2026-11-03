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
            return String(localized: "Days 1\u{2013}12", comment: "Consecration: name of the first period of the preparation, days 1 to 12, shown as a heading")
        case .knowledgeOfSelf:
            return String(localized: "Week 1", comment: "Consecration: name of the second period of the preparation (days 13 to 19)")
        case .knowledgeOfMary:
            return String(localized: "Week 2", comment: "Consecration: name of the third period of the preparation (days 20 to 26)")
        case .knowledgeOfJesus:
            return String(localized: "Week 3", comment: "Consecration: name of the fourth period of the preparation (days 27 to 33)")
        case .consecrationDay:
            return String(localized: "Consecration Day", comment: "Consecration: name of the last period, day 34, when the act of consecration is made")
        }
    }

    /// Subtitle describing the focus of the phase
    var subtitle: String {
        switch self {
        case .preparatory:
            return String(localized: "Letting Go of the World", comment: "Consecration: what the first period (days 1 to 12) is about, under its name")
        case .knowledgeOfSelf:
            return String(localized: "Knowing Yourself", comment: "Consecration: what the first week (days 13 to 19) is about, knowledge of self")
        case .knowledgeOfMary:
            return String(localized: "Knowing Mary", comment: "Consecration: what the second week (days 20 to 26) is about, knowledge of Mary")
        case .knowledgeOfJesus:
            return String(localized: "Knowing Jesus", comment: "Consecration: what the third week (days 27 to 33) is about, knowledge of Jesus")
        case .consecrationDay:
            return String(localized: "Total Consecration to Jesus through Mary", comment: "Consecration: what the day of consecration (day 34) is, under its name")
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

    /// The painting that frames the day-overview arch. Each phase borrows
    /// the mystery whose scene carries its work: the Jordan for the
    /// emptying of self, Gethsemane for self-knowledge, the Annunciation
    /// for Mary, the Upper Room for Christ, the Coronation for the day
    /// the consecration is made.
    var heroImageName: String {
        switch self {
        case .preparatory:      return "luminous_baptism"
        case .knowledgeOfSelf:  return "sorrowful_agony"
        case .knowledgeOfMary:  return "joyful_annunciation"
        case .knowledgeOfJesus: return "luminous_eucharist"
        case .consecrationDay:  return "glorious_coronation"
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
