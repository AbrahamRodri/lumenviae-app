//
//  ChantLearnSection.swift
//  Lumen Viae
//
//  The Learn board: chant learned by heart, a chant at a time, in four
//  steps — listen, read along, sing along, on your own. The course stands
//  as numbered paths: the Rosary's short prayers first, then the
//  antiphons of Our Lady, then the hymns of adoration, and more beneath
//  "See more". Each chant on a path shows where the learner stands with
//  it, and opens its practice.
//
//  Nothing here counts against anyone: what is shown is what the learner
//  has done — chants learned, chants under way — never what they have
//  not. A chant is learned when they say so.
//

import SwiftUI

struct ChantLearnSection: View {

    let open: (Chant) -> Void
    let learn: (Chant) -> Void

    private var shelf = ChantShelfStore.shared

    @State private var showsAll = false

    init(open: @escaping (Chant) -> Void, learn: @escaping (Chant) -> Void) {
        self.open = open
        self.learn = learn
    }

    private var paths: [ChantLearningPath] {
        showsAll ? ChantLibraryData.learningPaths : Array(ChantLibraryData.learningPaths.prefix(ChantLibraryData.openPaths))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            if !shelf.learned.isEmpty || shelf.inProgressCount > 0 {
                ledger
                    .padding(.horizontal, 20)
            }

            fourSteps
                .padding(.horizontal, 20)

            seasonal
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 30) {
                ForEach(Array(paths.enumerated()), id: \.element.id) { number, path in
                    pathView(path, number: number + 1)
                }
            }
            .padding(.horizontal, 20)

            if !showsAll, ChantLibraryData.learningPaths.count > ChantLibraryData.openPaths {
                Button {
                    withAnimation(Motion.crossfade) { showsAll = true }
                } label: {
                    Text("See more chants to learn")
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.gold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Ledger

    /// What the learner has done, and nothing they have not
    private var ledger: some View {
        HStack(spacing: 0) {
            if !shelf.learned.isEmpty {
                ledgerCell(shelf.learned.count, "learned")
            }
            if !shelf.learned.isEmpty, shelf.inProgressCount > 0 {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.24))
                    .frame(width: AppLine.hairline, height: 40)
            }
            if shelf.inProgressCount > 0 {
                ledgerCell(shelf.inProgressCount, "under way")
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) { ChantRule(opacity: 0.24) }
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.24) }
        .accessibilityElement(children: .combine)
    }

    private func ledgerCell(_ figure: Int, _ word: String) -> some View {
        VStack(spacing: 2) {
            Text("\(figure)")
                .font(AppFonts.titleFont(24))
                .foregroundColor(AppColors.cream)
                .monospacedDigit()
            Text(word)
                .font(AppFonts.readingItalicFont(13))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - The four steps

    private var fourSteps: some View {
        VStack(spacing: 14) {
            Text("Every chant is learned in four steps")
                .font(AppFonts.readingFont(16))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            HStack(alignment: .top, spacing: 6) {
                ForEach(ChantLearningStep.allCases) { step in
                    VStack(spacing: 5) {
                        Text("\(step.rawValue)")
                            .font(AppFonts.labelFont(10))
                            .foregroundColor(AppColors.gold)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.6), lineWidth: AppLine.hairline))
                        Text(step.title)
                            .font(AppFonts.readingFont(14))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        Text(step.note)
                            .font(AppFonts.readingItalicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
    }

    // MARK: - Before the season

    @ViewBuilder
    private var seasonal: some View {
        let next = ChantYear.containing(Date()).daysUntilNextSeason(from: Date())
        if let chant = next.season.signatureChant, !shelf.isLearned(chant.id), next.days <= 70 {
            Button {
                learn(chant)
            } label: {
                HStack(spacing: 14) {
                    ChantThumbnail(name: ChantCatalog.painting(subject: next.season.painting), size: 52, radius: 26)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(startsLine(next.season, days: next.days).uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.5)
                            .foregroundColor(AppColors.gold)
                        Text("Learn “\(chant.englishTitle)” before \(next.season.prose)")
                            .font(AppFonts.readingFont(16.5))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(chant.latinTitle) · for \(next.season.prose) · \(chant.durationLabel)")
                            .font(AppFonts.readingItalicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("\(chant.latinTitle), for \(next.season.prose), \(ChantPlayer.spoken(chant.duration))")
                    }
                    Spacer(minLength: 6)
                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .chantShell(padding: 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the practice for this chant")
        }
    }

    private func startsLine(_ season: ChantSeason, days: Int) -> String {
        switch days {
        case 0: return "\(season.title) begins today"
        case 1: return "\(season.title) begins tomorrow"
        default: return "\(season.title) begins in \(days) days"
        }
    }

    // MARK: - A path

    private func pathView(_ path: ChantLearningPath, number: Int) -> some View {
        let learned = path.chants.filter { shelf.isLearned($0.id) }.count

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(AppFonts.labelFont(11))
                    .foregroundColor(AppColors.gold)
                    .frame(width: 26, height: 26)
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(path.title)
                        .font(AppFonts.titleFont(16))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    HStack(alignment: .firstTextBaseline) {
                        Text(path.note)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        if learned > 0 {
                            Text(learned == path.chants.count ? "All learned" : "\(learned) of \(path.chants.count) learned")
                                .font(AppFonts.readingItalicFont(12.5))
                                .foregroundColor(AppColors.gold.opacity(0.85))
                                .lineLimit(1)
                                .fixedSize()
                        }
                    }
                }
            }
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(Array(path.chants.enumerated()), id: \.element.id) { index, chant in
                    pathRow(chant, isLast: index == path.chants.count - 1)
                }
            }
        }
    }

    private func pathRow(_ chant: Chant, isLast: Bool) -> some View {
        let learned = shelf.isLearned(chant.id)
        let step = shelf.step(of: chant.id)
        // The chant touched last is the board's one gold act; any other
        // under way keeps its CONTINUE outlined
        let latest = shelf.latestInProgress?.chant.id == chant.id

        return Button {
            if learned { open(chant) } else { learn(chant) }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                bead(learned: learned, step: step)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chant.latinTitle)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(chant.englishTitle)
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if learned {
                        Text("Learned")
                            .font(AppFonts.readingFont(13))
                            .foregroundColor(AppColors.gold)
                    } else if let step {
                        Text("Step \(step.rawValue) of 4: \(step.title)")
                            .font(AppFonts.readingFont(13))
                            .foregroundColor(AppColors.goldLight)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if step != nil, !learned {
                    Text("CONTINUE")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(1.5)
                        .foregroundColor(latest ? AppColors.background : AppColors.goldLight)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Capsule().fill(latest ? AppColors.gold : Color.clear))
                        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(latest ? 0 : 0.6), lineWidth: 1))
                        .padding(.top, 6)
                } else {
                    Text(chant.durationLabel)
                        .font(AppFonts.labelFont(9))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                        .padding(.top, 6)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, step != nil && !learned ? 10 : 0)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.gold.opacity(step != nil && !learned ? 0.07 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.25))
                    .frame(width: 1)
                    .padding(.leading, step != nil && !learned ? 23 : 13)
                    .padding(.top, 38)
                    .padding(.bottom, -10)
                    .accessibilityHidden(true)
            }
        }
        .chantContextMenu(chant)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowLabel(chant, learned: learned, step: step))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(learned ? "Opens the chant" : "Opens the practice for this chant")
    }

    /// The row as VoiceOver says it: its length in words, not "1:05"
    private func rowLabel(_ chant: Chant, learned: Bool, step: ChantLearningStep?) -> String {
        var parts = [chant.latinTitle, chant.englishTitle]
        if learned {
            parts.append("Learned")
        } else if let step {
            parts.append("Step \(step.rawValue) of 4: \(step.title)")
        }
        parts.append(ChantPlayer.spoken(chant.duration))
        return parts.joined(separator: ", ")
    }

    /// Learned: a gold bead with a check. Under way: a ring filled as far
    /// as the steps taken. Not begun: a ring, and nothing said of it.
    private func bead(learned: Bool, step: ChantLearningStep?) -> some View {
        ZStack {
            Circle()
                .fill(learned ? AppColors.gold : AppColors.background)
            Circle()
                .strokeBorder(AppColors.gold.opacity(learned ? 0 : 0.45), lineWidth: 1)
            if let step, !learned {
                Circle()
                    .trim(from: 0, to: CGFloat(step.rawValue - 1) / 4 + 0.125)
                    .stroke(AppColors.goldLight, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(3)
            }
            if learned {
                AppIcon("ph-check", size: 12)
                    .foregroundColor(AppColors.background)
            }
        }
        .frame(width: 26, height: 26)
        .padding(.top, 2)
        .accessibilityHidden(true)
    }
}
