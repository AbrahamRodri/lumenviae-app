//
//  SpanishSeedTests.swift
//  Lumen Viae Tests
//
//  The app ships the server's Spanish for the Consecration and the
//  Prayer Book, as it ships the English documents, so a Spanish
//  reader's first launch reads Spanish: the server's copy is fetched
//  that launch and read only at the next.
//

import Foundation
import Testing

@testable import app

struct SpanishSeedTests {

    @Test("The shipped Spanish Consecration covers all 33 days and the day of consecration")
    func theConsecrationsSpanishIsShipped() throws {
        let seed = try #require(LibraryContent.consecrationSpanishStore.seed)
        let numbers = Set(seed.days.map(\.number))
        #expect(numbers.isSuperset(of: Set(1...33)))
        #expect(seed.version != nil)
        #expect(seed.days.allSatisfy { !($0.title ?? "").isEmpty })
    }

    @Test("The shipped Spanish Prayer Book translates the book's prayers")
    func thePrayerBooksSpanishIsShipped() throws {
        let seed = try #require(LibraryContent.prayerBookSpanishStore.seed)
        #expect(seed.version != nil)
        #expect(!seed.translations.isEmpty)
        let ids = Set(LibraryContent.prayerBook.prayers.map(\.id))
        // The server's book may hold a prayer or two newer than the
        // app's English copy; the app passes those over
        let translated = Set(seed.translations.map(\.id))
        #expect(ids.subtracting(translated).isEmpty)
    }
}
