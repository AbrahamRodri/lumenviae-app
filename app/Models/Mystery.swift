//
//  Mystery.swift
//  Lumen Viae
//
//  Maps to the GET /api/mysteries response (snake_case JSON keys).
//

import Foundation

/// A single mystery of the Rosary (e.g., "The Annunciation").
struct Mystery: Codable, Identifiable, Hashable {

    // MARK: - Properties

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

    enum CodingKeys: String, CodingKey {
        case id, name, category, order, description
        case daysPrayed = "days_prayed"
        case scriptureReference = "scripture_reference"
    }

    // MARK: - Computed Properties

    /// The category as a type-safe enum, nil if the string doesn't match a known value.
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// Human-readable ordinal (e.g., "First") for "The First Joyful Mystery" labels.
    var ordinalName: String {
        let ordinals = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"]
        guard order >= 1, order <= ordinals.count else { return "" }
        return ordinals[order - 1]
    }

    /// Asset catalog image name, following the `mystery_<category>_<order>` convention.
    var imageName: String {
        "mystery_\(category)_\(order)"
    }
}
