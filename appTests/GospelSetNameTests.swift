//
//  GospelSetNameTests.swift
//  appTests
//
//  The bundled Gospel sets are named in the app's language: a Spanish
//  player read "THE GOSPEL" over the Joyful and Glorious Gospel sets.
//

import Foundation
import Testing

@testable import app

struct GospelSetNameTests {

    @Test func theGospelSetsShareOneName() {
        #expect(JoyfulGospelMeditationData.name == "The Gospel")
        #expect(GloriousGospelMeditationData.name == JoyfulGospelMeditationData.name)
    }

    @Test func theGospelHasItsSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        #expect(spanish.localizedString(forKey: "The Gospel", value: nil, table: nil) == "El Evangelio")
    }

    /// The other bundled sets' names and descriptions follow the app's
    /// language too, and the Spanish descriptions name the Spanish editions
    /// the Spanish text is taken from.
    @Test func theBundledSetsHaveTheirSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        func es(_ key: String) -> String { spanish.localizedString(forKey: key, value: nil, table: nil) }
        #expect(LuminousMeditationData.name == "Traditional Meditations")
        #expect(es(LuminousMeditationData.name) == "Meditaciones tradicionales")
        #expect(es(LuminousMeditationData.description) != LuminousMeditationData.description)
        #expect(es(JoyfulGospelMeditationData.description).contains("Torres Amat"))
        #expect(es(GloriousGospelMeditationData.description).contains("Torres Amat"))
        #expect(es(SorrowfulEmmerichMeditationData.description).contains("Madrid, 1865"))
        #expect(es(SevenSorrowsLiguoriMeditationData.description).contains("1868"))
    }
}
