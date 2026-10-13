//
//  LibraryBookPlaceTests.swift
//  Lumen Viae Tests
//
//  How the book page names a place and where its list of chapters
//  begins: the numeral a heading ends on, a part's Roman numeral, the
//  Continue button's short place, and the list opening a little before
//  the chapter being read, the part it cuts into kept whole by name.
//

import Testing
@testable import app

@MainActor
struct LibraryBookPlaceTests {

    private func chapter(_ id: Int, _ part: String?, _ heading: String) -> LibraryChapter {
        LibraryChapter(id: id, part: part, heading: heading, title: nil, paragraphs: ["…"])
    }

    /// Two parts of three chapters each, as the Imitation's Books stand
    private var runs: [LibraryPartRun] {
        [
            LibraryPartRun(id: "First", title: "The First Book", chapters: [
                chapter(0, "The First Book", "Chapter I"),
                chapter(1, "The First Book", "Chapter II"),
                chapter(2, "The First Book", "Chapter III"),
            ]),
            LibraryPartRun(id: "Second", title: "The Second Book", chapters: [
                chapter(3, "The Second Book", "Chapter I"),
                chapter(4, "The Second Book", "Chapter II"),
                chapter(5, "The Second Book", "Chapter III"),
            ]),
        ]
    }

    @Test func aHeadingsNumeralIsItsLastWordWhenThatIsANumber() {
        #expect(LibraryBookPlace.numeral(ofHeading: "Chapter V") == "V")
        #expect(LibraryBookPlace.numeral(ofHeading: "Chapter XXXVIII") == "XXXVIII")
        #expect(LibraryBookPlace.numeral(ofHeading: "Book 12") == "12")
        #expect(LibraryBookPlace.numeral(ofHeading: "Prologue") == nil)
        #expect(LibraryBookPlace.numeral(ofHeading: "The First Book") == nil)
    }

    @Test func partsAreCountedInRomanNumerals() {
        #expect(LibraryBookPlace.roman(1) == "I")
        #expect(LibraryBookPlace.roman(4) == "IV")
        #expect(LibraryBookPlace.roman(9) == "IX")
        #expect(LibraryBookPlace.roman(59) == "LIX")
    }

    @Test func theContinuePlaceNamesThePartAndTheChapter() {
        let runs = runs
        #expect(LibraryBookPlace.shortName(of: runs[1].chapters[1], in: runs) == "II.II")

        let single = [LibraryPartRun(id: "part-0", title: nil, chapters: [chapter(0, nil, "Prologue")])]
        #expect(LibraryBookPlace.shortName(of: single[0].chapters[0], in: single) == "Prologue")
    }

    @Test func theListOpensTwoChaptersBeforeTheOneBeingRead() {
        let runs = runs
        #expect(LibraryBookPlace.firstShown(in: runs, currentIndex: 4) == 2)

        let shown = LibraryBookPlace.runs(runs, from: 2)
        #expect(shown.map(\.id) == ["First", "Second"])
        #expect(shown[0].chapters.map(\.id) == [2])
        #expect(shown[1].chapters.map(\.id) == [3, 4, 5])
    }

    @Test func nothingIsFoldedNearTheStartOrWithoutAPlace() {
        let runs = runs
        #expect(LibraryBookPlace.firstShown(in: runs, currentIndex: nil) == nil)
        #expect(LibraryBookPlace.firstShown(in: runs, currentIndex: 1) == nil)
        #expect(LibraryBookPlace.firstShown(in: runs, currentIndex: 2) == nil)
        #expect(LibraryBookPlace.firstShown(in: runs, currentIndex: 99) == nil)
        #expect(LibraryBookPlace.runs(runs, from: nil).map(\.chapters.count) == [3, 3])
    }
}
