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

    /// Error message if playback fails (nil on success)
    var errorMessage: String?

    // MARK: - Private Properties

    private var player: AVPlayer?

    /// Token for the periodic time observer (must be removed on cleanup)
    private var timeObserver: Any?

    /// Currently loaded audio URL (for avoiding redundant loads)
    private var currentURL: URL?

    /// Monotonic load token. Each loadAudio call claims a new generation;
    /// after every await it checks it still owns the current one, so a
    /// superseded or cancelled load can never mutate the newer load's state.
    private var loadGeneration = 0

    private var endOfPlaybackObserver: NSObjectProtocol?

    /// Title/subtitle shown on the Lock Screen for the loaded audio
    private var nowPlayingTitle: String?
    private var nowPlayingSubtitle: String?

    /// Asset name of the Lock Screen artwork, with the built artwork
    /// cached — MPMediaItemArtwork construction isn't free and Now
    /// Playing refreshes happen on every play/pause/seek.
    private var nowPlayingArtworkAsset: String?
    private var cachedArtwork: (asset: String, artwork: MPMediaItemArtwork)?

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
                self.wasPlayingBeforeInterruption = self.isPlaying
                self.isPlaying = false
                self.updateNowPlayingPlaybackState()
            case .ended:
                let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && self.wasPlayingBeforeInterruption {
                    self.play()
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
        #endif
    }

    // MARK: - Track Navigation (headphones / Lock Screen)

    /// Hooks the prayer flow installs so AirPods presses and Lock Screen
    /// arrows move between mysteries. While set, the Lock Screen shows
    /// track arrows instead of the ±10s skips; when cleared (chant
    /// playback, no flow active) the skips come back.
    var onNextTrack: (() -> Void)? { didSet { updateTrackCommandAvailability() } }
    var onPreviousTrack: (() -> Void)? { didSet { updateTrackCommandAvailability() } }

    private func updateTrackCommandAvailability() {
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = onNextTrack != nil
        center.previousTrackCommand.isEnabled = onPreviousTrack != nil
        center.skipForwardCommand.isEnabled = onNextTrack == nil
        center.skipBackwardCommand.isEnabled = onPreviousTrack == nil
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
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, let advance = self.onNextTrack else { return .noActionableNowPlayingItem }
            advance()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, let back = self.onPreviousTrack else { return .noActionableNowPlayingItem }
            back()
            return .success
        }

        updateTrackCommandAvailability()
    }

    // MARK: - Now Playing Info

    /// Publishes metadata to the Lock Screen / Control Center.
    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = nowPlayingTitle ?? "Meditation"
        info[MPMediaItemPropertyArtist] = nowPlayingSubtitle ?? "Lumen Viae"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        if let artwork = lockScreenArtwork() {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
    private func updateNowPlayingPlaybackState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            updateNowPlayingInfo()
            return
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Loading Audio

    /// Loads audio from a URL string, skipping if the same URL is already
    /// loaded. `title`/`subtitle`/`artworkAssetName` feed the Lock Screen.
    ///
    /// `claimNowPlaying` makes this the Now Playing app as soon as the
    /// audio is ready, before any on-screen play — hands-off prayer needs
    /// headphone presses to reach it. Callers that must not take the
    /// route until the user presses play leave it off.
    @MainActor
    func loadAudio(
        from urlString: String,
        title: String? = nil,
        subtitle: String? = nil,
        artworkAssetName: String? = nil,
        claimNowPlaying: Bool = false
    ) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid audio URL"
            return
        }

        // Skip if same URL already loaded
        if url == currentURL && player != nil {
            nowPlayingTitle = title ?? nowPlayingTitle
            nowPlayingSubtitle = subtitle ?? nowPlayingSubtitle
            nowPlayingArtworkAsset = artworkAssetName ?? nowPlayingArtworkAsset
            updateNowPlayingInfo()
            return
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

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        do {
            let asset = AVURLAsset(url: url)
            let cmDuration = try await asset.load(.duration)

            // A newer load (or a reset) owns the state now — hands off.
            guard generation == loadGeneration else { return }

            duration = CMTimeGetSeconds(cmDuration)
            if duration.isNaN || duration.isInfinite {
                duration = 0
            }

            // An unplayable/indefinite asset would leave a silently dead
            // transport — say so instead.
            guard duration > 0 else {
                reset()
                errorMessage = "Audio unavailable — try again later"
                return
            }
        } catch {
            // Superseded loads exit without touching the newer load's state.
            guard generation == loadGeneration else { return }
            isLoading = false

            // Cancelled while current (view going away): quiet exit.
            if Task.isCancelled { return }

            // The asset is unreachable (offline, or an expired link) —
            // tear down so the UI shows the failure instead of a dead
            // transport that plays silence.
            #if DEBUG
            print("AudioService: Failed to load audio: \(error)")
            #endif
            reset()
            errorMessage = "Audio unavailable — check your connection"
            return
        }

        setupTimeObserver()
        setupNotifications(for: playerItem)
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
        guard let player else { return }

        if isPlaying {
            player.pause()
        } else {
            reactivateSessionIfNeeded()
            player.play()
        }
        isPlaying.toggle()
        updateNowPlayingPlaybackState()
    }

    /// Starts playback (no-op if already playing)
    func play() {
        guard let player, !isPlaying else { return }
        reactivateSessionIfNeeded()
        player.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    /// Pauses playback (no-op if already paused)
    func pause() {
        guard let player, isPlaying else { return }
        player.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }

    /// An interruption can deactivate the session; reactivate before playing.
    private func reactivateSessionIfNeeded() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

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
        removeTimeObserver()
        removeEndOfPlaybackObserver()
        player = nil
        currentURL = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        isLoading = false
        errorMessage = nil
        if !preservingNowPlaying {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
            self?.isPlaying = false
            self?.currentTime = 0
            self?.player?.seek(to: .zero)
            self?.updateNowPlayingPlaybackState()
        }
    }

    private func removeEndOfPlaybackObserver() {
        if let observer = endOfPlaybackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        endOfPlaybackObserver = nil
    }
}
