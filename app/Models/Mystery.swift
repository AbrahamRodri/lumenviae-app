//
//  Mystery.swift
//  app
//
//  Represents a single mystery from the API.
//  Maps to: GET /api/mysteries response
//

import Foundation

/// A single mystery of the Rosary (e.g., "The Annunciation")
struct Mystery: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: String
    let order: Int
    let daysPrayed: String?
    let description: String?
    let scriptureReference: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, order, description
        case daysPrayed = "days_prayed"
        case scriptureReference = "scripture_reference"
    }

    /// The mystery category as an enum (if valid)
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// Ordinal name (First, Second, etc.)
    var ordinalName: String {
        let ordinals = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"]
        guard order >= 1 && order <= ordinals.count else { return "" }
        return ordinals[order - 1]
    }
}
