//
//  ScripturalVerseBand.swift
//  Lumen Viae
//
//  One decade of Scripture, a verse per bead: the small strand shows
//  where the hand is, the verse gives the bead its word. A tap prays the
//  bead forward; a long press steps back one.
//
//  Shared rather than private to the player, because the app prays on
//  two surfaces — the painting and the reader — and whether a verse
//  appears is the view model's answer, not each screen's. A band that
//  lived on only one of them made the Prayer Experience toggle silently
//  do nothing for everyone who reads.
//

import SwiftUI

struct ScripturalVerseBand: View {

    let verse: ScripturalVerse
    let beadIndex: Int
    let beadCount: Int

    /// The reading size the surrounding surface is set at. The verse is
    /// prose like any other reading block, so it follows the Prayer
    /// Experience text size rather than sitting at a fixed point.
    var size: CGFloat = 15

    let onAdvance: () -> Void
    let onRetreat: () -> Void

    /// Strand width scaled to the bead count, so a seven-bead sorrow and
    /// a ten-bead decade keep the same spacing between beads.
    private var strandWidth: CGFloat { CGFloat(beadCount) * 13 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                RosaryBeadProgress(
                    total: beadCount,
                    completed: beadIndex,
                    activeIndex: beadIndex,
                    beadSize: 5
                )
                .frame(width: strandWidth)

                Spacer(minLength: 0)

                Text(verse.reference.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
            }

            // The pull-quote treatment the scripture library already
            // uses: an italic line standing on a gold rule. The row hugs
            // the text's height — a bare Rectangle is infinitely
            // flexible, and left free it would split the player's spare
            // space with the layout's Spacer and drop a gold line down
            // the whole painting.
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.55))
                    .frame(width: 2)

                Text(verse.text)
                    .font(AppFonts.readingItalicFont(size))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .lineSpacing(ReadingTypography.lineSpacing(for: size))
                    .multilineTextAlignment(.leading)
                    .id(verse)
                    .transition(.opacity)
            }
            .fixedSize(horizontal: false, vertical: true)
            .animation(.easeInOut(duration: 0.25), value: verse)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture(perform: onAdvance)
        .onLongPressGesture(perform: onRetreat)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bead \(beadIndex + 1) of \(beadCount). \(verse.reference). \(verse.text)")
        .accessibilityHint("Tap for the next bead's verse")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Previous verse", onRetreat)
    }
}
