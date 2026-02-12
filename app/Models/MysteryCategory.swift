//
//  MysteryCategory.swift
//  app
//
//  Represents the four types of Rosary mysteries with display properties.
//

import SwiftUI

/// The four types of Rosary mysteries
enum MysteryCategory: String, Codable, CaseIterable, Hashable {
    case joyful
    case sorrowful
    case glorious
    case luminous

    /// Display name for UI
    var displayName: String {
        rawValue.capitalized
    }

    /// Subtitle describing the mystery theme
    var subtitle: String {
        switch self {
        case .joyful: return "The Incarnation"
        case .sorrowful: return "The Passion"
        case .glorious: return "The Resurrection"
        case .luminous: return "The Light"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .joyful: return "star.fill"
        case .sorrowful: return "cross.fill"
        case .glorious: return "sunrise.fill"
        case .luminous: return "light.max"
        }
    }

    /// Gradient colors for mystery card backgrounds
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
        case .joyful: return "Monday, Saturday"
        case .sorrowful: return "Tuesday, Friday"
        case .glorious: return "Wednesday, Sunday"
        case .luminous: return "Thursday"
        }
    }

    /// Initialize from API string (handles case variations)
    init?(fromAPIString string: String) {
        self.init(rawValue: string.lowercased())
    }
}
