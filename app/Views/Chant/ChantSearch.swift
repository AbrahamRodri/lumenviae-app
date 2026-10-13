//
//  ChantSearch.swift
//  Lumen Viae
//
//  The chant library's word search, kept from its retired search page:
//  the practice reads its cleaning of a sung line, and the tests hold its
//  folding and matching.
//

import SwiftUI

// MARK: - ChantSearch

/// The library's search, apart from its page so it can be tested: the
/// folding, the grouping into works, the hits in the words, and the
/// highlighting.
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

    /// The setting a hit in the words was sung in, named where its work
    /// has more than one, as Titles names it with its pill: the simple
    /// and the solemn Salve Regina would otherwise give rows that read
    /// alike. A hit in the Prayer Book's text is the words of every
    /// setting, quoted once, and names none
    static func setting(of hit: WordHit) -> String? {
        guard hit.line != nil, hit.chant.settings.count > 1 else { return nil }
        return hit.chant.settingName
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

    /// Works whose Latin or English title holds `needle`, or every work
    /// when it is empty, the chants the filter passes
    static func works(matching needle: String, where passes: (Chant) -> Bool) -> [Work] {
        let chants = ChantCatalog.all.filter { chant in
            guard passes(chant) else { return false }
            guard !needle.isEmpty else { return true }
            return fold(chant.latinTitle).contains(needle) || fold(chant.englishTitle).contains(needle)
        }
        return group(chants)
    }

    /// Works that sing a prayer whose name, in the Prayer Book, holds
    /// `needle`: "glory be" finds the Gloria Patri
    static func works(singingPrayerMatching needle: String, where passes: (Chant) -> Bool) -> [Work] {
        guard !needle.isEmpty else { return [] }
        let chants = ChantCatalog.all.filter { chant in
            guard passes(chant), let prayer = chant.bookPrayer else { return false }
            return fold(prayer.title).contains(needle) || fold(prayer.latinTitle ?? "").contains(needle)
        }
        return group(chants)
    }

    /// Every line of every chant's words holding `needle`: a timed
    /// chant's own lines, with their place; else the lines of the Prayer
    /// Book's text, with none
    static func wordHits(matching needle: String, where passes: (Chant) -> Bool) -> [WordHit] {
        guard needle.count >= 3 else { return [] }
        var hits: [WordHit] = []
        var seenTexts = Set<String>()
        for chant in ChantCatalog.all where passes(chant) {
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

    /// Where the folded `needle` stands in `text`, as ranges of the text
    /// as written: a match on "caeli" is the range of "Cæli"
    static func matches(in text: String, needle: String) -> [Range<String.Index>] {
        guard !needle.isEmpty else { return [] }

        // Each folded character remembers the character it came from
        var folded: [Character] = []
        var origin: [String.Index] = []
        for index in text.indices {
            for character in fold(String(text[index])) {
                folded.append(character)
                origin.append(index)
            }
        }
        let pattern = Array(needle)
        guard !pattern.isEmpty, folded.count >= pattern.count else { return [] }

        var ranges: [Range<String.Index>] = []
        var i = 0
        while i <= folded.count - pattern.count {
            if Array(folded[i..<(i + pattern.count)]) == pattern {
                let lower = origin[i]
                let upper = text.index(after: origin[i + pattern.count - 1])
                ranges.append(lower..<upper)
                i += pattern.count
            } else {
                i += 1
            }
        }
        return ranges
    }

    /// `text` with every match of the folded `needle` underlined in gold
    static func highlighted(_ text: String, needle: String) -> AttributedString {
        let ranges = matches(in: text, needle: needle)
        guard !ranges.isEmpty else { return AttributedString(text) }

        var result = AttributedString()
        var cursor = text.startIndex
        for range in ranges where range.lowerBound >= cursor {
            result += AttributedString(String(text[cursor..<range.lowerBound]))
            var match = AttributedString(String(text[range]))
            // Typed, so the attributes are SwiftUI's and not UIKit's
            match.foregroundColor = AppColors.goldLight as Color
            match.underlineStyle = Text.LineStyle(pattern: .solid)
            result += match
            cursor = range.upperBound
        }
        result += AttributedString(String(text[cursor...]))
        return result
    }
}
