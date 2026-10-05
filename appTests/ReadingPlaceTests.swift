//
//  ReadingPlaceTests.swift
//  Lumen Viae Tests
//
//  The Spiritual Reading shelf's two places in a book — where the eye
//  left it and where the voice did — kept through `LibraryProgressStore`
//  on a SwiftData store held in memory: a reading place opened only by
//  reading, never by listening; chapters finished and passages marked;
//  a listening place offered back only when there is enough of the track
//  on either side of it; and a change to the edition's cutting rules
//  letting go of every index that no longer means what it meant.
//

import Foundation
import SwiftData
import Testing
@testable import app

// Serialized: the listening throttle is one clock for the whole shelf
@MainActor
@Suite(.serialized)
struct ReadingPlaceTests {

    private let context: ModelContext
    private let container: ModelContainer

    /// A real book on the shelf, so its edition's fingerprint is known
    private let bookID = LibraryCatalog.books[0].id

    init() throws {
        container = try ModelContainer(
            for: BookReadingProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    // MARK: Reading

    @Test func readingOpensAPlace() throws {
        LibraryProgressStore.recordReading(bookID: bookID, chapterIndex: 4, chapterTitle: "Chapter V", paragraphIndex: 12, in: context)
        let row = try #require(LibraryProgressStore.row(for: bookID, in: context))
        #expect(row.hasReadingPlace)
        #expect(row.lastChapterIndex == 4)
        #expect(row.lastParagraphIndex == 12)
        #expect(row.lastChapterTitle == "Chapter V")
        #expect(LibraryProgressStore.isCurrent(row))
    }

    @Test func aBookIsOneRowHoweverOftenItIsRead() {
        LibraryProgressStore.recordReading(bookID: bookID, chapterIndex: 1, in: context)
        LibraryProgressStore.recordReading(bookID: bookID, chapterIndex: 2, paragraphIndex: -5, in: context)
        let rows = LibraryProgressStore.all(in: context)
        #expect(rows.count == 1)
        #expect(rows.first?.lastChapterIndex == 2)
        #expect(rows.first?.lastParagraphIndex == 0, "a paragraph is never before the first")
    }

    @Test func aTitleLeftBlankKeepsTheLastOne() throws {
        LibraryProgressStore.recordReading(bookID: bookID, chapterIndex: 1, chapterTitle: "Prologue", in: context)
        LibraryProgressStore.recordReading(bookID: bookID, chapterIndex: 1, in: context)
        #expect(try #require(LibraryProgressStore.row(for: bookID, in: context)).lastChapterTitle == "Prologue")
    }

    @Test func aChapterIsFinishedOnce() throws {
        LibraryProgressStore.markFinished(bookID: bookID, chapterIndex: 3, in: context)
        LibraryProgressStore.markFinished(bookID: bookID, chapterIndex: 3, in: context)
        LibraryProgressStore.markFinished(bookID: bookID, chapterIndex: 1, in: context)
        let row = try #require(LibraryProgressStore.row(for: bookID, in: context))
        #expect(row.finishedChapterIndexesRaw == "1,3")
        #expect(row.isChapterFinished(3) && !row.isChapterFinished(2))
        #expect(!row.hasReadingPlace, "finishing a chapter is not where the eye left the book")
    }

    // MARK: Marks

    @Test func aMarkIsAPlaceAndATapTakesItAway() {
        #expect(LibraryProgressStore.toggleMark(bookID: bookID, chapter: 2, paragraph: 7, in: context))
        #expect(LibraryProgressStore.toggleMark(bookID: bookID, chapter: 5, paragraph: 0, in: context))
        #expect(LibraryProgressStore.marks(for: bookID, in: context) == [
            BookPassageMark(chapter: 2, paragraph: 7), BookPassageMark(chapter: 5, paragraph: 0)
        ])
        #expect(!LibraryProgressStore.toggleMark(bookID: bookID, chapter: 2, paragraph: 7, in: context))
        #expect(LibraryProgressStore.marks(for: bookID, in: context) == [BookPassageMark(chapter: 5, paragraph: 0)])
    }

    @Test func aBookNeverOpenedHasNoMarks() {
        #expect(LibraryProgressStore.marks(for: bookID, in: context).isEmpty)
    }

    // MARK: Listening

    @Test func listeningKeepsTheVoicesPlaceAndOpensNoReadingPlace() throws {
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t7", trackIndex: 7, seconds: 300, duration: 1200, force: true, in: context)
        let row = try #require(LibraryProgressStore.row(for: bookID, in: context))
        #expect(row.hasListeningPlace)
        #expect(row.lastTrackIndex == 7 && row.lastTrackSeconds == 300)
        #expect(!row.hasReadingPlace, "a track aligned with a chapter is not a chapter the reader opened")
        #expect(row.lastChapterIndex == -1)
    }

    @Test func aBrokenTimeIsNotKept() {
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t", trackIndex: 0, seconds: .nan, duration: 10, force: true, in: context)
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t", trackIndex: 0, seconds: -3, duration: 10, force: true, in: context)
        #expect(LibraryProgressStore.row(for: bookID, in: context) == nil)
    }

    @Test func listeningIsWrittenAtMostEveryFewSecondsUnlessForced() throws {
        LibraryProgressStore.allowImmediateListeningWrite()
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t", trackIndex: 0, seconds: 30, duration: 600, in: context)
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t", trackIndex: 0, seconds: 31, duration: 600, in: context)
        #expect(try #require(LibraryProgressStore.row(for: bookID, in: context)).lastTrackSeconds == 30)
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t", trackIndex: 0, seconds: 32, duration: 600, force: true, in: context)
        #expect(try #require(LibraryProgressStore.row(for: bookID, in: context)).lastTrackSeconds == 32,
                "a pause, a track change and leaving are always written")
    }

    @Test func aTrackIsOfferedBackOnlyWithRoomEitherSide() {
        let row = BookReadingProgress(bookID: "b", lastChapterIndex: -1)
        row.lastTrackID = "t"
        row.lastTrackIndex = 0
        row.lastTrackDuration = 600

        row.lastTrackSeconds = 10
        #expect(!row.hasResumableTrack, "barely begun is begun again")
        row.lastTrackSeconds = 300
        #expect(row.hasResumableTrack)
        row.lastTrackSeconds = 590
        #expect(!row.hasResumableTrack, "all but finished is finished")
        row.lastTrackDuration = 0
        #expect(row.hasResumableTrack, "with no known length, any place past the opening")
    }

    // MARK: A changed edition

    @Test func aChangedCuttingLetsGoOfTheOldIndices() throws {
        LibraryProgressStore.recordReading(bookID: bookID, chapterIndex: 9, chapterTitle: "IX", paragraphIndex: 4, in: context)
        LibraryProgressStore.markFinished(bookID: bookID, chapterIndex: 8, in: context)
        LibraryProgressStore.toggleMark(bookID: bookID, chapter: 9, paragraph: 4, in: context)
        LibraryProgressStore.recordListening(bookID: bookID, trackID: "t3", trackIndex: 3, seconds: 100, duration: 900, force: true, in: context)

        // The catalog's rules for this book change after the place was made
        let row = try #require(LibraryProgressStore.row(for: bookID, in: context))
        row.editionFingerprint = "an older cutting"
        #expect(!LibraryProgressStore.isCurrent(row))
        #expect(LibraryProgressStore.marks(for: bookID, in: context).isEmpty, "a mark from another cutting is not shown")

        // The next write retires everything indexed against the old cut
        LibraryProgressStore.markFinished(bookID: bookID, chapterIndex: 0, in: context)
        #expect(row.editionFingerprint == LibraryCatalog.books[0].editionFingerprint)
        #expect(!row.hasReadingPlace)
        #expect(row.lastChapterTitle.isEmpty)
        #expect(row.finishedChapterIndexesRaw == "0")
        #expect(row.marksRaw.isEmpty)
        #expect(row.lastTrackIndex == 3, "the voice's place is the recording's, not the cutting's")
    }

    @Test func aBookOffTheShelfIsNeverCurrent() {
        LibraryProgressStore.recordReading(bookID: "a-withdrawn-book", chapterIndex: 0, in: context)
        let row = LibraryProgressStore.row(for: "a-withdrawn-book", in: context)
        #expect(row?.hasReadingPlace == true)
        #expect(row.map(LibraryProgressStore.isCurrent) == false)
    }
}
