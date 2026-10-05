//
//  PrayerMarkupTests.swift
//  Lumen Viae Tests
//
//  The prayer-book grammar `PrayerText` reads from a prayer's own text:
//  the `|||` pair of languages, a rubric in square brackets, a litany's
//  invocation and response, a verse pointed at its mediant, and a rule.
//

import Testing
@testable import app

struct PrayerMarkupTests {

    @Test func aLineSplitsIntoItsTwoLanguages() {
        let parts = PrayerMarkup.parts("Ave María, grátia plena ||| Hail Mary, full of grace")
        #expect(parts.primary == "Ave María, grátia plena")
        #expect(parts.secondary == "Hail Mary, full of grace")
    }

    @Test func aLineWithNoOrAnEmptyTranslationHasNone() {
        #expect(PrayerMarkup.parts("Amen.").secondary == nil)
        #expect(PrayerMarkup.parts("Amen. |||   ").secondary == nil)
    }

    @Test func aBracketedLineIsARubric() {
        #expect(PrayerMarkup.isRubric("[Let us pray.]"))
        #expect(PrayerMarkup.rubric("[Let us pray.]") == "Let us pray.")
        #expect(!PrayerMarkup.isRubric("[]"))
        #expect(!PrayerMarkup.isRubric("[Let us pray.] And more"))
    }

    @Test func anInvocationAnsweredOnItsLineIsALitany() {
        #expect(PrayerMarkup.isLitany("Holy Mary, ℟. pray for us."))
        let parts = PrayerMarkup.litanyParts("Holy Mary, ℟. pray for us.")
        #expect(parts.invocation == "Holy Mary,")
        #expect(parts.response == "pray for us.")
    }

    @Test func aResponseStandingAloneIsNoLitany() {
        #expect(!PrayerMarkup.isLitany("℟. Amen."))
        #expect(!PrayerMarkup.isLitany("Holy Mary, pray for us."))
    }

    @Test func aPointedVerseBreaksAtItsMediant() {
        let verse = "Magníficat * ánima mea Dóminum."
        #expect(PrayerMarkup.isPointed(verse))
        let halves = PrayerMarkup.pointedParts(verse)
        #expect(halves.first == "Magníficat")
        #expect(halves.second == "ánima mea Dóminum.")
        #expect(!PrayerMarkup.isPointed("Glory*be"))
    }

    @Test(arguments: ["─────", "---", "* * *", "———"])
    func ruleCharactersMakeARule(text: String) {
        #expect(PrayerMarkup.isRule(text))
    }

    @Test(arguments: ["--", "- a -", "Amen"])
    func otherTextIsNoRule(text: String) {
        #expect(!PrayerMarkup.isRule(text))
    }
}
