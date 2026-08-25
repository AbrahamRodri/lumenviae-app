//
//  LibraryBook.swift
//  Lumen Viae
//
//  The Spiritual Reading shelf: public-domain classics fetched live
//  from Project Gutenberg when a book is opened (never bundled), cut
//  into chapters on device, and cached to disk like the missal. A
//  LibriVox recording, when a good one exists, streams beside the text.
//
//  `LibraryBookInfo` is the curated catalog entry — identity, where to
//  fetch, and the cutting rules for that edition's text. The catalog
//  itself lives in Data/LibraryCatalog.swift.
//

import Foundation

// MARK: - LibraryBookInfo

/// One book on the shelf: what it is, where its text and recording
/// live, and how its Gutenberg edition is cut into chapters.
///
/// `nonisolated` like its siblings below: the parse and the disk writes
/// run off the main actor, and a catalog entry is read there.
nonisolated struct LibraryBookInfo: Identifiable, Hashable {

    /// Stable slug — cache filenames and reading progress key on it
    let id: String

    let title: String

    let author: String

    /// Named where known; a translation is a voice, and the voice is
    /// part of what the shelf offers
    var translator: String? = nil

    /// One shelf sentence: why this book, in the app's own voice
    let blurb: String

    /// Project Gutenberg ebook number — the text source
    let gutenbergID: Int

    /// LibriVox audiobook id, when a complete recording exists
    var librivoxID: Int? = nil

    /// How this edition's plain text is cut into chapters
    let parsing: LibraryParsingRules

    /// The Gutenberg plain-text URL for this edition
    var textURL: URL {
        URL(string: "https://www.gutenberg.org/cache/epub/\(gutenbergID)/pg\(gutenbergID).txt")!
    }

    /// Everything that decides what the parsed book looks like, in eight
    /// hex digits — the edition and the rules that cut it. It rides in
    /// the cache filename, so correcting one book's `chapterPattern` or
    /// swapping its `gutenbergID` retires that book's cached parse and
    /// leaves the rest of the shelf alone.
    ///
    /// Hand-rolled FNV-1a rather than `hashValue`: Swift's hashing is
    /// seeded per process, so a stored key built from it would miss on
    /// every launch.
    var editionFingerprint: String {
        var hash: UInt32 = 2_166_136_261
        let seed = [
            String(gutenbergID),
            parsing.chapterPattern,
            parsing.partPattern ?? "",
            parsing.stopPattern ?? "",
            String(parsing.minimumChapterLength)
        ].joined(separator: "\u{1}")

        for byte in seed.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return String(format: "%08x", hash)
    }
}

// MARK: - LibraryParsingRules

/// Per-edition cutting rules for `LibraryBookParser`. Each pattern is
/// a regular expression matched against one whole trimmed line.
nonisolated struct LibraryParsingRules: Hashable {

    /// A line that begins a chapter (the shelf's reading unit)
    let chapterPattern: String

    /// A line that begins a part — kept as a section header over the
    /// chapters that follow it in the contents
    var partPattern: String? = nil

    /// A line at which the book is done — appendices, letter
    /// collections, and editorial tails end here
    var stopPattern: String? = nil

    /// A heading whose body runs shorter than this is not a chapter —
    /// it is the table of contents naming one. 500 characters rejects
    /// every contents line without touching any real chapter.
    var minimumChapterLength: Int = 500
}

// MARK: - LibraryBook (parsed)

/// A book cut into chapters — the shape the cache stores and the
/// reader reads. Decoded off the main actor, hence `nonisolated`.
nonisolated struct LibraryBook: Codable, Hashable {

    let bookID: String

    let chapters: [LibraryChapter]

    func chapter(at index: Int) -> LibraryChapter? {
        chapters.indices.contains(index) ? chapters[index] : nil
    }
}

/// One reading unit: "Chapter I — Of the Imitation of Christ".
nonisolated struct LibraryChapter: Codable, Hashable, Identifiable {

    /// Index within the book, stable because the parse is deterministic
    let id: Int

    /// The part header standing over this chapter, e.g. "The First
    /// Book" — nil for books without parts
    let part: String?

    /// The unit's own label, e.g. "Chapter I" or "Book IV"
    let heading: String

    /// The chapter's given title, when the edition prints one
    let title: String?

    let paragraphs: [String]

    /// What the contents ledger calls it
    var displayTitle: String { title ?? heading }
}

// MARK: - LibriVox

/// The `/api/feed/audiobooks` envelope. LibriVox serializes nearly
/// everything as strings; the models keep them and convert at the edge.
nonisolated struct LibriVoxResponse: Codable {
    let books: [LibriVoxAudiobook]
}

nonisolated struct LibriVoxAudiobook: Codable {
    let id: String
    let title: String
    let totaltime: String?
    let sections: [LibriVoxSection]?
}

/// One recorded track of a LibriVox audiobook
nonisolated struct LibriVoxSection: Codable, Identifiable, Hashable {
    let id: String
    let sectionNumber: String?
    let title: String?
    let listenURL: String?
    let playtime: String?

    enum CodingKeys: String, CodingKey {
        case id, title, playtime
        case sectionNumber = "section_number"
        case listenURL = "listen_url"
    }

    /// "54 min" / "1 hr 12 min" from the API's seconds-as-string
    var playtimeLabel: String? {
        guard let playtime, let seconds = Int(playtime), seconds > 0 else { return nil }
        let minutes = max(seconds / 60, 1)
        if minutes >= 60 {
            return "\(minutes / 60) hr \(minutes % 60) min"
        }
        return "\(minutes) min"
    }
}
