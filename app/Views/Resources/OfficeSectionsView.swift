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
//  A section is laid out one at a time, the way the missal's reader
//  lays out the Mass: `OfficeReaderSection` gives each one a stable id
//  and the names the rail and the index call it by, so the hour can be
//  jumped through and its place kept.
//

import SwiftUI

// MARK: - OfficeReaderSection

/// One section of an hour as the reader shows it. The engine names
/// nearly every section on both sides ("Psalmi" · "Psalms"); one that
/// arrives unnamed is a continuation, and is drawn but never listed.
struct OfficeReaderSection: Identifiable {

    let id: String
    let index: Int
    let latinName: String
    let englishName: String
    let section: OfficeSection

    /// Only a named section stands in the rail and the index
    var hasName: Bool { !latinName.isEmpty || !englishName.isEmpty }

    /// The name the rail and the ledger call it by — the vernacular
    /// where the engine gives one, since the rail has room for one word.
    var railName: String { englishName.isEmpty ? latinName : englishName }

    /// The section name in the language being read — "PSALMI" when
    /// praying in Latin, "PSALMS" in English, both when bilingual, in
    /// the user's own order.
    func displayName(_ language: PrayerLanguage) -> String? {
        let latin = latinName.isEmpty ? nil : latinName
        let english = englishName.isEmpty ? nil : englishName
        let distinct = latin != nil && english != nil
            && latin!.caseInsensitiveCompare(english!) != .orderedSame

        switch language {
        case .english:
            return english ?? latin
        case .latin:
            return latin ?? english
        case .both:
            return distinct ? "\(latin!) · \(english!)" : (latin ?? english)
        case .latinUnderEnglish:
            return distinct ? "\(english!) · \(latin!)" : (english ?? latin)
        }
    }

    /// The hour cut into addressable sections. The index rides in the
    /// id, so two sections the engine names alike still address
    /// separately — a hour with three lessons has three "Lectio"s.
    static func build(from sections: [OfficeSection]) -> [OfficeReaderSection] {
        sections.enumerated().map { index, section in
            let latin = trimmed(section.latin?.title)
            let english = trimmed(section.vernacular?.title)
            return OfficeReaderSection(
                id: "office-\(index)-\(slug(latin.isEmpty ? english : latin))",
                index: index,
                latinName: latin,
                englishName: english,
                section: section
            )
        }
    }

    private static func trimmed(_ string: String?) -> String {
        string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func slug(_ name: String) -> String {
        let lowered = name.lowercased()
        let cleaned = lowered.map { $0.isLetter || $0.isNumber ? $0 : "-" }
        return String(cleaned)
    }
}

// MARK: - Where the reader stands

extension Array where Element == OfficeReaderSection {

    /// Only a named section stands in the rail and the index; an
    /// unnamed one is a continuation of the section above it.
    var named: [OfficeReaderSection] { filter(\.hasName) }

    /// The named section a given section is being read under: the last
    /// one at or above it, so a continuation never leaves the rail dark
    /// or the ledger with nothing lit.
    ///
    /// One rule, in one place. The rail and the ☰ ledger must agree
    /// about where the reader is, and they agreed only by both being
    /// written to — two expressions that happened to match, and would
    /// have parted the first time either was touched.
    func namedSection(containing index: Int) -> OfficeReaderSection? {
        named.last(where: { $0.index <= index }) ?? named.first
    }
}

// MARK: - OfficeSectionView

/// One section of the hour: its red title, the rubric note beneath it,
/// and the text itself.
struct OfficeSectionView: View {

    let section: OfficeReaderSection
    let size: CGFloat
    let language: PrayerLanguage
    var layout: MissalLayout = .interlinear

    /// The illuminated versal belongs to the hour's opening words alone
    var showsDropCap: Bool = false

    private var latin: OfficeCell? { section.section.latin }
    private var vernacular: OfficeCell? { section.section.vernacular }

    var body: some View {
        VStack(alignment: .leading, spacing: (size * 0.65).rounded()) {
            if let heading = section.displayName(language) {
                Text(heading.uppercased())
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

    // MARK: - Note

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
                MissalPassageText(text: single, size: size, showsDropCap: versal(single))
            }
        case .latin:
            if let single = latinText ?? vernacularText {
                MissalPassageText(text: single, size: size, showsDropCap: versal(single))
            }
        case .both:
            if let latinText, let vernacularText {
                bilingual(primary: latinText, secondary: vernacularText,
                          paired: canPair(latin, vernacular))
            } else if let single = latinText ?? vernacularText {
                MissalPassageText(text: single, size: size, showsDropCap: versal(single))
            }
        case .latinUnderEnglish:
            if let latinText, let vernacularText {
                bilingual(primary: vernacularText, secondary: latinText,
                          paired: canPair(latin, vernacular))
            } else if let single = vernacularText ?? latinText {
                MissalPassageText(text: single, size: size, showsDropCap: versal(single))
            }
        }
    }

    /// Interlinear line pairs or facing columns when the two sides align
    /// line for line — they nearly always do, both keeping the engine's
    /// line structure — and stacked passages when one doesn't.
    @ViewBuilder
    private func bilingual(primary: String, secondary: String, paired: Bool) -> some View {
        let cap = versal(primary)

        switch layout {
        case .interlinear where paired:
            MissalPairedPassageText(
                primary: primary,
                secondary: secondary,
                size: size,
                showsDropCap: cap
            )
        case .sideBySide where paired:
            MissalColumnPassageText(
                primary: primary,
                secondary: secondary,
                size: size,
                showsDropCap: cap
            )
        case .sideBySide:
            HStack(alignment: .top, spacing: 18) {
                MissalPassageText(text: primary, size: max(13, size - 2), showsDropCap: cap)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MissalPassageText(text: secondary, size: max(13, size - 2), role: .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .interlinear:
            VStack(alignment: .leading, spacing: (size * 0.55).rounded()) {
                MissalPassageText(text: primary, size: size, showsDropCap: cap)
                MissalPassageText(text: secondary, size: size, role: .secondary)
            }
        }
    }

    /// The versal is only ever asked for on the hour's opening section,
    /// and only lands where the text opens on a word. An hour beginning
    /// "℣. Deus in adiutórium" would otherwise gild the versicle mark —
    /// a rubric blown up to twice the body size, which is a misprint,
    /// not an illumination. Nor is it drawn in columns: half a page is
    /// too narrow a measure for a floated initial.
    private func versal(_ text: String) -> Bool {
        guard showsDropCap else { return false }
        guard !(language.isBilingual && layout == .sideBySide) else { return false }
        guard let first = text.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return false
        }
        return first.isLetter
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
    let sections = OfficeReaderSection.build(from: [
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
                    "℣. O God, ✠ come to my assistance.",
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
    ])

    return ScrollView {
        VStack(alignment: .leading, spacing: 29) {
            ForEach(sections) { section in
                OfficeSectionView(section: section, size: 17, language: .both)
            }
        }
        .padding(24)
    }
    .background(AppColors.background)
}
