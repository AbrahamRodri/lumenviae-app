//
//  ChantLibraryView.swift
//  Lumen Viae
//
//  The Chant Library: the Church's own songs, each with its recording and
//  its score, to hear, to follow and to learn. It opens on the antiphon of
//  Our Lady the season sings tonight, then stands its shelves in the order
//  a year of prayer meets them — Our Lady, the Rosary, the Blessed
//  Sacrament, the Holy Ghost, the seasons, the dead.
//
//  A row plays where it stands (its disc) or opens the chant's own page
//  (everything else in it), so a reader can listen down a shelf without
//  leaving it. Everything here is bundled: a chapel with no signal still
//  has every chant.
//
//  Reached from the Chapel's Chant tile, Explore, and a chant's page.
//

import SwiftUI

struct ChantLibraryView: View {

    @Environment(AppRouter.self) private var router

    private var player = ChantPlayer.shared

    init() {}

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .padding(.horizontal, 28)
                        .devotionalEntrance()

                    if let antiphon = ChantCatalog.antiphonOfTheSeason() {
                        ofTheSeason(antiphon)
                            .padding(.horizontal, 24)
                            .padding(.top, 30)
                    }

                    ForEach(ChantCatalog.groups) { group in
                        shelf(group)
                            .padding(.horizontal, 24)
                            .padding(.top, 38)
                    }

                    ChantCredit()
                        .padding(.horizontal, 36)
                        .padding(.top, 44)
                        .padding(.bottom, 48)
                }
                .padding(.top, 8)
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(spacing: 14) {
            Text("SUNG PRAYER")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            OrnamentDivider()
                .frame(width: 150)

            Text("The Chant Library")
                .font(AppFonts.titleFont(28))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("The Church's own songs, each with its recording and its score — to hear, to follow, and to learn by heart.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(ChantCatalog.all.count) chants in Latin · kept on this phone".uppercased())
                .font(AppFonts.labelFont(8.5))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Of the season

    /// Tonight's antiphon of Our Lady, lifted out of its shelf
    private func ofTheSeason(_ chant: Chant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUNG TONIGHT")
                .font(AppFonts.labelFont(8.5))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.8))

            HStack(spacing: 16) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 50,
                    label: chant.latinTitle
                ) {
                    player.toggle(chant)
                }

                Button {
                    router.push(.chant(id: chant.id))
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chant.latinTitle)
                                .font(AppFonts.headlineFont(19))
                                .foregroundColor(AppColors.cream)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("The antiphon of Our Lady for this season, sung at the close of the day")
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 6)
                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.gold.opacity(0.5))
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the chant with its score")
            }
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
    }

    // MARK: - Shelves

    private func shelf(_ group: ChantGroup) -> some View {
        let chants = ChantCatalog.chants(in: group)
        return VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                Text(group.title)
                    .font(AppFonts.headlineFont(19))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
                if let note = group.note {
                    Text(note)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            Rectangle()
                .fill(AppColors.gold.opacity(0.3))
                .frame(height: AppLine.hairline)

            VStack(spacing: 0) {
                ForEach(chants) { chant in
                    ChantLibraryRow(chant: chant, player: player) {
                        router.push(.chant(id: chant.id))
                    }
                }
            }
        }
    }
}

// MARK: - ChantLibraryRow

/// A chant on its shelf: its disc to play it where it stands, then its
/// names, its length, and a caret to its page.
struct ChantLibraryRow: View {
    let chant: Chant
    let player: ChantPlayer
    let open: () -> Void

    private var sounding: Bool { player.isPlaying(chant) }

    var body: some View {
        HStack(spacing: 12) {
            ChantPlayDisc(
                isPlaying: sounding,
                isLoading: player.current.id == chant.id && player.isLoading,
                size: 34,
                label: chant.latinTitle
            ) {
                player.toggle(chant)
            }

            Button(action: open) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(chant.latinTitle)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(sounding ? AppColors.goldLight : AppColors.cream.opacity(0.94))
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(Motion.crossfade, value: sounding)

                        Text(subtitle)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text(chant.durationLabel)
                        .font(AppFonts.labelFont(9))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()

                    AppIcon("ph-caret-right", size: 10)
                        .foregroundColor(AppColors.gold.opacity(0.45))
                }
                .padding(.vertical, 10)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(chant.latinTitle), \(subtitle), \(chant.durationLabel)")
            .accessibilityHint("Opens the chant with its score")
            .accessibilityAddTraits(.isButton)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.12))
                .frame(height: AppLine.hairline)
        }
    }

    private var subtitle: String {
        if let setting = chant.setting {
            return "\(chant.englishTitle) · \(setting.lowercased())"
        }
        return chant.englishTitle
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChantLibraryView()
            .environment(AppRouter())
    }
}
