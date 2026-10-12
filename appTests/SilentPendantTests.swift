//
//  SilentPendantTests.swift
//  Lumen Viae Tests
//
//  The opening and closing prayers on the players prayed in silence: the
//  steps are the spoken script's own, the Rosary begins on the cross and
//  ends there, a move on the pendant is a prayer, AMEN is reached only on
//  the last Sign of the Cross, and a Rosary taken up again, or one whose
//  prayers Settings skips, begins on the decades as before.
//

import Foundation
import Testing
@testable import app

@MainActor
struct SilentPendantTests {

    // MARK: The Steps

    @Test func theRosaryOpensAndClosesAsTheVoiceSaysIt() {
        let pendant = SilentPendant(category: .joyful)
        #expect(pendant.opening.map(\.prayerID) == [
            "sign_of_cross", "apostles_creed", "our_father",
            "hail_mary", "hail_mary", "hail_mary", "glory_be",
        ])
        #expect(pendant.closing.map(\.prayerID) == ["hail_holy_queen", "rosary_closing_prayer", "sign_of_cross"])
        #expect(pendant.count(of: .opening(1)) == "2 of 7")
    }

    @Test func theChapletOpensWithTheActOfContritionAndClosesWithHerTears() {
        let pendant = SilentPendant(category: .sevenSorrows)
        #expect(pendant.opening.map(\.prayerID) == ["sign_of_cross", "act_of_contrition"])
        #expect(pendant.closing.map(\.prayerID) == [
            "hail_mary", "hail_mary", "hail_mary", "sorrows_closing_prayer", "sign_of_cross",
        ])
        #expect(pendant.opening.allSatisfy { $0.isChaplet })
    }

    @Test func thePrayersAfterTheRosaryAreLeftToTheVoice() {
        let ids = SilentPendant(category: .glorious).closing.map(\.prayerID)
        #expect(!ids.contains("memorare"))
        #expect(!ids.contains("st_michael_prayer"))
    }

    @Test func everyStepHasItsWords() {
        for category in MysteryCategory.allCases {
            let pendant = SilentPendant(category: category)
            for prayer in pendant.opening + pendant.closing {
                #expect(!SilentPendant.lines(of: prayer.prayerID, in: .english).isEmpty, "\(prayer.prayerID)")
                #expect(!SilentPendant.lines(of: prayer.prayerID, in: .latin).isEmpty, "\(prayer.prayerID)")
            }
        }
    }

    @Test func aBeadsWordsFollowTheStrand() {
        let rosary = RosaryStrand(decades: 5, hailMarys: 10)
        #expect(SilentPendant.lines(ofBead: 0, strand: rosary, in: .english).first?.hasPrefix("Our Father") == true)
        #expect(SilentPendant.lines(ofBead: 4, strand: rosary, in: .english).first?.hasPrefix("Hail Mary") == true)
        let closing = SilentPendant.lines(ofBead: rosary.gloryBe, strand: rosary, in: .english).joined(separator: " ")
        #expect(closing.hasPrefix("Glory be"))
        #expect(closing.contains("O my Jesus"), "the decade closes on the Fatima Prayer too")

        let chaplet = RosaryStrand(decades: 7, hailMarys: 7, saysFatimaPrayer: false)
        let sorrow = SilentPendant.lines(ofBead: chaplet.gloryBe, strand: chaplet, in: .english).joined(separator: " ")
        #expect(!sorrow.contains("O my Jesus"))
    }

    // MARK: The Meditation's Player

    private func player(pendant: Bool, startAtIndex: Int = 0, startAtBead: Int = 0) -> PrayerSessionViewModel {
        let meditations = MysteryData.mysteries(for: .joyful).map { mystery in
            Meditation(id: 1000 + mystery.order, title: nil, content: "Consider…", author: nil, source: nil,
                       audioUrl: nil, mystery: mystery)
        }
        let set = MeditationSet(id: 7, name: "A Set", category: "joyful", description: nil,
                                labels: nil, meditations: meditations)
        let defaults = UserDefaults(suiteName: "SilentPendantTests.\(UUID().uuidString)")!
        return PrayerSessionViewModel(
            meditationSet: set,
            startAtIndex: startAtIndex, startAtBead: startAtBead,
            showsOpeningPrayers: pendant,
            apiService: APIService(session: StubProtocol.session),
            audioService: AudioService(integratesWithSystem: false, defaults: defaults)
        )
    }

    @Test func theRosaryBeginsOnTheCrossAndEndsThere() {
        let vm = player(pendant: true)
        #expect(vm.pendant?.prayerID == "sign_of_cross")
        #expect(vm.pendant?.phase == .opening)
        #expect(vm.isFirstBeadOfRosary)
        var moves = 0
        while vm.prayForward() { moves += 1 }
        // Seven opening prayers, five decades of twelve beads, and the
        // three closing prayers: every step but the first is a move
        #expect(moves == 7 + 5 * 12 + 3 - 1)
        #expect(vm.isLastBeadOfRosary)
        #expect(vm.pendant?.prayerID == "sign_of_cross")
        #expect(vm.pendant?.phase == .closing)
        #expect(vm.currentMysteryIndex == 4 && vm.currentBeadIndex == vm.strand.gloryBe)
    }

    @Test func theLastOpeningPrayerLeadsToTheFirstOurFatherAndBack() {
        let vm = player(pendant: true)
        for _ in 1...7 { _ = vm.prayForward() }
        #expect(vm.pendant == nil)
        #expect(vm.currentMysteryIndex == 0 && vm.currentBeadIndex == 0)
        #expect(!vm.isFirstBeadOfRosary, "the opening prayers stand behind it")
        vm.prayBack()
        #expect(vm.pendant?.prayerID == "glory_be")
    }

    @Test func theLastGloryBeIsNoLongerTheEnd() {
        let vm = player(pendant: true, startAtIndex: 4, startAtBead: 11)
        #expect(vm.pendant == nil, "a Rosary taken up again begins where it was left")
        #expect(!vm.isLastBeadOfRosary)
        #expect(vm.prayForward())
        #expect(vm.pendant?.prayerID == "hail_holy_queen")
        vm.prayBack()
        #expect(vm.pendant == nil)
        #expect(vm.currentBeadIndex == vm.strand.gloryBe)
    }

    @Test func skippedTheRosaryIsTheDecadesAlone() {
        let vm = player(pendant: false)
        #expect(vm.pendant == nil)
        #expect(vm.isFirstBeadOfRosary)
        var moves = 0
        while vm.prayForward() { moves += 1 }
        #expect(moves == 5 * 12 - 1)
        #expect(vm.lastMysteryEndsRosary)
    }

    @Test func offTheBeadsTheArrowsWalkThePendantToo() {
        let vm = player(pendant: true)
        #expect(!vm.lastMysteryEndsRosary)
        var moves = 0
        while vm.advanceOffTheBeads() { moves += 1 }
        // Seven opening prayers, five mysteries, three closing prayers
        #expect(moves == 7 + 5 + 3 - 1)
        #expect(vm.isLastBeadOfRosary)
        for _ in 1...3 { vm.retreatOffTheBeads() }
        #expect(vm.pendant == nil && vm.currentMysteryIndex == 4 && vm.currentBeadIndex == 0)
    }

    // MARK: The Scriptural Rosary's Player

    @Test func theScripturalRosaryInSilenceSetsThePendantsWords() {
        let vm = ScripturalRosaryViewModel(category: .sorrowful, showsOpeningPrayers: true)
        #expect(vm.spokenPendant?.prayerID == "sign_of_cross")
        #expect(vm.setsPendantWords)
        #expect(vm.spokenPendantLines?.first?.hasPrefix("In the name of the Father") == true)
        #expect(vm.stepSpokenPrayer(forward: true))
        #expect(vm.spokenPendant?.prayerID == "apostles_creed")
        var moves = 1
        while vm.prayForward() { moves += 1 }
        #expect(moves == 7 + 5 * 12 + 3 - 1)
        #expect(vm.isLastBeadOfRosary)
    }
}
