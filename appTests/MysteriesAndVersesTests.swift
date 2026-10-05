//
//  MysteriesAndVersesTests.swift
//  Lumen Viae Tests
//
//  The mysteries the app carries with no signal: five sets of five and
//  the Seven Sorrows' seven, under the app's own names, each with its
//  fruit; the Scriptural Rosary's 249 Douay verses, ten to a mystery and
//  seven to a sorrow; the names a set is given on screen; and which acts
//  Daily Prayers may carry.
//

import Foundation
import Testing
@testable import app

@MainActor
struct BundledMysteriesTests {

    @Test func fiveToASetAndSevenSorrows() {
        for category in MysteryCategory.allCases {
            let expected = category == .sevenSorrows ? 7 : 5
            #expect(MysteryData.mysteries(for: category).count == expected, "\(category)")
        }
    }

    @Test func theMysteriesStandInOrderUnderTheirSet() {
        for category in MysteryCategory.allCases {
            let mysteries = MysteryData.mysteries(for: category)
            #expect(mysteries.map(\.order) == Array(1...mysteries.count))
            #expect(mysteries.allSatisfy { $0.category == category.rawValue })
        }
    }

    @Test func everyMysteryHasItsOwnId() {
        let ids = MysteryCategory.allCases.flatMap { MysteryData.mysteries(for: $0) }.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func theAppsOwnNames() {
        let names = { (category: MysteryCategory) in MysteryData.mysteries(for: category).map(\.name) }
        #expect(names(.joyful) == ["The Annunciation", "The Visitation", "The Nativity", "The Presentation", "The Finding in the Temple"])
        #expect(names(.sorrowful) == ["The Agony in the Garden", "The Scourging at the Pillar", "The Crowning with Thorns", "The Carrying of the Cross", "The Crucifixion"])
        #expect(names(.glorious) == ["The Resurrection", "The Ascension", "The Descent of the Holy Spirit", "The Assumption", "The Coronation"])
        #expect(names(.luminous) == ["The Baptism in the Jordan", "The Wedding at Cana", "The Proclamation of the Kingdom", "The Transfiguration", "The Institution of the Eucharist"])
        #expect(names(.sevenSorrows) == [
            "The Prophecy of Simeon", "The Flight into Egypt", "The Loss of Jesus in the Temple",
            "Mary Meets Jesus Carrying the Cross", "The Crucifixion",
            "Jesus Taken Down from the Cross", "The Burial of Jesus"
        ])
    }

    @Test func everyMysteryHasItsFruitAndItsScripture() {
        for category in MysteryCategory.allCases {
            for mystery in MysteryData.mysteries(for: category) {
                #expect(MysteryData.fruit(for: mystery) != nil, "\(mystery.name) has no fruit")
                #expect(!(mystery.scriptureReference ?? "").isEmpty, "\(mystery.name) has no scripture")
            }
        }
        #expect(MysteryData.traditionalFruits.count == 27, "no fruit for a mystery the app does not hold")
    }

    @Test func aSetIsNamedTheSameWayEverywhere() {
        #expect(MysteryCategory.joyful.devotionTitle == "Joyful Mysteries")
        #expect(MysteryCategory.sevenSorrows.devotionTitle == "Seven Sorrows of Mary")
        #expect(MysteryCategory.sorrowful.mysteryLabel(ordinal: 3) == "The Third Sorrowful Mystery")
        #expect(MysteryCategory.sevenSorrows.mysteryLabel(ordinal: 7) == "The Seventh Sorrow of Mary")
    }

    @Test func everySetHasItsOwnEmblemAndPainting() {
        let icons = MysteryCategory.allCases.map(\.iconName)
        #expect(Set(icons).count == icons.count)
        #expect(icons.allSatisfy { $0.hasPrefix("lv-") || $0.hasPrefix("ch-") }, "a devotion wears a devotional glyph")
    }
}

@MainActor
struct ScripturalVersesTests {

    @Test func aVerseForEveryBead() {
        for category in MysteryCategory.allCases {
            let beads = category == .sevenSorrows ? 7 : 10
            for mystery in MysteryData.mysteries(for: category) {
                let verses = ScripturalRosaryData.verses(category: category.rawValue, order: mystery.order)
                #expect(verses?.count == beads, "\(mystery.name) has \(verses?.count ?? 0) verses for \(beads) beads")
            }
        }
    }

    @Test func twoHundredFortyNineInAll() {
        #expect(ScripturalRosaryData.all.values.reduce(0) { $0 + $1.count } == 249)
        #expect(ScripturalRosaryData.all.count == 27)
    }

    @Test func everyVerseIsCitedAndSaid() {
        for (key, verses) in ScripturalRosaryData.all {
            for verse in verses {
                #expect(!verse.text.trimmingCharacters(in: .whitespaces).isEmpty, "\(key)")
                // "Luke 1:28", "1 John 4:8", "Canticle of Canticles 6:9"
                #expect(verse.reference.range(of: #"^[1-4 ]*[A-Z][A-Za-z ]+ \d+:\d+"#, options: .regularExpression) != nil,
                        "\(key): \(verse.reference)")
            }
        }
    }

    @Test func noMysteryHearsTheSameVerseTwice() {
        for (key, verses) in ScripturalRosaryData.all {
            let texts = verses.map(\.text)
            #expect(Set(texts).count == texts.count, "\(key) repeats a verse")
        }
    }

    @Test func aMysteryWithNoSetHasNone() {
        #expect(ScripturalRosaryData.verses(category: "joyful", order: 6) == nil)
    }
}

@MainActor
struct DailyPrayersVocabularyTests {

    @Test func onlyWhatTheChapelCanWatchFinishIsOnTheRule() {
        let eligible = Set(PrayerShortcut.allCases.filter(\.isRuleEligible))
        #expect(eligible == [.todaysRosary, .scripturalRosary, .rosaryAloud, .sevenSorrows,
                             .morningPrayers, .angelus, .nightPrayers])
        // The Mass and the Office stay off until a day's schedule is kept
        #expect(!PrayerShortcut.mass.isRuleEligible)
        #expect(!PrayerShortcut.office.isRuleEligible)
        #expect(!PrayerShortcut.consecration.isRuleEligible, "never chosen, never absent")
    }

    @Test func aStoredListDropsWhatThisBuildDoesNotKnow() {
        let decoded = PrayerShortcut.decode(["todays_rosary", "a_meditation", "angelus", ""])
        #expect(decoded == [.todaysRosary, .angelus])
    }

    @Test func everyActRoundTripsThroughItsStoredName() {
        #expect(PrayerShortcut.decode(PrayerShortcut.allCases.map(\.rawValue)) == PrayerShortcut.allCases)
    }
}
