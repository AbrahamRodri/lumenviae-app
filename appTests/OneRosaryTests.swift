//
//  OneRosaryTests.swift
//  Lumen Viae Tests
//
//  The One Rosary beta: off until chosen; with it on the beads always
//  hang and Helps stands in Counting's place; the overview's order of the
//  Rosary; the Helps line for each place on a player; and which beads a
//  tap on the strand may reach.
//

import Foundation
import SwiftUI
import Testing

@testable import app

@MainActor
struct OneRosaryTests {

    // MARK: - The Switch

    @Test func theBetaIsOffUntilChosen() throws {
        let defaults = try #require(UserDefaults(suiteName: "OneRosaryTests.\(UUID().uuidString)"))
        #expect(!UserSettings.storedOneRosaryBeta(in: defaults))
        defaults.set(true, forKey: UserSettings.oneRosaryBetaKey)
        #expect(UserSettings.storedOneRosaryBeta(in: defaults))
        #expect(UserSettings.oneRosaryBetaKey == "userSettings.oneRosaryBeta")
    }

    // MARK: - The Beads Always Hang

    @Test(arguments: [RosaryForm.meditation, .scriptural, .holy])
    func withTheBetaTheBeadsAlwaysCountOnTheScreen(form: RosaryForm) {
        for aloud in [false, true] {
            for onBeads in [false, true] {
                #expect(form.countsOnScreen(aloud: aloud, onBeads: onBeads, oneRosary: true))
            }
        }
    }

    @Test func withoutTheBetaCountingStillDecides() {
        #expect(!RosaryForm.meditation.countsOnScreen(aloud: false, onBeads: false, oneRosary: false))
        #expect(!RosaryForm.scriptural.countsOnScreen(aloud: false, onBeads: false))
    }

    @Test func withTheBetaHelpsTakesCountingsPlace() {
        for aloud in [false, true] {
            #expect(RosaryChoice.offered(for: .meditation, aloud: aloud, oneRosary: true) == [.audio, .helps])
            #expect(RosaryChoice.offered(for: .scriptural, aloud: aloud, oneRosary: true) == [.audio, .helps])
            #expect(RosaryChoice.offered(for: .holy, aloud: aloud, oneRosary: true) == [.helps])
        }
        // Off, as it was
        #expect(RosaryChoice.offered(for: .meditation, aloud: false) == [.audio, .counting])
        #expect(RosaryChoice.offered(for: .meditation, aloud: false, oneRosary: false) == [.audio, .counting])
    }

    @Test func helpsIsOffOrOn() {
        #expect(RosaryChoice.helps.title == "Helps")
        #expect(RosaryChoice.helps.options(for: .meditation).map(\.name) == ["Off", "On"])
        #expect(RosaryChoice.helps.note(for: false) != RosaryChoice.helps.note(for: true))
    }

    // MARK: - The Overview

    @Test func theOverviewRunsFromTheOpeningToTheClose() {
        let overview = RosaryOverview(category: .joyful, includesPendant: true)
        #expect(
            overview.parts.map(\.kind) == [
                .opening, .mystery(1), .mystery(2), .mystery(3), .mystery(4), .mystery(5), .closing,
            ])
        #expect(overview.mysteries.map(\.title) == MysteryData.mysteries(for: .joyful).map(\.name))
        #expect(overview.parts.first?.detail != nil)
        #expect(overview.parts.last?.detail != nil)
    }

    @Test func theChapletHasSevenSorrows() {
        let overview = RosaryOverview(category: .sevenSorrows, includesPendant: true)
        #expect(overview.mysteries.count == 7)
        #expect(overview.parts.count == 9)
    }

    @Test func withoutTheOpeningPrayersTheOverviewIsTheMysteries() {
        let overview = RosaryOverview(category: .glorious, includesPendant: false)
        #expect(overview.parts.map(\.kind) == (1...5).map { RosaryOverview.Kind.mystery($0) })
    }

    // MARK: - Helps

    @Test func helpsFollowsTheGuideOnThePendant() {
        let steps = GuidedRosary.steps(for: .joyful)
        let first = RosaryHelps.line(for: .joyful, pendantStep: .opening(0), mystery: 0, bead: 0)
        #expect(first == RosaryHelps.Line(place: steps[0].place, instruction: steps[0].instruction))

        let creed = RosaryHelps.line(for: .joyful, pendantStep: .opening(1), mystery: 0, bead: 0)
        #expect(creed?.instruction == steps[1].instruction)

        let closing = steps.filter(\.isClosing)
        let last = RosaryHelps.line(for: .joyful, pendantStep: .closing(2), mystery: 4, bead: 11)
        #expect(last?.instruction == closing[2].instruction)
    }

    @Test func helpsFollowsTheGuideOnTheDecades() {
        let mystery = MysteryData.mysteries(for: .sorrowful)[2]
        // The Our Father
        let ourFather = RosaryHelps.line(for: .sorrowful, pendantStep: nil, mystery: 2, bead: 0)
        #expect(ourFather?.place.contains(mystery.name) == true)
        // A Hail Mary: the guide's own place for it
        let hailMary = RosaryHelps.line(for: .sorrowful, pendantStep: nil, mystery: 2, bead: 4)
        #expect(hailMary?.place == GuidedRosary.hailMaryPlace(mystery.name, bead: 4))
        // The Glory Be closes the decade
        let close = RosaryHelps.line(for: .sorrowful, pendantStep: nil, mystery: 2, bead: 11)
        let decade = GuidedRosary.steps(for: .sorrowful).filter { $0.decade == 2 }
        #expect(close?.instruction == decade.last?.instruction)
    }

    @Test func everyPlaceOnTheRosaryHasAHelp() {
        let pendant = SilentPendant(category: .luminous)
        for index in pendant.opening.indices {
            #expect(RosaryHelps.line(for: .luminous, pendantStep: .opening(index), mystery: 0, bead: 0) != nil)
        }
        for index in pendant.closing.indices {
            #expect(RosaryHelps.line(for: .luminous, pendantStep: .closing(index), mystery: 4, bead: 11) != nil)
        }
        for mystery in 0..<5 {
            for bead in 0...11 {
                #expect(RosaryHelps.line(for: .luminous, pendantStep: nil, mystery: mystery, bead: bead) != nil)
            }
        }
    }

    @Test func theChapletHasNoHelps() {
        #expect(RosaryHelps.line(for: .sevenSorrows, pendantStep: nil, mystery: 0, bead: 3) == nil)
    }

    // MARK: - Tapping the Strand

    @Test func aTapReachesBackAndAheadToTheNextOurFather() {
        let strand = RosaryStrand(decades: 5, hailMarys: 10)
        let active = strand.index(mystery: 1, bead: 3)
        #expect(!strand.canTap(active, from: active))
        #expect(strand.canTap(active - 5, from: active))
        #expect(strand.canTap(strand.index(mystery: 2, bead: 0), from: active))
        #expect(!strand.canTap(strand.index(mystery: 2, bead: 1), from: active))
        #expect(!strand.canTap(strand.count, from: active))
    }

    @Test func aPositionOnTheStringIsAMysteryAndABead() {
        let strand = RosaryStrand(decades: 5, hailMarys: 10)
        #expect(strand.position(at: strand.index(mystery: 3, bead: 7)) == BeadPosition(mystery: 3, bead: 7))
        #expect(strand.position(at: strand.count - 1) == BeadPosition(mystery: 4, bead: strand.gloryBe))
    }

    @Test func aTapWalksTheHandToTheBead() {
        let vm = ScripturalRosaryViewModel(category: .joyful, startAtIndex: 1, startAtBead: 4, showsOpeningPrayers: false)
        #expect(vm.goToBead(at: vm.strand.index(mystery: 1, bead: 1)))
        #expect(vm.beadPosition == BeadPosition(mystery: 1, bead: 1))
        // Back across the decade's turn, to the mystery before
        #expect(vm.goToBead(at: vm.strand.index(mystery: 0, bead: 9)))
        #expect(vm.beadPosition == BeadPosition(mystery: 0, bead: 9))
        // Ahead as far as the next Our Father, where the Glory Be is said
        #expect(vm.goToBead(at: vm.strand.index(mystery: 1, bead: 0)))
        #expect(vm.strandIndex == vm.strand.index(mystery: 1, bead: 0))
        // Never past it
        #expect(!vm.goToBead(at: vm.strand.index(mystery: 1, bead: 5)))
    }

    // MARK: - Round 2: Helps Never Repeat the Mystery

    @Test func helpsNeverNameTheMysteryTheScreenNames() {
        for category in [MysteryCategory.joyful, .sorrowful, .glorious, .luminous] {
            let mysteries = MysteryData.mysteries(for: category)
            for mystery in 0..<5 {
                let name = mysteries[mystery].name.lowercasedArticle
                for bead in 1...10 {
                    let line = RosaryHelps.line(for: category, pendantStep: nil, mystery: mystery, bead: bead)
                    #expect(line?.instruction.localizedCaseInsensitiveContains(name) == false)
                }
            }
        }
    }

    // MARK: - Round 2: One Rail

    @Test func theRailClimbsThePendantRunsTheDecadesAndComesBackDown() {
        let strand = RosaryStrand(decades: 5, hailMarys: 10)
        let pendant = SilentPendant(category: .joyful)
        let rail = OneRosaryRail(strand: strand, pendant: pendant, showsPendant: true)

        // The cross (the Sign of the Cross and the Creed), the large bead,
        // three small beads; the Glory Be on the first mystery's Our
        // Father bead, the pendant's second large bead, as on a rosary
        #expect(Array(rail.kinds.prefix(5)) == [.cross, .largeBead, .smallBead, .smallBead, .smallBead])
        #expect(rail.strandStart == 5)
        #expect(rail.index(of: .opening(0)) == 0)
        #expect(rail.index(of: .opening(1)) == 0)
        #expect(rail.index(of: .opening(2)) == 1)
        #expect(rail.index(of: .opening(pendant.opening.count - 1)) == 5)
        #expect(rail.index(strandIndex: 0) == 5)
        #expect(rail.kinds[5] == .ourFather(decade: 0))

        // The last Glory Be, the Hail, Holy Queen and the closing prayer
        // on the medal; the last Sign of the Cross on the cross
        let end = rail.index(strandIndex: strand.count - 1)
        #expect(rail.kinds[end] == .medal)
        #expect(rail.index(of: .closing(0)) == end)
        #expect(rail.index(of: .closing(1)) == end)
        #expect(rail.index(of: .closing(2)) == end + 1)
        #expect(rail.kinds.last == .cross)
        #expect(rail.count == 5 + strand.count + 1)
    }

    @Test func theRailIsTheStrandWithoutThePendant() {
        let strand = RosaryStrand(decades: 5, hailMarys: 10)
        let rail = OneRosaryRail(strand: strand, pendant: SilentPendant(category: .joyful), showsPendant: false)
        #expect(rail.count == strand.count)
        #expect(rail.strandStart == 0)
        #expect(rail.kinds.last == .end)
        #expect(rail.label(at: rail.count - 1) == "Amen")
        #expect(rail.label(at: rail.index(strandIndex: strand.index(mystery: 2, bead: 0))) == "3")
    }

    @Test func aTapOnTheRailIsABeadOrThePendant() {
        let strand = RosaryStrand(decades: 5, hailMarys: 10)
        let rail = OneRosaryRail(strand: strand, pendant: SilentPendant(category: .joyful), showsPendant: true)
        #expect(rail.target(at: 0) == .pendant(.opening(0)))
        #expect(rail.target(at: 2) == .pendant(.opening(3)))
        #expect(rail.target(at: rail.strandStart + 7) == .strand(7))
        #expect(rail.target(at: rail.count - 1) == .pendant(.closing(2)))
        #expect(rail.target(at: rail.count) == nil)
    }

    @Test func theChapletsRailClosesOnItsOwnBeads() {
        let strand = RosaryStrand(decades: 7, hailMarys: 7, saysFatimaPrayer: false)
        let rail = OneRosaryRail(strand: strand, pendant: SilentPendant(category: .sevenSorrows), showsPendant: true)
        // The Sign of the Cross and the Act of Contrition on the cross
        #expect(rail.strandStart == 1)
        #expect(rail.kinds.first == .cross)
        // Three Hail Marys for her tears, the closing prayer, the cross
        #expect(Array(rail.kinds.suffix(5)) == [.smallBead, .smallBead, .smallBead, .medal, .cross])
    }

    // MARK: - Round 2: The Overview Lights Its Beads

    @Test func eachPartOfTheOverviewLightsItsBeads() {
        let overview = RosaryOverview(category: .joyful, includesPendant: true)
        #expect(overview.parts.first?.beads.contains(.crucifix) == true)
        #expect(overview.parts[1].beads.count == 11)
        #expect(overview.parts[1].beads.contains(RosaryMap.ourFatherBead(decade: 0)))
        #expect(overview.parts.last?.beads == [.medal, .crucifix, .pendantLarge(0), .pendantSmall(0), .pendantSmall(1), .pendantSmall(2)])
        // The opening and the close light the same pendant
        #expect(overview.parts.first?.beads.isSubset(of: overview.parts.last?.beads ?? []) == true)
        // No two mysteries share a bead
        let mysteries = overview.mysteries.map(\.beads)
        for (i, a) in mysteries.enumerated() {
            for b in mysteries[(i + 1)...] { #expect(a.isDisjoint(with: b)) }
        }
    }

    @Test func aSetsOwnTitlesStandUnderTheMysteries() {
        let names = MysteryData.mysteries(for: .joyful).map(\.name)
        let titles = [names[0], "The Word Made Flesh", "", names[3], "Lost and Found"]
        let overview = RosaryOverview(category: .joyful, includesPendant: false, meditationTitles: titles)
        #expect(overview.mysteries.map(\.detail) == [nil, "The Word Made Flesh", nil, nil, "Lost and Found"])
    }

    @Test func thePendantsLabelIsThePrayerAndItsCount() {
        #expect(OneRosaryColumn<EmptyView>.pendantLabel(prayer: "The Apostles' Creed", count: "2 of 7")
            == "The Apostles' Creed · 2 of 7")
        #expect(OneRosaryColumn<EmptyView>.pendantLabel(prayer: "The Sign of the Cross", count: nil)
            == "The Sign of the Cross")
    }

    @Test func theRailHangsBelowTheStrandsPlace() {
        let height: CGFloat = 956
        #expect(OneRosaryRailView.windowTop(fullHeight: height) > RosaryStrandView.windowTop(fullHeight: height))
        // The window still ends above the foot's Back and Next
        #expect(OneRosaryRailView.windowTop(fullHeight: height) + OneRosaryRailView.windowHeight(fullHeight: height)
            < height * 0.8)
    }

    @Test func eachMysteryIsOneSpanOfTheLoop() {
        // The bracket the overview draws spans a decade's beads, which
        // stand together on the loop
        let overview = RosaryOverview(category: .joyful, includesPendant: true)
        for part in overview.mysteries {
            let indices = part.beads.compactMap { RosaryMap.loop.firstIndex(of: $0) }.sorted()
            guard let first = indices.first, let last = indices.last else {
                Issue.record("a mystery with no beads on the loop"); continue
            }
            #expect(last - first == indices.count - 1)
        }
    }

    // MARK: - Round 6

    @Test(arguments: [MysteryCategory.joyful, .sorrowful, .glorious, .luminous, .sevenSorrows])
    func everyPendantLabelHasItsNumber(category: MysteryCategory) {
        let pendant = SilentPendant(category: category)
        let steps = pendant.opening.indices.map { SilentPendant.Step.opening($0) }
            + pendant.closing.indices.map { SilentPendant.Step.closing($0) }
        #expect(!steps.isEmpty)
        for step in steps {
            guard let prayer = pendant.pendant(at: step) else {
                Issue.record("a step with no prayer"); continue
            }
            let label = OneRosaryColumn<EmptyView>.pendantLabel(prayer: prayer.title, count: pendant.count(of: step))
            let (number, total): (Int, Int) = {
                switch step {
                case .opening(let i): return (i + 1, pendant.opening.count)
                case .closing(let i): return (i + 1, pendant.closing.count)
                }
            }()
            #expect(label.hasSuffix(" · \(number) of \(total)"), "\(label)")
            #expect(!label.contains("?"))
        }
    }

    @Test func noNumeralStandsBesideAPendantBead() {
        let strand = RosaryStrand(decades: 5, hailMarys: 10)
        let rail = OneRosaryRail(strand: strand, pendant: SilentPendant(category: .joyful), showsPendant: true)
        for index in 0..<rail.count where rail.label(at: index) != nil {
            switch rail.kinds[index] {
            case .ourFather, .end: break
            default: Issue.record("a numeral beside \(rail.kinds[index])")
            }
        }
        // The pendant's only large bead before the decades is its first:
        // no unnumbered large ring stands under the "1"
        let beforeDecades = rail.kinds.prefix(rail.strandStart)
        #expect(beforeDecades.filter { $0 == .largeBead || $0 == .medal }.count == 1)
    }

    @Test(arguments: [CGFloat(812), 852, 874, 932, 956])
    func theRailsWindowEndsOnTheGapBetweenBeads(fullHeight: CGFloat) {
        let height = OneRosaryRailView.windowHeight(fullHeight: fullHeight)
        let rows = height / OneRosaryRailView.rowHeight
        // An odd whole number of rows, so with the hand's bead at the
        // middle both edges fall between two beads
        #expect(rows == rows.rounded())
        #expect(Int(rows) % 2 == 1)
        let fade = OneRosaryRailView.fadeStops(height: height)
        // Clear across the outermost row, solid within the next
        #expect(fade.clear * height >= OneRosaryRailView.rowHeight - 3)
        #expect(fade.solid * height <= OneRosaryRailView.rowHeight * 1.5)
    }

    @Test func theKickerNamesTheMysteriesAndWhatWasChosen() {
        #expect(OneRosaryColumn<EmptyView>.kicker(mysteries: "Joyful Mysteries", chosen: "Blessed Fulton J. Sheen")
            == "Joyful Mysteries · Blessed Fulton J. Sheen")
        #expect(OneRosaryColumn<EmptyView>.kicker(mysteries: nil, chosen: "The Gospel") == "The Gospel")
        #expect(OneRosaryColumn<EmptyView>.kicker(mysteries: "Joyful Mysteries", chosen: "") == "Joyful Mysteries")
    }
}
