//
//  ScripturalRosaryWalkTests.swift
//  Lumen Viae Tests
//
//  The Scriptural Rosary and the Rosary Said Aloud prayed through, bead
//  by bead, as the hand moves them: the Our Father announcing the
//  mystery with its fruit, a verse for each Hail Mary in order, the
//  decade closing on the Glory Be and the Fatima Prayer (the Glory Be
//  alone in the chaplet), the mystery turning on its own, back across a
//  decade's end landing on its Glory Be, and the walk ending on the last
//  bead — a move never finishes the Rosary.
//

import Foundation
import Testing
@testable import app

@MainActor
struct ScripturalRosaryWalkTests {

    private func walk(_ category: MysteryCategory, form: SpokenForm = .scriptural) -> ScripturalRosaryViewModel {
        ScripturalRosaryViewModel(category: category, form: form)
    }

    @Test func theWholeRosaryIsFiftyHailMarysAndTheWalkEndsOnTheLastBead() {
        let vm = walk(.joyful)
        var moves = 0
        while vm.prayForward() { moves += 1 }
        // Five decades of Our Father, ten Hail Marys and the Glory Be
        #expect(moves == 5 * 12 - 1)
        #expect(vm.isLastBeadOfRosary)
        #expect(!vm.prayForward(), "a move never finishes the Rosary; AMEN does")
        #expect(vm.currentMysteryIndex == 4)
    }

    @Test func theChapletIsSevenSorrowsOfSevenHailMarys() {
        let vm = walk(.sevenSorrows)
        var moves = 0
        while vm.prayForward() { moves += 1 }
        #expect(moves == 7 * 9 - 1)
        #expect(vm.hailMarys == 7)
    }

    @Test func theOurFatherAnnouncesTheMysteryWithItsFruit() throws {
        let vm = walk(.joyful)
        #expect(vm.isFirstBeadOfRosary)
        let reading = vm.reading
        let annunciation = try #require(MysteryData.mysteries(for: .joyful).first)
        #expect(reading.reference == annunciation.scriptureReference)
        #expect(reading.footnote == "Ask for · Humility")
        #expect(vm.mysteryKicker == "The First Joyful Mystery")
    }

    @Test func eachHailMaryReadsItsOwnVerseInOrder() throws {
        let vm = walk(.sorrowful)
        let verses = try #require(ScripturalRosaryData.verses(category: "sorrowful", order: 1))
        for bead in 1...10 {
            _ = vm.prayForward()
            #expect(vm.currentBeadIndex == bead)
            #expect(vm.reading.reference == verses[bead - 1].reference)
            #expect(vm.reading.text == verses[bead - 1].text)
        }
    }

    @Test func theDecadeClosesOnTheGloryBeAndTheFatimaPrayer() {
        let vm = walk(.glorious)
        for _ in 1...11 { _ = vm.prayForward() }
        #expect(vm.isDecadePrayed)
        #expect(!vm.reading.text.isEmpty)
        #expect(vm.reading.closingPrayer != nil)
        _ = vm.prayForward()
        #expect(vm.currentMysteryIndex == 1, "the mystery turns on its own")
        #expect(vm.currentBeadIndex == 0)
    }

    @Test func aSorrowClosesOnTheGloryBeAlone() {
        let vm = walk(.sevenSorrows)
        for _ in 1...8 { _ = vm.prayForward() }
        #expect(vm.isDecadePrayed)
        #expect(vm.reading.closingPrayer == nil, "the Servite chaplet says no Fatima Prayer")
    }

    @Test func backAcrossADecadesEndLandsOnItsGloryBe() {
        let vm = walk(.luminous)
        for _ in 1...12 { _ = vm.prayForward() }
        #expect(vm.currentMysteryIndex == 1 && vm.currentBeadIndex == 0)
        vm.prayBack()
        #expect(vm.currentMysteryIndex == 0)
        #expect(vm.currentBeadIndex == 11)
        #expect(vm.isDecadePrayed)
    }

    @Test func backFromTheFirstBeadGoesNowhere() {
        let vm = walk(.joyful)
        vm.prayBack()
        #expect(vm.currentMysteryIndex == 0 && vm.currentBeadIndex == 0)
    }

    @Test func theStrandMovesABeadAtATimeAndStandsStillAtTheTurn() {
        // The Glory Be has no bead of its own: it is said on the next
        // decade's Our Father bead, so the decade's turn moves the words
        // and not the strand
        let vm = walk(.joyful)
        var last = vm.strandIndex
        while vm.prayForward() {
            if vm.currentBeadIndex == 0 {
                #expect(vm.strandIndex == last, "the turn stays on the bead under the hand")
            } else {
                #expect(vm.strandIndex == last + 1)
            }
            last = vm.strandIndex
        }
    }

    @Test func turningTheMysteryByHandStartsItsOurFather() {
        let vm = walk(.joyful)
        for _ in 1...4 { _ = vm.prayForward() }
        #expect(vm.nextMystery())
        #expect(vm.currentBeadIndex == 0)
        vm.previousMystery()
        #expect(vm.currentMysteryIndex == 0 && vm.currentBeadIndex == 0)
        for _ in 1...4 { #expect(vm.nextMystery()) }
        #expect(!vm.nextMystery(), "no sixth mystery")
    }

    @Test func aResumedRosaryIsHeldToItsMysteriesAndBeads() {
        let vm = ScripturalRosaryViewModel(category: .joyful, startAtIndex: 9, startAtBead: 40)
        #expect(vm.currentMysteryIndex == 4)
        #expect(vm.currentBeadIndex == 11)
        let early = ScripturalRosaryViewModel(category: .joyful, startAtIndex: -2, startAtBead: -1)
        #expect(early.isFirstBeadOfRosary)
    }

    // MARK: The Rosary Said Aloud

    @Test func saidAloudEachBeadCarriesItsPrayerNotAVerse() {
        let vm = walk(.joyful, form: .plain)
        #expect(vm.displayName == "The Rosary Said Aloud")
        #expect(vm.resumeKind == .rosaryAloud)
        let ourFather = vm.reading
        #expect(ourFather.reference == nil, "no passage; the prayer is set instead")
        #expect(ourFather.footnote == "Ask for · Humility")
        _ = vm.prayForward()
        let hailMary = vm.reading
        #expect(hailMary.reference == nil)
        #expect(!hailMary.text.isEmpty)
        _ = vm.prayForward()
        #expect(vm.reading.text == hailMary.text, "every Hail Mary is the Hail Mary")
        #expect(hailMary.text != ourFather.text)
    }

    @Test func theScripturalRosaryIsNamedAndResumedAsItself() {
        let vm = walk(.joyful)
        #expect(vm.displayName == "The Scriptural Rosary")
        #expect(vm.resumeKind == .scripturalRosary)
    }
}
