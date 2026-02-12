//
//  PrayerSessionViewModel.swift
//  app
//
//  Manages state for the prayer flow through the mysteries.
//

import Foundation

/// ViewModel for the prayer session (mystery prayer view)
@Observable
final class PrayerSessionViewModel {
    // MARK: - Published State

    /// The meditation set being prayed
    let meditationSet: MeditationSet

    /// Current mystery index (0-based)
    var currentMysteryIndex: Int = 0

    // MARK: - Dependencies

    private let apiService: APIService
    let audioService: AudioService
    private var startTime: Date?

    // MARK: - Audio State (proxied from AudioService)

    /// Audio playback state
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

    /// Current audio time (seconds)
    var currentTime: Double {
        get { audioService.currentTime }
        set { audioService.seek(to: newValue) }
    }

    /// Total audio duration (seconds)
    var totalDuration: Double {
        audioService.duration
    }

    /// Whether audio is loading
    var isLoadingAudio: Bool {
        audioService.isLoading
    }

    // MARK: - Initialization

    init(meditationSet: MeditationSet, apiService: APIService = .shared, audioService: AudioService = .shared) {
        self.meditationSet = meditationSet
        self.apiService = apiService
        self.audioService = audioService
        self.startTime = Date()
    }

    // MARK: - Computed Properties

    /// Total number of mysteries in this set
    var totalMysteries: Int {
        meditationSet.meditations?.count ?? 5
    }

    /// Current meditation (nil if index out of bounds)
    var currentMeditation: Meditation? {
        guard let meditations = meditationSet.meditations,
              currentMysteryIndex >= 0,
              currentMysteryIndex < meditations.count else {
            return nil
        }
        return meditations[currentMysteryIndex]
    }

    /// Current mystery from the meditation
    var currentMystery: Mystery? {
        currentMeditation?.mystery
    }

    /// Whether we're on the last mystery
    var isLastMystery: Bool {
        currentMysteryIndex >= totalMysteries - 1
    }

    /// Whether we're on the first mystery
    var isFirstMystery: Bool {
        currentMysteryIndex == 0
    }

    /// Progress through the rosary (0.0 to 1.0)
    var progress: Double {
        guard totalMysteries > 0 else { return 0 }
        return Double(currentMysteryIndex + 1) / Double(totalMysteries)
    }

    /// Human-readable progress (e.g., "Mystery 1 of 5")
    var progressLabel: String {
        "Mystery \(currentMysteryIndex + 1) of \(totalMysteries)"
    }

    /// Button text for the next action
    var nextButtonText: String {
        isLastMystery ? "COMPLETE" : "NEXT MYSTERY"
    }

    // MARK: - Navigation

    /// Move to the next mystery
    /// - Returns: false if already on last mystery (signals completion)
    func nextMystery() -> Bool {
        if isLastMystery {
            return false
        }
        currentMysteryIndex += 1
        resetAudioState()
        return true
    }

    /// Move to the previous mystery
    func previousMystery() {
        if currentMysteryIndex > 0 {
            currentMysteryIndex -= 1
            resetAudioState()
        }
    }

    // MARK: - Audio Controls

    /// Load audio for the current meditation
    @MainActor
    func loadCurrentAudio() async {
        guard let audioUrl = currentMeditation?.audioUrl else { return }
        await audioService.loadAudio(from: audioUrl)
    }

    func togglePlayback() {
        audioService.togglePlayback()
    }

    func seek(to time: Double) {
        audioService.seek(to: time)
    }

    func skipForward(seconds: Double = 10) {
        audioService.skipForward(seconds)
    }

    func skipBackward(seconds: Double = 10) {
        audioService.skipBackward(seconds)
    }

    private func resetAudioState() {
        audioService.reset()
    }

    // MARK: - Completion

    /// Record prayer completion to the API
    @MainActor
    func recordCompletion() async throws {
        try await apiService.recordCompletion(meditationSetId: meditationSet.id)
    }

    /// Duration of the prayer session in seconds
    var sessionDuration: Int {
        guard let startTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
}
