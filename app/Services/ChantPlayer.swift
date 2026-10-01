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
//  Practice asks more of it than the tile ever did: a slower pace (a
//  chant learned by ear is learned at three-quarters speed first), a
//  chant sung again from the top when it ends, and — for a chant whose
//  lines have been timed (`Chant.lines`) — a line at a time: the line
//  again, or the choir and the learner taking turns. The pace is
//  borrowed — part of the claim, never remembered as the app's narration
//  speed — and comes back however the claim ends.
//
//  It also sings a set: an occasion's chants in their order, or a set
//  the reader made, with silence where the set keeps it, and — when the
//  reader asks — a wait for a tap between one chant and the next. A
//  silence is kept by playing a few seconds of bundled silence on a loop
//  through the same claim (`chant_silence.m4a`): with nothing sounding,
//  iOS suspends a locked phone's app, and a silence timed by the clock
//  alone never ended. The Lock Screen and the headphones reach the set's
//  own pauses — a silence, a wait, the reader's turn — through the
//  claim's transport, so headphones pulled out in a silence never let
//  the next chant begin from the speaker. And it can be told to fall
//  silent after a while, for chant sung to sleep by.
//

import Foundation

// MARK: - ChantQueue

/// Chants sung one after another: an occasion, a set, a day's devotion.
struct ChantQueue: Equatable {

    enum Entry: Equatable {
        case chant(Chant)
        /// A pause the set keeps, in silence, with what it is for
        case silence(note: String, seconds: Int)

        var chant: Chant? {
            if case .chant(let chant) = self { return chant }
            return nil
        }
    }

    /// "Benediction", "Thursday Holy Hour"
    let title: String
    let entries: [Entry]
    /// For each entry, the step of the occasion or the item of the set it
    /// was unrolled from — so a page lights the row that is sounding
    /// without unrolling the set again itself
    let origins: [Int]
    /// What was unrolled: "occasion:benediction", "set:<id>"; nil for a
    /// list of chants
    let source: String?
    var index: Int = 0

    var entry: Entry? { entries.indices.contains(index) ? entries[index] : nil }
    var hasNext: Bool { index + 1 < entries.count }
    var hasPrevious: Bool { index > 0 }

    /// The step or item sounding now
    var origin: Int? { origins.indices.contains(index) ? origins[index] : nil }

    /// The next chant to sound, past any silence
    var nextChant: Chant? {
        entries.dropFirst(index + 1).lazy.compactMap(\.chant).first
    }

    /// "2 of 4", counting the chants alone
    var position: String {
        let chants = entries.compactMap(\.chant)
        let sung = entries.prefix(index + 1).compactMap(\.chant).count
        return "\(max(1, sung)) of \(chants.count)"
    }

    /// The occasion unrolled, its steps numbered in the order they are
    /// written, each repeat and round of a step keeping its number
    static func occasion(_ occasion: ChantOccasion, on date: Date = Date()) -> ChantQueue {
        var entries: [Entry] = []
        var origins: [Int] = []
        var number = 0
        for block in occasion.blocks {
            let first = number
            for _ in 0..<max(1, block.rounds) {
                number = first
                for step in block.steps {
                    if let chant = step.chant.resolve(on: date) {
                        for _ in 0..<max(1, step.times) {
                            entries.append(.chant(chant))
                            origins.append(number)
                        }
                    }
                    number += 1
                }
            }
        }
        return ChantQueue(title: occasion.title, entries: entries, origins: origins, source: "occasion:\(occasion.id)")
    }

    static func set(_ set: ChantSet) -> ChantQueue {
        var entries: [Entry] = []
        var origins: [Int] = []
        for (position, item) in set.items.enumerated() {
            switch item.kind {
            case .chant(let id, let times):
                guard let chant = ChantCatalog.chant(id) else { continue }
                for _ in 0..<max(1, times) {
                    entries.append(.chant(chant))
                    origins.append(position)
                }
            case .pause(let note, let seconds):
                // A note with no silence of its own is read, not waited on
                if seconds > 0 {
                    entries.append(.silence(note: note, seconds: seconds))
                    origins.append(position)
                }
            }
        }
        return ChantQueue(title: set.name, entries: entries, origins: origins, source: "set:\(set.id.uuidString)")
    }

    static func chants(_ chants: [Chant], title: String) -> ChantQueue {
        ChantQueue(title: title, entries: chants.map(Entry.chant), origins: Array(chants.indices), source: nil)
    }
}

// MARK: - ChantLineEnd

/// What happens when the line under the hand has been sung. Only a chant
/// with timed lines has any of this; every other chant plays through.
enum ChantLineEnd: Equatable {
    /// The next line follows: the chant as it was recorded
    case goOn
    /// The same line again, until the reader moves on
    case again
    /// The choir sings a line, then rests for as long while the reader
    /// sings it back, then goes on to the next
    case takeTurns
    /// Stops at the line's end (practice: listen, read along)
    case stop
    /// Rests for the reader to sing it back, then stops (practice: sing
    /// along)
    case yourTurnThenStop
}

// MARK: - ChantTurn

/// The reader's turn to sing a line back, and when it ends — or, while
/// the Lock Screen or the headphones have paused it, how long is left
struct ChantTurn: Equatable {
    let line: Int
    var endsAt: Date?
    var remaining: TimeInterval
}

// MARK: - ChantSilence

/// A silence a set keeps: what it is for, and when it ends — or, while
/// paused, how long is left of it
struct ChantSilence: Equatable {
    let note: String
    var endsAt: Date?
    var remaining: TimeInterval

    var isPaused: Bool { endsAt == nil }
}

// MARK: - ChantPlayer

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

    @ObservationIgnored private var loadCount = 0
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    private let audio = AudioService.shared
    private let shelf = ChantShelfStore.shared

    private init() {
        let stored = ChantCatalog.chant(UserSettings.shared.chapelChantID)
        current = stored ?? ChantCatalog.antiphonOfTheSeason() ?? ChantCatalog.all[0]
    }

    // MARK: - What is sounding

    /// Whether the player's loaded audio is still this player's chant:
    /// its claim holds the player, and the item in it is the chant it
    /// loaded — not the silence a set keeps between two
    var ownsPlayback: Bool { !silentClipLoaded && (claim?.holdsItem ?? false) }

    var isPlaying: Bool { ownsPlayback && (claim?.isPlaying ?? false) }

    /// The speed the chant is sounding at: the player's own while it holds
    /// the chant, so a speed chosen on the Lock Screen is the one shown and
    /// the one the line clock keeps; the practice pace asked for otherwise
    var speed: Double {
        ownsPlayback ? audio.playbackRate : rate
    }

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
        guard ownsPlayback, let claim, claim.duration > 0 else { return 0 }
        return min(1, claim.currentTime / claim.duration)
    }

    var currentTime: Double { ownsPlayback ? (claim?.currentTime ?? 0) : 0 }

    /// The recording's length: the player's once loaded, the catalog's
    /// measured length before, so the page never reads "0:00".
    var duration: Double {
        let loaded = ownsPlayback ? (claim?.duration ?? 0) : 0
        return loaded > 0 ? loaded : current.duration
    }

    /// "0:55 of 4:12", once the recording is loaded and ours.
    var timeLabel: String? {
        guard ownsPlayback, let claim, claim.duration > 0 else { return nil }
        return "\(Self.clock(claim.currentTime)) of \(Self.clock(claim.duration))"
    }

    /// "55 seconds of 4 minutes 12 seconds": the same, as VoiceOver says it
    var spokenTimeLabel: String? {
        guard ownsPlayback, let claim, claim.duration > 0 else { return nil }
        return "\(Self.spoken(claim.currentTime)) of \(Self.spoken(claim.duration))"
    }

    /// "1:12" — how far into the recording, once it is loaded and ours.
    /// The tile's kicker carries it at full width and the transport row
    /// at half, so the time is said once either way.
    var elapsedLabel: String? {
        guard ownsPlayback, let claim, claim.duration > 0 else { return nil }
        return Self.clock(claim.currentTime)
    }

    /// Whether the library is in the middle of something the mini player
    /// should stand for: a chant loaded, a set under way, a silence kept
    var isActive: Bool {
        ownsPlayback || isLoading || queue != nil || silence != nil
    }

    static func clock(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }

    /// "¾×", "1×", or a speed the Lock Screen set ("1.5×"): the pace the
    /// chant is sounding at, as the transport and the practice show it
    static func speedLabel(_ speed: Double) -> String {
        if abs(speed - 0.75) < 0.01 { return "¾×" }
        if abs(speed - 1) < 0.01 { return "1×" }
        let formatted = speed.formatted(.number.precision(.fractionLength(0...2)))
        return "\(formatted)×"
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

    /// Play or pause the chant the tile holds. A silence paused from the
    /// Lock Screen takes up where it was; a silence keeping its time, or a
    /// set waiting between chants, goes on at once to the next chant.
    func togglePlayback() {
        if let silence {
            if silence.isPaused {
                resumeSilence()
            } else {
                endSilence()
                continueQueue()
            }
        } else if waitingForNext {
            continueQueue()
        } else if let turn, turn.endsAt == nil {
            resumeTurn()
        } else if ownsPlayback {
            claim?.togglePlayback()
        } else {
            play(current)
        }
    }

    /// Play or pause `chant`: the one sounding pauses, any other starts.
    /// The chant a set is waiting to sing next goes on with the set; the
    /// one it has just sung, asked for again, is sung on its own.
    func toggle(_ chant: Chant) {
        if waitingForNext, queue?.nextChant?.id == chant.id {
            continueQueue()
        } else if holds(chant), !waitingForNext {
            claim?.togglePlayback()
        } else {
            play(chant)
        }
    }

    /// Pauses whatever the library is doing — the chant, a silence, the
    /// reader's turn — keeping each where it stands
    func pause() {
        if silence != nil { suspendSilence() }
        if turn != nil { suspendTurn() }
        if ownsPlayback { claim?.pause() }
    }

    /// Whether the library is going on with what it holds: a chant
    /// sounding, or a silence or the reader's turn keeping its time
    var isGoingOn: Bool {
        isPlaying || !(silence?.isPaused ?? true) || turn?.endsAt != nil
    }

    /// A set's own transport: pauses whatever is going on, keeping each
    /// where it stands, or takes up what was paused — where the mini
    /// player's tap would pass over a silence, this holds it
    func pauseOrResume() {
        guard !isLoading else { return }
        if isGoingOn { pause() } else { togglePlayback() }
    }

    /// The chant the mini player opens: the next, while a set waits for it
    var shown: Chant {
        if waitingForNext, let next = queue?.nextChant { return next }
        return current
    }

    /// Loads and sings a chant on its own, and makes it the tile's
    /// remembered one. A set under way is put down, and the lines go back
    /// to playing through: the reader chose another chant.
    func play(_ chant: Chant) {
        endQueue()
        lineEnd = .goOn
        load(chant)
    }

    /// Loads and sings a chant, keeping whatever set it belongs to: from
    /// the start of line `startLine` when one is asked for, and held
    /// still there when `paused`, for the reader to sing first.
    private func load(_ chant: Chant, startLine: Int? = nil, paused: Bool = false) {
        lineTask?.cancel()
        silentClipLoaded = false
        current = chant
        UserSettings.shared.chapelChantID = chant.id
        shelf.notePlayed(chant.id)

        loadCount += 1
        let token = loadCount
        errorMessage = nil
        resetLines()

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
                subtitle: self.nowPlayingSubtitle(for: chant),
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
            // To the line first, so nothing of the chant's opening sounds
            // on the way there; else from the top. The same recording
            // loaded again — the next Ave Maria of a decade — stays in the
            // player where it stood, and a step on or back in a set would
            // only have moved the count
            if let startLine, chant.lines.indices.contains(startLine) {
                claim.seek(to: chant.lines[startLine].start)
                self.activeLine = startLine
                self.lineIndex = startLine
            } else if claim.currentTime > 0.25 {
                claim.seek(to: 0)
            }
            if !paused { claim.play() }
            self.startLineWatch()
        }
    }

    /// The Lock Screen's line under the title: the set and where it
    /// stands, or the setting
    private func nowPlayingSubtitle(for chant: Chant) -> String {
        if let queue { return "\(queue.title) · \(queue.position)" }
        return chant.setting.map { "Chant · \($0)" } ?? "Chant"
    }

    /// Moves the playhead to a fraction of the recording.
    func seek(toFraction fraction: Double) {
        guard ownsPlayback, let claim, claim.duration > 0 else { return }
        seek(to: min(max(fraction, 0), 1) * claim.duration)
    }

    /// Ten seconds on or back: the transport's steps for a chant whose
    /// lines have not been timed
    func skip(by seconds: Double) {
        guard ownsPlayback, let claim else { return }
        let target = min(max(0, claim.currentTime + seconds), max(0, claim.duration - 0.5))
        seek(to: target)
    }

    private func seek(to time: Double) {
        guard let claim else { return }
        claim.seek(to: time)
        // Read afresh from the new place, even one the clock already read
        anchor = nil
        lastObserved = -1
        endTurn()
        activeLine = current.lineIndex(at: time)
        lineIndex = activeLine
    }

    /// Back to the top, for another try at a phrase.
    func restart() {
        guard ownsPlayback, let claim else { return }
        seek(to: 0)
        if !claim.isPlaying { claim.play() }
    }

    /// Practice pace. Applied at once to a chant already sounding.
    func setRate(_ newRate: Double) {
        rate = newRate
        claim?.setRate(newRate)
        anchor = nil
    }

    /// Gives the player and the app's narration speed back: the chant is
    /// put away, or the page is done with it. Silent if the player has
    /// already moved on to someone else's audio.
    func relinquish() {
        loadCount += 1
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
        silentClipLoaded = false
        endQueue()
        resetLines()
        lineTask?.cancel()
        cancelSleep()
        claim?.release()
        claim = nil
    }

    // MARK: - Sets

    /// The set being sung, if one is
    private(set) var queue: ChantQueue?

    /// A chant has ended and the reader asked to be waited for before the
    /// next (`ChantShelfStore.pausesBetween`)
    private(set) var waitingForNext = false

    /// A silence the set keeps, and when it ends
    private(set) var silence: ChantSilence?

    @ObservationIgnored private var silenceTask: Task<Void, Never>?

    /// The few seconds of bundled silence a set's pause plays on a loop
    /// are in the player, not a chant
    private var silentClipLoaded = false

    /// Sings a set from `index`
    func play(_ queue: ChantQueue, from index: Int = 0) {
        guard !queue.entries.isEmpty else { return }
        var queue = queue
        queue.index = min(max(0, index), queue.entries.count - 1)
        self.queue = queue
        waitingForNext = false
        // The player is taken at the tap, as a chant's is, so a set that
        // opens on a silence holds it too
        _ = takePlayer()
        playEntry()
    }

    /// Whether `queue` is the one being sung: the same occasion or set,
    /// or for a list of chants, the same chants under the same title
    func isSinging(_ queue: ChantQueue) -> Bool {
        guard let current = self.queue else { return false }
        if let source = queue.source { return current.source == source }
        return current.title == queue.title && current.entries == queue.entries
    }

    /// Whether the set from `source` is being sung, and what of it sounds
    func origin(singing source: String) -> Int? {
        guard let queue, queue.source == source else { return nil }
        return queue.origin
    }

    /// The next entry of the set, now
    func continueQueue() {
        guard var queue, queue.hasNext else {
            endQueue()
            return
        }
        queue.index += 1
        self.queue = queue
        waitingForNext = false
        playEntry()
    }

    func previousInQueue() {
        guard var queue, queue.hasPrevious else { return }
        queue.index -= 1
        self.queue = queue
        waitingForNext = false
        playEntry()
    }

    /// Puts the set down; the chant sounding, if any, sings on alone
    func endQueue() {
        queue = nil
        waitingForNext = false
        endSilence()
        // The silence's few seconds are no chant: a set put down in one, or
        // ending on one, takes them out of the player and off the Lock
        // Screen, where "Silence" once stood until something else loaded
        if silentClipLoaded {
            silentClipLoaded = false
            loadCount += 1
            loadTask?.cancel()
            loadTask = nil
            claim?.unload(preservingNowPlaying: false)
        }
    }

    private func playEntry() {
        endSilence()
        endTurn()
        // A set is sung as it is written: a line looped or turns taken on
        // a chant's page are not carried into it
        lineEnd = .goOn
        guard let entry = queue?.entry else {
            endQueue()
            return
        }
        switch entry {
        case .chant(let chant):
            load(chant)
        case .silence(let note, let seconds):
            beginSilence(note: note, seconds: TimeInterval(seconds))
        }
    }

    // MARK: Silence

    private func beginSilence(note: String, seconds: TimeInterval) {
        silence = ChantSilence(note: note, endsAt: Date().addingTimeInterval(seconds), remaining: seconds)
        scheduleSilenceEnd(after: seconds)
        playSilentClip(note: note)
    }

    /// The bundled silence, on a loop through the set's own claim, so a
    /// locked phone keeps the app awake to end the silence on time
    private func playSilentClip(note: String) {
        let claim = takePlayer()
        loadCount += 1
        let token = loadCount
        lineTask?.cancel()
        // A chant still arriving is let go for the silence, and with it its
        // spinner: left on, the set's own pause stood refusing every tap
        isLoading = false
        claim.pause()
        guard let url = Bundle.main.url(forResource: "chant_silence", withExtension: "m4a") else { return }
        silentClipLoaded = true
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let ready = await claim.load(
                url,
                title: note.isEmpty ? "Silence" : note,
                subtitle: self.queue?.title ?? "Silence",
                album: ChantCatalog.credit,
                claimNowPlaying: true
            )
            if token != self.loadCount {
                // Put down while it arrived, and nothing loaded since: the
                // silence is taken back out rather than read as a chant
                if !self.silentClipLoaded, !self.isLoading, claim.holdsItem, self.audio.currentURL == url {
                    claim.unload(preservingNowPlaying: false)
                }
                return
            }
            guard !Task.isCancelled, claim.isCurrent,
                  ready || claim.holdsItem, let silence = self.silence, !silence.isPaused else { return }
            self.attachNavigation(to: claim)
            claim.play()
        }
    }

    private func scheduleSilenceEnd(after seconds: TimeInterval) {
        silenceTask?.cancel()
        silenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, let silence = self.silence, !silence.isPaused else { return }
            self.silenceEnded()
        }
    }

    /// The silence has been kept. Another flow holding the player by now
    /// ends the set rather than have the next chant claim over it.
    private func silenceEnded() {
        silenceTask = nil
        silence = nil
        guard let claim, claim.isCurrent else {
            endQueue()
            return
        }
        claim.pause()
        entryFinished()
    }

    private func suspendSilence() {
        guard var silence, let endsAt = silence.endsAt else { return }
        silence.remaining = max(0, endsAt.timeIntervalSinceNow)
        silence.endsAt = nil
        self.silence = silence
        silenceTask?.cancel()
        silenceTask = nil
        if silentClipLoaded { claim?.pause() }
    }

    private func resumeSilence() {
        guard var silence, silence.isPaused else { return }
        silence.endsAt = Date().addingTimeInterval(silence.remaining)
        self.silence = silence
        scheduleSilenceEnd(after: silence.remaining)
        if silentClipLoaded, let claim, claim.holdsItem {
            claim.play()
        } else {
            playSilentClip(note: silence.note)
        }
    }

    private func endSilence() {
        silenceTask?.cancel()
        silenceTask = nil
        silence = nil
    }

    /// One entry of the set is done: the next follows, or waits for a
    /// tap, or the set is over
    private func entryFinished() {
        guard let queue else { return }
        guard queue.hasNext else {
            endQueue()
            return
        }
        if shelf.pausesBetween, queue.entries[queue.index + 1].chant != nil {
            waitingForNext = true
        } else {
            continueQueue()
        }
    }

    // MARK: - End of a recording

    private func finished() {
        // The silence's few seconds, heard to their end, go round again
        // until the silence is kept
        if silentClipLoaded {
            if let silence, !silence.isPaused { claim?.play() }
            return
        }
        if sleepsAtEndOfChant {
            fallAsleep()
            return
        }
        // The last line of a chant whose lines are being stepped: its end
        // is the recording's
        if current.hasLines, let line = activeLine ?? current.lines.indices.last, lineEnd != .goOn {
            lineEnded(line)
            return
        }
        // A set goes on whatever Repeat says: Repeat is for a chant sung
        // on its own, and would hold a set on its first chant for good
        if queue != nil {
            entryFinished()
            return
        }
        if repeats {
            claim?.play()
        }
    }

    // MARK: - Lines

    /// The line sounding now, for a chant with timed lines
    private(set) var lineIndex: Int?

    /// What happens at the end of each line (`ChantLineEnd`)
    private(set) var lineEnd: ChantLineEnd = .goOn

    /// The reader's turn to sing, while it lasts
    private(set) var turn: ChantTurn?

    /// Bumped each time a line stops at its end for practice, so a page
    /// can answer it
    private(set) var linesFinished = 0

    /// The line whose end is being waited on
    @ObservationIgnored private var activeLine: Int?

    /// The player's clock is read twice a second; between its ticks the
    /// time is carried forward from the last one at the chant's pace, so
    /// a line's end is met within a tenth of a second
    @ObservationIgnored private var anchor: (media: Double, wall: Date)?
    @ObservationIgnored private var lastObserved: Double = -1
    @ObservationIgnored private var anchoredPlaying = false
    @ObservationIgnored private var lineTask: Task<Void, Never>?
    @ObservationIgnored private var turnTask: Task<Void, Never>?

    var currentLine: ChantLine? {
        guard let lineIndex, current.lines.indices.contains(lineIndex) else { return nil }
        return current.lines[lineIndex]
    }

    func setLineEnd(_ end: ChantLineEnd) {
        lineEnd = end
        endTurn()
        activeLine = lineIndex
    }

    /// To the start of a line, playing on if it was playing
    func seek(toLine index: Int) {
        guard current.lines.indices.contains(index), ownsPlayback else { return }
        seek(to: current.lines[index].start)
        activeLine = index
        lineIndex = index
    }

    func nextLine() {
        let next = (lineIndex ?? -1) + 1
        guard current.lines.indices.contains(next) else { return }
        seek(toLine: next)
    }

    func previousLine() {
        guard let lineIndex else { return }
        // Within the first two seconds of a line, the line before; later,
        // this line from its start — as a track's back button does
        let index = currentTime - current.lines[lineIndex].start > 2 ? lineIndex : lineIndex - 1
        seek(toLine: max(0, index))
    }

    /// Sings line `index` of `chant` and then does what `end` says —
    /// practice's one act. Loads the chant first when it is not ours.
    func playLine(_ index: Int, of chant: Chant, then end: ChantLineEnd) {
        guard chant.lines.indices.contains(index) else { return }
        endTurn()
        // Practising a line is the reader's own act: a set under way is
        // put down, whether or not the chant was already in the player
        endQueue()
        if holds(chant), let claim {
            lineEnd = end
            seek(toLine: index)
            if !claim.isPlaying { claim.play() }
        } else {
            load(chant, startLine: index)
            lineEnd = end
        }
    }

    /// The reader sings line `index` first, then the choir sings it back
    /// to them, and stops — practice's last step
    func yourTurnFirst(_ index: Int, of chant: Chant) {
        guard chant.lines.indices.contains(index) else { return }
        endQueue()
        if holds(chant) {
            claim?.pause()
            seek(toLine: index)
        } else {
            // Loaded, but held still at the line, so the choir can answer
            // from its start when the reader's turn is over
            load(chant, startLine: index, paused: true)
        }
        lineEnd = .stop
        beginTurn(on: index) { [weak self] in
            guard let self, self.ownsPlayback, let claim = self.claim else { return }
            self.seek(toLine: index)
            claim.play()
        }
    }

    private func resetLines() {
        endTurn()
        lineIndex = current.hasLines ? 0 : nil
        activeLine = current.hasLines ? 0 : nil
        anchor = nil
        lastObserved = -1
    }

    private func startLineWatch() {
        lineTask?.cancel()
        guard current.hasLines else {
            lineIndex = nil
            return
        }
        // A tenth of a second while the chant sounds, a second while it
        // rests, and over once the player holds it no longer
        lineTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.ownsPlayback, let claim = self.claim else { return }
                self.tickLines()
                try? await Task.sleep(for: .milliseconds(claim.isPlaying ? 100 : 1000))
            }
        }
    }

    private func tickLines() {
        guard ownsPlayback, let claim, current.hasLines, turn == nil else { return }

        // The clock carried forward from the player's last reading — taken
        // afresh whenever that reading changes, and whenever the chant
        // starts or stops, so a resume never counts the time it was paused
        let observed = claim.currentTime
        let playing = claim.isPlaying
        if anchor == nil || observed != lastObserved || playing != anchoredPlaying {
            lastObserved = observed
            anchoredPlaying = playing
            anchor = (observed, Date())
        }
        let now: Double
        if playing, let anchor {
            now = anchor.media + Date().timeIntervalSince(anchor.wall) * speed
        } else {
            now = observed
        }

        if lineEnd == .goOn || activeLine == nil {
            let index = current.lineIndex(at: now)
            if index != lineIndex { lineIndex = index }
            activeLine = index
            return
        }

        guard playing, let line = activeLine, current.lines.indices.contains(line) else { return }
        if lineIndex != line { lineIndex = line }
        if now >= current.lines[line].end - 0.03 {
            lineEnded(line)
        }
    }

    /// The line under the hand has been sung: what `lineEnd` says follows
    private func lineEnded(_ line: Int) {
        guard let claim else { return }
        let lines = current.lines
        switch lineEnd {
        case .goOn:
            break
        case .again:
            seek(toLine: line)
            claim.play()
        case .stop:
            claim.pause()
            seek(toLine: line)
            linesFinished += 1
        case .yourTurnThenStop:
            claim.pause()
            beginTurn(on: line) { [weak self] in
                guard let self else { return }
                self.seek(toLine: line)
                self.linesFinished += 1
            }
        case .takeTurns:
            claim.pause()
            beginTurn(on: line) { [weak self] in
                guard let self, let claim = self.claim else { return }
                if lines.indices.contains(line + 1) {
                    self.seek(toLine: line + 1)
                    claim.play()
                } else {
                    self.seek(toLine: 0)
                    self.finishedTakingTurns()
                }
            }
        }
    }

    /// The last line has been sung back: the chant is over, as if it had
    /// played to its end
    private func finishedTakingTurns() {
        if queue != nil {
            entryFinished()
        } else if repeats {
            claim?.play()
        }
    }

    /// What follows the reader's turn when it ends
    @ObservationIgnored private var afterTurn: (() -> Void)?

    /// The reader's turn: as long as the choir took over the line, at the
    /// pace it is sounding at, and a breath more
    private func beginTurn(on line: Int, then: @escaping () -> Void) {
        let length = current.lines.indices.contains(line) ? current.lines[line].length : 4
        let seconds = length / max(speed, 0.5) + 0.6
        turn = ChantTurn(line: line, endsAt: Date().addingTimeInterval(seconds), remaining: seconds)
        afterTurn = then
        scheduleTurnEnd(after: seconds, line: line)
    }

    private func scheduleTurnEnd(after seconds: TimeInterval, line: Int) {
        turnTask?.cancel()
        turnTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, let turn = self.turn, turn.line == line, turn.endsAt != nil else { return }
            let then = self.afterTurn
            self.turn = nil
            self.afterTurn = nil
            then?()
        }
    }

    /// The turn held where it stands — the Lock Screen's pause, the
    /// headphones taken out — with what was left of it
    private func suspendTurn() {
        guard var turn, let endsAt = turn.endsAt else { return }
        turn.remaining = max(0, endsAt.timeIntervalSinceNow)
        turn.endsAt = nil
        self.turn = turn
        turnTask?.cancel()
        turnTask = nil
    }

    private func resumeTurn() {
        guard var turn, turn.endsAt == nil else { return }
        turn.endsAt = Date().addingTimeInterval(turn.remaining)
        self.turn = turn
        scheduleTurnEnd(after: turn.remaining, line: turn.line)
    }

    private func endTurn() {
        turnTask?.cancel()
        turnTask = nil
        turn = nil
        afterTurn = nil
    }

    // MARK: - Sleep

    /// When the library falls silent, if the reader asked it to
    private(set) var sleepEndsAt: Date?

    /// Falls silent when the chant sounding ends
    private(set) var sleepsAtEndOfChant = false

    @ObservationIgnored private var sleepTask: Task<Void, Never>?

    var hasSleepTimer: Bool { sleepEndsAt != nil || sleepsAtEndOfChant }

    func sleep(afterMinutes minutes: Int) {
        cancelSleep()
        let seconds = TimeInterval(minutes * 60)
        sleepEndsAt = Date().addingTimeInterval(seconds)
        sleepTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled else { return }
            self.fallAsleep()
        }
    }

    func sleepAtEndOfChant() {
        cancelSleep()
        sleepsAtEndOfChant = true
    }

    func cancelSleep() {
        sleepTask?.cancel()
        sleepTask = nil
        sleepEndsAt = nil
        sleepsAtEndOfChant = false
    }

    private func fallAsleep() {
        claim?.pause()
        endQueue()
        endTurn()
        cancelSleep()
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
            self?.finished()
        }
        // The Lock Screen and the headphones reach the library's own
        // pauses, which the player knows nothing of: a pause holds a
        // silence or a turn where it stands, and headphones taken out in a
        // silence never let the next chant begin from the speaker
        claim.onTransport = { [weak self] request in
            self?.transport(request)
        }
        self.claim = claim
        return claim
    }

    private func transport(_ request: AudioService.TransportRequest) {
        switch request {
        case .pause:
            pause()
        case .play:
            if let silence {
                // A silence keeping its time is already what was asked
                if silence.isPaused { resumeSilence() }
            } else if waitingForNext {
                continueQueue()
            } else if let turn, turn.endsAt == nil {
                resumeTurn()
            } else if !isPlaying {
                togglePlayback()
            }
        case .toggle:
            if let silence, !silence.isPaused {
                suspendSilence()
            } else if let turn, turn.endsAt != nil {
                suspendTurn()
                if ownsPlayback { claim?.pause() }
            } else {
                togglePlayback()
            }
        }
    }

    /// Another flow took the player: a recording still arriving is let go,
    /// a set and a silence are put down, and the readouts, which read the
    /// claim, are at rest
    private func lostPlayer() {
        loadTask?.cancel()
        loadTask = nil
        lineTask?.cancel()
        isLoading = false
        silentClipLoaded = false
        claim = nil
        endQueue()
        endTurn()
        cancelSleep()
    }

    // MARK: - Lock Screen

    /// The Lock Screen's arrows step through the set being sung, or else
    /// through the library in its order; a chant heard to its end sings
    /// again when Repeat is on (`finished`).
    private func attachNavigation(to claim: AudioClaim) {
        if let queue {
            claim.navigation = AudioNavigation(
                canGoNext: queue.hasNext,
                canGoPrevious: queue.hasPrevious,
                onNext: { [weak self] in self?.continueQueue() },
                onPrevious: { [weak self] in self?.previousInQueue() }
            )
            return
        }
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
