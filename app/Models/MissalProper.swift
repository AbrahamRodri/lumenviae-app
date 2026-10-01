//
//  MissalProper.swift
//  Lumen Viae
//
//  The 1962 Missal as the Missale Meum API serves it
//  (https://www.missalemeum.com/en/api/v5):
//  - GET /proper/YYYY-MM-DD → [MissalProper], one element per celebration
//    that day (Christmas carries its three Masses)
//  - GET /ordo → the fixed parts of the Mass in the same shape
//
//  Every passage arrives as an [english, latin] pair, so the prayer
//  language preference is honored without a second request. Foundation-only
//  so decoding can happen off the main actor.
//

import Foundation

// MARK: - MissalProper

/// One celebration: its feast metadata and its texts in liturgical order.
nonisolated struct MissalProper: Codable, Identifiable, Hashable {
    let info: MissalInfo
    let sections: [MissalSection]

    /// The API's id ("sancti:08-24:2:r") — null on the Ordo, which has
    /// no date, so the title stands in.
    var id: String { info.id ?? info.title }
}

// MARK: - MissalInfo

nonisolated struct MissalInfo: Codable, Hashable {
    let id: String?
    let title: String
    let description: String?
    let date: String?

    /// 1962 class of the feast, 1–4
    let rank: Int?

    /// Vestment color letters — "r", "w", "g", "v", "b", "p"
    let colors: [String]?

    /// Where the day falls in the temporal cycle, e.g.
    /// "Feria II after XIII Sunday after Pentecost"
    let tempora: String?

    /// Hand-missal page references, e.g. "Angelus Press p. 1376"
    let tags: [String]?

    /// Feasts commemorated within this Mass, the way a printed missal
    /// notes "Commemoration of Sts. Euphemia, Lucy and Geminianus"
    let commemorations: [MissalCommemoration]?

    /// The day's rank in plain words — "Great Feast", "Feast", "Lesser
    /// Feast", "Weekday" — never the 1962 "I class"; see `DayRank`
    var rankLabel: String? {
        DayRank.plainLabel(rank: rank, title: title, season: tempora)
    }
}

// MARK: - MissalCommemoration

nonisolated struct MissalCommemoration: Codable, Hashable {
    let title: String
}

// MARK: - MissalCalendarDay

/// One day of the 1962 calendar: GET /calendar/{year} → [MissalCalendarDay].
/// The API's `id` for a calendar entry is the date itself, "2026-01-01".
nonisolated struct MissalCalendarDay: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let rank: Int?
    let colors: [String]?
    let commemorations: [MissalCommemoration]?

    var rankLabel: String? {
        DayRank.plainLabel(rank: rank, title: title)
    }
}

// MARK: - DayRank

/// The day's rank in the words both books use. The 1962 calendar ranks
/// a day I to IV class; the Missal served it as "I class" and the Office
/// as "First class", which said nothing to a newcomer and did not agree
/// with each other. Home and the Chapel read the same words through
/// `MissalProper.rankLabel`, and the Office through `OfficeRank`.
nonisolated enum DayRank {

    /// "Great Feast" · "Feast" · "Lesser Feast" · "Weekday". A day whose
    /// title is a feria is a weekday whatever its class — "Lenten
    /// Weekday" or "Advent Weekday" in those seasons. `season` is any
    /// further text that may name the season (the Missal's tempora).
    static func plainLabel(rank: Int?, title: String?, season: String? = nil) -> String? {
        let words = "\(title ?? "") \(season ?? "")".lowercased()
        if isWeekday(title) {
            return weekday(in: words)
        }
        guard let rank, (1...4).contains(rank) else { return nil }
        switch rank {
        case 1: return "Great Feast"
        case 2: return "Feast"
        case 3: return "Lesser Feast"
        default: return weekday(in: words)
        }
    }

    /// A feria by its title: "Feria …", or a weekday named for its week
    /// ("Monday of Holy Week", "Tuesday after Ash Wednesday"), an Ember
    /// day, or Ash Wednesday itself — ranked I to III class in Lent and
    /// Holy Week, but weekdays, never feasts. The days of an octave and
    /// of the Triduum are named by weekday too, and are not weekdays.
    private static func isWeekday(_ title: String?) -> Bool {
        let t = (title ?? "").lowercased()
        let notWeekdays = ["octave", "supper", "good friday", "holy saturday", "vigil"]
        if notWeekdays.contains(where: { t.contains($0) }) { return false }
        return t.contains("feria")
            || t.contains("ember ")
            || t.hasPrefix("ash wednesday")
            || t.range(of: "^(monday|tuesday|wednesday|thursday|friday|saturday)\\b",
                       options: .regularExpression) != nil
    }

    private static func weekday(in words: String) -> String {
        if words.contains("advent") { return "Advent Weekday" }
        if words.contains("holy week") || words.contains("ash wednesday") { return "Lenten Weekday" }
        // "Lent" as a word, so a Valentine or a silent night is not Lenten;
        // the Latin tempora say "Quadragesimæ" and "Passionis"
        if words.range(of: "\\blent\\b", options: .regularExpression) != nil
            || words.contains("quadrages") || words.contains("passion") {
            return "Lenten Weekday"
        }
        return "Weekday"
    }
}

// MARK: - MissalSection

/// One proper of the Mass — Introit, Collect, Gospel — or one fixed part
/// of the Ordo.
nonisolated struct MissalSection: Codable, Hashable {

    /// Latin name — "Introitus", "Oratio", "Evangelium"
    let id: String?

    /// English name — "Introit", "Collect", "Gospel"
    let label: String?

    /// Passages in order; each is an [english, latin] pair. A rare
    /// single-element passage carries the same text for both.
    let body: [[String]]
}
