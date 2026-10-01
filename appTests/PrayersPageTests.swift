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
import SwiftUI
import Testing
@testable import app

@MainActor
struct PrayersPageTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func at(_ hour: Int, _ year: Int = 2026, _ month: Int = 9, _ day: Int = 24) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func moment(_ hour: Int, _ minute: Int, day: Int = 24) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
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
            "Angels and Saints", "Through the Day", "Confession", "For Those Who Have Died",
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
        #expect(PrayerBook.standing(of: morning, at: at(21), offered: false, calendar: calendar) == .at("On waking"))
        #expect(PrayerBook.standing(of: night, at: at(12), offered: false, calendar: calendar) == .at("At bedtime"))
        #expect(PrayerBook.standing(of: angelus, at: at(8), offered: false, calendar: calendar) == .at("At noon"))
    }

    @Test func theAngelusIsNamedForTheBellBeingKept() {
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        #expect(PrayerBook.hourName(of: angelus, at: at(12), calendar: calendar) == "Noon")
        #expect(PrayerBook.hourName(of: angelus, at: at(17), calendar: calendar) == "Evening")
        // The noon bell is still to come
        #expect(PrayerBook.hourName(of: angelus, at: at(8), calendar: calendar) == "Noon")
        #expect(PrayerBook.standing(of: angelus, at: at(8), offered: false, calendar: calendar) == .at("At noon"))
        // The evening's is kept until the day turns at four
        #expect(PrayerBook.hourName(of: angelus, at: at(21), calendar: calendar) == "Evening")
        #expect(PrayerBook.standing(of: angelus, at: at(21), offered: false, calendar: calendar) == .at("At 6 PM"))
    }

    @Test func anOfferedAngelusIsNamedForTheBellItKept() {
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        // The strip's name and its OFFERED, as the station reads them
        func station(at now: Date, last: Date) -> String {
            let offered = PrayerBook.isOfferedNow(angelus, at: now, offeredToday: true, lastOffered: last, calendar: calendar)
            let name = PrayerBook.hourName(of: angelus, at: now, calendar: calendar)
            return offered ? "\(name) · Prayed" : name
        }
        let sixInTheEvening = at(18)

        // Prayed at the evening bell: EVENING through the night, never NOON offered
        #expect(station(at: at(21), last: sixInTheEvening) == "Evening · Prayed")
        #expect(station(at: moment(0, 30, day: 25), last: sixInTheEvening) == "Evening · Prayed")
        // Prayed at noon, by evening it is the evening bell's turn to ask
        #expect(station(at: at(21), last: at(12)) == "Evening")
    }

    @Test func anAngelusAtTheMorningBellCountsForTheDayNotForNoon() {
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        let sixInTheMorning = moment(6, 2)
        func offered(at now: Date) -> Bool {
            PrayerBook.isOfferedNow(angelus, at: now, offeredToday: true, lastOffered: sixInTheMorning, calendar: calendar)
        }

        // The middle station is noon's, still to come
        #expect(!offered(at: moment(6, 5)))
        #expect(!offered(at: at(10)))
        #expect(!offered(at: at(12)))
        #expect(PrayerBook.hourName(of: angelus, at: moment(6, 5), calendar: calendar) == "Noon")

        // The day's measure still counts it, as the Chapel's rule reads it
        let defaults = UserDefaults(suiteName: "PrayersPageTests.morningBell")!
        defaults.removePersistentDomain(forName: "PrayersPageTests.morningBell")
        let store = PrayerBookStore(defaults: defaults)
        store.markOffered(PrayerBook.angelusOrderID, on: sixInTheMorning)
        #expect(store.wasOffered(PrayerBook.angelusOrderID, on: at(12)))
        #expect(store.wasOffered(PrayerBook.angelusOrderID, on: at(21)))
        defaults.removePersistentDomain(forName: "PrayersPageTests.morningBell")
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

    // MARK: Search

    @Test func aSearchFindsAPrayerByTheStartsOfItsWords() {
        func found(_ needle: String) -> [String] { PrayerBook.search(needle).map(\.id) }

        #expect(found("St Michael").contains("st_michael_prayer"))
        #expect(found("saint michael").contains("st_michael_prayer"))
        #expect(found("St. Michael").contains("st_michael_prayer"))
        #expect(found("Loreto").contains("litany_loreto"))
        #expect(found("salve regina").contains("hail_holy_queen"))
        #expect(found("St Joseph").contains("ad_te_beate_ioseph"))
        #expect(found("St Joseph").contains("litany_st_joseph"))
        #expect(found("hail ma").first == "hail_mary")
        #expect(found("zzqx").isEmpty)
        // The Latin's ligatures written out
        #expect(found("regina caeli").contains("regina_caeli"))
        #expect(found("praesidium").contains("sub_tuum"))
        // A lone "st" is a saint or the start of a word
        #expect(found("st").contains("st_michael_prayer"))
        #expect(found("st").contains("stabat_mater"))
        #expect(!found("saint").contains("stabat_mater"))
    }

    @Test func aSearchNamesTheOrdersPrayedTogether() {
        #expect(PrayerBook.searchOrders("blessed sacrament").map(\.id).contains("visit"))
        #expect(PrayerBook.searchOrders("visiting").map(\.id) == ["visit"])
        #expect(PrayerBook.searchOrders("ma").isEmpty)
    }

    @Test func aListNamesAPrayerAsPeopleSayIt() {
        #expect(PrayerBook.prayer("hail_mary")?.listTitle == "Hail Mary")
        #expect(PrayerBook.prayer("memorare")?.listTitle == "Memorare")
        #expect(PrayerBook.prayer("litany_loreto")?.listTitle == "Litany of Loreto")
        #expect(PrayerBook.prayer("st_michael_prayer")?.listTitle == "St Michael")
        // A prayer with no shorter name keeps its own
        #expect(PrayerBook.prayer("sub_tuum")?.listTitle == PrayerBook.prayer("sub_tuum")?.title)
    }

    // MARK: The Angelus's two bells

    @Test func theAngelusIsOfferedForItsBellNotItsDay() {
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        let night = PrayerBook.order(PrayerBook.nightOrderID)!
        func offered(_ order: PrayerOrder, at now: Date, last: Date?, today: Bool = true) -> Bool {
            PrayerBook.isOfferedNow(order, at: now, offeredToday: today, lastOffered: last, calendar: calendar)
        }
        let noon = calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 12, minute: 10))!

        // Prayed at noon: offered until three, and the evening bell asks again
        #expect(offered(angelus, at: at(13), last: noon))
        #expect(!offered(angelus, at: at(17), last: noon))
        // Prayed at the evening bell: offered through the night, past midnight
        #expect(offered(angelus, at: at(21), last: at(18)))
        #expect(offered(angelus, at: at(1, 2026, 9, 25), last: at(18)))
        // Not prayed today, whatever the moment says
        #expect(!offered(angelus, at: at(13), last: noon, today: false))
        // The other hours keep the day's offering alone
        #expect(offered(night, at: at(22), last: nil))
    }

    @Test func theStoreKeepsTheMomentBesideTheDay() {
        let defaults = UserDefaults(suiteName: "PrayersPageTests.store")!
        defaults.removePersistentDomain(forName: "PrayersPageTests.store")
        let store = PrayerBookStore(defaults: defaults)
        let moment = Date()

        #expect(store.lastOffered(PrayerBook.angelusOrderID) == nil)
        store.markOffered(PrayerBook.angelusOrderID, on: moment)
        #expect(store.wasOffered(PrayerBook.angelusOrderID, on: moment))
        #expect(store.lastOffered(PrayerBook.angelusOrderID) == moment)
        // Read back from the defaults, to within the store's own precision
        let kept = PrayerBookStore(defaults: defaults).lastOffered(PrayerBook.angelusOrderID)
        #expect(kept.map { abs($0.timeIntervalSince(moment)) < 0.001 } == true)

        defaults.removePersistentDomain(forName: "PrayersPageTests.store")
    }

    @Test func eachHourIsSummedUpInOnePlainLine() {
        let morning = PrayerBook.order(PrayerBook.morningOrderID)!
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        let night = PrayerBook.order(PrayerBook.nightOrderID)!
        let table = PrayerBook.order("table")!

        #expect(PrayerBook.daySummary(of: angelus, on: at(12)) == "A short prayer to Mary, said at 6 AM, noon and 6 PM.")
        #expect(PrayerBook.daySummary(of: angelus, on: at(12, 2026, 4, 12)).contains("Easter"))
        #expect(PrayerBook.daySummary(of: morning, on: at(7)) == "A few short prayers on waking, giving the day to God.")
        // Night Prayers close on the antiphon the season sings
        #expect(PrayerBook.daySummary(of: night, on: at(22)) == "Look back on the day, ask God's forgiveness, and end with this season's song to Mary: Hail, Holy Queen.")
        #expect(PrayerBook.daySummary(of: night, on: at(22, 2026, 12, 20)).hasSuffix("Loving Mother of the Redeemer."))
        #expect(PrayerBook.daySummary(of: night, on: at(22, 2026, 4, 12)).hasSuffix("Queen of Heaven."))
        // Any other order is its own detail
        #expect(PrayerBook.daySummary(of: table) == table.detail)
    }

    // MARK: Plain words

    @Test func everySurfaceSaysTheHourInTheSameWords() {
        let morning = PrayerBook.order(PrayerBook.morningOrderID)!
        let angelus = PrayerBook.order(PrayerBook.angelusOrderID)!
        let night = PrayerBook.order(PrayerBook.nightOrderID)!

        // Home's row and the Chapel's tile read these
        #expect(PrayerBook.dayOrderMoment(at: at(7), calendar: calendar) == "On waking")
        #expect(PrayerBook.dayOrderMoment(at: at(12), calendar: calendar) == "At noon")
        #expect(PrayerBook.dayOrderMoment(at: at(17), calendar: calendar) == "At 6 PM")
        #expect(PrayerBook.dayOrderMoment(at: at(22), calendar: calendar) == "At bedtime")
        // and the Prayers page's strip says the same of an hour not yet come
        #expect(PrayerBook.standing(of: morning, at: at(22), offered: false, calendar: calendar)
                == .at(PrayerBook.dayOrderMoment(at: at(7), calendar: calendar)))
        #expect(PrayerBook.standing(of: angelus, at: at(22), offered: false, calendar: calendar)
                == .at(PrayerBook.dayOrderMoment(at: at(17), calendar: calendar)))
        #expect(PrayerBook.standing(of: night, at: at(7), offered: false, calendar: calendar)
                == .at(PrayerBook.dayOrderMoment(at: at(22), calendar: calendar)))
    }

    @Test func theSongsToMaryAreNamedAsTheirPrayersAre() {
        for antiphon in MarianAntiphon.allCases {
            #expect(PrayerBook.prayer(antiphon.prayerID)?.listTitle == antiphon.name)
            // The seasons in plain dates, never the calendar's Latin
            for word in ["Purification", "Trinity", "Eastertide"] {
                #expect(!antiphon.season.contains(word))
            }
        }
    }

    @Test func aPrayersNameIsNeverSetTwice() {
        for prayer in PrayerBook.prayers.values {
            if let second = prayer.secondTitle {
                #expect(!PrayerBook.isSameName(second, prayer.title), "\(prayer.id) names itself twice")
            }
        }
        #expect(PrayerBook.prayer("memorare")?.secondTitle == "Remember, O most gracious Virgin Mary")
        #expect(PrayerBook.prayer("tantum_ergo")?.title == "Down in Adoration Falling")
        #expect(PrayerBook.prayer("tantum_ergo")?.secondTitle == "Tantum Ergo")
        #expect(PrayerBook.isSameName("The Memorare", "memorare"))
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
