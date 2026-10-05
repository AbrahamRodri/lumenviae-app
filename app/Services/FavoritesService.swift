//
//  FavoritesService.swift
//  Lumen Viae
//
//  Remembers which meditation sets the user has starred. Favorited sets
//  are pinned to the top of the meditation picker so a daily companion
//  set is always one tap away, no matter how large the library grows.
//
//  Favorites are a user preference, so they live on-device (UserDefaults),
//  not in the content API.
//

import Foundation

@Observable
final class FavoritesService {

    static let shared = FavoritesService()

    private static let storageKey = "userSettings.favoriteMeditationSets"

    /// IDs of favorited meditation sets
    private(set) var ids: Set<Int>

    /// Where the stars are kept; nil for preview instances, whose
    /// toggles never touch UserDefaults
    private let defaults: UserDefaults?

    private convenience init() {
        self.init(defaults: .standard)
    }

    /// Reads and keeps the stars in `defaults`
    init(defaults: UserDefaults) {
        self.defaults = defaults
        let stored = defaults.array(forKey: Self.storageKey) as? [Int] ?? []
        ids = Set(stored)
    }

    /// In-memory instance seeded with favorites, for previews
    init(previewFavorites: Set<Int>) {
        defaults = nil
        ids = previewFavorites
    }

    func isFavorite(_ id: Int) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: Int) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        defaults?.set(Array(ids), forKey: Self.storageKey)
    }
}
