//
//  ConsecrationScheduledTests.swift
//  Lumen Viae
//
//  The road ahead after a feast is chosen: what each part says beneath
//  its name, for every feast the chooser offers.
//

import Foundation
import Testing

@testable import app

@MainActor
struct ConsecrationScheduledTests {

    @Test func consecrationDayNamesEachFeastAsTheChooserDoes() {
        #expect(MarianFeastDay.all.count == 9)
        for feast in MarianFeastDay.all {
            #expect(ConsecrationScheduledView.note(for: .consecrationDay, feast: feast) == feast.name)
        }
    }

    @Test func aDayChosenWithNoFeastSaysNothingUnderConsecrationDay() {
        #expect(ConsecrationScheduledView.note(for: .consecrationDay, feast: nil) == nil)
    }

    @Test func thePartsSayHowLongTheyAre() {
        #expect(ConsecrationScheduledView.note(for: .preparatory, feast: nil) == "Twelve days")
        for week in [ConsecrationPhase.knowledgeOfSelf, .knowledgeOfMary, .knowledgeOfJesus] {
            #expect(ConsecrationScheduledView.note(for: week, feast: nil) == "A week")
        }
    }
}
