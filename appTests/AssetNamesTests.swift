//
//  AssetNamesTests.swift
//  Lumen Viae Tests
//
//  Every glyph and painting the app's data names by string is in the
//  asset catalog. A name with no asset compiles, and draws as nothing —
//  an empty slot where a set's emblem, a door's glyph or a period's
//  painting should be — so the names are checked here against the
//  catalog the app ships, and against the icon audit's rules: devotional
//  glyphs are the app's own families, and no milestone wears a prize.
//

import UIKit
import Testing
@testable import app

@MainActor
struct AssetNamesTests {

    private func missing(_ names: [String]) -> [String] {
        Array(Set(names.filter { UIImage(named: $0) == nil })).sorted()
    }

    // MARK: Glyphs

    @Test func everyMysterySetsGlyphIsInTheCatalog() {
        #expect(missing(MysteryCategory.allCases.map(\.iconName)) == [])
    }

    @Test func everyPrayActsGlyphIsInTheCatalog() {
        let names = MysteryCategory.allCases.flatMap { today in
            PrayerShortcut.allCases.map { $0.icon(today: today) }
        }
        #expect(missing(names) == [])
    }

    @Test func everyMilestonesGlyphIsInTheCatalog() {
        #expect(missing(StreakMilestone.all.map(\.icon)) == [])
    }

    @Test func everyPrayerBookChapterAndOrderGlyphIsInTheCatalog() {
        #expect(missing(PrayerBook.chapters.map(\.icon) + PrayerBook.orders.map(\.icon)) == [])
    }

    @Test func everyReadingShelfAndDoorGlyphIsInTheCatalog() {
        var names = LibraryReadings.shelves.map(\.icon)
        for reading in LibraryReadings.shelves.flatMap(\.entries) {
            for door in reading.doors {
                if case .page(_, let icon, _, _) = door { names.append(icon) }
            }
        }
        names += CarloAcutisData.rule.map(\.icon)
        #expect(missing(names) == [])
    }

    @Test func everyRosaryChoiceAndAfterPrayerGlyphIsInTheCatalog() {
        let names = RosaryChoice.allCases.map(\.icon) + RosaryClosingExtra.allCases.map(\.icon)
        #expect(missing(names) == [])
    }

    @Test func everyWhatsNewRowsGlyphIsInTheCatalog() {
        #expect(missing(WhatsNewRelease.all.flatMap(\.items).map(\.icon)) == [])
    }

    @Test func aDevotionsGlyphIsOneOfTheAppsOwn() {
        // Phosphor is the chrome's; a devotion wears a ch-* or lv-* glyph
        for category in MysteryCategory.allCases {
            #expect(category.iconName.hasPrefix("ch-") || category.iconName.hasPrefix("lv-"), "\(category)")
        }
        for chapter in PrayerBook.chapters where chapter.icon.hasPrefix("ph-") {
            Issue.record("\(chapter.id) wears the chrome's \(chapter.icon)")
        }
    }

    // MARK: Paintings

    @Test func everySetsCardPaintingIsInTheCatalog() {
        #expect(missing(MysteryCategory.allCases.map(\.cardImageName)) == [])
    }

    @Test func everyMysteryHasItsOwnPainting() {
        // The players hang each mystery's painting by its place in its set
        // (`Constants.mysteryImageURL`), not by `Mystery.imageName`, whose
        // mystery_<set>_<n> names no asset carries
        //
        // The chaplet shares two scenes with the Rosary — the Loss of Jesus
        // in the Temple is the Finding's, its Crucifixion the Sorrowful
        // Mysteries' — so a painting is unique within its set, not across
        var names: [String] = []
        for category in MysteryCategory.allCases {
            let count = MysteryData.mysteries(for: category).count
            let set = (0..<count).compactMap { Constants.mysteryImageURL(category: category.rawValue, index: $0) }
            #expect(set.count == count, "\(category) is missing a painting")
            #expect(Set(set).count == count, "two of the \(category) hang the same painting")
            #expect(Constants.mysteryImageURL(category: category.rawValue, index: count) == nil)
            names += set
        }
        #expect(names.count == 27)
        #expect(missing(names) == [])
    }

    @Test func everyConsecrationPeriodsPaintingIsInTheCatalog() {
        #expect(missing(ConsecrationPhase.allCases.map(\.heroImageName)) == [])
    }

    @Test func everyReadingsPaintingIsInTheCatalog() {
        let names = LibraryReadings.shelves.flatMap(\.entries).compactMap(\.painting)
        #expect(missing(names) == [])
    }

    @Test func everyChantPaintingIsInTheCatalog() {
        let names = Array(ChantLibraryData.paintings.values) + ChantSeason.allCases.map(\.painting)
        #expect(missing(names) == [])
    }
}
