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

    /// False for preview/test instances so toggles never touch UserDefaults
    private let persists: Bool

    private init() {
        persists = true
        let stored = UserDefaults.standard.array(forKey: Self.storageKey) as? [Int] ?? []
        ids = Set(stored)
    }

    /// In-memory instance seeded with favorites, for previews and tests
    init(previewFavorites: Set<Int>) {
        persists = false
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
        if persists {
            UserDefaults.standard.set(Array(ids), forKey: Self.storageKey)
        }
    }
}
