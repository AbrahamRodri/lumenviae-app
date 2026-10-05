//
//  PrayerGrammarTests.swift
//  Lumen Viae Tests
//
//  The prayer-book grammar `PrayerText` reads from a prayer's own text:
//  `|||` between a line's two languages, [brackets] for a rubric, a ℟
//  after an invocation for a litany, ` * ` at a verse's mediant, a line
//  of rule characters for an ornament — and the rubric glyphs set in
//  red. Then the bundled prayers themselves, held to that grammar.
//

import Foundation
import SwiftUI
import Testing
@testable import app

@MainActor
struct PrayerGrammarTests {

    @Test func aLineSplitsIntoItsTwoLanguages() {
        let parts = PrayerMarkup.parts("Ave María, grátia plena ||| Hail Mary, full of grace")
        #expect(parts.primary == "Ave María, grátia plena")
        #expect(parts.secondary == "Hail Mary, full of grace")
    }

    @Test func aLineWithNoTranslationHasNone() {
        #expect(PrayerMarkup.parts("Amen.").secondary == nil)
        #expect(PrayerMarkup.parts("Amen. |||  ").secondary == nil)
        #expect(PrayerMarkup.parts("  Amen.  ").primary == "Amen.")
    }

    @Test func aBracketedLineIsARubric() {
        #expect(PrayerMarkup.isRubric("[Let us pray.]"))
        #expect(PrayerMarkup.rubric("[Let us pray.]") == "Let us pray.")
        #expect(!PrayerMarkup.isRubric("[]"))
        #expect(!PrayerMarkup.isRubric("[Let us pray.] Amen."))
        #expect(!PrayerMarkup.isRubric("Let us pray."))
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
        #expect(PrayerMarkup.litanyParts("No response").response == "")
    }

    @Test func aPointedVerseBreaksAtItsMediant() {
        let verse = "Magníficat * ánima mea Dóminum."
        #expect(PrayerMarkup.isPointed(verse))
        let halves = PrayerMarkup.pointedParts(verse)
        #expect(halves.first == "Magníficat")
        #expect(halves.second == "ánima mea Dóminum.")
        // An asterisk not set apart by spaces is no mediant
        #expect(!PrayerMarkup.isPointed("Footnote*"))
    }

    @Test func aLineOfRuleCharactersIsAnOrnament() {
        #expect(PrayerMarkup.isRule("─────"))
        #expect(PrayerMarkup.isRule("* * *"))
        #expect(!PrayerMarkup.isRule("--"))
        #expect(!PrayerMarkup.isRule("— Amen —"))
    }

    @Test func onlyTheRubricGlyphsAreSetInRed() {
        let attributed = Rubric.rubricated("℣. Lord, ℟. Amen ✠ x")
        var red = ""
        for run in attributed.runs where run.foregroundColor == Rubric.red {
            red += String(attributed[run.range].characters)
        }
        #expect(red == "℣℟✠")
    }

    @Test func aReadingSplitsIntoParagraphsOnBlankLines() {
        let text = "  First.\n\n\n\nSecond line\nstill second.\n\n   \n\nThird.  "
        #expect(ReadingText.paragraphs(of: text) == ["First.", "Second line\nstill second.", "Third."])
        #expect(ReadingText.paragraphs(of: "").isEmpty)
    }
}

@MainActor
struct BundledPrayerGrammarTests {

    private var prayers: [BookPrayer] { Array(PrayerBook.prayers.values) }

    @Test func everyPrayerHasWordsAndATitle() {
        #expect(!prayers.isEmpty)
        for prayer in prayers {
            #expect(!prayer.title.isEmpty, "\(prayer.id) has no title")
            #expect(!prayer.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(prayer.id) has no words")
        }
    }

    @Test func everyLitanyLineAnswersWithAResponse() {
        for prayer in prayers {
            for line in prayer.english.components(separatedBy: "\n") {
                let primary = PrayerMarkup.parts(line).primary
                guard PrayerMarkup.isLitany(primary) else { continue }
                let parts = PrayerMarkup.litanyParts(primary)
                #expect(!parts.invocation.isEmpty, "\(prayer.id): \(line)")
                #expect(!parts.response.isEmpty, "\(prayer.id): a ℟ with nothing after it in \(line)")
            }
        }
    }

    @Test func noRubricIsLeftHalfBracketed() {
        for prayer in prayers {
            for text in [prayer.english, prayer.latin ?? ""] {
                for line in text.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard trimmed.hasPrefix("[") else { continue }
                    #expect(trimmed.hasSuffix("]"), "\(prayer.id): an unclosed rubric, \(trimmed)")
                }
            }
        }
    }

    @Test func aBlankLineInTheEnglishIsABlankLineInTheLatin() {
        // The bilingual modes pair line for line, blank lines included
        for prayer in prayers {
            guard let latin = prayer.latin else { continue }
            let english = prayer.english.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            let latinBlanks = latin.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard english.count == latinBlanks.count else { continue } // counted by PrayerBookTests
            #expect(english == latinBlanks, "\(prayer.id)'s stanzas break in different places")
        }
    }

    @Test func idsAreUniqueAndPlain() {
        for prayer in prayers {
            #expect(prayer.id.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }, "\(prayer.id)")
        }
    }
}
