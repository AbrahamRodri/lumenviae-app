//
//  ScheduleService.swift
//  Lumen Viae
//
//  Which mysteries the day calls for.
//
//  The traditional weekly schedule: Joyful on Monday and Thursday,
//  Sorrowful on Tuesday and Friday, Glorious on Wednesday and Saturday,
//  and Sunday by the season — Joyful in Advent, Sorrowful in Lent,
//  Glorious the rest of the year. The Luminous Mysteries (added 2002) are
//  available in the app but not part of this rotation.
//
//  This is the same rule, with the same season bounds, as the server's
//  `LumenViae.LiturgicalCalendar` — the two were once out of step, with
//  Saturday Joyful here and Glorious there, and the home screen, the
//  website and `days_prayed` each said a different thing. Change them
//  together. Seasons are computed, not fetched: Easter by the
//  Meeus/Jones/Butcher algorithm, Lent from Ash Wednesday up to Easter,
//  Advent from the Sunday on or after November 27 through December 24.
//  Anything the user needs in order to pray has to work with no network.
//
//  Future: a Traditional/Modern setting (Thursday = Luminous).
//

import Foundation

struct ScheduleService {

    // MARK: - Category Selection

    /// The mystery category for today.
    static func categoryForToday() -> MysteryCategory {
        category(for: Date())
    }

    /// The mystery category for a date, following the traditional schedule
    /// with season-aware Sundays. Read in the user's calendar, so the day
    /// turns over at their midnight.
    static func category(for date: Date, calendar: Calendar = .current) -> MysteryCategory {
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1:     // Sunday
            return sundayCategory(for: date, calendar: calendar)
        case 4, 7:  // Wednesday, Saturday
            return .glorious
        case 3, 6:  // Tuesday, Friday
            return .sorrowful
        default:    // Monday, Thursday
            return .joyful
        }
    }

    private static func sundayCategory(for date: Date, calendar: Calendar) -> MysteryCategory {
        switch season(for: date, calendar: calendar) {
        case .advent:   return .joyful
        case .lent:     return .sorrowful
        case .ordinary: return .glorious
        }
    }

    // MARK: - Seasons

    /// The seasons the Rosary schedule distinguishes. `ordinary` means
    /// "not Advent or Lent" for this purpose — it is not the liturgical
    /// Tempus per Annum, and it deliberately folds Christmastide and
    /// Eastertide in, as the server does.
    enum Season {
        case advent, lent, ordinary
    }

    static func season(for date: Date, calendar: Calendar = .current) -> Season {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)

        if let ash = ashWednesday(year: year, calendar: calendar),
           let easter = easterSunday(year: year, calendar: calendar),
           day >= ash, day < easter {
            return .lent
        }

        if let start = adventStart(year: year, calendar: calendar),
           let eve = calendar.date(from: DateComponents(year: year, month: 12, day: 24)),
           day >= start, day <= eve {
            return .advent
        }

        return .ordinary
    }

    /// Easter Sunday for a year (Gregorian; Meeus/Jones/Butcher).
    static func easterSunday(year: Int, calendar: Calendar = .current) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = (h + l - 7 * m + 114) % 31 + 1
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// Ash Wednesday: 46 days before Easter.
    static func ashWednesday(year: Int, calendar: Calendar = .current) -> Date? {
        easterSunday(year: year, calendar: calendar).flatMap {
            calendar.date(byAdding: .day, value: -46, to: $0)
        }
    }

    /// The First Sunday of Advent: the Sunday on or after November 27.
    static func adventStart(year: Int, calendar: Calendar = .current) -> Date? {
        guard let nov27 = calendar.date(from: DateComponents(year: year, month: 11, day: 27)) else {
            return nil
        }
        let weekday = calendar.component(.weekday, from: nov27)  // 1 = Sunday
        let daysUntilSunday = (8 - weekday) % 7
        return calendar.date(byAdding: .day, value: daysUntilSunday, to: nov27)
    }

    // MARK: - Day Labels

    /// Header label for the current day (e.g., "WEDNESDAY PRAYER")
    static var dayLabel: String {
        "\(dayName.uppercased()) PRAYER"
    }

    /// Reused: `DateFormatter` init is expensive, and `dayName` is reached
    /// from the home header on every render.
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }()

    /// Current day name (e.g., "Wednesday")
    static var dayName: String {
        weekdayFormatter.string(from: Date())
    }
}
