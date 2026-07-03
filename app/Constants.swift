//
//  Constants.swift
//  Lumen Viae
//
//  Theme colors, fonts, and constant strings.
//

import Foundation
import SwiftUI

// MARK: - String Constants

struct Constants {

    // MARK: Mystery Image Assets

    /// Images for Joyful Mysteries, in mystery order
    static let joyfulMysteryImages: [String] = [
        "joyful_annunciation",
        "joyful_visitation",
        "joyful_nativity",
        "joyful_presentation",
        "joyful_finding"
    ]

    /// Images for Sorrowful Mysteries, in mystery order
    static let sorrowfulMysteryImages: [String] = [
        "sorrowful_agony",
        "sorrowful_scourging",
        "sorrowful_crowning",
        "sorrowful_carrying",
        "sorrowful_crucifixion"
    ]

    /// Images for Glorious Mysteries, in mystery order
    static let gloriousMysteryImages: [String] = [
        "glorious_resurrection",
        "glorious_ascension",
        "glorious_pentecost",
        "glorious_assumption",
        "glorious_coronation"
    ]

    /// Images for Luminous Mysteries, in mystery order
    static let luminousMysteryImages: [String] = [
        "luminous_baptism",
        "luminous_cana",
        "luminous_proclamation",
        "luminous_transfiguration",
        "luminous_eucharist"
    ]

    /// Get the local image asset name for a mystery by category and 0-based index
    static func mysteryImageURL(category: String, index: Int) -> String? {
        let images: [String]
        switch category.lowercased() {
        case "joyful":
            images = joyfulMysteryImages
        case "sorrowful":
            images = sorrowfulMysteryImages
        case "glorious":
            images = gloriousMysteryImages
        case "luminous":
            images = luminousMysteryImages
        default:
            return nil
        }
        guard index >= 0 && index < images.count else { return nil }
        return images[index]
    }

    // MARK: App Identity

    static let appName = "LUMEN VIAE"
    static let appTagline = "LIGHT OF THE WAY"

    // MARK: Tab Bar Labels

    static let homeTab = "HOME"
    static let consecrationTab = "CONSECRATE"
    static let journalTab = "JOURNAL"
    static let progressTab = "PROGRESS"
    static let accountTab = "ACCOUNT"
}

// MARK: - Color Hex Support

extension Color {
    /// Creates a Color from a hex string like "d4af37" or "#d4af37" (3, 6, or 8 digits)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
