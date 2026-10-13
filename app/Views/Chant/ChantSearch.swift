//
//  ChantSearch.swift
//  Lumen Viae
//
//  How a chant is found by what it sings: by the prayer it sings and by
//  a line of its words. The one search (`AppSearch.chantHits`) lists
//  these after the chants found by name, and the practice reads `clean`
//  for a sung line. It came from the library's own search page, retired
//  for the one search.
//

import SwiftUI

// MARK: - ChantSearch

/// Finding chants by what they sing, and a sung line's plain words
enum ChantSearch {

    /// The chants of one work, its settings in the catalog's order
    struct Work {
        let key: String
        let chants: [Chant]
    }

    /// A match in a chant's words: the line it stands in, and where that
    /// line sounds when the chant's lines are timed
    struct WordHit: Identifiable {
        let id: String
        let chant: Chant
        let snippet: String
        /// The line's index in `Chant.lines`, for a timed chant
        let line: Int?
        let start: TimeInterval?
    }

    /// Case, accents and the ligatures aside: "Cæli" and "caeli" fold alike
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
    }

    private static func group(_ chants: [Chant]) -> [Work] {
        var order: [String] = []
        var byKey: [String: [Chant]] = [:]
        for chant in chants {
            if byKey[chant.workKey] == nil { order.append(chant.workKey) }
            byKey[chant.workKey, default: []].append(chant)
        }
        return order.map { Work(key: $0, chants: byKey[$0] ?? []) }
    }

    /// Works that sing a prayer whose name, in the Prayer Book, holds
    /// `needle`: "glory be" finds the Gloria Patri
    static func works(singingPrayerMatching needle: String) -> [Work] {
        guard !needle.isEmpty else { return [] }
        let chants = ChantCatalog.all.filter { chant in
            guard let prayer = chant.bookPrayer else { return false }
            return fold(prayer.title).contains(needle) || fold(prayer.latinTitle ?? "").contains(needle)
        }
        return group(chants)
    }

    /// Every line of every chant's words holding `needle`: a timed
    /// chant's own lines, with their place; else the lines of the Prayer
    /// Book's text, with none
    static func wordHits(matching needle: String) -> [WordHit] {
        guard needle.count >= 3 else { return [] }
        var hits: [WordHit] = []
        var seenTexts = Set<String>()
        for chant in ChantCatalog.all {
            if chant.hasLines {
                for (index, line) in chant.lines.enumerated() {
                    let latin = fold(line.latin).contains(needle)
                    let english = fold(line.english).contains(needle)
                    guard latin || english else { continue }
                    hits.append(WordHit(
                        id: "\(chant.id)#\(index)",
                        chant: chant,
                        snippet: latin ? line.latin : line.english,
                        line: index,
                        start: line.start
                    ))
                }
            } else if let prayer = chant.bookPrayer {
                // A prayer sung in two settings is quoted once, under the
                // first, rather than twice in the same words
                guard !seenTexts.contains(prayer.id) else { continue }
                let lines = ((prayer.latin ?? "") + "\n" + prayer.english).components(separatedBy: "\n")
                var found = false
                for (index, raw) in lines.enumerated() {
                    let text = clean(raw)
                    guard !text.isEmpty, fold(text).contains(needle) else { continue }
                    hits.append(WordHit(id: "\(chant.id)~\(index)", chant: chant, snippet: text, line: nil, start: nil))
                    found = true
                }
                if found { seenTexts.insert(prayer.id) }
            }
        }
        return hits
    }

    /// A line of the Prayer Book's grammar as plain words: the marks of
    /// versicle and response, the pointing and a rubric's brackets gone.
    /// Words in, words out, touching nothing else, so it is called from
    /// anywhere — a function reference to it included.
    nonisolated static func clean(_ line: String) -> String {
        var text = line
        for mark in ["℣.", "℟.", "℣", "℟", "✠", "|||"] {
            text = text.replacingOccurrences(of: mark, with: " ")
        }
        text = text.replacingOccurrences(of: " * ", with: " ")
        if text.hasPrefix("["), text.hasSuffix("]") { return "" }
        return text
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
