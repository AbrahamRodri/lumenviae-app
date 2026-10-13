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
        let topic = try #require(PrayerBook.homeChapter(of: "act_of_faith"))
        #expect(SavedPrayerPainting.scene(of: "act_of_faith") == nil)
        #expect(SavedPrayerPainting.of("act_of_faith") == PrayerBookPainting.topic(topic))
        #expect(PrayerBookPainting.prayer("act_of_faith") == PrayerBookPainting.topic(topic))
    }

    /// Every scene names a prayer the book prints, so a misspelt id
    /// never leaves its prayer under its topic's painting unnoticed
    @Test func everySceneNamesAPrayer() {
        #expect(SavedPrayerPainting.scened.isSubset(of: Set(PrayerBook.prayers.keys)))
        for id in SavedPrayerPainting.scened {
            #expect(SavedPrayerPainting.of(id) == PrayerBookPainting.scenes[id], "\(id)")
        }
    }

    /// The Coronation hangs only over a prayer to Our Lady as Queen
    @Test func theCoronationIsOnlyForTheQueen() {
        let crowned = PrayerBook.prayers.keys.filter { PrayerBookPainting.prayer($0).asset == "glorious_coronation" }
        #expect(Set(crowned) == ["hail_holy_queen"])
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
