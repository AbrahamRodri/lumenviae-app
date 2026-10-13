//
//  SavedPrayerPaintingTests.swift
//  Lumen Viae Tests
//
//  The painting a kept prayer stands under on Saved: the scene the book
//  names for it, else its topic's, so the shelf is not one painting
//  over and over.
//

import Testing
@testable import app

@MainActor
struct SavedPrayerPaintingTests {

    @Test func aPrayerWithAScenePaintsItsScene() {
        #expect(SavedPrayerPainting.of("memorare") == PrayerBookPainting.prayer("memorare"))
        #expect(SavedPrayerPainting.of("hail_mary").asset == "joyful_annunciation")
    }

    @Test func aPrayerWithNoScenePaintsItsTopic() throws {
        let topic = try #require(PrayerBook.homeChapter(of: "anima_christi"))
        #expect(SavedPrayerPainting.of("anima_christi") == PrayerBookPainting.topic(topic))
        #expect(SavedPrayerPainting.of("anima_christi") != PrayerBookPainting.prayer("anima_christi"))
    }

    @Test func everyPrayerHasAPainting() {
        for id in PrayerBook.prayers.keys {
            #expect(!SavedPrayerPainting.of(id).asset.isEmpty, "\(id) has no painting")
        }
    }
}
