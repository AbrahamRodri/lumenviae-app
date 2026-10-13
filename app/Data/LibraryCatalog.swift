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
        // 18 = 114 chapters, exactly as à Kempis wrote them, plus the
        // exhortation to Holy Communion that opens Book IV before its
        // first chapter — 115 units, the exhortation one of its own (see
        // LibraryBookParser). Benham gathers each chapter's scripture
        // citations onto one line at its foot, marked "(1)", so they are
        // lifted into the apparatus and split there.
        LibraryBookInfo(
            id: "imitation-of-christ",
            title: "The Imitation of Christ",
            author: "Thomas à Kempis",
            translator: "William Benham",
            blurb: "Four books on following Christ, read daily by the faithful for six hundred years.",
            gutenbergID: 1653,
            // No recording offered. LibriVox 575 exists, but it gathers
            // ten chapters into a file ("Book 3 - Chapters 21-30"), and
            // the Imitation's chapters are short enough that a listen
            // control on a chapter row would start a reading of nine
            // others alongside it. Offering nothing is honest; offering
            // a control that lands somewhere else is not. Restoring it
            // means a per-chapter recording, not a remapping.
            librivoxID: nil,
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
        // units, each with its own reading in the recording, track for
        // track. What follows the Epilogue — the Counsels, the letters,
        // the prayers, the poems — is an appendix this reader cannot
        // set, so `stopPattern` ends the text before it. The recording
        // does carry it, as tracks 15–21; those tracks map to no chapter
        // and are never offered.
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
            blurb: "St. Thérèse of Lisieux tells her own life, and her simple way of trusting God.",
            gutenbergID: 16772,
            // Version 2 (LibriVox 8021), read solo by Susan Morin from
            // Taylor's translation — the same English as the text, which
            // is the only kind of recording this shelf will offer. She
            // reads it slowly: thirteen hours and forty minutes against
            // the other recording's six and fifty-five, so the book opens
            // at one and a half and the reader can take it from there.
            //
            // Her Prologue is track 1 (track 0 is the dedication and
            // preface, which the text does not carry), so the offset is
            // one; her Epilogue takes two files, which the grouping in
            // LibraryTrackMap gathers back into one reading.
            librivoxID: 8021,
            trackMapping: .sequential(offset: 1),
            preferredRate: 1.5,
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

        // The 1852 Dunigan translation, cut into the units the printed
        // book has: the Introduction; Part I's twenty-two sections
        // (each chapter of the Salve Regina commentary in its sections,
        // Chapters IX and X whole) and the prayers of the saints that
        // close it; Part II's nine discourses on her feasts and the
        // reflections on each of the seven dolors; the ten sections on
        // her virtues; then the practices, the examples, the novena, the
        // meditations for her feasts, the prayers for the week, the
        // little rosary and the various prayers — 58 units. The
        // footnotes (1,934 of them, nearly all citations) are gathered
        // at the end of the Gutenberg text, and the book stops before
        // them; the markers stay in the prose, as the Imitation's do.
        // The seven feast meditations are headed by a bare "MEDITATION"
        // that cannot be told from the second one, so the first is cut
        // at its own italic subtitle and the bare lines are dropped.
        //
        // The recording is LibriVox 8533, read solo by Ann Boulais from
        // the 1888 Kenedy printing, which is this same translation (the
        // two were set side by side on the dolors). Her 58 files follow
        // the book's units one for one, but for two things: she gives no
        // file to the two paragraphs that open the virtues (they are read
        // into the first virtue's file, so that unit is `unread`), and she
        // needed two files for the examples, titled "part 1" and "part 2",
        // which the track map gathers back into one reading.
        LibraryBookInfo(
            id: "glories-of-mary",
            title: "The Glories of Mary",
            author: "St. Alphonsus Liguori",
            blurb:
                "Every title of the Hail, Holy Queen explained, with her feasts and her seven sorrows: the saints' case for trusting Mary.",
            gutenbergID: 72411,
            librivoxID: 8533,
            trackMapping: .sequential(offset: 0, unread: [40]),
            parsing: LibraryParsingRules(
                chapterPattern:
                    #"^(INTRODUCTION|SECTION [IVXLC]+\.|CHAPTER (IX|X)\.|SOME DEVOUT PRAYERS OF VARIOUS SAINTS TO THE HOLY MOTHER\.|DISCOURSE [IVXLC]+\.|ON THE (FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH|SEVENTH) DOLOR\.|VARIOUS PRACTICES OF DEVOTION TO THE DIVINE MOTHER\.|VARIOUS ADDITIONAL EXAMPLES APPERTAINING TO THE MOST HOLY MARY\.|NOVENA OF MEDITATIONS|_For the day of the Purification of Mary and the Presentation of Jesus\._|PRAYERS TO THE DIVINE MOTHER|LITTLE ROSARY OF THE SEVEN DOLORS OF MARY\.|VARIOUS PRAYERS TO MARY\.)$"#,
                partPattern: #"^(PART (FIRST|SECOND):.*|OF THE VIRTUES OF THE MOST HOLY MARY\.)$"#,
                startPattern: #"^INTRODUCTION$"#,
                stopPattern: #"^FOOTNOTES$"#,
                dropPattern: #"^MEDITATION$"#
            ),
            // The subtitle the feast meditations are cut at names only
            // the first of the seven; the unit holds them all
            headingOverrides: [54: "Meditations for the Feasts of Mary"]
        ),

        // The Fleming H. Revell edition (New York, 1895): the editor's
        // preface, four conversations and fifteen letters, twenty units.
        // The recording is LibriVox 564, read by Kirsten Ferreri from
        // the same edition, nineteen files: the conversations and the
        // letters, with no file for the preface, so the count begins one
        // unit in.
        LibraryBookInfo(
            id: "practice-of-the-presence-of-god",
            title: "The Practice of the Presence of God",
            author: "Brother Lawrence",
            blurb:
                "A monastery cook's way of praying while he worked: a few conversations and letters, short enough to keep for life.",
            gutenbergID: 13871,
            librivoxID: 564,
            trackMapping: .sequential(offset: -1),
            parsing: LibraryParsingRules(
                chapterPattern:
                    #"^(PREFACE|(FIRST|SECOND|THIRD|FOURTH) CONVERSATION|(FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH|SEVENTH|EIGHTH|NINTH|TENTH|ELEVENTH|TWELFTH|THIRTEENTH|FOURTEENTH|FIFTEENTH) LETTER)\.$"#,
                partPattern: #"^(CONVERSATIONS|LETTERS)\.$"#,
                startPattern: #"^PREFACE\.$"#
            )
        ),
    ]

    static func book(id: String) -> LibraryBookInfo? {
        books.first { $0.id == id }
    }

    /// True Devotion's display identity — the cloth it wears wherever
    /// books stand in a row.
    ///
    /// Deliberately *not* in `books`: that list is what gets fetched
    /// from Gutenberg and cut on device, and this book is bundled. It
    /// lives here anyway so there is one place that says what Montfort's
    /// book looks like. It had been written out separately on Explore
    /// and again in the reader, and a binding changed in one of them
    /// would have left the two disagreeing.
    static let trueDevotionDisplay = LibraryBookInfo(
        id: "true-devotion",
        title: "True Devotion to Mary",
        author: "St. Louis de Montfort",
        blurb: "Montfort's consecration to Jesus through Mary.",
        gutenbergID: 0,
        parsing: LibraryParsingRules(chapterPattern: "")
    )
}
