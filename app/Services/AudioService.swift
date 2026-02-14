//
//  AudioService.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  AUDIO SERVICE - MEDITATION AUDIO PLAYBACK
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Manages audio playback for guided meditation audio using AVFoundation.
//  Provides play/pause, seeking, and time tracking functionality.
//
//  ## AVFoundation Overview
//  AVFoundation is Apple's framework for audio/video playback:
//  - `AVPlayer`: The actual audio player
//  - `AVPlayerItem`: Represents a single audio file
//  - `CMTime`: Core Media time type (more precise than Double)
//  - `AVAudioSession`: Manages audio behavior (background play, etc.)
//
//  ## Architecture
//  AudioService is a singleton that the ViewModel proxies.
//  This keeps audio state in one place and allows the same audio
//  to continue playing across view changes.
//
//  ═══════════════════════════════════════════════════════════════════════════

import AVFoundation
import Foundation

// MARK: - AudioService

/// Service for playing meditation audio files.
///
/// ## @Observable
/// Allows SwiftUI to react to state changes (isPlaying, currentTime, etc.)
/// without needing Combine publishers.
///
/// ## Singleton Pattern
/// Uses `private init()` to enforce single instance access via `shared`.
/// This ensures only one AVPlayer exists app-wide.
///
@Observable
final class AudioService {

    // MARK: - Singleton

    /// Shared instance for app-wide audio playback
    static let shared = AudioService()

    // MARK: - Observable State

    /// Whether audio is currently playing
    var isPlaying = false

    /// Current playback position in seconds
    var currentTime: Double = 0

    /// Total duration of the loaded audio in seconds
    var duration: Double = 0

    /// Whether audio is currently loading
    var isLoading = false

    /// Error message if playback fails (nil on success)
    var errorMessage: String?

    // MARK: - Private Properties

    /// The AVPlayer instance (nil when no audio loaded)
    private var player: AVPlayer?

    /// Token for the periodic time observer (must be removed on cleanup)
    private var timeObserver: Any?

    /// Currently loaded audio URL (for avoiding redundant loads)
    private var currentURL: URL?

    /// Token for the end-of-playback notification observer
    private var endOfPlaybackObserver: NSObjectProtocol?

    // MARK: - Initialization

    /// Private initializer enforces singleton pattern
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

    /// Configures the iOS audio session for playback.
    ///
    /// ## Audio Session Categories
    /// - `.playback`: Audio plays even when the mute switch is on
    /// - This also allows background audio (with proper entitlements)
    ///
    /// The `#if os(iOS)` check is for cross-platform compatibility
    /// (macOS doesn't have AVAudioSession).
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioService: Failed to set up audio session: \(error)")
        }
        #endif
    }

    // MARK: - Loading Audio

    /// Loads audio from a URL string.
    ///
    /// - Parameter urlString: The URL string to load audio from
    ///
    /// This method:
    /// 1. Validates the URL
    /// 2. Skips if same URL already loaded
    /// 3. Resets previous state
    /// 4. Creates player and loads duration
    /// 5. Sets up time observer for progress tracking
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

        // Create player with the audio URL
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Load the duration asynchronously
        do {
            let asset = AVURLAsset(url: url)
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
            // Handle invalid duration values
            if duration.isNaN || duration.isInfinite {
                duration = 0
            }
        } catch {
            print("AudioService: Failed to load duration: \(error)")
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

    /// Seeks to a specific time in the audio.
    ///
    /// - Parameter time: Time in seconds to seek to
    ///
    /// ## CMTime
    /// AVFoundation uses CMTime instead of Double for precise timing.
    /// `preferredTimescale: 600` means 1/600th second precision.
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

    /// Sets up periodic time updates for the progress slider.
    ///
    /// Updates `currentTime` every 0.5 seconds while playing.
    /// Uses `[weak self]` to avoid retain cycles.
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

    /// Removes the time observer (required for cleanup).
    ///
    /// Must be called before releasing the player, otherwise
    /// the observer continues trying to update.
    private func removeTimeObserver() {
        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
    }

    // MARK: - Notifications

    /// Sets up notification for when audio finishes playing.
    ///
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
