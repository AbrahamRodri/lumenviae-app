//
//  BundledBooksAndBilingualTests.swift
//  Lumen Viae Tests
//
//  The texts the app carries with no signal: True Devotion to Mary,
//  read from its generated JSON as the reader reads it, and every
//  bilingual prayer of the Rosary and the consecration paired line for
//  line in all four ways the reader can choose — Latin under English,
//  English under Latin, either alone — never falling back to two blocks.
//

import Foundation
import Testing
@testable import app

@MainActor
struct TrueDevotionBookTests {

    private func book() throws -> TrueDevotionBook {
        try #require(TrueDevotionLibrary.shared.book, "TrueDevotionBook.json did not decode")
    }

    @Test func theBookIsFabersTranslation() throws {
        let book = try book()
        #expect(book.author.contains("Montfort"))
        #expect(book.translator.contains("Faber"), "never the modern translation, which is in copyright")
        #expect(!book.chapters.isEmpty)
    }

    @Test func chapterIdsAreUniqueAndFoundInOrder() throws {
        let book = try book()
        let ids = book.chapters.map(\.id)
        #expect(Set(ids).count == ids.count, "a mark keyed by chapter would land in two places")
        for (index, chapter) in book.chapters.enumerated() {
            #expect(book.chapterIndex(id: chapter.id) == index)
            #expect(book.chapter(id: chapter.id)?.title == chapter.title)
        }
    }

    @Test func eachChapterLeadsToTheNextAndTheLastToNone() throws {
        let book = try book()
        for (index, chapter) in book.chapters.enumerated().dropLast() {
            #expect(book.chapter(after: chapter.id)?.id == book.chapters[index + 1].id)
        }
        #expect(book.chapter(after: book.chapters.last!.id) == nil)
        #expect(book.chapter(after: "no-such-chapter") == nil)
    }

    @Test func everyChapterStandsInAPartTheBookNames() throws {
        // Part 0 is the front matter — the Introduction — which the
        // contents page sets apart from both parts
        let book = try book()
        let parts = Set(book.parts.map(\.number))
        for chapter in book.chapters where chapter.part != 0 {
            #expect(parts.contains(chapter.part), "\(chapter.id) is in part \(chapter.part)")
        }
        let frontMatter = book.chapters.prefix { $0.part == 0 }.count
        #expect(book.chapters.filter { $0.part == 0 }.count == frontMatter, "front matter only before Part I")
        let numbered = book.chapters.map(\.part).filter { $0 != 0 }
        #expect(numbered == numbered.sorted(), "the parts run in order")
    }

    @Test func paragraphIdsAreTheirPlaceInTheChapter() throws {
        // Marks are keyed chapterID:paragraph, so a paragraph's id must
        // be its stable index
        for chapter in try book().chapters {
            #expect(chapter.paragraphs.map(\.id) == Array(chapter.paragraphs.indices), "\(chapter.id)")
        }
    }

    @Test func everyChapterHasTextAndItsVersalKnowsWhere() throws {
        for chapter in try book().chapters {
            let first = try #require(chapter.firstTextParagraphID, "\(chapter.id) has no text")
            #expect(chapter.paragraphs[first].kind == .text)
            #expect(chapter.paragraphs.prefix(first).allSatisfy { $0.kind == .subheading })
            #expect(chapter.paragraphs.allSatisfy { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty })
        }
    }
}

@MainActor
struct BilingualPrayerPairingTests {

    private var prayers: [BilingualConsecrationPrayer] {
        RosaryPrayers.all + Array(BilingualConsecrationPrayers.allPrayers.values)
    }

    @Test func everyBilingualPrayerPairsLineForLine() {
        for prayer in prayers where !prayer.content.latin.isEmpty {
            let english = prayer.content.english.components(separatedBy: "\n").count
            let latin = prayer.content.latin.components(separatedBy: "\n").count
            #expect(english == latin, "\(prayer.id) pairs \(english) English lines with \(latin) Latin")
        }
    }

    @Test func eitherLanguageAloneIsThatLanguage() {
        for prayer in prayers {
            #expect(prayer.formattedContent(for: .english) == prayer.content.english)
            #expect(prayer.formattedContent(for: .latin) == prayer.content.latin)
            #expect(prayer.displayTitle(for: .english) == prayer.englishTitle)
            #expect(prayer.displayTitle(for: .latin) == prayer.latinTitle)
        }
    }

    @Test func bothLanguagesInterleaveWithTheChosenOneFirst() {
        let text = BilingualText(english: "Hail Mary,\n\nAmen.", latin: "Ave Maria,\n\nAmen.")
        #expect(text.formatted(for: .both) == "Ave Maria,|||Hail Mary,\n\nAmen.")
        #expect(text.formatted(for: .latinUnderEnglish) == "Hail Mary,|||Ave Maria,\n\nAmen.")
    }

    @Test func unpairedTextFallsBackToTwoBlocksRatherThanLosingOne() {
        let text = BilingualText(english: "One\nTwo", latin: "Unus")
        #expect(text.formatted(for: .both) == "Unus\n\nOne\nTwo")
    }

    @Test func noBundledPrayerFallsBackToTwoBlocks() {
        for prayer in prayers where !prayer.content.latin.isEmpty {
            for language in [PrayerLanguage.both, .latinUnderEnglish] {
                let formatted = prayer.formattedContent(for: language)
                #expect(formatted.contains("|||"), "\(prayer.id) in \(language.rawValue) is not paired")
            }
        }
    }

    @Test func everyPrayerIsFoundByItsId() {
        for prayer in prayers {
            #expect(DevotionPrayers.find(prayer.id) != nil, "\(prayer.id)")
        }
        let rosaryIDs = RosaryPrayers.all.map(\.id)
        #expect(Set(rosaryIDs).count == rosaryIDs.count)
    }
}
