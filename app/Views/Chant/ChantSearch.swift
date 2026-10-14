//
//  ChantSearch.swift
//  Lumen Viae
//
//  How a chant is found by what it sings: by the prayer it sings and by
//  a line of its words. The one search (`AppSearch.chantHits`) lists
//  these after the chants found by name. Every name and line is folded
//  once (`SearchText.fold`), the first time anything is searched, so a
//  keystroke only compares.
//

import Foundation

// MARK: - ChantSearch

/// Finding chants by what they sing
enum ChantSearch {

    /// What one chant is searched by, folded once
    private struct Entry {
        let chant: Chant
        /// The names of the prayer it sings, in the Prayer Book
        let prayerNames: [String]
        /// Its words a line at a time: a timed chant's own lines, Latin and
        /// English; else the lines of the Prayer Book's text, quoted under
        /// the first untimed chant that sings it and no other
        let lines: [String]
    }

    private static let entries: [Entry] = {
        var quoted = Set<String>()
        return ChantCatalog.all.map { chant in
            let prayer = chant.bookPrayer
            let names = [prayer?.title, prayer?.latinTitle].compactMap { $0 }.map(SearchText.fold)
            var lines: [String] = []
            if chant.hasLines {
                lines = chant.lines.flatMap { [SearchText.fold($0.latin), SearchText.fold($0.english)] }
            } else if let prayer, quoted.insert(prayer.id).inserted {
                lines = ((prayer.latin ?? "") + "\n" + prayer.english)
                    .components(separatedBy: "\n")
                    .map(SearchText.clean)
                    .filter { !$0.isEmpty }
                    .map(SearchText.fold)
            }
            return Entry(chant: chant, prayerNames: names, lines: lines)
        }
    }()

    /// Chants that sing a prayer whose name, in the Prayer Book, holds
    /// `needle` (folded): "glory be" finds the Gloria Patri. The settings
    /// of one work stand together, in the catalog's order.
    static func chants(singingPrayerMatching needle: String) -> [Chant] {
        guard !needle.isEmpty else { return [] }
        let found = entries.filter { $0.prayerNames.contains { $0.contains(needle) } }.map(\.chant)
        var order: [String] = []
        var byWork: [String: [Chant]] = [:]
        for chant in found {
            if byWork[chant.workKey] == nil { order.append(chant.workKey) }
            byWork[chant.workKey, default: []].append(chant)
        }
        return order.flatMap { byWork[$0] ?? [] }
    }

    /// Chants with a line of their words holding `needle` (folded), in
    /// the catalog's order. Fewer than three letters find no words: every
    /// chant has "a".
    static func chants(withWordsMatching needle: String) -> [Chant] {
        guard needle.count >= 3 else { return [] }
        return entries.filter { $0.lines.contains { $0.contains(needle) } }.map(\.chant)
    }
}
