//
//  PrayerBookChapterView.swift
//  Lumen Viae
//
//  One topic of the Prayer Book (the "Prayer Book Topics" design, option
//  B, Oct 2026): its painting at the head of the page, dissolving into
//  it, the part of the book it stands in, its name and one line, then a
//  strip of its sub-headings to jump between. Beneath: the orders of
//  prayer said together that belong here (Before Mass and After
//  Communion under Holy Mass and Communion), then its prayers under the
//  book's sub-headings, each with the reader's own marks. The page draws
//  its own Back over the painting, so the system bar is hidden.
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

    /// The topic on the page — starts as the one pushed, and moves on
    /// when the foot turns the page
    @State private var chapterID: String
    @State private var pageOpacity: Double = 1

    private var chapter: PrayerBookChapter? { PrayerBook.chapter(chapterID) }

    /// How tall the painting stands at the head of the page
    private static let heroHeight: CGFloat = 300

    /// Room left above a sub-heading jumped to, clear of the Back capsule
    private static let jumpClearance: CGFloat = 76

    init(chapterID: String) {
        _chapterID = State(initialValue: chapterID)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.appGradient.ignoresSafeArea()

            if let chapter {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            Color.clear.frame(height: 0).id("top")

                            hero(chapter)

                            header(chapter)
                                .padding(.horizontal, 22)
                                .padding(.top, -64)
                                .devotionalEntrance()

                            if chapter.sections.count > 1 {
                                sectionStrip(chapter, proxy: proxy)
                                    .padding(.top, 18)
                            }

                            if !chapter.orders.isEmpty {
                                orders(chapter)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 26)
                            }

                            sections(chapter)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .devotionalEntrance(delay: 0.06)

                            turner(chapter, proxy: proxy)
                                .padding(.horizontal, 20)
                                .padding(.top, 34)
                                .padding(.bottom, 48)
                        }
                        .opacity(pageOpacity)
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }

            ReaderBackCapsule { router.pop() }
                .padding(.leading, 16)
                .padding(.top, 4)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Head

    /// The topic's painting, run to the top of the glass and dissolving
    /// into the page beneath the title, never to a flat slab
    private func hero(_ chapter: PrayerBookChapter) -> some View {
        let painting = PrayerBookPainting.topic(chapter)
        return CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .overlay(alignment: .top) {
                // A veil under the status bar and the Back capsule
                LinearGradient(
                    colors: [AppColors.background.opacity(0.55), AppColors.background.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.heroHeight)
            .clipped()
            // Dissolves to clear, so the page's own gradient shows through
            // beneath it rather than a slab of one colour
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.5),
                        .init(color: .black.opacity(0.35), location: 0.8),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }

    private func header(_ chapter: PrayerBookChapter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(chapter.part.title) · \(PrayerBookView.prayerCount(chapter.prayerIDs.count))")
                .font(AppFonts.labelFont(9.5))
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundColor(AppColors.gold)

            Text(chapter.title)
                .font(AppFonts.titleFont(28))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(chapter.epigraph)
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The topic's sub-headings as a strip that scrolls sideways, each a
    /// jump to its prayers
    private func sectionStrip(_ chapter: PrayerBookChapter, proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(chapter.sections.enumerated()), id: \.offset) { i, section in
                    Button {
                        withAnimation(Motion.travel(0.45)) {
                            proxy.scrollTo(Self.sectionAnchor(i), anchor: .top)
                        }
                    } label: {
                        Text(section.title)
                            .font(AppFonts.labelFont(9.5))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundColor(AppColors.cream)
                            .padding(.horizontal, 13)
                            .frame(minHeight: 36)
                            .overlay(
                                Capsule()
                                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                            )
                            .contentShape(Capsule())
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(SacredCardButtonStyle())
                    .accessibilityLabel("Go to \(section.title)")
                }
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: Orders

    /// The orders of prayer said together that belong to this topic, as
    /// the Prayers page's shortcuts are drawn
    private func orders(_ chapter: PrayerBookChapter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("Prayed together")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(chapter.orders) { order in
                    PrayersShortcutTile(
                        title: order.title(on: Date()),
                        painting: .order(order)
                    ) {
                        router.push(.prayerOrder(id: order.id))
                    }
                }
            }
        }
    }

    // MARK: Prayers

    private func sections(_ chapter: PrayerBookChapter) -> some View {
        let seasonal = PrayerBook.antiphon(on: Date()).prayerID
        let numbered = Self.numbered(chapter)

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(numbered.enumerated()), id: \.offset) { i, section in
                VStack(alignment: .leading, spacing: 4) {
                    // The anchor a jump lands on, standing clear above the
                    // heading so it is not left under the Back capsule
                    Color.clear
                        .frame(height: Self.jumpClearance)
                        .padding(.bottom, -Self.jumpClearance)
                        .id(Self.sectionAnchor(i))

                    if chapter.sections.count > 1 {
                        sectionHeading(section.title)
                            .padding(.top, 22)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(section.rows.enumerated()), id: \.offset) { j, row in
                            BookPrayerRow(
                                prayer: row.prayer,
                                number: row.number,
                                badge: chapter.id == PrayerBook.ourLady.id && row.prayer.id == seasonal
                                    ? "This season" : nil,
                                showsRule: j < section.rows.count - 1
                            ) {
                                router.push(.devotionPrayer(id: row.prayer.id))
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(AppFonts.labelFont(9.5))
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundColor(AppColors.gold)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            Rectangle()
                .fill(AppColors.gold.opacity(0.24))
                .frame(height: AppLine.hairline)
        }
    }

    private struct NumberedSection {
        let title: String
        let rows: [(number: Int, prayer: BookPrayer)]
    }

    /// The prayers numbered down the whole topic, as a contents page
    /// numbers them, the count running on across the sub-headings
    private static func numbered(_ chapter: PrayerBookChapter) -> [NumberedSection] {
        var number = 0
        return chapter.sections.map { section in
            NumberedSection(
                title: section.title,
                rows: section.prayers.map { prayer in
                    number += 1
                    return (number, prayer)
                }
            )
        }
    }

    private static func sectionAnchor(_ index: Int) -> String { "section-\(index)" }

    // MARK: Turning the page

    @ViewBuilder
    private func turner(_ chapter: PrayerBookChapter, proxy: ScrollViewProxy) -> some View {
        let chapters = PrayerBook.chapters
        if let i = chapters.firstIndex(where: { $0.id == chapter.id }) {
            VStack(spacing: 14) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(height: AppLine.hairline)

                HStack(alignment: .top) {
                    if i > 0 {
                        turnButton(chapters[i - 1], forward: false, proxy: proxy)
                    }
                    Spacer(minLength: 12)
                    if i < chapters.count - 1 {
                        turnButton(chapters[i + 1], forward: true, proxy: proxy)
                    }
                }
            }
        }
    }

    /// The next topic replaces this one rather than stacking on it, so
    /// Back always returns to the Prayers page
    private func turnButton(_ target: PrayerBookChapter, forward: Bool, proxy: ScrollViewProxy) -> some View {
        Button {
            turn(to: target.id, proxy: proxy)
        } label: {
            VStack(alignment: forward ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if !forward { AppIcon("ph-caret-left", size: 9) }
                    Text(forward ? "NEXT TOPIC" : "TOPIC BEFORE")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                    if forward { AppIcon("ph-caret-right", size: 9) }
                }
                .foregroundColor(AppColors.gold.opacity(0.8))

                Text(target.title)
                    .font(AppFonts.readingFont(15.5))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .multilineTextAlignment(forward ? .trailing : .leading)
            }
            .frame(maxWidth: 170, alignment: forward ? .trailing : .leading)
            // Hung from the top, so the two kickers share a line when
            // one title wraps and the other does not
            .frame(minHeight: 44, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    /// Fades the page out, swaps the topic and puts the scroll back to
    /// the top unseen, then fades in — never a flash of the old topic
    private func turn(to id: String, proxy: ScrollViewProxy) {
        withAnimation(.easeIn(duration: 0.14)) { pageOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            chapterID = id
            proxy.scrollTo("top", anchor: .top)
            withAnimation(.easeOut(duration: 0.24)) { pageOpacity = 1 }
            // A new topic is a new page to VoiceOver too, as it was when
            // the turn pushed one: it starts again at the header
            AccessibilityNotification.ScreenChanged(nil).post()
        }
    }
}

#Preview {
    NavigationStack {
        PrayerBookChapterView(chapterID: "mass")
            .environment(AppRouter())
    }
}
