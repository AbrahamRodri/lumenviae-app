//
//  LockScreenPlayerTests.swift
//  Lumen Viae Tests
//
//  What the Lock Screen shows and what its controls do, read off a
//  service of its own that keeps off the system: every load publishes a
//  title, a second line and a picture (a flow's own painting, else the
//  fallback, never a blank square); the arrows stand where a flow steps
//  tracks and the ten-second skips where none does; play and pause from
//  outside the screen, and headphones pulled out, reach the owner's own
//  transport; a set's silence shows its whole length on the scrubber,
//  running at the clock's pace, named for the chant it leads to; and
//  the entry goes when the flow ends. A meditation set's player is walked
//  through it as well: it holds the player by a claim, the Lock Screen's
//  play, pause and arrows are the Rosary's own, a pause calls off the
//  next mystery beginning by itself, a play after another flow took the
//  player loads the meditation again, and the meditation heard to its
//  end unlocks the beads.
//

import Foundation
import MediaPlayer
import Testing

@testable import app

@MainActor
@Suite(.serialized)
struct LockScreenPlayerTests {

    private func makeService() -> AudioService {
        let defaults = UserDefaults(suiteName: "LockScreenPlayerTests.\(UUID().uuidString)")!
        return AudioService(integratesWithSystem: false, defaults: defaults)
    }

    /// A recording the app ships
    private var recording: URL { Bundle.main.url(forResource: "chant_silence", withExtension: "m4a")! }

    private func info(_ service: AudioService, _ key: String) -> Any? {
        service.nowPlayingInfo?[key]
    }

    /// Whether the Lock Screen's picture draws an image: the artwork asked
    /// for a size, as the system asks it, hands back something to draw
    private func drawsPicture(_ service: AudioService) -> Bool {
        guard let artwork = info(service, MPMediaItemPropertyArtwork) as? MPMediaItemArtwork,
              let image = artwork.image(at: CGSize(width: 64, height: 64)) else { return false }
        return image.size.width > 0 && image.size.height > 0
    }

    // MARK: - What is published

    @Test func aLoadPublishesTitleSecondLinePictureAndLength() async {
        let service = makeService()
        let claim = service.claim(.chant)!
        let ready = await claim.load(
            recording,
            title: "Salve Regina",
            subtitle: "Chant · Simple melody",
            artworkAssetName: "mary_sistine_madonna",
            album: "Verbum Gloriae"
        )
        #expect(ready)
        #expect(info(service, MPMediaItemPropertyTitle) as? String == "Salve Regina")
        #expect(info(service, MPMediaItemPropertyArtist) as? String == "Chant · Simple melody")
        #expect(info(service, MPMediaItemPropertyAlbumTitle) as? String == "Verbum Gloriae")
        #expect(drawsPicture(service))
        #expect(service.nowPlayingArtworkName == "mary_sistine_madonna")
        let length = info(service, MPMediaItemPropertyPlaybackDuration) as? Double ?? 0
        #expect(length > 0)
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == 0)
        claim.release()
    }

    @Test func aFlowThatNamesNoPictureGetsTheFallback() async {
        let service = makeService()
        let claim = service.claim(.prayerBook)!
        await claim.load(recording, title: "Memorare", subtitle: "Prayers")
        #expect(drawsPicture(service))
        #expect(service.nowPlayingArtworkName == AudioService.fallbackArtworkAsset)
        claim.release()
    }

    @Test func aPictureTheCatalogLacksFallsBackRatherThanDrawNothing() async {
        let service = makeService()
        let claim = service.claim(.chant)!
        await claim.load(recording, title: "Ave Maria", artworkAssetName: "no_such_painting")
        #expect(drawsPicture(service))
        claim.release()
    }

    @Test func theLengthStandsWhileTheFlowIsBetweenRecordings() async {
        let service = makeService()
        let claim = service.claim(.consecration)!
        await claim.load(recording, title: "Veni Creator")
        let length = info(service, MPMediaItemPropertyPlaybackDuration) as? Double ?? 0
        #expect(length > 0)
        claim.unload(preservingNowPlaying: true)
        service.pause()
        service.setPlaybackRate(1.25)
        #expect(info(service, MPMediaItemPropertyPlaybackDuration) as? Double == length)
        claim.release()
    }

    @Test func theEntryGoesWhenTheFlowEnds() async {
        let service = makeService()
        let claim = service.claim(.consecration)!
        await claim.load(recording, title: "Veni Creator", subtitle: "Consecration to Mary · Day 1")
        #expect(service.nowPlayingInfo != nil)

        // Between two steps the entry stays for the next load
        claim.unload(preservingNowPlaying: true)
        #expect(service.nowPlayingInfo != nil)

        claim.release()
        #expect(service.nowPlayingInfo == nil)
        // A pause or a speed change afterwards brings nothing back
        service.pause()
        service.setPlaybackRate(1.5)
        #expect(service.nowPlayingInfo == nil)
    }

    @Test func playAndPauseKeepElapsedAndRateTogether() async {
        let service = makeService()
        let claim = service.claim(.chant)!
        await claim.load(recording, title: "Ave Maria")
        claim.seek(to: 2)
        #expect(info(service, MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double == 2)

        claim.play()
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == service.playbackRate)
        claim.pause()
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == 0)
        #expect((info(service, MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double ?? 0) >= 2)
        claim.release()
    }

    // MARK: - Which controls stand

    @Test func theArrowsStandForAFlowThatStepsAndTheSkipsOtherwise() {
        let service = makeService()
        #expect(
            service.remoteCommandAvailability
                == .init(next: false, previous: false, skipForward: true, skipBackward: true))

        let claim = service.claim(.chant)!
        claim.navigation = AudioNavigation(canGoNext: true, canGoPrevious: false, onNext: {}, onPrevious: {})
        #expect(
            service.remoteCommandAvailability
                == .init(next: true, previous: false, skipForward: false, skipBackward: false))

        claim.navigation?.canGoPrevious = true
        claim.navigation?.canGoNext = false
        #expect(
            service.remoteCommandAvailability
                == .init(next: false, previous: true, skipForward: false, skipBackward: false))

        // A flow with nowhere to step — a prayer opened alone — has the
        // skips rather than nothing
        claim.navigation?.canGoPrevious = false
        #expect(service.remoteCommandAvailability == .init(next: false, previous: false, skipForward: true, skipBackward: true))

        claim.release()
        #expect(service.remoteCommandAvailability.skipForward)
    }

    @Test func anArrowAtTheEndSaysThereIsNothingThere() {
        let service = makeService()
        var stepped = 0
        let claim = service.claim(.prayerFlow)!
        claim.navigation = AudioNavigation(
            canGoNext: false, canGoPrevious: true, onNext: { stepped += 1 }, onPrevious: { stepped += 10 })
        #expect(service.handleRemoteCommand(.nextTrack) == .noSuchContent)
        #expect(service.handleRemoteCommand(.previousTrack) == .success)
        #expect(stepped == 10)
        claim.release()
        #expect(service.handleRemoteCommand(.nextTrack) == .noActionableNowPlayingItem)
    }

    // MARK: - Play and pause reach the owner

    @Test func playAndPauseFromOutsideReachTheOwnersTransport() {
        let service = makeService()
        var asked: [AudioService.TransportRequest] = []
        let claim = service.claim(.chant)!
        claim.onTransport = { asked.append($0) }

        #expect(service.handleRemoteCommand(.pause) == .success)
        #expect(service.handleRemoteCommand(.play) == .success)
        #expect(service.handleRemoteCommand(.togglePlayPause) == .success)
        service.audioRouteLost()
        #expect(asked == [.pause, .play, .toggle, .pause])

        // The claim ended, its transport goes with it, and with nothing
        // loaded there is nothing to play
        claim.release()
        #expect(service.handleRemoteCommand(.play) == .noActionableNowPlayingItem)
        #expect(asked.count == 4)
    }

    @Test func aFlowWithoutAClaimHearsThemThroughItsArrows() {
        let service = makeService()
        var asked: [AudioService.TransportRequest] = []
        service.setTrackNavigation(
            owner: "prayer-book", canGoNext: true, canGoPrevious: false,
            onNext: {}, onPrevious: {}, onTransport: { asked.append($0) }
        )
        service.handleRemoteCommand(.pause)
        service.handleRemoteCommand(.togglePlayPause)
        #expect(asked == [.pause, .toggle])
        service.clearTrackNavigation(owner: "prayer-book")
    }

    @Test func withNoTransportOfItsOwnThePlayerAnswers() async {
        let service = makeService()
        let claim = service.claim(.chant)!
        await claim.load(recording, title: "Ave Maria")
        #expect(service.handleRemoteCommand(.play) == .success)
        #expect(service.isPlaying)
        #expect(service.handleRemoteCommand(.pause) == .success)
        #expect(!service.isPlaying)
        claim.release()
    }

    // MARK: - A set's silence

    @Test func aSilenceShowsItsWholeLengthAtTheClocksPace() async {
        let service = makeService()
        let claim = service.claim(.chant)!
        await claim.load(recording, title: "Tantum Ergo", subtitle: "Adoration and Blessing · Next, after a pause")

        var silence = ChantSilence(note: "", endsAt: Date().addingTimeInterval(120), remaining: 120, length: 120)
        claim.setNowPlayingTimeline(silence.timeline)
        #expect(info(service, MPMediaItemPropertyPlaybackDuration) as? Double == 120)
        #expect(info(service, MPMediaItemPropertyTitle) as? String == "Tantum Ergo")

        claim.play()
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == 1)
        claim.pause()

        // Held with 50 seconds left: 70 seconds in, standing still
        silence.endsAt = nil
        silence.remaining = 50
        claim.setNowPlayingTimeline(silence.timeline)
        #expect(info(service, MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double == 70)
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == 0)

        // The next chant's own length comes back with its load
        claim.unload(preservingNowPlaying: true)
        await claim.load(recording, title: "Laudate Dominum")
        let length = info(service, MPMediaItemPropertyPlaybackDuration) as? Double ?? 0
        #expect(length > 0 && length < 120)
        claim.release()
    }

    // MARK: - A meditation set's player

    private func narratedSet() -> MeditationSet {
        let meditations = MysteryData.mysteries(for: .joyful).map { mystery in
            Meditation(
                id: 2000 + mystery.order, title: nil, content: "Consider…", author: nil, source: nil,
                audioUrl: recording.absoluteString,
                mystery: mystery
            )
        }
        return MeditationSet(
            id: 7, name: "The Joyful Gospel", category: "joyful", description: nil,
            labels: nil, meditations: meditations)
    }

    @Test func aSetsPlayerHoldsThePlayerByAClaimAndAnswersTheLockScreen() async {
        let service = makeService()
        let vm = PrayerSessionViewModel(
            meditationSet: narratedSet(),
            apiService: APIService(session: StubProtocol.session),
            audioService: service
        )
        await vm.loadCurrentAudio()

        #expect(service.holder?.kind == .prayerFlow)
        #expect(info(service, MPMediaItemPropertyArtist) as? String == "The Joyful Gospel")
        #expect(drawsPicture(service))
        #expect(service.nowPlayingArtworkName == Constants.mysteryImageURL(category: "joyful", index: 0))
        #expect(
            service.remoteCommandAvailability
                == .init(next: true, previous: false, skipForward: false, skipBackward: false))

        // The Lock Screen's play and pause are the screen's
        service.handleRemoteCommand(.play)
        #expect(vm.isPlaying)
        service.handleRemoteCommand(.pause)
        #expect(!vm.isPlaying)
        // ...and the screen's are the Lock Screen's
        vm.isPlaying = true
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == service.playbackRate)
        vm.isPlaying = false
        #expect(info(service, MPNowPlayingInfoPropertyPlaybackRate) as? Double == 0)

        // The arrow moves the mystery, and the arrows follow it
        #expect(service.handleRemoteCommand(.nextTrack) == .success)
        #expect(vm.currentMysteryIndex == 1)
        #expect(service.remoteCommandAvailability.previous)

        vm.stopAudio()
        #expect(service.holder == nil)
        #expect(service.nowPlayingInfo == nil)
    }

    @Test func anotherFlowTakingThePlayerSilencesTheSetsReadouts() async {
        let service = makeService()
        let vm = PrayerSessionViewModel(
            meditationSet: narratedSet(),
            apiService: APIService(session: StubProtocol.session),
            audioService: service
        )
        await vm.loadCurrentAudio()
        #expect(vm.totalDuration > 0)

        let chant = service.claim(.chant)!
        #expect(vm.totalDuration == 0)
        #expect(!vm.isPlaying)
        // Leaving the Rosary now leaves the chant's claim alone
        vm.stopAudio()
        #expect(chant.isCurrent)
        chant.release()
    }

    // MARK: - A set's silence, as named

    @Test func aSilenceIsNamedForTheChantItLeadsTo() throws {
        let chants = Array(ChantCatalog.all.prefix(2))
        try #require(chants.count == 2)
        var queue = ChantQueue(
            title: "Before Bed",
            entries: [.chant(chants[0]), .silence(note: "", seconds: 60), .chant(chants[1])],
            origins: [0, 1, 2],
            source: nil
        )
        queue.index = 1
        let shown = ChantSilenceNowPlaying(queue: queue, current: chants[0])
        #expect(shown.title == chants[1].latinTitle)
        #expect(shown.subtitle == "Before Bed · Next, after a pause")
        #expect(shown.painting == ChantCatalog.painting(for: chants[1]))
        #expect(shown.title != "Silence")
    }

    @Test func aSilenceThatEndsTheSetKeepsTheChantJustSung() throws {
        let chant = try #require(ChantCatalog.all.first)
        var queue = ChantQueue(
            title: "Before Bed",
            entries: [.chant(chant), .silence(note: "Rest", seconds: 60)],
            origins: [0, 1],
            source: nil
        )
        queue.index = 1
        let shown = ChantSilenceNowPlaying(queue: queue, current: chant)
        #expect(shown.title == chant.latinTitle)
        #expect(shown.subtitle == "Before Bed")
        #expect(shown.painting == ChantCatalog.painting(for: chant))
    }

    // MARK: - The sets player's transport

    private func setPlayer(_ service: AudioService) -> PrayerSessionViewModel {
        PrayerSessionViewModel(
            meditationSet: narratedSet(),
            showsOpeningPrayers: false,
            apiService: APIService(session: StubProtocol.session),
            audioService: service
        )
    }

    /// Waits on the main actor, a little at a time, until `done` holds.
    /// False when it never did, for the test to say so.
    private func until(_ done: () -> Bool) async -> Bool {
        for _ in 0..<100 where !done() {
            try? await Task.sleep(for: .milliseconds(20))
        }
        return done()
    }

    @Test func aPauseCallsOffTheNextMysteryBeginningByItself() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()

        // The arrow asks the next mystery to begin by itself; the pause
        // that follows at once calls that off
        service.handleRemoteCommand(.nextTrack)
        // On its way to begin, it shows Pause
        #expect(vm.isPlaying)
        service.handleRemoteCommand(.pause)
        #expect(!vm.isPlaying)
        #expect(await until { vm.totalDuration > 0 && vm.currentMysteryIndex == 1 })
        try? await Task.sleep(for: .milliseconds(200))
        #expect(vm.currentMysteryIndex == 1)
        #expect(!vm.isPlaying)
        #expect(!service.isPlaying)
        vm.stopAudio()
    }

    @Test func theScreensPauseCallsItOffToo() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()

        service.handleRemoteCommand(.nextTrack)
        // On its way, the mystery counts as playing for the screen as for
        // the Lock Screen: the screen's pause is a pause, not a play
        #expect(vm.isPlaying)
        vm.isPlaying = false
        #expect(!vm.isPlaying)
        #expect(await until { vm.totalDuration > 0 && vm.currentMysteryIndex == 1 })
        try? await Task.sleep(for: .milliseconds(200))
        #expect(!service.isPlaying)
        vm.stopAudio()
    }

    @Test func aPlayAfterAnotherFlowTookThePlayerLoadsTheMeditationAgain() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()

        let chant = service.claim(.chant)!
        #expect(!chant.holdsItem)
        #expect(service.holder?.kind == .chant)

        vm.isPlaying = true
        #expect(await until { service.holder?.kind == .prayerFlow && service.isPlaying })
        #expect(service.holder?.kind == .prayerFlow)
        #expect(vm.isPlaying)
        #expect(!chant.isCurrent)
        vm.isPlaying = false
        vm.stopAudio()
    }

    @Test func aLoadTheNextMysteryReplacedLeavesItsStartToTheNewerLoad() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()
        vm.isPlaying = true

        // NEXT while the first mystery sounds: the second is on its way to
        // begin by itself, and NEXT again replaces its load mid-way
        _ = vm.nextMystery()
        let replaced = Task { await vm.loadCurrentAudio() }
        // A local recording arrives within a turn or two: yield only until
        // the load has begun, not past its arrival
        for _ in 0..<50 where !service.isLoading { await Task.yield() }
        #expect(service.isLoading)
        _ = vm.nextMystery()
        await vm.loadCurrentAudio()
        await replaced.value

        #expect(vm.currentMysteryIndex == 2)
        #expect(service.isPlaying, "the newer load keeps the wish to play on")
        let third = vm.currentMeditation?.displayTitle
        #expect(info(service, MPMediaItemPropertyTitle) as? String == third)
        #expect(service.nowPlayingArtworkName == Constants.mysteryImageURL(category: "joyful", index: 2))
        vm.isPlaying = false
        vm.stopAudio()
    }

    @Test func aMysteryWithNoNarrationIsNamedAsItself() async {
        let set = narratedSet()
        var meditations = set.meditations ?? []
        let silent = meditations[1]
        meditations[1] = Meditation(
            id: silent.id, title: nil, content: silent.content, author: nil, source: nil,
            audioUrl: nil, mystery: silent.mystery
        )
        let service = makeService()
        let vm = PrayerSessionViewModel(
            meditationSet: MeditationSet(
                id: set.id, name: set.name, category: set.category, description: nil,
                labels: nil, meditations: meditations),
            showsOpeningPrayers: false,
            apiService: APIService(session: StubProtocol.session),
            audioService: service
        )
        await vm.loadCurrentAudio()
        _ = vm.nextMystery()
        await vm.loadCurrentAudio()

        #expect(info(service, MPMediaItemPropertyTitle) as? String == meditations[1].displayTitle)
        #expect(service.nowPlayingArtworkName == Constants.mysteryImageURL(category: "joyful", index: 1))
        #expect(service.remoteCommandAvailability.next, "the arrows still step past it")
        vm.stopAudio()
        #expect(service.nowPlayingInfo == nil)
    }

    @Test func leavingBeforeTheWholeRosaryBeginsClearsTheLockScreen() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()
        #expect(service.nowPlayingInfo != nil)

        // Settled first, so the Whole Rosary below is chosen mid-Rosary,
        // while paused: it waits for play, holding the meditation's entry
        await vm.setPrayAloud(false)
        let turnedOn = Task { await vm.setPrayAloud(true) }
        for _ in 0..<50 where !vm.isPrayingAloud { await Task.yield() }
        #expect(vm.isPrayingAloud)
        #expect(service.holder?.kind == .prayerFlow, "the entry is kept for the voice")

        // Left before the voice took the player
        vm.stopAudio()
        await turnedOn.value
        #expect(service.holder == nil)
        #expect(service.nowPlayingInfo == nil, "no entry whose play does nothing")
    }

    @Test func theMeditationHeardToItsEndUnlocksTheBeads() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()
        #expect(!vm.beadsUnlocked, "the meditation comes first")

        service.itemDidPlayToEnd()
        #expect(vm.beadsUnlocked)
        vm.stopAudio()
    }

    @Test func aFailedLoadsErrorGoesWithTheMysteryLeft() async {
        let service = makeService()
        let vm = setPlayer(service)
        await vm.loadCurrentAudio()
        service.itemDidFail()
        #expect(vm.audioErrorMessage != nil)

        _ = vm.nextMystery()
        #expect(vm.audioErrorMessage == nil)
        #expect(!vm.beadsUnlocked, "the next mystery's meditation is still to be heard")
        vm.stopAudio()
    }
}
