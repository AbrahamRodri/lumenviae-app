//
//  ReadingShelfSection.swift
//  Lumen Viae
//
//  The reading shelf as the home page wears it: the books standing in a
//  row, each spine a door, with a ribbon over any the reader has under
//  way.
//
//  The same shelf stands on Explore, but this is not that view moved —
//  Explore is a place to browse, and gives the covers room. Home is a
//  page you pass through on the way to praying, so the covers are set
//  smaller and the section takes the header the mysteries and the rest
//  of the page already use: a name in Cinzel with one quiet gold way
//  through to the whole shelf.
//

import SwiftUI
import SwiftData

struct ReadingShelfSection: View {

    @Environment(AppRouter.self) private var router

    /// Which books have a reading under way, so their cover can wear the
    /// marker ribbon. Sorted by the query, but only membership matters
    /// here — the row keeps the shelf's own order so a book never moves
    /// out from under the reader's thumb between visits.
    @Query private var progress: [BookReadingProgress]

    private var underWay: Set<String> {
        // Written out rather than as a key path: `filter` here is
        // ambiguous with SwiftData's Predicate overload.
        var ids: Set<String> = []
        for row in progress where row.hasReadingPlace || row.hasListeningPlace {
            ids.insert(row.bookID)
        }
        return ids
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            shelf
        }
    }

    // MARK: - Header

    /// The page's own section idiom — the same one Sacred Mysteries
    /// uses, so the reading shelf reads as part of the page rather than
    /// as something borrowed from another screen.
    private var header: some View {
        HStack {
            Text("Spiritual Reading")
                .font(AppFonts.headlineFont(19))
                .foregroundColor(AppColors.goldLight)

            Spacer()

            Button(action: { router.push(.spiritualReading) }) {
                HStack(spacing: 5) {
                    Text("THE SHELF")
                        .font(AppFonts.labelFont(10))
                        .tracking(1.5)
                    AppIcon("ph-caret-right", size: 9)
                }
                .foregroundColor(AppColors.gold)
                .padding(.vertical, 8)
                .padding(.leading, 16)
            }
            .accessibilityLabel("Open the Spiritual Reading shelf")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - The books

    /// True Devotion stands among them, because it is one of them. Its
    /// cover opens its book, not the page about it.
    private var shelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                cover(LibraryCatalog.trueDevotionDisplay) {
                    router.push(.trueDevotionBook)
                }

                ForEach(LibraryCatalog.books) { book in
                    cover(book, hasRibbon: underWay.contains(book.id)) {
                        router.push(.libraryBook(id: book.id))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    private func cover(
        _ info: LibraryBookInfo,
        hasRibbon: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            // 106, the width Explore uses. Narrower and the gilt
            // lettering breaks mid-word — "THE IMITATI / ON OF…" — which
            // no binder would set and no reader should have to read.
            BookCover(info: info, hasRibbon: hasRibbon)
                .frame(width: 106)
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(
            "\(info.title), \(info.author)\(hasRibbon ? ". Reading under way." : "")"
        )
    }
}
