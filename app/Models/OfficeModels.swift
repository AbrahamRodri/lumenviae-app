//
//  OfficeModels.swift
//  Lumen Viae
//
//  The Divine Office as the Lumen Viae API serves it
//  (https://lumenviae.fly.dev/api/office/*), assembled from the Divinum
//  Officium engine behind the Phoenix API:
//  - GET /office/:date        → OfficeDay (the day's place in the calendar)
//  - GET /office/:date/:hour  → OfficeHour (one canonical hour, in full)
//  - GET /office/calendar/:year/:month → OfficeCalendarMonth
//
//  Every hour arrives as sections whose Latin and vernacular cells keep
//  Divinum Officium's line structure, so the two sides pair line for
//  line the way the missal's passages do. Foundation-only so decoding
//  can happen off the main actor.
//

import Foundation

// MARK: - CanonicalHour

/// The eight hours of the Roman office. Bundled rather than fetched from
/// /office/versions — the hours of the office are doctrinally stable, and
/// the ledger must render with no network.
nonisolated enum CanonicalHour: String, CaseIterable, Codable, Identifiable {
    case matins = "matutinum"
    case lauds = "laudes"
    case prime = "prima"
    case terce = "tertia"
    case sext = "sexta"
    case nones = "nona"
    case vespers = "vesperae"
    case compline = "completorium"

    var id: String { rawValue }

    /// The name the hour is known by in English
    var label: String {
        switch self {
        case .matins: return "Matins"
        case .lauds: return "Lauds"
        case .prime: return "Prime"
        case .terce: return "Terce"
        case .sext: return "Sext"
        case .nones: return "None"
        case .vespers: return "Vespers"
        case .compline: return "Compline"
        }
    }

    /// The breviary's own name
    var latinName: String {
        switch self {
        case .matins: return "Matutinum"
        case .lauds: return "Laudes"
        case .prime: return "Prima"
        case .terce: return "Tertia"
        case .sext: return "Sexta"
        case .nones: return "Nona"
        case .vespers: return "Vesperae"
        case .compline: return "Completorium"
        }
    }

    /// When the hour is traditionally prayed
    var timeOfDay: String {
        switch self {
        case .matins: return "In the night"
        case .lauds: return "At dawn"
        case .prime: return "Early morning"
        case .terce: return "Mid-morning"
        case .sext: return "At midday"
        case .nones: return "Mid-afternoon"
        case .vespers: return "At evening"
        case .compline: return "Before sleep"
        }
    }

    /// The hour whose traditional time holds the given clock hour — a
    /// quiet suggestion for the ledger, never a gate.
    static func present(atClockHour clockHour: Int) -> CanonicalHour {
        switch clockHour {
        case 0...4: return .matins
        case 5...6: return .lauds
        case 7...8: return .prime
        case 9...11: return .terce
        case 12...13: return .sext
        case 14...15: return .nones
        case 16...18: return .vespers
        default: return .compline
        }
    }

    var previous: CanonicalHour? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return nil }
        return all[index - 1]
    }

    var next: CanonicalHour? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index < all.count - 1 else { return nil }
        return all[index + 1]
    }
}

// MARK: - OfficeHour

/// One canonical hour on one date: Latin and the requested translation,
/// section by section.
nonisolated struct OfficeHour: Codable, Hashable {
    /// "2026-08-24" — the request's own form, which the cache keys by
    let date: String

    /// The hour's slug, "laudes"
    let hour: String

    /// Rubrical version slug, "rubrics-1960"
    let version: String

    /// Translation language slug, "english"
    let language: String

    let celebration: OfficeCelebration?

    /// The season line, e.g. "Feria Secunda infra Hebdomadam XIII post
    /// Octavam Pentecostes"
    let tempora: String?

    let sections: [OfficeSection]

    /// The texts are the Divinum Officium Project's work; every response
    /// names its source and the reader's footer honors it.
    let source: OfficeSource
}

// MARK: - OfficeSection

/// One row of the office: a Latin cell and its translation. The engine
/// drops the second column when Latin itself is the requested
/// translation, so either side may be missing.
nonisolated struct OfficeSection: Codable, Hashable {
    let latin: OfficeCell?
    let vernacular: OfficeCell?
}

// MARK: - OfficeCell

/// One side of a section: its red title ("Incipit", "Psalmi"), an
/// optional brace-wrapped rubric note, and the text line by line.
nonisolated struct OfficeCell: Codable, Hashable {
    let title: String?
    let note: String?
    let lines: [String]
}

// MARK: - OfficeSource

nonisolated struct OfficeSource: Codable, Hashable {
    let name: String
    let url: String
}

// MARK: - OfficeCelebration

nonisolated struct OfficeCelebration: Codable, Hashable {
    let title: String

    /// "II. classis" — the engine's own wording, shown as given
    let rank: String?
}

// MARK: - OfficeDay

/// One day's place in the calendar, from GET /office/:date or a month's
/// calendar — the celebration and rank, the season or commemoration
/// line, and any rubric note, without any hour's text.
nonisolated struct OfficeDay: Codable, Hashable, Identifiable {
    /// "2026-08-24"
    let date: String

    let celebration: OfficeCelebration?

    /// The calendar's second column verbatim: usually the season
    /// ("Tempora"), on other days a commemoration line.
    let detail: OfficeDayDetail?

    let note: String?

    /// The ferial letter, "F.II" — carried but not displayed
    let letter: String?

    var id: String { date }
}

// MARK: - OfficeDayDetail

nonisolated struct OfficeDayDetail: Codable, Hashable {
    let label: String?
    let text: String?
}

// MARK: - OfficeCalendarMonth

/// GET /office/calendar/:year/:month — the liturgical calendar for one
/// month under one set of rubrics.
nonisolated struct OfficeCalendarMonth: Codable, Hashable {
    let year: Int
    let month: Int
    let version: String
    let days: [OfficeDay]
}
