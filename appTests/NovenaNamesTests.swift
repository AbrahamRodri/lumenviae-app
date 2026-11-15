//
//  NovenaNamesTests.swift
//  appTests
//
//  A novena day is named one way: "Day 4 of 9 · Undoer of Knots" under
//  the opening prayers' title and over Go to.
//

import Foundation
import Testing

@testable import app

struct NovenaNamesTests {

    @Test func goToNamesTheDayAndTheNovena() throws {
        let day = try #require(NovenaDayContext.resolve(novenaID: "undoer_of_knots", day: 4))
        #expect(day.dayAndName == "Day 4 of 9 · \(day.shortName)")
        #expect(day.goToTitle == day.dayAndName)
        #expect(day.dayAndName.hasPrefix(day.dayLine))
    }
}
