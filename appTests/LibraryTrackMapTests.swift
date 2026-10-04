//
//  LibraryTrackMapTests.swift
//  Lumen Viae Tests
//
//  The reading shelf's alignment of a LibriVox recording to the chapters
//  cut from the text: numbers read in all the ways the two sources write
//  them (and words that only look like numerals left alone), a file to a
//  chapter with an offset for front matter, a reading split into parts
//  gathered back into one, and a file to a span of chapters within a
//  book — which never claims to read a whole chapter.
//

import Testing
@testable import app

@MainActor
struct LibraryTrackMapTests {

    private func chapter(_ id: Int, _ heading: String, part: String? = nil) -> LibraryChapter {
        LibraryChapter(id: id, part: part, heading: heading, title: nil, paragraphs: ["…"])
    }

    private func sections(_ titles: [String]) -> [LibriVoxSection] {
        titles.enumerated().map { index, title in
            LibriVoxSection(id: "\(index)", sectionNumber: "\(index + 1)", title: title,
                            listenURL: nil, playtime: nil)
        }
    }

    // MARK: - Numerals

    @Test(arguments: [
        ("Chapter XI", 11),
        ("Book 3 - Chapters 1-10", 3),
        ("The First Book", 1),
        ("Book Thirteen", 13),
        ("CHAPTER XLIV.", 44),
        ("Chapter CXIV", 114)
    ])
    func aNumberIsReadHoweverItIsWritten(text: String, number: Int) {
        #expect(LibraryNumerals.number(in: text) == number)
    }

    @Test(arguments: ["DID", "CIVIL", "MIX", "IIII", "VV", "i", "Mix"])
    func wordsThatScanAsNumeralsAreWords(token: String) {
        #expect(LibraryNumerals.roman(token) == nil)
    }

    @Test func theBookNumberIsTheOneAfterBook() {
        #expect(LibraryNumerals.bookNumber(in: "Book Four, Chapters 1-10") == 4)
        #expect(LibraryNumerals.bookNumber(in: "Chapters 1-10 of Book 2") == 2)
        #expect(LibraryNumerals.bookNumber(in: "Chapter 1") == nil)
    }

    @Test func noHeadingNumberIsNil() {
        #expect(chapter(0, "Prologue").number == nil)
    }

    // MARK: - One file to a chapter

    @Test func sequentialSkipsTheFrontMatterTracks() {
        let chapters = [chapter(0, "Chapter I"), chapter(1, "Chapter II")]
        let tracks = sections(["Introduction", "Chapter 1", "Chapter 2"])
        let alignment = LibraryTrackMap.align(chapters: chapters, sections: tracks,
                                              mapping: .sequential(offset: 1))
        #expect(alignment.track(forChapter: 0) == 1)
        #expect(alignment.track(forChapter: 1) == 2)
        #expect(alignment.chapters(forTrack: 0) == nil)
        #expect(alignment.readsWholeChapter(track: 1))
        #expect(alignment.readsWholeChapter(track: 2))
    }

    @Test func aReadingInTwoPartsIsOneReadingAndNoWholeChapter() {
        let chapters = [chapter(0, "Chapter I"), chapter(1, "Epilogue")]
        let tracks = sections(["Chapter 1", "Epilogue     Part 1", "Epilogue Part 2"])
        let alignment = LibraryTrackMap.align(chapters: chapters, sections: tracks,
                                              mapping: .sequential(offset: 0))
        #expect(alignment.track(forChapter: 1) == 1)
        #expect(alignment.chapters(forTrack: 1) == 1...1)
        #expect(alignment.chapters(forTrack: 2) == 1...1)
        #expect(alignment.readsWholeChapter(track: 0))
        #expect(!alignment.readsWholeChapter(track: 1))
        #expect(!alignment.readsWholeChapter(track: 2))
    }

    @Test func aChapterBeyondTheRecordingHasNoTrack() {
        let chapters = [chapter(0, "Chapter I"), chapter(1, "Chapter II")]
        let alignment = LibraryTrackMap.align(chapters: chapters, sections: sections(["Chapter 1"]),
                                              mapping: .sequential(offset: 0))
        #expect(alignment.track(forChapter: 1) == nil)
        #expect(alignment.track(forChapter: 99) == nil)
    }

    // MARK: - One file to a span

    @Test func aSpanFileHoldsItsBooksChaptersAndNoOtherBooks() {
        let chapters = [
            chapter(0, "Chapter I", part: "The First Book"),
            chapter(1, "Chapter II", part: "The First Book"),
            chapter(2, "Chapter I", part: "The Second Book"),
            chapter(3, "Chapter II", part: "The Second Book")
        ]
        let tracks = sections(["Book 1 - Chapters 1-2", "Book II – Chapters 1 to 20"])
        let alignment = LibraryTrackMap.align(chapters: chapters, sections: tracks,
                                              mapping: .bookChapterRanges)
        #expect(alignment.track(forChapter: 0) == 0)
        #expect(alignment.track(forChapter: 1) == 0)
        #expect(alignment.track(forChapter: 2) == 1)
        #expect(alignment.track(forChapter: 3) == 1)
        #expect(alignment.chapters(forTrack: 0) == 0...1)
        #expect(alignment.firstChapter(forTrack: 1) == 2)
        #expect(!alignment.readsWholeChapter(track: 0))
    }

    // MARK: - Nothing to align

    @Test func noMappingOrNoTracksAlignsNothing() {
        let chapters = [chapter(0, "Chapter I")]
        #expect(LibraryTrackMap.align(chapters: chapters, sections: sections(["Chapter 1"]),
                                      mapping: .none).isEmpty)
        #expect(LibraryTrackMap.align(chapters: chapters, sections: [],
                                      mapping: .sequential(offset: 0)).isEmpty)
    }
}
