//
//  ScheduleService.swift
//  Lumen Viae
//
//  Which mysteries the day calls for.
//
//  Two weekly schedules, chosen in Settings (`MysterySchedule`):
//
//  The traditional one, the default: Joyful on Monday and Thursday,
//  Sorrowful on Tuesday and Friday, Glorious on Wednesday and Saturday.
//  The Luminous Mysteries (added 2002) are available in the app but not
//  part of this rotation.
//
//  The modern one, St. John Paul II's (Rosarium Virginis Mariae 38):
//  Luminous on Thursday and Joyful on Saturday, the rest as above.
//
//  In both, Sunday follows the season — Joyful in Advent, Sorrowful in
//  Lent, Glorious the rest of the year. RVM gives Sunday to the Glorious
//  but leaves room for the liturgical season, and keeping the custom in
//  both means the two schedules differ only on Thursday and Saturday.
//
//  The traditional schedule is the same rule, with the same season
//  bounds, as the server's `LumenViae.LiturgicalCalendar` — the two were
//  once out of step, with Saturday Joyful here and Glorious there, and
//  the home screen, the website and `days_prayed` each said a different
//  thing. Change them together. The modern schedule is the user's own
//  choice and lives only here: the server and the website keep the
//  traditional one. Seasons are computed, not fetched: Easter by the
//  Meeus/Jones/Butcher algorithm, Lent from Ash Wednesday up to Easter,
//  Advent from the Sunday on or after November 27 through December 24.
//  Anything the user needs in order to pray has to work with no network.
//

import Foundation

// MARK: - MysterySchedule

/// Which weekly schedule the day's mysteries follow. The raw values are
/// what is stored and never change.
enum MysterySchedule: String, CaseIterable, Identifiable {
    /// The schedule before 2002, without the Luminous. The default.
    case traditional
    /// St. John Paul II's, from Rosarium Virginis Mariae (2002)
    case modern

    var id: String { rawValue }

    var title: String {
        switch self {
        case .traditional: return "Traditional"
        case .modern:      return "Modern"
        }
    }

    /// Thursday and Saturday, the two days the schedules differ on
    var detail: String {
        switch self {
        case .traditional: return "Joyful on Thursday, Glorious on Saturday"
        case .modern:      return "Luminous on Thursday, Joyful on Saturday"
        }
    }
}

struct ScheduleService {

    // MARK: - Category Selection

    /// The mystery category for today.
    static func categoryForToday() -> MysteryCategory {
        category(for: today)
    }

    /// The mystery category for a date, on the user's schedule unless
    /// another is named, with season-aware Sundays. Read in the user's
    /// calendar, so the day turns over at their midnight.
    static func category(
        for date: Date,
        calendar: Calendar = .current,
        schedule: MysterySchedule = UserSettings.shared.mysterySchedule
    ) -> MysteryCategory {
        let weekday = calendar.component(.weekday, from: date)
        return weekdayCategory(weekday, in: schedule)
            ?? sundayCategory(in: season(for: date, calendar: calendar))
    }

    /// A weekday's mysteries, as `Calendar` numbers the days (2 is
    /// Monday, 7 Saturday). Nil for Sunday, which follows the season.
    private static func weekdayCategory(_ weekday: Int, in schedule: MysterySchedule) -> MysteryCategory? {
        switch (weekday, schedule) {
        case (2, _):              return .joyful      // Monday
        case (3, _), (6, _):      return .sorrowful   // Tuesday, Friday
        case (4, _):              return .glorious    // Wednesday
        case (5, .traditional):   return .joyful      // Thursday
        case (5, .modern):        return .luminous
        case (7, .traditional):   return .glorious    // Saturday
        case (7, .modern):        return .joyful
        default:                  return nil          // Sunday
        }
    }

    // MARK: - The Week's Sets

    /// The sets a schedule's week prays, in the week's order from Monday:
    /// Joyful, Sorrowful, Glorious, and in the modern one the Luminous,
    /// Thursday's. Sunday's seasons add none the weekdays have not. The
    /// home page's grid is these, then the Seven Sorrows.
    static func weekCategories(
        in schedule: MysterySchedule = UserSettings.shared.mysterySchedule
    ) -> [MysteryCategory] {
        var sets: [MysteryCategory] = []
        for weekday in 2...7 {
            if let category = weekdayCategory(weekday, in: schedule), !sets.contains(category) {
                sets.append(category)
            }
        }
        return sets
    }

    /// Sunday's mysteries: the same in both schedules
    private static func sundayCategory(in season: Season) -> MysteryCategory {
        switch season {
        case .advent:   return .joyful
        case .lent:     return .sorrowful
        case .ordinary: return .glorious
        }
    }

    // MARK: - Days in Words

    /// The days a set is prayed on a schedule, said in words:
    /// "Monday, Thursday, Sundays of Advent". Nil for a set the schedule
    /// never reaches — the Luminous in the traditional one, the Seven
    /// Sorrows in either.
    static func daysPrayed(
        _ category: MysteryCategory,
        in schedule: MysterySchedule = UserSettings.shared.mysterySchedule
    ) -> String? {
        let weekdays = (2...7)
            .filter { weekdayCategory($0, in: schedule) == category }
            .map { weekdayNames[$0 - 1] }
        let sundays: [(Season, String)] = [
            (.ordinary, "Sunday"), (.advent, "Sundays of Advent"), (.lent, "Sundays of Lent")
        ]
        let days = weekdays + sundays
            .filter { sundayCategory(in: $0.0) == category }
            .map { $0.1 }
        return days.isEmpty ? nil : days.joined(separator: ", ")
    }

    /// Sunday first, as `Calendar` numbers them. In English, like every
    /// other word on these pages.
    private static let weekdayNames = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    // MARK: - Today

    /// Today, as the schedule reads it. A debug build can be handed
    /// another day, to see a Thursday without waiting for one:
    /// SIMCTL_CHILD_LUMEN_VIAE_TODAY=2026-10-01 xcrun simctl launch …
    static var today: Date {
        #if DEBUG
        if let debugToday { return debugToday }
        #endif
        return Date()
    }

    #if DEBUG
    private static let debugToday: Date? = {
        guard let value = ProcessInfo.processInfo.environment["LUMEN_VIAE_TODAY"],
              !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        // Noon, so the day is the one named whichever way the clock is read
        return formatter.date(from: value)?.addingTimeInterval(12 * 60 * 60)
    }()
    #endif

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
        weekdayFormatter.string(from: today)
    }
}
