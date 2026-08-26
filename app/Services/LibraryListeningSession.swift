//
//  LibraryListeningSession.swift
//  Lumen Viae
//
//  The shelf's one voice. A recording begun on a book page must keep
//  reading while the reader walks into a chapter, must survive a
//  half-finished back-swipe, must remember where it stopped, and must
//  never, ever be playing when a Rosary begins.
//
//  None of that can hang off a single view's lifetime. `onDisappear`
//  fires for a push as well as a pop, doesn't fire at all when a screen
//  is torn out from under a pushed one, and fires spuriously for a
//  cancelled swipe — so the old arrangement both silenced recordings
//  that should have continued and left recordings running that should
//  have stopped. Here the session lives above the views: they announce
//  that a library screen is on screen, and the reading ends when the
//  last of them is gone.
//
//  Ownership of the shared player is held with a token, so if a Rosary
//  claims it mid-reading this session simply stops speaking for the
//  player rather than fighting it.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class LibraryListeningSession {

    static let shared = LibraryListeningSession()

    private init() {}

    // MARK: - What is loaded

    /// The book whose recording is in the player, if any
    private(set) var info: LibraryBookInfo?

    /// Its tracks, as LibriVox lists them
    private(set) var sections: [LibriVoxSection] = []

    /// How those tracks line up with the parsed chapters
    private(set) var alignment: LibraryTrackAlignment = .empty

    /// Which track is loaded — nil when nothing has been handed over
    private(set) var trackIndex: Int?

    /// Something went wrong reaching the recording, in the reader's words
    private(set) var failure: String?

    /// Where the voice would resume from, remembered before the player
    /// was torn down, so the ledger can say "31 min in" without a row
    /// loaded.
    private(set) var restingTrackID: String?
    private(set) var restingSeconds: Double = 0

    private let audio = AudioService.shared
    private var context: ModelContext?

    /// Monotonic token for a hand-over to the player. Every load claims
    /// one and checks it still owns it after the await, so a load the
    /// reader superseded — or walked out on — can never write its
    /// outcome over the live one's.
    private var playGeneration = 0

    /// Commits the listening place on a slow clock while a recording
    /// runs. Without it nothing is written between one gesture and the
    /// next, and background listening — which is most of it — was lost
    /// entirely on termination.
    private var commitTicker: Task<Void, Never>?

    /// Cover artwork already rendered for the Lock Screen, by book id
    private var artwork: [String: UIImage] = [:]

    // MARK: - Player state, read through this session

    /// Whether this session still holds the shared player. A Rosary that
    /// claims it takes ownership, and from that moment every readout
    /// here goes quiet rather than reporting another flow's playback.
    var isActive: Bool {
        info != nil && audio.isTrackNavigationOwner(token)
    }

    var isPlaying: Bool { isActive && audio.isPlaying }

    var isLoading: Bool { isActive && audio.isLoading }

    var isBuffering: Bool { isActive && audio.isBuffering }

    var currentTime: Double { isActive ? audio.currentTime : 0 }

    var duration: Double { isActive ? audio.duration : 0 }

    var playbackRate: Double { audio.playbackRate }

    var sleepTimer: AudioService.SleepTimer? { isActive ? audio.sleepTimer : nil }

    var sleepRemaining: Int? { isActive ? audio.sleepRemaining : nil }

    /// The track sounding right now, whether or not it is paused.
    func isLoaded(track index: Int) -> Bool {
        isActive && trackIndex == index
    }

    func isSounding(track index: Int) -> Bool {
        isLoaded(track: index) && audio.isPlaying
    }

    /// Where the voice is in this book's recording, whether the player
    /// currently holds it or it was put down earlier.
    func restingPosition(forTrack id: String) -> Double? {
        guard restingTrackID == id, restingSeconds > 20 else { return nil }
        return restingSeconds
    }

    /// Whether the page may keep pace with the voice — only where this
    /// track reads one whole chapter and nothing else.
    func canFollowText(chapterIndex: Int) -> Bool {
        guard let trackIndex, isPlaying else { return false }
        return alignment.readsWholeChapter(track: trackIndex)
            && alignment.firstChapter(forTrack: trackIndex) == chapterIndex
    }

    // MARK: - Adopting a book

    /// Tells the session which book's pages are on screen. Called by the
    /// book page and the reader once their text and tracks have arrived.
    ///
    /// Adopting a *different* book stops whatever was reading: two books
    /// cannot be read aloud at once, and silently continuing the old one
    /// under the new one's ledger is worse than stopping.
    func adopt(
        info: LibraryBookInfo,
        sections: [LibriVoxSection],
        alignment: LibraryTrackAlignment,
        context: ModelContext
    ) {
        self.context = context

        if self.info?.id != info.id {
            if self.info != nil { stop() }
            self.info = info
            restoreRestingPosition(for: info, in: context)
        } else {
            self.info = info
        }
        self.sections = sections
        self.alignment = alignment

        // This book's speed, not the app's. A reader who set 1.25x for
        // the Rosary's meditations has not thereby chosen a speed for
        // Susan Morin, and vice versa.
        audio.setPlaybackRate(
            UserSettings.shared.readingRate(for: info.id, default: info.preferredRate),
            remember: false
        )
    }

    /// Reads the last listening place off the book's row, so a ledger
    /// opened cold can already say where the voice stopped.
    private func restoreRestingPosition(for info: LibraryBookInfo, in context: ModelContext) {
        guard let row = LibraryProgressStore.row(for: info.id, in: context),
              row.hasResumableTrack else {
            restingTrackID = nil
            restingSeconds = 0
            return
        }
        restingTrackID = row.lastTrackID
        restingSeconds = row.lastTrackSeconds
    }

    // MARK: - Playing

    /// Hands a track to the player, resuming its remembered position
    /// when it has one.
    func play(track index: Int, from seconds: Double? = nil) {
        guard let info, sections.indices.contains(index) else { return }
        let section = sections[index]

        // A reading already on the device plays from the device — that
        // is the whole point of having saved it, and it spends no data
        // to hear it twice.
        let saved = LibraryAudioDownloads.shared
            .localURL(bookID: info.id, sectionID: section.id)?.absoluteString
        guard let url = saved ?? section.streamURL else { return }

        // Commit whatever the previous track reached before it is torn
        // down — reset() zeroes currentTime, and the position must be
        // taken before that, never after.
        persist(force: true)

        let resume = seconds ?? restingPosition(forTrack: section.id) ?? 0
        failure = nil
        trackIndex = index
        restingTrackID = section.id
        restingSeconds = resume

        playGeneration &+= 1
        let generation = playGeneration

        // Claim the Lock Screen arrows before the load, so the queue the
        // player is about to publish is one the ⏭ actually steps through.
        // A recording is a reading, not a devotion — it runs on to the
        // next track by itself, unless a sleep timer says otherwise.
        arm(at: index)

        Task { [weak self] in
            guard let self else { return }
            let ready = await audio.loadAudio(
                from: url,
                title: section.title ?? info.title,
                subtitle: info.author,
                artworkImage: artwork[info.id],
                album: info.title,
                queueIndex: index,
                queueCount: sections.count,
                claimNowPlaying: true,
                startAt: resume
            )
            // Someone else owns this session now — the reader moved to
            // another track, or left the shelf entirely. Say nothing.
            guard generation == playGeneration, trackIndex == index,
                  audio.isTrackNavigationOwner(token) else { return }

            // A load that failed tore the player down and said why; the
            // row must not be left showing a play mark over nothing.
            guard ready else {
                // Give the shared player back. `arm` claimed it before
                // the load; holding the claim over a track that never
                // arrived leaves Lock Screen arrows published for a
                // queue that isn't there.
                audio.clearTrackNavigation(owner: token)
                trackIndex = nil
                failure = "The recording couldn't be reached. Check your connection and try again."
                return
            }
            audio.play()
            LibraryProgressStore.allowImmediateListeningWrite()
            persist(force: true)
            startCommitting()
        }
    }

    /// Writes the place once a second while the voice runs; the store's
    /// own throttle turns that into a commit every five. Cheap, and it
    /// is what makes a reading listened to in a pocket survive the app
    /// being killed.
    private func startCommitting() {
        commitTicker?.cancel()
        commitTicker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled, self.isPlaying else { continue }
                self.persist()
            }
        }
    }

    private func stopCommitting() {
        commitTicker?.cancel()
        commitTicker = nil
    }

    /// One row, one control: tap what is sounding to pause it, tap it
    /// again to resume, tap another to move there.
    func toggle(track index: Int) {
        if isSounding(track: index) {
            pause()
            return
        }
        // Already on its way — a second tap must not start a second
        // load of the same file, whose synchronous early return would
        // then be read as this one having failed.
        if isLoaded(track: index), audio.isLoading { return }

        if isLoaded(track: index), audio.duration > 0 {
            audio.play()
            startCommitting()
            return
        }
        play(track: index)
    }

    func togglePlayPause() {
        guard isActive else { return }
        if audio.isPlaying {
            pause()
        } else {
            audio.play()
            startCommitting()
        }
    }

    func pause() {
        guard isActive else { return }
        audio.pause()
        stopCommitting()
        persist(force: true)
    }

    /// Moves to the neighbouring track, if there is one.
    func step(by offset: Int) {
        guard let trackIndex else { return }
        let target = trackIndex + offset
        guard sections.indices.contains(target) else { return }
        play(track: target, from: 0)
    }

    func seek(to seconds: Double) {
        guard isActive else { return }
        audio.seek(to: seconds)
        persist(force: true)
    }

    func skip(by seconds: Double) {
        guard isActive else { return }
        if seconds >= 0 {
            audio.skipForward(seconds)
        } else {
            audio.skipBackward(-seconds)
        }
        persist(force: true)
    }

    func setRate(_ rate: Double) {
        guard let info else { return }
        audio.setPlaybackRate(rate, remember: false)
        UserSettings.shared.setReadingRate(rate, for: info.id)
    }

    func setSleepTimer(_ timer: AudioService.SleepTimer?) {
        guard isActive else { return }
        audio.setSleepTimer(timer)
    }

    /// The Lock Screen shows the book's own cloth once it has been drawn.
    func offerArtwork(_ image: UIImage, for bookID: String) {
        artwork[bookID] = image
        guard isActive, info?.id == bookID else { return }
        audio.updateNowPlayingArtwork(image: image)
    }

    // MARK: - Track navigation

    private var token: AnyHashable { "library-listening" }

    private func arm(at index: Int) {
        audio.setTrackNavigation(
            owner: token,
            canGoNext: index + 1 < sections.count,
            canGoPrevious: index > 0,
            onNext: { [weak self] in self?.step(by: 1) },
            onPrevious: { [weak self] in self?.step(by: -1) },
            onFinish: { [weak self] in
                guard let self else { return }
                // "Stop at the end of this reading" is honoured here — the
                // one place where the reading's own end is known.
                if audio.consumeEndOfTrackSleep() {
                    persist(force: true)
                    return
                }
                step(by: 1)
            }
        )
    }

    // MARK: - Remembering the place

    /// Writes the listening place. Throttled inside the store unless
    /// `force` — pausing, changing track, leaving, backgrounding.
    func persist(force: Bool = false) {
        guard let info, let context, let trackIndex,
              sections.indices.contains(trackIndex) else { return }

        // The player's clock while this session still holds it; the last
        // place we saw otherwise. `reset()` zeroes `currentTime`, and any
        // other flow claiming the player resets it out from under us —
        // reading only the live clock threw the place away at exactly the
        // moment it most needed writing.
        let live = audio.isTrackNavigationOwner(token) ? audio.currentTime : 0
        let seconds = live > 0 ? live : restingSeconds
        guard seconds.isFinite, seconds > 0 else { return }

        let section = sections[trackIndex]
        restingTrackID = section.id
        restingSeconds = seconds

        LibraryProgressStore.recordListening(
            bookID: info.id,
            chapterIndex: alignment.firstChapter(forTrack: trackIndex) ?? 0,
            trackID: section.id,
            trackIndex: trackIndex,
            seconds: seconds,
            duration: audio.duration,
            force: force,
            in: context
        )
    }

    // MARK: - Presence

    /// How many library screens are on screen. Every one of them counts
    /// itself in and out; the reading ends when the last leaves.
    private var screens = 0

    func enterScreen() {
        screens += 1
    }

    func leaveScreen() {
        screens = max(0, screens - 1)
        // Deferred by one turn of the run loop on purpose. A push runs
        // the arriving screen's `onAppear` and the leaving screen's
        // `onDisappear` in an order SwiftUI does not promise, and a
        // cancelled back-swipe fires both — so the count is only
        // believed once everything has settled.
        Task { @MainActor [weak self] in
            guard let self, screens == 0 else { return }
            stop()
        }
    }

    // MARK: - Stopping

    /// Ends the reading: the place is written, the player torn down, the
    /// Lock Screen cleared, and the audio session handed back so other
    /// apps stop being ducked. Only if this session still owns it — a
    /// Rosary begun since must not be silenced.
    func stop() {
        stopCommitting()
        // Nothing a load still in flight says can land after this.
        playGeneration &+= 1

        guard audio.isTrackNavigationOwner(token) else {
            info = nil
            sections = []
            alignment = .empty
            trackIndex = nil
            return
        }
        persist(force: true)
        audio.clearTrackNavigation(owner: token)
        audio.reset()
        // Hand the app-wide narration speed back with the player.
        audio.restoreRememberedRate()
        audio.deactivateSession()

        info = nil
        sections = []
        alignment = .empty
        trackIndex = nil
        failure = nil
    }

    // MARK: - Transport helpers

    /// "12:04" / "1:02:33"
    static func time(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let whole = Int(seconds)
        let minutes = whole / 60
        if minutes >= 60 {
            return "\(minutes / 60):\(String(format: "%02d", minutes % 60)):\(String(format: "%02d", whole % 60))"
        }
        return "\(minutes):\(String(format: "%02d", whole % 60))"
    }

    /// How far into a reading the voice had got — "31 min", "1 hr 5
    /// min", "a minute". A bare span, so a caller can set it in its own
    /// sentence: "31 min in" in the ledger, "31 min into the reading" on
    /// the Me page.
    static func elapsedLabel(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 1 { return "a minute" }
        if minutes >= 60 {
            let hours = minutes / 60
            let rest = minutes % 60
            return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
        }
        return "\(minutes) min"
    }
}
