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
//  it — no count, and never a duration. Above it, the one quiet line
//  that says how the Rosary will be prayed (`RosarySetupCard`), so the
//  voice and whether it is heard are chosen before PRAY, not found in
//  the player's foot once the first decade is moving.
//
//  The Rosary Aloud stands on the same page (`SpokenForm.plain`): its
//  own name and plain words for what it is, the same picker, and no
//  first decade — there is no verse to show, and the Our Father needs
//  no preview.
//

import SwiftUI

struct ScripturalRosaryView: View {
    @Environment(AppRouter.self) private var router

    /// The day's mysteries, marked in the ledger and chosen to begin with
    private let today = ScheduleService.categoryForToday()

    /// The mysteries the prayer will open on
    @State private var category: MysteryCategory

    /// A verse to a bead, or the Rosary Aloud
    private let form: SpokenForm

    init(form: SpokenForm = .scriptural) {
        self.form = form
        _category = State(initialValue: ScheduleService.categoryForToday())
    }

    private var isPlain: Bool { form == .plain }

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
                    // The set's page's measure: its foot is the same
                    // line over the same act
                    .padding(.bottom, 260)
                }
                .animation(Motion.crossfade, value: category)
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
            Text(isPlain ? "EVERY PRAYER SAID ALOUD" : "A VERSE FOR EVERY BEAD")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            OrnamentDivider()
                .frame(width: 150)

            Text(isPlain ? "The Rosary Aloud" : "The Scriptural Rosary")
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
                ReadingText(text: about, size: 16)
            }

            SetSection(label: "The\nmysteries") {
                mysteryPicker
            }

            if !isPlain {
                SetSection(label: "The first\ndecade") {
                    firstDecade
                }
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

    private var about: String {
        isPlain
            ? "Every prayer said aloud, the beads moving with the voice — for praying with the phone put away, or for learning the prayers by ear. Each mystery is announced, and each prayer is set on the screen as it is said."
            : "One verse of Scripture for every Hail Mary, so a decade walks through its own scene bead by bead. The Our Father bead announces the mystery and the fruit to ask for; the Glory Be closes it."
    }

    /// The five sets of mysteries and the chaplet, each a bead on the
    /// rule: the chosen one lit, the rest waiting. Today's carries its
    /// mark whether or not it is the one chosen.
    private var mysteryPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(MysteryCategory.allCases, id: \.self) { candidate in
                let chosen = candidate == category

                Button {
                    withAnimation(Motion.crossfade) { category = candidate }
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

    /// Where the words come from — the one translation the beads carry,
    /// or, for the Rosary Aloud, the Church's own prayers.
    private var attribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(isPlain ? "The prayers of the Church" : "The Holy Bible")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.92))

            Text(isPlain
                 ? "Said in the voice you choose · ten Hail Marys to a mystery, seven to a sorrow"
                 : "Douay-Rheims translation · ten verses to a mystery, seven to a sorrow")
                .font(AppFonts.readingFont(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Pray

    /// How the Rosary will be prayed, then the act. Nothing is set
    /// beneath it.
    private var prayFoot: some View {
        VStack(spacing: 16) {
            RosarySetupCard(category: category, kind: isPlain ? .plain : .scriptural)
                .padding(.horizontal, 32)

            GoldCTAButton(title: "Pray") {
                router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(category: category, form: form)))
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 72)
        .padding(.bottom, 22)
        .background(PrayFootGround())
    }
}

// MARK: - Preview

#Preview {
    ScripturalRosaryView()
        .environment(AppRouter())
        .environment(UserSettings.shared)
}

#Preview("The Rosary Aloud") {
    ScripturalRosaryView(form: .plain)
        .environment(AppRouter())
        .environment(UserSettings.shared)
}
