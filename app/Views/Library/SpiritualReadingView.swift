//
//  SpiritualReadingView.swift
//  Lumen Viae
//
//  The Spiritual Reading shelf: a small curated case of public-domain
//  classics, fetched from Project Gutenberg the first time a book is
//  opened and read alongside LibriVox recordings. The shelf itself is
//  instant — only opening a book touches the network.
//

import SwiftUI
import SwiftData

struct SpiritualReadingView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    /// Which books have a reading under way — their covers wear the
    /// marker ribbon.
    @Query private var progress: [BookReadingProgress]

    private var readingIDs: Set<String> {
        Set(progress.map(\.bookID))
    }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .devotionalEntrance()

                    // The case itself: two columns of bound books, each
                    // in its own cloth — a shelf, not a ledger.
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 18),
                            GridItem(.flexible(), spacing: 18)
                        ],
                        spacing: 22
                    ) {
                        ForEach(Array(LibraryCatalog.books.enumerated()), id: \.element.id) { index, book in
                            bookCoverButton(book)
                                .devotionalEntrance(delay: 0.08 + Double(index) * 0.06)
                        }
                    }
                    .padding(.horizontal, 28)

                    credit
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                        .devotionalEntrance(delay: 0.3)
                }
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            AppIcon("ph-book-open", size: 36)
                .foregroundColor(AppColors.gold)
                .breathingGlow(AppColors.gold)
                .padding(.top, 24)

            Text("Spiritual Reading")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            // The words that converted Augustine — the shelf's whole
            // invitation in three of them.
            Text("Tolle, lege — take up and read")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.gold.opacity(0.8))

            OrnamentDivider()
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Shelf

    private func bookCoverButton(_ book: LibraryBookInfo) -> some View {
        Button {
            router.push(.libraryBook(id: book.id))
        } label: {
            BookCover(info: book, hasRibbon: readingIDs.contains(book.id))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(SacredCardButtonStyle())
        // The cover carries only title and author; the blurb still
        // belongs to the spoken label — it is what tells the books apart
        // before one is opened.
        .accessibilityLabel("\(book.title), \(authorLine(book)). \(book.blurb)\(readingIDs.contains(book.id) ? " Reading under way." : "")")
    }

    private func authorLine(_ book: LibraryBookInfo) -> String {
        if let translator = book.translator {
            return "\(book.author) · translated by \(translator)"
        }
        return book.author
    }

    // MARK: - Credit

    /// The shelf names its sources the way the Office names Divinum
    /// Officium — this work is other people's gift.
    private var credit: some View {
        Text("Texts from Project Gutenberg. Recordings by LibriVox volunteers. All in the public domain.")
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary.opacity(0.8))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SpiritualReadingView()
            .environment(AppRouter())
    }
}
