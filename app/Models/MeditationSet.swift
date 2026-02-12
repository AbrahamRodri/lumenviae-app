//
//  MeditationSet.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MEDITATION SET - A COLLECTION OF MEDITATIONS FOR A CATEGORY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A MeditationSet groups 5 meditations (one per mystery) under a theme.
//  For example, "Traditional Meditations" for Joyful mysteries contains
//  5 traditional meditations for the 5 Joyful mysteries.
//
//  ## API Endpoints
//  - List: GET /api/meditation-sets?category=joyful → [MeditationSetSummary]
//  - Detail: GET /api/meditation-sets/1 → MeditationSet (with meditations)
//
//  ## Why Two Structs?
//  The list endpoint returns summary data (no meditations array) while
//  the detail endpoint returns the full set with all meditations.
//  Using separate structs prevents accidentally accessing nil meditations.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - MeditationSet

/// A complete meditation set with all meditations included.
///
/// Used when fetching a specific set from GET /api/meditation-sets/:id.
/// Contains the full array of Meditation objects.
///
/// ## Example
/// ```
/// MeditationSet
/// ├── name: "Traditional Meditations"
/// ├── category: "joyful"
/// └── meditations: [
///       Meditation (The Annunciation),
///       Meditation (The Visitation),
///       Meditation (The Nativity),
///       Meditation (The Presentation),
///       Meditation (Finding Jesus in the Temple)
///     ]
/// ```
struct MeditationSet: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: Int

    /// Set name (e.g., "Traditional Meditations")
    let name: String

    /// Category string (e.g., "joyful")
    let category: String

    /// Optional description of this meditation style
    let description: String?

    /// Array of meditations, one per mystery (5 for standard Rosary).
    /// Optional because list endpoint doesn't include this.
    let meditations: [Meditation]?

    // MARK: - Computed Properties

    /// Type-safe category enum, or nil if category string is invalid
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// Whether any meditation in this set has audio available
    var hasAudio: Bool {
        meditations?.contains { $0.hasAudio } ?? false
    }

    /// Number of meditations (typically 5)
    var meditationCount: Int {
        meditations?.count ?? 0
    }
}

// MARK: - MeditationSetSummary

/// A summary of a meditation set WITHOUT the meditations array.
///
/// Used when listing available sets from GET /api/meditation-sets?category=.
/// Lighter weight than MeditationSet since it doesn't include all content.
///
/// When the user selects a set, fetch the full MeditationSet by ID.
struct MeditationSetSummary: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: Int

    /// Set name (e.g., "St. Louis de Montfort")
    let name: String

    /// Category string (e.g., "sorrowful")
    let category: String

    /// Optional description
    let description: String?

    // MARK: - Computed Properties

    /// Type-safe category enum
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }
}
