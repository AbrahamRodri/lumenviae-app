//
//  ScheduleService.swift
//  Lumen Viae
//
//  Determines the featured mystery category by day of week, following the
//  traditional pre-2002 schedule. Luminous Mysteries (added 2002) are
//  available in the app but not part of the default rotation.
//
//  Future: modern schedule setting (Thursday = Luminous), liturgical calendar.
//

import Foundation

struct ScheduleService {

    // MARK: - Category Selection

    /// The mystery category for today, based on the traditional schedule.
    static func categoryForToday() -> MysteryCategory {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return categoryFor(weekday: weekday)
    }

    /// The mystery category for a Calendar weekday (1=Sunday through 7=Saturday).
    static func categoryFor(weekday: Int) -> MysteryCategory {
        switch weekday {
        case 1, 4:  // Sunday, Wednesday
            return .glorious
        case 3, 6:  // Tuesday, Friday
            return .sorrowful
        default:    // Monday, Thursday, Saturday
            return .joyful
        }
    }

    // MARK: - Day Labels

    /// Header label for the current day (e.g., "WEDNESDAY PRAYER")
    static var dayLabel: String {
        "\(dayName.uppercased()) PRAYER"
    }

    /// Current day name (e.g., "Wednesday")
    static var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}
