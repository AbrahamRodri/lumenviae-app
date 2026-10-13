//
//  ChantPracticeWords.swift
//  Lumen Viae
//
//  The words a chant is practised from: the Prayer Book's grammar made
//  plain lines to sing from, and some or all of them cut to their first
//  letter for singing from memory.
//

import Foundation

/// How much of the words is hidden, for singing from memory
enum ChantHiding: CaseIterable {
    case none, half, all

    var title: String {
        switch self {
        case .none: return "None"
        case .half: return "Half"
        case .all:  return "All"
        }
    }
}

enum ChantPracticeWords {

    /// `text` with every other word, or every word, cut to its first
    /// letter — as the Prayer Book's learning by heart does
    static func hidden(_ text: String, _ hiding: ChantHiding) -> String {
        guard hiding != .none else { return text }
        var index = 0
        return text.components(separatedBy: "\n").map { line in
            line.components(separatedBy: " ").map { word -> String in
                defer { index += 1 }
                guard word.count > 1, hiding == .all || index % 2 == 1 else { return word }
                let letters = word.filter(\.isLetter)
                guard let first = letters.first else { return word }
                let trailing = word.last.map { $0.isLetter ? "" : String($0) } ?? ""
                return String(first) + String(repeating: "·", count: max(1, letters.count - 1)) + trailing
            }
            .joined(separator: " ")
        }
        .joined(separator: "\n")
    }

    /// The Prayer Book's grammar as plain lines to sing from
    static func plain(_ text: String) -> String {
        text.components(separatedBy: "\n")
            .map(SearchText.clean)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
