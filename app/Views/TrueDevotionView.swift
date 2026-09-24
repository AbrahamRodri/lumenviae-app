//
//  TrueDevotionView.swift
//  Lumen Viae
//
//  The Devotion in Summary: St. Louis de Montfort's True Devotion to
//  Mary, digested — a companion to the book, laid out like one.
//
//  - The book's own cloth over its halo, beside this page's title —
//    the book named in the byline under it — an epigraph from the book,
//    and the two doors a reader wants: read the book, or go to the
//    Total Consecration.
//  - "In one sentence": the whole devotion, said once, large.
//  - The contents, set like a printed book's — the six parts of the
//    teaching (`TrueDevotionData.teaching`) with Roman numerals and dot
//    leaders, each opening its reading.
//  - The short prayers of the devotion as cards swiped through, each
//    whole in the reader's prayer language.
//  - His sayings, one to a card, swiped through.
//
//  Named apart from the book. Both used to be called "True Devotion to
//  Mary", so a reader who wanted the text and a reader who wanted the
//  teaching arrived at the same title and could not tell which they had.
//  The large title is this page's own, for the same reason: set large
//  beside the cloth, the book's title made the page read as the book.
//

import SwiftUI

// MARK: - TrueDevotionView

struct TrueDevotionView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    bookHeader
                        .padding(.horizontal, 24)
                        .devotionalEntrance()

                    oneSentence
                        .padding(.horizontal, 24)
                        .padding(.top, 44)
                        .devotionalEntrance(delay: 0.08)

                    heading("Contents", note: "The teaching, part by part")
                    contents
                        .padding(.horizontal, 24)

                    heading("Short Prayers", note: "To say through the day")
                    prayerCards

                    heading("In His Words", note: "St. Louis de Montfort")
                    sayingCards
                        .padding(.bottom, 56)
                }
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }

    // MARK: - The Book

    /// The cloth beside this page's title and the book's byline, an
    /// epigraph from the book, and the two doors
    private var bookHeader: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 20) {
                Button {
                    router.push(.trueDevotionBook)
                } label: {
                    BookCover(
                        title: LibraryCatalog.trueDevotionDisplay.title,
                        author: LibraryCatalog.trueDevotionDisplay.author,
                        bindingColor: TrueDevotionBook.bindingColor
                    )
                    .frame(width: 112)
                    .shadow(color: .black.opacity(0.55), radius: 15, y: 7)
                    .background {
                        BookHalo(bindingColor: TrueDevotionBook.bindingColor)
                            .allowsHitTesting(false)
                    }
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("True Devotion to Mary. Opens the book.")

                VStack(alignment: .leading, spacing: 8) {
                    Text("A COMPANION TO THE BOOK")
                        .font(AppFonts.labelFont(9))
                        .tracking(2.4)
                        .foregroundColor(AppColors.gold)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("The Devotion in Summary")
                        .font(AppFonts.titleFont(24))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)

                    // The book is named here, under the page's title
                    Text("From \(LibraryCatalog.trueDevotionDisplay.title)\n\(LibraryCatalog.trueDevotionDisplay.author) · c. 1712")
                        .font(AppFonts.readingItalicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            .padding(.top, 20)

            // Not the book's first line (n. 1): Part I of the contents
            // opens on that saying, and the page quoted it twice. This one
            // stood among his sayings below, and has left them for here.
            QuotedPassageText(
                passage: Self.epigraph.text,
                citation: Self.epigraph.source,
                size: 17
            )
            .padding(.leading, 16)

            VStack(spacing: 6) {
                // The page's one filled act; it goes on to a page
                GoldCTAButton(title: "Read the Book", glyph: .chevron) {
                    router.push(.trueDevotionBook)
                }

                // The quieter door, and it leaves this stack for another
                // tab, so it says so rather than switching silently
                VStack(spacing: 2) {
                    QuietGoldButton(
                        title: "The Total Consecration",
                        leadingIcon: PrayerShortcut.consecration.icon,
                        trailingIcon: "ph-caret-right",
                        size: 10
                    ) {
                        router.run(.consecration)
                    }
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                    )

                    Text("Opens the Consecrate tab")
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 6)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - In One Sentence

    private var oneSentence: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("IN ONE SENTENCE")
                .font(AppFonts.labelFont(9.5))
                .tracking(2.8)
                .foregroundColor(AppColors.gold.opacity(0.9))

            Text("Give yourself entirely to Mary — body and soul, goods and merits, without reserve and for ever — so as to belong entirely to Jesus through her.")
                .font(AppFonts.readingItalicFont(22))
                .foregroundColor(AppColors.cream)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("Montfort calls it an easy, short, perfect and secure way to union with Our Lord. What follows is his teaching, a part at a time.")
                .font(AppFonts.readingFont(16))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Headings

    private func heading(_ title: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.titleFont(22))
                .foregroundColor(AppColors.cream)

            Text(note)
                .font(AppFonts.readingItalicFont(14.5))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 52)
        .padding(.bottom, 18)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Contents

    /// A book's contents page: numeral, title, dot leaders, and how many
    /// parts the reading holds
    private var contents: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(TrueDevotionData.teaching.entries.enumerated()), id: \.element.id) { index, reading in
                Button {
                    router.push(.libraryReading(id: reading.id))
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(LiturgicalCalendarFormat.roman(index + 1))
                                .font(AppFonts.titleFont(15))
                                .foregroundColor(AppColors.gold)
                                .frame(width: 30, alignment: .leading)

                            Text(Self.shortTitle(reading.title))
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)
                                .layoutPriority(1)

                            DotLeader()
                                .frame(height: 2)
                                .frame(minWidth: 16)

                            // Said in words: a bare figure after a dot
                            // leader reads as a page number
                            Text("\(reading.parts.count) \(reading.parts.count == 1 ? "part" : "parts")".uppercased())
                                .font(AppFonts.labelFont(8.5))
                                .tracking(1.5)
                                .foregroundColor(AppColors.gold.opacity(0.8))
                                .fixedSize()
                        }

                        Text(reading.detail)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.leading, 38)
                    }
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    /// "Key Principles of True Devotion" → "Key Principles"
    private static func shortTitle(_ title: String) -> String {
        for suffix in [" of True Devotion to Mary", " of True Devotion", " of This Devotion", " of the Devotion", " to Avoid"] {
            if title.hasSuffix(suffix) { return String(title.dropLast(suffix.count)) }
        }
        return title
    }

    // MARK: - Prayers

    /// The short prayers as cards, swiped through
    private var prayerCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(TrueDevotionPrayers.prayers.items) { prayer in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(prayer.title.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.8)
                            .foregroundColor(AppColors.gold.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)

                        PrayerText(
                            content: prayer.formattedContent(for: settings.prayerLanguage),
                            size: 16,
                            alignment: .leading
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: 262, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [TrueDevotionBook.bindingColor.opacity(0.55), AppColors.cardBackground.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline)
                    )
                }
            }
            .padding(.horizontal, 20)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: - Sayings

    private struct Saying {
        let text: String
        let source: String
    }

    /// The page's epigraph, under the title
    private static let epigraph = Saying(
        text: "God the Father gathered all the waters together and called them the seas; He gathered all His graces together and called them Mary.",
        source: "True Devotion, n. 23"
    )

    private static let sayings: [Saying] = [
        Saying(
            text: "Mary is the safest, easiest, shortest and most perfect way of approaching Jesus.",
            source: "True Devotion, n. 55"
        ),
        Saying(
            text: "The more one is consecrated to Mary, the more one is consecrated to Jesus Christ.",
            source: "True Devotion, n. 120"
        ),
        Saying(
            text: "Happy, indeed sublimely happy, is the person to whom the Holy Spirit reveals the secret of Mary.",
            source: "The Secret of Mary, n. 20"
        ),
        Saying(
            text: "I am all Thine, and all that I have is Thine.",
            source: "The Formula of Consecration"
        )
    ]

    private var sayingCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Self.sayings, id: \.text) { saying in
                    VStack(alignment: .leading, spacing: 14) {
                        Text("\u{201C}")
                            .font(AppFonts.titleFont(44))
                            .foregroundColor(AppColors.goldLight)
                            .frame(height: 26, alignment: .top)

                        Text(saying.text)
                            .font(AppFonts.readingItalicFont(18))
                            .foregroundColor(AppColors.cream)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        Text(saying.source.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(1.6)
                            .foregroundColor(AppColors.gold.opacity(0.75))
                    }
                    .frame(width: 250, alignment: .topLeading)
                    .frame(minHeight: 210, alignment: .topLeading)
                    .padding(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
                    )
                }
            }
            .padding(.horizontal, 20)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

// MARK: - DotLeader

/// The dotted line a printed contents page runs from a title to its page
private struct DotLeader: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(AppColors.gold.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.5, 5]))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrueDevotionView()
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
