//
//  SilentJumpTests.swift
//  Lumen Viae
//
//  The pill's Go to on a set read as text, where no voice holds the
//  hand: the opening on the pendant's first prayer, a mystery on its Our
//  Father, the closing on the last Glory Be and the pendant's first
//  closing prayer, and a mystery past the last left alone.
//

import Foundation
import Testing

@testable import app

@MainActor
struct SilentJumpTests {

    private func silentPlayer() -> PrayerSessionViewModel {
        let meditations = MysteryData.mysteries(for: .joyful).map { mystery in
            Meditation(
                id: 3000 + mystery.order, title: nil, content: "Consider…", author: nil, source: nil,
                audioUrl: nil, mystery: mystery)
        }
        let set = MeditationSet(
            id: 8, name: "Read as text", category: "joyful", description: nil, labels: nil, meditations: meditations)
        return PrayerSessionViewModel(
            meditationSet: set,
            showsOpeningPrayers: true,
            apiService: APIService(session: StubProtocol.session)
        )
    }

    @Test func aMysteryOpensOnItsOurFather() {
        let vm = silentPlayer()
        #expect(vm.spoken == nil)
        vm.jump(to: .mystery(2))
        #expect(vm.currentMysteryIndex == 2)
        #expect(vm.currentBeadIndex == 0)
        #expect(vm.pendantStep == nil)
    }

    @Test func aMysteryPastTheLastIsLeftAlone() {
        let vm = silentPlayer()
        vm.jump(to: .mystery(1))
        vm.jump(to: .mystery(9))
        vm.jump(to: .mystery(-1))
        #expect(vm.currentMysteryIndex == 1)
    }

    @Test func theClosingStandsOnTheLastGloryBeAndThePendant() {
        let vm = silentPlayer()
        vm.jump(to: .closing)
        #expect(vm.currentMysteryIndex == vm.totalMysteries - 1)
        #expect(vm.currentBeadIndex == vm.strand.gloryBe)
        #expect(vm.pendantStep == vm.silentPendant.firstClosing)
    }

    @Test func theOpeningGoesBackToTheFirstPrayer() {
        let vm = silentPlayer()
        vm.jump(to: .mystery(3))
        vm.jump(to: .opening)
        #expect(vm.currentMysteryIndex == 0)
        #expect(vm.pendantStep == vm.silentPendant.firstOpening)
    }
}
