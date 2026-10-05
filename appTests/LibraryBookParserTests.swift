//
//  LibraryBookParserTests.swift
//  Lumen Viae Tests
//
//  The Spiritual Reading shelf cuts a Gutenberg edition into chapters on
//  device. Here a small edition, written to carry every trap the real
//  ones do — the licence envelope, CRLF line ends, a contents page whose
//  lines match the chapter pattern, a title printed in capitals or on a
//  line of its own, a printer's FINIS, footnotes, the tail after the end
//  — is cut and read back. Then the shelf's own catalog is held to what
//  the parser needs of it.
//

import Foundation
import Testing
@testable import app

@MainActor
struct LibraryBookParserTests {

    private let prose = """
    And so it was that the soul, having been drawn by grace out of the
    noise of the world, came at last to rest in the _quiet_ of God, where
    nothing is wanting and nothing is feared, for He who made it holds it
    in the hollow of His hand and does not let it go.
    """

    private var edition: String {
        """
        The Project Gutenberg eBook of A Test Book
        Licence words before the book.
        *** START OF THE PROJECT GUTENBERG EBOOK A TEST BOOK ***

        CONTENTS

        CHAPTER I The Dawn
        CHAPTER II The Second Title
        THE END

        CHAPTER I THE DAWN

        \(prose)

        [1] Ps. 1:1. [2] Luke 2:19.

        CHAPTER II

        The Second Title.

        \(prose)

        ______

        FINIS

        \(prose)

        THE END

        AN APPENDIX THAT IS NOT THE BOOK

        \(prose)
        *** END OF THE PROJECT GUTENBERG EBOOK A TEST BOOK ***
        Eighteen kilobytes of licence.
        """
    }

    private func info(
        stopPattern: String? = "^THE END$",
        notePattern: String? = #"\[\d+\]"#,
        chapterTitles: [String]? = nil
    ) -> LibraryBookInfo {
        LibraryBookInfo(
            id: "test-book",
            title: "A Test Book",
            author: "Anonymous",
            blurb: "For the tests.",
            gutenbergID: 1,
            parsing: LibraryParsingRules(
                chapterPattern: #"^CHAPTER [IVXLC]+"#,
                stopPattern: stopPattern,
                notePattern: notePattern,
                dropPattern: "^FINIS$",
                minimumChapterLength: 200
            ),
            chapterTitles: chapterTitles
        )
    }

    @Test func theContentsPageIsNoChapter() {
        let book = LibraryBookParser.parse(text: edition, info: info())
        #expect(book.chapters.count == 2)
        #expect(book.chapters.map(\.id) == [0, 1])
        #expect(book.bookID == "test-book")
    }

    @Test func aContentsLineNamingTheEndDoesNotEndTheBook() {
        // "THE END" stands on the contents page before the body begins
        let book = LibraryBookParser.parse(text: edition, info: info())
        #expect(!book.chapters.isEmpty)
    }

    @Test func aHeadingInCapitalsIsSplitAndTitleCased() {
        let first = LibraryBookParser.parse(text: edition, info: info()).chapters[0]
        #expect(first.heading == "Chapter I")
        #expect(first.title == "The Dawn")
    }

    @Test func aTitleOnItsOwnLineIsLiftedOutOfTheProse() {
        let second = LibraryBookParser.parse(text: edition, info: info()).chapters[1]
        #expect(second.heading == "Chapter II")
        #expect(second.title == "The Second Title", "its full stop dropped")
        #expect(!second.paragraphs.contains { $0.hasPrefix("The Second Title") })
    }

    @Test func hardWrappedLinesJoinAndEmphasisIsUnwrapped() {
        let first = LibraryBookParser.parse(text: edition, info: info()).chapters[0]
        let paragraph = first.paragraphs[0]
        #expect(paragraph.hasPrefix("And so it was that the soul, having been drawn by grace out of the noise"))
        #expect(paragraph.contains("in the quiet of God"))
        #expect(!paragraph.contains("_"))
        #expect(!paragraph.contains("\n"))
    }

    @Test func footnotesAreLiftedToTheFootAndSplit() {
        let first = LibraryBookParser.parse(text: edition, info: info()).chapters[0]
        #expect(first.notes == ["[1] Ps. 1:1.", "[2] Luke 2:19."])
        #expect(first.paragraphs.count == 1, "the notes are not set as prose")
    }

    @Test func withNoNotePatternTheNotesStayInTheText() {
        let first = LibraryBookParser.parse(text: edition, info: info(notePattern: nil)).chapters[0]
        #expect(first.notes.isEmpty)
        #expect(first.paragraphs.contains("[1] Ps. 1:1. [2] Luke 2:19."))
    }

    @Test func thePrintersMarkAndRulesAreDropped() {
        let second = LibraryBookParser.parse(text: edition, info: info()).chapters[1]
        #expect(!second.paragraphs.contains("FINIS"))
        #expect(!second.paragraphs.contains { $0.contains("______") })
        #expect(second.paragraphs.count == 2)
    }

    @Test func nothingAfterTheStopLineOrTheEnvelope() {
        let book = LibraryBookParser.parse(text: edition, info: info())
        let all = book.chapters.flatMap(\.paragraphs).joined(separator: " ")
        #expect(!all.contains("APPENDIX"))
        #expect(!all.contains("licence"))
        #expect(!all.contains("Licence"))
    }

    @Test func withoutAStopLineTheTailRunsOn() {
        let book = LibraryBookParser.parse(text: edition, info: info(stopPattern: nil))
        let all = book.chapters.flatMap(\.paragraphs).joined(separator: " ")
        #expect(all.contains("AN APPENDIX"))
        #expect(!all.contains("Eighteen kilobytes"), "the licence after the envelope never")
    }

    @Test func crlfLineEndsCutTheSameWay() {
        let crlf = edition.replacingOccurrences(of: "\n", with: "\r\n")
        let lf = LibraryBookParser.parse(text: edition, info: info())
        let fromCRLF = LibraryBookParser.parse(text: crlf, info: info())
        #expect(fromCRLF.chapters.map(\.title) == lf.chapters.map(\.title))
        #expect(fromCRLF.chapters.map(\.paragraphs) == lf.chapters.map(\.paragraphs))
    }

    @Test func aCuratedTitleStandsOnlyWhereNoneIsPrinted() {
        let titled = info(chapterTitles: ["Curated One", "Curated Two"])
        #expect(titled.title(forChapter: 0, printed: "The Dawn") == "The Dawn")
        #expect(titled.title(forChapter: 1, printed: nil) == "Curated Two")
        #expect(titled.title(forChapter: 5, printed: nil) == nil)
    }
}

@MainActor
struct LibraryCatalogTests {

    @Test func everyBookIsFoundByItsId() {
        let ids = LibraryCatalog.books.map(\.id)
        #expect(Set(ids).count == ids.count)
        for book in LibraryCatalog.books {
            #expect(LibraryCatalog.book(id: book.id)?.gutenbergID == book.gutenbergID)
        }
    }

    @Test func everyCuttingRuleIsAWorkingPattern() {
        for book in LibraryCatalog.books {
            let rules = book.parsing
            let patterns = [rules.chapterPattern, rules.partPattern, rules.startPattern,
                            rules.stopPattern, rules.notePattern, rules.dropPattern].compactMap { $0 }
            for pattern in patterns {
                #expect((try? NSRegularExpression(pattern: pattern)) != nil, "\(book.id): \(pattern)")
            }
        }
    }

    @Test func everyEditionHasItsOwnFingerprint() {
        let prints = LibraryCatalog.books.map(\.editionFingerprint)
        #expect(Set(prints).count == prints.count)
    }

    @Test func aChangedRuleRetiresTheCachedCut() {
        let book = LibraryCatalog.books[0]
        var rules = book.parsing
        rules.minimumChapterLength += 1
        let changed = LibraryBookInfo(
            id: book.id, title: book.title, author: book.author, blurb: book.blurb,
            gutenbergID: book.gutenbergID, parsing: rules
        )
        let same = LibraryBookInfo(
            id: book.id, title: book.title, author: book.author, blurb: book.blurb,
            gutenbergID: book.gutenbergID, parsing: book.parsing
        )
        #expect(changed.editionFingerprint != same.editionFingerprint)
    }

    @Test func aBooksOwnSpeedIsOneTheShelfCanPlay() {
        for book in LibraryCatalog.books {
            #expect((0.5...2.0).contains(book.preferredRate), "\(book.id)")
        }
    }

    @Test func theTextComesFromGutenberg() {
        for book in LibraryCatalog.books {
            #expect(book.gutenbergID > 0)
            #expect(book.textURL.host == "www.gutenberg.org")
        }
    }
}
