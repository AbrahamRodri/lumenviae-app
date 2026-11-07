//
//  PrayerResumeServiceTests.swift
//  Lumen Viae Tests
//
//  The kept place of an unfinished Rosary: saved and read back across a
//  launch, let go a day after it was last saved, an unreadable snapshot
//  dropped rather than kept, and the spoken Rosary's step kept only for
//  the same prayer while the voice is running, and offered back only in
//  the decade being resumed and no earlier than its bead.
//

import Foundation
import Testing
@testable import app

@MainActor
struct PrayerResumeServiceTests {

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_790_000_000)
    }

    private let clock = Clock()
    private let defaults = UserDefaults(suiteName: "PrayerResumeServiceTests.\(UUID().uuidString)")!

    private func service() -> PrayerResumeService {
        PrayerResumeService(defaults: defaults, now: { [clock] in clock.now })
    }

    private func save(
        _ service: PrayerResumeService,
        kind: InProgressPrayer.Kind = .meditationSet,
        setId: Int = 12,
        category: String = "joyful",
        mystery: Int = 2,
        bead: Int = 4
    ) {
        service.save(kind: kind, setId: setId, setName: "Montfort", category: category,
                     mysteryIndex: mystery, beadIndex: bead,
                     startedAt: clock.now, accumulatedSeconds: 300)
    }

    private func step(mystery: Int = 2, bead: Int = 5) -> SpokenStep {
        SpokenStep(index: 40, mystery: mystery, bead: bead, caption: "Hail Mary")
    }

    // MARK: - Kept and let go

    @Test func thePlaceOutlivesTheLaunch() {
        save(service())
        let again = service()
        #expect(again.inProgress?.mysteryIndex == 2)
        #expect(again.inProgress?.beadIndex == 4)
        #expect(again.inProgress?.savedAt == clock.now)
    }

    @Test func thePlaceIsLetGoADayAfterItWasSaved() {
        let resume = service()
        save(resume)
        clock.now += 23 * 60 * 60
        #expect(resume.inProgress != nil)
        clock.now += 2 * 60 * 60
        #expect(resume.inProgress == nil)
        #expect(service().inProgress == nil)
        #expect(defaults.data(forKey: "prayerResume.inProgress") == nil)
    }

    @Test func clearingForgetsThePlace() {
        let resume = service()
        save(resume)
        resume.clear()
        #expect(resume.inProgress == nil)
        #expect(service().inProgress == nil)
    }

    @Test func anUnreadableSnapshotIsDropped() {
        defaults.set(Data("not a prayer".utf8), forKey: "prayerResume.inProgress")
        #expect(service().inProgress == nil)
        #expect(defaults.data(forKey: "prayerResume.inProgress") == nil)
    }

    // MARK: - The spoken Rosary's step

    @Test func theStepIsKeptForTheSamePrayerAndOfferedBackAtItsBead() {
        let resume = service()
        save(resume)
        resume.updateSpokenStep(step(), kind: .meditationSet, setId: 12, category: "joyful")
        #expect(resume.spokenStep(kind: .meditationSet, setId: 12, category: "joyful",
                                  mysteryIndex: 2, beadIndex: 4) == step())
        #expect(service().inProgress?.spokenStep == step())
    }

    @Test func theStepIsNotOfferedInAnotherDecadeOrBehindTheBead() {
        let resume = service()
        save(resume)
        resume.updateSpokenStep(step(), kind: .meditationSet, setId: 12, category: "joyful")
        #expect(resume.spokenStep(kind: .meditationSet, setId: 12, category: "joyful",
                                  mysteryIndex: 3, beadIndex: 0) == nil)
        #expect(resume.spokenStep(kind: .meditationSet, setId: 12, category: "joyful",
                                  mysteryIndex: 2, beadIndex: 6) == nil)
        #expect(resume.spokenStep(kind: .scripturalRosary, setId: 12, category: "joyful",
                                  mysteryIndex: 2, beadIndex: 4) == nil)
    }

    @Test func aStepForAnotherPrayerIsIgnored() {
        let resume = service()
        save(resume)
        resume.updateSpokenStep(step(), kind: .meditationSet, setId: 99, category: "joyful")
        #expect(resume.inProgress?.spokenStep == nil)
    }

    @Test func aBeadsSaveKeepsTheStepOnlyWhileTheVoiceRuns() {
        let resume = service()
        save(resume)
        resume.updateSpokenStep(step(), kind: .meditationSet, setId: 12, category: "joyful")
        save(resume, bead: 5)
        #expect(resume.inProgress?.spokenStep == step())

        resume.endSpokenSteps(forgettingStep: false)
        #expect(resume.inProgress?.spokenStep == step())
        save(resume, bead: 6)
        #expect(resume.inProgress?.spokenStep == nil)
    }

    @Test func turningTheVoiceOffForgetsTheStep() {
        let resume = service()
        save(resume)
        resume.updateSpokenStep(step(), kind: .meditationSet, setId: 12, category: "joyful")
        resume.endSpokenSteps(forgettingStep: true)
        #expect(resume.inProgress?.spokenStep == nil)
    }

    @Test func anotherPrayersSaveDoesNotInheritTheStep() {
        let resume = service()
        save(resume)
        resume.updateSpokenStep(step(), kind: .meditationSet, setId: 12, category: "joyful")
        save(resume, kind: .scripturalRosary, setId: 0, category: "joyful")
        #expect(resume.inProgress?.spokenStep == nil)
    }
}
