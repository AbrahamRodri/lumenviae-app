//
//  PrayerSessionViewModel.swift
//  Lumen Viae
//
//  State for the prayer flow through the 5 mysteries: position, audio
//  playback (delegated to AudioService), and session timing.
//

import Foundation

@Observable
final class PrayerSessionViewModel {

    // MARK: - State

    /// The meditation set being prayed (contains all 5 meditations)
    let meditationSet: MeditationSet

    /// Current mystery index (0-based, so 0-4 for 5 mysteries)
    var currentMysteryIndex: Int = 0

    // MARK: - Dependencies

    private let apiService: APIService

    /// Not private because the View may need to observe it
    let audioService: AudioService

    /// When THIS segment of the session started. Resumed sessions get a
    /// fresh clock — the gap between segments is not prayer time.
    private let segmentStart = Date()

    /// Seconds prayed in earlier segments of a resumed session
    private let priorSeconds: Int

    // MARK: - Audio State (Proxied)

    // These properties proxy through to AudioService so the View can bind
    // directly to the ViewModel while the audio logic lives in one place.

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

    var currentTime: Double {
        get { audioService.currentTime }
        set { audioService.seek(to: newValue) }
    }

    var totalDuration: Double {
        audioService.duration
    }

    var isLoadingAudio: Bool {
        audioService.isLoading
    }

    // MARK: - Initialization

    init(
        meditationSet: MeditationSet,
        startAtIndex: Int = 0,
        priorSeconds: Int = 0,
        apiService: APIService = .shared,
        audioService: AudioService = .shared
    ) {
        self.meditationSet = meditationSet
        self.apiService = apiService
        self.audioService = audioService
        self.priorSeconds = max(priorSeconds, 0)

        let upperBound = max((meditationSet.meditations?.count ?? 5) - 1, 0)
        self.currentMysteryIndex = min(max(startAtIndex, 0), upperBound)
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

    /// Loads the audio file for the current meditation. Downloaded copies
    /// win over the network — the bundled URLs are 24-hour presigned links
    /// that expire, and local files play offline.
    @MainActor
    func loadCurrentAudio() async {
        let generation = flowGeneration

        // hasAudio also rejects the empty-string URLs the server can emit
        let source = currentMeditation.flatMap { meditation in
            OfflineContentService.shared.localAudioURL(meditationId: meditation.id)?.absoluteString
                ?? (meditation.hasAudio ? meditation.audioUrl : nil)
        }

        guard let meditation = currentMeditation, let source else {
            // A mystery with no narration must not leave the previous
            // one's player standing on the Lock Screen: resetAudioState
            // preserved it for a load that is not coming.
            pendingRemoteAutoplay = false
            audioService.reset()
            return
        }

        await audioService.loadAudio(
            from: source,
            title: meditation.displayTitle,
            subtitle: meditationSet.name,
            artworkAssetName: Constants.mysteryImageURL(
                category: meditationSet.category,
                index: currentMysteryIndex
            ),
            claimNowPlaying: true
        )

        // The flow can be left while the asset loads — nothing this load
        // published may outlive it.
        guard generation == flowGeneration else {
            audioService.reset()
            audioService.deactivateSession()
            return
        }

        let autoplay = pendingRemoteAutoplay
        pendingRemoteAutoplay = false

        // A failed load published no track for a remote command to act on.
        guard audioService.errorMessage == nil else { return }

        attachRemoteNavigation()

        // A mystery reached from AirPods or the Lock Screen flows straight
        // into its narration — the whole point of hands-off prayer.
        if autoplay {
            audioService.play()
        }
    }

    // MARK: - Hands-Off Navigation

    /// Set when a remote track command changes the mystery, so the next
    /// load starts playing without the phone being touched.
    private var pendingRemoteAutoplay = false

    /// Bumped when the flow is left, so a load already in flight can tell
    /// that it no longer owns the session.
    private var flowGeneration = 0

    /// The load a remote track command started. The view's `.task` is
    /// cancelled for us when the screen goes away; this one is not.
    private var remoteLoadTask: Task<Void, Never>?

    /// Wires AirPods presses and Lock Screen arrows to mystery navigation.
    /// Attached only once a track of ours is actually published: a track
    /// command arriving before that belongs to whatever was Now Playing
    /// before us, replayed at our freshly activated session, rather than
    /// to a person praying.
    ///
    /// Completion stays on-screen only: advancing past the last mystery
    /// from a remote is ignored rather than ending the Rosary.
    ///
    /// The handlers load the next audio themselves instead of leaning on
    /// the view's task — with the phone locked, the view may not
    /// re-evaluate, and the narration must continue regardless. In the
    /// foreground the view's task also fires; the same-URL guard in
    /// AudioService makes the second load a no-op.
    private func attachRemoteNavigation() {
        audioService.onNextTrack = { [weak self] in
            guard let self, !self.isLastMystery else { return }
            self.pendingRemoteAutoplay = true
            self.currentMysteryIndex += 1
            self.startRemoteLoad()
        }
        audioService.onPreviousTrack = { [weak self] in
            guard let self, !self.isFirstMystery else { return }
            self.pendingRemoteAutoplay = true
            self.currentMysteryIndex -= 1
            self.startRemoteLoad()
        }
    }

    private func startRemoteLoad() {
        remoteLoadTask?.cancel()
        remoteLoadTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            await self?.loadCurrentAudio()
        }
    }

    /// Error from the audio layer, surfaced next to the transport
    var audioErrorMessage: String? {
        audioService.errorMessage
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

    /// Resets audio state when changing mysteries. The Lock Screen player
    /// survives the gap — the next mystery's load republishes over it.
    private func resetAudioState() {
        audioService.reset(preservingNowPlaying: true)
    }

    // MARK: - Completion

    /// Whether the completion has already been sent (guards double-taps)
    private var hasRecordedCompletion = false

    /// Records the prayer completion to the API (best-effort, at most once).
    @MainActor
    func recordCompletion() async throws {
        guard !hasRecordedCompletion else { return }
        hasRecordedCompletion = true
        try await apiService.recordCompletion(meditationSetId: meditationSet.id)
    }

    /// Stops any playing meditation audio and hands the audio session back
    /// to the system; call when leaving the prayer flow.
    func stopAudio() {
        // Disown any load still in flight before tearing down, so it
        // can't republish Now Playing or start narration over the screen
        // the user just moved to.
        flowGeneration &+= 1
        remoteLoadTask?.cancel()
        remoteLoadTask = nil
        pendingRemoteAutoplay = false

        audioService.onNextTrack = nil
        audioService.onPreviousTrack = nil
        audioService.reset()
        audioService.deactivateSession()
    }

    /// Seconds actually spent praying: earlier segments plus this one.
    /// Interruption gaps between segments are never counted.
    var sessionDuration: Int {
        priorSeconds + Int(Date().timeIntervalSince(segmentStart))
    }
}
