//
//  TrueDevotionBook.swift
//  Lumen Viae
//
//  Models for the full text of St. Louis de Montfort's "True Devotion to
//  the Blessed Virgin" (Fr. Faber's 1862 translation, public domain),
//  decoded from the bundled TrueDevotionBook.json resource.
//

import Foundation

// MARK: - TrueDevotionBook

struct TrueDevotionBook: Decodable {
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

    var totalWordCount: Int {
        chapters.reduce(0) { $0 + $1.wordCount }
    }
}

// MARK: - TrueDevotionPart

struct TrueDevotionPart: Decodable, Identifiable {
    /// 1 or 2; chapters with part 0 (the Introduction) belong to no part
    let number: Int
    let title: String

    var id: Int { number }
}

// MARK: - TrueDevotionChapter

struct TrueDevotionChapter: Decodable, Identifiable {
    /// Stable slug ("introduction", "motives", …) — persisted in reading
    /// progress, so it must never change once shipped.
    let id: String
    let part: Int
    let title: String
    let paragraphs: [TrueDevotionParagraph]

    var wordCount: Int {
        paragraphs.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }

    /// Rounded-up estimate at a contemplative ~200 words per minute
    var estimatedMinutes: Int {
        max(1, Int((Double(wordCount) / 200.0).rounded(.up)))
    }
}

// MARK: - TrueDevotionParagraph

struct TrueDevotionParagraph: Decodable, Identifiable, Equatable {
    enum Kind: String, Decodable {
        case text
        case subheading
    }

    /// Index within the chapter — stable because chapter content is static
    let id: Int
    let kind: Kind
    let text: String
}

// MARK: - TrueDevotionBookData

enum TrueDevotionBookData {

    /// The decoded book, loaded once. Nil only if the bundled resource is
    /// missing or corrupt, which is a build error rather than a runtime
    /// condition — views fall back to an empty state.
    static let book: TrueDevotionBook? = load()

    private static func load() -> TrueDevotionBook? {
        guard let url = Bundle.main.url(forResource: "TrueDevotionBook", withExtension: "json") else {
            assertionFailure("TrueDevotionBook.json missing from bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(TrueDevotionBook.self, from: data)
        } catch {
            assertionFailure("TrueDevotionBook.json failed to decode: \(error)")
            return nil
        }
    }
}
