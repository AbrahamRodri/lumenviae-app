//
//  PrayerSessionViewModel.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  PRAYER SESSION VIEW MODEL - MANAGES THE PRAYER FLOW
//  ═══════════════════════════════════════════════════════════════════════════
//
//  This ViewModel manages state during the prayer flow through 5 mysteries.
//  It tracks:
//  - Current mystery position (1 of 5, 2 of 5, etc.)
//  - Audio playback state (delegated to AudioService)
//  - Session timing for analytics
//
//  ## Flow
//  ```
//  Mystery 1 → Mystery 2 → Mystery 3 → Mystery 4 → Mystery 5 → Completion
//  ```
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - PrayerSessionViewModel

/// Manages state for the prayer flow through the Rosary mysteries.
///
/// This ViewModel coordinates:
/// - Navigation between mysteries (next/previous)
/// - Audio playback via AudioService
/// - Recording completion when finished
/// - Session duration tracking
///
@Observable
final class PrayerSessionViewModel {

    // MARK: - State

    /// The meditation set being prayed (contains all 5 meditations)
    let meditationSet: MeditationSet

    /// Current mystery index (0-based, so 0-4 for 5 mysteries)
    var currentMysteryIndex: Int = 0

    // MARK: - Dependencies

    private let apiService: APIService

    /// Audio service is `let` (not private) because the View may need to observe it
    let audioService: AudioService

    /// When the prayer session started (for duration tracking)
    private var startTime: Date?

    // MARK: - Audio State (Proxied)

    /// These properties proxy through to AudioService.
    /// This allows the View to bind directly to the ViewModel while
    /// the actual audio logic lives in AudioService.

    /// Whether audio is currently playing
    var isPlaying: Bool {
        get { audioService.isPlaying }
        set {
            if newValue && !audioService.isPlaying {
                audioService.play()
            } else if !newValue && audioService.isPlaying {
                audioService.pause()
            }
        }
    }

    /// Current playback position in seconds
    var currentTime: Double {
        get { audioService.currentTime }
        set { audioService.seek(to: newValue) }
    }

    /// Total audio duration in seconds
    var totalDuration: Double {
        audioService.duration
    }

    /// Whether audio is currently loading
    var isLoadingAudio: Bool {
        audioService.isLoading
    }

    // MARK: - Initialization

    init(
        meditationSet: MeditationSet,
        apiService: APIService = .shared,
        audioService: AudioService = .shared
    ) {
        self.meditationSet = meditationSet
        self.apiService = apiService
        self.audioService = audioService
        self.startTime = Date()
    }

    // MARK: - Computed Properties

    /// Total number of mysteries in this set (typically 5)
    var totalMysteries: Int {
        meditationSet.meditations?.count ?? 5
    }

    /// The meditation for the current mystery, or nil if not available
    var currentMeditation: Meditation? {
        guard let meditations = meditationSet.meditations,
              currentMysteryIndex >= 0,
              currentMysteryIndex < meditations.count else {
            return nil
        }
        return meditations[currentMysteryIndex]
    }

    /// The mystery data from the current meditation
    var currentMystery: Mystery? {
        currentMeditation?.mystery
    }

    /// Whether we're on the last mystery (index 4 for 5 mysteries)
    var isLastMystery: Bool {
        currentMysteryIndex >= totalMysteries - 1
    }

    /// Whether we're on the first mystery (index 0)
    var isFirstMystery: Bool {
        currentMysteryIndex == 0
    }

    /// Progress as a fraction (0.0 to 1.0) for progress bar
    var progress: Double {
        guard totalMysteries > 0 else { return 0 }
        return Double(currentMysteryIndex + 1) / Double(totalMysteries)
    }

    /// Human-readable progress (e.g., "Mystery 1 of 5")
    var progressLabel: String {
        "Mystery \(currentMysteryIndex + 1) of \(totalMysteries)"
    }

    /// Text for the next/complete button
    var nextButtonText: String {
        isLastMystery ? "COMPLETE" : "NEXT MYSTERY"
    }

    // MARK: - Navigation

    /// Advances to the next mystery.
    ///
    /// - Returns: `true` if advanced successfully, `false` if on last mystery
    ///
    /// When returning `false`, the caller should navigate to the completion screen.
    func nextMystery() -> Bool {
        if isLastMystery {
            return false
        }
        currentMysteryIndex += 1
        resetAudioState()
        return true
    }

    /// Returns to the previous mystery (no-op if on first mystery)
    func previousMystery() {
        if currentMysteryIndex > 0 {
            currentMysteryIndex -= 1
            resetAudioState()
        }
    }

    // MARK: - Audio Controls

    /// Loads the audio file for the current meditation
    @MainActor
    func loadCurrentAudio() async {
        guard let audioUrl = currentMeditation?.audioUrl else { return }
        await audioService.loadAudio(from: audioUrl)
    }

    /// Toggles play/pause state
    func togglePlayback() {
        audioService.togglePlayback()
    }

    /// Seeks to a specific time in seconds
    func seek(to time: Double) {
        audioService.seek(to: time)
    }

    /// Skips forward by specified seconds (default 10)
    func skipForward(seconds: Double = 10) {
        audioService.skipForward(seconds)
    }

    /// Skips backward by specified seconds (default 10)
    func skipBackward(seconds: Double = 10) {
        audioService.skipBackward(seconds)
    }

    /// Resets audio state when changing mysteries
    private func resetAudioState() {
        audioService.reset()
    }

    // MARK: - Completion

    /// Records the prayer completion to the API.
    ///
    /// Called when the user finishes all 5 mysteries.
    /// Failures are typically ignored (completion is best-effort).
    @MainActor
    func recordCompletion() async throws {
        try await apiService.recordCompletion(meditationSetId: meditationSet.id)
    }

    /// Duration of the prayer session in seconds since it started
    var sessionDuration: Int {
        guard let startTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
}
