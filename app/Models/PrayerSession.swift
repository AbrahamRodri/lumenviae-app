//
//  PrayerSession.swift
//  Lumen Viae
//
//  SwiftData model recording each completed Rosary, used for streaks
//  and progress statistics.
//

import Foundation
import SwiftData

@Model
final class PrayerSession {

    // MARK: - Properties

    var id: UUID

    /// When the prayer session was completed
    var completedAt: Date

    /// The mystery category prayed (stored as raw string for SwiftData compatibility)
    var categoryRaw: String

    /// Duration of the prayer session in seconds (optional)
    var durationSeconds: Int?

    /// The meditation type used (e.g., "traditional", "saint_louis_de_montfort")
    var meditationType: String?

    // MARK: - Computed Properties

    /// The mystery category as an enum
    var category: MysteryCategory? {
        MysteryCategory(rawValue: categoryRaw)
    }

    /// Formatted duration string (e.g., "12 min")
    var formattedDuration: String? {
        guard let seconds = durationSeconds else { return nil }
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    // MARK: - Initialization

    init(
        category: MysteryCategory,
        completedAt: Date = Date(),
        durationSeconds: Int? = nil,
        meditationType: String? = nil
    ) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.meditationType = meditationType
    }
}
