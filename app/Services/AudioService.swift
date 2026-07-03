//
//  AudioService.swift
//  Lumen Viae
//
//  Meditation audio playback via AVFoundation. Singleton so audio state
//  lives in one place and playback survives view changes.
//

import AVFoundation
import Foundation

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

    private var endOfPlaybackObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupAudioSession()
    }

    deinit {
        removeTimeObserver()
        if let observer = endOfPlaybackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Audio Session Setup

    /// Configures the audio session for playback
    /// (.playback plays even with the mute switch on).
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("AudioService: Failed to set up audio session: \(error)")
            #endif
        }
        #endif
    }

    // MARK: - Loading Audio

    /// Loads audio from a URL string, skipping if the same URL is already loaded.
    @MainActor
    func loadAudio(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid audio URL"
            return
        }

        // Skip if same URL already loaded
        if url == currentURL && player != nil {
            return
        }

        isLoading = true
        errorMessage = nil
        reset()
        currentURL = url

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        do {
            let asset = AVURLAsset(url: url)
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
            // Handle invalid duration values
            if duration.isNaN || duration.isInfinite {
                duration = 0
            }
        } catch {
            #if DEBUG
            print("AudioService: Failed to load duration: \(error)")
            #endif
        }

        setupTimeObserver()
        setupNotifications(for: playerItem)
        isLoading = false
    }

    // MARK: - Playback Controls

    /// Toggles between play and pause
    func togglePlayback() {
        guard let player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    /// Starts playback (no-op if already playing)
    func play() {
        guard let player, !isPlaying else { return }
        player.play()
        isPlaying = true
    }

    /// Pauses playback (no-op if already paused)
    func pause() {
        guard let player, isPlaying else { return }
        player.pause()
        isPlaying = false
    }

    /// Seeks to a specific time in seconds.
    func seek(to time: Double) {
        guard let player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
        currentTime = time
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
    func reset() {
        pause()
        removeTimeObserver()
        removeEndOfPlaybackObserver()
        player = nil
        currentURL = nil
        currentTime = 0
        duration = 0
        isPlaying = false
    }

    // MARK: - Time Observer

    /// Updates `currentTime` every 0.5 seconds for the progress slider.
    private func setupTimeObserver() {
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
        }
    }

    private func removeEndOfPlaybackObserver() {
        if let observer = endOfPlaybackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        endOfPlaybackObserver = nil
    }
}
