//
//  PrayerSwipeHint.swift
//  Lumen Viae
//
//  The one-time hint that the page is swiped: left between mysteries
//  off the beads, down a bead at a time on them.
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

    /// On the beads the Rosary moves a bead at a time, downward. The hint
    /// shows only once the beads unlock — after the meditation has been
    /// heard — so it teaches the swipe and nothing else. Off them
    /// the page is swiped left between mysteries.
    var onBeads = false

    /// Drives the drift. Starts false so the first frame is at rest and
    /// the glyph has somewhere to travel from.
    @State private var drifting = false

    var body: some View {
        HStack(spacing: 9) {
            // Names the act before the gesture. The screen shows a
            // painting and a transport and nothing that says the decade
            // is prayed on the user's own beads; onboarding says it once,
            // eight slides before they get here, and never again.
            Text(onBeads ? "Swipe down for the next bead" : "Pray the decade, then swipe left")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.cream.opacity(onBeads ? 0.78 : 0.6))

            // The glyph drifts the way the Rosary moves forward — down
            // the string on the beads, leftward off them — never the way
            // that goes back
            if onBeads {
                AppIcon("ph-caret-down", size: 14)
                    .foregroundColor(AppColors.gold.opacity(0.9))
                    .offset(y: drifting ? 6 : -4)
                    .opacity(drifting ? 0.15 : 1)
            } else {
                AppIcon("ph-hand-swipe-left", size: 17)
                    .foregroundColor(AppColors.gold.opacity(0.9))
                    .offset(x: drifting ? -8 : 6)
                    .opacity(drifting ? 0.15 : 1)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 16)
        // Off the beads the hint sits inside the controls, on the frost;
        // on them it floats over the painting's foot, where a wash of
        // black at a quarter strength vanished into the frost — so
        // there it takes the page's own ground and a hairline
        .background(
            Capsule()
                .fill(onBeads ? AppColors.background.opacity(0.74) : Color.black.opacity(0.28))
        )
        .overlay {
            if onBeads {
                Capsule()
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
            }
        }
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
    VStack(spacing: 24) {
        PrayerSwipeHint()
        PrayerSwipeHint(onBeads: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}
