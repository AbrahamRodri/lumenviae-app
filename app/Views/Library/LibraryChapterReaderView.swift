//
//  LibraryChapterReaderView.swift
//  Lumen Viae
//
//  One chapter of a Spiritual Reading book, set the way the app sets
//  all its long-form text: ReadingText with a drop cap, sized by the
//  user's text setting. The foot steps to the neighboring chapters in
//  place — walking a 114-chapter book must not stack 114 screens.
//
//  Opening a chapter records the place marker that powers the book
//  page's Continue card. Recorded from .task and on in-place steps —
//  real arrivals — never from view construction, which SwiftUI performs
//  eagerly for destinations that are never pushed.
//

import SwiftUI
import SwiftData

struct LibraryChapterReaderView: View {

    let bookID: String
    let chapterIndex: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSettings.self) private var settings

    @State private var book: LibraryBook?
    @State private var loadFailed = false

    /// Why the chapter didn't open — see LibraryError: only one of the
    /// two reasons is worth offering a second attempt.
    @State private var failure: LibraryError = .unreachable

    /// The chapter on screen — starts at the pushed index, then steps
    /// in place through the foot's prev/next.
    @State private var currentIndex: Int

    init(bookID: String, chapterIndex: Int) {
        self.bookID = bookID
        self.chapterIndex = chapterIndex
        self._currentIndex = State(initialValue: chapterIndex)
    }

    private var info: LibraryBookInfo? { LibraryCatalog.book(id: bookID) }
    private var chapter: LibraryChapter? { book?.chapter(at: currentIndex) }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let chapter {
                reader(chapter)
            } else if loadFailed {
                unavailable
            } else {
                ProgressView()
                    .tint(AppColors.gold)
            }
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
        .task {
            await load()
            recordPlace()
        }
    }

    // MARK: - Reader

    private func reader(_ chapter: LibraryChapter) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 1).id("chapterTop")

                    chapterHeader(chapter)
                        .padding(.bottom, 24)

                    // Paragraphs straight from the parser: a chapter of
                    // the Confessions runs past 80,000 characters, and
                    // joining it into one string only for ReadingText to
                    // split it again would redo that on every pass.
                    ReadingText(
                        paragraphs: chapter.paragraphs,
                        size: settings.meditationFontSize + 1,
                        showsDropCap: true,
                        isLazy: true
                    )

                    footNavigation
                        .padding(.top, 36)
                        .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .onChange(of: currentIndex) {
                proxy.scrollTo("chapterTop", anchor: .top)
                recordPlace()
            }
        }
    }

    private func chapterHeader(_ chapter: LibraryChapter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kicker(for: chapter).uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(chapter.title ?? chapter.heading)
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)

            OrnamentDivider(showsCross: false)
                .frame(width: 140)
                .padding(.top, 8)
        }
    }

    /// "The First Book · Chapter II", or just the heading where the
    /// book has no parts
    private func kicker(for chapter: LibraryChapter) -> String {
        if let part = chapter.part {
            return "\(part) · \(chapter.heading)"
        }
        if chapter.title != nil {
            return chapter.heading
        }
        return info?.title ?? chapter.heading
    }

    // MARK: - Foot

    /// The way on: previous and next chapter, stepped in place.
    @ViewBuilder
    private var footNavigation: some View {
        if let book {
            HStack {
                if currentIndex > 0, let previous = book.chapter(at: currentIndex - 1) {
                    footButton(
                        label: previous.heading,
                        icon: "ph-caret-left",
                        iconLeads: true
                    ) {
                        currentIndex -= 1
                    }
                }

                Spacer()

                if let next = book.chapter(at: currentIndex + 1) {
                    footButton(
                        label: next.heading,
                        icon: "ph-caret-right",
                        iconLeads: false
                    ) {
                        currentIndex += 1
                    }
                }
            }
        }
    }

    private func footButton(
        label: String,
        icon: String,
        iconLeads: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if iconLeads { AppIcon(icon, size: 11) }
                Text(label.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(1.5)
                if !iconLeads { AppIcon(icon, size: 11) }
            }
            .foregroundColor(AppColors.gold)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - States

    private var unavailable: some View {
        VStack(spacing: 12) {
            Text(failure.title)
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.cream)

            Text(failure.detail)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // The book page offers this; the reader used to strand the
            // reader on static text with only Back.
            if failure.isRetryable {
                QuietGoldButton(
                    title: "Try again",
                    size: 11,
                    color: AppColors.gold
                ) {
                    loadFailed = false
                    Task {
                        await load()
                        recordPlace()
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Loading & progress

    private func load() async {
        guard let info else {
            // A route carrying an id the catalog no longer holds: say so
            // rather than spinning on a book that cannot arrive.
            failure = .unreadable
            loadFailed = true
            return
        }
        guard book == nil else { return }
        do {
            let loaded = try await LibraryService.shared.book(for: info)
            // A stale place marker, or a route restored after a reparse
            // cut the book differently, can name a chapter this edition
            // no longer has. Clamp into range rather than leave the page
            // with no chapter, no error, and a spinner that never ends.
            if loaded.chapter(at: currentIndex) == nil, !loaded.chapters.isEmpty {
                currentIndex = min(max(currentIndex, 0), loaded.chapters.count - 1)
            }
            book = loaded
            loadFailed = false
        } catch let error as LibraryError {
            failure = error
            loadFailed = true
        } catch {
            failure = .unreachable
            loadFailed = true
        }
    }

    /// Upserts the book's one place-marker row.
    private func recordPlace() {
        guard book != nil else { return }
        let id = bookID
        let descriptor = FetchDescriptor<BookReadingProgress>(
            predicate: #Predicate { $0.bookID == id }
        )
        if let row = try? modelContext.fetch(descriptor).first {
            row.lastChapterIndex = currentIndex
            row.updatedAt = Date()
        } else {
            modelContext.insert(
                BookReadingProgress(bookID: bookID, lastChapterIndex: currentIndex)
            )
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryChapterReaderView(bookID: "imitation-of-christ", chapterIndex: 0)
            .environment(UserSettings.shared)
    }
}
