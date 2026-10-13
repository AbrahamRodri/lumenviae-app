//
//  PrayerSet.swift
//  Lumen Viae
//
//  The prayers a prayer's page deals through, one card after another:
//  the topic or the order of prayer it was opened from, and the place in
//  it. Opened from anywhere else, the page deals through the prayer's own
//  topic (`PrayerBook.homeChapter`).
//

import Foundation

/// The topic or order a prayer was opened from
enum PrayerSet: Hashable {
    case topic(String)
    /// The order, and the place in it of the prayer tapped: an order may
    /// say a prayer twice, and the deal must go on from the one tapped
    case order(String, at: Int)
}

/// The prayers a prayer's page deals through, its name over the card,
/// and where the page opens among them
struct PrayerDeck: Equatable {
    /// The prayers in the order they are dealt
    let ids: [String]
    /// The set's name as the card's kicker sets it, "PRAYERS TO MARY"
    let name: String
    /// What "All 6" says to VoiceOver: "All 6, Before Confession"
    let doorName: String
    /// Where the page opens, or nil for a prayer outside every set
    let start: Int?
    /// The topic the "All" door opens when the page was not opened from
    /// its set's own page; nil when it was, and Back already goes there
    let topicToOpen: String?

    /// The deck for a prayer opened from `set` (or, with none, from a door
    /// outside the book's pages), on `date`, which decides an order's
    /// prayers in its seasons
    static func of(_ prayerID: String, in set: PrayerSet?, on date: Date) -> PrayerDeck {
        switch set {
        case .order(let id, let at):
            if let order = PrayerBook.order(id) {
                let ids = order.prayerIDs(date)
                let start = ids.indices.contains(at) && ids[at] == prayerID ? at : ids.firstIndex(of: prayerID)
                let title = order.title(on: date)
                return PrayerDeck(ids: ids, name: title.uppercased(), doorName: title, start: start, topicToOpen: nil)
            }
        case .topic(let id):
            if let chapter = PrayerBook.chapter(id) {
                return topic(chapter, for: prayerID, opensItsPage: false)
            }
        case nil:
            break
        }
        guard let home = PrayerBook.homeChapter(of: prayerID) else {
            return PrayerDeck(ids: [], name: "", doorName: "", start: nil, topicToOpen: nil)
        }
        return topic(home, for: prayerID, opensItsPage: true)
    }

    /// The orders that say each of `prayerIDs` on `date`, by order id, in
    /// the book's order of the orders
    static func ordersSaying(_ prayerIDs: [String], on date: Date) -> [String: [String]] {
        let wanted = Set(prayerIDs)
        var saying: [String: [String]] = [:]
        for order in PrayerBook.orders {
            for id in Set(order.prayerIDs(date)) where wanted.contains(id) {
                saying[id, default: []].append(order.id)
            }
        }
        return saying
    }

    private static func topic(_ chapter: PrayerBookChapter, for prayerID: String, opensItsPage: Bool) -> PrayerDeck {
        let ids = chapter.prayerIDs
        let name = chapter.topic.isEmpty ? chapter.title : chapter.topic
        // "All 11 First Prayers", where the topic's own name, "The First
        // Prayers", read "All 11 The First Prayers"
        let door = name.hasPrefix("The ") ? String(name.dropFirst(4)) : name
        return PrayerDeck(
            ids: ids,
            name: name.uppercased(),
            doorName: door,
            start: ids.firstIndex(of: prayerID),
            topicToOpen: opensItsPage ? chapter.id : nil
        )
    }
}
