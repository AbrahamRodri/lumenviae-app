//
//  LibraryReaderComponents.swift
//  Lumen Viae
//
//  The reading shelf's shared vocabulary, from the Soul Book Reader
//  handoff: the halo that lights a cover, the one gold act that resumes
//  a book, the day's measure, the reader's own chrome, prose with
//  tappable footnotes and margin ribbons, and the pull-ups they raise.
//
//  Book-agnostic on purpose. The four Gutenberg books and the bundled
//  True Devotion are different plumbing but one design, so everything
//  here takes plain values — never a LibraryBook or a session.
//
//  Two words matter and are kept strictly apart: a MARK is a ribbon on
//  a page, nothing written; a NOTE is a passage plus the reader's own
//  words, kept in the journal. There is no second highlights library.
//

import SwiftUI
import SwiftData

// MARK: - Marker ribbon

/// The marker ribbon's silhouette — square head, notched tail.
struct MarkerRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.74))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Halo

/// The light behind a book's cover: the binding's own colour pooled
/// under a breath of gold. Replaces the old full-width cloth wash,
/// which sat every dark element on another dark element — this lights
/// the cover only.
struct BookHalo: View {

    let bindingColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: bindingColor.opacity(0.9), location: 0),
                            .init(color: bindingColor.opacity(0.35), location: 0.44),
                            .init(color: .clear, location: 0.74)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 270
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: AppColors.gold.opacity(0.09), location: 0),
                            .init(color: .clear, location: 0.58)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 270
                    )
                )
        }
        .frame(width: 540, height: 540)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - The one gold act

/// The book page's single filled gold shape: where the reading resumes.
/// Three lines — what this act is, where it goes, and how far along
/// that chapter already is.
struct ContinueReadingAct: View {

    /// "CONTINUE READING" on a book with a marker, "BEGIN READING" on
    /// one not yet opened
    let kicker: String

    /// Where the act leads — "Chapter I · Earliest Memories"
    let destination: String

    /// How far into that chapter the reader is, 0…1
    let fraction: Double

    /// "6 MIN IN · 18 MIN LEFT", or nil where no honest length exists
    let meta: String?

    let action: () -> Void

    private var ink: Color { AppColors.background }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    MarkerRibbonShape()
                        .fill(ink.opacity(0.5))
                        .frame(width: 7, height: 16)

                    Text(kicker)
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(ink.opacity(0.72))

                    Spacer(minLength: 8)

                    AppIcon("ph-caret-right", size: 13)
                        .foregroundColor(ink.opacity(0.55))
                }

                Text(destination)
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(ink.opacity(0.18))
                            Capsule()
                                .fill(ink.opacity(0.45))
                                .frame(width: max(geometry.size.width * fraction, 0))
                        }
                    }
                    .frame(height: 2)

                    if let meta {
                        Text(meta)
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.4)
                            .foregroundColor(ink.opacity(0.7))
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
            .padding(.top, 13)
            .padding(.horizontal, 17)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppColors.goldCTAGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(AppColors.goldLight.opacity(0.6), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18))
            .haloGlow(AppColors.gold, radius: 9, intensity: 0.3)
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kicker.capitalized): \(destination)")
    }
}

// MARK: - Today's goal

/// The day's measure, as a ruled band rather than a card: the dial that
/// is both the section's icon and its progress, the measure in words,
/// and the way to change it. Never a streak, never a debt.
struct TodaysGoalBand: View {

    /// The whole line: "A quarter-hour of reading · 6 of 15 minutes so far"
    let line: String

    /// How far today has come toward the measure, 0…1
    let fraction: Double

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                dial

                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S GOAL")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold)

                    Text(line)
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.cream.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Text("CHANGE")
                        .font(AppFonts.labelFont(8))
                        .tracking(1.4)
                    AppIcon("ph-caret-right", size: 10)
                }
                .foregroundColor(AppColors.gold.opacity(0.7))
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle().fill(AppColors.gold.opacity(0.18)).frame(height: 0.5)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppColors.gold.opacity(0.18)).frame(height: 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's goal. \(line). Opens the measures.")
    }

    /// A 38-point dial whose ring fills as the day's reading does —
    /// the section's icon and its progress at once.
    private var dial: some View {
        let f = min(max(fraction, 0), 1)

        return Circle()
            .fill(
                AngularGradient(
                    stops: [
                        .init(color: AppColors.goldLight, location: 0),
                        .init(color: AppColors.goldLight, location: f),
                        .init(color: AppColors.cream.opacity(0.1), location: f),
                        .init(color: AppColors.cream.opacity(0.1), location: 1)
                    ],
                    center: .center,
                    angle: .degrees(-90)
                )
            )
            .frame(width: 38, height: 38)
            .overlay(
                Circle()
                    .fill(AppColors.background)
                    .frame(width: 20, height: 20)
            )
            .overlay(
                Circle().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: AppColors.gold.opacity(0.12), radius: 6)
            .accessibilityHidden(true)
    }
}

// MARK: - Goal sheet

/// The measures themselves. The purpose line names what the sheet is
/// for, and the foot says the one thing that matters most: a missed
/// day is never counted against you.
struct ReadingGoalSheet: View {

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("HOW MUCH YOU MEAN TO READ EACH DAY")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                Text("Spiritual reading asks for a little every day rather than an evening every month.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.cream.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 14)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(height: 0.5)

                ForEach(ReadingGoal.allCases) { goal in
                    LibraryTrayRow(
                        title: goal.title,
                        isOn: settings.readingGoal == goal
                    ) {
                        settings.readingGoalRaw = goal.rawValue
                        dismiss()
                    }
                }

                Text("A missed day is never counted against you.")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Reader chrome

/// The reader's Back, standing over prose rather than a bar: a capsule
/// with its own quiet scrim.
struct ReaderBackCapsule: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                AppIcon("ph-caret-left", size: 14)
                Text("Back")
                    .font(AppFonts.bodyFont(16))
            }
            .foregroundColor(AppColors.gold)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Capsule().fill(Color.black.opacity(0.32)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.16), lineWidth: 0.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

/// One button of the reader's three-part capsule: an icon over a name.
/// Named, because an unlabelled Aa next to an unlabelled ☰ made the
/// reader guess.
struct ReaderCapsuleButton: Identifiable {
    let id: String
    /// Icon name, or nil to draw the marker ribbon glyph
    let icon: String?
    let label: String
    let action: () -> Void
}

/// The three-part capsule: SIZE · MARK · CONTENTS, each button named.
struct ReaderChromeCapsule: View {

    let buttons: [ReaderCapsuleButton]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                if index > 0 {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.18))
                        .frame(width: 0.5, height: 26)
                }

                Button(action: button.action) {
                    VStack(spacing: 3) {
                        if let icon = button.icon {
                            AppIcon(icon, size: 15)
                        } else {
                            MarkerRibbonShape()
                                .fill(AppColors.gold)
                                .frame(width: 8, height: 14)
                                .padding(.vertical, 0.5)
                        }

                        Text(button.label)
                            .font(AppFonts.labelFont(7))
                            .tracking(1.2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .foregroundColor(AppColors.gold)
                    .frame(width: 52, height: 46)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(button.label.capitalized)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColors.gold.opacity(0.16), lineWidth: 0.5)
        )
    }
}

// MARK: - Prose

/// One paragraph of a book, set the reader's way: a versal on the
/// chapter's opening, footnote markers lifted into small gold
/// superscripts a tap can raise, a ribbon in the margin where the
/// paragraph is marked, a wash where it is selected or where the voice
/// is reading.
struct ReaderProseParagraph: View {

    let text: String
    let isFirst: Bool
    let size: CGFloat

    /// This edition's footnote marker, compiled once by the reader
    var noteRegex: NSRegularExpression? = nil

    var isSelected: Bool = false
    var isMarked: Bool = false
    var isFollowed: Bool = false

    let onTap: () -> Void

    private static let openingQuotes: Set<Character> = ["\u{201C}", "\u{2018}", "\"", "'"]

    var body: some View {
        composed
            .lineSpacing(ReadingTypography.lineSpacing(for: size))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, isSelected || isFollowed ? 8 : 0)
            .padding(.vertical, isSelected || isFollowed ? 6 : 0)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.gold.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: 0.5)
                        )
                } else if isFollowed {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.gold.opacity(0.06))
                }
            }
            .padding(.horizontal, isSelected || isFollowed ? -8 : 0)
            .padding(.vertical, isSelected || isFollowed ? -6 : 0)
            .overlay(alignment: .topTrailing) {
                if isMarked {
                    MarkerRibbonShape()
                        .fill(AppColors.goldLight)
                        .frame(width: 11, height: 26)
                        .offset(x: 20, y: 2)
                        .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .accessibilityAction(named: "Select this passage") { onTap() }
    }

    /// The paragraph as one Text: versal where it earns one, then the
    /// prose with its markers styled.
    private var composed: Text {
        let qualifies = isFirst && text.count >= 80
            && text.first.map { !Self.openingQuotes.contains($0) } == true

        if qualifies, let first = text.first {
            let capSize = (size * 1.6).rounded()
            return Text(String(first))
                .font(AppFonts.titleFont(capSize))
                .foregroundColor(AppColors.gold)
                + Text(attributed(String(text.dropFirst())))
        }
        return Text(attributed(text))
    }

    /// The prose with each footnote marker set small, gold, raised, and
    /// linked — the reader's OpenURLAction turns the link into the
    /// footnote pull-up. Where the edition prints no markers this is a
    /// plain attributed run.
    private func attributed(_ string: String) -> AttributedString {
        var base = AttributedString(string)
        base.font = AppFonts.readingFont(size)
        base.foregroundColor = AppColors.cream.opacity(0.92)

        guard let noteRegex else { return base }
        let range = NSRange(string.startIndex..., in: string)
        // Not every match is a marker. `LibraryBookParser.divide` makes
        // the same distinction for the apparatus, and names the case:
        // Taylor gives the Psalms in both numberings, so "Ps. 88[89]:1"
        // carries a bracketed number that is no footnote at all. A real
        // marker never follows a digit — it follows a word, a stop, or a
        // space — so that one test leaves the alternative verse numbers
        // alone without touching genuine markers.
        let matches = noteRegex.matches(in: string, range: range).filter { match in
            guard let bounds = Range(match.range, in: string),
                  bounds.lowerBound > string.startIndex else { return true }
            let preceding = string[string.index(before: bounds.lowerBound)]
            return !preceding.isNumber
        }
        guard !matches.isEmpty else { return base }

        var built = AttributedString()
        var cursor = string.startIndex

        for match in matches {
            guard let bounds = Range(match.range, in: string) else { continue }

            if cursor < bounds.lowerBound {
                var plain = AttributedString(String(string[cursor..<bounds.lowerBound]))
                plain.font = AppFonts.readingFont(size)
                plain.foregroundColor = AppColors.cream.opacity(0.92)
                built += plain
            }

            let markerText = String(string[bounds])
            var marker = AttributedString(markerText)
            marker.font = AppFonts.readingFont(max((size * 0.78).rounded(), 11))
            marker.baselineOffset = (size * 0.28).rounded()
            marker.foregroundColor = AppColors.gold
            if let number = Int(markerText.filter(\.isNumber)) {
                marker.link = URL(string: "lumen-note://\(number)")
            }
            built += marker

            cursor = bounds.upperBound
        }

        if cursor < string.endIndex {
            var tail = AttributedString(String(string[cursor...]))
            tail.font = AppFonts.readingFont(size)
            tail.foregroundColor = AppColors.cream.opacity(0.92)
            built += tail
        }
        return built
    }
}

// MARK: - Passage actions

/// The capsule that rises over a selected paragraph: NOTE, MARK, SHARE.
struct PassageActionBar: View {

    let isMarked: Bool
    let onNote: () -> Void
    let onMark: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            action(icon: "ph-note-pencil", label: "NOTE", handler: onNote)

            divider

            Button(action: onMark) {
                HStack(spacing: 7) {
                    MarkerRibbonShape()
                        .fill(isMarked ? AppColors.goldLight : AppColors.gold)
                        .frame(width: 8, height: 15)

                    Text(isMarked ? "UNMARK" : "MARK")
                        .font(AppFonts.labelFont(10))
                        .tracking(1.5)
                }
                .foregroundColor(isMarked ? AppColors.goldLight : AppColors.gold)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isMarked ? "Take the mark off this passage" : "Mark this passage")

            divider

            action(icon: "ph-export", label: "SHARE", handler: onShare)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppColors.cardElevated)
                .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.18))
            .frame(width: 0.5, height: 22)
    }

    private func action(icon: String, label: String, handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            HStack(spacing: 7) {
                AppIcon(icon, size: 14)
                Text(label)
                    .font(AppFonts.labelFont(10))
                    .tracking(1.5)
            }
            .foregroundColor(AppColors.gold)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.capitalized)
    }
}

// MARK: - Toast

/// A small engraved confirmation — "SAVED TO YOUR JOURNAL" — that rises
/// above the foot and withdraws by itself.
private struct ReaderToastModifier: ViewModifier {

    @Binding var message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.9)
                    .foregroundColor(AppColors.goldLight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5))
                    .padding(.bottom, 120)
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(for: .seconds(1.9))
                        // `.id(message)` gives each message its own
                        // identity, so a second toast cancels this
                        // task. `try?` swallows that, and without the
                        // guard the withdrawal below would clear the
                        // message that just replaced this one.
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeOut(duration: 0.3)) { self.message = nil }
                    }
                    .id(message)
            }
        }
        .animation(.easeOut(duration: 0.25), value: message)
    }
}

extension View {
    /// Shows the message 120 points above the foot for 1.9 seconds.
    func readerToast(_ message: Binding<String?>) -> some View {
        modifier(ReaderToastModifier(message: message))
    }
}

// MARK: - Footnote sheet

/// One of the editor's notes, raised from its marker in the prose. The
/// full apparatus still stands at the chapter's foot; this brings one
/// note to the thumb without losing the line.
struct LibraryFootnoteSheet: View {

    let number: Int
    let text: String

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("FOOTNOTE \(number) · THE EDITOR'S")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .padding(.top, 24)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(height: 0.5)

                Text(text)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.88))
                    .lineSpacing(ReadingTypography.lineSpacing(for: 15) * 0.6)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Share sheet

/// The passage as a small setting — the words, the ornament, the
/// citation, the imprint — offered to the system share sheet as an
/// image, with the plain text a copy away.
struct PassageShareSheet: View {

    let passage: String
    /// "St. Thérèse of Lisieux · Chapter I"
    let citeLine: String
    /// The full citation for the copied text
    let citation: String
    var onCopied: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var rendered: UIImage?

    private var trimmed: String {
        passage.count > 220 ? String(passage.prefix(220)) + "\u{2026}" : passage
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("SHARE THIS PASSAGE")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .padding(.top, 24)

                    card

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = "\u{201C}\(passage)\u{201D}\n\n\(citation)"
                            onCopied?()
                            dismiss()
                        } label: {
                            Text("COPY TEXT")
                                .font(AppFonts.labelFont(10))
                                .tracking(1.8)
                                .foregroundColor(AppColors.goldLight)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(Capsule().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        if let rendered {
                            ShareLink(
                                item: Image(uiImage: rendered),
                                preview: SharePreview("A passage", image: Image(uiImage: rendered))
                            ) {
                                Text("SHARE")
                                    .font(AppFonts.labelFont(10))
                                    .tracking(1.8)
                                    .foregroundColor(AppColors.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                                    .background(Capsule().fill(AppColors.goldCTAGradient))
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(GoldCTAButtonStyle())
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear { render() }
    }

    private var card: some View {
        PassageShareCard(passage: trimmed, citeLine: citeLine)
    }

    /// Draws the card once for the share sheet — what leaves the app is
    /// exactly what the reader saw.
    private func render() {
        let renderer = ImageRenderer(
            content: PassageShareCard(passage: trimmed, citeLine: citeLine)
                .frame(width: 340)
        )
        renderer.scale = 3
        rendered = renderer.uiImage
    }
}

/// The card itself, kept apart so the preview on screen and the image
/// that is shared are one drawing.
struct PassageShareCard: View {

    let passage: String
    let citeLine: String

    var body: some View {
        VStack(spacing: 0) {
            Text("\u{201C}\(passage)\u{201D}")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .lineSpacing(ReadingTypography.lineSpacing(for: 15) * 0.6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            OrnamentDivider(showsCross: false)
                .frame(width: 100)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Text(citeLine.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .multilineTextAlignment(.center)

            Text("LUMEN VIAE")
                .font(AppFonts.labelFont(8))
                .tracking(3)
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                .padding(.top, 14)
        }
        .padding(.top, 26)
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: 0.5)
                .padding(8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Your notes

/// The quiet door on the book page to the notes pull-up.
struct BookNotesRow: View {

    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                AppIcon("ph-note-pencil", size: 15)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Text(count == 1
                     ? "1 note on a passage of this book"
                     : "\(count) notes on passages of this book")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream)

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 11)
                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
            }
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your notes on this book, \(count)")
    }
}

/// The notes pull-up: the passages the reader wrote something about.
/// Each one lives in the journal — this is a window onto it, not a
/// second store.
struct BookNotesSheet: View {

    let notes: [JournalEntry]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("YOUR NOTES ON THIS BOOK")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    Text("Passages you wrote something about. Each one is in your journal as well.")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.cream.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 14)

                    Rectangle()
                        .fill(AppColors.gold.opacity(0.2))
                        .frame(height: 0.5)

                    ForEach(notes) { note in
                        noteRow(note)

                        Rectangle()
                            .fill(AppColors.gold.opacity(0.12))
                            .frame(height: 0.5)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    /// One note: the passage, the reader's own words, and when.
    /// The entry's text is the journal's own composition — passage,
    /// citation, comment, blank-line separated — so it is read back
    /// the same way.
    private func noteRow(_ note: JournalEntry) -> some View {
        let parts = note.text.components(separatedBy: "\n\n")
        let quote = parts.first ?? note.text
        let comment = parts.count > 2 ? parts[2...].joined(separator: "\n\n") : nil

        return VStack(alignment: .leading, spacing: 8) {
            Text(quote)
                .font(AppFonts.readingItalicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            if let comment, !comment.isEmpty {
                Text(comment)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.cream.opacity(0.75))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                if parts.count > 1 {
                    Text(parts[1])
                        .font(AppFonts.labelFont(9))
                        .tracking(1.2)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(Self.dateFormatter.string(from: note.createdAt))
                    .font(AppFonts.italicFont(11))
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
            }
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Spans

/// Hours and minutes in the goal band's own hand: "2 h 5 m", "48 m".
enum ReadingSpans {

    static func spell(_ seconds: Double) -> String {
        let minutes = max(Int(seconds) / 60, 0)
        if minutes < 60 { return "\(minutes) m" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) m"
    }

    /// "24 MIN" — a recording's length as a chip wears it.
    static func chipMinutes(_ seconds: Double) -> String {
        let minutes = max(Int((seconds / 60).rounded()), 1)
        if minutes >= 60 {
            let hours = minutes / 60
            let rest = minutes % 60
            return rest == 0 ? "\(hours) HR" : "\(hours) HR \(rest) MIN"
        }
        return "\(minutes) MIN"
    }
}
