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

    /// How that recording's tracks line up with the chapters cut from
    /// this edition — the seam that lets a reader move between the text
    /// and the voice without losing their place.
    var trackMapping: LibraryTrackMapping = .none

    /// The speed this reader is best heard at, as the shelf's opening
    /// offer for this book.
    ///
    /// LibriVox readers are volunteers and their paces differ enormously
    /// — one Story of a Soul runs under seven hours and another runs
    /// nearly fourteen. A reader who has to slow down or speed up every
    /// book by hand is being asked to fix the catalog's homework. The
    /// reader's own choice for a book is remembered and outranks this
    /// from then on, and this never touches the speed of the Rosary's
    /// narration, which is a different voice at a different pace.
    var preferredRate: Double = 1.0

    /// How this edition's plain text is cut into chapters
    let parsing: LibraryParsingRules

    /// Titles for an edition that prints none, in parsed order. Pusey
    /// heads his thirteen books "BOOK I" and nothing more, which leaves
    /// a contents ledger saying "Book I" twice on every row and telling
    /// the reader nothing about where they are going. These are the
    /// received themes of each book, not invented ones.
    ///
    /// They ride in the edition fingerprint like the cutting rules, so
    /// correcting one retires that book's cached parse and no other's.
    var chapterTitles: [String]? = nil

    /// Corrections to a heading the edition misprints, by parsed index.
    ///
    /// `chapterTitles` only fills a title the edition *omits*. Gutenberg's
    /// Dolorous Passion heads its sixty-first chapter "CHAPTER LVI." —
    /// the printed book, the surrounding chapters, and LibriVox's own
    /// track all say LXI — so the ledger listed LVI twice and never
    /// listed LXI, and `LibraryChapter.number` answered 56 for both.
    var headingOverrides: [Int: String]? = nil

    /// The heading this edition prints, or the correction where it is
    /// misprinted.
    func heading(forChapter index: Int, printed: String) -> String {
        headingOverrides?[index] ?? printed
    }

    /// The title this edition prints for a parsed unit, or the curated
    /// one where it prints none.
    func title(forChapter index: Int, printed: String?) -> String? {
        if let printed, !printed.isEmpty { return printed }
        guard let chapterTitles, chapterTitles.indices.contains(index) else { return nil }
        return chapterTitles[index]
    }

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

        // Built in pieces: as one array literal the type-checker gives
        // up on it.
        let titles = (chapterTitles ?? []).joined(separator: "\u{2}")
        var overrides = ""
        if let headingOverrides {
            let pairs: [String] = headingOverrides.sorted { $0.key < $1.key }
                .map { pair in "\(pair.key)=\(pair.value)" }
            overrides = pairs.joined(separator: "\u{3}")
        }

        let parts: [String] = [
            String(gutenbergID),
            parsing.chapterPattern,
            parsing.partPattern ?? "",
            parsing.startPattern ?? "",
            parsing.stopPattern ?? "",
            parsing.notePattern ?? "",
            parsing.dropPattern ?? "",
            String(parsing.titleRunsToBlankGap),
            titles,
            overrides,
            String(parsing.minimumChapterLength)
        ]
        let seed = parts.joined(separator: "\u{1}")

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

    /// The line at which the book proper begins. Everything above it —
    /// the title page, the imprimatur, the table of contents, the
    /// publisher's front matter — is dropped before any pattern is
    /// matched, and the matching line itself is kept (it is often the
    /// first heading).
    ///
    /// `minimumChapterLength` alone can only reject a contents entry
    /// whose gathered text is short. An edition whose contents page is
    /// followed by a long preface hands that preface to the last entry
    /// on the page, and no length test can tell it from a chapter. This
    /// is the honest fix: say where the book starts.
    var startPattern: String? = nil

    /// A line at which the book is done — appendices, letter
    /// collections, and editorial tails end here
    var stopPattern: String? = nil

    /// A footnote's marker, as this edition prints it — `\[\d+\]` for
    /// Taylor's Thérèse ("[12] Ps. 118:32."), `\(\d+\)` for Benham's
    /// Kempis ("(1) Psalm xciv. 12.").
    ///
    /// A paragraph that *opens* with the marker is the editor's
    /// apparatus, not the author's text: it is lifted out of the body
    /// and set small at the foot of the chapter, split at each further
    /// marker (Kempis prints a whole chapter's notes on one line). A
    /// chapter of the Story of a Soul carries thirty-four of these, and
    /// they used to read as though the saint had written them.
    var notePattern: String? = nil

    /// A line to drop wherever it appears in the body — a printer's
    /// mark that is neither heading nor text ("END OF THE
    /// AUTOBIOGRAPHY", "FINIS"). Without this such a line is set as a
    /// shouted paragraph in the middle of the prose.
    var dropPattern: String? = nil

    /// Whether a printed title may run to more than one blank-line
    /// block. The Burns & Lambert Dolorous Passion sets nine of its
    /// titles as two blocks a single blank line apart, with a wider gap
    /// before the body; lifting only the first truncates the title and
    /// leaves its second half standing at the head of the prose.
    ///
    /// Per-edition, because a gap-blind rule would be wrong elsewhere:
    /// Benham puts a blank line and then the rubric "The Voice of the
    /// Disciple" under eighteen of Book IV's titles, and that is text,
    /// not part of the title.
    var titleRunsToBlankGap: Bool = false

    /// A heading whose body runs shorter than this is not a chapter —
    /// it is the table of contents naming one. 500 characters rejects
    /// every contents line without touching any real chapter.
    var minimumChapterLength: Int = 500
}

// MARK: - LibraryTrackMapping

/// How a recording's tracks line up with the chapters cut from the text.
///
/// LibriVox recordings are made by volunteers who split a book however
/// suited them: Thérèse's readers gave every chapter its own file, while
/// the Kempis reader gathered ten chapters at a time. Both are honest
/// recordings of the same text, so the app describes the alignment in
/// the catalog rather than pretending every book is one shape.
nonisolated enum LibraryTrackMapping: Hashable {

    /// No recording, or one whose tracks cannot be tied to these
    /// chapters — a different translation, an abridgement, a reading
    /// that reorders the book. The Listen ledger still plays; it just
    /// never claims to know which chapter a track holds.
    case none

    /// Track `chapterIndex + offset` reads chapter `chapterIndex`, one
    /// for one, in order. The offset covers the front-matter tracks a
    /// recording opens with and the text does not have.
    case sequential(offset: Int)

    /// Track titles name a part and a span of chapters — "Book 3 -
    /// Chapters 21-30". One track holds many chapters, so a chapter
    /// resolves to the track that contains it, played from its start.
    case bookChapterRanges

    /// The inverse: the reading unit is a whole book and the recording
    /// needed several files for it — "Book Ten, Chapters 21-30", where
    /// those chapters are subdivisions the text's own headings do not
    /// carry. A unit resolves to the first track that names it, and the
    /// rest of that book's tracks run on after it.
    case bookSpans
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

    /// The editor's footnotes for this chapter, in printed order, lifted
    /// out of the body by `notePattern` and set small at the foot of the
    /// page. Empty for editions that print none.
    ///
    /// Defaulted and decoded leniently so a chapter cached before the
    /// apparatus existed still reads — though the cache version retires
    /// those anyway.
    var notes: [String] = []

    /// What the contents ledger calls it
    var displayTitle: String { title ?? heading }

    /// The chapter's own number, when its heading carries one —
    /// "Chapter XI" is 11. Used to tie a chapter to the track that reads
    /// it; nil for a heading with no numeral ("Prologue").
    var number: Int? { LibraryNumerals.number(in: heading) }

    // Lenient decoding for the one field that postdates the shape.
    enum CodingKeys: String, CodingKey {
        case id, part, heading, title, paragraphs, notes
    }

    init(
        id: Int,
        part: String?,
        heading: String,
        title: String?,
        paragraphs: [String],
        notes: [String] = []
    ) {
        self.id = id
        self.part = part
        self.heading = heading
        self.title = title
        self.paragraphs = paragraphs
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        part = try c.decodeIfPresent(String.self, forKey: .part)
        heading = try c.decode(String.self, forKey: .heading)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        paragraphs = try c.decode([String].self, forKey: .paragraphs)
        notes = try c.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
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

    /// The URL to stream or save, always over https.
    ///
    /// LibriVox serves https today and archive.org's redirects stay
    /// https, but older ledgers served plain http, which App Transport
    /// Security refuses outright — and it would surface as "check your
    /// connection", blaming the reader for a policy refusal. One rule,
    /// here, so the player and the downloader cannot drift apart.
    var streamURL: String? {
        guard let listenURL, !listenURL.isEmpty else { return nil }
        guard listenURL.hasPrefix("http://") else { return listenURL }
        return "https://" + listenURL.dropFirst("http://".count)
    }

    /// The track's length in seconds, or nil when LibriVox gives none.
    var playtimeSeconds: Double? {
        guard let playtime, let seconds = Double(playtime), seconds > 0 else { return nil }
        return seconds
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
