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

    /// Total reading time for the day, summed from the per-reading
    /// estimates counted when the readings were built.
    var estimatedMinutes: Int {
        readings.reduce(0) { $0 + $1.estimatedMinutes }
    }

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

    /// The readings run together, separated by the ornament rule
    var meditationText: String {
        readings.map(\.text).joined(separator: "\n\n─────\n\n")
    }

    /// Every distinct work the day draws on, in order of appearance
    var meditationSource: String? {
        var seen: Set<String> = []
        let works = readings.compactMap(\.source).filter { seen.insert($0).inserted }
        return works.isEmpty ? nil : works.joined(separator: " & ")
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
