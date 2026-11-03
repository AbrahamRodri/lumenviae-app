//
//  ConsecrationDay.swift
//  Lumen Viae
//
//  A single day of the 33-Day Consecration: title/theme, meditation text,
//  and a journal prompt. Daily prayers come from the phase, not the day.
//

import Foundation

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

    /// The day's readings, in the order the plan prescribes them. Most
    /// days have two — a Gospel passage and a spiritual reading — each
    /// with its own citation and attribution.
    let readings: [ConsecrationReading]

    /// Reflection prompt for journaling
    let journalPrompt: String

    // MARK: - Readings

    /// Whether the day asks for more than one reading, which is what the
    /// reading card uses to decide between a single page and a carousel.
    var hasMultipleReadings: Bool { readings.count > 1 }

    // MARK: - Single-Reading Compatibility
    //
    // The meditation and journal screens still present a day as one
    // continuous page. These give them that view of it without a second
    // copy of the text: the readings run together under the ornament rule
    // `ReadingText` already draws for `─────`.

    /// Every reading's citation, joined — "Luke 13:1-5 & True Devotion, Nos. 81-82"
    var meditationTitle: String {
        readings.map(\.title).joined(separator: " & ")
    }

    // MARK: - Computed Properties

    /// Get the prayers for this day (based on the phase)
    /// Prayers are the same each day within a phase
    var prayerIds: [String] {
        phase.prayerIds
    }

    /// Human-readable day label (e.g., "Day 7 of 33")
    var dayLabel: String {
        if dayNumber == 34 {
            return String(localized: "Consecration Day", comment: "Consecration: label of day 34, when the act of consecration is made")
        }
        return String(localized: "Day \(dayNumber) of 33", comment: "Consecration: label of one day of the 33-day preparation, like Day 7 of 33")
    }

    /// Ordinal representation (e.g., "First Day", "Twelfth Day")
    var ordinalLabel: String {
        // One phrase per day, so a language can put the ordinal where it belongs
        let ordinals = [
            String(localized: "First Day", comment: "Consecration: heading naming day 1 of the preparation by its ordinal"),
            String(localized: "Second Day", comment: "Consecration: heading naming day 2 of the preparation by its ordinal"),
            String(localized: "Third Day", comment: "Consecration: heading naming day 3 of the preparation by its ordinal"),
            String(localized: "Fourth Day", comment: "Consecration: heading naming day 4 of the preparation by its ordinal"),
            String(localized: "Fifth Day", comment: "Consecration: heading naming day 5 of the preparation by its ordinal"),
            String(localized: "Sixth Day", comment: "Consecration: heading naming day 6 of the preparation by its ordinal"),
            String(localized: "Seventh Day", comment: "Consecration: heading naming day 7 of the preparation by its ordinal"),
            String(localized: "Eighth Day", comment: "Consecration: heading naming day 8 of the preparation by its ordinal"),
            String(localized: "Ninth Day", comment: "Consecration: heading naming day 9 of the preparation by its ordinal"),
            String(localized: "Tenth Day", comment: "Consecration: heading naming day 10 of the preparation by its ordinal"),
            String(localized: "Eleventh Day", comment: "Consecration: heading naming day 11 of the preparation by its ordinal"),
            String(localized: "Twelfth Day", comment: "Consecration: heading naming day 12 of the preparation by its ordinal"),
            String(localized: "Thirteenth Day", comment: "Consecration: heading naming day 13 of the preparation by its ordinal"),
            String(localized: "Fourteenth Day", comment: "Consecration: heading naming day 14 of the preparation by its ordinal"),
            String(localized: "Fifteenth Day", comment: "Consecration: heading naming day 15 of the preparation by its ordinal"),
            String(localized: "Sixteenth Day", comment: "Consecration: heading naming day 16 of the preparation by its ordinal"),
            String(localized: "Seventeenth Day", comment: "Consecration: heading naming day 17 of the preparation by its ordinal"),
            String(localized: "Eighteenth Day", comment: "Consecration: heading naming day 18 of the preparation by its ordinal"),
            String(localized: "Nineteenth Day", comment: "Consecration: heading naming day 19 of the preparation by its ordinal"),
            String(localized: "Twentieth Day", comment: "Consecration: heading naming day 20 of the preparation by its ordinal"),
            String(localized: "Twenty-First Day", comment: "Consecration: heading naming day 21 of the preparation by its ordinal"),
            String(localized: "Twenty-Second Day", comment: "Consecration: heading naming day 22 of the preparation by its ordinal"),
            String(localized: "Twenty-Third Day", comment: "Consecration: heading naming day 23 of the preparation by its ordinal"),
            String(localized: "Twenty-Fourth Day", comment: "Consecration: heading naming day 24 of the preparation by its ordinal"),
            String(localized: "Twenty-Fifth Day", comment: "Consecration: heading naming day 25 of the preparation by its ordinal"),
            String(localized: "Twenty-Sixth Day", comment: "Consecration: heading naming day 26 of the preparation by its ordinal"),
            String(localized: "Twenty-Seventh Day", comment: "Consecration: heading naming day 27 of the preparation by its ordinal"),
            String(localized: "Twenty-Eighth Day", comment: "Consecration: heading naming day 28 of the preparation by its ordinal"),
            String(localized: "Twenty-Ninth Day", comment: "Consecration: heading naming day 29 of the preparation by its ordinal"),
            String(localized: "Thirtieth Day", comment: "Consecration: heading naming day 30 of the preparation by its ordinal"),
            String(localized: "Thirty-First Day", comment: "Consecration: heading naming day 31 of the preparation by its ordinal"),
            String(localized: "Thirty-Second Day", comment: "Consecration: heading naming day 32 of the preparation by its ordinal"),
            String(localized: "Thirty-Third Day", comment: "Consecration: heading naming day 33 of the preparation by its ordinal"),
            String(localized: "Thirty-Fourth Day", comment: "Consecration: heading naming day 34 of the preparation by its ordinal"),
        ]
        guard dayNumber >= 1, dayNumber <= ordinals.count else { return "" }
        return ordinals[dayNumber - 1]
    }

    /// Day number within the current phase (e.g., Day 13 overall = Day 1 of Week 1)
    var dayWithinPhase: Int {
        dayNumber - phase.dayRange.lowerBound + 1
    }

    /// Whether this is the final consecration day
    var isConsecrationDay: Bool {
        dayNumber == 34
    }
}
