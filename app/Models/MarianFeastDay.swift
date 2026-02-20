//
//  MarianFeastDay.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MARIAN FEAST DAY - FEAST DAYS FOR CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  The 33-Day Consecration traditionally ends on a Marian feast day.
//  This model defines the major feast days and calculates start dates.
//
//  The user selects a feast day (Day 34), and the start date (Day 1)
//  is automatically calculated as 33 days prior.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - MarianFeastDay

/// A Marian feast day that can be used as the consecration day (Day 34)
struct MarianFeastDay: Identifiable, Hashable {

    let id: String
    let name: String
    let month: Int
    let day: Int
    let description: String

    // MARK: - Date Calculations

    /// Get the feast day date for a given year
    func date(for year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    /// Get the start date (Day 1) for this feast day in a given year
    /// The consecration is 33 days + 1 consecration day = 34 total
    /// So Day 1 starts 33 days before the feast
    func startDate(for year: Int) -> Date? {
        guard let feastDate = date(for: year) else { return nil }
        return Calendar.current.date(byAdding: .day, value: -33, to: feastDate)
    }

    /// Get the next occurrence of this feast day from today
    func nextOccurrence(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)

        // Try this year first
        if let thisYear = self.date(for: currentYear), thisYear > date {
            return thisYear
        }

        // Otherwise next year
        return self.date(for: currentYear + 1)
    }

    /// Get the start date for the next available consecration
    func nextStartDate(from date: Date = Date()) -> Date? {
        guard let nextFeast = nextOccurrence(from: date) else { return nil }
        return Calendar.current.date(byAdding: .day, value: -33, to: nextFeast)
    }

    /// Check if today is a valid start date for this feast day
    func isValidStartDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)

        // Check both this year and next year
        for year in [currentYear, currentYear + 1] {
            if let startDate = startDate(for: year) {
                if calendar.isDate(date, inSameDayAs: startDate) {
                    return true
                }
            }
        }
        return false
    }

    /// Whether this feast day is available to start today
    func canStartToday(from today: Date = Date()) -> Bool {
        guard let start = nextStartDate(from: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today) else {
            return false
        }
        return Calendar.current.isDate(start, inSameDayAs: today)
    }
}

// MARK: - Feast Day Data

extension MarianFeastDay {

    /// All major Marian feast days traditionally used for consecration
    /// Ordered by calendar date (Jan-Dec)
    /// Start dates: Feast date - 33 days
    static let all: [MarianFeastDay] = [
        // Feb 11 - Our Lady of Lourdes (Start: Jan 9)
        MarianFeastDay(
            id: "lourdes",
            name: "Our Lady of Lourdes",
            month: 2,
            day: 11,
            description: "Apparition of the Immaculate Virgin Mary at Lourdes"
        ),
        // Mar 25 - The Annunciation (Start: Feb 20)
        MarianFeastDay(
            id: "annunciation",
            name: "The Annunciation",
            month: 3,
            day: 25,
            description: "The Angel Gabriel announces to Mary"
        ),
        // Jul 16 - Our Lady of Mt. Carmel (Start: Jun 13)
        MarianFeastDay(
            id: "mount_carmel",
            name: "Our Lady of Mt. Carmel",
            month: 7,
            day: 16,
            description: "Our Lady of Mount Carmel"
        ),
        // Aug 15 - The Assumption (Start: Jul 13)
        MarianFeastDay(
            id: "assumption",
            name: "The Assumption",
            month: 8,
            day: 15,
            description: "Mary is assumed into Heaven"
        ),
        // Sep 8 - Nativity of Mary (Start: Aug 6)
        MarianFeastDay(
            id: "nativity_mary",
            name: "Nativity of the Blessed Virgin Mary",
            month: 9,
            day: 8,
            description: "The birth of the Blessed Virgin"
        ),
        // Sep 15 - Our Lady of Sorrows (Start: Aug 13)
        MarianFeastDay(
            id: "sorrows",
            name: "Our Lady of Sorrows",
            month: 9,
            day: 15,
            description: "Our Lady of Sorrows"
        ),
        // Nov 21 - Presentation of Mary (Start: Oct 19)
        MarianFeastDay(
            id: "presentation_mary",
            name: "Presentation of the Blessed Virgin Mary",
            month: 11,
            day: 21,
            description: "Mary presented in the Temple"
        ),
        // Dec 8 - Immaculate Conception (Start: Nov 5)
        MarianFeastDay(
            id: "immaculate_conception",
            name: "Immaculate Conception",
            month: 12,
            day: 8,
            description: "Mary conceived without sin"
        ),
        // Dec 12 - Our Lady of Guadalupe (Start: Nov 9)
        MarianFeastDay(
            id: "guadalupe",
            name: "Our Lady of Guadalupe",
            month: 12,
            day: 12,
            description: "Our Lady of Guadalupe"
        )
    ]

    /// Get feast days sorted by next occurrence
    static func sortedByNextOccurrence(from date: Date = Date()) -> [MarianFeastDay] {
        all.sorted { feast1, feast2 in
            guard let next1 = feast1.nextOccurrence(from: date),
                  let next2 = feast2.nextOccurrence(from: date) else {
                return false
            }
            return next1 < next2
        }
    }

    /// Get feast days that can be started today
    static func availableToday(from date: Date = Date()) -> [MarianFeastDay] {
        all.filter { $0.canStartToday(from: date) }
    }

    /// Find a feast day by ID
    static func find(_ id: String) -> MarianFeastDay? {
        all.first { $0.id == id }
    }
}
