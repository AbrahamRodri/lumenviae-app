//
//  ResourcePagesDataTests.swift
//  Lumen Viae Tests
//
//  The resource pages' bundled content holding together: In Scripture's
//  key verse for every mystery, split from its citation; How to Pray's
//  steps, each naming prayers the app can open, and the counts a
//  beginner is told agreeing with the Rosary the strand counts; St.
//  Carlo's timeline and rule of life, every door opening a reading.
//

import Foundation
import Testing
@testable import app

@MainActor
struct InScriptureDataTests {

    private var keys: [String] {
        MysteryCategory.allCases.flatMap { category in
            MysteryData.mysteries(for: category).map { "\(category.rawValue)_\($0.order)" }
        }
    }

    @Test func everyMysteryHasAKeyVerseAndNoOtherDoes() {
        #expect(Set(MysteriesInScriptureData.keyVerses.keys) == Set(keys))
    }

    @Test func aKeyVerseIsSplitFromItsCitation() throws {
        let verse = try #require(MysteriesInScriptureData.keyVerse("joyful_2"))
        #expect(verse.text == "Blessed art thou among women, and blessed is the fruit of thy womb.")
        #expect(verse.citation == "Luke 1:42")
        #expect(MysteriesInScriptureData.keyVerse("joyful_6") == nil)
    }

    @Test func everyKeyVerseIsCited() {
        for key in keys {
            let verse = MysteriesInScriptureData.keyVerse(key)
            #expect(verse?.citation.range(of: #"^[1-4 ]*[A-Z][A-Za-z ]+ \d+:\d+"#, options: .regularExpression) != nil,
                    "\(key) has no citation")
            #expect(!(verse?.text.isEmpty ?? true))
        }
    }

    @Test func sevenGracesForTheSevenSorrows() {
        #expect(MysteriesInScriptureData.sevenGraces.count == 7)
    }
}

@MainActor
struct HowToPrayDataTests {

    @Test func theStepsRunInOrder() {
        #expect(HowToPrayData.steps.map(\.id) == Array(1...HowToPrayData.steps.count))
        #expect(HowToPrayData.steps.first?.prayerIDs == ["sign_of_cross"])
    }

    @Test func everyPrayerAStepNamesCanBeOpened() {
        for step in HowToPrayData.steps {
            for id in step.prayerIDs {
                let found = DevotionPrayers.find(id) != nil || PrayerBook.prayer(id) != nil
                #expect(found, "step \(step.id) names \(id), which is nowhere")
            }
        }
    }

    @Test func everyPrayerTaughtIsToldHowOftenItIsSaid() {
        let taught = Set(HowToPrayData.steps.flatMap(\.prayerIDs))
        #expect(taught.isSubset(of: Set(HowToPrayData.prayerCounts.keys)))
        for id in HowToPrayData.prayerCounts.keys {
            #expect(DevotionPrayers.find(id) != nil || PrayerBook.prayer(id) != nil, "\(id)")
        }
    }

    @Test func theCountsAgreeWithFiveDecades() {
        // Fifty-three Hail Marys and six Our Fathers in five decades and the pendant
        #expect(HowToPrayData.prayerCounts["hail_mary"]?.hasPrefix("Fifty-three") == true)
        #expect(HowToPrayData.prayerCounts["our_father"]?.hasPrefix("Six") == true)
        #expect(HowToPrayData.prayerCounts["fatima_prayer"]?.hasPrefix("Five") == true)
        let decades = 5, beadsPerDecade = 10, pendantHailMarys = 3
        #expect(decades * beadsPerDecade + pendantHailMarys == 53)
    }

    @Test func theCourseHasMethodsAndQuestions() {
        #expect(!HowToPrayData.methods.entries.isEmpty)
        #expect(!HowToPrayData.questions.entries.isEmpty)
    }
}

@MainActor
struct CarloAcutisDataTests {

    @Test func everyMomentAndHabitOpensAReading() {
        for moment in CarloAcutisData.timeline {
            #expect(LibraryReadings.locate(id: moment.readingID) != nil, "\(moment.year) opens \(moment.readingID)")
        }
        for habit in CarloAcutisData.rule {
            #expect(LibraryReadings.locate(id: habit.readingID) != nil, "\(habit.name) opens \(habit.readingID)")
        }
    }

    @Test func theTimelineRunsForward() {
        let years = CarloAcutisData.timeline.compactMap { Int($0.year) }
        #expect(years.count == CarloAcutisData.timeline.count)
        #expect(years == years.sorted())
        #expect(years.first == 1991)
    }

    @Test func aHabitWithAnActNamesIt() {
        for habit in CarloAcutisData.rule {
            #expect((habit.act == nil) == (habit.actTitle == nil), "\(habit.name)")
        }
    }

    @Test func oneSayingADayFromTheCatalog() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
        for offset in 0..<366 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            #expect(CarloAcutisData.sayings.indices.contains(CarloAcutisData.sayingOfTheDay(date)))
        }
        let morning = calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 7))!
        let night = calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 23))!
        #expect(CarloAcutisData.sayingOfTheDay(morning) == CarloAcutisData.sayingOfTheDay(night), "the same all day")
    }

    @Test func hisFeastIsKeptOffTheMissal() {
        #expect(!CarloAcutisData.feast.inMissal, "raised to the altars after 1962")
        #expect(CarloAcutisData.feast.calendarNote != nil)
    }
}
