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

    /// A prayer the table does not name (one added to the book later)
    /// still hangs a painting rather than nothing
    @Test func aPrayerWithNoScenePaintsSomething() {
        #expect(SavedPrayerPainting.scene(of: "no_such_prayer") == nil)
        #expect(PrayerBookPainting.prayer("no_such_prayer") == PrayerBookPainting.saved)
    }

    /// Every scene names a prayer the book prints, so a misspelt id
    /// never leaves its prayer under its topic's painting unnoticed
    @Test func everySceneNamesAPrayer() {
        #expect(SavedPrayerPainting.scened.isSubset(of: Set(PrayerBook.prayers.keys)))
        for id in SavedPrayerPainting.scened {
            #expect(SavedPrayerPainting.of(id) == PrayerBookPainting.scenes[id], "\(id)")
        }
    }

    /// Every prayer the book prints has a scene of its own
    @Test func everyPrayerHasAScene() {
        let missing = Set(PrayerBook.prayers.keys).subtracting(SavedPrayerPainting.scened)
        #expect(missing.isEmpty, "\(missing.sorted())")
    }

    /// A topic's prayers are swiped through one card at a time, so no two
    /// side by side hang the same painting
    @Test func noTwoNeighboursInATopicShareAPainting() {
        for chapter in PrayerBook.chapters {
            for (a, b) in zip(chapter.prayerIDs, chapter.prayerIDs.dropFirst()) {
                #expect(PrayerBookPainting.prayer(a).asset != PrayerBookPainting.prayer(b).asset, "\(chapter.id): \(a), \(b)")
            }
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
