//
//  GuidedRosaryPlaceTests.swift
//  Lumen Viae Tests
//
//  The guide's kept place: a step is only ever offered back if it is a
//  step of those mysteries, still fresh, and in a Rosary the guide can
//  walk, and one whose guide has not changed length or bead since it
//  was kept — and a step means the same bead whichever set it was kept in.
//

import Foundation
import Testing
@testable import app

@MainActor
struct GuidedRosaryPlaceTests {

    private let guidable: [MysteryCategory] = [.joyful, .sorrowful, .glorious, .luminous]

    private func data(_ category: MysteryCategory, step: Int, savedAt: Date = .now) -> Data? {
        GuidedRosary.Place(category: category, step: step, prayedSeconds: 300, savedAt: savedAt).data
    }

    // MARK: - The Steps

    @Test func everySetIsTheSameSeventyFiveSteps() {
        let shape = GuidedRosary.steps(for: .joyful).map(\.part)
        #expect(shape.count == 75)
        for category in guidable {
            #expect(GuidedRosary.steps(for: category).map(\.part) == shape)
        }
    }

    @Test func thePlaceIsKeptFromTheFirstOurFather() {
        let step = GuidedRosary.steps(for: .joyful)[GuidedRosary.firstKeptStep]
        #expect(step.part == .pendantLarge(0))
        #expect(step.prayerIDs == ["our_father"])
    }

    // MARK: - Restoring

    @Test func aFreshPlaceComesBack() {
        let place = GuidedRosary.Place(data(.sorrowful, step: 40))
        #expect(place?.category == .sorrowful)
        #expect(place?.step == 40)
        #expect(place?.prayedSeconds == 300)
    }

    @Test func theLastStepComesBackAndOnePastItDoesNot() {
        #expect(GuidedRosary.Place(data(.glorious, step: 74)) != nil)
        #expect(GuidedRosary.Place(data(.glorious, step: 75)) == nil)
        #expect(GuidedRosary.Place(data(.glorious, step: -1)) == nil)
    }

    @Test func theChapletIsNeverOffered() {
        #expect(GuidedRosary.Place(data(.sevenSorrows, step: 10)) == nil)
    }

    @Test func aPlaceADayOldIsLetGo() {
        let now = Date()
        let kept = data(.joyful, step: 20, savedAt: now.addingTimeInterval(-GuidedRosary.Place.expiry - 1))
        #expect(GuidedRosary.Place(kept, now: now) == nil)
        #expect(GuidedRosary.Place(kept, now: now.addingTimeInterval(-2)) != nil)
    }

    @Test func nothingOrGarbageIsNoPlace() {
        #expect(GuidedRosary.Place(nil) == nil)
        #expect(GuidedRosary.Place(Data("not a place".utf8)) == nil)
    }

    // MARK: - A Guide Changed Since

    /// A kept place as stored, with its fields changed as a place kept by
    /// another build would have them: `nil` removes a field
    private func stored(_ category: MysteryCategory, step: Int, _ changes: [String: Any?]) -> Data? {
        guard let data = data(category, step: step),
              var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        for (key, value) in changes { object[key] = value ?? nil }
        return try? JSONSerialization.data(withJSONObject: object)
    }

    @Test func aPlaceKeepsItsBeadAndTheGuidesLength() {
        let place = GuidedRosary.Place(category: .joyful, step: 7 + 13 + 4, prayedSeconds: 0)
        #expect(place.stepCount == 75)
        #expect(place.bead == RosaryPart.loopSmall(decade: 1, bead: 2).key)
        #expect(RosaryPart.loopSmall(decade: 1, bead: 2).key == "loopSmall.1.2")
    }

    @Test func aPlaceKeptInAGuideOfAnotherLengthIsNotOffered() {
        #expect(GuidedRosary.Place(stored(.sorrowful, step: 40, ["stepCount": 76])) == nil)
        #expect(GuidedRosary.Place(stored(.sorrowful, step: 40, ["stepCount": 75])) != nil)
    }

    @Test func aPlaceWhoseStepIsNowAnotherBeadIsNotOffered() {
        #expect(GuidedRosary.Place(stored(.glorious, step: 40, ["bead": "loopSmall.4.9"])) == nil)
    }

    @Test func aPlaceKeptBeforeEitherWasStoredIsOfferedWhileInRange() {
        let older: [String: Any?] = ["stepCount": nil, "bead": nil]
        let place = GuidedRosary.Place(stored(.luminous, step: 40, older))
        #expect(place?.step == 40)
        #expect(place?.stepCount == nil)
        #expect(GuidedRosary.Place(stored(.luminous, step: 75, older)) == nil)
    }

    // MARK: - Naming It

    @Test func aHailMaryIsNamedByItsMysteryAndBead() {
        // Step 7 announces the first mystery, 8 is its Our Father, 9 the
        // first Hail Mary; the second decade's third Hail Mary is 13 on
        let place = GuidedRosary.Place(category: .sorrowful, step: 7 + 13 + 4, prayedSeconds: 0)
        #expect(place.partName == "The Second Sorrowful Mystery")
        #expect(place.beadName == "The Scourging at the Pillar · 3 of 10")
    }

    @Test func theOpeningAndClosingAreNamedAsSuch() {
        #expect(GuidedRosary.Place(category: .joyful, step: 3, prayedSeconds: 0).partName == "The opening prayers")
        #expect(GuidedRosary.Place(category: .joyful, step: 73, prayedSeconds: 0).partName == "The closing prayers")
    }
}
