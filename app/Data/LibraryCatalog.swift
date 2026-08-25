//
//  LibraryCatalog.swift
//  Lumen Viae
//
//  The Spiritual Reading shelf. The catalog is curated here — identity,
//  sources, and each edition's cutting rules — but the books themselves
//  are never bundled: text arrives from Project Gutenberg when a book
//  is opened, recordings stream from LibriVox, and both cache to disk
//  so a book once opened keeps working without a signal.
//
//  Every text and every recording is in the public domain.
//

import Foundation

enum LibraryCatalog {

    static let books: [LibraryBookInfo] = [
        LibraryBookInfo(
            id: "imitation-of-christ",
            title: "The Imitation of Christ",
            author: "Thomas à Kempis",
            translator: "William Benham",
            blurb: "Four books on following Christ, read daily by the faithful for six hundred years.",
            gutenbergID: 1653,
            librivoxID: 575,
            parsing: LibraryParsingRules(
                chapterPattern: #"^CHAPTER [IVXLC]+$"#,
                partPattern: #"^THE (FIRST|SECOND|THIRD|FOURTH) BOOK$"#
            )
        ),
        LibraryBookInfo(
            id: "story-of-a-soul",
            title: "The Story of a Soul",
            author: "St. Thérèse of Lisieux",
            translator: "Thomas N. Taylor",
            blurb: "The autobiography of the Little Flower — her little way, written under obedience.",
            gutenbergID: 16772,
            librivoxID: 3229,
            parsing: LibraryParsingRules(
                chapterPattern: #"^CHAPTER [IVXLC]+.*$"#,
                stopPattern: #"^EPILOGUE"#
            )
        ),
        LibraryBookInfo(
            id: "confessions-of-st-augustine",
            title: "The Confessions",
            author: "St. Augustine of Hippo",
            translator: "E. B. Pusey",
            blurb: "Thirteen books of prayer — the restless heart's long road home to God.",
            gutenbergID: 3296,
            parsing: LibraryParsingRules(
                chapterPattern: #"^BOOK [IVXLC]+$"#
            )
        ),
        LibraryBookInfo(
            id: "dolorous-passion",
            title: "The Dolorous Passion",
            author: "Anne Catherine Emmerich",
            blurb: "The Lenten visions of a contemplative nun on the Passion of Our Lord.",
            gutenbergID: 10866,
            librivoxID: 13588,
            parsing: LibraryParsingRules(
                chapterPattern: #"^CHAPTER [IVXLC]+\.$"#
            )
        ),
    ]

    static func book(id: String) -> LibraryBookInfo? {
        books.first { $0.id == id }
    }
}
