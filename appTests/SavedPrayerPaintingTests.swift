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
        #expect(SavedPrayerPainting.scene(of: "anima_christi") == nil)
        #expect(SavedPrayerPainting.of("anima_christi") == PrayerBookPainting.topic(topic))
    }

    /// Every prayer's painting is one the app carries, so no card on the
    /// shelf stands empty
    @Test func everyPrayersPaintingLoads() {
        for id in PrayerBook.prayers.keys {
            let painting = SavedPrayerPainting.of(id)
            #expect(ImageCacheService.shared.image(named: painting.resolvedAsset) != nil, "\(id): \(painting.asset)")
        }
    }
}
