//
//  NarrationVoiceNameTests.swift
//  appTests
//
//  A voice named mid-sentence reads in the app's language: the Prayers
//  tab's first question once said "con la voz male" in Spanish.
//

import Foundation
import Testing

@testable import app

struct NarrationVoiceNameTests {

    @Test func theNameInASentenceIsTheDisplayedOneLowered() {
        let male = NarrationVoice(slug: "frederick", name: "Male")
        #expect(male.nameInSentence == male.displayName.lowercased())
        #expect(NarrationVoice(slug: "x", name: "Brother Anselm").nameInSentence == "brother anselm")
    }

    @Test func spanishNamesTheVoiceInSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        let sentence = spanish.localizedString(forKey: "Read to you in the %@ voice", value: nil, table: nil)
        let male = spanish.localizedString(forKey: "Male", value: nil, table: nil).lowercased()
        let female = spanish.localizedString(forKey: "Female", value: nil, table: nil).lowercased()
        #expect(String(format: sentence, male) == "Leída para ti con la voz masculina")
        #expect(String(format: sentence, female) == "Leída para ti con la voz femenina")
    }
}
