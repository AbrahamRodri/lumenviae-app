//
//  SpanishTopicNamesTests.swift
//  appTests
//
//  In Spanish the Prayer Book's topics are named in Spanish everywhere a
//  topic is named (its card, its page, search), from the server's
//  chapter_translations; a topic with none keeps its English.
//

import Foundation
import Testing

@testable import app

struct SpanishTopicNamesTests {

    private var seed: PrayerBookTranslations? {
        guard let url = Bundle.main.url(forResource: "prayer_book.es", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(PrayerBookTranslations.self, from: data)
    }

    @Test func everyTopicHasItsSpanishInTheShippedCopy() throws {
        let spanish = try #require(seed).chaptersByID
        for chapter in LibraryContent.prayerBook.chapters {
            let translation = try #require(spanish[chapter.id], "\(chapter.id) has no Spanish")
            #expect(translation.sectionTitles?.count == chapter.sections.count, "\(chapter.id) sub-headings")
        }
    }

    @Test func aTopicIsLaidOverInSpanish() throws {
        let english = try #require(LibraryContent.prayerBook.chapters.first { $0.id == "day" })
        let translations = try #require(seed)
        let spanish = try #require(translations.chaptersByID["day"])
        let chapter = PrayerBook.inSpanish(english, spanish)
        #expect(chapter.title == spanish.title)
        #expect(chapter.topic == spanish.topic)
        #expect(chapter.epigraph == spanish.note)
        #expect(chapter.sections.map(\.title) == spanish.sectionTitles)
        #expect(chapter.sections.map(\.prayerIDs) == english.sections.map(\.prayerIDs))
        #expect(chapter.numeral == english.numeral)
        // Its English names are still found
        #expect(chapter.searchWords.contains(english.title))
    }

    @Test func aTopicWithNoSpanishKeepsItsEnglish() throws {
        let english = try #require(LibraryContent.prayerBook.chapters.first)
        let chapter = PrayerBook.inSpanish(english, nil)
        #expect(chapter.title == english.title)
        #expect(chapter.epigraph == english.note)
        #expect(chapter.sections.map(\.title) == english.sections.map(\.title))
    }

    @Test func anUnreadableTopicListLeavesThePrayersRead() throws {
        let json = #"{"translations":[{"id":"x","title":"X","text":"Amén."}],"chapter_translations":"broken"}"#
        let decoded = try JSONDecoder().decode(PrayerBookTranslations.self, from: Data(json.utf8))
        #expect(decoded.translations.count == 1)
        #expect(decoded.chapterTranslations.isEmpty)
    }
}
