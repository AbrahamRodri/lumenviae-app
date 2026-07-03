//
//  MysteryCategory.swift
//  Lumen Viae
//
//  The Rosary mystery categories, with display properties (colors, icons, days).
//  Raw values match the API strings. Luminous mysteries (added 2002) are not
//  part of the traditional daily rotation but are available in the app.
//

import SwiftUI

enum MysteryCategory: String, Codable, CaseIterable, Hashable {

    // MARK: - Cases

    case joyful
    case sorrowful
    case glorious
    case luminous
    case sevenSorrows = "seven_sorrows"

    // MARK: - Category Groups

    /// Categories shown on the home screen grid (traditional mysteries + Seven Sorrows)
    static let homeCategories: [MysteryCategory] = [.joyful, .sorrowful, .glorious, .sevenSorrows]

    /// All mystery categories including Luminous (for "View All" screen)
    static let allCategories: [MysteryCategory] = [.joyful, .sorrowful, .glorious, .luminous, .sevenSorrows]

    // MARK: - Display Properties

    /// Human-readable name (e.g., "Joyful")
    var displayName: String {
        switch self {
        case .sevenSorrows: return "Seven Sorrows"
        default: return rawValue.capitalized
        }
    }

    /// Subtitle describing the theological theme of this category
    var subtitle: String {
        switch self {
        case .joyful:      return "The Incarnation"
        case .sorrowful:   return "The Passion"
        case .glorious:    return "The Resurrection"
        case .luminous:    return "The Light"
        case .sevenSorrows: return "Mary's Sorrows"
        }
    }

    /// SF Symbol name for visual representation
    var iconName: String {
        switch self {
        case .joyful:      return "ph-star"
        case .sorrowful:   return "ch-crown-of-thorns"
        case .glorious:    return "ph-sun-horizon"
        case .luminous:    return "ph-sparkle"
        case .sevenSorrows: return "ch-sacred-heart"
        }
    }

    /// Representative image asset name for this category (used on home screen cards)
    var cardImageName: String {
        switch self {
        case .joyful:      return "joyful_annunciation"
        case .sorrowful:   return "sorrowful_agony"
        case .glorious:    return "glorious_resurrection"
        case .luminous:    return "luminous_baptism"
        case .sevenSorrows: return "seven_sorrows_pieta"
        }
    }

    /// Asset catalog image name for a specific mystery in this category,
    /// following the `mystery_<category>_<order>` convention.
    func imageName(for order: Int) -> String {
        "mystery_\(rawValue)_\(order)"
    }

    /// Gradient colors for card backgrounds (top → bottom)
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
        case .sevenSorrows:
            return [Color(hex: "2a2a4a"), Color(hex: "1a1a3a")]
        }
    }

    /// Traditional days this mystery is prayed
    var daysPrayed: String {
        switch self {
        case .joyful:      return "Monday, Saturday"
        case .sorrowful:   return "Tuesday, Friday"
        case .glorious:    return "Wednesday, Sunday"
        case .luminous:    return "Thursday"
        case .sevenSorrows: return "Fridays, September 15"
        }
    }

    // MARK: - Initialization

    /// Creates a category from an API string, normalizing case variations.
    init?(fromAPIString string: String) {
        self.init(rawValue: string.lowercased())
    }
}
