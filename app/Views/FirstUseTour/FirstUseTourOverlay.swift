//
//  FirstUseTourOverlay.swift
//  Lumen Viae
//
//  The tour's coach mark: the page dimmed in the theme's own deep ground,
//  the control of the stop left in the light and ringed in gold, and
//  beside it a small card saying what it is. The card carries the
//  tour's strand of beads (where you are, never how long), a way on, and
//  a way to leave on purpose. A tap anywhere else does nothing: the tour
//  cannot be lost by accident, and nothing under it can be pressed
//  while it stands.
//
//  Its acts are quiet gold words, never a filled gold button: the home
//  page beneath already has its one.
//
//  The light travels from one control to the next. Under Reduce Motion it
//  does not travel: one mark fades out and the next fades in.
//

import SwiftUI

struct FirstUseTourOverlay: View {

    let tour: FirstUseTour

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// VoiceOver's place, moved to the card's words at each stop
    @AccessibilityFocusState private var wordsFocused: Bool

    /// Room left around a control inside the light
    private static let margin: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let origin = geometry.frame(in: .global).origin
            if let stop = tour.stop, let frame = tour.frames[stop] {
                let lit = frame
                    .offsetBy(dx: -origin.x, dy: -origin.y)
                    .insetBy(dx: -Self.margin, dy: -Self.margin)
                // A control as wide as the page is lit inside the glass, so
                // its gold rim is seen on both sides rather than cut off by
                // them; a round one keeps its circle
                let hole = stop.isRound
                    ? lit
                    : lit.intersection(CGRect(origin: .zero, size: geometry.size).insetBy(dx: 6, dy: 6))

                Group {
                    if reduceMotion {
                        mark(stop, hole: hole, in: geometry.size)
                            .id(stop)
                            .transition(.opacity)
                    } else {
                        mark(stop, hole: hole, in: geometry.size)
                    }
                }
                .animation(reduceMotion ? Motion.crossfade : Motion.travel(0.45), value: stop)
            }
        }
        .ignoresSafeArea()
        .onChange(of: tour.stop, initial: true) { _, stop in
            if stop != nil { wordsFocused = true }
        }
    }

    private func mark(_ stop: FirstUseTourStop, hole: CGRect, in size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            dimming(around: hole, stop: stop)

            card(for: stop, near: hole, in: size)
        }
    }

    // MARK: - The Dimming

    private func dimming(around hole: CGRect, stop: FirstUseTourStop) -> some View {
        let radius = stop.isRound ? min(hole.width, hole.height) / 2 : 18

        return ZStack {
            TourSpotlight(hole: hole, radius: radius)
                .fill(AppColors.backgroundDeep.opacity(0.8), style: FillStyle(eoFill: true))

            TourSpotlight(hole: hole, radius: radius, ringOnly: true)
                .stroke(AppColors.goldLight.opacity(0.7), lineWidth: 1.2)
                .shadow(color: AppColors.gold.opacity(0.45), radius: 10)
        }
        // Every touch lands here and goes no further: the page under the
        // tour cannot be pressed, and a stray tap does not end it
        .contentShape(Rectangle())
        .onTapGesture {}
        .accessibilityHidden(true)
    }

    // MARK: - The Card

    private static let cardWidth: CGFloat = 320
    private static let gap: CGFloat = 16

    private func card(for stop: FirstUseTourStop, near hole: CGRect, in size: CGSize) -> some View {
        let width = min(Self.cardWidth, size.width - 32)
        // Beneath the control when it stands in the top half of the
        // screen, above it otherwise
        let below = hole.midY < size.height / 2
        let x = min(max(hole.midX - width / 2, 16), size.width - width - 16)
        let isLast = stop == FirstUseTourStop.allCases.last

        return VStack(alignment: .leading, spacing: 12) {
            RosaryBeadProgress(
                total: FirstUseTourStop.allCases.count,
                completed: stop.rawValue + 1,
                activeIndex: stop.rawValue,
                beadSize: 7,
                breathes: false
            )
            .frame(width: 84)
            .accessibilityHidden(true)

            // One slot: the stop's words crossfade whole over the last
            // stop's, with nothing laid out beneath them
            ZStack(alignment: .topLeading) {
                words(for: stop)
                    .id(stop)
                    .transition(.opacity)
            }

            HStack {
                QuietGoldButton(
                    title: "Leave the tour",
                    color: AppColors.textSecondary,
                    horizontalPadding: 0
                ) {
                    withAnimation(Motion.crossfade) { tour.end() }
                }
                .frame(minHeight: 44)

                Spacer(minLength: 12)

                QuietGoldButton(
                    title: isLast ? "Done" : "Next",
                    trailingIcon: isLast ? nil : "ph-caret-right",
                    color: AppColors.goldLight,
                    horizontalPadding: 0
                ) {
                    tour.advance()
                }
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 6)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
        .alignmentGuide(.top) { card in
            below ? -(hole.maxY + Self.gap) : -(hole.minY - Self.gap - card.height)
        }
        .offset(x: x)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func words(for stop: FirstUseTourStop) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stop.name.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(stop.words)
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(stop.rawValue + 1) of \(FirstUseTourStop.allCases.count). \(stop.name). \(stop.words)")
        .accessibilityFocused($wordsFocused)
    }
}

// MARK: - TourSpotlight

/// The screen with a rounded window cut in it, or the window's rim alone.
/// A shape, not a drawn path, so the window travels from one control to
/// the next instead of jumping. Nonisolated because SwiftUI may read an
/// animatable value off the main actor.
private nonisolated struct TourSpotlight: Shape {
    var hole: CGRect
    var radius: CGFloat
    var ringOnly = false

    var animatableData: AnimatablePair<
        AnimatablePair<CGFloat, CGFloat>,
        AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat>
    > {
        get {
            AnimatablePair(
                AnimatablePair(hole.minX, hole.minY),
                AnimatablePair(AnimatablePair(hole.width, hole.height), radius)
            )
        }
        set {
            hole = CGRect(
                x: newValue.first.first,
                y: newValue.first.second,
                width: newValue.second.first.first,
                height: newValue.second.first.second
            )
            radius = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if !ringOnly {
            path.addRect(rect)
        }
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: radius, height: radius))
        return path
    }
}
