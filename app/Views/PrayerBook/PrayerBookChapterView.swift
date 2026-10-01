//
//  PrayerBookChapterView.swift
//  Lumen Viae
//
//  One chapter of the Prayer Book: its numeral and name, its Latin, the
//  line that says what it holds, and its prayers as a ruled list, each
//  with the reader's own marks. The foot turns to the chapter before or
//  after, as a book's pages do — in place, the way a prayer's page steps
//  along its chapter: the page fades out, the chapter is swapped and the
//  scroll put back to the top unseen, and it fades in. It once popped
//  this page and pushed the next in one tick, and SwiftUI updated the
//  page where it stood: the next chapter opened scrolled to wherever the
//  last was left, its name and first prayers above the screen.
//

import SwiftUI

struct PrayerBookChapterView: View {

    @Environment(AppRouter.self) private var router

    /// The chapter on the page — starts as the one pushed, and moves on
    /// when the foot turns the page
    @State private var chapterID: String
    @State private var pageOpacity: Double = 1

    private var chapter: PrayerBookChapter? { PrayerBook.chapter(chapterID) }

    init(chapterID: String) {
        _chapterID = State(initialValue: chapterID)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            if let chapter {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 0).id("top")

                            header(chapter)
                                .padding(.horizontal, 28)
                                .padding(.top, 8)
                                .devotionalEntrance()

                            list(chapter)
                                .padding(.horizontal, 20)
                                .padding(.top, 26)
                                .devotionalEntrance(delay: 0.06)

                            turner(chapter, proxy: proxy)
                                .padding(.horizontal, 20)
                                .padding(.top, 34)
                                .padding(.bottom, 48)
                        }
                        .opacity(pageOpacity)
                    }
                    .topChromeFade()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
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

    private func header(_ chapter: PrayerBookChapter) -> some View {
        VStack(spacing: 12) {
            Text("CHAPTER \(chapter.numeral)")
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            AppIcon(chapter.icon, size: 26)
                .foregroundColor(AppColors.goldLight)

            Text(chapter.title)
                .font(AppFonts.titleFont(28))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text(chapter.latinTitle)
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.65))

            OrnamentDivider()
                .frame(width: 150)
                .padding(.vertical, 2)

            Text(chapter.epigraph)
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func list(_ chapter: PrayerBookChapter) -> some View {
        let seasonal = PrayerBook.antiphon(on: Date()).prayerID
        let prayers = chapter.prayers
        return VStack(spacing: 0) {
            ForEach(Array(prayers.enumerated()), id: \.element.id) { i, prayer in
                BookPrayerRow(
                    prayer: prayer,
                    number: i + 1,
                    badge: chapter.id == "our_lady" && prayer.id == seasonal ? "This season" : nil,
                    showsRule: i < prayers.count - 1
                ) {
                    router.push(.devotionPrayer(id: prayer.id))
                }
            }
        }
    }

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

    /// The next chapter replaces this one rather than stacking on it, so
    /// Back always returns to the book's first page
    private func turnButton(_ target: PrayerBookChapter, forward: Bool, proxy: ScrollViewProxy) -> some View {
        Button {
            turn(to: target.id, proxy: proxy)
        } label: {
            VStack(alignment: forward ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if !forward { AppIcon("ph-caret-left", size: 9) }
                    Text("CHAPTER \(target.numeral)")
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

    /// Fades the page out, swaps the chapter and puts the scroll back to
    /// the top unseen, then fades in — never a flash of the old chapter
    private func turn(to id: String, proxy: ScrollViewProxy) {
        withAnimation(.easeIn(duration: 0.14)) { pageOpacity = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            chapterID = id
            proxy.scrollTo("top", anchor: .top)
            withAnimation(.easeOut(duration: 0.24)) { pageOpacity = 1 }
            // A new chapter is a new page to VoiceOver too, as it was
            // when the turn pushed one: it starts again at the header
            AccessibilityNotification.ScreenChanged(nil).post()
        }
    }
}

#Preview {
    NavigationStack {
        PrayerBookChapterView(chapterID: "our_lady")
            .environment(AppRouter())
    }
}
