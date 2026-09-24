//
//  ConsecrationReading.swift
//  Lumen Viae
//
//  One reading of a consecration day.
//
//  Montfort's plan gives most days more than one: a Gospel passage and a
//  spiritual reading from The Imitation of Christ or True Devotion. They
//  are separate texts from separate works, so each carries its own
//  citation and its own attribution — a day that opens on Luke and closes
//  on Montfort must not be credited to Montfort alone.
//

import Foundation

struct ConsecrationReading: Codable, Identifiable, Hashable {

    /// Position within its day, 1-based — and its identity, since a day
    /// never repeats a reading.
    let order: Int

    /// What the reading is: "Luke 13:1-5", "Imitation of Christ, Book 2,
    /// Chapter 5", "True Devotion, Nos. 81-82".
    let title: String

    /// The reading itself
    let text: String

    /// The work this reading alone comes from — "Douay-Rheims Bible",
    /// "Thomas à Kempis", "St. Louis de Montfort". Never a merged pair.
    let source: String?

    var id: Int { order }

    init(order: Int, title: String, text: String, source: String? = nil) {
        self.order = order
        self.title = title
        self.text = text
        self.source = source
    }
}
