//
//  Mystery.swift
//  Lumen Viae
//
//  Maps to the GET /api/mysteries response (snake_case JSON keys).
//

import Foundation

/// A single mystery of the Rosary (e.g., "The Annunciation").
struct Mystery: nonisolated Codable, Identifiable, Hashable {

    // MARK: - Properties

    let id: Int

    /// The name as stored and sent (English, the server's or the app's own)
    let storedName: String

    /// Mystery name (e.g., "The Annunciation"), in Spanish when the app
    /// speaks Spanish (`SpanishContent`). Stored and encoded in English, so a
    /// cached copy reads right in either language.
    var name: String {
        SpanishContent.mysteryName(storedName, key: "\(category)_\(order)")
    }

    /// Category string from API (e.g., "joyful", "sorrowful")
    let category: String

    /// Position within the category (1-5 for standard mysteries)
    let order: Int

    /// Brief description of the mystery
    let description: String?

    /// Bible reference (e.g., "Luke 1:26-38")
    let scriptureReference: String?

    /// The server's `days_prayed` is not read: it carries older days
    /// than the app's schedule, and the days follow the user's own
    /// schedule besides (`daysPrayed`).
    enum CodingKeys: String, CodingKey {
        case id, category, order, description
        case storedName = "name"
        case scriptureReference = "scripture_reference"
    }

    init(id: Int, name: String, category: String, order: Int, description: String?, scriptureReference: String?) {
        self.id = id
        self.storedName = name
        self.category = category
        self.order = order
        self.description = description
        self.scriptureReference = scriptureReference
    }

    // MARK: - Computed Properties

    /// The category as a type-safe enum, nil if the string doesn't match a known value.
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// The days this mystery is prayed on the user's schedule
    /// (e.g., "Monday, Saturday, Sundays of Advent"), its set's days
    var daysPrayed: String? {
        mysteryCategory?.daysPrayed
    }

    /// Human-readable ordinal (e.g., "First") for "The First Joyful Mystery" labels.
    var ordinalName: String {
        Constants.ordinalWord(order)
    }

    /// Asset catalog image name, following the `mystery_<category>_<order>` convention.
    var imageName: String {
        "mystery_\(category)_\(order)"
    }
}
