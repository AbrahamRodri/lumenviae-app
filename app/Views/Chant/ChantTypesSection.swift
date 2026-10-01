//
//  ChantTypesSection.swift
//  Lumen Viae
//
//  The Types board: the library by kind of chant — antiphons, hymns, the
//  sequences of the great feasts, litanies, psalms and canticles, the
//  everyday prayers — each a lettered tile with how many it holds; the
//  kind chosen listed with each chant's length drawn as a rule; and, for
//  someone with only a minute, the library by how long a chant takes.
//

import SwiftUI

struct ChantTypesSection: View {

    let open: (Chant) -> Void

    private var player = ChantPlayer.shared

    @State private var form: ChantForm = .shortChant
    @State private var byLength = false
    @State private var length: ChantLength = .underAMinute

    init(open: @escaping (Chant) -> Void) {
        self.open = open
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            tiles
                .padding(.horizontal, 20)

            chosenForm
                .padding(.horizontal, 20)
                .animation(Motion.crossfade, value: form)

            shortOnTime
                .padding(.horizontal, 20)
                .animation(Motion.crossfade, value: length)
        }
    }

    // MARK: - Tiles

    private var tiles: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 18
        ) {
            ForEach(ChantForm.allCases) { each in
                tile(each, lit: each == form)
            }
        }
        .sensoryFeedback(.selection, trigger: form)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Types")
    }

    private func tile(_ each: ChantForm, lit: Bool) -> some View {
        let count = each.chants.count
        return Button {
            form = each
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Text(each.letter)
                        .font(AppFonts.titleFont(40))
                        .foregroundColor(lit ? AppColors.goldLight : AppColors.gold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text("\(count)")
                        .font(AppFonts.labelFont(8.5))
                        .foregroundColor(Rubric.red)
                        .padding(8)
                }
                .aspectRatio(1, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.gold.opacity(lit ? 0.1 : 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(AppColors.gold.opacity(lit ? 0.85 : 0.32), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .inset(by: 5)
                        .strokeBorder(AppColors.gold.opacity(lit ? 0.4 : 0.16), lineWidth: AppLine.hairline)
                )
                .shadow(color: lit ? AppColors.gold.opacity(0.3) : .clear, radius: 10)

                Text(each.title.uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.5)
                    .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(each.title), \(count) chants")
        .accessibilityAddTraits(lit ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - The kind chosen

    private var chosenForm: some View {
        let chants = byLength ? form.chants.sorted { $0.duration < $1.duration } : form.chants
        let longest = max(1, form.chants.map(\.duration).max() ?? 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Text(form.letter)
                    .font(AppFonts.titleFont(56))
                    .foregroundColor(Rubric.red)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(form.title)
                        .font(AppFonts.titleFont(22))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(form.note)
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            }

            HStack {
                Text((form.chants.count == 1 ? "1 chant" : "\(form.chants.count) chants").uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Button {
                    byLength.toggle()
                } label: {
                    Text(byLength ? "IN ORDER" : "BY LENGTH")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(1.5)
                        .foregroundColor(AppColors.gold.opacity(0.85))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel(byLength ? "Sort in the library's order" : "Sort by length")
            }
            .overlay(alignment: .bottom) { ChantRule() }

            VStack(spacing: 0) {
                ForEach(chants) { chant in
                    formRow(chant, longest: longest)
                }
            }
            .animation(Motion.crossfade, value: byLength)
        }
    }

    private func formRow(_ chant: Chant, longest: TimeInterval) -> some View {
        Button {
            open(chant)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chant.latinTitle)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(player.isPlaying(chant) ? AppColors.goldLight : AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(context(of: chant))
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                lengthRule(chant.duration, longest: longest)
                    .frame(width: 104)
            }
            .padding(.vertical, 10)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .chantContextMenu(chant)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(chant.latinTitle), \(context(of: chant)), \(ChantPlayer.spoken(chant.duration))")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the chant")
    }

    /// The chant's length as a rule from a gold stud, the longest of its
    /// kind the full width
    private func lengthRule(_ duration: TimeInterval, longest: TimeInterval) -> some View {
        HStack(spacing: 6) {
            GeometryReader { geo in
                let width = max(8, geo.size.width * CGFloat(duration / longest))
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(AppColors.gold)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.55))
                        .frame(width: max(0, width - 6), height: 1)
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.55))
                        .frame(width: 1, height: 7)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 12)
            Text(ChantPlayer.clock(duration))
                .font(AppFonts.labelFont(8.5))
                .tracking(1)
                .foregroundColor(AppColors.textSecondary)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityHidden(true)
    }

    /// What the row says under the name: the feast it is sung on, else
    /// when it is sung
    private func context(of chant: Chant) -> String {
        ChantLibraryData.feasts.first { $0.chantID == chant.id }?.name ?? chant.detail
    }

    // MARK: - Short on time

    private var shortOnTime: some View {
        VStack(alignment: .leading, spacing: 14) {
            ChantSectionHeading(
                kicker: "Short on time?",
                title: "By length",
                note: "Choose a chant that fits the time you have."
            )

            HStack(spacing: 10) {
                ForEach(ChantLength.allCases) { each in
                    lengthBucket(each, lit: each == length)
                }
            }

            ChantFlowLayout(spacing: 8) {
                ForEach(length.chants) { chant in
                    chip(chant)
                }
            }
            .padding(.top, 4)
        }
    }

    private func lengthBucket(_ each: ChantLength, lit: Bool) -> some View {
        Button {
            length = each
        } label: {
            VStack(spacing: 2) {
                Text("\(each.chants.count)")
                    .font(AppFonts.titleFont(20))
                    .foregroundColor(lit ? AppColors.goldLight : AppColors.cream)
                    .monospacedDigit()
                Text(each.title)
                    .font(AppFonts.readingItalicFont(13))
                    .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.gold.opacity(lit ? 0.1 : 0)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColors.gold.opacity(lit ? 0.7 : 0.25), lineWidth: AppLine.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(each.title), \(each.chants.count) chants")
        .accessibilityAddTraits(lit ? [.isSelected, .isButton] : .isButton)
    }

    /// A chant as a capsule: its disc plays it, its name opens it
    private func chip(_ chant: Chant) -> some View {
        HStack(spacing: 8) {
            ChantPlayDisc(
                isPlaying: player.isPlaying(chant),
                isLoading: player.current.id == chant.id && player.isLoading,
                size: 28,
                label: chant.latinTitle
            ) {
                player.toggle(chant)
            }

            Button {
                open(chant)
            } label: {
                HStack(spacing: 6) {
                    Text(chant.distinctSetting.map { "\(chant.latinTitle) · \($0.lowercased())" } ?? chant.latinTitle)
                        .font(AppFonts.readingFont(15))
                        .foregroundColor(player.isPlaying(chant) ? AppColors.goldLight : AppColors.cream)
                        .lineLimit(1)
                    Text(chant.durationLabel)
                        .font(AppFonts.labelFont(8))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the chant")
        }
        .padding(.leading, 0)
        .padding(.trailing, 14)
        .frame(height: 44)
        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.25), lineWidth: AppLine.hairline))
        .chantContextMenu(chant)
    }
}
