//
//  BookReadingProgress.swift
//  Lumen Viae
//
//  Where the reader stands in a Spiritual Reading book — one row per
//  book, created on the first chapter actually opened (never on
//  browsing), following TrueDevotionReadingProgress's shape.
//
//  A book can be held in two hands at once: read, and listened to. The
//  row keeps both places — the chapter and paragraph the eye left off
//  at, and the track and second the voice left off at — because they
//  are genuinely different places and a reader who listens in the car
//  and reads at night should lose neither.
//
//  A place marker, not a scoreboard. Nothing here is shown as a
//  percentage of a duty, and nothing is ever counted against the reader.
//

import Foundation
import SwiftData

// MARK: - BookPassageMark

/// One ribbon: the paragraph it lies on, addressed by the indices of the
/// current cutting of the edition.
struct BookPassageMark: Hashable {
    let chapter: Int
    let paragraph: Int
}

@Model
final class BookReadingProgress {

    /// The catalog id of the book this row marks
    var bookID: String

    // MARK: - The reading place

    /// Index of the chapter most recently opened
    var lastChapterIndex: Int

    /// Index of the paragraph last at the top of the screen in that
    /// chapter, so a chapter resumes where the eye left it rather than
    /// at its head. Same idea as TrueDevotionReadingProgress.
    var lastParagraphIndex: Int = 0

    /// Chapter indices read to the end, comma-separated — the storage
    /// pattern ConsecrationProgress and TrueDevotionReadingProgress both
    /// use. Feeds the contents ledger's quiet marks; never a score.
    var finishedChapterIndexesRaw: String = ""

    /// The reader's marks — a ribbon laid on a paragraph, several per
    /// chapter, collected book-wide. Stored as "chapter:paragraph" pairs,
    /// comma-separated, the same flat storage the finished set uses.
    ///
    /// A mark is a place, not a note: nothing is written, and nothing is
    /// counted. Like the reading place, a mark's indices only mean
    /// something within one cutting of the edition, so `retire` lets
    /// them go with it.
    var marksRaw: String = ""

    /// What that chapter is called, as the book itself names it —
    /// "Chapter IX", "Prologue", "Book X".
    ///
    /// Stored rather than derived because the surfaces that want to name
    /// a reader's place — the Me page's card above all — must not have to
    /// fetch and parse a whole book to draw one line. An index alone
    /// would have them counting: the Story of a Soul's tenth unit is
    /// Chapter IX, because a Prologue stands before it.
    var lastChapterTitle: String = ""

    /// When the reader last had this book open. Distinct from
    /// `updatedAt`, which any touch moves.
    var lastReadAt: Date?

    /// The edition this reading place was made against.
    ///
    /// A chapter index only means something for one cutting of one
    /// edition. Correcting a book's rules can move every index under a
    /// saved marker: the Story of a Soul gained a Prologue at index 0,
    /// so a marker saying 8 would open Chapter VIII where the reader
    /// left Chapter IX. When this no longer matches the catalog, the
    /// reading place is let go rather than silently pointing somewhere
    /// else. The listening place survives — it keys on the track's own
    /// id, which no reparse touches.
    var editionFingerprint: String = ""

    // MARK: - The listening place

    /// The LibriVox section id last handed to the player. Kept as the
    /// identity rather than the index alone: a recording's track list can
    /// come back re-cut, and a stale index would resume the wrong track
    /// silently where a stale id simply doesn't match.
    var lastTrackID: String = ""

    /// That track's position in the list — a hint, always checked
    /// against `lastTrackID` before it is trusted.
    var lastTrackIndex: Int = -1

    /// Seconds into that track
    var lastTrackSeconds: Double = 0

    /// The track's full length, so the book page can show how far in the
    /// voice left off without waiting for the player to load it
    var lastTrackDuration: Double = 0

    /// When the reader last listened
    var lastListenedAt: Date?

    var updatedAt: Date

    // MARK: - Derived

    var finishedChapterIndexes: Set<Int> {
        get {
            guard !finishedChapterIndexesRaw.isEmpty else { return [] }
            return Set(finishedChapterIndexesRaw.split(separator: ",").compactMap { Int($0) })
        }
        set {
            finishedChapterIndexesRaw = newValue.sorted().map(String.init).joined(separator: ",")
        }
    }

    func isChapterFinished(_ index: Int) -> Bool {
        finishedChapterIndexes.contains(index)
    }

    /// The marked paragraphs, in the order they were laid.
    var marks: [BookPassageMark] {
        get {
            guard !marksRaw.isEmpty else { return [] }
            return marksRaw.split(separator: ",").compactMap { pair in
                let parts = pair.split(separator: ":")
                guard parts.count == 2,
                      let chapter = Int(parts[0]),
                      let paragraph = Int(parts[1]) else { return nil }
                return BookPassageMark(chapter: chapter, paragraph: paragraph)
            }
        }
        set {
            marksRaw = newValue.map { "\($0.chapter):\($0.paragraph)" }
                .joined(separator: ",")
        }
    }

    /// Whether the reader has actually opened a chapter of this book.
    ///
    /// A row can exist without one: listening to a recording creates it
    /// too, and the chapter index it carries then is only the one the
    /// track happens to align with — a chapter nobody has read. Every
    /// surface that names a *reading* place asks this first, so the app
    /// never reports a place the reader has not been.
    var hasReadingPlace: Bool {
        lastReadAt != nil && lastChapterIndex >= 0
    }

    /// Whether a recording has ever been started for this book.
    var hasListeningPlace: Bool {
        !lastTrackID.isEmpty && lastTrackIndex >= 0
    }

    /// Whether the voice was left mid-track rather than at its head or
    /// its very end — the only case where resuming means anything.
    var hasResumableTrack: Bool {
        guard hasListeningPlace, lastTrackSeconds > 20 else { return false }
        guard lastTrackDuration > 0 else { return true }
        return lastTrackSeconds < lastTrackDuration - 20
    }

    // MARK: - Initialization

    init(
        bookID: String,
        lastChapterIndex: Int,
        lastParagraphIndex: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.bookID = bookID
        self.lastChapterIndex = lastChapterIndex
        self.lastParagraphIndex = lastParagraphIndex
        self.finishedChapterIndexesRaw = ""
        self.lastChapterTitle = ""
        self.lastTrackID = ""
        self.lastTrackIndex = -1
        self.lastTrackSeconds = 0
        self.lastTrackDuration = 0
        // Set by `recordReading`, not by construction: a row made by a
        // listening write has no reading place yet.
        self.lastReadAt = nil
        self.lastListenedAt = nil
        self.editionFingerprint = ""
        self.updatedAt = updatedAt
    }
}
