//
//  MysteryCategory.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MYSTERY CATEGORY - THE FOUR TYPES OF ROSARY MYSTERIES
//  ═══════════════════════════════════════════════════════════════════════════
//
//  The Rosary is organized into four categories, each containing five
//  mysteries. This enum represents those categories with associated
//  display properties (colors, icons, days).
//
//  ## The Four Categories
//
//  | Category   | Theme             | Days (Traditional) |
//  |------------|-------------------|-------------------|
//  | Joyful     | The Incarnation   | Mon, Sat          |
//  | Sorrowful  | The Passion       | Tue, Fri          |
//  | Glorious   | The Resurrection  | Wed, Sun          |
//  | Luminous   | The Light (2002)  | Thu               |
//
//  Note: Luminous mysteries were added by Pope John Paul II in 2002.
//  The traditional pre-2002 schedule doesn't include them in daily rotation.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - MysteryCategory

/// The four types of Rosary mysteries.
///
/// ## Protocol Conformances
///
/// ### String RawValue
/// Each case has a string raw value matching the API (e.g., `"joyful"`).
/// This enables easy JSON encoding/decoding.
///
/// ### Codable
/// Automatic JSON encoding/decoding using the raw value string.
///
/// ### CaseIterable
/// Provides `MysteryCategory.allCases` array for iterating all categories.
/// Used by the home screen's mystery grid.
///
/// ### Hashable
/// Allows using in Sets, Dictionaries, and NavigationPath.
///
enum MysteryCategory: String, Codable, CaseIterable, Hashable {

    // MARK: - Cases

    case joyful
    case sorrowful
    case glorious
    case luminous

    // MARK: - Display Properties

    /// Human-readable name (e.g., "Joyful")
    var displayName: String {
        rawValue.capitalized
    }

    /// Subtitle describing the theological theme of this category
    var subtitle: String {
        switch self {
        case .joyful:    return "The Incarnation"
        case .sorrowful: return "The Passion"
        case .glorious:  return "The Resurrection"
        case .luminous:  return "The Light"
        }
    }

    /// SF Symbol name for visual representation
    ///
    /// SF Symbols are Apple's built-in icon library. Browse at:
    /// https://developer.apple.com/sf-symbols/
    var iconName: String {
        switch self {
        case .joyful:    return "star.fill"
        case .sorrowful: return "cross.fill"
        case .glorious:  return "sunrise.fill"
        case .luminous:  return "light.max"
        }
    }

    /// Representative image asset name for this category (used on home screen cards).
    ///
    /// Maps to local Assets.xcassets image names.
    var cardImageName: String {
        switch self {
        case .joyful:    return "joyful_annunciation"
        case .sorrowful: return "sorrowful_agony"
        case .glorious:  return "glorious_resurrection"
        case .luminous:  return "luminous_baptism"
        }
    }

    /// Returns the asset catalog image name for a specific mystery in this category.
    ///
    /// Images should be added to Assets.xcassets using the naming convention:
    /// `mystery_<category>_<order>` (e.g., `mystery_joyful_1`)
    ///
    /// - Parameter order: The mystery's position within the category (1–5)
    /// - Returns: The image asset name string
    func imageName(for order: Int) -> String {
        "mystery_\(rawValue)_\(order)"
    }

    /// Gradient colors for card backgrounds (top → bottom)
    ///
    /// Each category has a unique color scheme:
    /// - Joyful: Warm gold/brown (celebratory)
    /// - Sorrowful: Deep purple/red (somber)
    /// - Glorious: Cool blue (heavenly)
    /// - Luminous: Amber/gold (radiant light)
    var gradientColors: [Color] {
        switch self {
        case .joyful:
            return [Color(hex: "3d3522"), Color(hex: "2a2518")]
        case .sorrowful:
            return [Color(hex: "3a2530"), Color(hex: "2a1520")]
        case .glorious:
            return [Color(hex: "2a3a4a"), Color(hex: "1a2a3a")]
        case .luminous:
            return [Color(hex: "4a3a2a"), Color(hex: "3a2a1a")]
        }
    }

    /// Traditional days this mystery is prayed
    var daysPrayed: String {
        switch self {
        case .joyful:    return "Monday, Saturday"
        case .sorrowful: return "Tuesday, Friday"
        case .glorious:  return "Wednesday, Sunday"
        case .luminous:  return "Thursday"
        }
    }

    // MARK: - Initialization

    /// Creates a category from an API string, handling case variations.
    ///
    /// The API might return "Joyful", "JOYFUL", or "joyful" - this
    /// normalizes to lowercase for matching.
    ///
    /// - Parameter string: The category string from the API
    /// - Returns: The matching category, or nil if not found
    init?(fromAPIString string: String) {
        self.init(rawValue: string.lowercased())
    }
}
