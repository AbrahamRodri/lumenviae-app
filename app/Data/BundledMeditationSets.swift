//
//  BundledMeditationSets.swift
//  Lumen Viae
//
//  The meditation sets compiled into the app, one for each set of
//  mysteries, so a Rosary with no signal and nothing downloaded still
//  has a reading at every decade. The server's sets come first on every
//  mysteries' page; these stand after them, and are there whatever the
//  network says. Each carries a negative sentinel ID that no server set
//  can collide with, and `MeditationSetResolver` resolves it from here.
//

import Foundation

enum BundledMeditationSets {

    /// Every bundled set, in the order the categories are listed.
    static let all: [MeditationSet] = [
        JoyfulGospelMeditationData.set,
        SorrowfulEmmerichMeditationData.set,
        GloriousGospelMeditationData.set,
        LuminousMeditationData.set,
        SevenSorrowsLiguoriMeditationData.set
    ]

    /// The picker rows for the bundled sets of one category.
    static func summaries(for category: MysteryCategory) -> [MeditationSetSummary] {
        switch category {
        case .joyful:       return [JoyfulGospelMeditationData.summary]
        case .sorrowful:    return [SorrowfulEmmerichMeditationData.summary]
        case .glorious:     return [GloriousGospelMeditationData.summary]
        case .luminous:     return [LuminousMeditationData.summary]
        case .sevenSorrows: return [SevenSorrowsLiguoriMeditationData.summary]
        }
    }

    /// The bundled sets by their sentinel IDs.
    static let byID: [Int: MeditationSet] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
