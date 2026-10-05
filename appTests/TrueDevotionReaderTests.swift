//
//  TrueDevotionReaderTests.swift
//  Lumen Viae Tests
//
//  True Devotion's reader keeping the reader's place on a SwiftData store
//  held in memory, against the bundled book: nothing to continue until
//  something is read; continue at the chapter left, mid-paragraph, or
//  at the first unfinished chapter once it is done; one record however
//  fast the scroll writes; marks kept by chapter and paragraph and read
//  back on a fresh open. Then how a reflection names itself in the
//  journal.
//

import Foundation
import SwiftData
import Testing
@testable import app

@MainActor
struct TrueDevotionReaderTests {

    private let container: ModelContainer
    private let context: ModelContext
    private let book: TrueDevotionBook

    init() throws {
        container = try ModelContainer(
            for: TrueDevotionReadingProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        book = try #require(TrueDevotionLibrary.shared.book)
    }

    private func reader() -> TrueDevotionReaderViewModel {
        let vm = TrueDevotionReaderViewModel()
        vm.setModelContext(context)
        vm.loadProgress()
        return vm
    }

    private var first: String { book.chapters[0].id }
    private var second: String { book.chapters[1].id }

    @Test func nothingReadIsNothingToContinue() {
        let vm = reader()
        #expect(!vm.hasStartedReading)
        #expect(vm.continueChapter(in: book) == nil)
    }

    @Test func theChapterLeftIsTakenUpAtItsParagraph() {
        let vm = reader()
        vm.recordPosition(chapterID: second, paragraphIndex: 7)
        #expect(vm.hasStartedReading)
        #expect(vm.continueChapter(in: book)?.id == second)
        #expect(vm.resumeParagraph(for: second) == 7)
        #expect(vm.resumeParagraph(for: first) == nil, "the place belongs to its own chapter")
    }

    @Test func theTopOfAChapterIsNoPlaceToResume() {
        let vm = reader()
        vm.recordPosition(chapterID: first, paragraphIndex: -3)
        #expect(vm.lastParagraphIndex == 0)
        #expect(vm.resumeParagraph(for: first) == nil)
    }

    @Test func aFinishedChapterLeadsOnToTheFirstUnfinished() {
        let vm = reader()
        vm.recordPosition(chapterID: first, paragraphIndex: 4)
        vm.completeChapter(first)
        #expect(vm.isCompleted(first))
        #expect(vm.resumeParagraph(for: first) == nil)
        #expect(vm.continueChapter(in: book)?.id == second)
    }

    @Test func aFinishedChapterKeepsNoPlaceWrittenAfterIt() {
        let vm = reader()
        vm.completeChapter(first)
        vm.recordPosition(chapterID: first, paragraphIndex: 9)
        #expect(vm.lastParagraphIndex == 0, "scrolling back through a finished chapter moves nothing")
    }

    @Test func aFastScrollWritesOneRecord() throws {
        let vm = reader()
        for paragraph in 0..<50 {
            vm.recordPosition(chapterID: second, paragraphIndex: paragraph)
        }
        vm.save()
        #expect(try context.fetch(FetchDescriptor<TrueDevotionReadingProgress>()).count == 1)
    }

    @Test func thePlaceIsThereOnTheNextOpen() {
        let vm = reader()
        vm.recordPosition(chapterID: second, paragraphIndex: 3)
        vm.completeChapter(first)
        let again = reader()
        #expect(again.isCompleted(first))
        #expect(again.lastChapterID == first, "finishing a chapter sets the place to it")
        #expect(again.continueChapter(in: book)?.id == second)
    }

    @Test func marksAreKeptByChapterAndParagraph() {
        let vm = reader()
        #expect(vm.toggleMark(chapterID: first, paragraph: 2))
        #expect(vm.toggleMark(chapterID: first, paragraph: 5))
        #expect(vm.toggleMark(chapterID: second, paragraph: 2))
        #expect(vm.markCount(forChapter: first) == 2)
        #expect(vm.isMarked(chapterID: second, paragraph: 2))
        #expect(!vm.isMarked(chapterID: second, paragraph: 5))

        #expect(!vm.toggleMark(chapterID: first, paragraph: 2), "a second tap lets it go")
        let again = reader()
        #expect(again.markCount(forChapter: first) == 1)
        #expect(again.isMarked(chapterID: first, paragraph: 5))
    }

    @Test func aChapterIdWithAColonStillReadsBack() {
        // A mark is stored "chapterID:paragraph" and read from the last colon
        let progress = TrueDevotionReadingProgress()
        progress.toggleMark(chapterID: "part1:chapter3", paragraph: 4)
        #expect(progress.marks.first?.chapterID == "part1:chapter3")
        #expect(progress.marks.first?.paragraph == 4)
    }
}

@MainActor
struct JournalEntryNamingTests {

    @Test func aConsecrationReflectionSaysWhichDay() {
        let entry = JournalEntry(text: "…", consecrationDay: 14, consecrationPhase: .knowledgeOfSelf)
        #expect(entry.subjectLabel == "Consecration · Day 14")
        #expect(entry.isConsecrationEntry)
        #expect(entry.consecrationPhase == .knowledgeOfSelf)
        #expect(entry.categoryIcon == "ch-consecration-fill")
        #expect(JournalEntry(text: "…", consecrationDay: 34, consecrationPhase: .consecrationDay).subjectLabel == "Consecration Day")
    }

    @Test func aRosaryReflectionIsNamedForItsMystery() {
        let entry = JournalEntry(text: "…", category: .sorrowful, mysteryTitle: "The Agony in the Garden", mysteryIndex: 0)
        #expect(entry.subjectLabel == "The Agony in the Garden")
        #expect(entry.categoryIcon == MysteryCategory.sorrowful.iconName, "the same icon as everywhere else")
        #expect(!entry.isConsecrationEntry)
    }

    @Test func withNoMysteryItIsNamedForItsSetOrJustAReflection() {
        #expect(JournalEntry(text: "…", category: .glorious, mysteryTitle: "").subjectLabel == "Glorious")
        #expect(JournalEntry(text: "…").subjectLabel == "Reflection")
    }
}
