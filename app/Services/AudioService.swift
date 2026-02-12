//
//  AudioService.swift
//  app
//
//  Manages audio playback for meditation audio using AVFoundation.
//

import AVFoundation
import Foundation

/// Service for playing meditation audio
@Observable
final class AudioService {
    // MARK: - Singleton

    static let shared = AudioService()

    // MARK: - State

    /// Whether audio is currently playing
    var isPlaying = false

    /// Current playback position in seconds
    var currentTime: Double = 0

    /// Total duration of current audio in seconds
    var duration: Double = 0

    /// Whether audio is currently loading
    var isLoading = false

    /// Error message if playback fails
    var errorMessage: String?

    // MARK: - Private

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var currentURL: URL?

    // MARK: - Initialization

    private init() {
        setupAudioSession()
    }

    deinit {
        removeTimeObserver()
    }

    // MARK: - Audio Session

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

    // MARK: - Playback Control

    /// Load audio from a URL
    /// - Parameter urlString: The URL string to load audio from
    @MainActor
    func loadAudio(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid audio URL"
            return
        }

        // Don't reload if same URL
        if url == currentURL && player != nil {
            return
        }

        isLoading = true
        errorMessage = nil
        reset()
        currentURL = url

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Wait for duration to be available
        do {
            let asset = AVURLAsset(url: url)
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
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

    /// Toggle play/pause
    func togglePlayback() {
        guard let player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    /// Play audio
    func play() {
        guard let player, !isPlaying else { return }
        player.play()
        isPlaying = true
    }

    /// Pause audio
    func pause() {
        guard let player, isPlaying else { return }
        player.pause()
        isPlaying = false
    }

    /// Seek to a specific time
    /// - Parameter time: Time in seconds
    func seek(to time: Double) {
        guard let player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
        currentTime = time
    }

    /// Skip forward by seconds
    func skipForward(_ seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    /// Skip backward by seconds
    func skipBackward(_ seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    /// Stop and reset playback
    func reset() {
        pause()
        removeTimeObserver()
        player = nil
        currentURL = nil
        currentTime = 0
        duration = 0
        isPlaying = false
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        guard let player else { return }

        // Update every 0.5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = CMTimeGetSeconds(time)
            if !seconds.isNaN && !seconds.isInfinite {
                self.currentTime = seconds
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
    }

    // MARK: - Notifications

    private func setupNotifications(for item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.currentTime = 0
            self?.player?.seek(to: .zero)
        }
    }
}
