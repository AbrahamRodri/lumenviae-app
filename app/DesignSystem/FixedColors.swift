//
//  FixedColors.swift
//  Lumen Viae
//
//  The colours that belong to a thing rather than to the page: a
//  vestment, the sky at each hour of the Office, a set of mysteries'
//  card, a stage of the consecration, a book's cloth, St. Carlo's polo.
//  They are the same in every theme, as `Rubric.red` and
//  `AppColors.marianBlue` are, because the thing wears them whatever the
//  page's ground; the page's own colours are the theme's (`AppColors`).
//
//  Every hex outside the theme's palettes is written here, once. They
//  once stood in the models and views that used them, beside the code
//  that drew them.
//

import SwiftUI

// MARK: - Vestments

extension MissalVestment {

    /// The vestment's own colour, for the dot beside a day. Muted so they
    /// never compete with the gold — only ever a small dot, never a field
    /// of colour. Red is the rubric's red, so a red day's dot and the
    /// missal's ℣ ℟ ✠ are one colour.
    var swatch: Color {
        switch self {
        case .white: return Color(hex: "#EDE7D6")
        case .red: return Rubric.red
        case .green: return Color(hex: "#4E6B4A")
        case .violet: return Color(hex: "#6B5480")
        case .black: return Color(hex: "#54545f")
        case .rose: return Color(hex: "#c98a97")
        }
    }
}

// MARK: - The Sky at Each Hour

/// Each hour's place in the day, said as a colour — night indigo for
/// Matins, dawn rose for Lauds, the sun's gold through the day hours,
/// dusk violet for Vespers, and night again at Compline. The swatches
/// are muted to sit on the dark ground, like the vestment swatches — a
/// mark, not a flag.
extension CanonicalHour {
    var skyColor: Color {
        switch self {
        case .matins:   return Color(hex: "#454568")  // deep night
        case .lauds:    return Color(hex: "#a06b7a")  // first light
        case .prime:    return Color(hex: "#c99a5e")  // early sun
        case .terce:    return Color(hex: "#d9b96a")  // morning gold
        case .sext:     return Color(hex: "#e3cf8a")  // noon
        case .nones:    return Color(hex: "#c98d56")  // afternoon amber
        case .vespers:  return Color(hex: "#8a6b9e")  // dusk violet
        case .compline: return Color(hex: "#3a3a5e")  // night
        }
    }
}

// MARK: - The Mysteries' Cards

extension MysteryCategory {

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
}

// MARK: - The Consecration's Stages

extension ConsecrationPhase {

    /// Tint colors layered OVER the theme's own gradient (never a
    /// standalone background, which would freeze one theme's palette) —
    /// a quiet hue journey: penitential violet-navy, deep navy, Marian
    /// blue, then warming toward gold as the consecration nears.
    var gradientColors: [Color] {
        switch self {
        case .preparatory:
            // Emptying of self: dark violet-tinged navy
            return [Color(hex: "#1D1832"), Color(hex: "#100D1F")]
        case .knowledgeOfSelf:
            // Introspection: deep navy
            return [Color(hex: "#141E38"), Color(hex: "#0C1222")]
        case .knowledgeOfMary:
            // Marian blue cast
            return [Color(hex: "#16264D"), Color(hex: "#0D142A")]
        case .knowledgeOfJesus:
            // Warming toward gold
            return [Color(hex: "#2A2318"), Color(hex: "#14101E")]
        case .consecrationDay:
            // Rich dark gold, matching the mystery-card gradient family
            return [Color(hex: "#3D3522"), Color(hex: "#1A1408")]
        }
    }
}

// MARK: - Books' Cloths

extension LibraryBookInfo {

    /// The book's cloth: muted and dark enough to sit on the page
    /// ground, distinct enough to name the book from across the room.
    var bindingColor: Color {
        switch id {
        case "imitation-of-christ":       return Color(hex: "44301e")  // old leather
        case "story-of-a-soul":           return Color(hex: "5e3140")  // rose-brown
        case "confessions-of-st-augustine": return Color(hex: "3d3a24") // bronze-olive
        case "dolorous-passion":          return Color(hex: "342a52")  // passion violet
        case "true-devotion":             return AppColors.marianBlue
        default:                          return Color(hex: "252542")
        }
    }
}

// MARK: - St. Carlo's Portrait

/// The palette of `StCarloIcon`, the medallion drawn of him: his skin,
/// his dark hair, and the red polo he is remembered in
enum StCarloPalette {
    static let skin = Color(hex: "EAC0A2")
    static let hair = Color(hex: "4A3222")
    static let polo = Color(hex: "A93B32")
    static let poloDark = Color(hex: "8E2F28")
}

// MARK: - The Chant Library's Spines

/// The spines on the Chant Library's Saved shelf: chants learned in
/// oxblood, favourites in Marian blue, and the reader's own sets in the
/// cloths of a choir's books, in turn
enum ChantSpineCloth {
    static let learned = Color(hex: "5a2626")     // oxblood
    static let favorites = AppColors.marianBlue
    static let sets: [Color] = [
        Color(hex: "2f4a36"),   // chapter green
        Color(hex: "3f3352"),   // Lenten violet
        Color(hex: "4a3a24"),   // old leather
        Color(hex: "2e3f55")    // slate blue
    ]
}
