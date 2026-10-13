//
//  LearnByHeartSnapshotTests.swift
//  appTests
//
//  The Learn by Heart sheet drawn at its steps, from the Our Father,
//  whose painting is bundled. The prayer's Learned mark is read from the
//  shared store, so each test sets it as it needs and puts it back.
//

import SwiftUI
import Testing

@testable import app

@Suite(
    "Learn by Heart snapshots",
    .serialized,
    .enabled(if: ScreenSnapshot.isRecordedRuntime, ScreenSnapshot.skipReason)
)
struct LearnByHeartSnapshotTests {

    init() async {
        await ScreenSnapshot.preloadPaintings()
    }

    private static let prayerID = "our_father"

    /// Draws the sheet with the prayer marked as learned or not, and
    /// leaves the store as it found it
    private func assertSheet(
        at stage: LearnByHeartSheet.Stage,
        learned: Bool,
        named name: String,
        testName: String = #function
    ) throws {
        let prayer = try #require(PrayerBook.prayer(Self.prayerID))
        let store = PrayerBookStore.shared
        let was = store.isByHeart(Self.prayerID)
        store.setByHeart(Self.prayerID, learned)
        defer { store.setByHeart(Self.prayerID, was) }

        ScreenSnapshot.assertScreen(
            LearnByHeartSheet(prayer: prayer, stage: stage),
            named: name,
            testName: testName
        )
    }

    @Test func read() throws {
        try assertSheet(at: .read, learned: false, named: "learn-by-heart-read")
    }

    @Test func someHidden() throws {
        try assertSheet(at: .someHidden, learned: false, named: "learn-by-heart-some-hidden")
    }

    @Test func firstLetters() throws {
        try assertSheet(at: .firstLetters, learned: false, named: "learn-by-heart-first-letters")
    }

    @Test func byHeart() throws {
        try assertSheet(at: .byHeart, learned: false, named: "learn-by-heart-by-heart")
    }

    @Test func learned() throws {
        try assertSheet(at: .byHeart, learned: true, named: "learn-by-heart-learned")
    }
}

@Suite("Learn by Heart steps")
struct LearnByHeartStepTests {

    @Test func onlyTheMiddleStepsCarryALine() {
        #expect(LearnByHeartSheet.Stage.read.hint == nil)
        #expect(LearnByHeartSheet.Stage.someHidden.hint == "Touch a word to see it.")
        #expect(LearnByHeartSheet.Stage.firstLetters.hint == "Say it from the first letters.")
        #expect(LearnByHeartSheet.Stage.byHeart.hint == nil)
    }

    @Test func stepsAreFourInOrder() {
        #expect(LearnByHeartSheet.Stage.allCases.map(\.label) == ["Read", "Some hidden", "First letters", "By heart"])
    }
}
