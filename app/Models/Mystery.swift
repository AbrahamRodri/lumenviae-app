//
//  Mystery.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MYSTERY MODEL - REPRESENTS A SINGLE ROSARY MYSTERY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Maps to: GET /api/mysteries response
//
//  ## The Rosary Structure
//  The Rosary consists of 4 sets of 5 mysteries each:
//  - Joyful (5 mysteries about Christ's early life)
//  - Sorrowful (5 mysteries about Christ's Passion)
//  - Glorious (5 mysteries about the Resurrection)
//  - Luminous (5 mysteries about Christ's public ministry)
//
//  ## Example API Response
//  ```json
//  {
//    "id": 1,
//    "name": "The Annunciation",
//    "category": "joyful",
//    "order": 1,
//    "days_prayed": "Monday, Saturday",
//    "description": "The Angel Gabriel announces...",
//    "scripture_reference": "Luke 1:26-38"
//  }
//  ```
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - Mystery

/// A single mystery of the Rosary (e.g., "The Annunciation").
///
/// ## Protocol Conformances
///
/// ### Codable
/// Allows encoding/decoding to/from JSON. The `CodingKeys` enum maps
/// Swift property names (camelCase) to JSON keys (snake_case).
///
/// ### Identifiable
/// Required by SwiftUI's `ForEach` to uniquely identify items.
/// Uses the `id` property we already have.
///
/// ### Hashable
/// Allows using Mystery in Sets and as Dictionary keys.
/// Also needed for `NavigationPath` and `ForEach(id: \.self)`.
///
struct Mystery: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier from the API
    let id: Int

    /// Mystery name (e.g., "The Annunciation")
    let name: String

    /// Category string from API (e.g., "joyful", "sorrowful")
    let category: String

    /// Position within the category (1-5 for standard mysteries)
    let order: Int

    /// Days this mystery is traditionally prayed (e.g., "Monday, Saturday")
    let daysPrayed: String?

    /// Brief description of the mystery
    let description: String?

    /// Bible reference (e.g., "Luke 1:26-38")
    let scriptureReference: String?

    // MARK: - Coding Keys

    /// Maps Swift property names to JSON keys.
    ///
    /// ## Why CodingKeys?
    /// Swift uses camelCase (`scriptureReference`) but the API uses
    /// snake_case (`scripture_reference`). CodingKeys bridges this gap.
    ///
    /// Properties with matching names (id, name, etc.) don't need
    /// explicit mapping - they're inferred automatically.
    enum CodingKeys: String, CodingKey {
        case id, name, category, order, description
        case daysPrayed = "days_prayed"
        case scriptureReference = "scripture_reference"
    }

    // MARK: - Computed Properties

    /// The category as a type-safe enum.
    ///
    /// Returns `nil` if the category string doesn't match any known value.
    /// This provides type safety while still accepting any API response.
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// Human-readable ordinal (e.g., "First", "Second").
    ///
    /// Used in UI to display "The First Joyful Mystery" style labels.
    var ordinalName: String {
        let ordinals = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"]
        guard order >= 1, order <= ordinals.count else { return "" }
        return ordinals[order - 1]
    }
}
