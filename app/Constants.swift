//
//  Constants.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  This file contains all the app's theme colors, fonts, and constant strings.
//  Centralizing these values makes it easy to update the app's appearance
//  from one place instead of hunting through multiple files.
//

// MARK: - Imports
// 'import' brings in external code libraries (called "frameworks" in iOS)
// Foundation: Basic Swift utilities (strings, dates, etc.)
// SwiftUI: Apple's modern UI framework for building interfaces
import Foundation
import SwiftUI

// MARK: - App Colors
/// `AppColors` holds all the color values used throughout the app.
///
/// ## Swift Concepts Used:
/// - `struct`: A value type that groups related data together (like a blueprint)
/// - `static`: Means this property belongs to the TYPE itself, not instances of it
///   - Access with: `AppColors.gold` (no need to create an AppColors object)
/// - `let`: Declares a constant (value cannot change after being set)
///
/// ## Usage Example:
/// ```swift
/// Text("Hello")
///     .foregroundColor(AppColors.gold)
/// ```
struct AppColors {
    /// Deep navy background - the main app background color
    static let background = Color(hex: "#1F2033")

    /// Slightly lighter navy for cards and elevated surfaces
    static let cardBackground = Color(hex: "#22223A")

    /// Primary gold accent color - used for highlights and important elements
    static let gold = Color(hex: "d4af37")

    /// Lighter gold variant - used for buttons and emphasized text
    static let goldLight = Color(hex: "e8c547")

    /// Cream/off-white color - used for primary text on dark backgrounds
    static let cream = Color(hex: "f5f0e1")

    /// Pure white - used for the most prominent text
    static let textPrimary = Color.white

    /// Muted gray-blue - used for secondary/less important text
    static let textSecondary = Color(hex: "a0a0b0")

    /// Special background color for quote sections
    static let quoteBackground = Color(hex: "2a2a45")

    /// Gradient background used throughout the app for a glowy, contemplative feel
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
/// `AppFonts` provides font styles used throughout the app.
///
/// ## Swift Concepts Used:
/// - `func`: Declares a function (a reusable block of code)
/// - `(_ size: CGFloat)`: A parameter with an external name omitted (`_`)
///   - `CGFloat`: A number type used for graphics (Core Graphics Float)
/// - `-> Font`: The return type - this function returns a Font object
///
/// ## Usage Example:
/// ```swift
/// Text("Title")
///     .font(AppFonts.headlineFont(24))
/// ```
struct AppFonts {

    // MARK: Custom Fonts (require font files to be added to project)

    /// Cinzel Regular - elegant serif font for titles
    /// Note: You need to add the actual font file to use this
    static func cinzelRegular(_ size: CGFloat) -> Font {
        .custom("Cinzel-Regular", size: size)
    }

    /// Cinzel Bold - bold variant for emphasis
    static func cinzelBold(_ size: CGFloat) -> Font {
        .custom("Cinzel-Bold", size: size)
    }

    /// Cormorant Garamond Medium Italic - for quotes and scripture
    static func cormorantMediumItalic(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-MediumItalic", size: size)
    }

    /// Cormorant Garamond Regular - elegant body text
    static func cormorantRegular(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Regular", size: size)
    }

    // MARK: System Fonts (always available, used as fallbacks)

    /// System serif font for titles - always available on iOS
    static func titleFont(_ size: CGFloat) -> Font {
        // .system() creates a built-in iOS font
        // weight: how thick/thin the font is
        // design: .serif gives it a traditional book-like appearance
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
        // .italic() is a modifier that makes the font italic
        .system(size: size, weight: .medium, design: .serif).italic()
    }
}

// MARK: - String Constants
/// `Constants` holds text strings used throughout the app.
///
/// ## Why Use Constants?
/// 1. **Avoid typos**: Write the string once, reference it everywhere
/// 2. **Easy updates**: Change text in one place, updates everywhere
/// 3. **Localization**: Makes it easier to translate the app later
///
/// ## Usage Example:
/// ```swift
/// Text(Constants.appName)  // Displays "LUMEN VIAE"
/// ```
struct Constants {
    /// The word "Pray" - used in various places
    static let prayString = "Pray"

    // MARK: SF Symbol Icon Names
    // SF Symbols are Apple's built-in icon library (thousands of free icons!)
    // Browse them at: https://developer.apple.com/sf-symbols/

    static let homeIconString = "house"
    static let prayerIconString = "prayer"
    static let journalIconString = "book"
    static let accountIconString = "person"

    // MARK: Mystery Image URLs
    // Public domain artwork from Wikimedia Commons for each Rosary mystery

    /// Images for Joyful Mysteries
    static let joyfulMysteryImages: [String] = [
        // 1. The Annunciation - Fra Angelico
        "https://commons.wikimedia.org/wiki/Special:FilePath/Fra_Angelico_-_The_Annunciation_-_WGA00555.jpg?width=1024",
        // 2. The Visitation - Pontormo
        "https://commons.wikimedia.org/wiki/Special:FilePath/Pontormo-Visitazione1.jpg?width=1024",
        // 3. The Nativity - Bartolomé Esteban Murillo
        "https://commons.wikimedia.org/wiki/Special:FilePath/Bartolom%C3%A9_Esteban_Murillo_-_The_Nativity_-_Google_Art_Project.jpg?width=1024",
        // 4. The Presentation in the Temple
        "https://commons.wikimedia.org/wiki/Special:FilePath/The_Presentation_in_the_Temple_MET_DT8826.jpg?width=1024",
        // 5. Finding Jesus in the Temple - Albrecht Dürer
        "https://commons.wikimedia.org/wiki/Special:FilePath/Albrecht_D%C3%BCrer_-_Jesus_among_the_Doctors_-_Google_Art_Project.jpg?width=1024"
    ]

    /// Images for Sorrowful Mysteries
    static let sorrowfulMysteryImages: [String] = [
        // 1. The Agony in the Garden - Andrea Mantegna
        "https://commons.wikimedia.org/wiki/Special:FilePath/Andrea_Mantegna_-_Agony_in_the_Garden_-_WGA13946.jpg?width=1024",
        // 2. The Scourging at the Pillar - Piero della Francesca
        "https://commons.wikimedia.org/wiki/Special:FilePath/Piero_della_Francesca_042_Flagellation.jpg?width=1024",
        // 3. The Crowning with Thorns - Caravaggio
        "https://commons.wikimedia.org/wiki/Special:FilePath/The_Crowning_with_Thorns-Caravaggio_(1602).jpg?width=1024",
        // 4. The Carrying of the Cross - El Greco
        "https://commons.wikimedia.org/wiki/Special:FilePath/El_Greco_-_Christ_Carrying_the_Cross_-_WGA10559.jpg?width=1024",
        // 5. The Crucifixion - Diego Velázquez
        "https://commons.wikimedia.org/wiki/Special:FilePath/Cristo_crucificado.jpg?width=1024"
    ]

    /// Images for Glorious Mysteries
    static let gloriousMysteryImages: [String] = [
        // 1. The Resurrection - Piero della Francesca
        "https://commons.wikimedia.org/wiki/Special:FilePath/Piero_della_Francesca_-_Resurrection_-_WGA17609.jpg?width=1024",
        // 2. The Ascension - Giotto di Bondone
        "https://commons.wikimedia.org/wiki/Special:FilePath/Giotto_di_Bondone_-_Ascension_of_Christ_-_WGA09156.jpg?width=1024",
        // 3. The Descent of the Holy Spirit (Pentecost) - El Greco
        "https://commons.wikimedia.org/wiki/Special:FilePath/El_Greco_-_The_Pentecost_-_WGA10533.jpg?width=1024",
        // 4. The Assumption of Mary - Titian
        "https://commons.wikimedia.org/wiki/Special:FilePath/Tizian_041.jpg?width=1024",
        // 5. The Coronation of Mary - Fra Angelico
        "https://commons.wikimedia.org/wiki/Special:FilePath/Fra_Angelico_-_The_Coronation_of_the_Virgin_-_WGA0630.jpg?width=1024"
    ]

    /// Images for Luminous Mysteries
    static let luminousMysteryImages: [String] = [
        // 1. The Baptism of Jesus in the Jordan - Verrocchio & Leonardo
        "https://commons.wikimedia.org/wiki/Special:FilePath/The_Baptism_of_Christ_(Verrocchio_%26_Leonardo).jpg?width=1024",
        // 2. The Wedding Feast at Cana - Paolo Veronese
        "https://commons.wikimedia.org/wiki/Special:FilePath/Paolo_Veronese%2C_The_Wedding_at_Cana.JPG?width=1024",
        // 3. The Proclamation of the Kingdom of God - Carl Heinrich Bloch (Sermon on the Mount)
        "https://commons.wikimedia.org/wiki/Special:FilePath/Bloch-SermonOnTheMount.jpg?width=1024",
        // 4. The Transfiguration - Raphael
        "https://commons.wikimedia.org/wiki/Special:FilePath/Transfiguration_Raphael.jpg?width=1024",
        // 5. The Institution of the Eucharist - Juan de Juanes
        "https://commons.wikimedia.org/wiki/Special:FilePath/%C3%9Altima_Cena_-_Juan_de_Juanes.jpg?width=1024"
    ]

    /// Get mystery image URL by category and index (0-based)
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

    /// The app's display name
    static let appName = "LUMEN VIAE"

    /// Tagline shown under the app name
    static let appTagline = "LIGHT OF THE WAY"

    // MARK: Tab Bar Labels

    static let homeTab = "HOME"
    static let journalTab = "JOURNAL"
    static let progressTab = "PROGRESS"
    static let accountTab = "ACCOUNT"
}

// MARK: - Color Extension for Hex Support
/// This `extension` adds new functionality to SwiftUI's built-in `Color` type.
///
/// ## Swift Concepts Used:
/// - `extension`: Adds new methods/properties to an existing type
///   - Here we're adding a new initializer to Color
/// - `init`: A special function that creates a new instance of a type
///
/// ## Why We Need This:
/// SwiftUI's Color doesn't natively support hex color codes like "#d4af37".
/// This extension adds that ability so we can use web-style hex colors.
///
/// ## Usage Example:
/// ```swift
/// let gold = Color(hex: "d4af37")  // Creates a gold color
/// let blue = Color(hex: "#0000FF") // The # is optional
/// ```
extension Color {
    /// Creates a Color from a hex string (like "FF5733" or "#FF5733")
    /// - Parameter hex: A hex color string (3, 6, or 8 characters)
    init(hex: String) {
        // Remove any non-alphanumeric characters (like # or spaces)
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // Convert the hex string to a number
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        // Declare variables for alpha, red, green, blue
        let a, r, g, b: UInt64

        // Parse differently based on hex string length
        switch hex.count {
        case 3: // RGB (12-bit) - e.g., "F00" for red
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit) - e.g., "FF0000" for red (most common)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit) - includes alpha/transparency
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0) // Fallback to transparent
        }

        // Create the Color with RGB values (converted to 0.0-1.0 range)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
