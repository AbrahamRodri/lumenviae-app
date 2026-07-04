//
//  MeditationSet.swift
//  Lumen Viae
//
//  A meditation set groups 5 meditations (one per mystery) under a theme,
//  e.g. "Traditional Meditations" for the Joyful mysteries.
//
//  - List: GET /api/meditation-sets?category=joyful → [MeditationSetSummary]
//  - Detail: GET /api/meditation-sets/:id → MeditationSet (with meditations)
//

import Foundation

// MARK: - MeditationSet

/// A complete meditation set with all meditations included (detail endpoint).
struct MeditationSet: Codable, Identifiable, Hashable {

    // MARK: - Properties

    let id: Int

    /// Set name (e.g., "Traditional Meditations")
    let name: String

    /// Category string (e.g., "joyful")
    let category: String

    /// Optional description of this meditation style
    let description: String?

    /// Descriptive labels for browsing/filtering (e.g., ["Saints", "Marian"]).
    /// The first label is the set's primary group. Optional — absent until
    /// the API sends it, in which case the picker shows a flat list.
    let labels: [String]?

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

/// A meditation set without the meditations array (list endpoint).
/// When the user selects one, fetch the full MeditationSet by ID.
struct MeditationSetSummary: Codable, Identifiable, Hashable {

    // MARK: - Properties

    let id: Int

    /// Set name (e.g., "St. Louis de Montfort")
    let name: String

    /// Category string (e.g., "sorrowful")
    let category: String

    /// Optional description
    let description: String?

    /// Descriptive labels for browsing/filtering (e.g., ["Saints", "Marian"]).
    /// The first label is the set's primary group; nil until the API sends it.
    let labels: [String]?

    // MARK: - Computed Properties

    /// Type-safe category enum
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// The label this set is grouped under when browsing unfiltered
    var primaryLabel: String? {
        labels?.first
    }
}
