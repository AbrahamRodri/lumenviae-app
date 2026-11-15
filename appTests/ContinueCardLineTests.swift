//
//  ContinueCardLineTests.swift
//  appTests
//
//  Home's Continue card names what is being prayed by the form's own
//  name, never the mysteries' page's "No Meditation", and the bead the
//  hand stopped on.
//

import Foundation
import Testing

@testable import app

struct ContinueCardLineTests {

    private func left(_ kind: InProgressPrayer.Kind, _ category: MysteryCategory, bead: Int?) -> InProgressPrayer {
        InProgressPrayer(
            kind: kind,
            meditationSetId: 0,
            setName: "The Rosary Aloud",
            category: category.rawValue,
            mysteryIndex: 1,
            beadIndex: bead,
            startedAt: Date(timeIntervalSince1970: 0),
            accumulatedSeconds: 60,
            savedAt: Date(timeIntervalSince1970: 60)
        )
    }

    @Test func theAudioRosaryIsNamedAsItselfOutsideTheChoice() {
        #expect(ScripturalRosaryViewModel.formName(for: .plain) == "The Audio Rosary")
        #expect(ScripturalRosaryViewModel.displayName(for: .plain) == "No Meditation")
        #expect(
            ScripturalRosaryViewModel.formName(for: .scriptural)
                == ScripturalRosaryViewModel.displayName(for: .scriptural)
        )
    }

    @Test func theBeadIsNamedInRunningText() {
        #expect(left(.rosaryAloud, .joyful, bead: 8).beadLabel == "Hail Mary 8 of 10")
        #expect(left(.rosaryAloud, .joyful, bead: 0).beadLabel == "Our Father")
        #expect(left(.rosaryAloud, .sevenSorrows, bead: 7).beadLabel == "Hail Mary 7 of 7")
        #expect(left(.rosaryAloud, .sevenSorrows, bead: 8).beadLabel == "Glory Be")
    }

    @Test func aSnapshotWithNoBeadSaysNone() {
        #expect(left(.rosaryAloud, .joyful, bead: nil).beadLabel == nil)
    }
}
