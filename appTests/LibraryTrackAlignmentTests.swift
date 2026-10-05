//
//  LibraryTrackAlignmentTests.swift
//  Lumen Viae Tests
//
//  A LibriVox recording tied to the chapters cut from the text: one file
//  a chapter (with front-matter tracks the text does not carry, and a
//  reading split into "Part 1" and "Part 2"), one file holding ten
//  chapters, and one book read across several files. The alignment
//  decides what the reader may claim — HEAR THIS READ only where a track
//  reads one whole chapter — so it must never hand over the wrong one.
//

import Foundation
import Testing
@testable import app

@MainActor
struct LibraryTrackAlignmentTests {

    private func chapters(_ headings: [String], part: (Int) -> String? = { _ in nil }) -> [LibraryChapter] {
        headings.enumerated().map { index, heading in
            LibraryChapter(id: index, part: part(index), heading: heading, title: nil, paragraphs: ["…"])
        }
    }

    private func sections(_ titles: [String]) -> [LibriVoxSection] {
        titles.enumerated().map { index, title in
            LibriVoxSection(id: "\(index)", sectionNumber: "\(index + 1)", title: title,
                            listenURL: "http://archive.org/\(index).mp3", playtime: "600")
        }
    }

    // MARK: One file a chapter

    @Test func oneFileAChapterTiesThemInOrder() {
        let text = chapters(["Chapter I", "Chapter II", "Chapter III"])
        let audio = sections(["Chapter 1", "Chapter 2", "Chapter 3"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: audio, mapping: .sequential(offset: 0))
        #expect((0..<3).map { aligned.track(forChapter: $0) } == [0, 1, 2])
        #expect((0..<3).allSatisfy { aligned.readsWholeChapter(track: $0) })
    }

    @Test func frontMatterTracksAreSkippedByTheOffset() {
        let text = chapters(["Chapter I", "Chapter II"])
        let audio = sections(["Introduction by the reader", "Chapter 1", "Chapter 2"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: audio, mapping: .sequential(offset: 1))
        #expect(aligned.track(forChapter: 0) == 1)
        #expect(aligned.track(forChapter: 1) == 2)
        #expect(aligned.chapters(forTrack: 0) == nil, "the introduction reads no chapter of the text")
    }

    @Test func aReadingInTwoPartsIsOneChapter() {
        let text = chapters(["Chapter X", "Chapter XI", "Epilogue"])
        let audio = sections(["Chapter 10", "Chapter 11", "Epilogue Part 1", "Epilogue Part 2"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: audio, mapping: .sequential(offset: 0))
        #expect(aligned.track(forChapter: 2) == 2, "the epilogue begins at its first part")
        #expect(aligned.chapters(forTrack: 3) == 2...2, "its second part belongs to it too")
        #expect(!aligned.readsWholeChapter(track: 2), "neither half is the whole of it")
        #expect(!aligned.readsWholeChapter(track: 3))
        #expect(aligned.readsWholeChapter(track: 0))
    }

    @Test func aPartOneWithNoPartTwoIsItsOwnReading() {
        let text = chapters(["Chapter I", "Chapter II"])
        let audio = sections(["Chapter 1 Part 1", "Chapter 2"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: audio, mapping: .sequential(offset: 0))
        #expect(aligned.track(forChapter: 1) == 1)
    }

    @Test func moreChaptersThanTracksLeavesTheRestUnmapped() {
        let text = chapters(["Chapter I", "Chapter II", "Chapter III"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: sections(["Chapter 1"]), mapping: .sequential(offset: 0))
        #expect(aligned.track(forChapter: 0) == 0)
        #expect(aligned.track(forChapter: 2) == nil, "no track is claimed for a chapter that has none")
        #expect(aligned.track(forChapter: 99) == nil)
    }

    // MARK: Ten chapters to a file

    @Test func aFileOfManyChaptersHoldsItsRange() {
        let headings = (1...20).map { "Chapter \(LiturgicalCalendarFormat.roman($0))" }
        let text = chapters(headings) { $0 < 10 ? "The First Book" : "The Second Book" }
            + [LibraryChapter(id: 20, part: "The Third Book", heading: "Chapter I", title: nil, paragraphs: ["…"])]
        // Books one and two print chapters 1–20 as one run here, so the
        // spans name them as the recording does
        let audio = sections(["Book 1, Chapters 1-10", "Book 2, Chapters 11 to 20", "Book III, Chapters 1–5"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: audio, mapping: .bookChapterRanges)
        #expect(aligned.track(forChapter: 0) == 0)
        #expect(aligned.track(forChapter: 9) == 0)
        #expect(aligned.track(forChapter: 10) == 1)
        #expect(aligned.track(forChapter: 20) == 2)
        #expect(aligned.chapters(forTrack: 0) == 0...9)
        #expect(aligned.firstChapter(forTrack: 1) == 10)
        #expect(!aligned.readsWholeChapter(track: 0), "ten chapters are no one chapter")
    }

    @Test func aChapterOutsideEverySpanHasNoTrack() {
        let text = chapters(["Chapter XI"]) { _ in "The First Book" }
        let aligned = LibraryTrackMap.align(chapters: text, sections: sections(["Book 1, Chapters 1-10"]), mapping: .bookChapterRanges)
        #expect(aligned.track(forChapter: 0) == nil)
    }

    // MARK: One book across several files

    @Test func aBookReadAcrossFilesBeginsAtItsFirst() {
        let text = chapters(["Book I", "Book II"])
        let audio = sections(["Book 1 part 1", "Book 1 part 2", "Book Two", "Preface"])
        let aligned = LibraryTrackMap.align(chapters: text, sections: audio, mapping: .bookSpans)
        #expect(aligned.track(forChapter: 0) == 0)
        #expect(aligned.track(forChapter: 1) == 2)
        #expect(aligned.chapters(forTrack: 1) == 0...0)
        #expect(aligned.chapters(forTrack: 3) == nil)
        #expect(!aligned.readsWholeChapter(track: 0), "two files share book one")
        #expect(aligned.readsWholeChapter(track: 2))
    }

    // MARK: Nothing to align

    @Test func noMappingOrNothingToMapIsEmpty() {
        let text = chapters(["Chapter I"])
        let audio = sections(["Chapter 1"])
        #expect(LibraryTrackMap.align(chapters: text, sections: audio, mapping: .none).isEmpty)
        #expect(LibraryTrackMap.align(chapters: [], sections: audio, mapping: .sequential(offset: 0)).isEmpty)
        #expect(LibraryTrackMap.align(chapters: text, sections: [], mapping: .sequential(offset: 0)).isEmpty)
        #expect(LibraryTrackMap.align(chapters: text, sections: sections(["Prologue"]), mapping: .bookChapterRanges).isEmpty)
    }

    // MARK: The section itself

    @Test func aSectionStreamsOverHTTPS() {
        let section = LibriVoxSection(id: "1", sectionNumber: "1", title: nil, listenURL: "http://archive.org/a.mp3", playtime: "61")
        #expect(section.streamURL == "https://archive.org/a.mp3")
        #expect(section.playtimeSeconds == 61)
        let silent = LibriVoxSection(id: "2", sectionNumber: nil, title: nil, listenURL: "", playtime: "0")
        #expect(silent.streamURL == nil)
        #expect(silent.playtimeSeconds == nil)
    }
}
