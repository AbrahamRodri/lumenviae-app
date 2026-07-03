//
//  Constants.swift
//  Lumen Viae
//
//  Theme colors, fonts, and constant strings.
//

import Foundation
import SwiftUI

// MARK: - App Colors

struct AppColors {
    /// Deep navy background - the main app background color
    static let background = Color(hex: "#1F2033")

    /// Slightly lighter navy for cards and elevated surfaces
    static let cardBackground = Color(hex: "#22223A")

    /// Primary gold accent color
    static let gold = Color(hex: "d4af37")

    /// Lighter gold variant - used for buttons and emphasized text
    static let goldLight = Color(hex: "e8c547")

    /// Cream/off-white - primary text on dark backgrounds
    static let cream = Color(hex: "f5f0e1")

    /// Pure white - the most prominent text
    static let textPrimary = Color.white

    /// Muted gray-blue - secondary text
    static let textSecondary = Color(hex: "a0a0b0")

    /// Background color for quote sections
    static let quoteBackground = Color(hex: "2a2a45")

    /// Gradient background used throughout the app
    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "0d0d1a"),
                Color(hex: "1a1a2e"),
                Color(hex: "0d0d1a")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - App Fonts

struct AppFonts {

    /// System serif font for titles
    static func titleFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Semi-bold serif for headlines and card titles
    static func headlineFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    /// Regular weight for body text
    static func bodyFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Italic serif for quotes and scripture references
    static func italicFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif).italic()
    }
}

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
