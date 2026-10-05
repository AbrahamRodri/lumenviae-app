//
//  MissalAndNotesTests.swift
//  Lumen Viae Tests
//
//  The Missal's day rules — the Gloria silent in violet, black and rose,
//  the Credo on Sundays and the greater feasts, the Asperges at a sung
//  Sunday Mass — and its page built from the day's propers whatever
//  they turn out to hold; then the What's New notes, the reading goal's
//  words, and a set pinned on the shelf.
//

import Foundation
import Testing
@testable import app

@MainActor
struct MissalDayRulesTests {

    private func info(rank: Int? = 3, colors: [String]? = ["w"]) throws -> MissalInfo {
        var json: [String: Any] = ["title": "A Day"]
        if let rank { json["rank"] = rank }
        if let colors { json["colors"] = colors }
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(MissalInfo.self, from: data)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // 4 October 2026 is a Sunday, the 5th a Monday
    private var sunday: Date { date(2026, 10, 4) }
    private var monday: Date { date(2026, 10, 5) }

    @Test func theGloriaFallsAwayWithThePenitentialColours() throws {
        #expect(MissalOrderData.saysGloria(try info(colors: ["w"])))
        #expect(MissalOrderData.saysGloria(try info(colors: ["r"])))
        #expect(!MissalOrderData.saysGloria(try info(colors: ["v"])))
        #expect(!MissalOrderData.saysGloria(try info(colors: ["b"])))
        #expect(!MissalOrderData.saysGloria(try info(colors: ["p"])), "rose stands in for violet")
    }

    @Test func withNothingKnownTheGloriaIsSaid() throws {
        #expect(MissalOrderData.saysGloria(nil))
        #expect(MissalOrderData.saysGloria(try info(colors: nil)))
    }

    @Test func theCredoBelongsToSundaysAndTheGreaterFeasts() throws {
        #expect(MissalOrderData.saysCredo(try info(rank: 4), date: sunday))
        #expect(MissalOrderData.saysCredo(try info(rank: 1), date: monday))
        #expect(MissalOrderData.saysCredo(try info(rank: 2), date: monday))
        #expect(!MissalOrderData.saysCredo(try info(rank: 3), date: monday))
        #expect(!MissalOrderData.saysCredo(nil, date: monday))
    }

    @Test func theAspergesOpensOnlyASungSundayMass() {
        #expect(MissalOrderData.saysAsperges(date: sunday, highMass: true))
        #expect(!MissalOrderData.saysAsperges(date: sunday, highMass: false))
        #expect(!MissalOrderData.saysAsperges(date: monday, highMass: true))
    }

    @Test func thePropersAreKeptInTheOrderServed() throws {
        let propers = [
            MissalSection(id: "Introitus", label: "Introit", body: [["Gaudeamus", "Let us rejoice"]]),
            MissalSection(id: "Oratio", label: "Collect", body: [["Deus", "O God"]]),
            MissalSection(id: "Strange Rite", label: "Something New", body: [["x", "y"]]),
            MissalSection(id: "Evangelium", label: "Gospel", body: [["In illo", "At that time"]])
        ]
        for scope in MissalScope.allCases {
            let sections = MissalOrderData.readerSections(
                propers: propers, ordo: [], scope: scope,
                info: try info(), date: sunday, highMass: true
            )
            // With no Ordo on hand the page is the day's texts alone
            #expect(sections.map(\.id) == ["proper-0", "proper-1", "proper-2", "proper-3"])
            #expect(sections.map(\.section.body) == propers.map(\.body))
            #expect(sections[0].latinName == "Introitus")
            #expect(sections[2].englishName == "Something New", "an unknown section keeps the API's own name")
        }
    }

    @Test func noPropersAndNoOrdoIsAnEmptyPage() throws {
        let sections = MissalOrderData.readerSections(
            propers: [], ordo: [], scope: .full, info: nil, date: monday, highMass: false
        )
        #expect(sections.isEmpty)
    }
}

@MainActor
struct WhatsNewNotesTests {

    @Test func aVersionWithNoNotesShowsNothing() {
        #expect(WhatsNewRelease.release(for: "0.1") == nil)
        #expect(WhatsNewRelease.release(for: "4.0.1") == nil, "a point release has no notes of its own")
    }

    @Test func theFourOhNotesNameWhatItAdded() throws {
        let release = try #require(WhatsNewRelease.release(for: "4.0"))
        #expect(release.items.map(\.title) == [
            "Prayers", "The Chant Library", "The Rosary Said Aloud", "How to Pray the Rosary"
        ])
    }

    @Test func everyRowIsADoorWithItsWords() {
        for release in WhatsNewRelease.all {
            let titles = release.items.map(\.title)
            #expect(Set(titles).count == titles.count, "\(release.version) names a thing twice")
            for item in release.items {
                #expect(!item.detail.isEmpty && !item.icon.isEmpty)
                // No counts, no durations, no marketing gloss
                #expect(!item.detail.lowercased().contains("minute"), "\(item.title)")
                #expect(!item.detail.contains("!"), "\(item.title)")
            }
        }
    }

    @Test func eachVersionHasOneSetOfNotes() {
        let versions = WhatsNewRelease.all.map(\.version)
        #expect(Set(versions).count == versions.count)
    }
}

@MainActor
struct ReadingGoalTests {

    @Test func theMinutesOfEachGoal() {
        #expect(ReadingGoal.fewMinutes.minutes == 5)
        #expect(ReadingGoal.quarterHour.minutes == 15)
        #expect(ReadingGoal.halfHour.minutes == 30)
        #expect(ReadingGoal.chapterADay.minutes == nil)
    }

    @Test func aGoalIsReadBackByItsKeyOrItsOldWords() {
        for goal in ReadingGoal.allCases {
            #expect(ReadingGoal.stored(goal.rawValue) == goal)
            // A goal stored by its sentence before keys were stable
            #expect(ReadingGoal.stored(goal.title) == goal)
        }
        #expect(ReadingGoal.stored("an hour of reading") == nil)
    }

    @Test func aGoalNeverCountsAgainstTheReader() {
        for goal in ReadingGoal.allCases {
            let words = (goal.title + goal.readingPhrase).lowercased()
            #expect(!words.contains("streak") && !words.contains("missed"))
        }
    }
}

@MainActor
struct PinnedSetsTests {

    @Test func aSetIsPinnedAndLetGo() {
        let favorites = FavoritesService(previewFavorites: [3])
        #expect(favorites.isFavorite(3))
        #expect(!favorites.isFavorite(7))
        favorites.toggle(7)
        #expect(favorites.isFavorite(7))
        favorites.toggle(3)
        #expect(!favorites.isFavorite(3))
        #expect(favorites.ids == [7])
    }

    @Test func aPreviewNeverWritesToTheReadersPins() {
        let key = "userSettings.favoriteMeditationSets"
        let before = UserDefaults.standard.array(forKey: key) as? [Int]
        let favorites = FavoritesService(previewFavorites: [])
        favorites.toggle(987_654)
        #expect(UserDefaults.standard.array(forKey: key) as? [Int] == before)
    }
}
