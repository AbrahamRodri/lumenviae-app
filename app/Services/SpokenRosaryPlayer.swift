//
//  SpokenRosaryPlayer.swift
//  Lumen Viae
//
//  Prays a whole Rosary aloud: walks a SpokenRosaryScript segment by
//  segment through AudioService, moving the hand on the strand as the
//  voice reaches each bead, so a person can pray with the phone in a
//  pocket and still find the screen where the voice is.
//
//  It sits above AudioService rather than inside it. The service plays one
//  track; the Rosary is seventy of them with a breath between each, and
//  the service's own end-of-track rule — a meditation ending never moves
//  the Rosary on — is right for the silent player and wrong here. So the
//  player takes track navigation under its own owner token while it runs
//  and hands it back when it stops, and the prayer screen's own narration
//  loading stands aside for as long as it is running.
//
//  The Rosary is never finished by the player. The last Amen leaves the
//  hand on the final bead, where AMEN is tapped as it always is: a
//  completion is something a person does, not something a recording
//  reaches.
//

import Foundation

/// What the player needs from the screen it prays for.
@MainActor
protocol SpokenRosaryHost: AnyObject {
    /// The voice has reached a bead; move the hand to it
    func spokenRosaryMoved(mystery: Int, bead: Int)

    /// The narrated meditation for a decade, or nil for none
    func spokenMeditationURL(decade: Int) async -> String?

    /// What the Lock Screen calls the Rosary: the set, or the devotion
    var spokenRosaryTitle: String { get }

    /// The mystery's name, for the Lock Screen while it is announced
    func spokenMysteryName(decade: Int) -> String?

    /// The painting for a decade, as an asset name or URL
    func spokenArtwork(decade: Int) -> String?

    /// The voice has begun a step of the script, or the hand has moved
    /// it to one: the place to come back to after an interruption
    func spokenRosaryReached(_ step: SpokenStep)
}

@Observable
final class SpokenRosaryPlayer {

    enum Phase: Equatable {
        case idle
        /// Fetching the recordings; files saved of files missing
        case preparing(done: Int, total: Int)
        case running
        /// The last Amen has been said
        case finished
        case failed(Failure)
    }

    /// Why the spoken Rosary could not begin, told in the listener's
    /// terms: what is wrong, and what the screen offers to put it right.
    enum Failure: Equatable {
        /// No connection, and the recordings were never downloaded
        case offline
        /// The server has no recordings in the chosen voice yet
        case notRecorded

        var message: String {
            switch self {
            case .offline:
                return "You're offline. Praying aloud needs the internet the first time."
            case .notRecorded:
                return "Praying aloud isn't ready in this voice yet."
            }
        }
    }

    // MARK: - State

    private(set) var phase: Phase = .idle

    let script: [SpokenSegment]

    /// The segment being said, or about to be
    private(set) var index = 0

    var currentSegment: SpokenSegment? {
        script.indices.contains(index) ? script[index] : nil
    }

    /// The opening or closing prayer under way, for the pendant the screen
    /// draws in place of a mystery's painting. Shown while the recordings
    /// are still being fetched too, so a Rosary begun from the cross
    /// opens on the cross.
    var pendant: SpokenPendant? {
        switch phase {
        case .preparing, .running, .finished: break
        case .idle, .failed: return nil
        }
        guard let segment = currentSegment, segment.phase != .decade,
              case .prayer(let id) = segment.kind else { return nil }
        return SpokenPendant(
            phase: segment.phase,
            prayerID: id,
            title: segment.caption,
            place: segment.place,
            isChaplet: !script.contains { $0.kind == .prayer("apostles_creed") }
        )
    }

    /// Between two segments, in the breath before the next begins
    private(set) var inPause = false

    /// Paused by the person during that breath, so resuming goes on to
    /// the next segment rather than replaying the last
    private var heldInPause = false

    /// Moved by hand while paused: resuming starts the new place from its
    /// beginning
    private var restartOnResume = false

    /// Whether the voice will be saying the Rosary once its recordings
    /// are in hand: true from a start that plays, through the fetch
    private var playsWhenReady = true

    /// The last Amen has been said and the hand rests on the final bead,
    /// waiting for AMEN
    var isFinished: Bool { phase == .finished }

    /// Whether the Rosary is being said, or is about to be: what a
    /// restart in another voice should carry on doing
    var isPlayingOrAboutTo: Bool {
        if case .preparing = phase { return playsWhenReady }
        return isPlaying
    }

    /// Whether the Rosary is being said right now — speaking, or in the
    /// breath between two prayers. What the play button shows.
    var isPlaying: Bool {
        guard phase == .running else { return false }
        return audio.isPlaying || audio.isLoading || (inPause && !heldInPause)
    }

    // MARK: - Dependencies

    private weak var host: SpokenRosaryHost?
    private let audio: AudioService
    private let pack: RosaryAudioPack

    /// The recordings, on disk, once prepared
    private var files: [RosaryAudioPack.ClipID: URL] = [:]

    /// Track navigation on the shared AudioService is owned by token, so
    /// a late teardown here cannot disarm a flow that took over since
    private let owner = UUID()

    /// Bumped whenever the place changes or the player stops, so a load
    /// or a pause already in flight can tell it no longer speaks for it
    private var generation = 0

    private var advanceTask: Task<Void, Never>?

    init(
        script: [SpokenSegment],
        host: SpokenRosaryHost,
        audio: AudioService = .shared,
        pack: RosaryAudioPack = .shared
    ) {
        self.script = script
        self.host = host
        self.audio = audio
        self.pack = pack
    }

    // MARK: - Starting

    /// Fetches what the script needs in the chosen voice, then begins
    /// saying it from the hand's place: the opening prayers from the very
    /// first bead, the decade's announcement from any other Our Father.
    ///
    /// With `autoplay` false it prepares and waits at that place, paused,
    /// as a Rosary paused before a change of voice should.
    ///
    /// A Rosary resumed after an interruption passes the step it stopped
    /// on, and begins there when the script still has it.
    @MainActor
    func start(mystery: Int, bead: Int, autoplay: Bool = true, resumingAt step: SpokenStep? = nil) async {
        generation &+= 1
        let started = generation
        advanceTask?.cancel()
        playsWhenReady = autoplay

        let needed = SpokenRosaryScript.clips(in: script)
        index = SpokenRosaryScript.resumeIndex(in: script, step: step)
            ?? SpokenRosaryScript.startIndex(in: script, mystery: mystery, bead: bead, includingOpening: true)
        phase = .preparing(done: 0, total: 0)

        let offline: Bool
        do {
            let prepared = try await pack.prepare(
                voice: NarrationVoiceCatalog.shared.chosenSlug,
                clips: needed
            ) { [weak self] done, total in
                guard let self, self.generation == started else { return }
                self.phase = .preparing(done: done, total: total)
            }
            guard generation == started else { return }
            files = prepared.files
            offline = prepared.offline
        } catch {
            guard generation == started else { return }
            phase = .failed(.offline)
            return
        }

        // Nothing at all to say: either the downloads could not be made,
        // or the server has not recorded this voice yet
        guard files[.prayer("hail_mary")] != nil else {
            phase = .failed(offline ? .offline : .notRecorded)
            return
        }

        phase = .running
        if autoplay {
            await sayCurrent()
        } else {
            restartOnResume = true
        }
    }

    // MARK: - Transport

    /// Pauses mid-prayer, or holds in the breath between two
    @MainActor
    func pause() {
        guard phase == .running else { return }
        if inPause {
            advanceTask?.cancel()
            heldInPause = true
        } else {
            audio.pause()
        }
    }

    /// Resumes where it paused: mid-prayer, or on to the next one
    @MainActor
    func resume() {
        guard phase == .running else { return }
        if restartOnResume {
            restartOnResume = false
            Task { await sayCurrent() }
        } else if heldInPause || inPause {
            heldInPause = false
            advance(after: 0)
        } else {
            audio.play()
        }
    }

    @MainActor
    func togglePlayback() {
        isPlaying ? pause() : resume()
    }

    /// The hand moved on the strand: go on from there. Saying carries on
    /// if it was; a paused Rosary waits there and starts that bead's
    /// prayers from their beginning when resumed.
    ///
    /// After the last Amen, moving the hand back picks the Rosary up
    /// again there, paused, so the play button means something again.
    @MainActor
    func move(toMystery mystery: Int, bead: Int) {
        if phase == .finished {
            phase = .running
        }
        guard phase == .running else { return }
        let wasPlaying = isPlaying
        generation &+= 1
        advanceTask?.cancel()
        inPause = false
        heldInPause = false
        index = SpokenRosaryScript.startIndex(in: script, mystery: mystery, bead: bead, includingOpening: false)
        reportStep()

        if wasPlaying {
            Task { await sayCurrent() }
        } else {
            audio.reset(preservingNowPlaying: true)
            restartOnResume = true
        }
    }

    /// One prayer on, or one back: the player's own buttons while the
    /// Rosary is said aloud, where ten seconds either way meant nothing
    /// inside a Hail Mary a few seconds long. Unlike the hand on the
    /// strand this can step back into the opening prayers, so a Creed
    /// skipped by accident can be said again. The hand follows at once,
    /// playing or paused.
    @MainActor
    func stepPrayer(forward: Bool) {
        if phase == .finished, !forward {
            phase = .running
        }
        guard phase == .running else { return }
        let target = index + (forward ? 1 : -1)
        guard script.indices.contains(target) else { return }
        let wasPlaying = isPlaying
        generation &+= 1
        advanceTask?.cancel()
        inPause = false
        heldInPause = false
        index = target
        if let segment = currentSegment {
            host?.spokenRosaryMoved(mystery: segment.mystery, bead: segment.bead)
        }
        reportStep()

        if wasPlaying {
            Task { await sayCurrent() }
        } else {
            audio.reset(preservingNowPlaying: true)
            restartOnResume = true
        }
    }

    /// Stops for good and hands the audio back. The caller deactivates
    /// the session if it is leaving the flow.
    @MainActor
    func stop() {
        generation &+= 1
        advanceTask?.cancel()
        advanceTask = nil
        inPause = false
        heldInPause = false
        if phase != .finished { phase = .idle }
        guard audio.isTrackNavigationOwner(owner) else { return }
        audio.clearTrackNavigation(owner: owner)
        audio.reset()
    }

    // MARK: - Saying the Script

    @MainActor
    private func sayCurrent() async {
        let saying = generation
        inPause = false
        heldInPause = false

        guard let segment = currentSegment else {
            finish()
            return
        }

        host?.spokenRosaryMoved(mystery: segment.mystery, bead: segment.bead)
        reportStep()

        let url: String?
        switch segment.kind {
        case .meditation:
            url = await host?.spokenMeditationURL(decade: segment.mystery)
        default:
            url = RosaryAudioPack.ClipID(segment: segment).flatMap { files[$0] }?.absoluteString
        }
        guard saying == generation else { return }

        // A recording that could not be had is passed over, not waited on
        guard let url else {
            advance(after: 0.3)
            return
        }

        installNavigation()

        let onPendant = segment.phase != .decade
        let ready = await audio.loadAudio(
            from: url,
            title: title(for: segment),
            subtitle: host?.spokenRosaryTitle,
            artworkAssetName: onPendant ? nil : host?.spokenArtwork(decade: segment.mystery),
            artworkImage: onPendant ? PendantArtwork.lockScreenImage : nil,
            album: host?.spokenRosaryTitle,
            queueIndex: segment.mystery,
            queueCount: (script.last?.mystery ?? 0) + 1,
            claimNowPlaying: true
        )
        guard saying == generation else { return }

        guard ready else {
            advance(after: 0.3)
            return
        }

        // The same recording twice in a row — ten Hail Marys — is not
        // loaded again; it was left at its start when it ended, so play
        // simply says it once more
        audio.play()
    }

    /// Tells the host where in the script the Rosary now stands
    @MainActor
    private func reportStep() {
        guard let segment = currentSegment else { return }
        host?.spokenRosaryReached(SpokenStep(
            index: index, mystery: segment.mystery, bead: segment.bead, caption: segment.caption
        ))
    }

    /// The breath after a segment, then the next one
    @MainActor
    private func advance(after seconds: Double) {
        let saying = generation
        inPause = true
        advanceTask?.cancel()
        advanceTask = Task { [weak self] in
            if seconds > 0 {
                try? await Task.sleep(for: .seconds(seconds))
            }
            guard let self, !Task.isCancelled, saying == self.generation else { return }
            self.index += 1
            await self.sayCurrent()
        }
    }

    @MainActor
    private func finish() {
        inPause = false
        phase = .finished
        if let last = script.last {
            host?.spokenRosaryMoved(mystery: last.mystery, bead: last.bead)
        }
        audio.updateTrackNavigation(owner: owner, canGoNext: false, canGoPrevious: true)
    }

    // MARK: - Headphones and the Lock Screen

    /// The arrows move a decade at a time — a Hail Mary is too small a
    /// step to find by pressing — and the end of each recording moves the
    /// script on.
    @MainActor
    private func installNavigation() {
        let decade = currentSegment?.mystery ?? 0
        let lastDecade = script.last?.mystery ?? 0
        audio.setTrackNavigation(
            owner: owner,
            canGoNext: decade < lastDecade || currentSegment?.phase == .opening,
            canGoPrevious: decade > 0 || currentSegment?.phase != .opening,
            onNext: { [weak self] in self?.skipDecade(forward: true) },
            onPrevious: { [weak self] in self?.skipDecade(forward: false) },
            onFinish: { [weak self] in
                guard let self, let segment = self.currentSegment else { return }
                self.advance(after: segment.pauseAfter)
            }
        )
    }

    @MainActor
    private func skipDecade(forward: Bool) {
        guard let segment = currentSegment else { return }
        let target: Int
        switch (segment.phase, forward) {
        case (.opening, true): target = 0
        case (.opening, false): return
        case (.closing, true): return
        case (.closing, false): target = segment.mystery
        case (.decade, true): target = segment.mystery + 1
        case (.decade, false):
            // Back to the start of this decade, or the one before when
            // already at its start
            let atStart = segment.kind == .announcement
            target = atStart ? max(segment.mystery - 1, 0) : segment.mystery
        }

        generation &+= 1
        advanceTask?.cancel()
        inPause = false
        heldInPause = false
        restartOnResume = false

        let lastDecade = script.last?.mystery ?? 0
        if target > lastDecade {
            index = script.firstIndex { $0.phase == .closing } ?? script.count
        } else {
            index = SpokenRosaryScript.startIndex(in: script, mystery: target, bead: 0, includingOpening: false)
        }
        Task { await sayCurrent() }
    }

    /// The Lock Screen's line: the prayer, or on the announcement and the
    /// meditation, the mystery itself
    @MainActor
    private func title(for segment: SpokenSegment) -> String {
        switch segment.kind {
        case .announcement, .meditation:
            return host?.spokenMysteryName(decade: segment.mystery) ?? segment.caption
        default:
            return segment.caption
        }
    }
}
