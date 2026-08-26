//
//  LibraryProgressStore.swift
//  Lumen Viae
//
//  Every read and write of a Spiritual Reading place marker, in one
//  place. The shelf, the book page, the reader, the player, and the Me
//  page all touch the same row, and having each of them hand-roll its
//  own FetchDescriptor is how the two places drift apart.
//
//  Writing policy matters here. The reading place moves when a chapter
//  is opened or scrolled — rarely, so it is written straight through.
//  The listening place moves twice a second, so it is held in memory
//  and committed on a slow clock and at the moments that actually
//  matter: pausing, changing track, leaving the page, backgrounding the
//  app. A place marker is not worth a SwiftData write every 500ms, and a
//  reader who force-quits mid-chapter loses at most a few seconds.
//

import Foundation
import SwiftData

@MainActor
enum LibraryProgressStore {

    // MARK: - Reading

    /// The row for one book, or nil if it has never been opened.
    static func row(for bookID: String, in context: ModelContext) -> BookReadingProgress? {
        let id = bookID
        let descriptor = FetchDescriptor<BookReadingProgress>(
            predicate: #Predicate { $0.bookID == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Every book with a place marker, most recently touched first —
    /// what the Me page's Reading card draws on.
    static func all(in context: ModelContext) -> [BookReadingProgress] {
        let descriptor = FetchDescriptor<BookReadingProgress>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Records where the eye is. Called on a real chapter opening and on
    /// in-place steps — never from view construction, which SwiftUI
    /// performs eagerly for destinations that are never pushed.
    @discardableResult
    static func recordReading(
        bookID: String,
        chapterIndex: Int,
        chapterTitle: String = "",
        paragraphIndex: Int = 0,
        in context: ModelContext
    ) -> BookReadingProgress {
        let row = upsert(bookID: bookID, chapterIndex: chapterIndex, in: context)
        row.lastChapterIndex = chapterIndex
        row.lastParagraphIndex = max(0, paragraphIndex)
        // This, and only this, is what opens a reading place.
        row.lastReadAt = Date()
        if !chapterTitle.isEmpty { row.lastChapterTitle = chapterTitle }
        row.lastReadAt = Date()
        row.updatedAt = Date()
        save(context)
        return row
    }

    /// Moves only the paragraph within the chapter already recorded —
    /// what a scroll reports. Silently ignored if the reader has since
    /// moved to another chapter.
    static func recordParagraph(
        bookID: String,
        chapterIndex: Int,
        paragraphIndex: Int,
        in context: ModelContext
    ) {
        guard let row = row(for: bookID, in: context),
              row.lastChapterIndex == chapterIndex,
              row.lastParagraphIndex != paragraphIndex else { return }
        row.lastParagraphIndex = max(0, paragraphIndex)
        row.lastReadAt = Date()
        row.updatedAt = Date()
        save(context)
    }

    /// Marks a chapter read to the end. Additive only — a chapter is
    /// never un-finished, and nothing counts what is missing.
    static func markFinished(
        bookID: String,
        chapterIndex: Int,
        in context: ModelContext
    ) {
        let row = upsert(bookID: bookID, chapterIndex: chapterIndex, in: context)
        guard !row.isChapterFinished(chapterIndex) else { return }
        row.finishedChapterIndexes.insert(chapterIndex)
        row.updatedAt = Date()
        save(context)
    }

    // MARK: - Marks

    /// The ribbons laid in one book, if its row still belongs to the
    /// edition the catalog cuts today.
    static func marks(for bookID: String, in context: ModelContext) -> [BookPassageMark] {
        guard let row = row(for: bookID, in: context) else { return [] }
        let fingerprint = LibraryCatalog.book(id: bookID)?.editionFingerprint ?? ""
        guard fingerprint.isEmpty || row.editionFingerprint == fingerprint else { return [] }
        return row.marks
    }

    /// Lays a ribbon on a paragraph, or lifts the one already there.
    /// Returns whether the paragraph is marked afterwards.
    @discardableResult
    static func toggleMark(
        bookID: String,
        chapter: Int,
        paragraph: Int,
        in context: ModelContext
    ) -> Bool {
        let row = upsert(bookID: bookID, chapterIndex: chapter, in: context)
        let mark = BookPassageMark(chapter: chapter, paragraph: paragraph)
        var marks = row.marks
        let nowMarked: Bool
        if let index = marks.firstIndex(of: mark) {
            marks.remove(at: index)
            nowMarked = false
        } else {
            marks.append(mark)
            nowMarked = true
        }
        row.marks = marks
        row.updatedAt = Date()
        save(context)
        return nowMarked
    }

    // MARK: - Listening

    /// Records where the voice is, at most every `commitInterval`
    /// seconds unless `force` — pausing, changing track, leaving.
    static func recordListening(
        bookID: String,
        chapterIndex: Int,
        trackID: String,
        trackIndex: Int,
        seconds: Double,
        duration: Double,
        force: Bool = false,
        in context: ModelContext
    ) {
        guard seconds.isFinite, seconds >= 0 else { return }
        guard force || Date().timeIntervalSince(lastCommit) >= commitInterval else { return }
        lastCommit = Date()

        // A listening write never claims a chapter: the index it has is
        // whichever chapter the track aligns with, not one the reader
        // opened. `-1` on a fresh row leaves `hasReadingPlace` false.
        let row = upsert(bookID: bookID, chapterIndex: -1, in: context)
        row.lastTrackID = trackID
        row.lastTrackIndex = trackIndex
        row.lastTrackSeconds = seconds
        row.lastTrackDuration = duration.isFinite && duration > 0 ? duration : 0
        row.lastListenedAt = Date()
        row.updatedAt = Date()
        save(context)
    }

    /// How often a running recording commits its position.
    private static let commitInterval: TimeInterval = 5

    private static var lastCommit: Date = .distantPast

    /// Lets the next `recordListening` through whatever the clock says —
    /// used when a track changes, so the new track's opening position
    /// isn't swallowed by the throttle.
    static func allowImmediateListeningWrite() {
        lastCommit = .distantPast
    }

    // MARK: - Plumbing

    /// The row, made if this is the book's first opening, and with any
    /// reading place from a superseded cutting of the edition let go.
    private static func upsert(
        bookID: String,
        chapterIndex: Int,
        in context: ModelContext
    ) -> BookReadingProgress {
        let fingerprint = LibraryCatalog.book(id: bookID)?.editionFingerprint ?? ""

        if let existing = row(for: bookID, in: context) {
            retire(existing, unless: fingerprint)
            return existing
        }
        let created = BookReadingProgress(bookID: bookID, lastChapterIndex: chapterIndex)
        created.editionFingerprint = fingerprint
        context.insert(created)
        return created
    }

    /// Lets go of a reading place made against a different cutting of the
    /// book. Chapter and paragraph indices are meaningful only within one
    /// parse; the listening place is kept, because a track id survives
    /// any reparse.
    ///
    /// A row written before this field existed carries an empty
    /// fingerprint, which means it was made against the cutting that
    /// came before — and those indices really did move: the Story of a
    /// Soul gained a Prologue at index 0 and the Dolorous Passion gained
    /// eleven units at its head. So an empty fingerprint is let go too.
    /// Losing a marker on a shelf this young costs the reader a moment;
    /// opening eleven chapters from where they stopped looks broken.
    private static func retire(_ row: BookReadingProgress, unless fingerprint: String) {
        guard !fingerprint.isEmpty else { return }
        guard row.editionFingerprint != fingerprint else { return }
        row.editionFingerprint = fingerprint
        row.lastChapterIndex = -1
        row.lastParagraphIndex = 0
        row.lastChapterTitle = ""
        row.lastReadAt = nil
        row.finishedChapterIndexesRaw = ""
        // A mark's indices belonged to the old cutting too.
        row.marksRaw = ""
    }

    /// Whether a book's stored reading place still belongs to the edition
    /// the catalog cuts today. Read before trusting a marker on a surface
    /// that never writes one — the Me page's card, the shelf's ribbons.
    static func isCurrent(_ row: BookReadingProgress) -> Bool {
        guard row.hasReadingPlace else { return false }
        guard let fingerprint = LibraryCatalog.book(id: row.bookID)?.editionFingerprint
        else { return false }
        return row.editionFingerprint == fingerprint
    }

    private static func save(_ context: ModelContext) {
        try? context.save()
    }
}
