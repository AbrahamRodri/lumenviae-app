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

    /// The devotion's full title as a user reads it: "Joyful Mysteries",
    /// "Seven Sorrows of Mary". One place for the noun, so the picker
    /// header, the detail's context line and the prayer screen agree.
    var devotionTitle: String {
        switch self {
        case .sevenSorrows: return "Seven Sorrows of Mary"
        default: return "\(displayName) Mysteries"
        }
    }

    /// The label for one decade by position: "The First Joyful Mystery",
    /// or, for the chaplet, "The First Sorrow of Mary". Callers uppercase
    /// or trim the article as their surface needs.
    func mysteryLabel(ordinal number: Int) -> String {
        let ordinal = Constants.ordinalWord(number)
        switch self {
        case .sevenSorrows: return "The \(ordinal) Sorrow of Mary"
        default: return "The \(ordinal) \(displayName) Mystery"
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

    /// Icon for this category — the ONLY icon mapping for mystery
    /// categories; every surface (pickers, journal, chips) reads this.
    /// Star of Bethlehem for the Incarnation, crown of thorns for the
    /// Passion, dawn for the Resurrection, the sun for the Mysteries of
    /// Light, the Sacred Heart for Mary's sorrows.
    var iconName: String {
        switch self {
        case .joyful:      return "ph-star"
        case .sorrowful:   return "ch-crown-of-thorns"
        case .glorious:    return "ph-sun-horizon"
        case .luminous:    return "ph-sun"
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

    /// Where the card crop sits in each painting.
    ///
    /// A `.fill` crop keeps the middle of the canvas, which is right for
    /// the paintings whose figures are centered. The Resurrection and the
    /// Pietà are both tall canvases carrying their subject high — the
    /// risen Christ in the upper third, the Pietà's halos and faces
    /// around a fifth of the way down — so centering crops the subject
    /// away and leaves a card of drapery and onlookers. Anchoring those
    /// two to the top brings the subject back into the frame.
    var cardImageAlignment: Alignment {
        switch self {
        case .glorious, .sevenSorrows: return .top
        case .joyful, .sorrowful, .luminous: return .center
        }
    }

    /// Fine adjustment on top of `cardImageAlignment`, in points, where
    /// negative lifts the crop back toward the top of the canvas.
    ///
    /// Anchoring is coarse — it can only pick an edge — and the Pietà
    /// overshoots it: pinned to the top of that very tall canvas the
    /// halos land square in the middle of the card, which reads low
    /// against the title. A small lift carries them into the upper
    /// third where the eye expects them.
    var cardImageOffset: CGFloat {
        switch self {
        case .sevenSorrows: return -48
        case .joyful, .sorrowful, .glorious, .luminous: return 0
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
