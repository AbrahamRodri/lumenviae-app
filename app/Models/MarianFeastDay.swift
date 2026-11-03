//
//  MarianFeastDay.swift
//  Lumen Viae
//
//  The consecration traditionally ends on a Marian feast day. The user
//  selects a feast (Day 34) and the start date is calculated 33 days prior.
//

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
            name: String(localized: "Our Lady of Lourdes", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 2,
            day: 11,
            description: String(localized: "Apparition of the Immaculate Virgin Mary at Lourdes", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Mar 25 - The Annunciation (Start: Feb 20)
        MarianFeastDay(
            id: "annunciation",
            name: String(localized: "The Annunciation", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 3,
            day: 25,
            description: String(localized: "The Angel Gabriel announces to Mary", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Jul 16 - Our Lady of Mt. Carmel (Start: Jun 13)
        MarianFeastDay(
            id: "mount_carmel",
            name: String(localized: "Our Lady of Mt. Carmel", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 7,
            day: 16,
            description: String(localized: "Our Lady of Mount Carmel", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Aug 15 - The Assumption (Start: Jul 13)
        MarianFeastDay(
            id: "assumption",
            name: String(localized: "The Assumption", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 8,
            day: 15,
            description: String(localized: "Mary is assumed into Heaven", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Sep 8 - Nativity of Mary (Start: Aug 6)
        MarianFeastDay(
            id: "nativity_mary",
            name: String(localized: "Nativity of the Blessed Virgin Mary", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 9,
            day: 8,
            description: String(localized: "The birth of the Blessed Virgin", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Sep 15 - Our Lady of Sorrows (Start: Aug 13)
        MarianFeastDay(
            id: "sorrows",
            name: String(localized: "Our Lady of Sorrows", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 9,
            day: 15,
            description: String(localized: "Our Lady of Sorrows", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Nov 21 - Presentation of Mary (Start: Oct 19)
        MarianFeastDay(
            id: "presentation_mary",
            name: String(localized: "Presentation of the Blessed Virgin Mary", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 11,
            day: 21,
            description: String(localized: "Mary presented in the Temple", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Dec 8 - Immaculate Conception (Start: Nov 5)
        MarianFeastDay(
            id: "immaculate_conception",
            name: String(localized: "Immaculate Conception", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 12,
            day: 8,
            description: String(localized: "Mary conceived without sin", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
        ),
        // Dec 12 - Our Lady of Guadalupe (Start: Nov 9)
        MarianFeastDay(
            id: "guadalupe",
            name: String(localized: "Our Lady of Guadalupe", comment: "Consecration feast chooser: name of a feast of Our Lady the 33-day preparation can end on"),
            month: 12,
            day: 12,
            description: String(localized: "Our Lady of Guadalupe", comment: "Consecration feast chooser: one short line saying what the feast of Our Lady remembers")
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

    /// Find a feast day by ID
    static func find(_ id: String) -> MarianFeastDay? {
        all.first { $0.id == id }
    }
}

// MARK: - FeastPreparation

/// One feast's next preparation that can still be begun on its first day:
/// Day 1, thirty-three days before the feast, and the feast itself, which
/// is Consecration Day.
struct FeastPreparation: Identifiable, Hashable {
    let feast: MarianFeastDay

    /// Day 1, at the start of its day
    let start: Date

    /// Consecration Day: the feast
    let feastDate: Date

    var id: String { feast.id }

    /// Whole days from today to Day 1: 0 when it is today
    func daysUntilStart(from today: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: today),
            to: start
        ).day ?? 0
    }
}

extension MarianFeastDay {

    /// This year's preparation while its Day 1 is today or later, and
    /// otherwise next year's. A preparation already under way is never
    /// offered, so every one the chooser lists begins on Day 1 and ends
    /// on its feast.
    func upcomingPreparation(from today: Date = Date()) -> FeastPreparation? {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        let year = calendar.component(.year, from: today)

        for candidate in [year, year + 1] {
            guard let feastDate = date(for: candidate),
                  let start = calendar.date(byAdding: .day, value: -33, to: feastDate) else { continue }
            let dayOne = calendar.startOfDay(for: start)
            if dayOne >= todayStart {
                return FeastPreparation(feast: self, start: dayOne, feastDate: feastDate)
            }
        }
        return nil
    }

    /// Every feast's next preparation, the soonest Day 1 first
    static func upcomingPreparations(from today: Date = Date()) -> [FeastPreparation] {
        all.compactMap { $0.upcomingPreparation(from: today) }
            .sorted { $0.start < $1.start }
    }

    /// The feast a preparation begun on `start` ends on, if it ends on one
    static func feast(endingPreparationFrom start: Date) -> MarianFeastDay? {
        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .day, value: 33, to: calendar.startOfDay(for: start)) else {
            return nil
        }
        let month = calendar.component(.month, from: end)
        let day = calendar.component(.day, from: end)
        return all.first { $0.month == month && $0.day == day }
    }
}
