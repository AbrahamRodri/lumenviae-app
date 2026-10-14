//
//  PrayerBookChapterView.swift
//  Lumen Viae
//
//  One topic of the Prayer Book (the "simplify the prayer topic" design,
//  option B, Painted Doors, Oct 2026): its painting at the head of the
//  page, about half the glass, with the topic's name and one line set
//  over its foot, then the prayers. Where the topic has orders of prayer
//  said together (Before Mass and After Communion under Holy Mass and
//  Communion), one painted card, Pray together, stands first with a row
//  for each. The prayers follow under the book's sub-headings, set as the
//  Prayers tab sets its shelves, each a row with a small arched picture
//  of the prayer's holy card, its name and the reader's own marks. The foot is the next topic as a painted card, and
//  a quiet line back to the topic before. The page draws its own Back
//  over the painting, so the system bar is hidden; once the painting has
//  scrolled away, a dark ground comes up under the clock and the Back so
//  no prayer runs beneath them.
//
//  The page once stacked a kicker (the part of the book and a count), a
//  strip of its sub-headings to jump between, gold capital sub-headings
//  with rules, and Roman numerals running down the whole topic: six
//  voices of small gold capitals over the prayer names. They went; the
//  strip only repeated the sub-headings beneath it.
//
//  The foot turns to the topic before or after in place, as a book's
//  pages do: the page fades out, the topic is swapped and the scroll put
//  back to the top unseen, and it fades in. It once popped this page and
//  pushed the next in one tick, and SwiftUI updated the page where it
//  stood: the next chapter opened scrolled to wherever the last was left.
//

import SwiftUI

struct PrayerBookChapterView: View {

    @Environment(AppRouter.self) private var router

    private let store: PrayerBookStore
    private let fixedDate: Date?

    /// The topic on the page — starts as the one pushed, and moves on
    /// when the foot turns the page
    @State private var chapterID: String
    @State private var pageOpacity: Double = 1

    /// The page turning to another topic. One at a time: two quick taps
    /// once ran two turns from the same topic
    @State private var turnTask: Task<Void, Never>?

    /// Whether the painting has scrolled up behind the clock and the
    /// Back, so the dark ground under them is needed
    @State private var paintingGone = false

    private var chapter: PrayerBookChapter? { PrayerBook.chapter(chapterID) }

    /// The painting stands this share of the whole glass
    private static let heroShare: CGFloat = 0.47

    /// How far below the safe area the Back capsule ends
    private static let backFoot: CGFloat = 52

    init(chapterID: String, store: PrayerBookStore = .shared, date: Date? = nil) {
        _chapterID = State(initialValue: chapterID)
        self.store = store
        self.fixedDate = date
    }

    private var now: Date { fixedDate ?? Date() }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let heroHeight = (geo.size.height + safeTop + geo.safeAreaInsets.bottom) * Self.heroShare

            ZStack(alignment: .topLeading) {
                AppColors.appGradient.ignoresSafeArea()

                if let chapter {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                Color.clear.frame(height: 0).id("top")

                                hero(chapter, height: heroHeight, safeTop: safeTop)
                                    .onGeometryChange(for: Bool.self) { hero in
                                        hero.frame(in: .global).maxY < safeTop + Self.backFoot + 64
                                    } action: { gone in
                                        paintingGone = gone
                                    }

                                VStack(alignment: .leading, spacing: 0) {
                                    if !chapter.orders.isEmpty {
                                        prayTogether(chapter)
                                            .padding(.top, 18)
                                    }

                                    sections(chapter)

                                    foot(chapter, proxy: proxy)
                                        .padding(.top, 40)
                                        .padding(.bottom, 48)
                                }
                                .padding(.horizontal, 18)
                                .devotionalEntrance(delay: 0.06)
                            }
                            .opacity(pageOpacity)
                        }
                        .ignoresSafeArea(edges: .top)
                    }
                }

                chromeGround(safeTop: safeTop)

                ReaderBackCapsule { router.pop() }
                    .padding(.leading, 16)
                    .padding(.top, 4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Head

    /// The topic's painting, run to the top of the glass, with its name
    /// and line over its foot on a scrim that is at full strength behind
    /// the words. Under a larger text size the words grow upward over the
    /// painting rather than being cut or shrunk.
    private func hero(_ chapter: PrayerBookChapter, height: CGFloat, safeTop: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chapter.title)
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.55), radius: 12, y: 2)
                // Only matters if the app-wide cap (DynamicTypeSize.appMaximum,
                // .xLarge) is ever lifted: past AX1 a word like COMMUNION
                // breaks mid-word in Cinzel
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .accessibilityAddTraits(.isHeader)

            if let epigraph = chapter.epigraph {
                Text(epigraph)
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The scrim behind the words, from clear well above them to the
        // page's own ground at their foot, across the whole width
        .background(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0), location: 0),
                    .init(color: AppColors.background.opacity(0.72), location: 0.45),
                    .init(color: AppColors.background.opacity(0.92), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .padding(.top, -90)
            .accessibilityHidden(true)
        }
        // Never under the clock or the Back: where the words outgrow the
        // painting, the painting grows with them
        .padding(.top, safeTop + Self.backFoot + 16)
        .devotionalEntrance()
        .frame(maxWidth: .infinity, minHeight: height, alignment: .bottomLeading)
        .background { painting(chapter, safeTop: safeTop) }
        .clipped()
    }

    /// The painting, dissolving to clear at its foot so the page's own
    /// gradient shows through beneath it rather than a slab of one colour,
    /// and veiled under the status bar and the Back
    private func painting(_ chapter: PrayerBookChapter, safeTop: CGFloat) -> some View {
        let painting = PrayerBookPainting.topic(chapter)
        return CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [AppColors.backgroundDeep.opacity(0.6), AppColors.backgroundDeep.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: safeTop + Self.backFoot + 24)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.55),
                        .init(color: .black.opacity(0.4), location: 0.85),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }

    /// The dark ground under the clock and the Back once the painting has
    /// gone, so the prayers dissolve beneath them and never run under
    /// either
    private func chromeGround(safeTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            AppColors.backgroundDeep
                .frame(height: safeTop + Self.backFoot + 6)
            // Long enough that a row passing beneath dissolves rather than
            // being sliced at the band's edge
            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep, location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.85), location: 0.35),
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 44)
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
        .opacity(paintingGone ? 1 : 0)
        .animation(Motion.crossfade, value: paintingGone)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Pray together

    /// The orders of prayer said together that belong to this topic: one
    /// card, the first order's painting on its band, a row for each
    private func prayTogether(_ chapter: PrayerBookChapter) -> some View {
        let orders = chapter.orders
        let painting = PrayerBookPainting.order(orders[0], on: now)

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            stops: [
                                .init(color: AppColors.cardBackground.opacity(0), location: 0.2),
                                .init(color: AppColors.cardBackground.opacity(0.85), location: 0.82),
                                .init(color: AppColors.cardBackground, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .accessibilityHidden(true)

                Text("Pray together")
                    .font(AppFonts.titleFont(18))
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { i, order in
                    TopicOrderRow(
                        title: order.title(on: now),
                        occasion: order.occasion,
                        showsRule: i < orders.count - 1
                    ) {
                        router.push(.prayerOrder(id: order.id))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
        )
    }

    // MARK: Prayers

    private func sections(_ chapter: PrayerBookChapter) -> some View {
        let seasonal = PrayerBook.antiphon(on: now).prayerID
        let headed = chapter.sections.count > 1

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(chapter.sections.enumerated()), id: \.offset) { i, section in
                VStack(alignment: .leading, spacing: 0) {
                    if headed {
                        PrayersShelfHeading(title: section.title)
                            .padding(.top, 32)
                            .padding(.bottom, 4)
                    }

                    let prayers = section.prayers
                    ForEach(Array(prayers.enumerated()), id: \.offset) { j, prayer in
                        TopicPrayerRow(
                            prayer: prayer,
                            store: store,
                            seasonal: chapter.id == PrayerBook.ourLady.id && prayer.id == seasonal,
                            showsRule: j < prayers.count - 1
                        ) {
                            router.push(.devotionPrayer(id: prayer.id, set: .topic(chapter.id)))
                        }
                    }
                }
                // A topic with no sub-headings, or no orders above it,
                // still stands clear of what comes before
                .padding(.top, !headed && i == 0 ? 14 : 0)
            }
        }
    }

    // MARK: Turning the page

    /// The next topic as a painted card, then a quiet line back to the
    /// one before. The last topic has no next card: the ornament closes
    /// the page over the line back.
    @ViewBuilder
    private func foot(_ chapter: PrayerBookChapter, proxy: ScrollViewProxy) -> some View {
        let chapters = PrayerBook.chapters
        if let i = chapters.firstIndex(where: { $0.id == chapter.id }) {
            let previous = i > 0 ? chapters[i - 1] : nil
            let next = i < chapters.count - 1 ? chapters[i + 1] : nil

            VStack(spacing: 12) {
                if let next {
                    Button {
                        turn(to: next.id, proxy: proxy)
                    } label: {
                        NextTopicCard(chapter: next)
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityLabel("Next topic, \(next.title)")
                } else {
                    OrnamentDivider()
                        .padding(.vertical, 8)
                }

                if let previous {
                    Button {
                        turn(to: previous.id, proxy: proxy)
                    } label: {
                        Text(Self.backLine(to: previous.title))
                            .font(AppFonts.readingItalicFont(15.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Topic before, \(previous.title)")
                }
            }
        }
    }

    /// "or back to Short Prayers", the name in pale gold
    private static func backLine(to title: String) -> AttributedString {
        var lead = AttributedString("or back to ")
        lead.foregroundColor = AppColors.textSecondary
        var name = AttributedString(title)
        name.foregroundColor = AppColors.goldLight
        return lead + name
    }

    /// Fades the page out, swaps the topic and puts the scroll back to
    /// the top unseen, then fades in — never a flash of the old topic
    private func turn(to id: String, proxy: ScrollViewProxy) {
        withAnimation(Motion.pageFadeOut) { pageOpacity = 0 }
        turnTask?.cancel()
        turnTask = Task { @MainActor in
            try? await Task.sleep(for: Motion.pageFadeGap)
            guard !Task.isCancelled else { return }
            chapterID = id
            proxy.scrollTo("top", anchor: .top)
            withAnimation(Motion.pageFadeIn) { pageOpacity = 1 }
            // A new topic is a new page to VoiceOver too, as it was when
            // the turn pushed one: it starts again at the header
            AccessibilityNotification.ScreenChanged(nil).post()
        }
    }
}

// MARK: - An order's row

/// One order of prayer in the Pray together card: its name over when it
/// is said, and a caret. The whole row opens the order's page.
private struct TopicOrderRow: View {
    let title: String
    let occasion: String
    let showsRule: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(occasion)
                            .font(AppFonts.readingItalicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                }
                .padding(.vertical, 11)
                .frame(minHeight: 56)

                if showsRule {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: AppLine.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(occasion)")
        .accessibilityHint("Prayed together")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - A prayer's row

/// One prayer of the topic: a small arched picture of its holy card (the
/// painting its own page hangs), its name, and at the trailing edge the
/// reader's marks — THIS SEASON on Our Lady's song for the season,
/// LEARNED, the saved ribbon — then a caret. Where the marks and the name
/// will not share a line, the marks drop under the name rather than cut
/// it short. The second name the row once carried stands on the card.
private struct TopicPrayerRow: View {
    let prayer: BookPrayer
    let store: PrayerBookStore
    let seasonal: Bool
    let showsRule: Bool
    let action: () -> Void

    private var learned: Bool { store.isByHeart(prayer.id) }
    private var saved: Bool { store.isKept(prayer.id) }
    private var hasMarks: Bool { seasonal || learned || saved }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    MiniHolyCard(prayerID: prayer.id)

                    if hasMarks {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                names.fixedSize(horizontal: true, vertical: false)
                                Spacer(minLength: 8)
                                marks
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                names
                                marks
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        names.frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.gold.opacity(0.5))
                }
                .padding(.vertical, 9)
                .frame(minHeight: 56)

                if showsRule {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: AppLine.hairline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var names: some View {
        Text(prayer.title)
            .font(AppFonts.readingFont(17))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var marks: some View {
        HStack(spacing: 10) {
            if seasonal {
                Text("THIS SEASON")
                    .font(AppFonts.labelFont(9))
                    .tracking(1.6)
                    .foregroundColor(AppColors.gold)
                    .fixedSize()
            }
            if learned {
                ByHeartMark()
            }
            if saved {
                RibbonMark(kept: true, width: 7, restLength: 12, keptLength: 16)
            }
        }
    }

    private var spokenLabel: String {
        [
            prayer.title,
            seasonal ? "This season" : nil,
            learned ? "Learned" : nil,
            saved ? "Saved" : nil
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

// MARK: - A prayer's card, small

/// The prayer's holy card as a list draws it: its painting in a small
/// arch with a gold edge, as the prayer's own page sets it large
private struct MiniHolyCard: View {
    let prayerID: String

    var body: some View {
        let painting = SavedPrayerPainting.of(prayerID)
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 17,
            bottomLeadingRadius: 4,
            bottomTrailingRadius: 4,
            topTrailingRadius: 17,
            style: .continuous
        )
        PaintingThumbnail(painting: painting, size: CGSize(width: 34, height: 44))
            .frame(width: 34, height: 44)
            .clipShape(shape)
            .overlay(shape.strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
            .accessibilityHidden(true)
    }
}

// MARK: - The next topic

/// The next topic as a painted card: its own painting under a scrim that
/// darkens toward the words, "Next topic" over its name
private struct NextTopicCard: View {
    let chapter: PrayerBookChapter

    var body: some View {
        let painting = PrayerBookPainting.topic(chapter)

        VStack(alignment: .leading, spacing: 2) {
            Text("Next topic")
                .font(AppFonts.readingItalicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.78))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(chapter.title)
                    .font(AppFonts.titleFont(22))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .bottomLeading)
        .background {
            CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.background.opacity(0.92), location: 0),
                            .init(color: AppColors.background.opacity(0.55), location: 0.55),
                            .init(color: AppColors.background.opacity(0.1), location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        PrayerBookChapterView(chapterID: "mass")
            .environment(AppRouter())
    }
}
