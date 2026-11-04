//
//  OneRosaryViews.swift
//  Lumen Viae
//
//  What the One Rosary beta (`UserSettings.oneRosaryBeta`) draws: the
//  whole Rosary at a glance on its own page (`RosaryOverviewSection`),
//  the Helps line on the players (`RosaryHelpLine`), and the one layout
//  the opening and closing prayers share on both players
//  (`PendantPrayerPanel`), taken from the meditation's player, whose
//  Back and Next already stood under the words.
//
//  Off, none of this is drawn.
//

import SwiftUI

// MARK: - RosaryOverviewSection

/// THE WHOLE ROSARY: a small drawing of the rosary beside the order of
/// the prayer, opening to close, as a ruled ledger, so the Rosary can be
/// seen whole before PRAY. The chaplet has no drawing: the rosary drawn
/// is the Rosary's five decades.
struct RosaryOverviewSection: View {

    let category: MysteryCategory

    /// Whether the opening and closing prayers are prayed
    let includesPendant: Bool

    private var overview: RosaryOverview {
        RosaryOverview(category: category, includesPendant: includesPendant)
    }

    var body: some View {
        let overview = overview

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(
                    "THE WHOLE ROSARY",
                    comment:
                        "One Rosary beta, a Rosary's own page: heading over the order of the whole Rosary, before PRAY"
                )
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .accessibilityAddTraits(.isHeader)

                LinearGradient(
                    colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: AppLine.hairline)
                .accessibilityHidden(true)
            }

            HStack(alignment: .top, spacing: 18) {
                if category != .sevenSorrows {
                    RosaryDiagram()
                        .frame(width: 84)
                        .padding(.top, 4)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(overview.parts) { part in
                        row(part, isLast: part == overview.parts.last)
                    }

                    Text(overview.decadeNote)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, 18)
    }

    private func row(_ part: RosaryOverview.Part, isLast: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Group {
                if case .mystery(let number) = part.kind {
                    Text(verbatim: "\(number)")
                        .font(AppFonts.labelFont(10))
                        .foregroundColor(AppColors.gold.opacity(0.75))
                } else {
                    AppIcon("lv-lozenge", size: 7)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
            }
            .frame(width: 14, alignment: .leading)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(part.title)
                    .font(part.detail == nil ? AppFonts.bodyFont(16) : AppFonts.headlineFont(13))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = part.detail {
                    Text(detail)
                        .font(AppFonts.italicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(height: AppLine.hairline)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - RosaryHelpLine

/// With Helps on: where the hand is and what to do there, one plain
/// line under a small kicker, from the Guided Rosary's own words
struct RosaryHelpLine: View {
    let line: RosaryHelps.Line

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(line.place.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(1.8)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(line.instruction)
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.88))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.6), radius: 5, y: 1)
        .contentTransition(.opacity)
        .animation(Motion.words, value: line)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - PendantPrayerPanel

/// The opening or closing prayer under the hand, prayed in silence, laid
/// out the same on both players: where it stands ("The Opening Prayers ·
/// 2 of 7"), its name, its words, and Back and Next beneath — AMEN on the
/// last of the close. The swipe does what Back and Next do. The pendant
/// is drawn above it, centred, by the player.
struct PendantPrayerPanel: View {

    let pendant: SpokenPendant

    /// "2 of 7"
    let count: String

    /// The prayer's words, line by line
    let lines: [String]

    let isFirst: Bool
    let isLast: Bool
    let isLastOpening: Bool

    /// With Helps on, the line for this prayer
    var help: RosaryHelps.Line? = nil

    /// The most the words may take, so the pendant keeps its room
    let wordsMaxHeight: CGFloat

    let onBack: () -> Void
    let onNext: () -> Void
    let onAmen: () -> Void

    var body: some View {
        // The long prayers — the Creed, the Hail, Holy Queen, the closing
        // prayer — a size down, so the pendant keeps room above them
        let wordsSize: CGFloat = lines.joined().count > 280 ? 15 : 17
        let words = Rubric.paragraph(lines, size: wordsSize)

        VStack(alignment: .leading, spacing: 0) {
            if let help {
                RosaryHelpLine(line: help)
                    .padding(.bottom, 14)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("\(pendant.heading) · \(count)".uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                    .contentTransition(.opacity)

                Text(pendant.title)
                    .font(AppFonts.headlineFont(24))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                ViewThatFits(in: .vertical) {
                    wordsText(words, size: wordsSize)
                        .fixedSize(horizontal: false, vertical: true)
                    wordsText(words, size: wordsSize)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxHeight: wordsMaxHeight, alignment: .topLeading)
                .padding(.top, 6)
                .contentTransition(.opacity)

                AITranslationNote(prayerID: pendant.prayerID)

                if isFirst {
                    Text(SilentPendant.openingSummary(isChaplet: pendant.isChaplet))
                        .font(AppFonts.italicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
            .animation(Motion.words, value: pendant)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                QuietGoldButton(
                    title: String(
                        localized: "Back",
                        comment:
                            "Prayer screen, the opening and closing prayers: the quiet button back to the prayer before"
                    ),
                    leadingIcon: "ph-caret-left",
                    leadingIconSize: 10,
                    horizontalPadding: 0,
                    action: onBack
                )
                .disabled(isFirst)
                .opacity(isFirst ? 0.3 : 1)
                .accessibilityLabel("Previous prayer")

                Spacer(minLength: 8)

                if isLast {
                    GoldCTAButton(
                        title: String(
                            localized: "Amen",
                            comment: "Prayer screen, last closing prayer: the gold button that finishes the Rosary"
                        ),
                        prominence: .inline,
                        trailingIcon: "ph-check",
                        fullWidth: false,
                        action: onAmen
                    )
                    .accessibilityLabel("Amen — finish the Rosary")
                    .transition(.opacity)
                } else {
                    QuietGoldButton(
                        title: nextTitle,
                        trailingIcon: "ph-caret-right",
                        horizontalPadding: 0,
                        action: onNext
                    )
                }
            }
            .frame(minHeight: 44)
            .padding(.top, 18)
            .animation(Motion.settle, value: isLast)
        }
    }

    private var nextTitle: String {
        guard isLastOpening else {
            return String(
                localized: "Next prayer",
                comment: "Prayer screen, the opening and closing prayers: the button on to the next prayer"
            )
        }
        return pendant.isChaplet
            ? String(
                localized: "The first sorrow",
                comment:
                    "Prayer screen, last opening prayer of the Seven Sorrows chaplet: the button on to the first sorrow"
            )
            : String(
                localized: "The first mystery",
                comment: "Prayer screen, last opening prayer: the button on to the first mystery"
            )
    }

    private func wordsText(_ words: AttributedString, size: CGFloat) -> some View {
        Text(words)
            .font(AppFonts.readingFont(size))
            .foregroundColor(AppColors.cream.opacity(0.92))
            .lineSpacing(size > 15 ? 4 : 2)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
