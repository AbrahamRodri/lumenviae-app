//
//  VoiceCaptionTests.swift
//  appTests
//
//  The line under every choice of voice: the voice reads the spoken
//  prayers and meditations, and a chant has one singer.
//

import Foundation
import Testing

@testable import app

struct VoiceCaptionTests {

    @Test func theCaptionSaysChantsHaveOneSinger() {
        #expect(UserSettings.narrationVoiceCaption == "For spoken prayers and meditations. Chants have one singer.")
    }

    @Test func theCaptionHasItsSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))
        let key = "For spoken prayers and meditations. Chants have one singer."
        #expect(
            spanish.localizedString(forKey: key, value: nil, table: nil)
                == "Para las oraciones habladas y las meditaciones. Los cantos tienen un solo cantor.")
    }
}
