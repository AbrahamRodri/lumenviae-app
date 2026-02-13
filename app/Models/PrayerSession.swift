//
//  PrayerSession.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  PRAYER SESSION - SWIFTDATA MODEL FOR TRACKING COMPLETED ROSARIES
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Each completed Rosary is stored as a PrayerSession. This enables:
//  - Streak tracking (consecutive days of prayer)
//  - Progress statistics (total Rosaries, by category)
//  - Historical view of prayer activity
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftData

// MARK: - PrayerSession

/// A record of a completed Rosary prayer session.
///
/// ## SwiftData
/// The `@Model` macro makes this class persistable with SwiftData.
/// SwiftData automatically handles:
/// - Schema generation
/// - CRUD operations
/// - Migration between schema versions
///
@Model
final class PrayerSession {

    // MARK: - Properties

    /// Unique identifier for this session
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

    /// Creates a new prayer session record.
    ///
    /// - Parameters:
    ///   - category: The mystery category that was prayed
    ///   - completedAt: When the session was completed (defaults to now)
    ///   - durationSeconds: How long the session took
    ///   - meditationType: The meditation style used
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
