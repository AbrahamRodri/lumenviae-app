//
//  Motion.swift
//  Lumen Viae
//
//  Reverent motion helpers. All animation here is slow, soft, and
//  optional — every helper quiets itself when Reduce Motion is on.
//

import SwiftUI

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
struct SacredCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

/// Press feedback for gold call-to-action pills.
struct GoldCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
