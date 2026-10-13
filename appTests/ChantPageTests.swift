//
//  ChantPageTests.swift
//  appTests
//
//  A chant's own page: the Learn card's words for each place a learner
//  can stand, the tools capsule's tools, and what the ⋯ menu offers.
//

import Testing

@testable import app

@Suite("Chant page")
struct ChantPageTests {

    @Test func learnWordsForEachPlace() {
        let notBegun = ChantView.learnWords(learned: false, step: nil)
        #expect(notBegun.title == "Learn this chant")
        #expect(notBegun.note == "Four steps: listen, read along, sing along, on your own")

        let underWay = ChantView.learnWords(learned: false, step: .readAlong)
        #expect(underWay.title == "Continue learning")
        #expect(underWay.note == "Step 2 of 4 · Read along")

        // Learned outranks a step left behind
        let learned = ChantView.learnWords(learned: true, step: .singAlong)
        #expect(learned.title == "Practise again")
        #expect(learned.note == "Learned")
    }

    @Test func takeTurnsOnlyForTimedChants() throws {
        let timed = try #require(ChantCatalog.chant("salve_regina_simple"))
        #expect(timed.hasLines)
        #expect(NowPlayingTools.tools(for: timed) == [.again, .speed, .takeTurns, .sleep])

        var untimed = timed
        untimed.lines = []
        #expect(NowPlayingTools.tools(for: untimed) == [.again, .speed, .sleep])
    }

    @Test func stopLearningOnlyWhileUnderWay() {
        #expect(
            ChantView.MoreItem.items(stepUnderWay: false)
                == [.favourite, .addToSet, .words, .enlargeScore, .source])
        #expect(
            ChantView.MoreItem.items(stepUnderWay: true)
                == [.favourite, .addToSet, .words, .enlargeScore, .stopLearning, .source])
    }
}
