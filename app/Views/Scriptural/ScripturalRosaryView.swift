//
//  ScripturalRosaryView.swift
//  Lumen Viae
//
//  The Scriptural Rosary's own page: what it is, and which mysteries to
//  pray it through. Set like a title page, the way a meditation set is
//  — kicker, ornament, name in Cinzel, the painting in a lancet arch —
//  and beneath it a ruled ledger: what the devotion is, the mysteries
//  to choose from (today's already chosen), how the first decade
//  opens, and where the words come from.
//
//  The mysteries section is the picker. Choosing one changes the
//  painting in the arch and the first decade beneath, and nothing is
//  remembered: tomorrow's page opens on tomorrow's mysteries.
//
//  One gold act at the foot begins the prayer, and nothing rides under
//  it — no count, and never a duration.
//

import SwiftUI

struct ScripturalRosaryView: View {
    @Environment(AppRouter.self) private var router

    /// The day's mysteries, marked in the ledger and chosen to begin with
    private let today = ScheduleService.categoryForToday()

    /// The mysteries the prayer will open on
    @State private var category: MysteryCategory

    init() {
        _category = State(initialValue: ScheduleService.categoryForToday())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.appGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        titling
                            .devotionalEntrance()

                        frontispiece(width: min(geometry.size.width * 0.56, 260))
                            .padding(.top, 26)
                            .devotionalEntrance(delay: 0.08)

                        sections
                            .padding(.top, 34)
                            .devotionalEntrance(delay: 0.16)
                    }
                    // Clears the header chrome above and the fixed act below
                    .padding(.top, 62)
                    .padding(.bottom, 200)
                }
                .animation(.easeOut(duration: 0.3), value: category)
                // Scrolled content softens away behind the back button
                // rather than running under it at full strength.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.075),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // The one act, fixed at the foot
                VStack {
                    Spacer()
                    prayFoot
                }

                headerChrome
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Chrome

    private var headerChrome: some View {
        VStack {
            HStack {
                PrayerHeaderButton(icon: "ph-caret-left", size: 16, label: "Back") {
                    router.pop()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Titling

    /// Kicker, ornament, name — the title page, centered and quiet.
    private var titling: some View {
        VStack(spacing: 16) {
            Text("A VERSE FOR EVERY BEAD")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            OrnamentDivider()
                .frame(width: 150)

            Text("The Scriptural Rosary")
                .font(AppFonts.titleFont(29))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Frontispiece

    /// The chosen mysteries' painting in a lancet arch, unframed — the
    /// shape is the frame — crossfading as the choice changes.
    private func frontispiece(width: CGFloat) -> some View {
        let arch = GothicArchShape(riseRatio: 0.34)

        return arch
            .fill(AppColors.cardBackground)
            .frame(width: width, height: width * 1.22)
            .overlay(
                CachedAssetImage(category.cardImageName, focal: category.cardFocalPoint)
                    .id(category)
                    .transition(.opacity)
            )
            .clipShape(arch)
            .accessibilityHidden(true)
    }

    // MARK: - The Ledger

    private var sections: some View {
        VStack(spacing: 0) {
            SetSection(label: "About") {
                ReadingText(
                    text: "One verse of Scripture for every Hail Mary, so a decade walks through its own scene bead by bead. The Our Father bead announces the mystery and the fruit to ask for; the Glory Be closes it.",
                    size: 16
                )
            }

            SetSection(label: "The\nmysteries") {
                mysteryPicker
            }

            SetSection(label: "The first\ndecade") {
                firstDecade
            }

            SetSection(label: "From") {
                attribution
            }

            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)
        }
        .padding(.horizontal, 24)
    }

    /// The five sets of mysteries and the chaplet, each a bead on the
    /// rule: the chosen one lit, the rest waiting. Today's carries its
    /// mark whether or not it is the one chosen.
    private var mysteryPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(MysteryCategory.allCases, id: \.self) { candidate in
                let chosen = candidate == category

                Button {
                    withAnimation(.easeOut(duration: 0.25)) { category = candidate }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        RosaryBead(state: chosen ? .prayed : .ahead, size: 8)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }

                        Text(candidate.devotionTitle)
                            .font(AppFonts.readingFont(16))
                            .foregroundColor(chosen ? AppColors.goldLight : AppColors.cream.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        if candidate == today {
                            Text("TODAY")
                                .font(AppFonts.labelFont(8))
                                .tracking(2)
                                .foregroundColor(AppColors.gold.opacity(0.7))
                        }
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(candidate.devotionTitle + (candidate == today ? ", today's" : ""))
                .accessibilityAddTraits(chosen ? [.isSelected] : [])
            }
        }
        .padding(.vertical, -10)
    }

    /// How the prayer will open: the first mystery by name, and the
    /// first verse said on its beads.
    @ViewBuilder
    private var firstDecade: some View {
        let mystery = MysteryData.mysteries(for: category).first
        let verse = mystery.flatMap {
            ScripturalRosaryData.verses(category: $0.category.lowercased(), order: $0.order)?.first
        }

        VStack(alignment: .leading, spacing: 10) {
            Text(mystery?.name ?? category.devotionTitle)
                .font(AppFonts.readingFont(16))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            if let verse {
                Text(verse.reference.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Text(verse.text)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .id(category)
        .transition(.opacity)
    }

    /// Where the words come from — the one translation the beads carry.
    private var attribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("The Holy Bible")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.92))

            Text("Douay-Rheims translation · ten verses to a mystery, seven to a sorrow")
                .font(AppFonts.readingFont(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Pray

    /// The act, alone. Nothing is set beneath it.
    private var prayFoot: some View {
        GoldCTAButton(title: "Pray", showsCross: false) {
            router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(category: category)))
        }
        .padding(.horizontal, 32)
        .padding(.top, 96)
        .padding(.bottom, 22)
        .background(PrayFootScrim())
    }
}

// MARK: - Preview

#Preview {
    ScripturalRosaryView()
        .environment(AppRouter())
}
