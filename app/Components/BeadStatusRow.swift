//
//  BeadStatusRow.swift
//  Lumen Viae
//
//  The bead under the hand, in words, and what to do next: OUR FATHER,
//  a hairline, then the cue — "Listen to the meditation, then swipe
//  down for the first Hail Mary". On the last bead of all the cue gives
//  way to AMEN, the one act that finishes a Rosary; a swipe never does.
//
//  The strand at the screen's edge draws the same fact; this row is
//  where VoiceOver reads it, and where a hand that cannot swipe still
//  prays the bead forward — tap the row for the next bead, hold it for
//  the one before. The reader carries this row where the player carries
//  the strand, so the count is the same on whichever surface the
//  meditation is prayed.
//
//  The row keeps one identity from bead to bead. Its count rolls the
//  way a counter does — 4 OF 10 to 5 OF 10 — and the cue crossfades in
//  place; nothing is torn down and rebuilt, so the row never jumps
//  under the thumb that just tapped it.
//

import SwiftUI

struct BeadStatusRow: View {

    /// "Our Father", "Hail Mary · 4 of 10", "Glory Be" — set in caps
    let label: String

    /// What to do next. Nil on the final bead, where AMEN stands instead.
    let cue: String?

    /// Finishes the Rosary. Present only on the final bead.
    var onAmen: (() -> Void)?

    /// True when the hand stepped back, so the count rolls down
    var countsDown: Bool = false

    let onAdvance: () -> Void
    let onRetreat: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(label.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(1.5)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.numericText(countsDown: countsDown))

            Rectangle()
                .fill(AppColors.gold.opacity(0.4))
                .frame(width: 1, height: 10)

            // One slot for the cue and for AMEN, so the two crossfade
            // over each other rather than standing side by side for the
            // length of the transition
            ZStack(alignment: .leading) {
                if let onAmen {
                    GoldCTAButton(
                        title: "Amen",
                        prominence: .inline,
                        trailingIcon: "ph-check",
                        fullWidth: false,
                        action: onAmen
                    )
                    .accessibilityLabel("Amen — finish the Rosary")
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                } else if let cue {
                    Text(cue)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.6))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentTransition(.opacity)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The whole row is the tap target, at the 44pt minimum: a thumb
        // praying in the dark should not have to find a word
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture(perform: onAdvance)
        .onLongPressGesture(perform: onRetreat)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(onAmen == nil ? "Tap for the next bead" : "")
        .accessibilityAction(named: "Next bead", onAdvance)
        .accessibilityAction(named: "Previous bead", onRetreat)
    }

    private var accessibilityText: String {
        var parts = [label]
        if let cue { parts.append(cue) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        BeadStatusRow(
            label: "Our Father",
            cue: "Listen to the meditation, then swipe down for the first Hail Mary",
            onAdvance: {},
            onRetreat: {}
        )
        BeadStatusRow(
            label: "Hail Mary · 4 of 10",
            cue: "Swipe down for the next bead",
            onAdvance: {},
            onRetreat: {}
        )
        BeadStatusRow(
            label: "Glory Be",
            cue: "The Second Sorrowful Mystery follows on the next swipe.",
            onAdvance: {},
            onRetreat: {}
        )
        BeadStatusRow(
            label: "Glory Be",
            cue: nil,
            onAmen: {},
            onAdvance: {},
            onRetreat: {}
        )
    }
    .padding(22)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}
