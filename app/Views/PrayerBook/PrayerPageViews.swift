//
//  PrayerPageViews.swift
//  Lumen Viae
//
//  What the pray-along page draws for each part of a prayer (PrayerPage):
//  ℣ and ℟ in a red column with the answer bold, the three red dots between
//  parts, a part's heading, the prayers said as small marks, the gold pause
//  where the reader names a request, the collect as one block, and a
//  litany's group with its answer once beside it. The frames are design's
//  option 1 (reports/design/prayer-format/frames/w-1-*.png).
//

import SwiftUI

// MARK: - A section

/// One section of the page: a stanza, or the collect's stanzas in one
/// block. Each stanza keeps its scroll id and its own strength under the
/// voice.
struct PrayerPageSectionView: View {
    let section: PrayerPage.Section
    let size: CGFloat
    let opacity: (Int) -> Double
    let open: (PrayerPage.SaidPrayer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.opensPart {
                PrayerPartMark()
                    .padding(.bottom, ReadingTypography.stanzaSpacing(for: size))
            }

            switch section {
            case .stanza(let stanza, _):
                stanzaView(stanza)

            case .collect(let stanzas, _):
                VStack(alignment: .leading, spacing: (size * 0.6).rounded()) {
                    ForEach(stanzas, id: \.index) { stanza in
                        stanzaView(stanza)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColors.textSecondary.opacity(0.18), lineWidth: AppLine.hairline)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stanzaView(_ stanza: PrayerPage.Stanza) -> some View {
        VStack(alignment: .leading, spacing: (size * 0.5).rounded()) {
            ForEach(Array(stanza.parts.enumerated()), id: \.offset) { _, part in
                PrayerPagePartView(part: part, size: size, showsDropCap: stanza.index == 0, open: open)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(opacity(stanza.index))
        .id(stanza.index)
    }
}

// MARK: - A part

struct PrayerPagePartView: View {
    let part: PrayerPage.Part
    let size: CGFloat
    let showsDropCap: Bool
    let open: (PrayerPage.SaidPrayer) -> Void

    var body: some View {
        switch part {
        case .classic(let content):
            PrayAlongStanza(content: content, size: size, showsDropCap: showsDropCap, opacity: 1)

        case .lines(let lines):
            VStack(alignment: .leading, spacing: ReadingTypography.quoteLineSpacing(for: size)) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    PrayerPageLineView(line: line, size: size)
                        // An answer stands a little apart from the
                        // prayer after it
                        .padding(.top, i > 0 && isVerse(line) && !isVerse(lines[i - 1]) ? size * 0.3 : 0)
                }
            }

        case .intro(let words):
            Text(words)
                .font(AppFonts.readingItalicFont(max(14, size - 2)))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

        case .heading(let title, let reference):
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.titleFont(max(16, size - 1)))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let reference {
                    Text(reference)
                        .font(AppFonts.readingItalicFont(max(13, size - 4)))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, 4)

        case .said(let prayers):
            PrayerSaidMarks(prayers: prayers, open: open)

        case .intention:
            PrayerIntentionPause(size: size)

        case .litanyGroup(let invocations, let response):
            PrayerLitanyGroup(invocations: invocations, response: response, size: size)

        case .mark:
            PrayerPartMark()

        case .letUsPray(let words):
            Text(words.uppercased())
                .font(AppFonts.labelFont(11))
                .tracking(2.6)
                .foregroundColor(Rubric.text)
                .accessibilityLabel(words)

        case .paragraph(let text):
            Text(Rubric.rubricated(text))
                .font(AppFonts.readingFont(size))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .lineSpacing(ReadingTypography.lineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func isVerse(_ line: PrayerPage.Line) -> Bool {
        if case .verse = line { return true }
        return false
    }
}

// MARK: - Lines

/// A line on the page: ℣ or ℟ hung in a red column, the answer bold; a
/// direction red and italic; a verse in the prayer's face
struct PrayerPageLineView: View {
    let line: PrayerPage.Line
    let size: CGFloat

    private var column: CGFloat { (size * 0.95).rounded() }

    var body: some View {
        switch line {
        case .versicle(let text):
            marked("℣", text, bold: false)
        case .response(let text):
            marked("℟", text, bold: true)
        case .verse(let text):
            Text(Rubric.rubricated(text))
                .font(AppFonts.bodyFont(size))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
        case .rubric(let text):
            Text(text)
                .font(AppFonts.readingItalicFont(max(12, size - 2)))
                .foregroundColor(Rubric.text)
                .fixedSize(horizontal: false, vertical: true)
        case .litany(let invocation, let response):
            (Text(invocation).font(AppFonts.bodyFont(size)).foregroundColor(AppColors.cream.opacity(0.92))
                + Text(" ℟ ").font(AppFonts.bodyFont(size)).foregroundColor(Rubric.red)
                + Text(response).font(AppFonts.readingItalicFont(size)).foregroundColor(Rubric.text))
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func marked(_ mark: String, _ text: String, bold: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(mark)
                .font(AppFonts.bodyFont(size))
                .foregroundColor(Rubric.red)
                .frame(width: column, alignment: .leading)
                .accessibilityHidden(true)
            Text(Rubric.rubricated(text))
                .font(bold ? AppFonts.semiboldBodyFont(size) : AppFonts.bodyFont(size))
                .foregroundColor(AppColors.cream.opacity(bold ? 1 : 0.92))
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: size))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The mark between parts

/// Three red dots, centred, where one part of a prayer gives way to the next
struct PrayerPartMark: View {
    var body: some View {
        Text("·  ·  ·")
            .font(AppFonts.bodyFont(16))
            .foregroundColor(Rubric.red)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

// MARK: - Prayers said here

/// The prayers a direction names, as small outlined marks; each opens
/// its prayer on a sheet, so the page and its voice stay where they are
struct PrayerSaidMarks: View {
    let prayers: [PrayerPage.SaidPrayer]
    let open: (PrayerPage.SaidPrayer) -> Void

    var body: some View {
        WordFlow(spacing: 8, lineSpacing: 8) {
            ForEach(prayers) { prayer in
                Button {
                    open(prayer)
                } label: {
                    Text(prayer.name.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(1.8)
                        .foregroundColor(AppColors.cream)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 32)
                        .overlay(
                            Capsule().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                        )
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel(prayer.name)
                .accessibilityHint(
                    String(
                        localized: "Shows the prayer",
                        comment:
                            "Pray-along page: VoiceOver hint on a mark naming a prayer said here (Our Father, Hail Mary)"
                    ))
            }
        }
    }
}

/// The prayer a mark opens: its title and words, read, nothing played
struct PrayerSaidSheet: View {
    let said: PrayerPage.SaidPrayer
    let language: PrayerLanguage
    /// The page's reading size, so the prayer reads as the page does
    let size: CGFloat

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if let prayer = PrayerBook.prayer(said.prayerID) {
                    SheetHeader(title: prayer.title)
                    PrayerText(content: prayer.content(for: language), size: size)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                } else {
                    SheetHeader(title: said.name)
                }
            }
        }
        .sheetGround()
        .presentationDetents([.medium, .large])
        .dynamicTypeSize(...DynamicTypeSize.appMaximum)
    }
}

// MARK: - The intention

/// Where the reader names what they ask for: a quiet gold pause rather
/// than "(here name your request)" in the sentence
struct PrayerIntentionPause: View {
    let size: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                String(
                    localized: "… your intention",
                    comment: "Pray-along page: the pause in a prayer where the reader names what they ask for")
            )
            .font(AppFonts.readingItalicFont(max(15, size - 2)))
            .foregroundColor(AppColors.gold)
            .underline(pattern: .dot, color: AppColors.gold)
            Text(
                String(
                    localized: "Pause, and name it in your heart.",
                    comment: "Pray-along page: the line under the intention pause")
            )
            .font(AppFonts.readingItalicFont(max(13, size - 5)))
            .foregroundColor(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - A litany's group

/// A group of calls marked by a red line, its answer once beside the
/// first call; where they cannot share the line, the answer stands above
struct PrayerLitanyGroup: View {
    let invocations: [String]
    let response: String
    let size: CGFloat

    private var answer: some View {
        (Text("℟ ").foregroundColor(Rubric.red) + Text(response).foregroundColor(Rubric.text))
            .font(AppFonts.readingItalicFont(max(15, size - 1)))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var calls: some View {
        VStack(alignment: .leading, spacing: ReadingTypography.quoteLineSpacing(for: size)) {
            ForEach(Array(invocations.enumerated()), id: \.offset) { _, call in
                Text(Rubric.rubricated(call))
                    .font(AppFonts.bodyFont(size))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var body: some View {
        // Beside the calls when every call and the answer fit on their
        // lines at this size, measured; otherwise above them, the same
        // rule at every size
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                calls.fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 0)
                answer.fixedSize()
            }
            VStack(alignment: .leading, spacing: 6) {
                answer
                calls
            }
        }
        .padding(.leading, 12)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Rubric.red.opacity(0.55))
                .frame(width: 2)
        }
        .accessibilityElement(children: .combine)
    }
}
