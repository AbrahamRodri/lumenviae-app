//
//  MissalSectionsView.swift
//  Lumen Viae
//
//  Renders missal sections — daily propers or the Ordo — under the
//  prayer language preference. Each passage arrives as an
//  [english, latin] pair; the bilingual modes set the second language
//  beneath the first as quiet italic, the same visual grammar
//  PrayerText uses for line pairs, but at passage level: scripture
//  never lines up one-to-one across languages.
//

import SwiftUI

// MARK: - MissalVestment

/// The vestment colors of the 1962 rite, from the API's single letters.
/// Swatches are muted to sit on the dark ground — a mark, not a flag.
enum MissalVestment: String {
    case white = "w"
    case red = "r"
    case green = "g"
    case violet = "v"
    case black = "b"
    case rose = "p"

    var name: String {
        switch self {
        case .white: return "White"
        case .red: return "Red"
        case .green: return "Green"
        case .violet: return "Violet"
        case .black: return "Black"
        case .rose: return "Rose"
        }
    }

    /// Muted so they never compete with the gold — only ever a small
    /// dot, never a field of colour.
    var swatch: Color {
        switch self {
        case .white: return Color(hex: "#EDE7D6")
        case .red: return Color(hex: "#A0473F")
        case .green: return Color(hex: "#4E6B4A")
        case .violet: return Color(hex: "#6B5480")
        case .black: return Color(hex: "#54545f")
        case .rose: return Color(hex: "#c98a97")
        }
    }
}

// MARK: - MissalRubric

/// Rubric red — the mark color of a printed missal. One red for the
/// vestment dot, the citations, and the ℣ ℟ ☩ marks, so the page reads
/// as one palette.
enum MissalRubric {
    static let red = MissalVestment.red.swatch
}

// MARK: - MissalSectionsView

struct MissalSectionsView: View {

    let sections: [MissalSection]
    let size: CGFloat
    let language: PrayerLanguage
    var layout: MissalLayout = .interlinear

    /// Sections that open with an illuminated initial in a printed
    /// missal: the Introit, the readings, and the Canon.
    private static let dropCapSections: Set<String> = [
        "introitus", "introit",
        "lectio", "epistola", "epistle", "lesson",
        "evangelium", "gospel",
        "canon"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: (size * 1.7).rounded()) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                sectionView(section)
            }
        }
    }

    // MARK: - Section

    private func sectionView(_ section: MissalSection) -> some View {
        VStack(alignment: .leading, spacing: (size * 0.65).rounded()) {
            if let heading = heading(for: section) {
                Text(heading)
                    .font(AppFonts.labelFont(11))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(section.body.enumerated()), id: \.offset) { index, pair in
                passage(pair, showsDropCap: index == 0 && showsDropCap(section))
            }
        }
    }

    private func showsDropCap(_ section: MissalSection) -> Bool {
        [section.id, section.label]
            .compactMap { $0?.lowercased() }
            .contains { Self.dropCapSections.contains($0) }
    }

    /// The section name in the language being read — "INTROITUS" when
    /// praying in Latin, "INTROIT" in English, both when bilingual, in
    /// the user's own order.
    private func heading(for section: MissalSection) -> String? {
        let latin = nonEmpty(section.id)
        let english = nonEmpty(section.label)
        let distinct = latin != nil && english != nil
            && latin!.caseInsensitiveCompare(english!) != .orderedSame

        let text: String?
        switch language {
        case .english:
            text = english ?? latin
        case .latin:
            text = latin ?? english
        case .both:
            text = distinct ? "\(latin!) · \(english!)" : (latin ?? english)
        case .latinUnderEnglish:
            text = distinct ? "\(english!) · \(latin!)" : (english ?? latin)
        }
        return text?.uppercased()
    }

    private func nonEmpty(_ string: String?) -> String? {
        guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    // MARK: - Passage

    private func passage(_ pair: [String], showsDropCap: Bool) -> some View {
        MissalPassage(
            pair: pair,
            size: size,
            language: language,
            layout: layout,
            showsDropCap: showsDropCap
        )
    }
}

// MARK: - MissalPassage

/// One passage — an [english, latin] pair — set under the reader's
/// language and layout. Interlinear: line by line when the two
/// languages align, each line with its translation beneath it, the way
/// the app's prayers read, and stacked passages when they don't. Side
/// by side: facing columns, corresponding lines on the same row, like
/// the page of a printed hand missal. Standing alone so the Daily
/// Missal's reader sets its sections through the same pairing rules.
struct MissalPassage: View {

    let pair: [String]
    let size: CGFloat
    let language: PrayerLanguage
    var layout: MissalLayout = .interlinear
    var showsDropCap: Bool = false

    var body: some View {
        let english = pair.first ?? ""
        let latin = pair.count > 1 ? pair[1] : english

        switch language {
        case .english:
            MissalPassageText(text: english, size: size, role: .primary, showsDropCap: showsDropCap)
        case .latin:
            MissalPassageText(text: latin, size: size, role: .primary, showsDropCap: showsDropCap)
        case .both:
            bilingual(primary: latin, secondary: english)
        case .latinUnderEnglish:
            bilingual(primary: english, secondary: latin)
        }
    }

    @ViewBuilder
    private func bilingual(primary: String, secondary: String) -> some View {
        let paired = missalCanPair(primary, secondary)

        switch layout {
        case .interlinear where paired:
            MissalPairedPassageText(
                primary: primary,
                secondary: secondary,
                size: size,
                showsDropCap: showsDropCap
            )
        case .sideBySide where paired:
            MissalColumnPassageText(
                primary: primary,
                secondary: secondary,
                size: size,
                showsDropCap: showsDropCap
            )
        case .sideBySide:
            HStack(alignment: .top, spacing: 18) {
                MissalPassageText(text: primary, size: max(13, size - 2), role: .primary, showsDropCap: showsDropCap)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MissalPassageText(text: secondary, size: max(13, size - 2), role: .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .interlinear:
            VStack(alignment: .leading, spacing: (size * 0.55).rounded()) {
                MissalPassageText(text: primary, size: size, role: .primary, showsDropCap: showsDropCap)
                MissalPassageText(text: secondary, size: size, role: .secondary)
                    .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Rubrication

/// ℣, ℟, and the cross — the marks a missal prints in red. One red for
/// these marks and the vestment dots; everything else stays gold.
private let missalRubricGlyphs: Set<Character> = ["℣", "℟", "✠"]

private func missalRubricated(_ string: String) -> AttributedString {
    var attributed = AttributedString(string)
    var index = attributed.startIndex
    while index < attributed.endIndex {
        let next = attributed.characters.index(after: index)
        if missalRubricGlyphs.contains(attributed.characters[index]) {
            attributed[index..<next].foregroundColor = MissalRubric.red
        }
        index = next
    }
    return attributed
}

/// The source texts mark the sign of the cross unevenly — ☩ in the
/// propers, a bare "+" in the Ordo. Both become the traditional ✠, the
/// cross a printed missal sets, before anything is drawn or paired.
private let missalCrossPattern = try? NSRegularExpression(pattern: #"(^|\s)\+\s*"#)

private func missalNormalized(_ line: String) -> String {
    var normalized = line
    if normalized.contains("☩") {
        normalized = normalized.replacingOccurrences(of: "☩", with: "✠")
    }
    guard normalized.contains("+"), let pattern = missalCrossPattern else { return normalized }

    // Compiled once, not once per line: `replacingOccurrences(options:
    // .regularExpression)` builds a fresh regex on every call, and every
    // visible passage runs this over every one of its lines several
    // times a pass of the reader's body.
    return pattern.stringByReplacingMatches(
        in: normalized,
        range: NSRange(normalized.startIndex..., in: normalized),
        withTemplate: "$1✠ "
    )
}

/// A line wholly wrapped in asterisks — "*Ps 138:17*" — is a citation
private func missalReference(in line: String) -> String? {
    guard line.count > 2, line.hasPrefix("*"), line.hasSuffix("*") else { return nil }
    return String(line.dropFirst().dropLast())
}

/// A citation, unwrapped — set as a small engraved caption in dim gold.
/// The old red was outside the palette; the vestment reds stay for the
/// vestment dots alone.
struct MissalReferenceText: View {

    let reference: String

    /// The measure the passage around it is set at. A citation is
    /// caption-sized, but it is still part of the reading: pinned to a
    /// constant it became the one thing on the page that ignored the
    /// missal's own text-size slider.
    var size: CGFloat = 16

    private var captionSize: CGFloat { max(10, (size - 4).rounded()) }

    var body: some View {
        Text(reference.uppercased())
            .font(AppFonts.labelFont(captionSize))
            .tracking(1.5)
            .foregroundColor(AppColors.gold.opacity(0.72))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private func missalLines(of text: String) -> [String] {
    text.components(separatedBy: "\n")
        .map { missalNormalized($0.trimmingCharacters(in: .whitespaces)) }
        .filter { !$0.isEmpty }
}

// MARK: - Line Pairing

/// One line and its translation, shared by the interlinear and the
/// side-by-side bilingual layouts.
private struct MissalLinePair {
    let primary: String
    let secondary: String

    /// Both sides carry the citation — set it once, in red. A citation
    /// on one side only falls through as an ordinary pair rather than
    /// silently dropping the other side's text.
    var reference: String? {
        guard let primaryReference = missalReference(in: primary),
              missalReference(in: secondary) != nil else { return nil }
        return primaryReference
    }
}

private func missalCanPair(_ primary: String, _ secondary: String) -> Bool {
    let primaryLines = missalLines(of: primary)
    return !primaryLines.isEmpty && primaryLines.count == missalLines(of: secondary).count
}

private func missalLinePairs(_ primary: String, _ secondary: String) -> [MissalLinePair] {
    zip(missalLines(of: primary), missalLines(of: secondary))
        .map { MissalLinePair(primary: $0, secondary: $1) }
}

/// The line carrying the illuminated initial: the first text line
/// after a citation when there is one, the first text line otherwise.
private func missalDropCapIndex(in pairs: [MissalLinePair]) -> Int? {
    var firstLine: Int?
    var seenReference = false
    for (index, pair) in pairs.enumerated() {
        if pair.reference != nil {
            seenReference = true
        } else {
            if firstLine == nil { firstLine = index }
            if seenReference { return index }
        }
    }
    return firstLine
}

// MARK: - MissalPassageText

/// One passage of missal text. A line wholly wrapped in asterisks is a
/// scripture reference ("*Ps 138:17*") and is set as small engraved
/// caps in dim gold, the way a hand missal prints its citations; runs
/// of ordinary lines share one Text so wrapped verses keep the reading
/// rhythm, with the ℣ ℟ ✠ marks picked out in rubric red. (The sources'
/// ☩ is normalized to ✠ by `missalLines` before anything is drawn.)
struct MissalPassageText: View {

    enum Role {
        case primary
        case secondary
    }

    let text: String
    let size: CGFloat
    var role: Role = .primary

    /// Sets an illuminated initial on the passage's opening — the run
    /// after the citation, where a printed missal puts it, so the
    /// Epistle's initial lands on "Brethren", not on the announcement.
    var showsDropCap: Bool = false

    private enum Fragment: Hashable {
        case reference(String)
        case lines(String)
    }

    private func makeFragments() -> [Fragment] {
        var result: [Fragment] = []
        var run: [String] = []

        func closeRun() {
            if !run.isEmpty {
                result.append(.lines(run.joined(separator: "\n")))
                run = []
            }
        }

        for line in missalLines(of: text) {
            if let reference = missalReference(in: line) {
                closeRun()
                result.append(.reference(reference))
            } else {
                run.append(line)
            }
        }
        closeRun()
        return result
    }

    var body: some View {
        // Built once per pass: `fragments` was a computed property read
        // both here and by the drop-cap search, so every passage was cut
        // into lines and normalized twice over.
        let fragments = makeFragments()
        let capIndex = dropCapIndex(in: fragments)

        return VStack(alignment: .leading, spacing: (size * 0.4).rounded()) {
            ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                switch fragment {
                case .reference(let reference):
                    MissalReferenceText(reference: reference, size: bodySize)

                case .lines(let lines):
                    if index == capIndex {
                        DropCapText(text: lines, bodySize: bodySize, textColor: color)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(missalRubricated(lines))
                            .font(font)
                            .foregroundColor(color)
                            .lineSpacing(ReadingTypography.lineSpacing(for: bodySize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// The fragment carrying the illuminated initial: the first run
    /// after a citation when there is one, the first run otherwise.
    /// Translations never carry one — the initial belongs to the text
    /// being prayed.
    private func dropCapIndex(in fragments: [Fragment]) -> Int? {
        guard showsDropCap, role == .primary else { return nil }

        var firstRun: Int?
        var seenReference = false
        for (index, fragment) in fragments.enumerated() {
            switch fragment {
            case .reference:
                seenReference = true
            case .lines:
                if firstRun == nil { firstRun = index }
                if seenReference { return index }
            }
        }
        return firstRun
    }

    private var bodySize: CGFloat {
        role == .primary ? size : max(12, size - 2)
    }

    private var font: Font {
        role == .primary
            ? AppFonts.readingFont(bodySize)
            : AppFonts.readingItalicFont(bodySize)
    }

    private var color: Color {
        role == .primary ? AppColors.cream.opacity(0.92) : AppColors.accentSoft
    }
}

// MARK: - MissalPairedPassageText

/// A bilingual passage whose languages align line for line — each line
/// set with its translation directly beneath it, the way PrayerText
/// renders the app's prayers. Missale Meum keeps both languages in
/// Divinum Officium's line structure, so nearly every passage pairs;
/// the caller falls back to stacked passages when one doesn't.
struct MissalPairedPassageText: View {

    let primary: String
    let secondary: String
    let size: CGFloat
    var showsDropCap: Bool = false

    var body: some View {
        // Cut once per pass: `pairs` was a computed property read both
        // here and by the drop-cap search, so every passage was split
        // and normalized twice over.
        let pairs = missalLinePairs(primary, secondary)
        let dropCapIndex = showsDropCap ? missalDropCapIndex(in: pairs) : nil

        return VStack(
            alignment: .leading,
            spacing: ReadingTypography.verseSpacing(for: size)
        ) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                if let reference = pair.reference {
                    MissalReferenceText(reference: reference, size: size)
                } else {
                    linePair(pair, showsDropCap: index == dropCapIndex)
                }
            }
        }
    }

    private func linePair(_ pair: MissalLinePair, showsDropCap: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if showsDropCap {
                DropCapText(
                    text: pair.primary,
                    bodySize: size,
                    textColor: AppColors.cream.opacity(0.92)
                )
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(missalRubricated(pair.primary))
                    .font(AppFonts.readingFont(size))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .lineSpacing((size * 0.3).rounded())
                    .fixedSize(horizontal: false, vertical: true)
            }

            // The translation steps in from the margin — set under its
            // line the way the handoff recommends, so the eye keeps the
            // Latin as the text and the English as its shadow.
            Text(missalRubricated(pair.secondary))
                .font(AppFonts.readingItalicFont(max(12, size - 2)))
                .foregroundColor(AppColors.accentSoft)
                .lineSpacing((size * 0.25).rounded())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 20)
        }
    }
}

// MARK: - MissalColumnPassageText

/// A bilingual passage in facing columns, corresponding lines on the
/// same row — the page of a printed hand missal. Set one step smaller
/// than the single-column measure: half a page is a narrow line.
struct MissalColumnPassageText: View {

    let primary: String
    let secondary: String
    let size: CGFloat
    var showsDropCap: Bool = false

    private var columnSize: CGFloat { max(13, size - 2) }

    var body: some View {
        let pairs = missalLinePairs(primary, secondary)
        let dropCapIndex = showsDropCap ? missalDropCapIndex(in: pairs) : nil

        return Grid(
            alignment: .topLeading,
            horizontalSpacing: 18,
            verticalSpacing: ReadingTypography.verseSpacing(for: columnSize)
        ) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                if let reference = pair.reference {
                    // A lone view in a Grid spans both columns
                    MissalReferenceText(reference: reference, size: columnSize)
                } else {
                    GridRow {
                        primaryCell(pair.primary, showsDropCap: index == dropCapIndex)
                        secondaryCell(pair.secondary)
                    }
                }
            }
        }
    }

    private func primaryCell(_ text: String, showsDropCap: Bool) -> some View {
        Group {
            if showsDropCap {
                DropCapText(
                    text: text,
                    bodySize: columnSize,
                    textColor: AppColors.cream.opacity(0.92)
                )
            } else {
                Text(missalRubricated(text))
                    .font(AppFonts.readingFont(columnSize))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .lineSpacing((columnSize * 0.35).rounded())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func secondaryCell(_ text: String) -> some View {
        Text(missalRubricated(text))
            .font(AppFonts.readingItalicFont(columnSize))
            .foregroundColor(AppColors.accentSoft)
            .lineSpacing((columnSize * 0.3).rounded())
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - MissalLayoutChoiceSheet

/// The missal's first-open question: how should the translation read?
/// Undismissable until answered — choosing is the only way through —
/// and the Aa sheet owns the setting afterward.
///
/// Two words cannot answer it. "The translation beneath each line" and
/// "facing columns" both ask the reader to picture a page they have
/// never seen, so the sheet shows the page instead: two plain toggles,
/// and one Introit set beneath them that re-sets itself as they move
/// between the two. The specimen is drawn by `MissalSectionsView` — the
/// reader's own renderer — so what is compared here cannot drift from
/// what the missal will actually do, and it is set in the reader's own
/// language order.
///
/// One specimen rather than two side by side: the question is which of
/// these you would rather read, and that is answered by watching the
/// same words change, not by looking back and forth between two
/// samples that are each half the width they will really have.
struct MissalLayoutChoiceSheet: View {

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    /// Seeded from the setting when there is one, so re-opening this
    /// shows the layout in force rather than a fresh question.
    @State private var selection: MissalLayout?

    /// Carries the lit capsule between the two toggles instead of
    /// blinking it out of one and into the other.
    @Namespace private var toggle

    /// The Introit of the First Sunday of Advent — where the missal's
    /// own year begins, one line in each tongue so both layouts have
    /// something to pair.
    private static let sample = MissalSection(
        id: "Introitus",
        label: "Introit",
        body: [[
            "To thee have I lifted up my soul: O my God, I trust in thee.",
            "Ad te levávi ánimam meam: Deus meus, in te confído."
        ]]
    )

    /// The layout only shows itself in two languages. A reader set to
    /// English or Latin alone still gets the question — the setting
    /// outlives the language — so the specimen is bilingual in their own
    /// order, defaulting to Latin leading.
    private var previewLanguage: PrayerLanguage {
        settings.prayerLanguage.isBilingual ? settings.prayerLanguage : .both
    }

    private var chosen: MissalLayout { selection ?? .interlinear }

    var body: some View {
        VStack(spacing: 0) {
            Text("THE DAILY MISSAL")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.7))
                .padding(.top, 30)

            Text("How should the translation read?")
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 32)

            HStack(spacing: 10) {
                capsule(.interlinear, "Line by line")
                capsule(.sideBySide, "Side by side")
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            specimen
                .padding(.horizontal, 24)
                .padding(.top, 20)

            Spacer(minLength: 12)

            Text("You can change this any time from the Aa button.")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            GoldCTAButton(title: "Read the Mass", showsCross: false) {
                settings.missalLayoutPreference = chosen.rawValue
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            if settings.hasChosenMissalLayout { selection = settings.missalLayout }
        }
    }

    // MARK: - The Toggles

    /// The same struck capsule the Aa sheet uses for this setting, so
    /// the choice looks the same wherever it is made.
    private func capsule(_ layout: MissalLayout, _ title: String) -> some View {
        let isSelected = chosen == layout

        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                selection = layout
            }
        } label: {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(capsuleGround(isSelected))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The lit ground is a single view handed between the two capsules,
    /// so it slides across rather than appearing where it is wanted.
    @ViewBuilder
    private func capsuleGround(_ isSelected: Bool) -> some View {
        if isSelected {
            Capsule()
                .fill(AppColors.cardElevated)
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.7), lineWidth: 1))
                .matchedGeometryEffect(id: "missalLayoutLit", in: toggle)
        } else {
            Capsule()
                .fill(AppColors.background.opacity(0.5))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 1))
        }
    }

    // MARK: - The Specimen

    /// One passage, re-set as the toggles move.
    ///
    /// The old setting leaves before the new one arrives rather than
    /// crossfading through it — two settings of the same words dissolved
    /// over each other are unreadable for the moment they overlap, which
    /// is exactly the moment being watched. The block's height eases so
    /// the sheet never jumps between the two.
    private var specimen: some View {
        MissalSectionsView(
            sections: [Self.sample],
            size: 16,
            language: previewLanguage,
            layout: chosen
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(chosen)
        .transition(
            .asymmetric(
                insertion: .opacity.animation(.easeOut(duration: 0.24).delay(0.13)),
                removal: .opacity.animation(.easeIn(duration: 0.13))
            )
        )
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.3), value: chosen)
        .accessibilityLabel("Preview of the \(chosen == .interlinear ? "line by line" : "side by side") setting")
    }
}

// MARK: - MissalTextSizeSheet

/// The reader's size slider, alone — the missal has no narration to
/// follow. Writes the same app-wide scale every reading surface uses,
/// so the page behind the sheet resizes as the thumb moves.
struct MissalTextSizeSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = userSettings

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Text")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    AppIcon("ph-x", size: 15)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close")
            }

            Text("SIZE")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            HStack(spacing: 14) {
                Text("A")
                    .font(AppFonts.readingFont(13))
                    .foregroundColor(AppColors.textSecondary)

                Slider(value: $settings.textSizeScale, in: 0...1)
                    .tint(AppColors.gold)
                    .accessibilityLabel("Text size")

                Text("A")
                    .font(AppFonts.readingFont(24))
                    .foregroundColor(AppColors.cream)
            }

            Text("TRANSLATION")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)
                .padding(.top, 20)

            HStack(spacing: 6) {
                layoutCapsule("Line by line", layout: .interlinear)
                layoutCapsule("Side by side", layout: .sideBySide)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background.ignoresSafeArea())
    }

    private func layoutCapsule(_ title: String, layout: MissalLayout) -> some View {
        let isSelected = userSettings.missalLayout == layout

        return Button {
            userSettings.missalLayoutPreference = layout.rawValue
        } label: {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(
                        isSelected ? AppColors.cardElevated : AppColors.background.opacity(0.5)
                    )
                )
                .overlay(
                    Capsule().strokeBorder(
                        AppColors.gold.opacity(isSelected ? 0.7 : 0.15),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MissalSectionsView(
            sections: [
                MissalSection(
                    id: "Introitus",
                    label: "Introit",
                    body: [[
                        "*Ps 138:17*\nTo me, Your friends, O God, are made exceedingly honorable; their principality is exceedingly strengthened.",
                        "*Ps 138:17*\nMihi autem nimis honoráti sunt amíci tui, Deus: nimis confortátus est principátus eórum."
                    ]]
                ),
                MissalSection(
                    id: "Oratio",
                    label: "Collect",
                    body: [[
                        "Almighty, eternal God, Who bestowed on us the devout and holy joy of this day. Through our Lord…",
                        "Omnípotens sempitérne Deus, qui hujus diei venerándam sanctámque lætítiam tribuísti. Per Dominum…"
                    ]]
                )
            ],
            size: 17,
            language: .both
        )
        .padding(24)
    }
    .background(AppColors.background)
}
