//
//  ScheduleService.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  SCHEDULE SERVICE - DETERMINES DAILY MYSTERY CATEGORY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Determines which mystery category should be featured based on the current
//  day of the week, following the traditional pre-2002 Rosary schedule.
//
//  ## Traditional Schedule (Pre-2002)
//
//  | Day       | Weekday | Mystery    |
//  |-----------|---------|------------|
//  | Sunday    | 1       | Glorious   |
//  | Monday    | 2       | Joyful     |
//  | Tuesday   | 3       | Sorrowful  |
//  | Wednesday | 4       | Glorious   |
//  | Thursday  | 5       | Joyful     |
//  | Friday    | 6       | Sorrowful  |
//  | Saturday  | 7       | Joyful     |
//
//  Note: Luminous Mysteries (added by Pope John Paul II in 2002) are available
//  in the app but not part of the default daily rotation.
//
//  ## Future Enhancements
//  - Modern schedule setting (Thursday = Luminous)
//  - Liturgical calendar integration
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - ScheduleService

/// Service for determining which mystery to pray based on day of week.
///
/// ## Why a struct with static methods?
/// This service has no state - it just provides pure functions that
/// compute the schedule. Using static methods makes it simple to call
/// (`ScheduleService.categoryForToday()`) without creating instances.
///
struct ScheduleService {

    // MARK: - Category Selection

    /// Returns the mystery category for today.
    ///
    /// Uses `Calendar.current.component(.weekday)` to get the day:
    /// - 1 = Sunday, 2 = Monday, ... 7 = Saturday
    ///
    /// - Returns: Today's MysteryCategory based on traditional schedule
    static func categoryForToday() -> MysteryCategory {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return categoryFor(weekday: weekday)
    }

    /// Returns the mystery category for a specific weekday number.
    ///
    /// - Parameter weekday: Calendar weekday (1=Sunday through 7=Saturday)
    /// - Returns: The appropriate MysteryCategory
    ///
    /// ## Schedule Logic
    /// - Glorious: Sunday (1), Wednesday (4) - Resurrection themes
    /// - Joyful: Monday (2), Thursday (5), Saturday (7) - Birth/childhood
    /// - Sorrowful: Tuesday (3), Friday (6) - Passion themes
    static func categoryFor(weekday: Int) -> MysteryCategory {
        switch weekday {
        case 1, 4:  // Sunday, Wednesday → Glorious
            return .glorious
        case 2, 5:  // Monday, Thursday → Joyful
            return .joyful
        case 3, 6:  // Tuesday, Friday → Sorrowful
            return .sorrowful
        case 7:     // Saturday → Joyful
            return .joyful
        default:
            return .joyful  // Fallback (shouldn't happen)
        }
    }

    // MARK: - Day Labels

    /// Formatted label for the current day (e.g., "WEDNESDAY PRAYER").
    ///
    /// Used in the home screen header to show what day's prayer it is.
    static var dayLabel: String {
        "\(dayName.uppercased()) PRAYER"
    }

    /// Current day name (e.g., "Wednesday").
    ///
    /// Uses "EEEE" date format which gives the full weekday name.
    static var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"  // Full weekday name
        return formatter.string(from: Date())
    }
}
