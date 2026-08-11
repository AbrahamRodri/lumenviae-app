//
//  TrueDevotionBook.swift
//  Lumen Viae
//
//  Models for the full text of St. Louis de Montfort's "True Devotion to
//  the Blessed Virgin" (Fr. Faber's 1862 translation, public domain).
//
//  Loading lives in TrueDevotionLibrary; these are pure data. The text is
//  generated from Tools/TrueDevotion — see the README there.
//
//  Declared nonisolated so the book can be decoded off the main actor at
//  launch — these carry no UI state and are immutable once decoded.
//

import Foundation

// MARK: - TrueDevotionBook

nonisolated struct TrueDevotionBook: Decodable {
    let title: String
    let author: String
    let translator: String
    let sourceNote: String
    let parts: [TrueDevotionPart]
    let chapters: [TrueDevotionChapter]

    func chapter(id: String) -> TrueDevotionChapter? {
        chapters.first { $0.id == id }
    }

    func chapterIndex(id: String) -> Int? {
        chapters.firstIndex { $0.id == id }
    }

    /// The chapter that follows the given one, or nil for the last chapter.
    func chapter(after id: String) -> TrueDevotionChapter? {
        guard let index = chapterIndex(id: id), index + 1 < chapters.count else { return nil }
        return chapters[index + 1]
    }
}

// MARK: - TrueDevotionPart

nonisolated struct TrueDevotionPart: Decodable, Identifiable {
    /// 1 or 2; chapters with part 0 (the Introduction) belong to no part
    let number: Int
    let title: String

    var id: Int { number }
}

// MARK: - TrueDevotionChapter

nonisolated struct TrueDevotionChapter: Decodable, Identifiable {
    /// Stable slug ("introduction", "motives", …) — persisted in reading
    /// progress, so it must never change once shipped.
    let id: String
    let part: Int
    let title: String
    let paragraphs: [TrueDevotionParagraph]

    /// Rounded-up estimate at a contemplative ~200 words per minute.
    /// Counted once while decoding — the chapter list asks every row for
    /// this on each render, and counting words walks the whole book.
    let estimatedMinutes: Int

    /// The paragraph that gets the illuminated initial
    let firstTextParagraphID: Int?

    private enum CodingKeys: String, CodingKey {
        case id, part, title, paragraphs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        part = try container.decode(Int.self, forKey: .part)
        title = try container.decode(String.self, forKey: .title)
        paragraphs = try container.decode([TrueDevotionParagraph].self, forKey: .paragraphs)

        let words = paragraphs.reduce(0) { $0 + $1.text.split(separator: " ").count }
        estimatedMinutes = max(1, Int((Double(words) / 200.0).rounded(.up)))
        firstTextParagraphID = paragraphs.first { $0.kind == .text }?.id
    }
}

// MARK: - TrueDevotionParagraph

nonisolated struct TrueDevotionParagraph: Decodable, Identifiable, Equatable {
    nonisolated enum Kind: String, Decodable {
        case text
        case subheading
    }

    /// Index within the chapter — stable because chapter content is static
    let id: Int
    let kind: Kind
    let text: String
}

