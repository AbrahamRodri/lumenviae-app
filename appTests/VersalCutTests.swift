//
//  VersalCutTests.swift
//  Lumen Viae Tests
//
//  The versal's cut: where a paragraph's first letter is, what opening
//  marks stand before it, and whether those marks open a quotation (and
//  are gilded) or an elision ('Tis, which is set as a letter).
//

import Testing
@testable import app

@MainActor
struct VersalCutTests {

    @Test func aPlainParagraphIsCutAtItsFirstLetter() {
        let cut = VersalCut.of("  and the Word was made flesh.")!
        #expect(cut.lead.isEmpty)
        #expect(cut.letter == "A")
        #expect(cut.typedLetter == "a")
        #expect(cut.rest == "nd the Word was made flesh.")
        #expect(cut.wordsAfterLead == "and the Word was made flesh.")
        #expect(!cut.opensOnQuotation)
    }

    @Test(arguments: ["", "   ", "1. The first", "— a dash", "℣. Deus in adiutórium"])
    func aParagraphThatOpensOnNoLetterIsSetPlain(text: String) {
        #expect(VersalCut.of(text) == nil)
    }

    @Test(arguments: [
        "\u{201C}Behold the handmaid of the Lord.\u{201D}",
        "\"Be it done unto me.\"",
        "«Ave Maria»"
    ])
    func aDoubleMarkOrGuillemetAlwaysOpensAQuotation(text: String) {
        #expect(VersalCut.of(text)?.opensOnQuotation == true)
    }

    @Test func aSingleMarkOpensAQuotationWhenAClosingOneAnswersIt() {
        #expect(VersalCut.of("\u{2018}Fiat,\u{2019} she said.")?.opensOnQuotation == true)
        #expect(VersalCut.of("'Fiat,' she said.")?.opensOnQuotation == true)
    }

    @Test(arguments: [
        "\u{2018}Tis the season of grace.",
        "'Twas the night before.",
        "'Tis the saints' feast."
    ])
    func anElisionIsNoQuotation(text: String) {
        #expect(VersalCut.of(text)?.opensOnQuotation == false)
    }

    @Test func anApostropheInsideAWordIsNoClosingMark() {
        #expect(VersalCut.of("\u{2018}Don\u{2019}t be afraid")?.opensOnQuotation == false)
    }
}
