//
//  ScheduleService.swift
//  app
//
//  Determines which mystery category to display based on the current day.
//  Uses the traditional pre-2002 schedule (Luminous not in daily rotation).
//

import Foundation

/// Service for determining the mystery schedule based on day of week
struct ScheduleService {
    /// Get the mystery category for today based on traditional schedule
    /// - Returns: The MysteryCategory that should be featured today
    static func categoryForToday() -> MysteryCategory {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return categoryFor(weekday: weekday)
    }

    /// Get the mystery category for a specific weekday
    /// - Parameter weekday: Calendar weekday (1=Sunday, 2=Monday, ... 7=Saturday)
    /// - Returns: The appropriate MysteryCategory
    static func categoryFor(weekday: Int) -> MysteryCategory {
        // Traditional pre-2002 schedule (Luminous available but not in rotation)
        switch weekday {
        case 1, 4:      // Sunday, Wednesday
            return .glorious
        case 2, 5:      // Monday, Thursday
            return .joyful
        case 3, 6:      // Tuesday, Friday
            return .sorrowful
        case 7:         // Saturday
            return .joyful
        default:
            return .joyful
        }
    }

    /// Get a formatted label for the current day (e.g., "WEDNESDAY PRAYER")
    static var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()).uppercased() + " PRAYER"
    }

    /// Get the day name for display (e.g., "Wednesday")
    static var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}
