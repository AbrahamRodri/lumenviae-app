//
//  LibraryReading.swift
//  Lumen Viae
//
//  The vocabulary of the library's short readings — the Marian Library's
//  entries, St. Carlo's life and devotions — and the one place that
//  finds a reading by its id.
//
//  A reading is a few paragraphs of prose, one saying set apart as a
//  quotation, and the doors it ends in: its feast, the mysteries or
//  prayer it is prayed in, an act of the day's rule, or another page.
//  Readings stand on shelves; `LibraryReadingView` steps along a shelf
//  in place.
//

import Foundation

// MARK: - Model

struct KeptFeast: Hashable {
    let month: Int
    let day: Int
    let name: String

    /// On the universal 1962 calendar, so the Missal serves its Mass
    var inMissal: Bool = true

    /// Named for a place or a people it is kept by, when not universal
    var keptBy: String? = nil

    /// The next time the feast is kept, today included
    func nextDate(from now: Date = .now, calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: now)
        let year = calendar.component(.year, from: today)
        for candidate in [year, year + 1] {
            if let date = calendar.date(from: DateComponents(year: candidate, month: month, day: day)),
               date >= today {
                return date
            }
        }
        return nil
    }

    func isToday(_ now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.component(.month, from: now) == month && calendar.component(.day, from: now) == day
    }

    /// "11 February"
    var dateLabel: String {
        let symbols = Calendar.current.monthSymbols
        let monthName = symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
        return "\(day) \(monthName)"
    }

    /// "11 FEB"
    var shortDateLabel: String {
        let symbols = Calendar.current.shortMonthSymbols
        let monthName = symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
        return "\(day) \(monthName.uppercased())"
    }

    /// Said beneath a feast the Missal cannot open, so a day with no
    /// Mass door never reads as a door that failed to draw — Kolbe, Padre
    /// Pio and St. Carlo were raised to the altars after 1962
    var calendarNote: String? {
        inMissal ? nil : "Not on the universal 1962 calendar, so the Missal has no Mass for it"
    }
}

/// Where an entry leads, beyond its own words
enum ReadingDoor: Hashable {
    /// The mysteries this truth is prayed in
    case mysteries(MysteryCategory, note: String)

    /// A bundled prayer (`BilingualConsecrationPrayers.allPrayers`)
    case prayer(id: String, note: String)

    /// A page of the app, drawn with its own glyph and words
    case page(AppRoute, icon: String, title: String, note: String)

    /// A devotional act, run the way the Pray tray runs it — today's
    /// Rosary straight to prayer, the day's Mass
    case act(PrayerShortcut, note: String)
}

struct ReadingQuote: Hashable {
    let text: String
    let citation: String
}

struct LibraryReading: Identifiable, Hashable {
    let id: String
    let title: String

    /// The date, council, place or witness — one line under the title
    let detail: String

    let paragraphs: [String]
    let quote: ReadingQuote?

    /// A painting from the asset catalog, hung in the arch
    var painting: String? = nil

    var feast: KeptFeast? = nil
    var doors: [ReadingDoor] = []

    /// Named parts set after the prose, each under its own heading —
    /// the marks of true devotion, one by one
    var parts: [ReadingPart] = []

    /// Lists set after the prose — a mystery and its grace, row by row
    var tables: [ReadingTable] = []
}

/// A named part of a reading: a heading in engraved caps, then prose
struct ReadingPart: Hashable {
    let title: String
    let text: String
}

/// A short two-column list under a heading: "The Annunciation — a
/// profound humility"
struct ReadingTable: Hashable {
    let title: String
    let rows: [Row]

    struct Row: Hashable {
        let label: String
        let value: String
    }

    /// Rows written "label — value", one to a line
    init(_ title: String, _ lines: String) {
        self.title = title
        self.rows = lines.split(separator: "\n").map { line in
            let parts = line.components(separatedBy: " \u{2014} ")
            return Row(label: parts[0], value: parts.dropFirst().joined(separator: " \u{2014} "))
        }
    }
}

struct ReadingShelf: Identifiable, Hashable {
    let id: String
    let icon: String
    let title: String

    /// The shelf's name in the page's left margin, broken where it reads
    /// best in narrow caps
    let marginLabel: String
    let subtitle: String
    let entries: [LibraryReading]

    /// Closing line for a shelf that only samples a larger tradition
    var footnote: String? = nil

    /// A reading's place on its shelf, "IV" — as many as a shelf holds,
    /// never a fixed table that runs out when a shelf grows
    static func numeral(_ n: Int) -> String {
        LiturgicalCalendarFormat.roman(n)
    }
}


// MARK: - Lookup

enum LibraryReadings {

    /// Every shelf of readings the app holds
    static var shelves: [ReadingShelf] {
        MarianLibraryData.sections + CarloAcutisData.shelves + [HowToPrayData.methods, HowToPrayData.questions, TrueDevotionData.teaching]
    }

    /// The shelf a reading stands on, and its place there
    static func locate(id: String) -> (section: ReadingShelf, index: Int)? {
        for shelf in shelves {
            if let index = shelf.entries.firstIndex(where: { $0.id == id }) {
                return (shelf, index)
            }
        }
        return nil
    }

    /// The page a shelf belongs to, as a door — the way home for a
    /// reading opened from Explore or How to Pray, where the kicker names
    /// only the shelf and the library it stands in is a page away.
    static func home(of shelf: ReadingShelf) -> ReadingDoor? {
        if MarianLibraryData.sections.contains(where: { $0.id == shelf.id }) {
            return .page(.marianLibrary, icon: "ch-lily", title: "The Marian Library", note: shelf.title)
        }
        if CarloAcutisData.shelves.contains(where: { $0.id == shelf.id }) {
            return .page(.carloAcutis, icon: "ch-monstrance", title: "St. Carlo Acutis", note: shelf.title)
        }
        return nil
    }
}
