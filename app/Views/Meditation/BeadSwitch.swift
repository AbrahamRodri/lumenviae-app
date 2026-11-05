//
//  BeadSwitch.swift
//  Lumen Viae
//
//  A switch in the app's own hand, wherever a single setting is on or
//  off: the prayers after the Rosary in the Voice & speed sheet.
//

import SwiftUI

// MARK: - BeadSwitch

/// A switch in the app's own hand: a hairline track with a bead for its
/// knob. On, the bead is lit with the same gold sheen as a prayed bead
/// on the strand and rests at the right on a track washed with gold;
/// off, it is a hollow bead at the left on a track barely there. The
/// knob travels with `Motion.settle`, so the change is seen, not just
/// the result.
struct BeadSwitch: View {
    let isOn: Bool

    private let width: CGFloat = 38
    private let height: CGFloat = 22
    private let knob: CGFloat = 16

    var body: some View {
        let travel = (width - knob) / 2 - 3

        ZStack {
            Capsule()
                .fill(isOn ? AppColors.gold.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    Capsule().strokeBorder(
                        isOn ? AppColors.gold.opacity(0.75) : AppColors.cream.opacity(0.3),
                        lineWidth: AppLine.hairline
                    )
                )

            Circle()
                .fill(isOn ? AnyShapeStyle(AppColors.goldGradient) : AnyShapeStyle(AppColors.cream.opacity(0.12)))
                .overlay(
                    Circle().strokeBorder(
                        isOn ? Color.clear : AppColors.cream.opacity(0.6),
                        lineWidth: 1
                    )
                )
                .frame(width: knob, height: knob)
                .shadow(color: isOn ? AppColors.gold.opacity(0.5) : .clear, radius: 4)
                .offset(x: isOn ? travel : -travel)
        }
        .frame(width: width, height: height)
        .animation(Motion.settle, value: isOn)
        .accessibilityHidden(true)
    }
}
