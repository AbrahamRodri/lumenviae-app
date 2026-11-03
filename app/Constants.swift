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

    /// Images for the Seven Sorrows of Mary, in sorrow order. The third
    /// and fifth once borrowed the Finding and the Crucifixion from the
    /// other sets; each sorrow now has a painting of Mary's own part in it.
    static let sevenSorrowsMysteryImages: [String] = [
        "seven_sorrows_simeon",
        "seven_sorrows_flight",
        "seven_sorrows_finding",
        "seven_sorrows_meeting",
        "seven_sorrows_calvary",
        "seven_sorrows_descent",
        "seven_sorrows_burial"
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
        case "seven_sorrows":
            images = sevenSorrowsMysteryImages
        default:
            return nil
        }
        guard index >= 0 && index < images.count else { return nil }
        return images[index]
    }

    // MARK: Ordinals

    /// Ordinal word for a mystery's position ("First"…"Seventh") — covers
    /// five-decade rosaries and the Seven Sorrows chaplet.
    static func ordinalWord(_ number: Int) -> String {
        let ordinals = [
            String(localized: "First", comment: "Ordinal word for a decade's place, set before Mystery or Sorrow in titles like The First Joyful Mystery"),
            String(localized: "Second", comment: "Ordinal word for a decade's place, set before Mystery or Sorrow in titles like The Second Joyful Mystery"),
            String(localized: "Third", comment: "Ordinal word for a decade's place, set before Mystery or Sorrow in titles like The Third Joyful Mystery"),
            String(localized: "Fourth", comment: "Ordinal word for a decade's place, set before Mystery or Sorrow in titles like The Fourth Joyful Mystery"),
            String(localized: "Fifth", comment: "Ordinal word for a decade's place, set before Mystery or Sorrow in titles like The Fifth Joyful Mystery"),
            String(localized: "Sixth", comment: "Ordinal word for a sorrow's place in the Seven Sorrows chaplet, as in The Sixth Sorrow of Mary"),
            String(localized: "Seventh", comment: "Ordinal word for a sorrow's place in the Seven Sorrows chaplet, as in The Seventh Sorrow of Mary"),
        ]
        guard number >= 1 && number <= ordinals.count else { return "" }
        return ordinals[number - 1]
    }

    // MARK: App Identity

    static let appName = "LUMEN VIAE"
    /// The name stays Latin in every language; the tagline is translated.
    static let appTagline = String(localized: "LIGHT OF THE WAY", comment: "Tagline under the app's name, Lumen Viae, in capitals")

    /// Where questions, feedback, and privacy notes go. The same address
    /// the web app publishes on its own feedback and privacy pages —
    /// `lumenviae.app` has no mailbox behind it, so mail addressed there
    /// went nowhere.
    static let supportEmail = "rodriguez.abrahamdev@gmail.com"

    // MARK: Tab Bar Labels

    static let homeTab = String(localized: "HOME", comment: "Tab bar label, in capitals")
    static let consecrationTab = String(localized: "CONSECRATION", comment: "Tab bar label for the 33-day Marian consecration, in capitals")
    static let journalTab = String(localized: "JOURNAL", comment: "Tab bar label, in capitals")
    static let progressTab = String(localized: "PRAYER RECORD", comment: "Tab bar label for streaks and prayer history, in capitals")
    static let chapelTab = String(localized: "CHAPEL", comment: "Tab bar label, in capitals")
    static let chantTab = String(localized: "CHANT", comment: "Tab bar label for the Gregorian chant library, in capitals")
    static let prayersTab = String(localized: "PRAYERS", comment: "Tab bar label for the prayer book, in capitals")
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

// MARK: - Bundle Version

extension Bundle {

    /// The marketing version from the Info.plist, e.g. "1.0.1".
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    /// The build number, e.g. "12". Paired with `appVersion` in feedback
    /// so two reports from the same marketing version are still telling
    /// apart.
    var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}
