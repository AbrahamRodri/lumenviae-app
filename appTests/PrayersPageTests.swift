//
//  PrayersPageTests.swift
//  Lumen Viae Tests
//
//  The Prayers page: every occasion's order stands in one place, the
//  chapters carry their plain names, a search names a topic only when
//  its words name one, the day's three hours say where they stand and
//  never "missed", every painting the page hangs is in the catalog, and
//  a door to the Prayer Book turns to its tab.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayersPageTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func at(_ hour: Int, _ year: Int = 2026, _ month: Int = 9, _ day: Int = 24) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: Occasions

    @Test func everyOccasionsOrderStandsInExactlyOnePlace() {
        let placed = PrayerOccasionPlace.allCases.flatMap(\.orderIDs)
        #expect(Set(placed).count == placed.count, "an order stands in two places")
        #expect(Set(placed) == Set(PrayerBook.occasionOrders.map(\.id)))
        for place in PrayerOccasionPlace.allCases {
            #expect(PrayerBook.ordersKept(at: place).count == place.orderIDs.count, "\(place) names an order the book lacks")
        }
    }

    // MARK: Chapters

    @Test func theChaptersCarryTheirPlainNames() {
        #expect(PrayerBook.chapters.map(\.title) == [
            "Basic Prayers", "Mary", "Jesus", "The Eucharist", "The Holy Spirit",
            "Angels and Saints", "Through the Day", "Confession", "For the Dead",
            "The Church", "Litanies", "Short Prayers"
        ])
        for chapter in PrayerBook.chapters {
            #expect(!chapter.topic.isEmpty, "\(chapter.id) has no topic name")
        }
    }

    @Test func herBestKnownPrayersAreHers() {
        for id in PrayerBook.bestKnownMarianIDs {
            #expect(PrayerBook.prayer(id) != nil, "\(id) is not in the book")
            #expect(PrayerBook.ourLady.prayerIDs.contains(id), "\(id) is not in Mary's chapter")
        }
    }

    // MARK: Topics

    @Test func aSearchNamesATopicOnlyWhenItsWordsNameOne() {
        func topics(_ needle: String) -> [String] { PrayerBook.topics(matching: needle).map(\.id) }

        #expect(topics("mary") == ["our_lady"])
        #expect(topics("Our Lady") == ["our_lady"])
        #expect(topics("holy ghost") == ["holy_ghost"])
        #expect(topics("penance") == ["penance"])
        #expect(topics("dead") == ["departed"])
        #expect(topics("prayers to mary") == ["our_lady"])
        // A prayer's name is the prayer's, not the chapter's
        #expect(topics("hail mary").isEmpty)
        // The small words name nothing
        #expect(topics("the").isEmpty)
        #expect(topics("pra").isEmpty)
        #expect(topics("ma").isEmpty)
    }

    // MARK: The day's three hours

    @Test func theHoursSayWhereTheyStandAndNeverMissed() {
        let morning = PrayerBook.order(PrayerBook.morningOrderID)!
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        let night = PrayerBook.order(PrayerBook.nightOrderID)!

        #expect(PrayerBook.standing(of: angelus, at: at(12), offered: false, calendar: calendar) == .now)
        #expect(PrayerBook.standing(of: angelus, at: at(12), offered: true, calendar: calendar) == .offered)
        // A morning not prayed by night is still said on rising
        #expect(PrayerBook.standing(of: morning, at: at(21), offered: false, calendar: calendar) == .at("On rising"))
        #expect(PrayerBook.standing(of: night, at: at(12), offered: false, calendar: calendar) == .at("At bedtime"))
        #expect(PrayerBook.standing(of: angelus, at: at(8), offered: false, calendar: calendar) == .at("At noon"))
    }

    @Test func theAngelusIsNamedForTheBellThatIsComing() {
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        #expect(PrayerBook.hourName(of: angelus, at: at(12), calendar: calendar) == "Noon")
        #expect(PrayerBook.hourName(of: angelus, at: at(17), calendar: calendar) == "Evening")
        #expect(PrayerBook.hourName(of: angelus, at: at(8), calendar: calendar) == "Noon")
    }

    // MARK: Paintings

    @Test func everyPaintingThePageHangsIsInTheCatalog() {
        var paintings = PrayerBook.dayOrders.flatMap { order in
            [PrayerBookPainting.hour(order, on: at(12)), PrayerBookPainting.hour(order, on: at(12, 2026, 4, 12))]
        }
        paintings += MarianAntiphon.allCases.map { PrayerBookPainting.antiphon($0) }

        for painting in paintings {
            #expect(ImageCacheService.shared.image(named: painting.fallback) != nil, "\(painting.fallback) is not in the catalog")
            #expect(ImageCacheService.shared.image(named: painting.resolvedAsset) != nil)
        }
    }

    // MARK: The tab

    @Test func aDoorToThePrayerBookTurnsToItsTab() {
        let router = AppRouter()
        router.push(.explore)
        router.push(.prayerBook)
        #expect(router.selectedTab == .prayers)
        #expect(router.path.isEmpty)

        // Every other page still pushes
        router.push(.prayerOrder(id: "table"))
        #expect(router.path.count == 1)
    }
}
