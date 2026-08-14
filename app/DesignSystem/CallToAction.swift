//
//  CallToAction.swift
//  Lumen Viae
//
//  One call-to-action system for the whole app.
//
//  The rule that governs it: **one filled gold shape per screen**, and it
//  is the primary act — BEGIN PRAYER, BEGIN TODAY'S PRAYER, AMEN,
//  CONTINUE TO PRAYERS. If two appear together, one of them is wrong.
//
//  Everything quieter than that act is bare gold type (`QuietGoldButton`),
//  and controls that sit over artwork are circular chrome
//  (`PrayerHeaderButton`, in the prayer flow).
//
//  The pill is flat gold with a hairline and a steady halo — no keyline
//  inside the rim, no top highlight, no vertical gradient, no rules
//  flanking the label. Those were tried and set aside.
//

import SwiftUI

// MARK: - GoldCTAButton

/// The gold call-to-action.
///
/// `.solid` is the filled pill. The remaining fills are held in reserve
/// for dark screens where even the pill reads loud; they are never the
/// default. Press feedback is always a quiet settle, never a bounce.
struct GoldCTAButton: View {

    /// The button's surface. `solid` is the app's one filled shape.
    enum Fill {
        case solid
        /// A dark chapel surface lit through a gold rim
        case votive
        /// Dark interior, single rim
        case outline
        /// Rim plus an inset hairline, like a struck plate
        case engraved
    }

    /// How much room the button takes: a page-level act, or an inline
    /// control sitting among other content (prayer flow AMEN/CONTINUE).
    enum Prominence {
        case page
        case inline
    }

    /// A pill unless it would fight a card's corners.
    enum Silhouette {
        case pill
        case rounded(CGFloat)
    }

    let title: String
    var fill: Fill = .solid
    var prominence: Prominence = .page
    var silhouette: Silhouette = .pill

    /// The Latin cross that leads a page-level act. Never SF Symbols'
    /// medical cross.
    var showsCross: Bool = true

    /// Trailing glyph for the inline variant (`ph-check`, `ph-arrow-right`)
    var trailingIcon: String?

    var fullWidth: Bool = true

    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(title)
    }

    // MARK: - Label

    private var label: some View {
        HStack(spacing: prominence == .page ? 10 : 6) {
            if showsCross && prominence == .page {
                LatinCross()
                    .fill(foreground)
                    .frame(width: 10, height: 14)
            }

            Text(title.uppercased())
                .font(AppFonts.labelFont(prominence == .page ? 13 : 11))
                .tracking(prominence == .page ? 2.5 : 2)

            if let trailingIcon {
                AppIcon(trailingIcon, size: 11)
            }
        }
        .foregroundColor(foreground)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(.vertical, prominence == .page ? 16 : 10)
        .padding(.horizontal, prominence == .page ? 24 : 18)
        .frame(minHeight: 44)
        .background(surface)
        .overlay(rim)
        .contentShape(shape)
        .modifier(HaloModifier(color: AppColors.gold, radius: haloRadius, intensity: haloIntensity))
        .opacity(isEnabled ? 1 : 0.35)
    }

    // MARK: - Skin

    private var foreground: Color {
        switch fill {
        case .solid: return AppColors.background
        case .votive, .outline, .engraved: return AppColors.goldLight
        }
    }

    @ViewBuilder
    private var surface: some View {
        switch fill {
        case .solid:
            shape.fill(AppColors.goldCTAGradient)
        case .votive:
            shape.fill(
                LinearGradient(
                    stops: [
                        .init(color: AppColors.gold.opacity(0.22), location: 0),
                        .init(color: AppColors.gold.opacity(0.06), location: 0.38),
                        .init(color: AppColors.cardBackground, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .outline:
            shape.fill(
                RadialGradient(
                    colors: [
                        AppColors.gold.opacity(0.14),
                        AppColors.gold.opacity(0.04),
                        AppColors.background.opacity(0.5)
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 120
                )
            )
        case .engraved:
            shape.fill(AppColors.background.opacity(0.55))
        }
    }

    @ViewBuilder
    private var rim: some View {
        switch fill {
        case .solid:
            shape.strokeBorder(AppColors.goldLight.opacity(0.6), lineWidth: 0.5)
        case .votive:
            shape.strokeBorder(AppColors.gold.opacity(0.55), lineWidth: 1)
        case .outline:
            shape.strokeBorder(AppColors.gold.opacity(0.75), lineWidth: 1)
        case .engraved:
            ZStack {
                shape.strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 1)
                shape.inset(by: 1.5)
                    .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: 1)
            }
        }
    }

    private var shape: AnyInsettableShape {
        switch silhouette {
        case .pill: return AnyInsettableShape(Capsule())
        case .rounded(let radius): return AnyInsettableShape(RoundedRectangle(cornerRadius: radius))
        }
    }

    private var haloRadius: CGFloat {
        switch fill {
        case .solid: return 9
        case .votive, .outline, .engraved: return 10
        }
    }

    /// Disabled buttons carry no glow — they should recede, not smoulder.
    private var haloIntensity: Double {
        guard isEnabled else { return 0 }
        switch fill {
        case .solid: return 0.3
        case .votive, .outline, .engraved: return 0.14
        }
    }
}

// MARK: - QuietGoldButton

/// Bare gold type for secondary moves — PREV / NEXT in the prayer flow,
/// VIEW ALL, READ IN FULL, WRITE IN YOUR JOURNAL, RESTART CONSECRATION.
///
/// No background, no border. When an action is genuinely unavailable it
/// should *disappear* rather than grey out, so this has no disabled skin.
struct QuietGoldButton: View {

    let title: String
    var leadingIcon: String?
    var leadingIconSize: CGFloat = 13
    var trailingIcon: String?
    var trailingIconSize: CGFloat = 9
    var size: CGFloat = 11
    var tracking: CGFloat = 2
    var color: Color = AppColors.gold.opacity(0.7)

    /// Zero inside a card, where the card's own padding sets the gutter.
    var horizontalPadding: CGFloat = 18

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leadingIcon {
                    AppIcon(leadingIcon, size: leadingIconSize)
                }

                Text(title.uppercased())
                    .font(AppFonts.labelFont(size))
                    .tracking(tracking)

                if let trailingIcon {
                    AppIcon(trailingIcon, size: trailingIconSize)
                }
            }
            .foregroundColor(color)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - AnyInsettableShape

/// Type-erased insettable shape, so a button can carry either a capsule
/// or a rounded rectangle and still stroke its border inset.
struct AnyInsettableShape: InsettableShape {

    private let makePath: @Sendable (CGRect) -> Path
    private let makeInset: @Sendable (CGFloat) -> AnyInsettableShape

    init<S: InsettableShape>(_ shape: S) {
        makePath = { shape.path(in: $0) }
        makeInset = { AnyInsettableShape(shape.inset(by: $0)) }
    }

    func path(in rect: CGRect) -> Path { makePath(rect) }

    func inset(by amount: CGFloat) -> AnyInsettableShape { makeInset(amount) }
}

// MARK: - HaloModifier

/// `haloGlow` as a modifier, so a view can carry a glow whose intensity
/// varies (a disabled CTA drops it entirely).
private struct HaloModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double

    func body(content: Content) -> some View {
        if intensity > 0 {
            content.haloGlow(color, radius: radius, intensity: intensity)
        } else {
            content
        }
    }
}

// MARK: - Previews

#Preview("Call to action") {
    ScrollView {
        VStack(spacing: 20) {
            GoldCTAButton(title: "Begin prayer") {}

            GoldCTAButton(title: "Continue to prayers", showsCross: false) {}

            GoldCTAButton(title: "Begin prayer") {}
                .disabled(true)

            HStack {
                QuietGoldButton(title: "Prev", leadingIcon: "ph-arrow-left", leadingIconSize: 11) {}
                Spacer()
                GoldCTAButton(
                    title: "Amen",
                    prominence: .inline,
                    trailingIcon: "ph-check",
                    fullWidth: false
                ) {}
            }

            QuietGoldButton(
                title: "Read in full",
                leadingIcon: "ph-book-open",
                trailingIcon: "ph-caret-right",
                size: 10,
                color: AppColors.gold,
                horizontalPadding: 0
            ) {}

            GoldCTAButton(title: "Votive", fill: .votive, showsCross: false) {}
            GoldCTAButton(title: "Outline", fill: .outline, showsCross: false) {}
            GoldCTAButton(title: "Engraved", fill: .engraved, showsCross: false) {}
        }
        .padding(20)
    }
    .background(AppColors.appGradient)
}
