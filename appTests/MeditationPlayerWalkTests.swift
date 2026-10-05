//
//  MeditationPlayerWalkTests.swift
//  Lumen Viae Tests
//
//  A meditation set's Rosary prayed through on the player's beads, with
//  an audio service of its own that keeps off the Lock Screen and the
//  app's player: the decade's length by its set (ten Hail Marys, seven
//  in a sorrow), the mystery turning on its own past the Glory Be, back
//  across a decade's end, the beads unlocking at once where there is no
//  narration to wait for and locked on a narrated Our Father until it is
//  heard — and a Rosary resumed past the Our Father already unlocked.
//

import Foundation
import Testing
@testable import app

@MainActor
struct MeditationPlayerWalkTests {

    private func audio() -> AudioService {
        let defaults = UserDefaults(suiteName: "MeditationPlayerWalkTests.\(UUID().uuidString)")!
        return AudioService(integratesWithSystem: false, defaults: defaults)
    }

    private func set(_ category: MysteryCategory, narrated: Bool) -> MeditationSet {
        let meditations = MysteryData.mysteries(for: category).map { mystery in
            Meditation(
                id: 1000 + mystery.order, title: nil, content: "Consider…", author: nil, source: nil,
                audioUrl: narrated ? "https://example.org/\(mystery.order).mp3" : nil,
                mystery: mystery
            )
        }
        return MeditationSet(id: 7, name: "A Set", category: category.rawValue, description: nil,
                             labels: nil, meditations: meditations)
    }

    private func player(_ category: MysteryCategory = .joyful, narrated: Bool = false,
                        startAtIndex: Int = 0, startAtBead: Int = 0) -> PrayerSessionViewModel {
        PrayerSessionViewModel(
            meditationSet: set(category, narrated: narrated),
            startAtIndex: startAtIndex, startAtBead: startAtBead,
            apiService: APIService(session: StubProtocol.session),
            audioService: audio()
        )
    }

    @Test func aRosaryIsFiveDecadesOfTenAndEndsOnTheLastBead() {
        let vm = player()
        var moves = 0
        while vm.prayForward() { moves += 1 }
        #expect(moves == 5 * 12 - 1)
        #expect(vm.isLastBeadOfRosary)
        #expect(vm.currentMysteryIndex == 4)
    }

    @Test func theChapletsSorrowsAreSevenHailMarysWithNoFatimaPrayer() {
        let vm = player(.sevenSorrows)
        #expect(vm.totalMysteries == 7)
        #expect(!vm.strand.saysFatimaPrayer)
        var moves = 0
        while vm.prayForward() { moves += 1 }
        #expect(moves == 7 * 9 - 1)
    }

    @Test func theMysteryTurnsOnItsOwnPastTheGloryBe() {
        let vm = player()
        for _ in 1...11 { _ = vm.prayForward() }
        #expect(vm.isDecadePrayed)
        #expect(vm.prayForward())
        #expect(vm.currentMysteryIndex == 1 && vm.currentBeadIndex == 0)
        #expect(vm.currentMeditation?.id == 1002)
    }

    @Test func backAcrossADecadesEndLandsOnItsGloryBe() {
        let vm = player()
        for _ in 1...12 { _ = vm.prayForward() }
        vm.prayBack()
        #expect(vm.currentMysteryIndex == 0)
        #expect(vm.currentBeadIndex == vm.strand.gloryBe)
    }

    @Test func withNoNarrationTheBeadsAreUnlockedAtOnce() {
        let vm = player(narrated: false)
        #expect(vm.beadsUnlocked, "nothing to wait for")
    }

    @Test func aNarratedOurFatherHoldsTheBeadsUntilHeard() {
        let vm = player(narrated: true)
        #expect(!vm.beadsUnlocked, "the meditation comes first")
        // The hand moved past the Our Father all the same (the reader, or
        // VoiceOver's own action), and the decade stays unlocked after it
        _ = vm.prayForward()
        #expect(vm.beadsUnlocked)
        _ = vm.prayForward()
        vm.prayBack()
        vm.prayBack()
        #expect(vm.currentBeadIndex == 0)
        #expect(vm.beadsUnlocked, "back on the Our Father, the mystery stays unlocked")
    }

    @Test func theNextMysterysOurFatherIsLockedAgain() {
        let vm = player(narrated: true)
        for _ in 1...12 { _ = vm.prayForward() }
        #expect(vm.currentMysteryIndex == 1 && vm.currentBeadIndex == 0)
        #expect(!vm.beadsUnlocked, "each mystery's meditation is heard before its beads")
    }

    @Test func aRosaryResumedPastTheOurFatherIsUnlocked() {
        let vm = player(narrated: true, startAtIndex: 2, startAtBead: 4)
        #expect(vm.currentMysteryIndex == 2 && vm.currentBeadIndex == 4)
        #expect(vm.beadsUnlocked)
        vm.prayBack(); vm.prayBack(); vm.prayBack(); vm.prayBack()
        #expect(vm.currentBeadIndex == 0)
        #expect(vm.beadsUnlocked, "a mystery once past its Our Father stays unlocked")
    }

    @Test func aResumeIsHeldToTheSetAndTheDecade() {
        let vm = player(startAtIndex: 12, startAtBead: 99)
        #expect(vm.currentMysteryIndex == 4)
        #expect(vm.currentBeadIndex == vm.strand.gloryBe)
    }

    @Test func turningByHandStopsAtTheEnds() {
        let vm = player()
        vm.previousMystery()
        #expect(vm.currentMysteryIndex == 0)
        for _ in 1...4 { #expect(vm.nextMystery()) }
        #expect(!vm.nextMystery(), "the caller goes on to the completion screen")
    }
}
