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
//  running at the clock's pace; and the entry goes when the flow ends.
//  A meditation set's player is walked through it as well: it holds the
//  player by a claim, and the Lock Screen's play, pause and arrows are
//  the Rosary's own.
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
        #expect(info(service, MPMediaItemPropertyArtwork) is MPMediaItemArtwork)
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
        #expect(info(service, MPMediaItemPropertyArtwork) is MPMediaItemArtwork)
        #expect(service.nowPlayingArtworkName == AudioService.fallbackArtworkAsset)
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
        #expect(info(service, MPMediaItemPropertyArtwork) is MPMediaItemArtwork)
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
}
