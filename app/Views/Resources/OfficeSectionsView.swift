//
//  OfficeSectionsView.swift
//  Lumen Viae
//
//  Renders one canonical hour's sections under the prayer language
//  preference. The Latin and vernacular cells keep Divinum Officium's
//  line structure, so bilingual reading pairs line for line through the
//  same passage views the missal reads with — interlinear or facing
//  columns — and the ℣ ℟ ✠ marks take the same rubric red.
//

import SwiftUI

struct OfficeSectionsView: View {

    let sections: [OfficeSection]
    let size: CGFloat
    let language: PrayerLanguage
    var layout: MissalLayout = .interlinear

    var body: some View {
        VStack(alignment: .leading, spacing: (size * 1.7).rounded()) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                sectionView(section)
            }
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func sectionView(_ section: OfficeSection) -> some View {
        // The engine drops the vernacular column when Latin itself is
        // the requested translation; whichever side exists is read.
        let latin = section.latin
        let vernacular = section.vernacular

        VStack(alignment: .leading, spacing: (size * 0.65).rounded()) {
            if let heading = heading(latin: latin?.title, vernacular: vernacular?.title) {
                Text(heading)
                    .font(AppFonts.labelFont(11))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note = note(latin: latin?.note, vernacular: vernacular?.note) {
                Text(note)
                    .font(AppFonts.italicFont(max(11, size - 4)))
                    .foregroundColor(MissalRubric.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            body(latin: latin, vernacular: vernacular)
        }
    }

    // MARK: - Heading

    /// The section's red title in the language being read — "PSALMI"
    /// when praying in Latin, "PSALMS" in English, both when bilingual,
    /// in the user's own order.
    private func heading(latin: String?, vernacular: String?) -> String? {
        let latin = nonEmpty(latin)
        let vernacular = nonEmpty(vernacular)
        let distinct = latin != nil && vernacular != nil
            && latin!.caseInsensitiveCompare(vernacular!) != .orderedSame

        let text: String?
        switch language {
        case .english:
            text = vernacular ?? latin
        case .latin:
            text = latin ?? vernacular
        case .both:
            text = distinct ? "\(latin!) · \(vernacular!)" : (latin ?? vernacular)
        case .latinUnderEnglish:
            text = distinct ? "\(vernacular!) · \(latin!)" : (vernacular ?? latin)
        }
        return text?.uppercased()
    }

    /// The rubric note beneath the title, read from the side being
    /// prayed. The engine wraps it in braces; a printed breviary just
    /// sets it in red.
    private func note(latin: String?, vernacular: String?) -> String? {
        let chosen: String?
        switch language {
        case .english, .latinUnderEnglish:
            chosen = nonEmpty(vernacular) ?? nonEmpty(latin)
        case .latin, .both:
            chosen = nonEmpty(latin) ?? nonEmpty(vernacular)
        }
        guard var note = chosen else { return nil }
        if note.hasPrefix("{") { note.removeFirst() }
        if note.hasSuffix("}") { note.removeLast() }
        return note.trimmingCharacters(in: .whitespaces)
    }

    private func nonEmpty(_ string: String?) -> String? {
        guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    // MARK: - Body

    @ViewBuilder
    private func body(latin: OfficeCell?, vernacular: OfficeCell?) -> some View {
        let latinText = text(of: latin)
        let vernacularText = text(of: vernacular)

        switch language {
        case .english:
            if let single = vernacularText ?? latinText {
                MissalPassageText(text: single, size: size)
            }
        case .latin:
            if let single = latinText ?? vernacularText {
                MissalPassageText(text: single, size: size)
            }
        case .both:
            if let latinText, let vernacularText {
                bilingual(primary: latinText, secondary: vernacularText,
                          paired: canPair(latin, vernacular))
            } else if let single = latinText ?? vernacularText {
                MissalPassageText(text: single, size: size)
            }
        case .latinUnderEnglish:
            if let latinText, let vernacularText {
                bilingual(primary: vernacularText, secondary: latinText,
                          paired: canPair(latin, vernacular))
            } else if let single = vernacularText ?? latinText {
                MissalPassageText(text: single, size: size)
            }
        }
    }

    /// Interlinear line pairs or facing columns when the two sides align
    /// line for line — they nearly always do, both keeping the engine's
    /// line structure — and stacked passages when one doesn't.
    @ViewBuilder
    private func bilingual(primary: String, secondary: String, paired: Bool) -> some View {
        switch layout {
        case .interlinear where paired:
            MissalPairedPassageText(primary: primary, secondary: secondary, size: size)
        case .sideBySide where paired:
            MissalColumnPassageText(primary: primary, secondary: secondary, size: size)
        case .sideBySide:
            HStack(alignment: .top, spacing: 18) {
                MissalPassageText(text: primary, size: max(13, size - 2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                MissalPassageText(text: secondary, size: max(13, size - 2), role: .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .interlinear:
            VStack(alignment: .leading, spacing: (size * 0.55).rounded()) {
                MissalPassageText(text: primary, size: size)
                MissalPassageText(text: secondary, size: size, role: .secondary)
            }
        }
    }

    private func text(of cell: OfficeCell?) -> String? {
        guard let cell, !cell.lines.isEmpty else { return nil }
        return cell.lines.joined(separator: "\n")
    }

    private func canPair(_ latin: OfficeCell?, _ vernacular: OfficeCell?) -> Bool {
        guard let latin, let vernacular else { return false }
        return !latin.lines.isEmpty && latin.lines.count == vernacular.lines.count
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        OfficeSectionsView(
            sections: [
                OfficeSection(
                    latin: OfficeCell(
                        title: "Incipit",
                        note: nil,
                        lines: [
                            "℣. Deus ✠ in adiutórium meum inténde.",
                            "℟. Dómine, ad adiuvándum me festína.",
                            "Glória Patri, et Fílio, * et Spirítui Sancto."
                        ]
                    ),
                    vernacular: OfficeCell(
                        title: "Start",
                        note: nil,
                        lines: [
                            "℣. O God, ✠ come to my assistance;",
                            "℟. O Lord, make haste to help me.",
                            "Glory be to the Father, and to the Son, * and to the Holy Ghost."
                        ]
                    )
                ),
                OfficeSection(
                    latin: OfficeCell(
                        title: "Psalmi",
                        note: "{Psalmi & antiphonæ ex Commune aut Festo}",
                        lines: [
                            "Ant. Hoc est præcéptum meum, * ut diligátis ínvicem.",
                            "Psalmus 92 [1]",
                            "92:1 Dóminus regnávit, decórem indútus est."
                        ]
                    ),
                    vernacular: OfficeCell(
                        title: "Psalms",
                        note: "{Psalms & antiphons from the Common or Feast}",
                        lines: [
                            "Ant. This is my commandment * that you love one another.",
                            "Psalm 92 [1]",
                            "92:1 The Lord hath reigned, he is clothed with beauty."
                        ]
                    )
                )
            ],
            size: 17,
            language: .both
        )
        .padding(24)
    }
    .background(AppColors.background)
}
