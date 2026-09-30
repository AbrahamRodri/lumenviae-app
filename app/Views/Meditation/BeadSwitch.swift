//
//  BeadSwitch.swift
//  Lumen Viae
//
//  A switch in the app's own hand, and the pill that names one.
//
//  These once lived beside the HOW YOU'LL PRAY line and its sheet, which
//  the Rosary's own pages have replaced with the choices set out above
//  PRAY (`RosaryConfirmPage`). The switch still stands wherever a single
//  setting is on or off — the prayers after the Rosary, the Scriptural
//  Rosary's Whole Rosary in its foot.
//

import SwiftUI

// MARK: - SetupTogglePill

/// A named switch as one capsule: the icon, the words, and a bead for a
/// knob. The whole pill is the target; the switch inside it is only the
/// drawing.
struct SetupTogglePill: View {

    let icon: String
    let title: String
    @Binding var isOn: Bool
    var hint: String = ""

    var body: some View {
        Button {
            withAnimation(Motion.settle) { isOn.toggle() }
        } label: {
            HStack(spacing: 7) {
                AppIcon(icon, size: 14)
                    .foregroundColor(isOn ? AppColors.gold : AppColors.cream.opacity(0.6))

                Text(title)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream.opacity(isOn ? 1 : 0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                BeadSwitch(isOn: isOn)
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(AppColors.cardElevated))
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isToggle)
    }
}

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
