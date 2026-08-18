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

// MARK: - Label Display

/// How API labels are worded in the picker.
///
/// Labels are matched and filtered as the raw, case-sensitive strings the
/// API sends — this only changes what the user reads, so the app never has
/// to wait on a backend relabel to say something better.
enum MeditationLabel {

    private static let displayNames: [String: String] = [
        "Considerations": "Reflections"
    ]

    /// The user-facing wording for an API label.
    static func displayName(_ label: String) -> String {
        displayNames[label] ?? label
    }

    /// A set's labels as one tracked line — "SAINTS  ·  REFLECTIONS" — the
    /// way every shelf and hero renders them.
    static func displayLine(_ labels: [String]) -> String {
        labels.map(displayName).joined(separator: "  ·  ").uppercased()
    }
}

// MARK: - MeditationSet

/// A complete meditation set with all meditations included (detail endpoint).
///
/// The `Codable` conformance is `nonisolated` — the module defaults to
/// `@MainActor`, but offline reads decode these off the main actor.
struct MeditationSet: nonisolated Codable, Identifiable, Hashable {

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
struct MeditationSetSummary: nonisolated Codable, Identifiable, Hashable {

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
