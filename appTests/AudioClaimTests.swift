//
//  AudioClaimTests.swift
//  Lumen Viae Tests
//
//  Ownership of the shared player as a claim: one holder at a time, a new
//  claim ending the old with notice, a borrowed speed coming back however
//  a claim ends, the app's speed controls never retuning a borrowed one,
//  a claim declining while something plays when asked to, the older
//  surface ending a claim when it takes the player, end-of-track told to
//  the claim that loaded the item and never to a flow that took the arrows
//  without loading it, a load dropped when its claim ends mid-way, and a
//  release that stops only its own item, or the empty player its own
//  unload left.
//
//  Each test drives a service of its own that does not speak to the
//  system (no audio session, no Lock Screen), with its speed kept in a
//  defaults suite of its own. Recordings are the app's bundled chants,
//  loaded but never played.
//

import Foundation
import Testing
@testable import app

@MainActor
@Suite(.serialized)
struct AudioClaimTests {

    /// A service apart from the app's, its app speed 1.25×
    private func makeService(appRate: Double = 1.25) -> AudioService {
        let defaults = UserDefaults(suiteName: "AudioClaimTests.\(UUID().uuidString)")!
        defaults.set(appRate, forKey: "userSettings.narrationRate")
        return AudioService(integratesWithSystem: false, defaults: defaults)
    }

    private var recording: URL { ChantCatalog.all[0].audioURL! }

    private func navigation() -> AudioNavigation {
        AudioNavigation(canGoNext: true, canGoPrevious: false, onNext: {}, onPrevious: {})
    }

    /// Until a load begun in a task is on its way, so a test can end its
    /// claim while the recording is still arriving rather than before
    /// the load has begun at all
    private func untilLoading(_ service: AudioService) async {
        for _ in 0..<50 where !service.isLoading { await Task.yield() }
        #expect(service.isLoading)
    }

    // MARK: - One holder

    @Test func aNewClaimEndsTheOldWithNotice() {
        let service = makeService()
        var revoked = 0
        let first = service.claim(.chant, onRevoked: { revoked += 1 })!
        #expect(first.isCurrent)
        #expect(service.holder === first)

        let second = service.claim(.consecration)!
        #expect(!first.isCurrent)
        #expect(second.isCurrent)
        #expect(revoked == 1)

        // Its own release, and a second, tell the first nothing more
        second.release()
        second.release()
        first.release()
        #expect(revoked == 1)
        #expect(service.holder == nil)
    }

    @Test func theOlderSurfaceTakingThePlayerEndsTheClaim() async {
        let service = makeService()
        var revoked = 0
        _ = service.claim(.chant, onRevoked: { revoked += 1 })
        service.setTrackNavigation(owner: "rosary", canGoNext: true, canGoPrevious: false, onNext: {}, onPrevious: {})
        #expect(service.holder == nil)
        #expect(revoked == 1)

        _ = service.claim(.chant, onRevoked: { revoked += 1 })
        _ = await service.loadAudio(from: "")
        #expect(service.holder == nil)
        #expect(revoked == 2)
    }

    @Test func aClaimDeclinesWhileSomethingPlaysWhenAskedTo() {
        let service = makeService()
        let chant = service.claim(.chant)!
        service.isPlaying = true
        #expect(service.claim(.consecration, ifIdle: true) == nil)
        #expect(chant.isCurrent)

        service.isPlaying = false
        let day = service.claim(.consecration, ifIdle: true)
        #expect(day != nil)
        #expect(!chant.isCurrent)
    }

    // MARK: - Speed

    @Test func aBorrowedSpeedComesBackWhenTheClaimIsEnded() {
        let service = makeService()
        _ = service.claim(.chant, rate: .borrowed(0.75))
        #expect(service.playbackRate == 0.75)
        #expect(service.appRate == 1.25)

        _ = service.claim(.prayerFlow)
        #expect(service.playbackRate == 1.25)
    }

    @Test func aBorrowedSpeedComesBackOnReleaseAndALaterOneIsKept() {
        let service = makeService()
        let chant = service.claim(.chant, rate: .borrowed(0.75))!
        let book = service.claim(.library, rate: .borrowed(1.5))!
        #expect(service.playbackRate == 1.5)

        // The chant, already ended, hands back nothing that is the book's
        chant.release()
        #expect(service.playbackRate == 1.5)
        #expect(book.isCurrent)

        book.release()
        #expect(service.playbackRate == 1.25)
    }

    @Test func aFlowWithoutAClaimKeepsTheSpeedItBorrowed() {
        let service = makeService()
        _ = service.claim(.chant, rate: .borrowed(0.75))
        // The reading shelf, not yet on claims: its speed, then its arrows
        service.setPlaybackRate(1.5, remember: false, borrower: "book")
        service.setTrackNavigation(owner: "book", canGoNext: true, canGoPrevious: true, onNext: {}, onPrevious: {})
        #expect(service.holder == nil)
        #expect(service.playbackRate == 1.5)
    }

    @Test func aClaimAtTheAppsSpeedTakesItBack() {
        let service = makeService()
        service.setPlaybackRate(1.5, remember: false, borrower: "book")
        _ = service.claim(.consecration)
        #expect(service.playbackRate == 1.25)
    }

    @Test func aClaimsSpeedChangeKeepsToItsPolicy() {
        let service = makeService()
        let chant = service.claim(.chant, rate: .borrowed(0.75))!
        chant.setRate(1.0)
        #expect(service.playbackRate == 1.0)
        #expect(service.appRate == 1.25)
        #expect(chant.ratePolicy == .borrowed(1.0))

        let flow = service.claim(.prayerFlow)!
        #expect(service.playbackRate == 1.25)
        flow.setRate(1.4)
        #expect(service.appRate == 1.4)
        #expect(service.playbackRate == 1.4)

        // An ended claim changes nothing
        chant.setRate(0.5)
        #expect(service.playbackRate == 1.4)
    }

    @Test func theAppsSpeedControlsNeverRetuneABorrowedSpeed() {
        let service = makeService()
        let chant = service.claim(.chant, rate: .borrowed(0.75))!
        service.previewAppRate(1.4)
        #expect(service.playbackRate == 0.75)
        service.setAppRate(1.4)
        #expect(service.playbackRate == 0.75)
        #expect(service.appRate == 1.4)

        // The app's speed, as set meanwhile, comes back with the release
        chant.release()
        #expect(service.playbackRate == 1.4)

        // With nothing borrowed, a drag is heard and a release kept
        service.previewAppRate(1.1)
        #expect(service.playbackRate == 1.1)
        #expect(service.appRate == 1.4)
        service.setAppRate(1.1)
        #expect(service.appRate == 1.1)
    }

    // MARK: - Arrows

    @Test func theArrowsAreTheHoldersAlone() {
        let service = makeService()
        let chant = service.claim(.chant)!
        chant.navigation = navigation()
        #expect(service.isTrackNavigationOwner(chant.token))

        let day = service.claim(.consecration)!
        #expect(!service.isTrackNavigationOwner(chant.token))

        // An ended claim cannot put its arrows back
        chant.navigation = navigation()
        #expect(!service.isTrackNavigationOwner(chant.token))

        day.navigation = navigation()
        day.release()
        #expect(!service.isTrackNavigationOwner(day.token))
    }

    @Test func aClaimTakesOffArrowsAFlowWithoutOneLeft() {
        let service = makeService()
        service.setTrackNavigation(owner: "rosary", canGoNext: true, canGoPrevious: false, onNext: {}, onPrevious: {})
        _ = service.claim(.consecration)
        #expect(!service.isTrackNavigationOwner("rosary"))
    }

    // MARK: - Items

    @Test func aClaimReadsAndDrivesOnlyTheItemItLoaded() async {
        let service = makeService()
        let chant = service.claim(.chant)!
        #expect(await chant.load(recording))
        #expect(chant.holdsItem)
        #expect(chant.duration > 0)

        let day = service.claim(.consecration)!
        #expect(!chant.holdsItem)
        #expect(chant.duration == 0)
        #expect(!day.holdsItem)

        // An ended claim's transport does nothing
        chant.play()
        chant.seek(to: 10)
        #expect(!service.isPlaying)
        #expect(service.currentTime == 0)
    }

    @Test func aClaimNeverInheritsAnothersItem() async {
        let service = makeService()
        let chant = service.claim(.chant)!
        #expect(await chant.load(recording))

        let day = service.claim(.consecration)!
        let generation = service.loadGeneration
        #expect(await day.load(recording))
        #expect(day.holdsItem)
        // The same file, loaded afresh from its top
        #expect(service.loadGeneration > generation)

        // A load of the item it already holds is not a new load
        let own = service.loadGeneration
        #expect(await day.load(recording))
        #expect(service.loadGeneration == own)
    }

    @Test func anItemsEndIsToldToTheClaimThatLoadedIt() async {
        let service = makeService()
        var rosaryFinished = 0
        service.setTrackNavigation(
            owner: "rosary", canGoNext: false, canGoPrevious: false,
            onNext: {}, onPrevious: {}, onFinish: { rosaryFinished += 1 }
        )

        let chant = service.claim(.chant)!
        var chantFinished = 0
        chant.onFinish = { chantFinished += 1 }
        #expect(await chant.load(recording))
        service.itemDidPlayToEnd()
        #expect(chantFinished == 1)
        #expect(rosaryFinished == 0)

        // Once the chant's claim has ended, its item's end is nobody's
        let day = service.claim(.consecration)!
        var dayFinished = 0
        day.onFinish = { dayFinished += 1 }
        service.itemDidPlayToEnd()
        #expect(chantFinished == 1)
        #expect(dayFinished == 0)
    }

    @Test func anItemsFailureIsToldToTheClaimThatLoadedIt() async {
        let service = makeService()
        let chant = service.claim(.chant)!
        var failed = 0
        chant.onFail = { failed += 1 }
        #expect(await chant.load(recording))
        service.itemDidFail()
        #expect(failed == 1)
        #expect(!chant.holdsItem)
    }

    @Test func aFlowWithoutAClaimStillHearsItsOwnItemEnd() async {
        let service = makeService()
        _ = service.claim(.chant)
        #expect(await service.loadAudio(from: recording.absoluteString))
        var finished = 0
        service.setTrackNavigation(
            owner: "rosary", canGoNext: false, canGoPrevious: false,
            onNext: {}, onPrevious: {}, onFinish: { finished += 1 }
        )
        service.itemDidPlayToEnd()
        #expect(finished == 1)
    }

    @Test func aLoadWhoseClaimEndedDropsItsRecording() async {
        let service = makeService()
        let chant = service.claim(.chant)!
        let loading = Task { await chant.load(self.recording) }
        await untilLoading(service)
        _ = service.claim(.consecration)
        #expect(await loading.value == false)
        #expect(!chant.holdsItem)
        #expect(service.currentURL == nil)
    }

    // MARK: - The seam with the older surface

    @Test func aLoadIsDroppedWhenTheOlderSurfaceTakesTheArrowsMeanwhile() async {
        // The reading shelf takes the arrows first and loads a beat later,
        // so nothing newer has been loaded to supersede the claim's load
        let service = makeService()
        let chant = service.claim(.chant)!
        let loading = Task { await chant.load(self.recording) }
        await untilLoading(service)
        service.setTrackNavigation(owner: "book", canGoNext: true, canGoPrevious: true, onNext: {}, onPrevious: {})
        #expect(await loading.value == false)
        #expect(service.currentURL == nil)
        #expect(!service.isLoading)
        #expect(service.isTrackNavigationOwner("book"))
    }

    @Test func aClaimsItemEndIsNotToldToAFlowThatTookTheArrowsWithoutLoadingIt() async {
        let service = makeService()
        var revoked = 0
        let chant = service.claim(.chant, rate: .borrowed(0.75), onRevoked: { revoked += 1 })!
        var chantFinished = 0
        chant.onFinish = { chantFinished += 1 }
        #expect(await chant.load(recording))

        var rosaryFinished = 0
        service.setTrackNavigation(
            owner: "rosary", canGoNext: false, canGoPrevious: false,
            onNext: {}, onPrevious: {}, onFinish: { rosaryFinished += 1 }
        )
        // Ended once, its speed back once, and the arrows the Rosary's
        #expect(revoked == 1)
        #expect(service.playbackRate == 1.25)
        #expect(service.isTrackNavigationOwner("rosary"))

        // The chant still in the player plays out: the Rosary never
        // loaded it, and the claim that did no longer holds the player
        service.itemDidPlayToEnd()
        #expect(chantFinished == 0)
        #expect(rosaryFinished == 0)

        // A late release from the chant leaves the Rosary's arrows be
        chant.release()
        #expect(service.isTrackNavigationOwner("rosary"))
        #expect(revoked == 1)
    }

    // MARK: - Release

    @Test func releaseStopsOnlyItsOwnItemThenGivesTheSpeedBack() async {
        let service = makeService()
        let chant = service.claim(.chant, rate: .borrowed(0.75))!
        chant.navigation = navigation()
        #expect(await chant.load(recording))

        chant.release()
        #expect(service.holder == nil)
        #expect(service.currentURL == nil)
        #expect(service.playbackRate == 1.25)
        #expect(!service.isTrackNavigationOwner(chant.token))
        chant.release()

        // A late release from a claim ended long ago leaves the live one be
        let day = service.claim(.consecration)!
        #expect(await day.load(recording))
        chant.release()
        #expect(day.holdsItem)
    }

    @Test func releaseAfterItsOwnUnloadPutsThePlayerAway() async {
        // A consecration day: a chant heard, then a reading with none, then
        // the day left. The unload keeps the Lock Screen entry for a next
        // load; the release must not keep it for one that is not coming.
        // A service apart from the system has no Lock Screen to read, so
        // the sleep timer — kept across a step, cleared when a flow is
        // left entirely — says which of the two the player was given.
        let service = makeService()
        let day = service.claim(.consecration)!
        #expect(await day.load(recording))
        service.setSleepTimer(.endOfTrack)

        day.unload(preservingNowPlaying: true)
        #expect(service.sleepTimer == .endOfTrack)
        #expect(!day.holdsItem)

        let generation = service.loadGeneration
        day.release()
        #expect(service.sleepTimer == nil)
        #expect(service.loadGeneration > generation)
        #expect(service.holder == nil)
    }

    @Test func aResetFromElsewhereLeavesTheClaimHoldingNothing() async {
        let service = makeService()
        let chant = service.claim(.chant)!
        #expect(await chant.load(recording))
        service.reset()
        #expect(chant.isCurrent)
        #expect(!chant.holdsItem)
    }
}
