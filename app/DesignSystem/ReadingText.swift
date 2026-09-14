//
//  ReadingText.swift
//  Lumen Viae
//
//  The shared long-form reading typography. Every screen that sets a
//  page of devotional text — meditations, consecration readings, prayer
//  texts, the resource library — draws its rhythm from here, so the app
//  reads like one book instead of many hands.
//
//  Two shapes cover everything the app displays:
//  - ReadingText: running prose, split into real paragraphs
//  - PrayerText: verse lines and stanzas, with optional bilingual pairs
//

import SwiftUI

// MARK: - ReadingTypography

/// One place for the app's reading rhythm. Spacing scales with the font
/// size so text enlarged in Account → Text Size keeps the same openness
/// instead of tightening as it grows.
enum ReadingTypography {

    /// Space between wrapped lines of running prose. Generous — these
    /// are pages to be prayed slowly, not scanned.
    static func lineSpacing(for size: CGFloat) -> CGFloat {
        (size * 0.55).rounded()
    }

    /// Leading for a verse or pull-quote standing alone — about a 1.45
    /// line height, tighter than prose, because a few lines read as one
    /// breath and the prose leading pulls them apart into a list.
    static func quoteLineSpacing(for size: CGFloat) -> CGFloat {
        (size * 0.28).rounded()
    }

    /// Space between paragraphs, over and above the line height
    static func paragraphSpacing(for size: CGFloat) -> CGFloat {
        (size * 0.95).rounded()
    }

    /// Space between verse lines rendered as separate views
    /// (bilingual pairs), looser than wrapped prose so each line-pair
    /// reads as its own unit
    static func verseSpacing(for size: CGFloat) -> CGFloat {
        (size * 0.55).rounded()
    }

    /// Space between prayer stanzas — wide enough that the verse
    /// structure is visible at a glance
    static func stanzaSpacing(for size: CGFloat) -> CGFloat {
        (size * 1.2).rounded()
    }
}

// MARK: - ReadingText

/// Long-form devotional prose. Splits its text into real paragraphs on
/// blank lines and gives each one book-like line spacing that scales
/// with the font. Two marks in the text are drawn rather than printed:
/// a paragraph consisting only of rule characters (`─────`, as the
/// consecration readings use between sections) is an ornamental
/// divider, and a paragraph opening `# ` is the reading's own title —
/// "Of Resisting Temptations", the chapter's name as the book prints it
/// above the chapter — set as a title, not as a first sentence. The
/// first paragraph of prose can open with an illuminated drop cap; a
/// title never takes one, and the versal falls to the prose beneath it.
struct ReadingText: View {

    /// EB Garamond Regular reads best for sustained text at 15pt and up;
    /// Medium holds its weight better in small card copy.
    enum Style {
        case reading
        case body
    }

    let paragraphs: [String]
    var size: CGFloat = 16
    var style: Style = .reading
    var showsDropCap: Bool = false

    /// The drop cap's length floor, `DropCapText.minimumLength`. The
    /// journal passes 0: a reader's own short entry still opens on its
    /// letter.
    var dropCapMinimumLength: Int = 80
    var textColor: Color = AppColors.cream.opacity(0.92)
    var alignment: TextAlignment = .leading

    /// Whether to build the paragraphs lazily. Off by default, because
    /// most callers are cards that need the block's intrinsic height;
    /// on for book-length chapters inside a scroll view, where an eager
    /// stack would lay out every paragraph before the first can draw.
    var isLazy: Bool = false

    /// One block of prose, split into paragraphs on blank lines.
    init(
        text: String,
        size: CGFloat = 16,
        style: Style = .reading,
        showsDropCap: Bool = false,
        dropCapMinimumLength: Int = 80,
        textColor: Color = AppColors.cream.opacity(0.92),
        alignment: TextAlignment = .leading,
        isLazy: Bool = false
    ) {
        self.init(
            paragraphs: Self.paragraphs(of: text),
            size: size, style: style, showsDropCap: showsDropCap,
            dropCapMinimumLength: dropCapMinimumLength,
            textColor: textColor, alignment: alignment, isLazy: isLazy
        )
    }

    /// Prose already in paragraphs — a parsed book chapter, say, whose
    /// structure the parser established. Passing them through directly
    /// spares joining a whole chapter into one string only to split it
    /// apart again on every pass of the body.
    init(
        paragraphs: [String],
        size: CGFloat = 16,
        style: Style = .reading,
        showsDropCap: Bool = false,
        dropCapMinimumLength: Int = 80,
        textColor: Color = AppColors.cream.opacity(0.92),
        alignment: TextAlignment = .leading,
        isLazy: Bool = false
    ) {
        self.paragraphs = paragraphs
        self.size = size
        self.style = style
        self.showsDropCap = showsDropCap
        self.dropCapMinimumLength = dropCapMinimumLength
        self.textColor = textColor
        self.alignment = alignment
        self.isLazy = isLazy
    }

    /// The paragraph split every reading surface uses. Exposed so a
    /// caller that needs to address paragraphs individually — the prayer
    /// reader's narration follow-along — indexes exactly what is drawn
    /// here, instead of keeping a second copy of this rule in step.
    static func paragraphs(of text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// A hand-typed rule between sections of a reading
    private func isRule(_ paragraph: String) -> Bool {
        paragraph.count >= 3 && paragraph.allSatisfy { "─—–-—*_ ".contains($0) }
    }

    /// The reading's title, marked `# ` at the head of its paragraph
    private func isHeading(_ paragraph: String) -> Bool {
        paragraph.hasPrefix("# ")
    }

    private func heading(_ paragraph: String) -> String {
        paragraph.dropFirst(2).trimmingCharacters(in: .whitespaces)
    }

    /// The paragraph that takes the versal: the first that is prose —
    /// not a rule, not a title.
    private var dropCapIndex: Int? {
        guard showsDropCap else { return nil }
        return paragraphs.firstIndex { !isRule($0) && !isHeading($0) }
    }

    private var font: Font {
        style == .reading ? AppFonts.readingFont(size) : AppFonts.bodyFont(size)
    }

    var body: some View {
        Group {
            if isLazy {
                LazyVStack(
                    alignment: alignment == .center ? .center : .leading,
                    spacing: ReadingTypography.paragraphSpacing(for: size)
                ) { paragraphStack }
            } else {
                VStack(
                    alignment: alignment == .center ? .center : .leading,
                    spacing: ReadingTypography.paragraphSpacing(for: size)
                ) { paragraphStack }
            }
        }
        .multilineTextAlignment(alignment)
    }

    @ViewBuilder
    private var paragraphStack: some View {
        let capIndex = dropCapIndex
        ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
            if isRule(paragraph) {
                OrnamentDivider(showsCross: false)
                    .frame(width: 140)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, (size * 0.3).rounded())
            } else if isHeading(paragraph) {
                // The chapter's name in the display face, a step above
                // the text, with a little more air beneath it than one
                // paragraph leaves the next
                Text(heading(paragraph))
                    .font(AppFonts.titleFont((size + 2).rounded()))
                    .foregroundColor(AppColors.cream)
                    .lineSpacing((size * 0.3).rounded())
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, (size * 0.25).rounded())
            } else if index == capIndex {
                DropCapText(
                    text: paragraph,
                    bodySize: size,
                    textColor: textColor,
                    minimumLength: dropCapMinimumLength
                )
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(paragraph)
                    .font(font)
                    .foregroundColor(textColor)
                    .lineSpacing(ReadingTypography.lineSpacing(for: size))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


// MARK: - Rubric

/// The marks a printed book sets in red — ℣ and ℟, and the cross — and
/// the one red they are set in: the missal's vestment red, so the
/// consecration's litanies, the Rosary's prayers and the missal's own
/// propers read as one palette.
enum Rubric {

    /// The muted red of a red vestment — the mark colour of a printed
    /// missal, deliberately not a bright red, which would shout on the
    /// dark page. The missal's vestment dot is this same colour.
    static let red = Color(hex: "#A0473F")

    /// The glyphs set in red wherever they fall in a line
    static let glyphs: Set<Character> = ["℣", "℟", "✠"]

    /// `string` with every rubric glyph coloured and the text around
    /// them left to the Text's own colour.
    static func rubricated(_ string: String) -> AttributedString {
        var attributed = AttributedString(string)
        var index = attributed.startIndex
        while index < attributed.endIndex {
            let next = attributed.characters.index(after: index)
            if glyphs.contains(attributed.characters[index]) {
                attributed[index..<next].foregroundColor = red
            }
            index = next
        }
        return attributed
    }
}

// MARK: - PrayerMarkup

/// The small grammar a prayer's text carries, read here and nowhere
/// else. Every rule is a mark a printed prayer book already uses, so
/// the data reads as a prayer book page even as plain text.
nonisolated enum PrayerMarkup {

    /// One line's two languages — the text being prayed, and its
    /// translation after the `|||` when there is one.
    static func parts(_ line: String) -> (primary: String, secondary: String?) {
        let pieces = line.components(separatedBy: "|||")
        let primary = pieces[0].trimmingCharacters(in: .whitespaces)
        guard pieces.count > 1 else { return (primary, nil) }
        let secondary = pieces[1].trimmingCharacters(in: .whitespaces)
        return (primary, secondary.isEmpty ? nil : secondary)
    }

    /// A line wholly in square brackets is a rubric — "[Let us pray.]",
    /// a direction — and is set in red, never prayed aloud as text.
    static func isRubric(_ text: String) -> Bool {
        text.count > 2 && text.hasPrefix("[") && text.hasSuffix("]")
    }

    static func rubric(_ text: String) -> String {
        String(text.dropFirst().dropLast())
    }

    /// An invocation answered on its own line — "Holy Mary, ℟. pray for
    /// us." A line that *opens* on ℟ is a response standing alone
    /// ("℟. Amen.") and is ordinary verse.
    static func isLitany(_ text: String) -> Bool {
        guard let range = text.range(of: "℟.") else { return false }
        return range.lowerBound != text.startIndex
    }

    /// The invocation and the response either side of the ℟
    static func litanyParts(_ text: String) -> (invocation: String, response: String) {
        guard let range = text.range(of: "℟.") else { return (text, "") }
        return (
            String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces),
            String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        )
    }

    /// A verse pointed at its mediant — "Magníficat * ánima mea Dóminum."
    /// — the breviary's own mark for where a psalm verse breaks.
    static func isPointed(_ text: String) -> Bool {
        text.contains(" * ")
    }

    /// The two halves of a pointed verse
    static func pointedParts(_ text: String) -> (first: String, second: String) {
        let halves = text.components(separatedBy: " * ")
        return (halves[0], halves.dropFirst().joined(separator: " "))
    }

    /// A hand-typed rule between the parts of a prayer
    static func isRule(_ text: String) -> Bool {
        text.count >= 3 && text.allSatisfy { "─—–-—*_ ".contains($0) }
    }
}

// MARK: - PrayerText

/// Prayer and hymn text, set the way a printed prayer book sets it.
///
/// The shape of every prayer is read from its text, so the consecration's
/// litanies, the Rosary's prayers and True Devotion's ejaculations all
/// come through one grammar:
///
/// - A blank line ends a stanza.
/// - `|||` divides a line into the language being prayed and its
///   translation, set beneath it in quiet italic.
/// - ℣ ℟ ✠ are rubric red wherever they fall.
/// - A response following its invocation on the line — "Holy Mary,
///   ℟. pray for us." — makes a litany: each invocation stands on its
///   own line, a little apart from the next, and the response steps
///   back into italic, so a page of fifty reads as the column of
///   titles it is. A litany's other stanzas keep that rhythm too.
/// - ` * ` inside a line is the mediant of a pointed verse: the verse
///   breaks there, the asterisk in red, the second half stepped in —
///   how a breviary sets a canticle.
/// - A line in [square brackets] is a rubric: red, italic, a size
///   smaller. "Let us pray."; a direction.
/// - A stanza of only rule characters (`─────`) is an ornament.
/// - A stanza that is one long line is prose — a paragraph of one of
///   Montfort's prayers — and takes the reading face and the prose
///   leading, and the first such paragraph can open on an illuminated
///   initial. A stanza of short lines is verse, and takes the tighter
///   leading of a single breath.
struct PrayerText: View {

    let content: String
    var size: CGFloat = 16
    var alignment: TextAlignment = .leading

    /// Opens the prayer on an illuminated initial — when the prayer
    /// opens in prose. A hymn, a canticle or a litany never takes one,
    /// whatever this says: the versal belongs to a page of prose.
    var showsDropCap: Bool = false

    // MARK: - Reading the text

    private enum Kind {
        case verse
        case prose
        case litany
        case pointed
        case rule
    }

    private enum Role {
        case primary
        case secondary
    }

    private struct Stanza: Identifiable {
        let id: Int
        let lines: [String]
        let kind: Kind

        var isBilingual: Bool { lines.contains { $0.contains("|||") } }
        var isRubricOnly: Bool {
            lines.allSatisfy { PrayerMarkup.isRubric(PrayerMarkup.parts($0).primary) }
        }
    }

    /// A paragraph is one line of at least this many characters. Under
    /// it a lone line is verse — an "Amen.", a versicle, a one-line
    /// ejaculation.
    private static let proseThreshold = 90

    private static func kind(of lines: [String]) -> Kind {
        if lines.count == 1, PrayerMarkup.isRule(lines[0]) { return .rule }
        let primaries = lines.map { PrayerMarkup.parts($0).primary }
        if primaries.contains(where: PrayerMarkup.isPointed) { return .pointed }
        if primaries.contains(where: PrayerMarkup.isLitany) { return .litany }
        if primaries.count == 1,
           !PrayerMarkup.isRubric(primaries[0]),
           primaries[0].count >= proseThreshold {
            return .prose
        }
        return .verse
    }

    private var stanzas: [Stanza] {
        var grouped: [[String]] = []
        var current: [String] = []
        for rawLine in content.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                if !current.isEmpty {
                    grouped.append(current)
                    current = []
                }
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty { grouped.append(current) }
        return grouped.enumerated().map {
            Stanza(id: $0.offset, lines: $0.element, kind: Self.kind(of: $0.element))
        }
    }

    // MARK: - Measures

    private var horizontalAlignment: HorizontalAlignment {
        alignment == .center ? .center : .leading
    }

    /// The translation steps in from the margin, so the eye keeps the
    /// text as the text and the translation as its shadow — unless the
    /// prayer is centred, where a step would only unbalance it.
    private var translationIndent: CGFloat {
        alignment == .leading ? 16 : 0
    }

    /// The second half of a pointed verse hangs in by about an em and
    /// a half, as a breviary sets it
    private var mediantIndent: CGFloat {
        alignment == .leading ? (size * 1.5).rounded() : 0
    }

    private var secondarySize: CGFloat { max(12, size - 2) }
    private var primaryColor: Color { AppColors.cream.opacity(0.92) }

    // MARK: - Body

    var body: some View {
        let stanzas = self.stanzas
        // A litany's Kyrie, and a group that answers with the response
        // stated above it, are stanzas of short lines too; in a litany
        // they keep the litany's rhythm rather than tightening into a
        // hymn stanza beside the others.
        let isLitany = stanzas.contains { $0.kind == .litany }
        let opening = stanzas.first { $0.kind != .rule && !$0.isRubricOnly }
        let capID = showsDropCap && opening?.kind == .prose ? opening?.id : nil

        VStack(
            alignment: horizontalAlignment,
            spacing: ReadingTypography.stanzaSpacing(for: size)
        ) {
            ForEach(stanzas) { stanza in
                stanzaView(stanza, asLitany: isLitany, showsDropCap: stanza.id == capID)
            }
        }
        .multilineTextAlignment(alignment)
    }

    // MARK: - Stanzas

    @ViewBuilder
    private func stanzaView(_ stanza: Stanza, asLitany: Bool, showsDropCap: Bool) -> some View {
        switch stanza.kind {
        case .rule:
            OrnamentDivider(showsCross: false)
                .frame(width: 140)
                .frame(maxWidth: .infinity)
                .padding(.vertical, (size * 0.3).rounded())

        case .verse where !asLitany && !stanza.isBilingual:
            verseStanza(stanza.lines)

        default:
            // Every other shape sets each line as its own view: a
            // litany's invocations a little apart, a canticle's verses,
            // a line and its translation beneath it.
            VStack(
                alignment: horizontalAlignment,
                spacing: ReadingTypography.verseSpacing(for: size)
            ) {
                ForEach(Array(stanza.lines.enumerated()), id: \.offset) { index, line in
                    pair(line, kind: stanza.kind, showsDropCap: showsDropCap && index == 0)
                }
            }
        }
    }

    /// A hymn stanza in one language: its verse lines share one Text,
    /// so a wrapped line keeps the stanza's rhythm, and any rubric
    /// among them stands on its own.
    private func verseStanza(_ lines: [String]) -> some View {
        var runs: [(isRubric: Bool, text: String)] = []
        var verse: [String] = []
        func closeVerse() {
            if !verse.isEmpty {
                runs.append((false, verse.joined(separator: "\n")))
                verse = []
            }
        }
        for line in lines {
            if PrayerMarkup.isRubric(line) {
                closeVerse()
                runs.append((true, line))
            } else {
                verse.append(line)
            }
        }
        closeVerse()

        return VStack(
            alignment: horizontalAlignment,
            spacing: ReadingTypography.verseSpacing(for: size)
        ) {
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                if run.isRubric {
                    rubricLine(run.text, role: .primary)
                } else {
                    styled(run.text, role: .primary)
                        .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Lines

    /// One line and, beneath it, its translation in quiet italic —
    /// close enough to belong to its line, distinct enough not to blur.
    @ViewBuilder
    private func pair(_ line: String, kind: Kind, showsDropCap: Bool) -> some View {
        let parts = PrayerMarkup.parts(line)
        if let secondary = parts.secondary {
            VStack(alignment: horizontalAlignment, spacing: 3) {
                lineView(parts.primary, kind: kind, role: .primary, showsDropCap: showsDropCap)
                lineView(secondary, kind: kind, role: .secondary, showsDropCap: false)
                    .padding(.leading, translationIndent)
            }
        } else {
            lineView(parts.primary, kind: kind, role: .primary, showsDropCap: showsDropCap)
        }
    }

    @ViewBuilder
    private func lineView(_ text: String, kind: Kind, role: Role, showsDropCap: Bool) -> some View {
        if PrayerMarkup.isRubric(text) {
            rubricLine(text, role: role)
        } else if kind == .litany, PrayerMarkup.isLitany(text) {
            litanyLine(text, role: role)
        } else if kind == .pointed, PrayerMarkup.isPointed(text) {
            pointedVerse(text, role: role)
        } else if kind == .prose {
            proseLine(text, role: role, showsDropCap: showsDropCap)
        } else {
            styled(text, role: role)
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func proseLine(_ text: String, role: Role, showsDropCap: Bool) -> some View {
        if showsDropCap, role == .primary {
            DropCapText(text: text, bodySize: size, textColor: primaryColor)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            styled(text, role: role, prose: true)
                .lineSpacing(
                    role == .primary
                        ? ReadingTypography.lineSpacing(for: size)
                        : (secondarySize * 0.4).rounded()
                )
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// "Holy Mary, ℟. pray for us." — the invocation full, the mark
    /// red, the response stepped back into italic.
    private func litanyLine(_ text: String, role: Role) -> some View {
        let parts = PrayerMarkup.litanyParts(text)
        let response = Text(parts.response)
            .font(AppFonts.readingItalicFont(role == .primary ? size : secondarySize))
            .foregroundColor(role == .primary ? AppColors.cream.opacity(0.74) : AppColors.accentSoft)

        return (styled(parts.invocation, role: role) + mark(" ℟. ", role: role) + response)
            .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// "Magníficat * ánima mea Dóminum." — broken at the mediant, the
    /// asterisk red, the second half hung in.
    private func pointedVerse(_ text: String, role: Role) -> some View {
        let parts = PrayerMarkup.pointedParts(text)
        return VStack(alignment: horizontalAlignment, spacing: (size * 0.12).rounded()) {
            (styled(parts.first, role: role) + mark(" *", role: role))
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)

            styled(parts.second, role: role)
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, mediantIndent)
        }
    }

    private func rubricLine(_ text: String, role: Role) -> some View {
        Text(PrayerMarkup.rubric(text))
            .font(AppFonts.readingItalicFont(role == .primary ? secondarySize : max(11, size - 4)))
            .foregroundColor(Rubric.red.opacity(role == .primary ? 1 : 0.8))
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Type

    /// Text in the face and colour of its role, its ℣ ℟ ✠ in red
    private func styled(_ text: String, role: Role, prose: Bool = false) -> Text {
        switch role {
        case .primary:
            return Text(Rubric.rubricated(text))
                .font(prose ? AppFonts.readingFont(size) : AppFonts.bodyFont(size))
                .foregroundColor(primaryColor)
        case .secondary:
            return Text(Rubric.rubricated(text))
                .font(AppFonts.readingItalicFont(secondarySize))
                .foregroundColor(AppColors.accentSoft)
        }
    }

    private func mark(_ glyph: String, role: Role) -> Text {
        Text(glyph)
            .font(role == .primary ? AppFonts.bodyFont(size) : AppFonts.readingItalicFont(secondarySize))
            .foregroundColor(Rubric.red)
    }
}

// MARK: - Previews

#Preview("ReadingText") {
    ScrollView {
        ReadingText(
            text: """
            Examine your conscience, pray, practice renouncement of your own will; mortification, purity of heart. This purity is the indispensable condition for contemplating God in heaven.

            ─────

            The spirit of the world consists essentially in the denial of the supreme dominion of God; a denial which is manifested in practice by sin and disobedience.
            """,
            size: 17,
            showsDropCap: true
        )
        .padding(24)
    }
    .background(AppColors.background)
}

#Preview("PrayerText — litany") {
    ScrollView {
        PrayerText(
            content: """
            Lord, have mercy on us.
            Christ, have mercy on us.
            Lord, have mercy on us.

            Holy Mary, ℟. pray for us.
            Holy Mother of God,
            Holy Virgin of virgins,

            ℣. Pray for us, O holy Mother of God,
            ℟. That we may be made worthy of the promises of Christ.

            [Let us pray.]

            Grant, we beseech Thee, O Lord God, unto us Thy servants, that we may rejoice in continual health of mind and body. Through Christ Our Lord.

            ℟. Amen.
            """,
            size: 17
        )
        .padding(24)
    }
    .background(AppColors.background)
}

#Preview("PrayerText — canticle, bilingual") {
    ScrollView {
        PrayerText(
            content: """
            Magníficat * ánima mea Dóminum.|||My soul * doth magnify the Lord.
            Et exsultávit spíritus meus * in Deo salutári meo.|||And my spirit hath rejoiced * in God my Saviour.

            Glória Patri, et Fílio, * et Spirítui Sancto.|||Glory be to the Father, and to the Son, * and to the Holy Ghost.
            """,
            size: 17
        )
        .padding(24)
    }
    .background(AppColors.background)
}
