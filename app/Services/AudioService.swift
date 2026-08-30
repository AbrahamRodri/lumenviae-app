//
//  AudioService.swift
//  Lumen Viae
//
//  Meditation audio playback via AVFoundation. Singleton so audio state
//  lives in one place and playback survives view changes.
//
//  Integrates with the system so guided prayer works eyes-closed:
//  - Now Playing metadata on the Lock Screen / Control Center
//  - Remote commands (headphones, AirPods, watch): play, pause, skip, scrub
//  - Interruption handling (calls, Siri) and headphone-unplug pausing
//

import AVFoundation
import Foundation
import MediaPlayer
import UIKit

@Observable
final class AudioService {

    static let shared = AudioService()

    // MARK: - Observable State

    var isPlaying = false

    /// Current playback position in seconds
    var currentTime: Double = 0

    /// Total duration of the loaded audio in seconds
    var duration: Double = 0

    var isLoading = false

    /// True while the player is stalled waiting for data — a weak signal
    /// mid-decade. Distinct from `isLoading`, which covers the initial load.
    var isBuffering = false

    /// Error message if playback fails (nil on success)
    var errorMessage: String?

    // MARK: - Private Properties

    private var player: AVPlayer?

    /// Token for the periodic time observer (must be removed on cleanup)
    private var timeObserver: Any?

    /// Currently loaded audio URL (for avoiding redundant loads)
    /// Readable so a surface that shares the player (the Chapel's chant
    /// tile) can tell whether the loaded audio is still its own — a
    /// Rosary that claims the player simply silences that tile's readouts.
    private(set) var currentURL: URL?

    /// Monotonic load token. Each loadAudio call claims a new generation;
    /// after every await it checks it still owns the current one, so a
    /// superseded or cancelled load can never mutate the newer load's state.
    ///
    /// Readable because the URL alone is not ownership: two flows can load
    /// the same file (the consecration's chants and the Chapel's chant tile
    /// are the same three recordings), and a surface that pinned its claim
    /// to the URL would narrate and drive playback it never started. Pairing
    /// the URL with the generation it was loaded under is what distinguishes
    /// "still mine" from "the same file, someone else's".
    private(set) var loadGeneration = 0

    private var endOfPlaybackObserver: NSObjectProtocol?

    /// Title/subtitle shown on the Lock Screen for the loaded audio
    private var nowPlayingTitle: String?
    private var nowPlayingSubtitle: String?

    /// Album line and queue position ("Mystery 3 of 5") for the Lock Screen.
    private var nowPlayingAlbum: String?
    private var nowPlayingQueueIndex: Int?
    private var nowPlayingQueueCount: Int?

    /// KVO on the player's real transport state. `isPlaying` used to be a
    /// hand-maintained Bool that only this class wrote, so after any
    /// system-side stop — a stall, an interruption whose `.ended` never
    /// arrives, a route loss — the transport and the Lock Screen kept
    /// claiming "playing" over silence. These reconcile it with reality.
    private var timeControlObservation: NSKeyValueObservation?
    private var stallObservation: NSKeyValueObservation?

    /// Deferred resume after an interruption that arrived without
    /// `.shouldResume`. Cancellable so a user pause beats it.
    private var pendingResumeTask: Task<Void, Never>?

    /// Asset name of the Lock Screen artwork, with the built artwork
    /// cached — MPMediaItemArtwork construction isn't free and Now
    /// Playing refreshes happen on every play/pause/seek.
    private var nowPlayingArtworkAsset: String?
    private var cachedArtwork: (asset: String, artwork: MPMediaItemArtwork)?

    /// A painting already decoded by the caller — a set's own, fetched
    /// from the API — which wins over the asset name when present. Kept
    /// with its built artwork for the same reason as the asset's.
    private var nowPlayingArtworkImage: UIImage?
    private var cachedImageArtwork: (image: UIImage, artwork: MPMediaItemArtwork)?

    // MARK: - Initialization

    private init() {
        setupAudioSession()
        setupRemoteCommands()
        setupSessionObservers()
    }

    deinit {
        removeTimeObserver()
        if let observer = endOfPlaybackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Audio Session Setup

    /// Configures the audio session category for playback
    /// (.playback plays even with the mute switch on).
    ///
    /// The session is NOT activated here — activation silences other
    /// apps' audio. It happens when the user actually plays, or on load
    /// for a caller that asks for `claimNowPlaying` (the prayer flow,
    /// which must answer headphone presses before the first tap).
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        } catch {
            #if DEBUG
            print("AudioService: Failed to set up audio session: \(error)")
            #endif
        }
        #endif
    }

    /// Hands the audio session back to the system so other apps' audio can
    /// resume. Call when leaving a prayer flow, not between mysteries.
    func deactivateSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        #endif
    }

    /// Whether audio was actually playing when an interruption began, so
    /// `.ended` never auto-resumes audio the user had deliberately paused.
    private var wasPlayingBeforeInterruption = false

    /// Interruptions (calls, Siri) pause the player under us — keep
    /// `isPlaying` truthful so the UI never shows a pause icon over
    /// silence, and resume when the system says we should.
    private func setupSessionObservers() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            switch type {
            case .began:
                // Sample the user's intent, not the transport: the system
                // has usually already paused us, so `isPlaying` may have
                // been reconciled to false before this handler runs.
                self.wasPlayingBeforeInterruption = self.userIntendsPlayback
                self.isPlaying = false
                self.updateNowPlayingPlaybackState()
            case .ended:
                let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                // `.shouldResume` is advisory and often absent after a short
                // system interruption (a Maps turn prompt, a timer). For
                // spoken prayer with the phone locked, not resuming ends the
                // Rosary silently — so resume whenever we were the one
                // playing. play() refuses safely if the session is still held.
                if self.wasPlayingBeforeInterruption {
                    if options.contains(.shouldResume) {
                        self.play()
                    } else {
                        // Give the interrupter a moment to release the
                        // session. Cancellable, so a user pause or a
                        // headphone unplug in that window wins.
                        self.pendingResumeTask?.cancel()
                        self.pendingResumeTask = Task { @MainActor [weak self] in
                            try? await Task.sleep(for: .milliseconds(300))
                            guard let self, !Task.isCancelled,
                                  self.wasPlayingBeforeInterruption else { return }
                            self.play()
                            self.wasPlayingBeforeInterruption = false
                        }
                        return
                    }
                }
                self.wasPlayingBeforeInterruption = false
            @unknown default:
                break
            }
        }

        // Unplugging headphones pauses system-side; mirror it in our state.
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
                  reason == .oldDeviceUnavailable else { return }
            self.pause()
        }

        // The audio server can be reset out from under us. Every player and
        // the session category die with it; without this the transport keeps
        // claiming to play over a dead pipeline until the app is relaunched.
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // Every player and the session category die with the reset, so
            // the old AVPlayer is unusable. Tear it down: leaving it
            // installed made the same-URL guard in loadAudio short-circuit,
            // and the "press play" this message asks for could never work.
            self.setupAudioSession()
            self.reset()
            self.errorMessage = "Audio was interrupted by the system — reopen this mystery to continue"
        }
        #endif
    }

    // MARK: - Track Navigation (headphones / Lock Screen)

    /// Who currently owns track navigation.
    ///
    /// The service is a singleton and more than one flow drives it (the
    /// Rosary and each consecration day). Without an owner token, a flow
    /// that ends without tearing down leaves its closures installed, and
    /// the next flow's AirPods press advances a Rosary the user already
    /// left. Every install names an owner; only that owner can clear it.
    private var trackNavigationOwner: AnyHashable?

    private var onNextTrack: (() -> Void)?
    private var onPreviousTrack: (() -> Void)?

    /// What to do when a track reaches its end — owned by the same token
    /// as the arrows, and cleared with them.
    private var onTrackFinished: (() -> Void)?

    /// Whether a next/previous step exists right now. The Lock Screen
    /// arrows and AirPods presses are enabled from these, so pressing ⏭ on
    /// the last mystery reports "no such content" instead of drawing a live
    /// control that silently does nothing.
    private var canGoNext = false
    private var canGoPrevious = false

    /// Installs track navigation for `owner`, replacing any previous owner's.
    /// `onFinish` runs when a track plays to its end, and only while this
    /// owner still holds navigation. The prayer flow leaves it nil — a
    /// decade is a meditation plus ten Hail Marys, and the next mystery
    /// begins when the person praying says so — while a recording of a
    /// book is a reading, which runs on to the next track by itself.
    func setTrackNavigation(
        owner: AnyHashable,
        canGoNext: Bool,
        canGoPrevious: Bool,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onFinish: (() -> Void)? = nil
    ) {
        trackNavigationOwner = owner
        self.canGoNext = canGoNext
        self.canGoPrevious = canGoPrevious
        onNextTrack = onNext
        onPreviousTrack = onPrevious
        onTrackFinished = onFinish
        updateTrackCommandAvailability()
    }

    /// Updates only the end-of-set availability for the current owner.
    func updateTrackNavigation(owner: AnyHashable, canGoNext: Bool, canGoPrevious: Bool) {
        guard trackNavigationOwner == owner else { return }
        self.canGoNext = canGoNext
        self.canGoPrevious = canGoPrevious
        updateTrackCommandAvailability()
    }

    /// Whether `owner` still holds track navigation — lets a flow tell
    /// whether it is still the live one before tearing anything down.
    func isTrackNavigationOwner(_ owner: AnyHashable) -> Bool {
        trackNavigationOwner == owner
    }

    /// Removes track navigation, but only if `owner` still holds it — a
    /// late teardown from an abandoned flow must not disarm the live one.
    func clearTrackNavigation(owner: AnyHashable) {
        guard trackNavigationOwner == owner else { return }
        trackNavigationOwner = nil
        onNextTrack = nil
        onPreviousTrack = nil
        onTrackFinished = nil
        canGoNext = false
        canGoPrevious = false
        updateTrackCommandAvailability()
    }

    private func updateTrackCommandAvailability() {
        let center = MPRemoteCommandCenter.shared()
        let hasNavigation = trackNavigationOwner != nil

        // Track arrows appear only where there is somewhere to go.
        center.nextTrackCommand.isEnabled = hasNavigation && canGoNext
        center.previousTrackCommand.isEnabled = hasNavigation && canGoPrevious

        // ±10s stays available whenever a flow is not driving tracks, so a
        // missed line can still be replayed from the Lock Screen.
        center.skipForwardCommand.isEnabled = !hasNavigation
        center.skipBackwardCommand.isEnabled = !hasNavigation
    }

    // MARK: - Remote Commands (Lock Screen / headphones / watch)

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else { return .noActionableNowPlayingItem }
            self.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else { return .noActionableNowPlayingItem }
            self.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else { return .noActionableNowPlayingItem }
            self.togglePlayback()
            return .success
        }

        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else { return .noActionableNowPlayingItem }
            self.skipForward()
            return .success
        }

        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else { return .noActionableNowPlayingItem }
            self.skipBackward()
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, self.player != nil,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .noActionableNowPlayingItem
            }
            self.seek(to: event.positionTime)
            return .success
        }

        // AirPods double/triple presses arrive as track commands, not
        // skips — without these, a double-tap does nothing at all.
        // `.noSuchContent` at the ends: reporting `.success` for a press
        // that did nothing tells iOS the gesture landed, so the user gets
        // neither movement nor feedback.
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, let advance = self.onNextTrack else { return .noActionableNowPlayingItem }
            guard self.canGoNext else { return .noSuchContent }
            advance()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, let back = self.onPreviousTrack else { return .noActionableNowPlayingItem }
            guard self.canGoPrevious else { return .noSuchContent }
            back()
            return .success
        }

        // Press-and-hold scrubbing. Wired remotes, most Bluetooth car head
        // units, and Apple TV send seekForward/seekBackward rather than the
        // skip commands, so without these a hold gesture does nothing.
        center.seekForwardCommand.addTarget { [weak self] event in
            guard let self, self.player != nil,
                  let event = event as? MPSeekCommandEvent else { return .noActionableNowPlayingItem }
            self.handleSeekGesture(type: event.type, forward: true)
            return .success
        }
        center.seekBackwardCommand.addTarget { [weak self] event in
            guard let self, self.player != nil,
                  let event = event as? MPSeekCommandEvent else { return .noActionableNowPlayingItem }
            self.handleSeekGesture(type: event.type, forward: false)
            return .success
        }

        // Narration speed, from the Lock Screen and CarPlay.
        center.changePlaybackRateCommand.supportedPlaybackRates = Self.supportedRates.map(NSNumber.init)
        center.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let self, self.player != nil,
                  let event = event as? MPChangePlaybackRateCommandEvent else {
                return .noActionableNowPlayingItem
            }
            self.setPlaybackRate(Double(event.playbackRate))
            return .success
        }

        // Anything left at its default `isEnabled = true` with no target
        // draws a live control that does nothing. Turn them off explicitly.
        for unsupported in [
            center.stopCommand,
            center.changeRepeatModeCommand,
            center.changeShuffleModeCommand,
            center.likeCommand,
            center.dislikeCommand,
            center.bookmarkCommand,
            center.ratingCommand,
            center.enableLanguageOptionCommand,
            center.disableLanguageOptionCommand
        ] as [MPRemoteCommand] {
            unsupported.isEnabled = false
        }

        updateTrackCommandAvailability()
    }

    // MARK: - Playback Rate

    /// Narration speeds offered on screen and to the system.
    static let supportedRates: [Double] = [0.75, 1.0, 1.25, 1.5, 2.0]

    private static let rateStorageKey = "userSettings.narrationRate"

    /// Playback speed, persisted — a reader who needs 1.25x needs it every
    /// time. Applied only while playing, since setting a non-zero rate on
    /// an AVPlayer is itself a command to start playing.
    private(set) var playbackRate: Double = {
        let stored = UserDefaults.standard.double(forKey: "userSettings.narrationRate")
        return AudioService.supportedRates.contains(stored) ? stored : 1.0
    }()

    /// Sets the speed of whatever is playing.
    ///
    /// `remember` writes it as the app-wide narration speed. A flow that
    /// keeps its own — the Spiritual Reading shelf, where the speed
    /// belongs to the book and its reader — passes false, so choosing
    /// 1.5x for a slow LibriVox volunteer does not also speed up the
    /// Rosary's meditations.
    func setPlaybackRate(_ rate: Double, remember: Bool = true) {
        let resolved = Self.supportedRates.contains(rate) ? rate : 1.0
        playbackRate = resolved
        if remember {
            UserDefaults.standard.set(resolved, forKey: Self.rateStorageKey)
        }
        if isPlaying { player?.rate = Float(resolved) }
        updateNowPlayingPlaybackState()
    }

    /// Puts the app-wide narration speed back, for a flow that borrowed
    /// the transport at a speed of its own.
    func restoreRememberedRate() {
        let stored = UserDefaults.standard.double(forKey: Self.rateStorageKey)
        setPlaybackRate(Self.supportedRates.contains(stored) ? stored : 1.0, remember: false)
    }

    // MARK: - Sleep Timer

    /// How a sleep timer ends: at a chosen span, or when the reading
    /// being played reaches its own end.
    enum SleepTimer: Equatable {
        case after(minutes: Int)
        case endOfTrack
    }

    /// The armed timer, or nil. Observed, so a view can draw the moon
    /// filled and name what it is waiting for.
    private(set) var sleepTimer: SleepTimer?

    /// Seconds left before the fade begins — nil when nothing is armed,
    /// and nil for `.endOfTrack`, whose end is the track's own.
    private(set) var sleepRemaining: Int?

    private var sleepTask: Task<Void, Never>?

    /// Arms (or re-arms) the sleep timer. Passing nil disarms it.
    ///
    /// A devotional recording is not guillotined: the last four seconds
    /// fade out, so the voice withdraws rather than being cut off, and
    /// the volume is restored afterwards so the next play is not silent.
    func setSleepTimer(_ timer: SleepTimer?) {
        sleepTask?.cancel()
        sleepTask = nil
        sleepTimer = timer
        sleepRemaining = nil

        guard let timer else { return }
        guard case .after(let minutes) = timer else {
            // `.endOfTrack` needs no clock — the end-of-playback observer
            // already fires there, and `handleSleepAtTrackEnd` reads it.
            return
        }

        sleepRemaining = minutes * 60
        sleepTask = Task { @MainActor [weak self] in
            while let self, let left = self.sleepRemaining, left > 0 {
                // A paused reading does not burn its timer down — and it
                // does not wake the main actor once a second either,
                // which an armed hour would have done three thousand
                // times over.
                let step: Duration = self.isPlaying ? .seconds(1) : .seconds(5)
                try? await Task.sleep(for: step)
                guard !Task.isCancelled, self.sleepTimer != nil else { return }
                guard self.isPlaying else { continue }
                self.sleepRemaining = max(0, left - 1)
            }
            guard let self, !Task.isCancelled, self.sleepTimer != nil else { return }
            await self.fadeOutAndPause()
        }
    }

    /// Whether a `.endOfTrack` timer should stop the reading here rather
    /// than letting it run on. Read by the flow that owns track stepping.
    func consumeEndOfTrackSleep() -> Bool {
        guard sleepTimer == .endOfTrack else { return false }
        setSleepTimer(nil)
        return true
    }

    /// Withdraws the voice over four seconds, then pauses and restores
    /// the volume for next time.
    ///
    /// Disarming the timer during the fade calls it off entirely: the
    /// volume comes back and the reading runs on. Falling through to
    /// `pause()` here stopped a reading a second after the reader had
    /// explicitly asked it to keep going.
    private func fadeOutAndPause() async {
        let steps = 16
        for step in 0..<steps {
            guard !Task.isCancelled, sleepTimer != nil else {
                player?.volume = 1
                return
            }
            player?.volume = Float(1.0 - Double(step + 1) / Double(steps))
            try? await Task.sleep(for: .milliseconds(250))
        }
        pause()
        player?.volume = 1
        sleepTimer = nil
        sleepRemaining = nil
        sleepTask = nil
    }

    /// True while a press-and-hold scrub is running. The transport observer
    /// checks it before reconciling `isPlaying`, so a scrub can never be
    /// mistaken for the user starting or stopping playback.
    private(set) var isScrubbing = false
    private var wasPlayingBeforeSeek = false
    private var scrubTask: Task<Void, Never>?

    /// Press-and-hold scrub.
    ///
    /// Deliberately NOT done by assigning `player.rate`: these assets are
    /// MP3, which AVFoundation cannot play in fast reverse, and a non-zero
    /// rate is itself a command to start playing — so a hold-to-rewind
    /// while paused would have begun playback, and the transport observer
    /// would have laundered the scrub back into `isPlaying`. Stepping with
    /// `seek` works in both directions and never changes play state.
    private func handleSeekGesture(type: MPSeekCommandEventType, forward: Bool) {
        switch type {
        case .beginSeeking:
            guard !isScrubbing else { return }
            isScrubbing = true
            wasPlayingBeforeSeek = isPlaying
            scrubTask = Task { @MainActor [weak self] in
                while let self, self.isScrubbing, !Task.isCancelled {
                    let step: Double = forward ? 3 : -3
                    self.seek(to: min(max(self.currentTime + step, 0), self.duration))
                    try? await Task.sleep(for: .milliseconds(200))
                }
            }
        case .endSeeking:
            endScrub()
        @unknown default:
            endScrub()
        }
    }

    private func endScrub() {
        scrubTask?.cancel()
        scrubTask = nil
        guard isScrubbing else { return }
        isScrubbing = false
        // Restore exactly the state the gesture started in.
        player?.rate = wasPlayingBeforeSeek ? Float(playbackRate) : 0
        isPlaying = wasPlayingBeforeSeek
        updateNowPlayingPlaybackState()
    }

    // MARK: - Now Playing Info

    /// Swaps the Lock Screen painting for a track already published —
    /// the set's painting arriving a moment after its narration loaded.
    /// Nothing else about the track changes, so only the artwork moves.
    @MainActor
    func updateNowPlayingArtwork(image: UIImage) {
        nowPlayingArtworkImage = image
        guard player != nil else { return }
        updateNowPlayingInfo()
    }

    /// Publishes metadata to the Lock Screen / Control Center.
    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = nowPlayingTitle ?? "Meditation"
        info[MPMediaItemPropertyArtist] = nowPlayingSubtitle ?? "Lumen Viae"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPNowPlayingInfoPropertyIsLiveStream] = false
        if let album = nowPlayingAlbum {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        // "3 of 5" on the Lock Screen, so a user stepping through with the
        // arrows knows where in the Rosary they are without unlocking.
        if let index = nowPlayingQueueIndex, let count = nowPlayingQueueCount {
            info[MPNowPlayingInfoPropertyPlaybackQueueIndex] = index
            info[MPNowPlayingInfoPropertyPlaybackQueueCount] = count
        }
        if let artwork = lockScreenArtwork() {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    /// Nominal bounds for Lock Screen artwork. The request handler hands
    /// back the asset at its natural size and the system scales it.
    private static let artworkBounds = CGSize(width: 1024, height: 1024)

    /// The mystery's painting on the Lock Screen player.
    ///
    /// The image is loaded inside the request handler, which the system
    /// calls lazily and off this path: decoding a full-screen painting
    /// here would run on the main actor at exactly the moment the
    /// artwork transition is animating on screen.
    private func lockScreenArtwork() -> MPMediaItemArtwork? {
        if let image = nowPlayingArtworkImage {
            if let cached = cachedImageArtwork, cached.image === image {
                return cached.artwork
            }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            cachedImageArtwork = (image, artwork)
            return artwork
        }

        guard let asset = nowPlayingArtworkAsset else { return nil }
        if let cached = cachedArtwork, cached.asset == asset {
            return cached.artwork
        }
        let artwork = MPMediaItemArtwork(boundsSize: Self.artworkBounds) { _ in
            UIImage(named: asset) ?? UIImage()
        }
        cachedArtwork = (asset, artwork)
        return artwork
    }

    /// Cheap update of just position/rate after play/pause/seek.
    ///
    /// The elapsed/rate pair must be written together: iOS extrapolates the
    /// Lock Screen scrubber from elapsed at the moment rate was set, so a
    /// stale elapsed makes the scrubber drift or crawl over silence.
    private func updateNowPlayingPlaybackState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            updateNowPlayingInfo()
            return
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    // MARK: - Loading Audio

    /// Loads audio from a URL string, skipping if the same URL is already
    /// loaded. `title`/`subtitle`/`artworkAssetName` feed the Lock Screen.
    ///
    /// `claimNowPlaying` makes this the Now Playing app as soon as the
    /// audio is ready, before any on-screen play — hands-off prayer needs
    /// headphone presses to reach it. Callers that must not take the
    /// route until the user presses play leave it off.
    ///
    /// Returns whether *this* call left the audio ready to play. A caller
    /// cannot tell that from the service's own state afterwards: a load
    /// superseded by a newer one returns silently, and the newer one has
    /// already zeroed `duration` and cleared `errorMessage` on its way
    /// past — so "no error and no duration" reads identically to a real
    /// network failure. Judging by that is how a stale load came to
    /// report the live one as unreachable.
    @MainActor
    @discardableResult
    func loadAudio(
        from urlString: String,
        title: String? = nil,
        subtitle: String? = nil,
        artworkAssetName: String? = nil,
        artworkImage: UIImage? = nil,
        album: String? = nil,
        queueIndex: Int? = nil,
        queueCount: Int? = nil,
        claimNowPlaying: Bool = false,
        startAt: Double = 0
    ) async -> Bool {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid audio URL"
            return false
        }

        // Skip if same URL already loaded
        if url == currentURL && player != nil {
            nowPlayingTitle = title ?? nowPlayingTitle
            nowPlayingSubtitle = subtitle ?? nowPlayingSubtitle
            nowPlayingArtworkAsset = artworkAssetName ?? nowPlayingArtworkAsset
            nowPlayingArtworkImage = artworkImage ?? nowPlayingArtworkImage
            nowPlayingAlbum = album ?? nowPlayingAlbum
            nowPlayingQueueIndex = queueIndex ?? nowPlayingQueueIndex
            nowPlayingQueueCount = queueCount ?? nowPlayingQueueCount
            // The same track handed over again with a place to resume
            // from still has to go there. This branch never touches the
            // transport, so without the seek a resume into the track
            // already loaded would silently start from wherever the
            // playhead happened to be.
            if startAt > 0, duration > 0, startAt < duration - 1 {
                seek(to: startAt)
            }
            updateNowPlayingInfo()
            // Ready only once the duration is known — a second call for a
            // track whose first load is still in flight is not a failure,
            // but it is not ready either.
            return duration > 0
        }

        // reset() invalidates any in-flight load; claim our generation
        // after. Now Playing survives so switching mysteries doesn't
        // collapse the Lock Screen player mid-session.
        reset(preservingNowPlaying: true)
        let generation = loadGeneration

        isLoading = true
        currentURL = url
        nowPlayingTitle = title
        nowPlayingSubtitle = subtitle
        nowPlayingArtworkAsset = artworkAssetName
        nowPlayingArtworkImage = artworkImage
        nowPlayingAlbum = album
        nowPlayingQueueIndex = queueIndex
        nowPlayingQueueCount = queueCount

        // One asset, shared by the player item and the duration load. Built
        // separately, the same presigned URL was opened twice for every
        // track — the player's fetch plus a throwaway asset's.
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        do {
            let cmDuration = try await asset.load(.duration)

            // A newer load (or a reset) owns the state now — hands off.
            guard generation == loadGeneration else { return false }

            duration = CMTimeGetSeconds(cmDuration)
            if duration.isNaN || duration.isInfinite {
                duration = 0
            }

            // An unplayable/indefinite asset would leave a silently dead
            // transport — say so instead.
            guard duration > 0 else {
                reset()
                errorMessage = "Audio unavailable — try again later"
                return false
            }
        } catch {
            // Superseded loads exit without touching the newer load's state.
            guard generation == loadGeneration else { return false }
            isLoading = false

            // Cancelled while current (view going away): quiet exit.
            if Task.isCancelled { return false }

            // The asset is unreachable (offline, or an expired link) —
            // tear down so the UI shows the failure instead of a dead
            // transport that plays silence.
            #if DEBUG
            print("AudioService: Failed to load audio: \(error)")
            #endif
            reset()
            errorMessage = "Audio unavailable — check your connection"
            return false
        }

        // Where the voice left off. Seeking before the observers are
        // installed keeps `currentTime` from reporting 0 for a beat and
        // publishing a Lock Screen playhead at the head of a track the
        // reader is resuming forty minutes in.
        if startAt > 0, startAt < duration - 1 {
            await player?.seek(
                to: CMTime(seconds: startAt, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
            guard generation == loadGeneration else { return false }
            currentTime = startAt
        }

        setupTimeObserver()
        setupNotifications(for: playerItem)
        observeTransportState(for: playerItem)
        updateNowPlayingInfo()

        // Become the Now Playing app while the audio is merely ready:
        // otherwise headphone play presses keep controlling whatever app
        // played last until the user has once tapped play on screen, and
        // the Lock Screen shows nothing to resume. Never claim the route
        // while another app is actually playing.
        if claimNowPlaying {
            activateSessionIfIdle()
        }

        isLoading = false
        return true
    }

    /// Activates the audio session when no other app is playing, so remote
    /// commands route here before the first on-screen play.
    private func activateSessionIfIdle() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        guard !session.isOtherAudioPlaying else { return }
        try? session.setActive(true)
        #endif
    }

    // MARK: - Playback Controls

    /// Toggles between play and pause
    func togglePlayback() {
        guard player != nil else { return }
        if isPlaying { pause() } else { play() }
    }

    /// Starts playback (no-op if already playing).
    ///
    /// Refuses to claim a playing state the session never granted: if
    /// activation fails the transport stays paused and says why, instead of
    /// showing a pause icon over silence on screen and on the Lock Screen.
    func play() {
        guard let player, !isPlaying else { return }
        userIntendsPlayback = true
        guard reactivateSessionIfNeeded() else {
            // Don't claim a playing state the session never granted, but do
            // keep trying in the background — this is usually a phone call
            // still letting go, and it resolves within a second.
            isPlaying = false
            retryActivationThenPlay()
            updateNowPlayingPlaybackState()
            return
        }
        errorMessage = nil
        player.rate = Float(playbackRate)
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    /// Pauses playback (no-op if already paused)
    func pause() {
        userIntendsPlayback = false
        // A user pause outranks any resume still waiting on the session.
        activationRetryTask?.cancel()
        pendingResumeTask?.cancel()
        guard let player, isPlaying else { return }
        player.pause()
        isPlaying = false
        isBuffering = false
        updateNowPlayingPlaybackState()
    }

    /// Reactivates the session, retrying the documented race where a just-
    /// ended interruption has not finished tearing down its own session and
    /// `setActive` throws `cannotInterruptOthers`. Swallowing that failure
    /// is what made a post-phone-call resume produce silence.
    ///
    /// - Returns: whether the session is active and safe to play into.
    @discardableResult
    private func reactivateSessionIfNeeded() -> Bool {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            #if DEBUG
            print("AudioService: session activation failed: \(error)")
            #endif
            return false
        }
        #else
        return true
        #endif
    }

    /// Retries activation off the hot path.
    ///
    /// A just-ended interruption may not have finished releasing the session,
    /// so the first `setActive` throws `cannotInterruptOthers`. Retrying must
    /// NOT spin the main thread: this class is main-actor isolated, and the
    /// very callbacks the retry waits on are delivered through the run loop
    /// a `Thread.sleep` would have frozen.
    private func retryActivationThenPlay() {
        activationRetryTask?.cancel()
        activationRetryTask = Task { @MainActor [weak self] in
            for _ in 0..<3 {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, !Task.isCancelled, self.userIntendsPlayback else { return }
                if self.reactivateSessionIfNeeded() {
                    self.errorMessage = nil
                    self.player?.rate = Float(self.playbackRate)
                    self.isPlaying = true
                    self.updateNowPlayingPlaybackState()
                    return
                }
            }
        }
    }

    private var activationRetryTask: Task<Void, Never>?

    /// What the *user* asked for, as opposed to what the transport is doing.
    ///
    /// The transport observer reconciles `isPlaying` with reality, so by the
    /// time an interruption handler ran, `isPlaying` had often already been
    /// cleared by the system pausing us — and resume-after-a-call never
    /// fired. Only explicit user-intent paths write this.
    private var userIntendsPlayback = false

    /// Seeks to a specific time in seconds.
    func seek(to time: Double) {
        guard let player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
        currentTime = time
        updateNowPlayingPlaybackState()
    }

    /// Skips forward by the specified number of seconds
    func skipForward(_ seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    /// Skips backward by the specified number of seconds
    func skipBackward(_ seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    /// Stops playback and resets all state.
    ///
    /// Called when changing mysteries or leaving the prayer screen.
    /// `preservingNowPlaying` keeps the Lock Screen player alive across
    /// an in-flow change of track (the next load republishes over it);
    /// leaving a flow entirely clears it.
    func reset(preservingNowPlaying: Bool = false) {
        // Invalidate any in-flight load so its continuation can't mutate
        // the state this reset establishes.
        loadGeneration &+= 1

        pause()
        // An in-flow track change preserves the sleep timer along with the
        // Lock Screen player: "stop in fifteen minutes" means fifteen
        // minutes, not fifteen minutes or the end of this file, whichever
        // comes first. Leaving the flow entirely clears it.
        if !preservingNowPlaying {
            sleepTask?.cancel()
            sleepTask = nil
            sleepTimer = nil
            sleepRemaining = nil
        }
        player?.volume = 1
        removeTimeObserver()
        removeEndOfPlaybackObserver()
        removeTransportObservations()
        player = nil
        currentURL = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        isLoading = false
        isBuffering = false
        errorMessage = nil
        if !preservingNowPlaying {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            MPNowPlayingInfoCenter.default().playbackState = .stopped
            nowPlayingAlbum = nil
            nowPlayingQueueIndex = nil
            nowPlayingQueueCount = nil
        }
    }

    // MARK: - Time Observer

    /// Updates `currentTime` every 0.5 seconds for the progress slider.
    private func setupTimeObserver() {
        // Never stack observers: an orphaned periodic observer on a
        // deallocated AVPlayer is a documented crash.
        removeTimeObserver()

        guard let player else { return }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let seconds = CMTimeGetSeconds(time)
            if !seconds.isNaN && !seconds.isInfinite {
                self.currentTime = seconds
            }
        }
    }

    /// Reconciles `isPlaying` and the buffering flag with the player's real
    /// transport state, and re-publishes Now Playing whenever it changes.
    private func observeTransportState(for playerItem: AVPlayerItem) {
        timeControlObservation = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self, self.player === player else { return }

                // A scrub drives the transport on purpose; reconciling
                // against it would let the gesture rewrite play state.
                guard !self.isScrubbing else { return }

                switch player.timeControlStatus {
                case .playing:
                    self.isBuffering = false
                    if !self.isPlaying { self.isPlaying = true }
                case .paused:
                    self.isBuffering = false
                    // A pause we did not ask for (interruption, route loss,
                    // media reset) must show as paused, not as a lying
                    // pause-icon over silence.
                    if self.isPlaying { self.isPlaying = false }
                case .waitingToPlayAtSpecifiedRate:
                    // Still trying — the transport stays "playing" but the
                    // UI says buffering rather than sitting mute, and the
                    // Lock Screen is told rate 0 so its scrubber stops
                    // crawling forward over silence.
                    self.isBuffering = true
                    self.publishStalledState()
                    return
                @unknown default:
                    break
                }
                self.updateNowPlayingPlaybackState()
            }
        }

        // A stall with an empty buffer on a weak signal would otherwise
        // leave the Rosary silent with no explanation and nothing retrying.
        stallObservation = playerItem.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self, self.player?.currentItem === item else { return }
                if item.isPlaybackBufferEmpty && self.isPlaying {
                    self.isBuffering = true
                }
            }
        }
    }

    /// Freezes the Lock Screen scrubber while buffering: rate 0 at the true
    /// elapsed time, so it stops advancing over audio that isn't arriving.
    private func publishStalledState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func removeTransportObservations() {
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        stallObservation?.invalidate()
        stallObservation = nil
    }

    /// Must be called before releasing the player, otherwise
    /// the observer continues trying to update.
    private func removeTimeObserver() {
        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
    }

    // MARK: - Notifications

    /// When audio reaches the end, reset to the beginning and stop.
    private func setupNotifications(for item: AVPlayerItem) {
        removeEndOfPlaybackObserver()
        endOfPlaybackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isPlaying = false
            self.isBuffering = false
            self.currentTime = 0
            self.player?.seek(to: .zero)
            self.updateNowPlayingPlaybackState()
            // Only the flow that currently owns track navigation is told.
            // Ungated, a handler left behind by a flow the user walked out
            // of stays installed on the singleton, and the next flow's
            // track ending calls it: a recording begun on the shelf an
            // hour ago would start playing over a Rosary.
            guard self.trackNavigationOwner != nil else { return }
            self.onTrackFinished?()
        }
    }

    private func removeEndOfPlaybackObserver() {
        if let observer = endOfPlaybackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        endOfPlaybackObserver = nil
    }
}
