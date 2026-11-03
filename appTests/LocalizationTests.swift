//
//  LocalizationTests.swift
//  appTests
//
//  The String Catalog's plural variations give English its singulars:
//  the code asks for "6 sets of meditations" and the catalog answers
//  "1 set of meditations" when there is one. If the catalog's entry is
//  lost, English reads "1 sets", and these fail.
//

import Foundation
import Testing

@testable import app

struct LocalizationTests {

    @Test func meditationSetCountsAreSingularForOne() {
        #expect(String(localized: "\(1) sets of meditations") == "1 set of meditations")
        #expect(String(localized: "\(6) sets of meditations") == "6 sets of meditations")
        #expect(String(localized: "\(1) of \(1) sets of meditations") == "1 of 1 set of meditations")
        #expect(String(localized: "\(2) of \(6) sets of meditations") == "2 of 6 sets of meditations")
    }

    @Test func narrationTimeIsSaidWithSingulars() {
        #expect(NarrationClock.spoken(61) == "1 minute 1 second")
        #expect(NarrationClock.spoken(200) == "3 minutes 20 seconds")
        #expect(NarrationClock.spoken(60) == "1 minute")
        #expect(NarrationClock.spoken(1) == "1 second")
    }

    @Test func openingPrayersLeadIntoTheDecadeInOneSentence() {
        #expect(PendantTitleBlock.leadIn(category: .glorious, ordinal: 1) == "Then the First Glorious Mystery")
        #expect(PendantTitleBlock.leadIn(category: .sevenSorrows, ordinal: 1) == "Then the First Sorrow of Mary")
        #expect(PendantTitleBlock.leadIn(category: nil, ordinal: 4) == "Then the Fourth Mystery")
    }

    @Test func consecrationAndLiturgyCountsAreSingularForOne() {
        #expect(String(localized: "\(1) chapters") == "1 chapter")
        #expect(String(localized: "in \(1) days") == "in 1 day")
        #expect(String(localized: "Opens a menu of \(1) devotions") == "Opens a menu of 1 devotion")
        #expect(String(localized: "\(1) of \(1) days on this device") == "1 of 1 day on this device")
        #expect(String(localized: "\(3) of \(30) days on this device") == "3 of 30 days on this device")
    }

    @Test func setNamesKeepTheirEnglishWording() {
        #expect(MysteryCategory.joyful.devotionTitle == "Joyful Mysteries")
        #expect(MysteryCategory.sevenSorrows.devotionTitle == "Seven Sorrows of Mary")
        #expect(MysteryCategory.luminous.displayName == "Luminous")
        #expect(MysteryCategory.sevenSorrows.displayName == "Seven Sorrows")
        #expect(MysteryCategory.joyful.subtitle == "Jesus' birth and childhood")
        #expect(MysteryCategory.sevenSorrows.subtitle == "Mary in her grief")
    }

    @Test func meditationKindsKeepTheirEnglishWording() {
        #expect(MeditationLabel.displayName("Considerations") == "Reflections")
        #expect(MeditationLabel.displayName("Contemplative") == "Inside the Scene")
        #expect(MeditationLabel.displayName("Scriptural") == "Gospel")
        #expect(MeditationLabel.displayName("Saints") == "Saints")
        #expect(MeditationLabel.displayName("Something New") == "Something New")
    }

    @Test func streakAndReadingCountsAreSingularForOne() {
        #expect(String(localized: "\(1) days in a row") == "1 day in a row")
        #expect(String(localized: "\(1) days away") == "1 day away")
        #expect(String(localized: "Next: \("A novena") · \(1) days away") == "Next: A novena · 1 day away")
        #expect(String(localized: "\(1) earlier chapters") == "1 earlier chapter")
        #expect(String(localized: "Show the \(1) earlier chapters") == "Show the earlier chapter")
        #expect(String(localized: "\("A chapter a day") · \(1) read today") == "A chapter a day · one read today")
        #expect(String(localized: "\("A chapter a day") · \(2) read today") == "A chapter a day · 2 read today")
        #expect(String(localized: "Sleep timer, \(1) minutes left") == "Sleep timer, 1 minute left")
    }

    @Test func chantOccasionsAreShownInTheirEnglishWording() {
        for occasion in ChantLibraryData.occasions {
            #expect(ChantLibraryData.displayWording(of: occasion.title) == occasion.title)
            #expect(occasion.shownTitle == occasion.title)
            for rubric in occasion.blocks.compactMap(\.rubric) {
                #expect(ChantLibraryData.displayWording(of: rubric) == rubric)
            }
        }
        #expect(ChantLibraryData.displayWording(of: "Silent prayer") == "Silent prayer")
        // A kept set in older words is shown as the occasion reads now
        #expect(ChantLibraryData.displayWording(of: "Benediction") == "Adoration and Blessing")
        // The reader's own words pass through
        #expect(ChantLibraryData.displayWording(of: "Thursday holy hour") == "Thursday holy hour")
    }
}
