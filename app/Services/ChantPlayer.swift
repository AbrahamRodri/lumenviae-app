//
//  ChantPlayer.swift
//  Lumen Viae
//
//  The Chant Library's hold on the shared player: the chant pages, the
//  library's rows and the Chapel's Chant tile all sound through it, so a
//  chant started on one is paused on another and the tile knows what the
//  library is singing.
//
//  It remembers which file it loaded and the load generation it loaded
//  under, and holds the Lock Screen arrows; everything it claims about
//  playback is conditioned on all three still being its — so when another
//  flow (a Rosary, a book, a
//  consecration day singing the very same recording) takes the player,
//  its progress line and pause glyph quietly return to rest instead of
//  narrating someone else's audio.
//
//  It lives **above the views**, like `LibraryListeningSession`: the
//  Chapel is a tab, and `ContentView`'s tab `switch` destroys a view's
//  `@State` the moment the user looks at the Journal. A chant that kept
//  its hold in view state would go on singing with nothing in the app
//  able to pause it.
//
//  Practice asks two things of it the tile never did: a slower pace (a
//  chant learned by ear is learned at three-quarters speed first) and a
//  chant sung again from the top when it ends. Both are borrowed, never
//  remembered as the app's narration speed, and handed back.
//

import Foundation

@Observable
@MainActor
final class ChantPlayer {

    static let shared = ChantPlayer()

    /// The chant the Chapel's tile holds, remembered across launches:
    /// the last one sung, or the antiphon of the season until one is.
    private(set) var current: Chant

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Practice pace, 0.75 or 1. Borrowed from the app's own speed.
    private(set) var rate: Double = 1.0

    /// Sing the chant again from the top when it ends
    var repeats = false

    private var loadedURL: URL?

    /// The player's load generation at the moment this chant took it.
    /// Another flow's `loadAudio` of a different file resets the player
    /// and bumps this; one of the same file takes the arrows instead.
    /// Either lets go of the claim (`ownsPlayback`).
    private var loadedGeneration: Int?

    private var loadCount = 0
    private var loadTask: Task<Void, Never>?

    /// Whether this player set a rate that is not the app's own, so it
    /// knows there is something to hand back — and never "restores" a
    /// rate it did not borrow.
    private var borrowedRate = false

    /// Owner token for the Lock Screen's track arrows, which step through
    /// the library while a chant is sounding.
    private let navigationOwner = UUID()

    private let audio = AudioService.shared

    private init() {
        let stored = ChantCatalog.chant(UserSettings.shared.chapelChantID)
        current = stored ?? ChantCatalog.antiphonOfTheSeason() ?? ChantCatalog.all[0]
    }

    // MARK: - What is sounding

    /// Whether the player's loaded audio is still this player's chant.
    ///
    /// The URL alone will not do: the consecration flow loads some of the
    /// same files, so a player that went by URL would claim a chant a
    /// consecration day started. Nor will the generation alone: a second
    /// load of the file already loaded is not a new load, so a day that
    /// took the Veni Creator from the library kept its generation, and
    /// both believed they held it — closing the day then silenced the
    /// library's chant. The Lock Screen arrows go to whoever claimed the
    /// file last, so holding them is what settles it, as it does for the
    /// Prayer Book's player.
    var ownsPlayback: Bool {
        guard let loadedURL, let loadedGeneration else { return false }
        return audio.currentURL == loadedURL && audio.loadGeneration == loadedGeneration
            && audio.isTrackNavigationOwner(navigationOwner)
    }

    var isPlaying: Bool { ownsPlayback && audio.isPlaying }

    /// Whether `chant` is the one this player holds and is sounding.
    func isPlaying(_ chant: Chant) -> Bool {
        current.id == chant.id && isPlaying
    }

    /// Whether `chant` is loaded here, playing or paused part-way.
    func holds(_ chant: Chant) -> Bool {
        current.id == chant.id && ownsPlayback
    }

    /// 0…1 through the recording, or 0 when the player is elsewhere.
    var progress: Double {
        guard ownsPlayback, audio.duration > 0 else { return 0 }
        return min(1, audio.currentTime / audio.duration)
    }

    var currentTime: Double { ownsPlayback ? audio.currentTime : 0 }

    /// The recording's length: the player's once loaded, the catalog's
    /// measured length before, so the page never reads "0:00".
    var duration: Double {
        ownsPlayback && audio.duration > 0 ? audio.duration : current.duration
    }

    /// "0:55 of 4:12", once the recording is loaded and ours.
    var timeLabel: String? {
        guard ownsPlayback, audio.duration > 0 else { return nil }
        return "\(Self.clock(audio.currentTime)) of \(Self.clock(audio.duration))"
    }

    /// "1:12" — how far into the recording, once it is loaded and ours.
    /// The tile's kicker carries it at full width and the transport row
    /// at half, so the time is said once either way.
    var elapsedLabel: String? {
        guard ownsPlayback, audio.duration > 0 else { return nil }
        return Self.clock(audio.currentTime)
    }

    static func clock(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }

    /// "1 minute 5 seconds" — the clock as VoiceOver should say it, where
    /// "1:05" is read out as a ratio or an hour.
    static func spoken(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        let minutes = whole / 60
        let rest = whole % 60
        let minuteWords = minutes == 1 ? "1 minute" : "\(minutes) minutes"
        let secondWords = rest == 1 ? "1 second" : "\(rest) seconds"
        if minutes == 0 { return secondWords }
        if rest == 0 { return minuteWords }
        return "\(minuteWords) \(secondWords)"
    }

    // MARK: - Acts

    /// Play or pause the chant the tile holds.
    func togglePlayback() {
        if ownsPlayback {
            audio.togglePlayback()
        } else {
            play(current)
        }
    }

    /// Play or pause `chant`: the one sounding pauses, any other starts.
    func toggle(_ chant: Chant) {
        if holds(chant) {
            audio.togglePlayback()
        } else {
            play(chant)
        }
    }

    /// Loads and sings a chant, and makes it the tile's remembered one.
    func play(_ chant: Chant) {
        current = chant
        UserSettings.shared.chapelChantID = chant.id

        loadCount += 1
        let token = loadCount
        errorMessage = nil

        guard let url = chant.audioURL else {
            errorMessage = "This chant's recording is missing."
            return
        }
        isLoading = true

        // The transport as it stood when the user asked. Taking it over
        // from whatever holds it now is what they asked for; taking it
        // from something that claimed it *while they waited* is not.
        let generationAtRequest = audio.loadGeneration

        // A load already in flight is superseded, not left to finish:
        // its continuation would otherwise reach `audio.play()` after
        // the user asked for something else entirely.
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { if token == self.loadCount { self.isLoading = false } }

            guard self.audio.loadGeneration == generationAtRequest else { return }

            // The file already in the player, but someone else's (a
            // consecration day's Veni Creator): loaded afresh, so the
            // chant begins at its top rather than where the day left it
            if self.audio.currentURL == url, !self.ownsPlayback {
                self.audio.reset(preservingNowPlaying: true)
            }

            // Take the transport at chant's own pace. A Rosary read at
            // 2× has not thereby chosen a speed for sung Latin, so the
            // rate is borrowed rather than remembered, and handed back
            // in `relinquish()` — or as soon as another flow takes the
            // arrows from the chant.
            self.audio.setPlaybackRate(self.rate, remember: false, borrower: self.navigationOwner)
            self.borrowedRate = true

            let ready = await self.audio.loadAudio(
                from: url.absoluteString,
                title: chant.latinTitle,
                subtitle: chant.setting.map { "Chant · \($0)" } ?? "Chant",
                album: ChantCatalog.credit,
                claimNowPlaying: true
            )

            guard token == self.loadCount, !Task.isCancelled else { return }

            // `loadAudio` answers false for a track already loaded whose
            // duration is still resolving — a second press on the same
            // chant, not a failure. The player having the URL is the
            // honest test of whether the load landed.
            guard ready || self.audio.currentURL == url else {
                self.errorMessage = "The chant couldn't be played."
                self.releaseRate()
                return
            }

            self.loadedURL = url
            self.loadedGeneration = self.audio.loadGeneration
            self.attachNavigation()
            self.audio.play()
        }
    }

    /// Moves the playhead to a fraction of the recording.
    func seek(toFraction fraction: Double) {
        guard ownsPlayback, audio.duration > 0 else { return }
        audio.seek(to: min(max(fraction, 0), 1) * audio.duration)
    }

    /// Back to the top, for another try at a phrase.
    func restart() {
        guard ownsPlayback else { return }
        audio.seek(to: 0)
        if !audio.isPlaying { audio.play() }
    }

    /// Practice pace. Applied at once to a chant already sounding.
    func setRate(_ newRate: Double) {
        rate = newRate
        guard ownsPlayback else { return }
        audio.setPlaybackRate(newRate, remember: false, borrower: navigationOwner)
        borrowedRate = true
    }

    /// Gives the player and the app's narration speed back: the chant is
    /// put away, or the page is done with it. Silent if the player has
    /// already moved on to someone else's audio.
    func relinquish() {
        loadCount += 1
        loadTask?.cancel()
        loadTask = nil
        isLoading = false

        if ownsPlayback {
            audio.reset()
            audio.deactivateSession()
        }
        audio.clearTrackNavigation(owner: navigationOwner)
        loadedURL = nil
        loadedGeneration = nil
        releaseRate()
    }

    // MARK: - Lock Screen

    /// The Lock Screen's arrows step through the library in its order,
    /// and a chant heard to its end sings again when Repeat is on.
    private func attachNavigation() {
        let chants = ChantCatalog.all
        let index = chants.firstIndex { $0.id == current.id } ?? 0
        audio.setTrackNavigation(
            owner: navigationOwner,
            canGoNext: index < chants.count - 1,
            canGoPrevious: index > 0,
            onNext: { [weak self] in
                guard let self, index < chants.count - 1 else { return }
                self.play(chants[index + 1])
            },
            onPrevious: { [weak self] in
                guard let self, index > 0 else { return }
                self.play(chants[index - 1])
            },
            onFinish: { [weak self] in
                guard let self, self.repeats, self.ownsPlayback else { return }
                self.audio.play()
            }
        )
    }

    /// Hands the app-wide narration speed back, once, whether or not
    /// this player still holds the transport — unless another flow has
    /// set a speed of its own since, which is its to keep.
    private func releaseRate() {
        guard borrowedRate else { return }
        borrowedRate = false
        audio.restoreRememberedRate(from: navigationOwner)
    }
}
