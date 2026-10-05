//
//  FavoritesServiceTests.swift
//  Lumen Viae Tests
//
//  The meditation sets the reader has pinned: a tap pins and a second
//  unpins, the pins outlive a launch, and a preview's pins never reach
//  the reader's own.
//

import Foundation
import Testing
@testable import app

@MainActor
struct FavoritesServiceTests {

    private let defaults = UserDefaults(suiteName: "FavoritesServiceTests.\(UUID().uuidString)")!

    @Test func aTapPinsAndASecondUnpins() {
        let favorites = FavoritesService(defaults: defaults)
        favorites.toggle(7)
        #expect(favorites.isFavorite(7))
        favorites.toggle(7)
        #expect(!favorites.isFavorite(7))
    }

    @Test func thePinsOutliveALaunch() {
        let favorites = FavoritesService(defaults: defaults)
        favorites.toggle(3)
        favorites.toggle(9)
        #expect(FavoritesService(defaults: defaults).ids == [3, 9])
    }

    @Test func aPreviewsPinsAreKeptNowhere() {
        let preview = FavoritesService(previewFavorites: [1])
        preview.toggle(2)
        #expect(preview.ids == [1, 2])
        #expect(FavoritesService(defaults: defaults).ids.isEmpty)
    }
}
