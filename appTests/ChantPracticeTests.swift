//
//  ChantPracticeTests.swift
//  appTests
//
//  The words the chant practice says at each moment, how it hides the
//  words for singing from memory, and the line it keeps for CONTINUE.
//

import Foundation
import Testing

@testable import app

@Suite("Chant practice")
struct ChantPracticeTests {

    // MARK: - The gold act

    @Test func theForwardActNamesWhatComesNext() {
        #expect(ChantPracticeView.forwardTitle(step: .listen, timed: true, line: 0, count: 9) == "Next line")
        #expect(ChantPracticeView.forwardTitle(step: .singAlong, timed: true, line: 7, count: 9) == "Next line")
        // A step's last line goes on to the next step
        #expect(ChantPracticeView.forwardTitle(step: .listen, timed: true, line: 8, count: 9) == "Next step")
        #expect(ChantPracticeView.forwardTitle(step: .singAlong, timed: true, line: 8, count: 9) == "Next step")
        // The last line of all is the learner's own word
        #expect(
            ChantPracticeView.forwardTitle(step: .onYourOwn, timed: true, line: 8, count: 9) == "I know it by heart")
        #expect(ChantPracticeView.forwardTitle(step: .onYourOwn, timed: true, line: 3, count: 9) == "Next line")
    }

    @Test func anUntimedChantGoesAStepAtATime() {
        #expect(ChantPracticeView.forwardTitle(step: .listen, timed: false, line: 0, count: 0) == "Next step")
        #expect(
            ChantPracticeView.forwardTitle(step: .onYourOwn, timed: false, line: 0, count: 0) == "I know it by heart")
    }

    // MARK: - The path

    @Test func thePathBeginsContinuesOrPractisesAgain() {
        #expect(ChantPracticeView.pathAction(begun: false, learned: false) == "Begin")
        #expect(ChantPracticeView.pathAction(begun: true, learned: false) == "Continue")
        #expect(ChantPracticeView.pathAction(begun: true, learned: true) == "Practise again")
    }

    @Test func eachStepIsSaidOnceAndDifferently() {
        for timed in [true, false] {
            let notes = ChantLearningStep.allCases.map { ChantPracticeView.note(of: $0, timed: timed) }
            #expect(Set(notes).count == 4)
        }
    }

    // MARK: - The disc

    @Test func theTurnSaysWhoSingsFirst() {
        #expect(ChantPracticeView.turnCaption(step: .singAlong) == "Sing it back")
        #expect(ChantPracticeView.turnCaption(step: .onYourOwn) == "You sing first")
    }

    // MARK: - Hiding

    @Test func halfHidesEveryOtherWordToItsFirstLetter() {
        let hidden = ChantPracticeView.hide("Salve, Regína, Mater misericórdiæ:", .half)
        #expect(hidden == "Salve, R·····, Mater m···········:")
    }

    @Test func allHidesEveryWordButLeavesNoneAlone() {
        #expect(ChantPracticeView.hide("Kýrie, eléison.", .all) == "K····, e······.")
        #expect(ChantPracticeView.hide("Kýrie, eléison.", .none) == "Kýrie, eléison.")
    }

    // MARK: - The kept line

    @Test func theLineIsKeptWithItsStep() throws {
        let defaults = try #require(UserDefaults(suiteName: "ChantPracticeTests.\(UUID().uuidString)"))
        PracticePlace.keep(line: 4, of: "kyrie", on: .singAlong, defaults: defaults)

        #expect(PracticePlace.line(of: "kyrie", on: .singAlong, defaults: defaults) == 4)
        // Stood on another step since, the line no longer means anything
        #expect(PracticePlace.line(of: "kyrie", on: .onYourOwn, defaults: defaults) == nil)
        #expect(PracticePlace.line(of: "gloria", on: .singAlong, defaults: defaults) == nil)

        PracticePlace.forget("kyrie", defaults: defaults)
        #expect(PracticePlace.line(of: "kyrie", on: .singAlong, defaults: defaults) == nil)
    }
}
