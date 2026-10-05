//
//  OfficeAndReadingRulesTests.swift
//  Lumen Viae Tests
//
//  Small rules several pages lean on at once: which canonical hour the
//  clock is in (the home ledger, the Office's arch and the Chapel all
//  read it), the class of a day read off the Office engine's Latin, the
//  narration's speed brought into range, the API's labels in the
//  picker's words, and when a paragraph opens on a quotation rather
//  than an elision.
//

import Foundation
import Testing
@testable import app

@MainActor
struct CanonicalHourClockTests {

    @Test func eachHourIsPresentFromItsOwnBoundary() {
        for hour in CanonicalHour.allCases {
            #expect(CanonicalHour.present(atClockHour: hour.beginsAtClockHour) == hour)
        }
    }

    @Test func anHourHoldsUntilTheNextOneBegins() {
        #expect(CanonicalHour.present(atClockHour: 4) == .matins)
        #expect(CanonicalHour.present(atClockHour: 6) == .lauds)
        #expect(CanonicalHour.present(atClockHour: 11) == .terce)
        #expect(CanonicalHour.present(atClockHour: 13) == .sext)
        #expect(CanonicalHour.present(atClockHour: 18) == .vespers)
        #expect(CanonicalHour.present(atClockHour: 23) == .compline)
    }

    @Test func everyClockHourHasAnHourAndTheyRunInOrder() {
        var last: CanonicalHour?
        for clockHour in 0..<24 {
            let hour = CanonicalHour.present(atClockHour: clockHour)
            if let last {
                let lastIndex = CanonicalHour.allCases.firstIndex(of: last)!
                let index = CanonicalHour.allCases.firstIndex(of: hour)!
                #expect(index >= lastIndex, "the hours never run backwards through the day")
            }
            last = hour
        }
    }

    @Test func theBoundariesRiseThroughTheDay() {
        let starts = CanonicalHour.allCases.map(\.beginsAtClockHour)
        #expect(starts == starts.sorted())
        #expect(Set(starts).count == starts.count)
        #expect(starts.first == 0, "Matins begins at midnight, so no hour of the clock is without one")
    }

    @Test func followingWrapsAndNextStops() {
        #expect(CanonicalHour.compline.following == .matins)
        #expect(CanonicalHour.compline.next == nil)
        #expect(CanonicalHour.matins.previous == nil)
        #expect(CanonicalHour.lauds.previous == .matins)
        #expect(CanonicalHour.terce.following == .sext)
    }

    @Test func lapsesNamesTheNextHourInWords() {
        #expect(CanonicalHour.terce.lapses == "until Midday Prayer at noon")
        #expect(CanonicalHour.compline.lapses == "until Night Vigil at midnight")
        #expect(CanonicalHour.sext.lapses == "until Mid-Afternoon Prayer at two")
        #expect(CanonicalHour.vespers.lapses == "until Bedtime Prayer at seven")
    }

    @Test func theScribesCloseIsInEnglish() {
        #expect(CanonicalHour.lauds.explicit == "END OF DAWN PRAYER")
        for hour in CanonicalHour.allCases {
            #expect(!hour.explicit.contains("EXPLICI"))
        }
    }

    @Test func noPlainNameIsThePrayerBooksOwn() {
        // "Morning Prayer" and "Night Prayer" belong to the Prayer Book
        let names = CanonicalHour.allCases.map(\.plainName)
        #expect(!names.contains("Morning Prayer"))
        #expect(!names.contains("Night Prayer"))
        #expect(Set(names).count == names.count)
    }
}

@MainActor
struct OfficeRankTests {

    @Test func readsTheEnginesLatinClasses() {
        #expect(OfficeRank("I. classis") == .first)
        #expect(OfficeRank("II. classis") == .second)
        #expect(OfficeRank("III. classis") == .third)
        #expect(OfficeRank("IV. classis") == .fourth)
        #expect(OfficeRank("  ii. classis ") == .second)
    }

    @Test func anythingElseIsAFeria() {
        #expect(OfficeRank("Feria") == .feria)
        #expect(OfficeRank(nil) == .feria)
        #expect(OfficeRank("") == .feria)
        #expect(OfficeRank("Simplex") == .feria)
    }

    @Test func namesTheDayInTheMissalsWords() {
        #expect(OfficeRank.first.englishLabel == "Great Feast")
        #expect(OfficeRank.second.englishLabel == "Feast")
        #expect(OfficeRank.third.englishLabel == "Lesser Feast")
        #expect(OfficeRank.feria.englishLabel == "Weekday")
    }

    @Test func aFeriaSaysItsSeason() {
        #expect(OfficeRank.feria.plainLabel(title: "Quadragesimæ") == "Lenten Weekday")
        #expect(OfficeRank.feria.plainLabel(title: "of Advent") == "Advent Weekday")
    }

    @Test func greaterFeastsBurnBrighterAndAFeriaNotAtAll() {
        let ranks: [OfficeRank] = [.first, .second, .third, .fourth, .feria]
        let opacities = ranks.map(\.markOpacity)
        #expect(opacities == opacities.sorted(by: >))
        #expect(OfficeRank.feria.markOpacity == 0)
    }
}

@MainActor
struct NarrationRateTests {

    @Test func aMissingSpeedIsOneTimes() {
        #expect(AudioService.resolvedRate(0) == 1.0)
        #expect(AudioService.resolvedRate(-1) == 1.0)
        #expect(AudioService.resolvedRate(.nan) == 1.0)
        #expect(AudioService.resolvedRate(.infinity) == 1.0)
    }

    @Test func aSpeedIsHeldToTheNarrationsRange() {
        #expect(AudioService.resolvedRate(0.5) == 0.7)
        #expect(AudioService.resolvedRate(2.0) == 1.7)
        #expect(AudioService.resolvedRate(1.7) == 1.7)
    }

    @Test func aSpeedOffThePresetsIsKeptOnItsTwentieth() {
        // It once became 1× wherever it was read
        #expect(AudioService.resolvedRate(1.15) == 1.15)
        #expect(AudioService.resolvedRate(1.1500000001) == 1.15)
        #expect(AudioService.resolvedRate(1.12) == 1.1)
        #expect(AudioService.resolvedRate(1.13) == 1.15)
    }

    @Test func aBorrowedRangeReachesTheShelfsTwoTimes() {
        #expect(AudioService.resolvedRate(2.0, in: 0.5...2.0) == 2.0)
        #expect(AudioService.resolvedRate(0.5, in: 0.5...2.0) == 0.5)
    }

    @Test func everyPresetInRangeSurvivesAsItIs() {
        for rate in AudioService.supportedRates where AudioService.rateRange.contains(rate) {
            #expect(AudioService.resolvedRate(rate) == rate)
        }
    }
}

@MainActor
struct MeditationLabelTests {

    @Test func threeLabelsAreReworded() {
        #expect(MeditationLabel.displayName("Considerations") == "Reflections")
        #expect(MeditationLabel.displayName("Contemplative") == "Inside the Scene")
        #expect(MeditationLabel.displayName("Scriptural") == "Gospel")
    }

    @Test func theRestAreTheAPIsOwn() {
        #expect(MeditationLabel.displayName("Saints") == "Saints")
        #expect(MeditationLabel.displayName("Intentions") == "Intentions")
        // Matching is case-sensitive, as the API's strings are
        #expect(MeditationLabel.displayName("scriptural") == "scriptural")
    }

    @Test func aSetsLabelsReadAsOneTrackedLine() {
        #expect(MeditationLabel.displayLine(["Saints", "Considerations"]) == "SAINTS  ·  REFLECTIONS")
        #expect(MeditationLabel.displayLine([]) == "")
    }
}

@MainActor
struct VersalQuotationTests {

    @Test func aParagraphOnALetterTakesTheVersal() throws {
        let cut = try #require(VersalCut.of("  blessed are they"))
        #expect(cut.lead.isEmpty)
        #expect(cut.letter == "B")
        #expect(cut.typedLetter == "b")
        #expect(cut.rest == "lessed are they")
        #expect(!cut.opensOnQuotation)
    }

    @Test func aParagraphOnADigitOrADashIsSetPlain() {
        #expect(VersalCut.of("1. The first") == nil)
        #expect(VersalCut.of("— and then") == nil)
        #expect(VersalCut.of("") == nil)
        #expect(VersalCut.of("\u{201C}") == nil)
    }

    @Test func doubleMarksAndGuillemetsAlwaysOpenAQuotation() throws {
        #expect(try #require(VersalCut.of("\u{201C}Behold the handmaid\u{201D}")).opensOnQuotation)
        #expect(try #require(VersalCut.of("\"Be it done\"")).opensOnQuotation)
        #expect(try #require(VersalCut.of("«Magnificat»")).opensOnQuotation)
    }

    @Test func aLoneApostropheIsAnElision() throws {
        #expect(try !#require(VersalCut.of("'Tis the season")).opensOnQuotation)
        #expect(try !#require(VersalCut.of("\u{2018}twas the night")).opensOnQuotation)
        // A plural possessive later on is not the quotation's close
        #expect(try !#require(VersalCut.of("'Tis the saints' feast")).opensOnQuotation)
    }

    @Test func aSingleMarkAnsweredByAClosingOneIsAQuotation() throws {
        let cut = try #require(VersalCut.of("\u{2018}Fiat\u{2019}, she said"))
        #expect(cut.opensOnQuotation)
        #expect(cut.wordsAfterLead == "Fiat\u{2019}, she said")
    }

    @Test func anApostropheInsideAWordDoesNotCloseOne() throws {
        #expect(try !#require(VersalCut.of("'Don\u{2019}t be afraid")).opensOnQuotation)
    }
}
