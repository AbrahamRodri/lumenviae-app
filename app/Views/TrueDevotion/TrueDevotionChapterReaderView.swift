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
    @Query private var progressRecords: [TrueDevotionReadingProgress]

    /// Paragraph id currently at the top of the screen (scroll tracking)
    @State private var topParagraphID: Int?

    /// True once the reader has actually been touched. SwiftUI builds the
    /// destination of a link on the contents screen before it is pushed,
    /// and that off-screen copy still reports scroll positions — without
    /// this gate it would silently record progress for a chapter the user
    /// never opened.
    @State private var hasInteracted = false

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
                            paragraphView(paragraph, isFirst: paragraph.id == firstTextParagraphID(chapter))
                                .id(paragraph.id)
                        }

                        endBlock(chapter)
                            .id(Self.endBlockID)
                            // Reading to the end is what marks the chapter
                            // read — no button press required.
                            .onAppear {
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
                Button(action: { dismiss() }) {
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
        .onDisappear {
            try? modelContext.save()
        }
    }

    // MARK: - Progress

    /// The single reading-progress record, created on first use
    private func ensureProgress() -> TrueDevotionReadingProgress {
        if let existing = progressRecords.first { return existing }
        let record = TrueDevotionReadingProgress()
        modelContext.insert(record)
        return record
    }

    private func restorePosition() {
        guard let progress = progressRecords.first,
              progress.lastChapterID == chapterID,
              progress.lastParagraphIndex > 0,
              !progress.isChapterCompleted(chapterID) else { return }
        topParagraphID = progress.lastParagraphIndex
    }

    /// Remembers the paragraph at the top of the screen. Completion is not
    /// decided here: the end block is the last item, so it can never scroll
    /// up to the top and would never be reported.
    private func recordPosition(_ paragraphID: Int?) {
        guard hasInteracted else { return }
        guard let paragraphID, paragraphID >= 0, paragraphID != Self.endBlockID else { return }
        let progress = ensureProgress()
        guard !progress.isChapterCompleted(chapterID) else { return }
        progress.savePosition(chapterID: chapterID, paragraphIndex: paragraphID)
    }

    private func finishChapter() {
        let progress = ensureProgress()
        progress.markChapterCompleted(chapterID)
        progress.savePosition(chapterID: chapterID, paragraphIndex: 0)
        try? modelContext.save()
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

    private func firstTextParagraphID(_ chapter: TrueDevotionChapter) -> Int? {
        chapter.paragraphs.first { $0.kind == .text }?.id
    }

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
                    .background(
                        LinearGradient(
                            colors: [AppColors.gold, AppColors.goldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
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
                            .background(
                                LinearGradient(
                                    colors: [AppColors.gold, AppColors.goldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
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
