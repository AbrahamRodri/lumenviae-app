//
//  Theme.swift
//  Lumen Viae
//
//  The three sanctuary palettes and the live theme switcher.
//
//  Every color in the app flows through `AppColors`, which reads the
//  active `AppTheme` from `ThemeManager`. Because `ThemeManager` is
//  @Observable and `AppColors` accessors are evaluated inside view
//  bodies, changing the theme re-renders the whole app instantly —
//  no per-view plumbing required.
//

import SwiftUI

// MARK: - ThemePalette

/// The full color vocabulary of one theme.
struct ThemePalette {
    /// Main app background
    let background: Color

    /// Darker edge for background gradients (top/bottom vignette)
    let backgroundDeep: Color

    /// Cards and elevated surfaces
    let card: Color

    /// Surfaces raised above cards (inner chips, active rows)
    let cardElevated: Color

    /// Quote / scripture block background
    let quote: Color

    /// Primary gold accent
    let gold: Color

    /// Brighter gold for buttons and emphasis
    let goldLight: Color

    /// Warm off-white for primary text on dark
    let cream: Color

    /// Muted secondary text
    let textSecondary: Color

    /// Soft secondary accent (scripture references, quiet labels) —
    /// Marian blue in the blue theme, cooler lavender/parchment elsewhere
    let accentSoft: Color
}

// MARK: - AppTheme

/// The user-selectable appearance themes, chosen in Account → Appearance.
enum AppTheme: String, CaseIterable, Identifiable {
    case marianBlue
    case midnight
    case candlelit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .marianBlue: return "Marian Blue"
        case .midnight:   return "Midnight"
        case .candlelit:  return "Candlelit"
        }
    }

    /// One-line character description shown in the theme picker
    var detail: String {
        switch self {
        case .marianBlue: return "Royal blue depths — Our Lady's color"
        case .midnight:   return "Deep navy calm, quiet and steady"
        case .candlelit:  return "A dark chapel lit by warm gold"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .marianBlue:
            return ThemePalette(
                background:     Color(hex: "0D1730"),
                backgroundDeep: Color(hex: "070E1F"),
                card:           Color(hex: "17284E"),
                cardElevated:   Color(hex: "1E3260"),
                quote:          Color(hex: "14213F"),
                gold:           Color(hex: "D9B84A"),
                goldLight:      Color(hex: "E9CC6E"),
                cream:          Color(hex: "F4EFE2"),
                textSecondary:  Color(hex: "93A5C8"),
                accentSoft:     Color(hex: "8FA9D8")
            )
        case .midnight:
            return ThemePalette(
                background:     Color(hex: "131324"),
                backgroundDeep: Color(hex: "0B0B16"),
                card:           Color(hex: "1F1F38"),
                cardElevated:   Color(hex: "29294A"),
                quote:          Color(hex: "232340"),
                gold:           Color(hex: "D4AF37"),
                goldLight:      Color(hex: "E8C547"),
                cream:          Color(hex: "F5F0E1"),
                textSecondary:  Color(hex: "9C9CB5"),
                accentSoft:     Color(hex: "ABABD6")
            )
        case .candlelit:
            return ThemePalette(
                background:     Color(hex: "0A0A15"),
                backgroundDeep: Color(hex: "050509"),
                card:           Color(hex: "151521"),
                cardElevated:   Color(hex: "1E1E2E"),
                quote:          Color(hex: "17172A"),
                gold:           Color(hex: "E3BC5B"),
                goldLight:      Color(hex: "F3D89A"),
                cream:          Color(hex: "F6F1E4"),
                textSecondary:  Color(hex: "8B8BA5"),
                accentSoft:     Color(hex: "C9B98F")
            )
        }
    }
}

// MARK: - ThemeManager

/// Holds the active theme and persists it across launches.
@Observable
final class ThemeManager {

    static let shared = ThemeManager()

    private static let storageKey = "userSettings.appTheme"

    var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.storageKey)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        current = AppTheme(rawValue: stored) ?? .marianBlue
    }
}

// MARK: - AppColors

/// Theme-aware color accessors. Call sites keep the familiar
/// `AppColors.gold` spelling; values follow the active theme.
struct AppColors {

    private static var palette: ThemePalette { ThemeManager.shared.current.palette }

    /// Deep background - the main app background color
    static var background: Color { palette.background }

    /// Darker edge used by background gradients
    static var backgroundDeep: Color { palette.backgroundDeep }

    /// Slightly lighter surface for cards and elevated content
    static var cardBackground: Color { palette.card }

    /// Surfaces raised above cards (inner chips, selected rows)
    static var cardElevated: Color { palette.cardElevated }

    /// Primary gold accent color
    static var gold: Color { palette.gold }

    /// Lighter gold variant - used for buttons and emphasized text
    static var goldLight: Color { palette.goldLight }

    /// Cream/off-white - primary text on dark backgrounds
    static var cream: Color { palette.cream }

    /// Pure white - the most prominent text
    static let textPrimary = Color.white

    /// Muted secondary text
    static var textSecondary: Color { palette.textSecondary }

    /// Soft secondary accent for scripture references and quiet labels
    static var accentSoft: Color { palette.accentSoft }

    /// Background color for quote sections
    static var quoteBackground: Color { palette.quote }

    /// Gradient background used throughout the app
    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [palette.backgroundDeep, palette.background, palette.backgroundDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The standard gold sheen for buttons, flames, and filled beads
    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [palette.goldLight, palette.gold],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
