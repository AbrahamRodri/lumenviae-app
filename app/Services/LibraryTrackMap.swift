//
//  LibraryTrackMap.swift
//  Lumen Viae
//
//  Ties a LibriVox recording to the chapters cut from the text, so a
//  reader can hand a chapter to the voice and hand it back again
//  without losing their place.
//
//  Nothing here is guesswork dressed as certainty. The alignment is
//  computed from what the recording actually says its tracks are — the
//  track titles — against what the parser actually produced, and a
//  chapter with no track simply has none. A book whose recording cannot
//  be aligned (`.none`) still plays; it just never claims to know which
//  chapter is sounding.
//

import Foundation

// MARK: - Numerals

/// Roman, arabic, and written-out numbers, read out of the strings both
/// sources use — "Chapter XI", "Book 3", "The First Book".
nonisolated enum LibraryNumerals {

    /// The first number in a string, in whichever form it is written.
    /// "Chapter XI" → 11, "Book 3 - Chapters 1-10" → 3, "The First
    /// Book" → 1.
    static func number(in text: String) -> Int? {
        for token in tokens(of: text) {
            if let value = numeral(token) { return value }
        }
        return nil
    }

    /// The number that follows the word "Book" — not merely the first
    /// number in the line. "Book Four, Chapters 1-10" names book four;
    /// read loosely it names chapter one. Track titles are written by
    /// volunteers and put the two numbers side by side, so the anchor
    /// matters: this is the difference between opening Book IV and
    /// playing Book I over it.
    static func bookNumber(in text: String) -> Int? {
        let tokens = tokens(of: text)
        for (index, token) in tokens.enumerated()
        where token.lowercased().hasPrefix("book") && index + 1 < tokens.count {
            if let value = numeral(tokens[index + 1]) { return value }
        }
        return nil
    }

    /// One token as a number, however it is written: "3", "III",
    /// "Third", "Three". LibriVox's readers use all four across one
    /// shelf, and the text's own headings use a fifth wording again.
    static func numeral(_ token: String) -> Int? {
        if let arabic = Int(token) { return arabic }
        if let roman = roman(token) { return roman }
        return ordinalWord(token)
    }

    /// Roman numerals as the two sources print them — uppercase, with
    /// an optional trailing period. Deliberately strict: a lowercase
    /// "i" is the English word, and "MIX" is a title.
    static func roman(_ token: String) -> Int? {
        let cleaned = token.trimmingCharacters(in: CharacterSet(charactersIn: ".,:;"))
        guard !cleaned.isEmpty, cleaned == cleaned.uppercased() else { return nil }

        let values: [Character: Int] = [
            "I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000
        ]
        var total = 0
        var previous = 0
        for character in cleaned.reversed() {
            guard let value = values[character] else { return nil }
            if value < previous {
                total -= value
            } else {
                total += value
                previous = value
            }
        }
        return total > 0 ? total : nil
    }

    /// "First" → 1 and "One" → 1, through the thirteen books of the
    /// Confessions — the text says "THE FIRST BOOK", the recording says
    /// "Book One", and both have to be read.
    static func ordinalWord(_ token: String) -> Int? {
        let key = token
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;"))
            .lowercased()
        return Self.written[key]
    }

    private static let written: [String: Int] = [
        "first": 1, "second": 2, "third": 3, "fourth": 4, "fifth": 5,
        "sixth": 6, "seventh": 7, "eighth": 8, "ninth": 9, "tenth": 10,
        "eleventh": 11, "twelfth": 12, "thirteenth": 13,
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13
    ]

    /// Words and numerals, with punctuation that isn't part of a numeral
    /// stripped off the ends.
    private static func tokens(of text: String) -> [String] {
        text.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }
}

// MARK: - LibraryTrackAlignment

/// Which track reads which chapter, both ways round. Built once when a
/// book's text and track list have both arrived.
nonisolated struct LibraryTrackAlignment: Equatable {

    /// Track index for each chapter index, `nil` where no track reads it
    private let chapterToTrack: [Int?]

    /// The chapters one track reads. A 1:1 recording gives ranges of
    /// one; the Imitation's reader gathered ten chapters to a file.
    private let trackToChapters: [Int: ClosedRange<Int>]

    /// Tracks that read exactly one chapter and the whole of it. Only
    /// these can carry the page along with the voice — over a track
    /// holding ten chapters, or a chapter split across five tracks,
    /// there is nothing honest to follow it with.
    private let wholeChapterTracks: Set<Int>

    static let empty = LibraryTrackAlignment(chapterToTrack: [], trackToChapters: [:])

    init(chapterToTrack: [Int?], trackToChapters: [Int: ClosedRange<Int>]) {
        self.chapterToTrack = chapterToTrack
        self.trackToChapters = trackToChapters

        // A track reads a whole chapter when it holds exactly one and
        // no other track holds that same one.
        var tracksPerChapter: [Int: Int] = [:]
        for range in trackToChapters.values where range.count == 1 {
            tracksPerChapter[range.lowerBound, default: 0] += 1
        }
        var whole: Set<Int> = []
        for (track, range) in trackToChapters where range.count == 1 {
            if tracksPerChapter[range.lowerBound] == 1 { whole.insert(track) }
        }
        wholeChapterTracks = whole
    }

    /// Whether any chapter at all can be tied to a track.
    var isEmpty: Bool { trackToChapters.isEmpty }

    /// The track that reads this chapter.
    func track(forChapter index: Int) -> Int? {
        guard chapterToTrack.indices.contains(index) else { return nil }
        return chapterToTrack[index]
    }

    /// The chapters this track reads.
    func chapters(forTrack index: Int) -> ClosedRange<Int>? {
        trackToChapters[index]
    }

    /// The chapter a track opens with — where "read along with this
    /// track" should put the page.
    func firstChapter(forTrack index: Int) -> Int? {
        trackToChapters[index]?.lowerBound
    }

    /// Whether this track reads one whole chapter — the only case where
    /// the page can keep pace with the voice.
    func readsWholeChapter(track index: Int) -> Bool {
        wholeChapterTracks.contains(index)
    }
}

// MARK: - LibraryTrackMap

nonisolated enum LibraryTrackMap {

    /// Aligns a parsed book against a fetched track list.
    static func align(
        chapters: [LibraryChapter],
        sections: [LibriVoxSection],
        mapping: LibraryTrackMapping
    ) -> LibraryTrackAlignment {
        guard !chapters.isEmpty, !sections.isEmpty else { return .empty }

        let aligned: LibraryTrackAlignment
        switch mapping {
        case .none:
            return .empty
        case .sequential(let offset):
            aligned = sequential(chapters: chapters, sections: sections, offset: offset)
        case .bookChapterRanges:
            aligned = bookChapterRanges(chapters: chapters, sections: sections)
        case .bookSpans:
            aligned = bookSpans(chapters: chapters, sections: sections)
        }

        // A book that names a mapping should leave nothing unmapped. The
        // alignment is derived from a volunteer's track titles, which can
        // be re-edited at any time — so when one drifts, say so here
        // rather than letting a reader ask to hear a chapter and be given
        // a different one.
        #if DEBUG
        let unmapped = chapters.indices.filter { aligned.track(forChapter: $0) == nil }
        if let firstUnmapped = unmapped.first {
            print("LibraryTrackMap: \(unmapped.count) of \(chapters.count) chapters have no track. First: \(chapters[firstUnmapped].heading)")
        }
        #endif
        return aligned
    }

    // MARK: Book spans

    /// One reading unit, several tracks. The unit's heading carries its
    /// number ("Book X" → 10) and each track title names the book it
    /// reads ("Book Ten, Chapters 21-30"); the unit opens at the first
    /// track of its book and the rest run on after it.
    private static func bookSpans(
        chapters: [LibraryChapter],
        sections: [LibriVoxSection]
    ) -> LibraryTrackAlignment {
        var firstTrack: [Int: Int] = [:]
        var bookOfTrack: [Int: Int] = [:]

        for (index, section) in sections.enumerated() {
            guard let title = section.title else { continue }
            guard let book = LibraryNumerals.bookNumber(in: title) else { continue }
            bookOfTrack[index] = book
            if firstTrack[book] == nil { firstTrack[book] = index }
        }
        guard !firstTrack.isEmpty else { return .empty }

        var chapterOfBook: [Int: Int] = [:]
        var chapterToTrack = [Int?](repeating: nil, count: chapters.count)

        for (index, chapter) in chapters.enumerated() {
            guard let book = chapter.number else { continue }
            chapterOfBook[book] = index
            guard let track = firstTrack[book] else { continue }
            chapterToTrack[index] = track
        }

        var trackToChapters: [Int: ClosedRange<Int>] = [:]
        for (track, book) in bookOfTrack {
            guard let chapter = chapterOfBook[book] else { continue }
            trackToChapters[track] = chapter...chapter
        }
        return LibraryTrackAlignment(
            chapterToTrack: chapterToTrack,
            trackToChapters: trackToChapters
        )
    }

    // MARK: Sequential

    /// Chapter *i* is read by track *i + offset*. Used where the readers
    /// gave every chapter its own file, with the offset covering the
    /// tracks the recording opens with that the text does not have (a
    /// preface, a "To the Reader").
    private static func sequential(
        chapters: [LibraryChapter],
        sections: [LibriVoxSection],
        offset: Int
    ) -> LibraryTrackAlignment {
        var chapterToTrack = [Int?](repeating: nil, count: chapters.count)
        var trackToChapters: [Int: ClosedRange<Int>] = [:]

        // A reading is not always one file. Susan Morin needed two for
        // Thérèse's Epilogue and titled them "…Part 1" and "…Part 2", so
        // the tracks are grouped by what the reader called them before
        // anything is counted: one group is one reading, however many
        // files it took. Without this the second half belongs to no
        // chapter, and the first half claims to be the whole of one —
        // which is what follow-along would then pace the page against.
        let groups = Self.groupedByContinuation(sections)

        for index in chapters.indices {
            let position = index + offset
            guard groups.indices.contains(position) else { continue }
            for track in groups[position] {
                trackToChapters[track] = index...index
            }
            chapterToTrack[index] = groups[position].first
        }
        return LibraryTrackAlignment(
            chapterToTrack: chapterToTrack,
            trackToChapters: trackToChapters
        )
    }

    /// Consecutive tracks that are parts of one reading, gathered.
    ///
    /// The test is the volunteer's own labelling — a trailing "Part 2"
    /// over the same title as the track before it — which is the same
    /// evidence the range and span strategies read. A recording with no
    /// such titles comes back as one group per track, so this is a no-op
    /// for every book that does not need it.
    private static func groupedByContinuation(_ sections: [LibriVoxSection]) -> [[Int]] {
        var groups: [[Int]] = []
        var previousBase: String?

        for (index, section) in sections.enumerated() {
            let title = section.title ?? ""
            let part = Self.continuationPart(of: title)

            if let part, part > 1, let previousBase,
               Self.baseTitle(of: title) == previousBase, !groups.isEmpty {
                groups[groups.count - 1].append(index)
            } else {
                groups.append([index])
                previousBase = Self.baseTitle(of: title)
            }
        }
        return groups
    }

    /// The number in a trailing "Part 2" / "Pt. 2", or nil.
    private static func continuationPart(of title: String) -> Int? {
        guard let regex = Self.partRegex else { return nil }
        let range = NSRange(title.startIndex..., in: title)
        guard let match = regex.firstMatch(in: title, range: range),
              let bounds = Range(match.range(at: 1), in: title) else { return nil }
        return Int(title[bounds])
    }

    /// The title with any trailing part number taken off, folded for
    /// comparison — these titles are hand-typed, and this one carries
    /// five spaces before "Part 1".
    private static func baseTitle(of title: String) -> String {
        let stripped = Self.partRegex.map {
            $0.stringByReplacingMatches(
                in: title,
                range: NSRange(title.startIndex..., in: title),
                withTemplate: ""
            )
        } ?? title
        return stripped
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static let partRegex = try? NSRegularExpression(
        pattern: #"(?i)[\s,\-–—]*\bp(?:ar)?t\.?\s*(\d+)\s*$"#
    )

    // MARK: Book + chapter ranges

    /// One track per span of chapters within a part: "Book 3 - Chapters
    /// 21-30". Matched on the numbers both sides carry — the chapter's
    /// part ("The Third Book" → 3) and its own heading ("Chapter XXV" →
    /// 25) — rather than by counting forward, because a reader's stated
    /// span can overrun the part it names: the Imitation's reader
    /// labelled a file "Book 2 - Chapters 11-20" for a book that ends at
    /// twelve.
    private static func bookChapterRanges(
        chapters: [LibraryChapter],
        sections: [LibriVoxSection]
    ) -> LibraryTrackAlignment {
        var spans: [TrackSpan] = []
        for (index, section) in sections.enumerated() {
            guard let title = section.title else { continue }
            guard let span = Self.span(in: title) else { continue }
            spans.append(
                TrackSpan(track: index, book: span.book, first: span.first, last: span.last)
            )
        }
        guard !spans.isEmpty else { return .empty }

        var chapterToTrack = [Int?](repeating: nil, count: chapters.count)
        var lowest: [Int: Int] = [:]
        var highest: [Int: Int] = [:]

        for (index, chapter) in chapters.enumerated() {
            guard let part = chapter.part else { continue }
            guard let book = LibraryNumerals.number(in: part) else { continue }
            guard let number = chapter.number else { continue }

            var found: TrackSpan?
            for span in spans where span.book == book {
                if number >= span.first && number <= span.last {
                    found = span
                    break
                }
            }
            guard let span = found else { continue }

            chapterToTrack[index] = span.track
            let low = lowest[span.track] ?? index
            let high = highest[span.track] ?? index
            lowest[span.track] = min(low, index)
            highest[span.track] = max(high, index)
        }

        var trackToChapters: [Int: ClosedRange<Int>] = [:]
        for (track, low) in lowest {
            trackToChapters[track] = low...(highest[track] ?? low)
        }
        return LibraryTrackAlignment(
            chapterToTrack: chapterToTrack,
            trackToChapters: trackToChapters
        )
    }

    private struct TrackSpan {
        let track: Int
        let book: Int
        let first: Int
        let last: Int
    }

    /// "Book 1 - Chapters 11-20" → (book 1, 11 through 20).
    private static func span(in title: String) -> (book: Int, first: Int, last: Int)? {
        guard let regex = Self.spanRegex else { return nil }
        let range = NSRange(title.startIndex..., in: title)
        guard let match = regex.firstMatch(in: title, range: range) else { return nil }

        func value(_ index: Int) -> Int? {
            guard let r = Range(match.range(at: index), in: title) else { return nil }
            let token = String(title[r])
            return Int(token) ?? LibraryNumerals.roman(token)
        }
        guard let book = value(1), let first = value(2), let last = value(3),
              last >= first else { return nil }
        return (book, first, last)
    }

    /// Deliberately tolerant about what stands between the numbers —
    /// LibriVox titles use "-", "–", and "to" interchangeably — and
    /// deliberately strict that a book number comes first.
    private static let spanRegex = try? NSRegularExpression(
        pattern: #"(?i)\bbook\s+([IVXLC]+|\d+)\b.*?\b(\d+)\s*(?:[-–—]|to)\s*(\d+)\b"#
    )
}
