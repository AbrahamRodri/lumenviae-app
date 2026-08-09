//
//  TrueDevotionChapterReaderView.swift
//  Lumen Viae
//
//  The reading screen for one chapter of True Devotion. Tracks the
//  paragraph at the top of the screen so reading resumes exactly where
//  it left off, and marks the chapter read at the end.
//

import SwiftUI
import SwiftData

struct TrueDevotionChapterReaderView: View {

    let chapterID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSettings.self) private var settings

    /// Surfaced to the user rather than dropped — losing someone's place in
    /// a book they are praying through should never fail quietly.
    @State private var saveError: String?

    /// Paragraph id currently at the top of the screen (scroll tracking)
    @State private var topParagraphID: Int?

    /// True once the reader has actually been touched. SwiftUI builds the
    /// destination of a link on the contents screen before it is pushed,
    /// and that off-screen copy still reports scroll positions — without
    /// this gate it would silently record progress for a chapter the user
    /// never opened.
    @State private var hasInteracted = false

    /// True once the end of the chapter has been on screen. A chapter short
    /// enough to fit in one screenful is finished without any scrolling, so
    /// leaving via the toolbar still has to count as having read it.
    @State private var hasReachedEnd = false

    /// Sentinel id for the end-of-chapter block in the scroll layout
    private static let endBlockID = Int.max

    private var book: TrueDevotionBook? { TrueDevotionBookData.book }
    private var chapter: TrueDevotionChapter? { book?.chapter(id: chapterID) }

    private var readingFontSize: CGFloat { settings.meditationFontSize + 1 }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let chapter {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        chapterHeader(chapter)
                            .id(-1)

                        ForEach(chapter.paragraphs) { paragraph in
                            paragraphView(paragraph, isFirst: paragraph.id == chapter.firstTextParagraphID)
                                .id(paragraph.id)
                        }

                        endBlock(chapter)
                            .id(Self.endBlockID)
                            // Reading to the end is what marks the chapter
                            // read — no button press required.
                            .onAppear {
                                hasReachedEnd = true
                                if hasInteracted { finishChapter() }
                            }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .scrollPosition(id: $topParagraphID, anchor: .top)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { _ in hasInteracted = true }
                )
            } else {
                Text("Chapter unavailable.")
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasReachedEnd { finishChapter() }
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Contents")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        .onAppear(perform: restorePosition)
        .onChange(of: topParagraphID) { _, newValue in
            recordPosition(newValue)
        }
        .onDisappear(perform: save)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Progress

    /// Fetches the single reading-progress record straight from the context
    /// rather than from a @Query snapshot. Scroll callbacks fire faster than
    /// a @Query refreshes, so reading the snapshot would miss a record
    /// inserted moments earlier and insert a duplicate on every event.
    private func currentProgress() -> TrueDevotionReadingProgress? {
        var descriptor = FetchDescriptor<TrueDevotionReadingProgress>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func ensureProgress() -> TrueDevotionReadingProgress {
        if let existing = currentProgress() { return existing }
        let record = TrueDevotionReadingProgress()
        modelContext.insert(record)
        return record
    }

    private func restorePosition() {
        guard let progress = currentProgress(),
              progress.lastChapterID == chapterID,
              progress.lastParagraphIndex > 0,
              !progress.isChapterCompleted(chapterID) else { return }
        topParagraphID = progress.lastParagraphIndex
    }

    /// Remembers the paragraph at the top of the screen. Completion is not
    /// decided here: the end block is the last item, so it can never scroll
    /// up to the top and would never be reported.
    private func recordPosition(_ paragraphID: Int?) {
        guard hasInteracted, let paragraphID, paragraphID != Self.endBlockID else { return }
        // The header sits above the first paragraph and carries id -1;
        // reaching it means the reader is back at the start of the chapter.
        let index = max(paragraphID, 0)
        let progress = ensureProgress()
        guard !progress.isChapterCompleted(chapterID) else { return }
        progress.savePosition(chapterID: chapterID, paragraphIndex: index)
    }

    private func finishChapter() {
        let progress = ensureProgress()
        progress.markChapterCompleted(chapterID)
        progress.savePosition(chapterID: chapterID, paragraphIndex: 0)
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            saveError = "Your place in the book could not be saved. \(error.localizedDescription)"
        }
    }

    // MARK: - Header

    private func chapterHeader(_ chapter: TrueDevotionChapter) -> some View {
        VStack(spacing: 10) {
            if let partTitle = book?.parts.first(where: { $0.number == chapter.part })?.title {
                Text(partTitle.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Text(chapter.title)
                .font(AppFonts.headlineFont(23))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            Text("\(chapter.estimatedMinutes) min")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)

            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Paragraphs

    @ViewBuilder
    private func paragraphView(_ paragraph: TrueDevotionParagraph, isFirst: Bool) -> some View {
        switch paragraph.kind {
        case .subheading:
            Text(paragraph.text)
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.gold.opacity(0.9))
                .padding(.top, 10)

        case .text:
            if isFirst {
                DropCapText(text: paragraph.text, bodySize: readingFontSize)
            } else {
                Text(paragraph.text)
                    .font(AppFonts.readingFont(readingFontSize))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - End Block

    private func endBlock(_ chapter: TrueDevotionChapter) -> some View {
        VStack(spacing: 20) {
            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 16)

            if let next = book?.chapter(after: chapter.id) {
                NavigationLink {
                    TrueDevotionChapterReaderView(chapterID: next.id)
                } label: {
                    HStack(spacing: 10) {
                        Text("Next: \(next.title)")
                            .font(AppFonts.headlineFont(15))
                            .multilineTextAlignment(.leading)

                        AppIcon("ph-caret-right", size: 14)
                    }
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .goldCTABackground()
                }
                // Moving on covers the short chapters a reader finishes
                // without ever needing to scroll.
                .simultaneousGesture(TapGesture().onEnded { finishChapter() })
            } else {
                VStack(spacing: 10) {
                    Text("Finis")
                        .font(AppFonts.italicFont(18))
                        .foregroundColor(AppColors.gold)

                    Text("You have read the whole of True Devotion. Totus tuus.")
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        finishChapter()
                        dismiss()
                    } label: {
                        Text("Back to Contents")
                            .font(AppFonts.headlineFont(15))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .goldCTABackground()
                    }
                    .buttonStyle(GoldCTAButtonStyle())
                    .padding(.top, 8)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrueDevotionChapterReaderView(chapterID: "introduction")
    }
    .environment(UserSettings.shared)
    .modelContainer(for: [TrueDevotionReadingProgress.self])
}
