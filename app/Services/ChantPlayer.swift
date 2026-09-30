//
//  ChantPlayer.swift
//  Lumen Viae
//
//  The Chant Library's hold on the shared player: the chant pages, the
//  library's rows and the Chapel's Chant tile all sound through it, so a
//  chant started on one is paused on another and the tile knows what the
//  library is singing.
//
//  It holds the player by a claim (`AudioClaim`), and everything it says
//  about playback is the claim's: when another flow (a Rosary, a book, a
//  consecration day singing the very same recording) takes the player,
//  the claim ends, and its progress line and pause glyph quietly return
//  to rest instead of narrating someone else's audio. It once decided
//  that for itself, from the file it loaded, the load generation and the
//  Lock Screen arrows, and a day that took the same recording from it
//  left both believing they held it.
//
//  It lives **above the views**, like `LibraryListeningSession`: the
//  Chapel is a tab, and `ContentView`'s tab `switch` destroys a view's
//  `@State` the moment the user looks at the Journal. A chant that kept
//  its hold in view state would go on singing with nothing in the app
//  able to pause it.
//
//  Practice asks two things of it the tile never did: a slower pace (a
//  chant learned by ear is learned at three-quarters speed first) and a
//  chant sung again from the top when it ends. The pace is borrowed —
//  part of the claim, never remembered as the app's narration speed —
//  and comes back however the claim ends.
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

    /// The player, while the library holds it. Ended by another flow's
    /// claim or load (`lostPlayer`), or by `relinquish()`.
    private var claim: AudioClaim?

    private var loadCount = 0
    private var loadTask: Task<Void, Never>?

    private let audio = AudioService.shared

    private init() {
        let stored = ChantCatalog.chant(UserSettings.shared.chapelChantID)
        current = stored ?? ChantCatalog.antiphonOfTheSeason() ?? ChantCatalog.all[0]
    }

    // MARK: - What is sounding

    /// Whether the player's loaded audio is still this player's chant:
    /// its claim holds the player, and the item in it is the one it loaded
    var ownsPlayback: Bool { claim?.holdsItem ?? false }

    var isPlaying: Bool { claim?.isPlaying ?? false }

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
        guard let claim, claim.duration > 0 else { return 0 }
        return min(1, claim.currentTime / claim.duration)
    }

    var currentTime: Double { claim?.currentTime ?? 0 }

    /// The recording's length: the player's once loaded, the catalog's
    /// measured length before, so the page never reads "0:00".
    var duration: Double {
        let loaded = claim?.duration ?? 0
        return loaded > 0 ? loaded : current.duration
    }

    /// "0:55 of 4:12", once the recording is loaded and ours.
    var timeLabel: String? {
        guard let claim, claim.duration > 0 else { return nil }
        return "\(Self.clock(claim.currentTime)) of \(Self.clock(claim.duration))"
    }

    /// "1:12" — how far into the recording, once it is loaded and ours.
    /// The tile's kicker carries it at full width and the transport row
    /// at half, so the time is said once either way.
    var elapsedLabel: String? {
        guard let claim, claim.duration > 0 else { return nil }
        return Self.clock(claim.currentTime)
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
            claim?.togglePlayback()
        } else {
            play(current)
        }
    }

    /// Play or pause `chant`: the one sounding pauses, any other starts.
    func toggle(_ chant: Chant) {
        if holds(chant) {
            claim?.togglePlayback()
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

        // Taken now, at the tap: whatever holds the player is what the
        // user asked to take it from, and nothing can claim it while the
        // recording arrives without ending this claim first
        let claim = takePlayer()

        // A load already in flight is superseded, not left to finish:
        // its continuation would otherwise reach `play()` after the user
        // asked for something else entirely.
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { if token == self.loadCount { self.isLoading = false } }

            // Loaded afresh, from its top, when the file in the player is
            // someone else's (a consecration day's Veni Creator) — the
            // claim sees to that
            let ready = await claim.load(
                url,
                title: chant.latinTitle,
                subtitle: chant.setting.map { "Chant · \($0)" } ?? "Chant",
                album: ChantCatalog.credit,
                claimNowPlaying: true
            )

            // Superseded by another chant, or the player taken meanwhile:
            // nothing to say, and nothing to play
            guard token == self.loadCount, !Task.isCancelled, claim.isCurrent else { return }

            // `load` answers false for a track already loaded whose
            // duration is still resolving — a second press on the same
            // chant, not a failure. The claim holding the item is the
            // honest test of whether the load landed.
            guard ready || claim.holdsItem else {
                self.errorMessage = "The chant couldn't be played."
                // Nothing of the chant's is in the player: the player, the
                // arrows and the app's speed go back
                claim.release()
                self.claim = nil
                return
            }

            self.attachNavigation(to: claim)
            claim.play()
        }
    }

    /// Moves the playhead to a fraction of the recording.
    func seek(toFraction fraction: Double) {
        guard let claim, claim.duration > 0 else { return }
        claim.seek(to: min(max(fraction, 0), 1) * claim.duration)
    }

    /// Back to the top, for another try at a phrase.
    func restart() {
        guard let claim, claim.holdsItem else { return }
        claim.seek(to: 0)
        if !claim.isPlaying { claim.play() }
    }

    /// Practice pace. Applied at once to a chant already sounding.
    func setRate(_ newRate: Double) {
        rate = newRate
        claim?.setRate(newRate)
    }

    /// Gives the player and the app's narration speed back: the chant is
    /// put away, or the page is done with it. Silent if the player has
    /// already moved on to someone else's audio.
    func relinquish() {
        loadCount += 1
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
        claim?.release()
        claim = nil
    }

    // MARK: - The Player

    /// The library's claim on the player: the one it holds, or a new one
    /// at the chant's own pace. A Rosary read at 2× has not thereby chosen
    /// a speed for sung Latin, so the pace is borrowed, and the app's
    /// comes back when the claim ends — by `relinquish()`, or by another
    /// flow taking the player.
    private func takePlayer() -> AudioClaim {
        if let claim, claim.isCurrent { return claim }
        let claim = audio.claim(.chant, rate: .borrowed(rate)) { [weak self] in
            self?.lostPlayer()
        }!
        claim.onFinish = { [weak self] in
            guard let self, self.repeats else { return }
            self.claim?.play()
        }
        self.claim = claim
        return claim
    }

    /// Another flow took the player: a recording still arriving is let go,
    /// and the readouts, which read the claim, are at rest
    private func lostPlayer() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
        claim = nil
    }

    // MARK: - Lock Screen

    /// The Lock Screen's arrows step through the library in its order;
    /// a chant heard to its end sings again when Repeat is on
    /// (`takePlayer`).
    private func attachNavigation(to claim: AudioClaim) {
        let chants = ChantCatalog.all
        let index = chants.firstIndex { $0.id == current.id } ?? 0
        claim.navigation = AudioNavigation(
            canGoNext: index < chants.count - 1,
            canGoPrevious: index > 0,
            onNext: { [weak self] in
                guard let self, index < chants.count - 1 else { return }
                self.play(chants[index + 1])
            },
            onPrevious: { [weak self] in
                guard let self, index > 0 else { return }
                self.play(chants[index - 1])
            }
        )
    }
}
