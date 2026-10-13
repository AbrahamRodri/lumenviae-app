//
//  BookPrayerViewTests.swift
//  appTests
//
//  The door at the foot of a prayer's card names its set as a reader
//  would say it after "All 11".
//

import Foundation
import Testing

@testable import app

struct BookPrayerViewTests {

    @Test func theDoorDropsTheTopicsLeadingArticle() throws {
        let first = try #require(PrayerBook.chapter("first"))
        #expect(first.topic == "The First Prayers")
        let id = try #require(first.prayerIDs.first)
        #expect(PrayerDeck.of(id, in: .topic(first.id), on: Date()).doorName == "First Prayers")
    }

    @Test func theDoorKeepsAnyOtherTopicAsItIs() throws {
        let mary = try #require(PrayerBook.chapter("our_lady"))
        let id = try #require(mary.prayerIDs.first)
        #expect(PrayerDeck.of(id, in: .topic(mary.id), on: Date()).doorName == mary.topic)
    }
}
