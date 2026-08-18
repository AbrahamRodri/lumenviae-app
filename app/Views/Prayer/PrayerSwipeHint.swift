//
//  PrayerSwipeHint.swift
//  Lumen Viae
//
//  The one-time hint that the page can be swiped between mysteries.
//
//  Deliberately not a coach-mark overlay with a cutout and a dimmed
//  screen: this is a prayer screen, and stopping the Rosary to run a
//  tutorial over a painting of the Annunciation is the wrong register.
//  It is a line of small caps and a hand that moves the way the page
//  does, sitting quietly above the transport.
//
//  It teaches a shortcut, never a requirement — the arrows in the
//  transport do everything the swipe does — so it shows once in a
//  lifetime, retires itself, and leaves at the first touch.
//

import SwiftUI

struct PrayerSwipeHint: View {

    /// Drives the drift. Starts false so the first frame is at rest and
    /// the glyph has somewhere to travel from.
    @State private var drifting = false

    var body: some View {
        HStack(spacing: 9) {
            Text("Swipe left for the next mystery")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.cream.opacity(0.6))

            // Leftward, because a leftward swipe is what carries the
            // Rosary forward — a hand drifting the other way would teach
            // the gesture that goes back
            AppIcon("ph-hand-swipe-left", size: 17)
                .foregroundColor(AppColors.gold.opacity(0.9))
                .offset(x: drifting ? -8 : 6)
                .opacity(drifting ? 0.15 : 1)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.28))
        )
        .allowsHitTesting(false)
        // The hint describes a gesture VoiceOver cannot perform, and the
        // buttons it duplicates are already labelled
        .accessibilityHidden(true)
        .onAppear {
            // A finite number of passes, not repeatForever: the hint should
            // demonstrate the gesture and then be finished, so the drift
            // runs out at about the moment the hint fades
            withAnimation(.easeInOut(duration: 1.4).repeatCount(3, autoreverses: false)) {
                drifting = true
            }
        }
    }
}

#Preview {
    PrayerSwipeHint()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
}
