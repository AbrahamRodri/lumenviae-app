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

    @Test func meditationKindsKeepTheirEnglishWording() {
        #expect(MeditationLabel.displayName("Considerations") == "Reflections")
        #expect(MeditationLabel.displayName("Contemplative") == "Inside the Scene")
        #expect(MeditationLabel.displayName("Scriptural") == "Gospel")
        #expect(MeditationLabel.displayName("Saints") == "Saints")
        #expect(MeditationLabel.displayName("Something New") == "Something New")
    }
}
