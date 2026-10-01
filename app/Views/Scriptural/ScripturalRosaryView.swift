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
//  The Scriptural Rosary offers the same two choices a set does — Read
//  in Silence or Whole Rosary, and while in silence, On My Rosary or On
//  the Screen — then the mysteries and the voice as rows. The Holy
//  Rosary offers no choice at all: it is always said aloud, the beads
//  moving with the voice, so its audio is a plain row, and to pray
//  quietly for a while one pauses the voice.
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
            kicker: isPlain ? "Every prayer, no readings" : "A verse for every bead",
            title: ScripturalRosaryViewModel.displayName(for: form),
            subtitle: isPlain
                ? "A voice leads every prayer, with no readings between."
                : "One verse of Scripture for every Hail Mary.",
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
            SetSection(label: "About") {
                ReadingText(text: about, size: 16)
            }

            if !isPlain {
                // The chaplet's are sorrows, and its ledger says so
                SetSection(label: category == .sevenSorrows ? "The first\nsorrow" : "The first\nmystery") {
                    firstDecade
                }
            }

            SetSection(label: "From") {
                attribution
            }
        }
    }

    /// What the form is, past the line under its name — which the ledger
    /// does not say twice
    private var about: String {
        isPlain
            ? "The beads move with the voice — for praying with the phone put away, or for learning the prayers by ear. Each mystery, a scene from the lives of Jesus and Mary, is announced, and each prayer is shown on the screen as it is said. Pause the voice to pray quietly for a while."
            : "Each mystery, a scene from the lives of Jesus and Mary, is told verse by verse. The Our Father bead names the mystery and a grace to ask for, each of the Hail Marys has its own verse, and the Glory Be closes it."
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
