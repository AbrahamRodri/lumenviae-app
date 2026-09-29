//
//  RosaryStrandTests.swift
//  Lumen Viae Tests
//
//  The strand's arithmetic, which both players pray on: a decade is its
//  Our Father and its Hail Marys, the Glory Be is said on the next
//  decade's Our Father bead (and after the last decade on the final
//  bead), and the chaplet's sorrows are seven Hail Marys closing on the
//  Glory Be alone.
//

import Testing
@testable import app

@MainActor
struct RosaryStrandTests {

    private let rosary = RosaryStrand(decades: 5, hailMarys: 10)
    private let chaplet = RosaryStrand(decades: 7, hailMarys: 7, saysFatimaPrayer: false)

    // MARK: - Lengths

    @Test func theRosaryIsFiveDecadesOfElevenBeadsAndAnAmen() {
        #expect(rosary.decadeLength == 11)
        #expect(rosary.gloryBe == 11)
        #expect(rosary.count == 56)
        #expect(rosary.saysFatimaPrayer)
    }

    @Test func theChapletIsSevenSorrowsOfEightBeadsAndAnAmen() {
        #expect(chaplet.decadeLength == 8)
        #expect(chaplet.gloryBe == 8)
        #expect(chaplet.count == 57)
        #expect(!chaplet.saysFatimaPrayer)
    }

    @Test func theStringHoldsEveryPrayerOnceAndEndsOnOneAmen() {
        for strand in [rosary, chaplet] {
            let beads = (0..<strand.count).map(strand.bead(at:))
            #expect(beads.filter { if case .ourFather = $0 { return true } else { return false } }.count == strand.decades)
            #expect(beads.filter { if case .hailMary = $0 { return true } else { return false } }.count == strand.decades * strand.hailMarys)
            #expect(beads.filter { $0 == .amen } == [.amen])
            #expect(beads.last == .amen)
        }
    }

    // MARK: - Walking the String

    @Test func eachDecadeOpensOnItsOurFather() {
        #expect(rosary.bead(at: 0) == .ourFather(decade: 0))
        #expect(rosary.bead(at: 1) == .hailMary(decade: 0, number: 1))
        #expect(rosary.bead(at: 10) == .hailMary(decade: 0, number: 10))
        #expect(rosary.bead(at: 11) == .ourFather(decade: 1))
        #expect(rosary.bead(at: 54) == .hailMary(decade: 4, number: 10))
        #expect(rosary.bead(at: 55) == .amen)

        #expect(chaplet.bead(at: 7) == .hailMary(decade: 0, number: 7))
        #expect(chaplet.bead(at: 8) == .ourFather(decade: 1))
        #expect(chaplet.bead(at: 48) == .ourFather(decade: 6))
        #expect(chaplet.bead(at: 55) == .hailMary(decade: 6, number: 7))
        #expect(chaplet.bead(at: 56) == .amen)
    }

    @Test func everyPlaceInADecadeFindsItsBead() {
        for strand in [rosary, chaplet] {
            for mystery in 0..<strand.decades {
                #expect(strand.bead(at: strand.index(mystery: mystery, bead: 0)) == .ourFather(decade: mystery))
                for number in 1...strand.hailMarys {
                    #expect(strand.bead(at: strand.index(mystery: mystery, bead: number))
                        == .hailMary(decade: mystery, number: number))
                }
            }
        }
    }

    @Test func theGloryBeIsSaidOnTheNextDecadesOurFather() {
        for strand in [rosary, chaplet] {
            for mystery in 0..<(strand.decades - 1) {
                let index = strand.index(mystery: mystery, bead: strand.gloryBe)
                #expect(index == strand.index(mystery: mystery + 1, bead: 0))
                #expect(strand.bead(at: index) == .ourFather(decade: mystery + 1))
            }
        }
    }

    @Test func theLastGloryBeIsSaidOnTheFinalBead() {
        #expect(rosary.index(mystery: 4, bead: rosary.gloryBe) == rosary.count - 1)
        #expect(chaplet.index(mystery: 6, bead: chaplet.gloryBe) == chaplet.count - 1)
        #expect(rosary.bead(at: rosary.index(mystery: 4, bead: rosary.gloryBe)) == .amen)
    }

    @Test func aPlaceOffTheDecadeIsHeldToIt() {
        #expect(rosary.index(mystery: 2, bead: -3) == rosary.index(mystery: 2, bead: 0))
        #expect(rosary.index(mystery: 2, bead: 40) == rosary.index(mystery: 2, bead: rosary.gloryBe))
        #expect(rosary.index(mystery: 9, bead: 0) == rosary.count - 1)
    }

    // MARK: - Names

    @Test func theBeadUnderTheHandIsNamedForItsPrayer() {
        #expect(rosary.label(bead: 0) == "Our Father")
        #expect(rosary.label(bead: 4) == "Hail Mary · 4 of 10")
        #expect(rosary.labelLines(bead: 11) == ["Glory Be &", "Fatima Prayer"])
        #expect(chaplet.label(bead: 7) == "Hail Mary · 7 of 7")
        #expect(chaplet.labelLines(bead: 3) == ["Hail Mary", "3 of 7"])
    }

    @Test func theOurFatherBeadsCarryTheirNumeralAndTheLastBeadItsAmen() {
        #expect(rosary.strandLabel(at: 0) == "I")
        #expect(rosary.strandLabel(at: 1) == nil)
        #expect(rosary.strandLabel(at: 44) == "V")
        #expect(rosary.strandLabel(at: 55) == "Amen")
        #expect(chaplet.strandLabel(at: 48) == "VII")
        #expect(chaplet.strandLabel(at: 56) == "Amen")
    }

    @Test func numeralsRunToTenAndNoFurther() {
        #expect((1...10).map(RosaryStrand.roman) == ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"])
        #expect(RosaryStrand.roman(11) == "11")
        #expect(RosaryStrand.roman(0) == "0")
    }
}
