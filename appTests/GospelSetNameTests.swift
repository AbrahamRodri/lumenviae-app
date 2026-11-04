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
}
