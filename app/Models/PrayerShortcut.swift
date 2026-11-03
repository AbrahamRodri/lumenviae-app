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
    // The Prayer Book's three orders of the day
    case morningPrayers = "morning_prayers"
    case angelus = "angelus"
    case nightPrayers = "night_prayers"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todaysRosary:     return String(localized: "Pray Today's Rosary", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .chooseMeditation: return String(localized: "Choose How to Pray Today", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .sevenSorrows:     return String(localized: "The Seven Sorrows of Mary", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .scripturalRosary: return String(localized: "The Scriptural Rosary", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .rosaryAloud:      return String(localized: "The Audio Rosary", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .mass:             return String(localized: "The Mass", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .office:           return String(localized: "Hours of Prayer", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .consecration:     return String(localized: "Consecration to Mary", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .morningPrayers:   return String(localized: "Morning Prayers", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        case .angelus:          return Self.angelusTitle
        case .nightPrayers:     return String(localized: "Night Prayers", comment: "Pray button tray and its editor: the name of a devotional act the Pray button can open")
        }
    }

    /// The Angelus, or in Eastertide the prayer said in its place, by the
    /// Prayers page's own title for it (`PrayerOrder.title(on:)`), so the
    /// two never name the season's prayer in two ways
    static var angelusTitle: String {
        PrayerBook.order(PrayerBook.angelusOrderID)?.title(on: Date())
            ?? String(localized: "The Angelus", comment: "Pray button tray and daily prayers: the Angelus's name, when the Prayers page's own title for it is missing")
    }

    /// The static line under the title. The Rosary's forms name the
    /// day's mysteries where the schedule is known (`trayDetail`).
    var subtitle: String {
        switch self {
        case .todaysRosary:     return String(localized: "The day's mysteries, straight to prayer", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .chooseMeditation: return String(localized: "Choose how to pray today's mysteries", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .sevenSorrows:     return String(localized: "Seven Hail Marys for each sorrow", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .scripturalRosary: return String(localized: "A Bible verse for every Hail Mary", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .rosaryAloud:      return String(localized: "Listen and pray along", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .mass:             return String(localized: "Today's traditional Latin Mass", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .office:           return String(localized: "The Church\u{2019}s prayer for each hour (Divine Office)", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .consecration:     return String(localized: "Giving yourself to Jesus through Mary", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .morningPrayers:   return String(localized: "Prayers to give the day to God", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .angelus:          return String(localized: "A prayer to Mary at 6 AM, noon and 6 PM", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        case .nightPrayers:     return String(localized: "Look back on the day, and a song to Mary", comment: "Pray button tray and its editor: the line under a devotional act's name, saying what it is")
        }
    }

    /// The line under the title in the Pray tray, where the Rosary's
    /// forms each say whose mysteries they are — and Today's Rosary,
    /// what the voice will do — in the same words as the mysteries' page
    func trayDetail(today: MysteryCategory, praysAloud: Bool) -> String {
        switch self {
        case .todaysRosary where praysAloud:
            return String(
                localized: "\(today.devotionTitle) · with the whole Rosary read to you",
                comment: "Pray button tray, under Pray Today's Rosary when every prayer is said aloud: the day's mysteries (like Joyful Mysteries), then what the voice will do"
            )
        case .todaysRosary:
            return String(
                localized: "\(today.devotionTitle) · with a meditation",
                comment: "Pray button tray, under Pray Today's Rosary when only the meditation is read: the day's mysteries (like Joyful Mysteries), then how it is prayed"
            )
        case .scripturalRosary:
            return String(
                localized: "\(today.devotionTitle) · a verse for every bead",
                comment: "Pray button tray, under The Scriptural Rosary: the day's mysteries (like Joyful Mysteries), then a Bible verse for every bead"
            )
        case .rosaryAloud:
            return String(
                localized: "\(today.devotionTitle) · listen and pray along",
                comment: "Pray button tray, under The Audio Rosary: the day's mysteries (like Joyful Mysteries), then listen and pray along"
            )
        default:
            return subtitle
        }
    }

    /// The act's glyph today, on the user's schedule and in the season
    var icon: String {
        icon(today: ScheduleService.categoryForToday())
    }

    /// The act's glyph on a day whose mysteries are `today`. Every act
    /// wears its own sign but Today's Mysteries, which wears the day's
    /// mysteries' own emblem: the row names them, and the page it opens
    /// is theirs. It wore the open book, which the reading shelf's door
    /// and the Journal wear too.
    func icon(today: MysteryCategory) -> String {
        switch self {
        case .todaysRosary:     return "lv-rosary"
        // The mysteries' page, where the Rosary's forms are chosen
        case .chooseMeditation: return today.iconName
        // Mary's heart pierced by Simeon's sword, the devotion's own
        // image; the plain heart meant nothing in particular
        case .sevenSorrows:     return "lv-pierced-heart"
        case .scripturalRosary: return "ch-bible"
        // The speaker, which elsewhere only ever marks a thing that
        // sounds — a chant, a chapter read aloud — and never another
        // devotion's door: this devotion is the one that sounds
        case .rosaryAloud:      return "ph-speaker-high"
        case .mass:             return "ch-altar"
        case .office:           return "ph-clock"
        case .consecration:     return "ch-consecration"
        case .morningPrayers:   return "lv-rooster"
        case .angelus:          return "lv-bell"
        case .nightPrayers:     return "lv-lamp"
        }
    }

    /// The act's name as the daily prayers and the Chapel's focus block
    /// set it — "The Rosary", not "Today's Rosary": on a list of daily
    /// prayers every act is today's, and the shorter name is the one that
    /// fits a ledger row.
    var actName: String {
        switch self {
        case .todaysRosary:     return String(localized: "The Rosary", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .chooseMeditation: return String(localized: "Choose How to Pray Today", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .sevenSorrows:     return String(localized: "The Seven Sorrows of Mary", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .scripturalRosary: return String(localized: "Scriptural Rosary", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .rosaryAloud:      return String(localized: "The Audio Rosary", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .mass:             return String(localized: "The Mass", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .office:           return String(localized: "Hours of Prayer", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .consecration:     return String(localized: "Consecration to Mary", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .morningPrayers:   return String(localized: "Morning Prayers", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        case .angelus:          return Self.angelusTitle
        case .nightPrayers:     return String(localized: "Night Prayers", comment: "Daily prayers list (the rule of prayer): the short name of a devotional act, as a ledger row sets it")
        }
    }

    /// The Prayer Book's order this act prays, if it is one
    var prayerOrderID: String? {
        switch self {
        case .morningPrayers: return PrayerBook.morningOrderID
        case .angelus:        return PrayerBook.angelusOrderID
        case .nightPrayers:   return PrayerBook.nightOrderID
        default:              return nil
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
    /// so it is not a rule of its own. The Rosary Said Aloud is: the Chapel
    /// watches it finish by name, as it does the Scriptural Rosary.
    var isRuleEligible: Bool {
        switch self {
        case .todaysRosary, .scripturalRosary, .rosaryAloud, .sevenSorrows:
            return true
        // Prayed through to their Amen on the pray-along screen, which
        // marks them offered — so the Chapel can ask about them honestly
        case .morningPrayers, .angelus, .nightPrayers:
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
