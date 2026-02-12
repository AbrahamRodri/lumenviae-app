//
//  MeditationSet.swift
//  app
//
//  Represents a collection of meditations for a mystery category.
//  Maps to: GET /api/meditation-sets and GET /api/meditation-sets/:id
//

import Foundation

/// A set of meditations (e.g., "Traditional Meditations" for Joyful mysteries)
struct MeditationSet: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: String
    let description: String?
    let meditations: [Meditation]?  // Only populated in detail endpoint

    /// The mystery category as an enum (if valid)
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// Whether any meditation in this set has audio
    var hasAudio: Bool {
        meditations?.contains { $0.hasAudio } ?? false
    }

    /// Number of meditations in this set
    var meditationCount: Int {
        meditations?.count ?? 0
    }
}

/// Summary version for list endpoints (no meditations array)
struct MeditationSetSummary: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: String
    let description: String?

    /// The mystery category as an enum (if valid)
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }
}
