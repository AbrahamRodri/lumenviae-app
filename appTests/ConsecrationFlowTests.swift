//
//  ConsecrationFlowTests.swift
//  Lumen Viae Tests
//
//  The 33-day preparation as a reader lives it, on a real SwiftData
//  store held in memory: begun on a day (or taken up partway), the day
//  reckoned from the start date, days opened only once reached, each
//  day's reflection kept for that day of that consecration alone, the
//  day of consecration closing it, a reflection written before entries
//  were scoped claimed by the consecration it was written during, and
//  the whole put down again.
//

import Foundation
import SwiftData
import Testing
@testable import app

@MainActor
struct ConsecrationFlowTests {

    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainer(
            for: ConsecrationProgress.self, JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    private func viewModel() -> ConsecrationViewModel {
        let vm = ConsecrationViewModel()
        vm.setModelContext(context)
        return vm
    }

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Calendar.current.startOfDay(for: .now))!
    }

    private func entries() throws -> [JournalEntry] {
        try context.fetch(FetchDescriptor<JournalEntry>())
    }

    // MARK: Beginning

    @Test func nothingBegunIsNoConsecration() {
        let vm = viewModel()
        vm.loadProgress()
        #expect(!vm.hasActiveConsecration)
        #expect(vm.todaysDayNumber == 1)
        #expect(!vm.canAccessDay(1))
    }

    @Test func begunTodayItIsDayOne() throws {
        let vm = viewModel()
        vm.startConsecration(on: .now)
        #expect(vm.hasActiveConsecration)
        #expect(vm.todaysDayNumber == 1)
        #expect(vm.currentDay?.dayNumber == 1)
        #expect(vm.canAccessDay(1))
        #expect(!vm.canAccessDay(2), "a day is opened only once it is reached")
        #expect(try context.fetch(FetchDescriptor<ConsecrationProgress>()).count == 1)
    }

    @Test func takenUpPartwayItStandsOnThatDay() {
        let vm = viewModel()
        vm.startConsecration(startingAt: 14)
        #expect(vm.todaysDayNumber == 14)
        #expect(vm.currentDay?.phase == .knowledgeOfSelf)
        #expect(vm.canAccessDay(13) && vm.canAccessDay(14) && !vm.canAccessDay(15))
    }

    @Test func aStartIsHeldToTheThirtyFourDays() {
        let vm = viewModel()
        vm.startConsecration(startingAt: 90)
        #expect(vm.todaysDayNumber == 34)
        let early = viewModel()
        early.startConsecration(startingAt: -4)
        #expect(early.todaysDayNumber == 1)
    }

    @Test func theDayCountsOnFromTheStartAndStopsAtTheConsecration() {
        #expect(ConsecrationProgress(startDate: daysAgo(9)).currentDayNumber == 10)
        #expect(ConsecrationProgress(startDate: daysAgo(200)).currentDayNumber == 34)
        #expect(ConsecrationProgress(startDate: Calendar.current.date(byAdding: .day, value: 5, to: .now)!).currentDayNumber == 1,
                "a start chosen ahead waits on day one")
    }

    // MARK: Praying the days

    @Test func aDayPrayedIsKeptWithItsReflection() throws {
        let vm = viewModel()
        vm.startConsecration(startingAt: 3)
        vm.completeDay(dayNumber: 3, journalEntry: "Emptying myself of the world.")
        #expect(vm.isDayCompleted(3))
        #expect(!vm.isDayCompleted(2))

        let kept = try entries()
        #expect(kept.count == 1)
        #expect(kept.first?.consecrationDay == 3)
        #expect(kept.first?.consecrationId == vm.progress?.id)
        #expect(kept.first?.text == "Emptying myself of the world.")
    }

    @Test func anEmptyReflectionKeepsNothing() throws {
        let vm = viewModel()
        vm.startConsecration(on: .now)
        vm.completeDay(dayNumber: 1, journalEntry: "   \n ")
        #expect(vm.isDayCompleted(1))
        #expect(try entries().isEmpty)
    }

    @Test func aDraftIsRewrittenNotDoubled() throws {
        let vm = viewModel()
        vm.startConsecration(on: .now)
        vm.saveReflectionDraft("First thought", for: 1)
        vm.saveReflectionDraft("Second thought", for: 1)
        #expect(try entries().map(\.text) == ["Second thought"])
        #expect(vm.journalText == "Second thought")
    }

    @Test func aDaysReflectionComesBackWhenTheDayIsOpened() {
        let vm = viewModel()
        vm.startConsecration(startingAt: 5)
        vm.saveReflectionDraft("On day four", for: 4)
        vm.loadDay(5)
        #expect(vm.journalText.isEmpty)
        vm.loadDay(4)
        #expect(vm.currentDay?.dayNumber == 4)
        #expect(vm.journalText == "On day four")
    }

    @Test func aDayNotYetReachedCannotBeOpened() {
        let vm = viewModel()
        vm.startConsecration(startingAt: 5)
        vm.loadDay(20)
        #expect(vm.currentDay?.dayNumber == 5)
    }

    @Test func theDayOfConsecrationClosesIt() {
        let vm = viewModel()
        vm.startConsecration(startingAt: 34)
        vm.completeDay(dayNumber: 34, journalEntry: "Totus tuus.")
        #expect(!vm.hasActiveConsecration)
        #expect(vm.completedProgress?.isCompleted == true)
        #expect(vm.completedProgress?.completedAt != nil)

        // Read back afresh, the finished one is remembered and none is under way
        let again = viewModel()
        again.loadProgress()
        #expect(again.progress == nil)
        #expect(again.completedProgress != nil)
    }

    @Test func theCompletedDaysAreStoredInOrder() {
        let progress = ConsecrationProgress()
        progress.completeDay(3)
        progress.completeDay(1)
        progress.completeDay(2)
        progress.completeDay(0)
        progress.completeDay(35)
        #expect(progress.completedDaysRaw == "1,2,3", "days out of range are not kept")
        #expect(!progress.isCompleted)
    }

    // MARK: Two consecrations, and the reflections of each

    @Test func aSecondConsecrationDoesNotReadTheFirstsReflections() {
        let first = viewModel()
        first.startConsecration(startingAt: 34)
        first.saveReflectionDraft("The first time", for: 2)
        first.completeDay(dayNumber: 34, journalEntry: "")

        let second = viewModel()
        second.startConsecration(startingAt: 2)
        second.loadDay(2)
        #expect(second.journalText.isEmpty, "a reflection belongs to its own consecration")
    }

    @Test func anUnscopedReflectionIsClaimedByTheConsecrationItWasWrittenIn() throws {
        let progress = ConsecrationProgress(startDate: daysAgo(4))
        context.insert(progress)
        let orphan = JournalEntry(text: "Written before scoping", consecrationDay: 2,
                                  consecrationPhase: .preparatory, createdAt: daysAgo(3))
        context.insert(orphan)
        try context.save()

        let vm = viewModel()
        vm.loadProgress()
        #expect(orphan.consecrationId == progress.id)
        vm.loadDay(2)
        #expect(vm.journalText == "Written before scoping")
    }

    // MARK: Putting it down

    @Test func abandoningClearsTheConsecration() throws {
        let vm = viewModel()
        vm.startConsecration(startingAt: 6)
        vm.abandonConsecration()
        #expect(vm.progress == nil)
        #expect(vm.currentDay == nil)
        #expect(try context.fetch(FetchDescriptor<ConsecrationProgress>()).isEmpty)
    }
}
