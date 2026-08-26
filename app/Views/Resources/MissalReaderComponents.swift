//
//  MissalReaderComponents.swift
//  Lumen Viae
//
//  The Daily Missal reader's pieces: one section of the Mass — posture
//  cue, tiered heading, passages — and the two sheets the header's
//  buttons raise: Reading (the Aa settings) and Ordo Missæ (the
//  jump-to-section index). All of it draws through the shared missal
//  passage views, so the text itself is set the same way everywhere.
//

import SwiftUI

// MARK: - MissalReaderSectionView

/// One section of the day's Mass. The propers' gold diamond is the one
/// mark that sets them apart from the Ordinary — both read at full
/// strength.
struct MissalReaderSectionView: View {

    let section: MissalReaderSection
    let size: CGFloat
    let language: PrayerLanguage
    let layout: MissalLayout
    let showsPosture: Bool

    /// The illuminated versal belongs to the first section only
    let showsDropCap: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsPosture, let posture = section.posture {
                postureCue(posture)
                    .padding(.bottom, 18)
            }

            heading
                .padding(.bottom, 16)

            passages
        }
    }

    // MARK: - Posture Cue

    private func postureCue(_ posture: MissalPosture) -> some View {
        HStack(spacing: 10) {
            fadingRule(leading: true)

            Text(posture.rawValue.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(3)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize()

            fadingRule(leading: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(posture.rawValue)
    }

    private func fadingRule(leading: Bool) -> some View {
        LinearGradient(
            colors: leading
                ? [AppColors.gold.opacity(0), AppColors.gold.opacity(0.22)]
                : [AppColors.gold.opacity(0.22), AppColors.gold.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }

    // MARK: - Heading

    /// A diamond stud (propers only), the Latin name, and the English
    /// name a step smaller beside it — one wrapping line.
    private var heading: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            if section.isProper {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.85))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            headingText
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var showsBothNames: Bool {
        !section.englishName.isEmpty
            && section.latinName.caseInsensitiveCompare(section.englishName) != .orderedSame
    }

    private var headingText: Text {
        let latin = Text(section.latinName.uppercased())
            .font(AppFonts.headlineFont(12))
            .tracking(2.5)
            .foregroundColor(AppColors.gold)

        guard showsBothNames else { return latin }

        let english = Text(section.englishName.uppercased())
            .font(AppFonts.labelFont(10))
            .tracking(2)
            .foregroundColor(AppColors.gold.opacity(0.42))

        return latin + Text("  ") + english
    }

    // MARK: - Passages

    private var passages: some View {
        let body = section.section.body

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(body.enumerated()), id: \.offset) { index, pair in
                MissalPassage(
                    pair: pair,
                    size: size,
                    language: language,
                    layout: layout,
                    showsDropCap: showsDropCap && index == 0 && dropCapAllowed
                )
                .padding(.bottom, spacingBelow(pair, index: index, count: body.count))
            }
        }
    }

    /// The versal is suppressed in columns — half a page is too narrow
    /// a measure for a floated initial.
    private var dropCapAllowed: Bool {
        !(language.isBilingual && layout == .sideBySide)
    }

    /// A versicle-and-response pair reads as one exchange: a passage
    /// opening on a ℣/℟/✠ mark keeps its response close.
    private func spacingBelow(_ pair: [String], index: Int, count: Int) -> CGFloat {
        guard index < count - 1 else { return 0 }
        return hasLeadingMark(pair) ? 9 : 16
    }

    private func hasLeadingMark(_ pair: [String]) -> Bool {
        let text = pair.count > 1 ? pair[1] : (pair.first ?? "")
        guard let first = text.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return false
        }
        return first == "℣" || first == "℟" || first == "☩" || first == "✠"
    }
}

// MARK: - MissalSheetShell

/// The shared shell of the missal's bottom sheets: gold handle,
/// engraved title, ornament, then whatever the sheet holds. An empty
/// title leaves the head to the sheet itself — the calendar sets a
/// month stepper there instead.
struct MissalSheetShell<Content: View>: View {

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.gold.opacity(0.38))
                .frame(width: 30, height: 2)
                .padding(.top, 10)
                .padding(.bottom, 14)

            if !title.isEmpty {
                VStack(spacing: 10) {
                    Text(title.uppercased())
                        .font(AppFonts.headlineFont(11))
                        .tracking(3.5)
                        .foregroundColor(AppColors.gold)

                    OrnamentDivider()
                        .frame(width: 118)
                }
                .padding(.bottom, 18)
            }

            content()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.cardBackground.ignoresSafeArea())
    }
}

// MARK: - MissalSheetChip

/// One option in a sheet's chip row — equal-width pills, the selected
/// one lit in gold.
struct MissalSheetChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(isSelected ? AppColors.gold.opacity(0.1) : Color.clear))
                .overlay(Capsule().strokeBorder(
                    AppColors.gold.opacity(isSelected ? 0.5 : 0.16),
                    lineWidth: 0.5
                ))
                .contentShape(Capsule())
                .animation(.timingCurve(0, 0, 0.58, 1, duration: 0.18), value: isSelected)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - MissalReadingSheet

/// The Aa sheet: language, bilingual layout, contents, text size, and
/// the posture-cue toggle. Every choice writes straight to settings, so
/// the page behind resets as the chips are struck.
struct MissalReadingSheet: View {

    @Environment(UserSettings.self) private var settings

    /// The bilingual order restored when "Both" is re-chosen, owned by
    /// the missal screen so a Latin detour never loses it.
    @Binding var preferredBilingual: PrayerLanguage

    var body: some View {
        @Bindable var settings = settings

        return MissalSheetShell(title: "Reading") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    chipGroup("Language") {
                        MissalSheetChip(
                            title: "Latin",
                            isSelected: settings.prayerLanguage == .latin
                        ) { choose(.latin) }

                        MissalSheetChip(
                            title: "English",
                            isSelected: settings.prayerLanguage == .english
                        ) { choose(.english) }

                        MissalSheetChip(
                            title: "Both",
                            isSelected: settings.prayerLanguage.isBilingual
                        ) { chooseBoth() }
                    }

                    chipGroup("Latin and English") {
                        MissalSheetChip(
                            title: "Stacked",
                            isSelected: settings.missalLayout == .interlinear
                        ) {
                            settings.missalLayoutPreference = MissalLayout.interlinear.rawValue
                        }

                        MissalSheetChip(
                            title: "Side by side",
                            isSelected: settings.missalLayout == .sideBySide
                        ) { chooseSideBySide() }
                    }

                    chipGroup("Contents") {
                        MissalSheetChip(
                            title: "Propers only",
                            isSelected: settings.missalScope == .propersOnly
                        ) {
                            settings.missalScopeRaw = MissalScope.propersOnly.rawValue
                        }

                        MissalSheetChip(
                            title: "With the Ordinary",
                            isSelected: settings.missalScope == .full
                        ) {
                            settings.missalScopeRaw = MissalScope.full.rawValue
                        }
                    }

                    sizeSlider($settings.missalTextScale)

                    toggleRow(
                        title: "Posture cues",
                        detail: "Stand, kneel and sit, marked in the text",
                        isOn: $settings.missalPostureCues
                    )

                    toggleRow(
                        title: "High Mass",
                        detail: "The sung Mass — Asperges and incensing; the Leonine prayers follow Low Mass",
                        isOn: $settings.missalHighMass
                    )
                }
                .padding(.bottom, 36)
            }
        }
    }

    // MARK: - Choices

    private func choose(_ language: PrayerLanguage) {
        if settings.prayerLanguage.isBilingual {
            preferredBilingual = settings.prayerLanguage
        }
        settings.prayerLanguagePreference = language.rawValue
    }

    private func chooseBoth() {
        settings.prayerLanguagePreference = preferredBilingual.rawValue
    }

    /// Two columns need two languages: side by side forces Both.
    private func chooseSideBySide() {
        settings.missalLayoutPreference = MissalLayout.sideBySide.rawValue
        if !settings.prayerLanguage.isBilingual {
            settings.prayerLanguagePreference = preferredBilingual.rawValue
        }
    }

    // MARK: - Pieces

    private func chipGroup<Chips: View>(
        _ label: String,
        @ViewBuilder chips: () -> Chips
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(label.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 8) {
                chips()
            }
        }
        .padding(.bottom, 20)
    }

    /// The reader's size slider — the same control every other reading
    /// surface offers, bound to the missal's own scale.
    private func sizeSlider(_ scale: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("TEXT SIZE")
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 14) {
                Text("A")
                    .font(AppFonts.readingFont(13))
                    .foregroundColor(AppColors.textSecondary)

                Slider(value: scale, in: 0...1)
                    .tint(AppColors.gold)
                    .accessibilityLabel("Text size")

                Text("A")
                    .font(AppFonts.readingFont(24))
                    .foregroundColor(AppColors.cream)
            }
        }
        .padding(.bottom, 6)
    }

    private func toggleRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(12))
                    .tracking(1.5)
                    .foregroundColor(AppColors.cream)

                Text(detail)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(AppColors.gold.opacity(0.55))
        }
        .frame(minHeight: 44)
        .padding(.top, 16)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.1))
                .frame(height: 0.5)
        }
        .padding(.top, 4)
    }
}

// MARK: - MissalIndexSheet

/// The ☰ sheet: every visible section as a ruled ledger — the active
/// one marked with a lit dot, propers with their diamond — a tap jumps
/// the page there and puts the sheet away.
struct MissalIndexSheet: View {

    @Environment(\.dismiss) private var dismiss

    let sections: [MissalReaderSection]
    let activeIndex: Int
    let onJump: (String) -> Void

    var body: some View {
        MissalSheetShell(title: "Ordo Missæ") {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        row(section, index: index)
                    }

                    legend
                }
                .padding(.bottom, 36)
            }
        }
    }

    private func row(_ section: MissalReaderSection, index: Int) -> some View {
        let isActive = index == activeIndex

        return Button {
            onJump(section.id)
            dismiss()
        } label: {
            HStack(spacing: 11) {
                Circle()
                    .fill(isActive ? AppColors.gold : Color.clear)
                    .frame(width: 5, height: 5)
                    .shadow(color: isActive ? AppColors.gold.opacity(0.6) : .clear, radius: 4)

                Rectangle()
                    .fill(section.isProper ? AppColors.gold.opacity(0.85) : Color.clear)
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))

                VStack(alignment: .leading, spacing: 1) {
                    Text(section.latinName.uppercased())
                        .font(AppFonts.labelFont(13))
                        .tracking(1.5)
                        .foregroundColor(isActive ? AppColors.gold : AppColors.cream)

                    if section.latinName.caseInsensitiveCompare(section.englishName) != .orderedSame {
                        Text(section.englishName)
                            .font(AppFonts.bodyFont(13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                if let posture = section.posture {
                    Text(posture.rawValue.uppercased())
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.42))
                }
            }
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.1))
                .frame(height: 0.5)
        }
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var legend: some View {
        HStack(spacing: 9) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.85))
                .frame(width: 4, height: 4)
                .rotationEffect(.degrees(45))

            Text("Marked parts are proper to today; the rest is the Ordinary.")
                .font(AppFonts.bodyFont(12.5))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }
}
