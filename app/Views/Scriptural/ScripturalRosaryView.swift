//
//  ScripturalRosaryView.swift
//  Lumen Viae
//
//  The page of the Rosary's two forms that are not a meditation set:
//  the Scriptural Rosary — a verse of Scripture for every Hail Mary —
//  and the Rosary Said Aloud, every prayer said aloud with no readings
//  between (`SpokenForm.plain`; it was the Holy Rosary, and before that
//  the Rosary Aloud).
//
//  Both are reached from a mysteries' page, WAYS TO PRAY, with
//  those mysteries already chosen, and both are set on the Rosary's own
//  page (`RosaryConfirmPage`), as a meditation set is: the mysteries'
//  painting dissolving into the page, the name, one line saying what the
//  form is, then YOUR ROSARY TODAY and PRAY.
//
//  Neither offers a choice of how to pray: both are said aloud, the
//  beads moving with the voice, and to pray quietly one mutes or pauses
//  the voice in the player. The page has the mysteries and the voice as
//  rows, and the Audio Rosary its audio as a plain row.
//
//  The Mysteries row is the picker: choosing another set changes the
//  painting, and nothing is remembered — tomorrow's page opens on
//  tomorrow's mysteries. Past the choices, a short ledger for whoever
//  scrolls: what the devotion is, how the first decade opens, and where
//  the words come from.
//

import SwiftUI

struct ScripturalRosaryView: View {
    @Environment(AppRouter.self) private var router

    /// The mysteries the prayer will open on — those of the page it was
    /// opened from, until the Mysteries row changes them
    @State private var category: MysteryCategory

    /// A verse to a bead, or the Holy Rosary
    private let form: SpokenForm

    /// Set once PRAY has pushed the prayer, and cleared when the page
    /// shows again, so a double tap before the push covers the page
    /// cannot open the Rosary twice — as the mysteries' page guards its sets
    @State private var isOpening = false

    init(category: MysteryCategory = ScheduleService.categoryForToday(), form: SpokenForm = .scriptural) {
        self.form = form
        _category = State(initialValue: category)
    }

    private var isPlain: Bool { form == .plain }

    var body: some View {
        RosaryConfirmPage(
            kicker: isPlain ? String(
                localized: "Listen and pray along",
                comment: "The Audio Rosary's own page: small capitals over its name, saying what it is"
            ) : String(
                localized: "A verse for every bead",
                comment: "The Scriptural Rosary's own page: small capitals over its name, saying what it is"
            ),
            title: ScripturalRosaryViewModel.displayName(for: form),
            subtitle: isPlain
                ? String(
                    localized: "A voice leads every prayer, with no readings between.",
                    comment: "The Audio Rosary's own page: the italic line under its name"
                )
                : String(
                    localized: "One verse of Scripture for every Hail Mary.",
                    comment: "The Scriptural Rosary's own page: the italic line under its name"
                ),
            onBack: { router.pop() },
            onPray: {
                guard !isOpening else { return }
                isOpening = true
                router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(category: category, form: form)))
            }
        ) {
            // The chosen mysteries' painting, crossfading as the choice
            // changes
            ZStack {
                CachedAssetImage(category.cardImageName, focal: category.cardFocalPoint)
                    .id(category)
                    .transition(.opacity)
            }
            .animation(Motion.crossfade, value: category)
        } choices: {
            RosaryChoicesSection(form: RosaryForm(form), mysteries: $category)
        } ledger: {
            sections
                .animation(Motion.crossfade, value: category)
        }
        .onAppear { isOpening = false }
    }

    // MARK: - The Ledger

    private var sections: some View {
        VStack(spacing: 0) {
            SetSection(label: String(
                localized: "About",
                comment: "A Rosary's own page, the ledger below the choices: label of the row describing the form"
            )) {
                ReadingText(text: about, size: 16)
            }

            if !isPlain {
                // The chaplet's are sorrows, and its ledger says so
                SetSection(
                    label: category == .sevenSorrows
                        ? String(
                            localized: "The first\nsorrow",
                            comment: "A Rosary's own page, ledger label in two short lines (a line break between) over the chaplet's first sorrow and its first verse"
                        )
                        : String(
                            localized: "The first\nmystery",
                            comment: "A Rosary's own page, ledger label in two short lines (a line break between) over the first mystery and its first verse"
                        )
                ) {
                    firstDecade
                }
            }

            SetSection(label: String(
                localized: "From",
                comment: "A Rosary's own page, ledger label of the row naming where the words come from"
            )) {
                attribution
            }
        }
    }

    /// What the form is, past the line under its name — which the ledger
    /// does not say twice
    private var about: String {
        isPlain
            ? String(
                localized: "The beads move with the voice — for praying with the phone put away, or for learning the prayers by ear. Each mystery, a scene from the lives of Jesus and Mary, is announced, and each prayer is shown on the screen as it is said. Pause the voice to pray quietly for a while.",
                comment: "The Audio Rosary's own page, ledger: what the form is"
            )
            : String(
                localized: "Each mystery, a scene from the lives of Jesus and Mary, is told verse by verse. The Our Father bead names the mystery and a grace to ask for, each of the Hail Marys has its own verse, and the Glory Be closes it.",
                comment: "The Scriptural Rosary's own page, ledger: what the form is"
            )
    }

    /// How the prayer will open: the first mystery by name, and the
    /// first verse said on its beads.
    @ViewBuilder
    private var firstDecade: some View {
        let mystery = MysteryData.mysteries(for: category).first
        let verse = mystery.flatMap {
            ScripturalRosaryData.verses(category: $0.category.lowercased(), order: $0.order)?.first
        }

        ZStack(alignment: .topLeading) {
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
    }

    /// Where the words come from — the one translation the beads carry,
    /// or, for the Holy Rosary, the Church's own prayers.
    private var attribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(isPlain ? "The prayers of the Church" : "The Holy Bible")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.92))

            Text(isPlain
                 ? "Said in the voice you choose · ten Hail Marys to a mystery, seven to a sorrow"
                 : "Douay-Rheims, the classic Catholic English Bible · ten verses to a mystery, seven to a sorrow")
                .font(AppFonts.readingFont(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    ScripturalRosaryView()
        .environment(AppRouter())
        .environment(UserSettings.shared)
}

#Preview("The Holy Rosary") {
    ScripturalRosaryView(form: .plain)
        .environment(AppRouter())
        .environment(UserSettings.shared)
}
