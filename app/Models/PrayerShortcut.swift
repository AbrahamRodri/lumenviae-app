//
//  PrayerShortcut.swift
//  Lumen Viae
//
//  The vocabulary of the app's personalization: the devotional acts a
//  user can reach in one motion, and the old Me page's sections, which
//  the Chapel's migration still reads.
//
//  One enum feeds three surfaces — the Pray button's quick tap, the
//  press-and-hold tray beneath it, and the Rule of Prayer on the
//  Chapel's Today tile — so an act added to the app lights up
//  everywhere at once.
//
//  Stored by raw string in UserDefaults; an unrecognized value (from a
//  newer or older build) is silently dropped rather than crashing the
//  layout.
//

import Foundation

// MARK: - PrayerShortcut

/// A devotional act reachable in one motion.
enum PrayerShortcut: String, CaseIterable, Identifiable {
    case todaysRosary = "todays_rosary"
    case chooseMeditation = "choose_meditation"
    case sevenSorrows = "seven_sorrows"
    case scripturalRosary = "scriptural_rosary"
    case rosaryAloud = "rosary_aloud"
    case mass = "mass"
    case office = "office"
    case consecration = "consecration"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todaysRosary:     return "Today's Rosary"
        case .chooseMeditation: return "Choose a Meditation"
        case .sevenSorrows:     return "Seven Sorrows"
        case .scripturalRosary: return "The Scriptural Rosary"
        case .rosaryAloud:      return "The Rosary Aloud"
        case .mass:             return "The Mass"
        case .office:           return "The Divine Office"
        case .consecration:     return "The Consecration"
        }
    }

    /// The static line under the title. The Rosary's is dynamic (the
    /// day's mysteries) and computed where the schedule is known.
    var subtitle: String {
        switch self {
        case .todaysRosary:     return "The day's mysteries, straight to prayer"
        case .chooseMeditation: return "Browse the day's meditation sets"
        case .sevenSorrows:     return "The chaplet of Our Lady's sorrows"
        case .scripturalRosary: return "A verse of Scripture for every bead"
        case .rosaryAloud:      return "Every prayer said aloud, bead by bead"
        case .mass:             return "Today's propers · 1962 Missal"
        case .office:           return "The canonical hours · 1962 Breviary"
        case .consecration:     return "The 33-day preparation"
        }
    }

    var icon: String {
        switch self {
        case .todaysRosary:     return "ch-rosary"
        case .chooseMeditation: return "ph-cards"
        // Mary's heart pierced by Simeon's sword, the devotion's own
        // image; the plain heart meant nothing in particular
        case .sevenSorrows:     return "ch-sorrowful-heart"
        case .scripturalRosary: return "ch-bible"
        // The speaker, which elsewhere only ever marks a thing that
        // sounds — a chant, a chapter read aloud — and never another
        // devotion's door: this devotion is the one that sounds
        case .rosaryAloud:      return "ph-speaker-high"
        case .mass:             return "ch-altar"
        case .office:           return "ph-clock"
        case .consecration:     return "ch-consecration"
        }
    }

    /// The act's name as the rule and the Chapel's focus block set it —
    /// "The Rosary", not "Today's Rosary": on a daily rule every act is
    /// today's, and the shorter name is the one that fits a ledger row.
    var actName: String {
        switch self {
        case .todaysRosary:     return "The Rosary"
        case .chooseMeditation: return "A Meditation"
        case .sevenSorrows:     return "Seven Sorrows"
        case .scripturalRosary: return "Scriptural Rosary"
        case .rosaryAloud:      return "The Rosary Aloud"
        case .mass:             return "The Mass"
        case .office:           return "The Office"
        case .consecration:     return "Consecration"
        }
    }

    /// Whether this act can be chosen for a daily Rule of Prayer.
    ///
    /// The Mass and the Office stay off it until the app can keep a
    /// day's schedule for them — a rule may only carry what the Chapel
    /// can ask about honestly. The Consecration is not chosen either,
    /// but is never absent: while a preparation is under way it stands
    /// on the rule of its own accord. Browsing the picker for a
    /// meditation is a doorway to the Rosary, not a devotion beside it,
    /// so it is not a rule of its own. The Rosary Aloud is: the Chapel
    /// watches it finish by name, as it does the Scriptural Rosary.
    var isRuleEligible: Bool {
        switch self {
        case .todaysRosary, .scripturalRosary, .rosaryAloud, .sevenSorrows:
            return true
        case .mass, .office, .consecration, .chooseMeditation:
            return false
        }
    }

    /// Decodes a stored list, dropping values this build doesn't know.
    static func decode(_ raw: [String]) -> [PrayerShortcut] {
        raw.compactMap(PrayerShortcut.init(rawValue:))
    }
}

// MARK: - MeWidget

/// A section of the old Me page, which the Chapel replaced. Nothing
/// draws these any more: they are kept so the Chapel's one-time
/// migration (`UserSettings.chapelLayout(fromMeWidgets:)`) can read an
/// arrangement stored under `userSettings.meWidgets`. A stored raw value
/// this build no longer knows is dropped on decode.
enum MeWidget: String {
    case rule = "rule"
    case streak = "streak"
    case library = "library"
    case reading = "reading"
    case consecration = "consecration"
    case journal = "journal"

    static func decode(_ raw: [String]) -> [MeWidget] {
        raw.compactMap(MeWidget.init(rawValue:))
    }
}
