//
//  RecentShelf.swift
//  Lumen Viae
//
//  How a shelf of defaults takes in what the reader actually uses.
//  Explore's Prayers shelf and its Chant tiles start from a list ranked
//  by importance; each thing prayed or sung lately takes one place, the
//  least important default giving way first and the most important last.
//  What the reader used leads the shelf, the latest first, and is marked
//  RECENT; the defaults left follow in their own order. The shelf never
//  grows past its defaults' count and never shows a thing twice.
//

import Foundation

nonisolated enum RecentShelf {

    struct Slot<Item: Hashable>: Hashable {
        let item: Item
        /// Placed for the reader's own use rather than as a default
        let isRecent: Bool
    }

    /// `defaults` most important first; `recents` latest first
    static func fill<Item: Hashable>(defaults: [Item], recents: [Item]) -> [Slot<Item>] {
        let count = defaults.count
        var seen = Set<Item>()
        var slots: [Slot<Item>] = []

        for item in recents where slots.count < count && seen.insert(item).inserted {
            slots.append(Slot(item: item, isRecent: true))
        }
        for item in defaults where slots.count < count && seen.insert(item).inserted {
            slots.append(Slot(item: item, isRecent: false))
        }
        return slots
    }
}
