//
//  ConsecrationAndNumeralsTests.swift
//  Lumen Viae Tests
//
//  The 33-day preparation as the app carries it — de Montfort's four
//  periods (12, 7, 7 and 7 days) and the day of consecration, every day
//  with its readings and every period's prayers really there — the
//  Missal's plain names for a day's rank, and the numbers read out of
//  chapter headings and volunteer-typed track titles.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ConsecrationPreparationTests {

    @Test func thirtyThreeDaysAndTheDayOfConsecration() {
        #expect(ConsecrationData.days.count == 34)
        for (index, day) in ConsecrationData.days.enumerated() {
            #expect(day.dayNumber == index + 1)
        }
    }

    @Test func thePeriodsRunTwelveSevenSevenSevenThenOne() {
        #expect(ConsecrationPhase.allCases.map(\.dayCount) == [12, 7, 7, 7, 1])
        // Contiguous, with no day in two periods and none in none
        for number in 1...34 {
            let phases = ConsecrationPhase.allCases.filter { $0.dayRange.contains(number) }
            #expect(phases.count == 1, "day \(number) belongs to \(phases.count) periods")
        }
        #expect(ConsecrationPhase.phase(for: 0) == nil)
        #expect(ConsecrationPhase.phase(for: 35) == nil)
    }

    @Test func everyDayStandsInItsOwnPeriod() {
        for day in ConsecrationData.days {
            #expect(day.phase == ConsecrationPhase.phase(for: day.dayNumber), "day \(day.dayNumber)")
            #expect(day.phase.dayRange.contains(day.dayNumber))
        }
    }

    @Test func everyDayHasATitleAReadingAndAQuestion() {
        for day in ConsecrationData.days {
            #expect(!day.title.isEmpty, "day \(day.dayNumber)")
            #expect(!day.readings.isEmpty, "day \(day.dayNumber) has nothing to read")
            #expect(!day.journalPrompt.isEmpty, "day \(day.dayNumber) asks nothing")
            for reading in day.readings {
                #expect(!reading.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        "day \(day.dayNumber)'s \(reading.title) is empty")
            }
        }
    }

    @Test func everyPeriodsPrayersAreAllThere() {
        // `prayers(for:)` passes over an id it cannot find, so a missing
        // prayer would leave a day short with nothing said
        for phase in ConsecrationPhase.allCases {
            for language in PrayerLanguage.allCases {
                let prayers = ConsecrationData.prayers(for: phase, language: language)
                #expect(prayers.map(\.id) == phase.prayerIds, "\(phase) in \(language) is missing a prayer")
                for prayer in prayers {
                    #expect(!prayer.content.isEmpty, "\(prayer.id) has no words")
                }
            }
        }
    }

    @Test func aDayIsNamedAsThePageNamesIt() throws {
        let fourteen = try #require(ConsecrationData.day(14))
        #expect(fourteen.dayLabel == "Day 14 of 33")
        #expect(fourteen.ordinalLabel == "Fourteenth Day")
        #expect(fourteen.dayWithinPhase == 2)
        #expect(!fourteen.isConsecrationDay)

        let last = try #require(ConsecrationData.day(34))
        #expect(last.dayLabel == "Consecration Day")
        #expect(last.isConsecrationDay)
        #expect(last.phase == .consecrationDay)

        #expect(ConsecrationData.day(0) == nil)
        #expect(ConsecrationData.day(35) == nil)
    }

    @Test func theFirstDayOfEachPeriodIsItsDayOne() {
        for phase in ConsecrationPhase.allCases {
            let first = ConsecrationData.day(phase.dayRange.lowerBound)
            #expect(first?.dayWithinPhase == 1)
        }
    }

    @Test func everyPeriodHasItsOwnPainting() {
        let paintings = ConsecrationPhase.allCases.map(\.heroImageName)
        #expect(Set(paintings).count == paintings.count)
    }
}

@MainActor
struct DayRankTests {

    @Test func theFourClassesInPlainWords() {
        #expect(DayRank.plainLabel(rank: 1, title: "Nativity of the Lord") == "Great Feast")
        #expect(DayRank.plainLabel(rank: 2, title: "Holy Rosary of the Blessed Virgin Mary") == "Feast")
        #expect(DayRank.plainLabel(rank: 3, title: "St. Francis of Assisi") == "Lesser Feast")
        #expect(DayRank.plainLabel(rank: 4, title: "St. Bruno") == "Weekday")
    }

    @Test func aDayWithNoRankIsNotNamed() {
        #expect(DayRank.plainLabel(rank: nil, title: "Something") == nil)
        #expect(DayRank.plainLabel(rank: 7, title: "Something") == nil)
    }

    @Test func aFeriaIsAWeekdayWhateverItsClass() {
        // Lent's ferias are ranked high, and are still weekdays
        #expect(DayRank.plainLabel(rank: 1, title: "Ash Wednesday") == "Lenten Weekday")
        #expect(DayRank.plainLabel(rank: 1, title: "Monday of Holy Week") == "Lenten Weekday")
        #expect(DayRank.plainLabel(rank: 3, title: "Feria", season: "Hebdomada I Adventus") == "Advent Weekday", "the Latin tempora name the season too")
        #expect(DayRank.plainLabel(rank: 3, title: "Feria of Advent") == "Advent Weekday")
        #expect(DayRank.plainLabel(rank: 2, title: "Ember Wednesday of Lent") == "Lenten Weekday")
    }

    @Test func theTriduumAndAnOctaveAreNoWeekdays() {
        #expect(DayRank.plainLabel(rank: 1, title: "Good Friday") == "Great Feast")
        #expect(DayRank.plainLabel(rank: 1, title: "Thursday of the Lord's Supper") == "Great Feast")
        #expect(DayRank.plainLabel(rank: 1, title: "Monday within the Octave of Easter") == "Great Feast")
    }

    @Test func lentIsAWordNotALetterRun() {
        // A Valentine or a silent night is not Lenten
        #expect(DayRank.plainLabel(rank: 4, title: "Feria", season: "St. Valentine") == "Weekday")
        #expect(DayRank.plainLabel(rank: 4, title: "Feria", season: "Silent night") == "Weekday")
        #expect(DayRank.plainLabel(rank: 3, title: "Feria", season: "Hebdomada Quadragesimæ") == "Lenten Weekday")
    }
}

@MainActor
struct NumeralTests {

    @Test func romanNumeralsAreWrittenAsPrinted() {
        #expect(LiturgicalCalendarFormat.roman(1) == "I")
        #expect(LiturgicalCalendarFormat.roman(4) == "IV")
        #expect(LiturgicalCalendarFormat.roman(9) == "IX")
        #expect(LiturgicalCalendarFormat.roman(14) == "XIV")
        #expect(LiturgicalCalendarFormat.roman(66) == "LXVI")
        #expect(LiturgicalCalendarFormat.roman(114) == "CXIV")
        #expect(LiturgicalCalendarFormat.roman(1962) == "MCMLXII")
        #expect(LiturgicalCalendarFormat.roman(0) == "")
        #expect(LiturgicalCalendarFormat.roman(-3) == "")
    }

    @Test func writtenAndReadBackTheyAgree() {
        for number in 1...200 {
            #expect(LibraryNumerals.numeral(LiturgicalCalendarFormat.roman(number)) == number)
        }
    }

    @Test func aWordSpelledInNumeralLettersIsNoNumber() {
        #expect(LibraryNumerals.numeral("DID") == nil)
        #expect(LibraryNumerals.numeral("CIVIL") == nil)
        #expect(LibraryNumerals.numeral("MIX") == nil, "1009 is past any chapter on the shelf")
        #expect(LibraryNumerals.numeral("IIII") == nil)
        #expect(LibraryNumerals.numeral("i") == nil, "a lowercase i is the English word")
    }

    @Test func aNumberIsReadHoweverItIsWritten() {
        #expect(LibraryNumerals.numeral("3") == 3)
        #expect(LibraryNumerals.numeral("XI.") == 11)
        #expect(LibraryNumerals.numeral("Third") == 3)
        #expect(LibraryNumerals.numeral("Three") == 3)
    }

    @Test func theFirstNumberInATitle() {
        #expect(LibraryNumerals.number(in: "Chapter XI") == 11)
        #expect(LibraryNumerals.number(in: "Book 3 - Chapters 1-10") == 3)
        #expect(LibraryNumerals.number(in: "The First Book") == 1)
        #expect(LibraryNumerals.number(in: "Preface") == nil)
    }

    @Test func theBooksNumberIsTheOneAfterBook() {
        #expect(LibraryNumerals.bookNumber(in: "Chapters 1-10, Book Four") == 4)
        #expect(LibraryNumerals.bookNumber(in: "Book IV, Chapter 1") == 4)
        #expect(LibraryNumerals.bookNumber(in: "Chapter 1") == nil)
    }
}
