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
/// with the font. A paragraph consisting only of rule characters
/// (`─────`, as the consecration readings use between sections) is
/// rendered as an ornamental divider instead of literal glyphs, and the
/// first paragraph can open with an illuminated drop cap.
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
        textColor: Color = AppColors.cream.opacity(0.92),
        alignment: TextAlignment = .leading,
        isLazy: Bool = false
    ) {
        self.init(
            paragraphs: Self.paragraphs(of: text),
            size: size, style: style, showsDropCap: showsDropCap,
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
        textColor: Color = AppColors.cream.opacity(0.92),
        alignment: TextAlignment = .leading,
        isLazy: Bool = false
    ) {
        self.paragraphs = paragraphs
        self.size = size
        self.style = style
        self.showsDropCap = showsDropCap
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
        ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
            if isRule(paragraph) {
                OrnamentDivider(showsCross: false)
                    .frame(width: 140)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, (size * 0.3).rounded())
            } else if showsDropCap && index == 0 {
                DropCapText(
                    text: paragraph,
                    bodySize: size,
                    textColor: textColor
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


// MARK: - PrayerText

/// Prayer and hymn text. Understands the app's two prayer shapes —
/// verse lines separated by newlines with blank lines between stanzas,
/// and bilingual lines carrying both languages around a `|||` marker —
/// and spaces them on three clear levels: a translation hugs its line,
/// verse lines sit apart, and stanzas breathe.
struct PrayerText: View {

    let content: String
    var size: CGFloat = 16
    var alignment: TextAlignment = .leading

    private struct Stanza: Identifiable {
        let id: Int
        let lines: [String]
        var isBilingual: Bool { lines.contains { $0.contains("|||") } }
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
        return grouped.enumerated().map { Stanza(id: $0.offset, lines: $0.element) }
    }

    private var horizontalAlignment: HorizontalAlignment {
        alignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(
            alignment: horizontalAlignment,
            spacing: ReadingTypography.stanzaSpacing(for: size)
        ) {
            ForEach(stanzas) { stanza in
                stanzaView(stanza)
            }
        }
        .multilineTextAlignment(alignment)
    }

    @ViewBuilder
    private func stanzaView(_ stanza: Stanza) -> some View {
        if stanza.isBilingual {
            VStack(
                alignment: horizontalAlignment,
                spacing: ReadingTypography.verseSpacing(for: size)
            ) {
                ForEach(Array(stanza.lines.enumerated()), id: \.offset) { _, line in
                    bilingualLine(line)
                }
            }
        } else {
            // One Text per stanza so wrapped verse lines share the rhythm
            Text(stanza.lines.joined(separator: "\n"))
                .font(AppFonts.bodyFont(size))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .lineSpacing(ReadingTypography.lineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// One verse line and, beneath it, its translation in quiet italic —
    /// close enough to belong to its line, distinct enough not to blur.
    @ViewBuilder
    private func bilingualLine(_ line: String) -> some View {
        let parts = line.components(separatedBy: "|||")

        VStack(alignment: horizontalAlignment, spacing: 3) {
            Text(parts[0].trimmingCharacters(in: .whitespaces))
                .font(AppFonts.bodyFont(size))
                .foregroundColor(AppColors.cream)
                .lineSpacing((size * 0.3).rounded())

            if parts.count >= 2 {
                Text(parts[1].trimmingCharacters(in: .whitespaces))
                    .font(AppFonts.italicFont(size - 3))
                    .foregroundColor(AppColors.accentSoft)
                    .lineSpacing((size * 0.25).rounded())
            }
        }
        .fixedSize(horizontal: false, vertical: true)
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

#Preview("PrayerText — bilingual") {
    ScrollView {
        PrayerText(
            content: """
            Hail Mary, full of grace, the Lord is with thee;|||Ave Maria, gratia plena, Dominus tecum;
            blessed art thou among women,|||benedicta tu in mulieribus,

            Holy Mary, Mother of God,|||Sancta Maria, Mater Dei,
            pray for us sinners. Amen.|||ora pro nobis peccatoribus. Amen.
            """,
            size: 16
        )
        .padding(24)
    }
    .background(AppColors.background)
}
