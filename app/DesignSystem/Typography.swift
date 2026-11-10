//
//  Typography.swift
//  Lumen Viae
//
//  Bundled serif fonts and the app-wide font accessors.
//
//  Cinzel — Trajan-style Roman capitals (the letterform carved on
//  St. Peter's) for titles and engraved labels.
//  EB Garamond — warm old-style serif for body and meditation text.
//  Both are registered at runtime so no Info.plist entries are needed.
//

import SwiftUI
import CoreText

// MARK: - FontRegistrar

enum FontRegistrar {

    private static let fontFiles = [
        "Cinzel-Regular",
        "Cinzel-SemiBold",
        "EBGaramond-Regular",
        "EBGaramond-Medium",
        "EBGaramond-SemiBold",
        "EBGaramond-Italic",
        "EBGaramond-MediumItalic"
    ]

    /// Registers every bundled font with the process. Safe to call once
    /// at launch; re-registration errors are ignored.
    static func registerBundledFonts() {
        for name in fontFiles {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                #if DEBUG
                print("FontRegistrar: missing font resource \(name).ttf")
                #endif
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Largest Text

extension DynamicTypeSize {

    /// The largest the app's text is allowed to grow. Every `AppFonts`
    /// face is `Font.custom(_:size:)`, which scales with the body style,
    /// so the whole app follows the phone's Larger Text setting — up to
    /// here and no further. At the accessibility sizes the display type
    /// broke mid-word and the pages stopped reading as designed, and
    /// xxLarge still cut the home page's rows short, so the cap is one
    /// step below it.
    ///
    /// Applied at the root (`appApp`) as
    /// `.dynamicTypeSize(...DynamicTypeSize.appMaximum)`. A sheet or a
    /// cover takes its text size from the phone rather than from the
    /// view that presents it, so each presentation's content carries
    /// the same modifier. The readers' own Aa sizes are separate and
    /// stand on top of it.
    static let appMaximum: DynamicTypeSize = .xLarge

    /// How far the Rosary's player follows the phone's Larger Text: one
    /// step into the accessibility sizes, where the rest of the app stops
    /// at `appMaximum` (Abraham's yes to the larger-text proposal, 10 Nov
    /// 2026). The player reads the phone's own size through
    /// `phoneTypeSize`, since the root has already clamped the one it
    /// inherits, and its sheets carry this cap in place of `appMaximum`.
    static let playerMaximum: DynamicTypeSize = .accessibility1
}

// MARK: - The phone's own text size

private struct PhoneTypeSizeKey: EnvironmentKey {
    static let defaultValue: DynamicTypeSize = .large
}

extension EnvironmentValues {
    /// The phone's Larger Text setting before the app's cap, read at the
    /// root above `.dynamicTypeSize(...appMaximum)`
    var phoneTypeSize: DynamicTypeSize {
        get { self[PhoneTypeSizeKey.self] }
        set { self[PhoneTypeSizeKey.self] = newValue }
    }
}

/// Reads the phone's text size above the app's cap and hands it down
struct PhoneTypeSizeRoot<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var phoneSize
    @ViewBuilder let content: Content

    var body: some View {
        content.environment(\.phoneTypeSize, phoneSize)
    }
}

extension View {
    /// Lets a page follow the phone's Larger Text past `appMaximum`, up to
    /// `maximum` (the Rosary's player, to `playerMaximum`)
    func followsPhoneTypeSize(upTo maximum: DynamicTypeSize) -> some View {
        modifier(PhoneTypeSizeFollower(maximum: maximum))
    }
}

private struct PhoneTypeSizeFollower: ViewModifier {
    @Environment(\.phoneTypeSize) private var phoneSize
    let maximum: DynamicTypeSize

    func body(content: Content) -> some View {
        content.environment(\.dynamicTypeSize, min(phoneSize, maximum))
    }
}

// MARK: - App Fonts

struct AppFonts {

    /// Cinzel Regular — hero titles and display text
    static func titleFont(_ size: CGFloat) -> Font {
        .custom("Cinzel-Regular", size: size)
    }

    /// Cinzel SemiBold — headlines and card titles
    static func headlineFont(_ size: CGFloat) -> Font {
        .custom("Cinzel-SemiBold", size: size)
    }

    /// Cinzel Regular — small engraved caps labels ("BEGIN PRAYER").
    /// Pair with `.tracking(...)`; Cinzel's capitals carry the look.
    static func labelFont(_ size: CGFloat) -> Font {
        .custom("Cinzel-Regular", size: size)
    }

    /// EB Garamond Medium — default body text (Medium holds weight
    /// against dark backgrounds better than Regular)
    static func bodyFont(_ size: CGFloat) -> Font {
        .custom("EBGaramond-Medium", size: size)
    }

    /// EB Garamond Regular — long meditation/reading text at larger sizes
    static func readingFont(_ size: CGFloat) -> Font {
        .custom("EBGaramond-Regular", size: size)
    }

    /// EB Garamond SemiBold — emphasized body text
    static func semiboldBodyFont(_ size: CGFloat) -> Font {
        .custom("EBGaramond-SemiBold", size: size)
    }

    /// EB Garamond Medium Italic — quotes and scripture references
    static func italicFont(_ size: CGFloat) -> Font {
        .custom("EBGaramond-MediumItalic", size: size)
    }

    /// EB Garamond Italic — long italic passages
    static func readingItalicFont(_ size: CGFloat) -> Font {
        .custom("EBGaramond-Italic", size: size)
    }
}
