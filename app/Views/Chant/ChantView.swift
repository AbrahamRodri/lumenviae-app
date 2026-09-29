//
//  ChantView.swift
//  Lumen Viae
//
//  One chant on a page of its own, laid out for learning it: its name in
//  Latin and in English and when it is sung, the recording, then the
//  score to follow while it sounds. Practice asks two more things of the
//  transport — a slower pace, and the chant again from the top when it
//  ends — and the score opens large, to be read at arm's length.
//
//  Beneath: the prayer the chant sings, in words, and its other settings
//  (the solemn tone beside the simple), each a door. The credit stands at
//  the foot, as the recordings' licence asks.
//
//  Reached from the Chant Library, a prayer's own page ("Sing it in
//  chant"), and the Chapel's Chant tile (`AppRoute.chant(id:)`).
//

import SwiftUI

struct ChantView: View {

    let chantID: String

    @Environment(AppRouter.self) private var router

    private var player = ChantPlayer.shared

    @State private var showsScore = false

    init(chantID: String) {
        self.chantID = chantID
    }

    private var chant: Chant? { ChantCatalog.chant(chantID) }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let chant {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        titleBlock(chant)
                            .padding(.horizontal, 28)
                            .devotionalEntrance()

                        transport(chant)
                            .padding(.horizontal, 24)
                            .padding(.top, 28)

                        score(chant)
                            .padding(.horizontal, 20)
                            .padding(.top, 36)

                        doors(chant)
                            .padding(.horizontal, 28)
                            .padding(.top, 36)

                        ChantCredit()
                            .padding(.horizontal, 36)
                            .padding(.top, 40)
                            .padding(.bottom, 48)
                    }
                    .padding(.top, 8)
                }
                .topChromeFade()
            } else {
                Text("This chant could not be found.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }
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
        .sheet(isPresented: $showsScore) {
            if let chant {
                ChantScoreSheet(chant: chant)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
    }

    // MARK: - Title

    private func titleBlock(_ chant: Chant) -> some View {
        VStack(spacing: 14) {
            Text(kicker(chant))
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            OrnamentDivider()
                .frame(width: 150)

            Text(chant.latinTitle)
                .font(AppFonts.titleFont(27))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)

            Text(chant.englishTitle)
                .font(AppFonts.readingItalicFont(17))
                .foregroundColor(AppColors.cream.opacity(0.7))
                .multilineTextAlignment(.center)

            if let setting = chant.distinctSetting {
                Text(setting.uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(chant.detail)
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func kicker(_ chant: Chant) -> String {
        let group = chant.group?.title ?? "Chant"
        return "The Chant Library · \(group)".uppercased()
    }

    // MARK: - Transport

    private func transport(_ chant: Chant) -> some View {
        let holds = player.holds(chant)
        let progress = holds ? player.progress : 0
        let elapsed = holds ? player.currentTime : 0
        let total = holds ? player.duration : chant.duration

        return VStack(spacing: 14) {
            HStack(spacing: 16) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 56,
                    label: chant.latinTitle
                ) {
                    player.toggle(chant)
                }

                VStack(spacing: 4) {
                    ChantScrubber(progress: progress, isEnabled: holds) { fraction in
                        player.seek(toFraction: fraction)
                    }
                    HStack {
                        Text(ChantPlayer.clock(elapsed))
                            .contentTransition(.numericText())
                        Spacer()
                        Text(ChantPlayer.clock(total))
                    }
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
                    .monospacedDigit()
                    .accessibilityHidden(true)
                }
            }

            if let error = player.current.id == chant.id ? player.errorMessage : nil {
                Text(error)
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
            }

            // Practice: a slower pace, the chant again when it ends, and
            // back to the top for another try at a phrase. One row while
            // it fits; at larger text the chips keep a row of their own
            // rather than break SLOW and REPEAT mid-word.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    practiceChips
                    Spacer(minLength: 0)
                    fromTheTop(holds: holds)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 10) { practiceChips }
                    fromTheTop(holds: holds)
                }
                VStack(alignment: .leading, spacing: 2) {
                    practiceChips
                    fromTheTop(holds: holds)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
    }

    @ViewBuilder
    private var practiceChips: some View {
        ChantPracticeChip(title: "Slow", isOn: player.rate < 1) {
            player.setRate(player.rate < 1 ? 1.0 : 0.75)
        }
        .accessibilityHint("Plays at three-quarters speed, for learning")

        ChantPracticeChip(title: "Repeat", isOn: player.repeats) {
            player.repeats.toggle()
        }
        .accessibilityHint("Sings the chant again from the top when it ends")
    }

    private func fromTheTop(holds: Bool) -> some View {
        Button {
            player.restart()
        } label: {
            HStack(spacing: 6) {
                AppIcon("ph-arrow-counter-clockwise", size: 12)
                Text("FROM THE TOP")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .lineLimit(1)
            }
            .foregroundColor(AppColors.gold.opacity(holds ? 0.8 : 0.35))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .disabled(!holds)
        .accessibilityLabel("Start the chant again from the top")
    }

    // MARK: - Score

    private func score(_ chant: Chant) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Both words shrink a little before either breaks mid-word
            HStack(spacing: 10) {
                Text("THE SCORE")
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Rectangle()
                    .fill(AppColors.gold.opacity(0.18))
                    .frame(height: AppLine.hairline)
                Button {
                    showsScore = true
                } label: {
                    Text("ENLARGE")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Enlarge the score")
            }
            .padding(.horizontal, 8)

            Button {
                showsScore = true
            } label: {
                ChantScoreView(parts: chant.score)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the score full screen")
        }
    }

    // MARK: - Doors

    @ViewBuilder
    private func doors(_ chant: Chant) -> some View {
        let prayers = chant.prayerIDs.compactMap { id in
            PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil)
        }
        let others = ChantCatalog.otherSettings(of: chant)

        if !prayers.isEmpty || !others.isEmpty {
            VStack(alignment: .leading, spacing: 22) {
                if !prayers.isEmpty {
                    section("The prayer in words") {
                        ForEach(prayers, id: \.id) { prayer in
                            LedgerDoorRow(title: prayer.title, note: prayer.latinTitle, icon: "ch-praying-hands") {
                                router.push(.devotionPrayer(id: prayer.id))
                            }
                        }
                    }
                }

                if !others.isEmpty {
                    section("Also sung") {
                        ForEach(others) { other in
                            LedgerDoorRow(
                                title: other.fullTitle,
                                note: other.detail,
                                icon: "ph-music-note"
                            ) {
                                router.push(.chant(id: other.id))
                            }
                        }
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                Rectangle()
                    .fill(AppColors.gold.opacity(0.18))
                    .frame(height: AppLine.hairline)
            }
            VStack(spacing: 0) {
                content()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChantView(chantID: "salve_regina_simple")
            .environment(AppRouter())
    }
}
