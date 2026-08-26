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

    /// "I class" … "IV class", the 1962 ranking
    var rankLabel: String? {
        guard let rank, (1...4).contains(rank) else { return nil }
        return ["I", "II", "III", "IV"][rank - 1] + " class"
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
        guard let rank, (1...4).contains(rank) else { return nil }
        return ["I", "II", "III", "IV"][rank - 1] + " class"
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
