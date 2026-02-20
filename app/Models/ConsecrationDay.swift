//
//  ConsecrationDay.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION DAY - REPRESENTS A SINGLE DAY OF THE 33-DAY CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Each of the 34 days has unique content:
//  - A title/theme for the day
//  - Meditation text (spiritual writings that vary daily)
//  - A journal prompt for reflection
//
//  The prayers for each day come from the phase, not stored per-day.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - ConsecrationDay

/// Represents a single day of the 33-Day Consecration journey.
///
/// Each day includes:
/// - Unique meditation content (spiritual writings)
/// - Journal prompt for reflection
/// - Phase-based prayers (derived from the phase)
///
struct ConsecrationDay: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier (same as day number for simplicity)
    var id: Int { dayNumber }

    /// Day number (1-34)
    let dayNumber: Int

    /// Phase this day belongs to
    let phase: ConsecrationPhase

    /// Title/theme for the day (e.g., "Renouncing the Spirit of the World")
    let title: String

    /// Title of today's meditation/spiritual reading
    let meditationTitle: String

    /// The spiritual writing/meditation text for this day
    /// Note: Content varies every day - this is NOT the same as prayers
    let meditationText: String

    /// Source attribution for the meditation (e.g., "True Devotion, Ch. 3")
    let meditationSource: String?

    /// Reflection prompt for journaling
    let journalPrompt: String

    // MARK: - Computed Properties

    /// Get the prayers for this day (based on the phase)
    /// Prayers are the same each day within a phase
    var prayerIds: [String] {
        phase.prayerIds
    }

    /// Human-readable day label (e.g., "Day 7 of 33")
    var dayLabel: String {
        if dayNumber == 34 {
            return "Consecration Day"
        }
        return "Day \(dayNumber) of 33"
    }

    /// Ordinal representation (e.g., "First Day", "Twelfth Day")
    var ordinalLabel: String {
        let ordinals = [
            "First", "Second", "Third", "Fourth", "Fifth",
            "Sixth", "Seventh", "Eighth", "Ninth", "Tenth",
            "Eleventh", "Twelfth", "Thirteenth", "Fourteenth", "Fifteenth",
            "Sixteenth", "Seventeenth", "Eighteenth", "Nineteenth", "Twentieth",
            "Twenty-First", "Twenty-Second", "Twenty-Third", "Twenty-Fourth", "Twenty-Fifth",
            "Twenty-Sixth", "Twenty-Seventh", "Twenty-Eighth", "Twenty-Ninth", "Thirtieth",
            "Thirty-First", "Thirty-Second", "Thirty-Third", "Thirty-Fourth"
        ]
        guard dayNumber >= 1, dayNumber <= ordinals.count else { return "" }
        return "\(ordinals[dayNumber - 1]) Day"
    }

    /// Day number within the current phase (e.g., Day 13 overall = Day 1 of Week 1)
    var dayWithinPhase: Int {
        dayNumber - phase.dayRange.lowerBound + 1
    }

    /// Progress through the current phase (0.0 to 1.0)
    var phaseProgress: Double {
        Double(dayWithinPhase) / Double(phase.dayCount)
    }

    /// Overall consecration progress (0.0 to 1.0)
    var overallProgress: Double {
        Double(dayNumber) / 34.0
    }

    /// Whether this is the final consecration day
    var isConsecrationDay: Bool {
        dayNumber == 34
    }
}
