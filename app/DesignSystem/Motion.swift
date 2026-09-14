//
//  Motion.swift
//  Lumen Viae
//
//  Reverent motion helpers. All animation here is slow, soft, and
//  optional — every helper quiets itself when Reduce Motion is on.
//

import SwiftUI

// MARK: - Motion Vocabulary

/// The app's named motions, so two screens doing the same thing move
/// the same way. Springs settle and never bounce; curves are short.
/// Reach for one of these before writing a duration at a call site.
enum Motion {

    /// A bead drawn to the hand: the strand slides one bead's length
    /// and settles, with a little weight and no bounce.
    static let beadSlide = Animation.spring(response: 0.42, dampingFraction: 0.82)

    /// A strand let go short of the next bead, coming back to rest.
    static let beadSettle = Animation.spring(response: 0.36, dampingFraction: 0.74)

    /// Words changing under a hand that has just moved: a bead's name,
    /// its verse, its cue.
    static let words = Animation.easeOut(duration: 0.3)

    /// The decade turning — the painting, the kicker and the title
    /// crossfading to the next mystery.
    static let decadeTurn = Animation.easeInOut(duration: 0.45)

    /// Chrome cleared from a painting, or brought back.
    static let chrome = Animation.easeInOut(duration: 0.35)

    /// A panel or reader arriving over a screen, with some weight
    /// behind it.
    static let panel = Animation.spring(response: 0.42, dampingFraction: 0.86)

    /// Something small settling into place after a press or a toggle.
    static let settle = Animation.spring(response: 0.32, dampingFraction: 0.8)

    /// A quiet crossfade for content that changes in place.
    static let crossfade = Animation.easeInOut(duration: 0.28)

    /// The design system's ease-out — cubic-bezier(0, 0, 0.58, 1) —
    /// for chrome that collapses, fades or slides as the page moves.
    /// Nothing springs past its mark.
    static func ease(_ duration: Double) -> Animation {
        .timingCurve(0, 0, 0.58, 1, duration: duration)
    }

    /// Ease-in-out for travel — a jump to a section leaves as gently
    /// as it arrives.
    static func travel(_ duration: Double) -> Animation {
        .timingCurve(0.42, 0, 0.58, 1, duration: duration)
    }
}

// MARK: - Devotional Entrance

/// Fades content in with a gentle upward drift. Stagger sections by
/// passing increasing delays. With Reduce Motion, only the fade runs.
private struct DevotionalEntrance: ViewModifier {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let delay: Double
    let drift: CGFloat

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : drift)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Breathing Glow

/// A soft halo that swells and settles like candlelight. With Reduce
/// Motion, renders as a steady glow at mid intensity.
private struct BreathingGlow: ViewModifier {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var color: Color
    var radius: CGFloat
    var dimOpacity: Double
    var brightOpacity: Double
    var period: Double

    func body(content: Content) -> some View {
        if reduceMotion {
            content.shadow(color: color.opacity((dimOpacity + brightOpacity) / 2), radius: radius)
        } else {
            content.phaseAnimator([dimOpacity, brightOpacity]) { view, phase in
                view.shadow(color: color.opacity(phase), radius: radius)
            } animation: { _ in
                .easeInOut(duration: period)
            }
        }
    }
}

// MARK: - View Extensions

extension View {

    /// Fade-and-drift entrance for screen content. Stagger sections
    /// with increasing `delay` values (0, 0.08, 0.16...).
    func devotionalEntrance(delay: Double = 0, drift: CGFloat = 14) -> some View {
        modifier(DevotionalEntrance(delay: delay, drift: drift))
    }

    /// A steady, layered halo glow — presence without motion.
    func haloGlow(_ color: Color, radius: CGFloat = 10, intensity: Double = 0.5) -> some View {
        self
            .shadow(color: color.opacity(intensity * 0.7), radius: radius)
            .shadow(color: color.opacity(intensity * 0.35), radius: radius * 2.2)
    }

    /// A halo that breathes like candlelight (steady under Reduce Motion).
    func breathingGlow(
        _ color: Color,
        radius: CGFloat = 12,
        dimOpacity: Double = 0.25,
        brightOpacity: Double = 0.6,
        period: Double = 2.4
    ) -> some View {
        modifier(BreathingGlow(
            color: color,
            radius: radius,
            dimOpacity: dimOpacity,
            brightOpacity: brightOpacity,
            period: period
        ))
    }
}

// MARK: - Button Styles

/// Press feedback for tappable cards: a quiet settle, no bounce.
/// The whole label rectangle is tappable — without an explicit content
/// shape, Spacers inside card labels leave dead zones a finger can miss.
struct SacredCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

/// Press feedback for gold call-to-action pills. The same beat as the
/// card press — one press, one speed, wherever it lands.
struct GoldCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

/// Press feedback for a bare glyph — the header's search glass, a
/// month arrow, a row's chevron: it dims and draws in a little under
/// the finger, so chrome taps never feel dead.
struct QuietGlyphButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
