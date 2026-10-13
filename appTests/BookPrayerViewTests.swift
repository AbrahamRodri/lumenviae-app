//
//  BookPrayerViewTests.swift
//  appTests
//
//  The door at the foot of a prayer's page names its topic as a reader
//  would say it after "All 11".
//

import Testing

@testable import app

struct BookPrayerViewTests {

    @Test func theDoorDropsTheTopicsLeadingArticle() throws {
        let first = try #require(PrayerBook.chapter("first"))
        #expect(first.topic == "The First Prayers")
        #expect(BookPrayerView.doorName(of: first) == "First Prayers")
    }

    @Test func theDoorKeepsAnyOtherTopicAsItIs() throws {
        let mary = try #require(PrayerBook.chapter("our_lady"))
        #expect(BookPrayerView.doorName(of: mary) == mary.topic)
    }
}
