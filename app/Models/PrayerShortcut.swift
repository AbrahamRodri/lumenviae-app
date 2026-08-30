//
//  PrayerShortcut.swift
//  Lumen Viae
//
//  The vocabulary of the app's personalization: the devotional acts a
//  user can reach in one motion, and the sections they can lay out on
//  their own page.
//
//  One enum feeds three surfaces — the Pray button's quick tap, the
//  press-and-hold tray beneath it, and the Rule of Prayer on the Me
//  page — so an act added to the app lights up everywhere at once.
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
    case mass = "mass"
    case office = "office"
    case consecration = "consecration"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todaysRosary:     return "Today's Rosary"
        case .chooseMeditation: return "Choose a Meditation"
        case .sevenSorrows:     return "Seven Sorrows"
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
        case .mass:             return "Today's propers · 1962 Missal"
        case .office:           return "The canonical hours · 1962 Breviary"
        case .consecration:     return "The 33-day preparation"
        }
    }

    var icon: String {
        switch self {
        case .todaysRosary:     return "ch-rosary"
        case .chooseMeditation: return "ph-cards"
        case .sevenSorrows:     return "ph-heart"
        case .mass:             return "ch-altar"
        case .office:           return "ph-clock"
        case .consecration:     return "ph-crown"
        }
    }

    /// Whether this act belongs in a daily Rule of Prayer. Browsing the
    /// picker is a doorway, not a devotion — it stays off the rule.
    var isRuleEligible: Bool {
        self != .chooseMeditation
    }

    /// Decodes a stored list, dropping values this build doesn't know.
    static func decode(_ raw: [String]) -> [PrayerShortcut] {
        raw.compactMap(PrayerShortcut.init(rawValue:))
    }
}

// MARK: - MeWidget

/// A section the user can place on their Me page, in their own order.
/// A stored raw value this build no longer knows (a removed section) is
/// dropped on decode rather than crashing the layout.
enum MeWidget: String, CaseIterable, Identifiable {
    case rule = "rule"
    case streak = "streak"
    case library = "library"
    case reading = "reading"
    case consecration = "consecration"
    case journal = "journal"

    var id: String { rawValue }

    /// The sections a fresh install shows, in order.
    static let defaultOrder: [MeWidget] = [.rule, .streak, .library, .reading, .consecration, .journal]

    var title: String {
        switch self {
        case .rule:         return "Rule of Prayer"
        case .streak:       return "Prayer Streak"
        case .library:      return "Library"
        case .reading:      return "Reading"
        case .consecration: return "Consecration"
        case .journal:      return "Reflections"
        }
    }

    /// One line in the editor explaining what the section shows.
    var detail: String {
        switch self {
        case .rule:         return "Your daily devotions as a checklist"
        case .streak:       return "Your streak and this week's prayer"
        case .library:      return "The missal, office, books, and guides"
        case .reading:      return "The book you have open, and where you left it"
        case .consecration: return "Your place on the 33-day path"
        case .journal:      return "Your latest journal entries"
        }
    }

    var icon: String {
        switch self {
        case .rule:         return "ph-scroll"
        case .streak:       return "ph-flame"
        case .library:      return "ph-book"
        case .reading:      return "ph-book-open-fill"
        case .consecration: return "ph-crown"
        case .journal:      return "ph-book-open"
        }
    }

    static func decode(_ raw: [String]) -> [MeWidget] {
        raw.compactMap(MeWidget.init(rawValue:))
    }
}
