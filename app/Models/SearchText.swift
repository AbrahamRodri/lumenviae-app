//
//  SearchText.swift
//  Lumen Viae
//
//  How the app's searches read text: case and accents aside, and the
//  ligatures the Latin is printed with written out, so "regina caeli"
//  finds the Regina Cæli and "coeli" the Cœli. One rule, so a chant and
//  a prayer are found by the same words.
//

import Foundation

nonisolated enum SearchText {

    /// Case, accents and the ligatures aside: "Cæli" and "caeli" fold
    /// alike. A character is never dropped, so a match in the folded text
    /// can be traced back to the words as written.
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "ae")
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "oe")
    }

    /// A search as typed, folded and trimmed: what a title is searched for
    static func needle(_ query: String) -> String {
        fold(query).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A line of a prayer or a chant as words alone: the versicle and
    /// response marks, the cross, the line-pair marker and a canticle's
    /// pointing taken out, a rubric line dropped whole, the spaces closed
    /// up. Words in, words out, touching nothing else.
    static func clean(_ line: String) -> String {
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
