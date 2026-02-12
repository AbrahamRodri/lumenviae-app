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
    static let background = Color(hex: "1a1a2e")

    /// Slightly lighter navy for cards and elevated surfaces
    static let cardBackground = Color(hex: "252542")

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

    // MARK: Image URLs

    /// Placeholder image for mystery meditation (Rosary artwork)
    static let mysteryPlaceholderImageURL = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Bartolom%C3%A9_Esteban_Murillo_-_Madonna_and_Child_-_Google_Art_Project.jpg/800px-Bartolom%C3%A9_Esteban_Murillo_-_Madonna_and_Child_-_Google_Art_Project.jpg"

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
