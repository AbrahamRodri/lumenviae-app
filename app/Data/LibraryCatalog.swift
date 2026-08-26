//
//  LibraryCatalog.swift
//  Lumen Viae
//
//  The Spiritual Reading shelf. The catalog is curated here — identity,
//  sources, each edition's cutting rules, and how its recording lines up
//  with its text — but the books themselves are never bundled: text
//  arrives from Project Gutenberg when a book is opened, recordings
//  stream from LibriVox, and both cache to disk so a book once opened
//  keeps working without a signal.
//
//  Every text and every recording is in the public domain.
//
//  A note on the rules below: they are not guesses. Each was checked
//  against the actual Gutenberg edition, chapter by chapter, and each
//  track mapping against the actual LibriVox ledger, track by track.
//  An edition that changes shape retires its own cached parse through
//  `editionFingerprint`, so correcting one book never disturbs another.
//

import Foundation

enum LibraryCatalog {

    static let books: [LibraryBookInfo] = [

        // Benham's translation, cut on its own "CHAPTER I" headings
        // under the four "THE FIRST BOOK" part headers: 25 + 12 + 59 +
        // 18 = 114 chapters, exactly as à Kempis wrote them. Benham
        // gathers each chapter's scripture citations onto one line at
        // its foot, marked "(1)", so they are lifted into the apparatus
        // and split there.
        //
        // The recording gathers ten chapters to a file and says so in
        // its titles ("Book 3 - Chapters 21-30"), so a chapter resolves
        // to the file that holds it.
        LibraryBookInfo(
            id: "imitation-of-christ",
            title: "The Imitation of Christ",
            author: "Thomas à Kempis",
            translator: "William Benham",
            blurb: "Four books on following Christ, read daily by the faithful for six hundred years.",
            gutenbergID: 1653,
            librivoxID: 575,
            trackMapping: .bookChapterRanges,
            parsing: LibraryParsingRules(
                chapterPattern: #"^CHAPTER [IVXLC]+$"#,
                partPattern: #"^THE (FIRST|SECOND|THIRD|FOURTH) BOOK$"#,
                notePattern: #"\(\d+\)"#
            )
        ),

        // Taylor's translation. The autobiography proper is the Prologue
        // (Thérèse's parentage and birth), the eleven chapters she
        // wrote, and the Prioress's Epilogue on her death — thirteen
        // units, which is exactly what the recording holds, track for
        // track. What follows the Epilogue — the Counsels, the letters,
        // the prayers, the poems — is an appendix this reader cannot
        // set, and the recording does not carry it either.
        //
        // `startPattern` is load-bearing: without it the contents page's
        // own "EPILOGUE" line opens a false chapter that swallows the
        // whole of Cardinal Bourne's preface. Taylor's footnotes are
        // marked "[1]" and run to thirty-four in a single chapter.
        LibraryBookInfo(
            id: "story-of-a-soul",
            title: "The Story of a Soul",
            author: "St. Thérèse of Lisieux",
            translator: "Thomas N. Taylor",
            blurb: "The autobiography of the Little Flower — her little way, written under obedience.",
            gutenbergID: 16772,
            librivoxID: 3229,
            trackMapping: .sequential(offset: 0),
            parsing: LibraryParsingRules(
                chapterPattern: #"^(PROLOGUE|CHAPTER [IVXLC]+|EPILOGUE)\b.*$"#,
                startPattern: #"^PROLOGUE: THE PARENTAGE"#,
                stopPattern: #"^COUNSELS AND REMINISCENCES"#,
                notePattern: #"\[\d+\]"#,
                // Both halves of the half-title that opens the
                // autobiography, and the one that closes it — printer's
                // marks, matched line by line, which otherwise stand as
                // shouted paragraphs inside the Prologue and Chapter XI.
                dropPattern:
                    #"^(END OF THE AUTOBIOGRAPHY|THE AUTOBIOGRAPHY OF SOEUR THÉRÈSE|HERSELF: "THE STORY OF THE SPRINGTIME)"#
            )
        ),

        // Pusey heads his thirteen books "BOOK I" and prints no titles
        // at all, so the received theme of each stands in — otherwise
        // the contents ledger says "Book I" twice on every row and tells
        // the reader nothing. The books themselves are the reading
        // units, as Augustine divided them; the reader's place is kept
        // inside one, which is what a book of this length needs.
        //
        // The recording is LibriVox 2601, read by one voice throughout —
        // and read from Pusey, the same English as the text. The other
        // complete Confessions on LibriVox is Outler's 1955 version by
        // ten different readers; its track titles would map just as
        // neatly, which is exactly what makes it a trap. A recording of
        // another man's English must never be offered as the voice of
        // this text.
        //
        // MaryAnn needed thirty-two files for thirteen books, so here
        // the relation runs the other way: one unit, several tracks.
        LibraryBookInfo(
            id: "confessions-of-st-augustine",
            title: "The Confessions",
            author: "St. Augustine of Hippo",
            translator: "E. B. Pusey",
            blurb: "Thirteen books of prayer — the restless heart's long road home to God.",
            gutenbergID: 3296,
            librivoxID: 2601,
            trackMapping: .bookSpans,
            parsing: LibraryParsingRules(
                chapterPattern: #"^BOOK [IVXLC]+$"#
            ),
            chapterTitles: [
                "Infancy and boyhood",
                "The sixteenth year",
                "Carthage, and the Manichees",
                "Nine years astray",
                "Rome, Milan, and Ambrose",
                "Monica, and the wavering will",
                "God sought, and the Platonists",
                "The garden, and the conversion",
                "Cassiciacum, baptism, and Monica's death",
                "Memory, and the search for happiness",
                "Time, eternity, and the beginning",
                "Heaven and earth unformed",
                "The Spirit, and the seventh day"
            ]
        ),

        // Emmerich's visions, in the Burns & Lambert English. Two
        // corrections here matter. The nine MEDITATIONS are the Last
        // Supper — the Holy Thursday half of the book, fifty thousand
        // characters of it — and the old rules discarded every one.
        // And with nothing after Chapter LXVI matching the chapter
        // pattern, that chapter used to swallow the Appendix, the words
        // "THE END.", and twenty footnotes: eighty-eight per cent of
        // what it showed the reader was not the chapter.
        //
        // Cut this way the book is "To the Reader", nine Meditations,
        // the Passion's own Introduction, and Chapters I through LXVI —
        // seventy-seven units, which is the recording's first
        // seventy-seven tracks, in order. The editorial life of
        // Emmerich that opens the volume is left out; `startPattern`
        // steps over it.
        LibraryBookInfo(
            id: "dolorous-passion",
            title: "The Dolorous Passion",
            author: "Anne Catherine Emmerich",
            blurb: "The Lenten visions of a contemplative nun on the Passion of Our Lord.",
            gutenbergID: 10866,
            librivoxID: 13588,
            trackMapping: .sequential(offset: 0),
            parsing: LibraryParsingRules(
                // "INTRODUCTION." with its period is the Passion's own;
                // the bare "INTRODUCTION" far above it is the editor's
                // life of Emmerich, and startPattern steps over that.
                chapterPattern:
                    #"^(TO THE READER|MEDITATION [IVXLC]+\.|INTRODUCTION\.|CHAPTER [IVXLC]+\.)$"#,
                startPattern: #"^TO THE READER$"#,
                stopPattern: #"^APPENDIX\.$"#,
                // Nine of this edition's titles are set as two blocks a
                // single blank line apart.
                titleRunsToBlankGap: true
            ),
            // Gutenberg's transcription heads the sixty-first chapter
            // "CHAPTER LVI." The printed book, the chapters either side
            // of it, and LibriVox's own track all say LXI; left as it
            // stands the ledger lists LVI twice and never lists LXI.
            headingOverrides: [71: "Chapter LXI"]
        ),
    ]

    static func book(id: String) -> LibraryBookInfo? {
        books.first { $0.id == id }
    }
}
