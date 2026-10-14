//
//  ChantPlayback.swift
//  Lumen Viae
//
//  The values `ChantPlayer` works with, apart from the player itself: a
//  set unrolled into the chants and silences it sings, what happens at a
//  line's end, the reader's turn, a set's silence, the clock carried
//  between the player's ticks, and what went wrong when a chant would not
//  play. Pure, so each is tested without sounding anything.
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
    /// The singer sings a line, then rests for as long while the reader
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
    /// How long the whole silence is, for the Lock Screen's scrubber
    var length: TimeInterval = 0

    var isPaused: Bool { endsAt == nil }

    /// The silence as the Lock Screen shows it: its whole length, not the
    /// few seconds of bundled silence looping under it
    var timeline: AudioService.NowPlayingTimeline {
        AudioService.NowPlayingTimeline(duration: max(length, remaining), remaining: remaining, endsAt: endsAt)
    }
}

// MARK: - ChantTurn length

extension ChantTurn {
    /// How long the reader is given to sing a line back: as long as the
    /// singer took over it, at the pace it is sounding at, and a breath
    /// more. A line the chant does not have is given four seconds.
    static func length(of line: ChantLine?, speed: Double) -> TimeInterval {
        (line?.length ?? 4) / max(speed, 0.5) + 0.6
    }
}

// MARK: - ChantClock

/// The chant's place in its recording between the player's readings. The
/// player reports its time twice a second; between those readings the
/// time is carried forward from the last one at the pace the chant is
/// sounding, so a line's end is met within a tenth of a second and the
/// progress line moves smoothly. Read afresh whenever the reading
/// changes, and whenever the chant starts or stops, so a resume never
/// counts the time it was paused.
struct ChantClock: Equatable {
    /// The last reading, and when it was taken
    private(set) var media: Double = 0
    private(set) var wall: Date = .distantPast
    private(set) var playing = false
    /// Nil until the first reading, and after a seek, so the next reading
    /// anchors the clock even if it repeats the last
    private var observed: Double?

    /// Takes the player's reading, anchoring the clock again when it has
    /// moved or the chant has started or stopped
    mutating func observe(_ time: Double, playing: Bool, at date: Date) {
        guard observed != time || playing != self.playing else { return }
        observed = time
        self.playing = playing
        media = time
        wall = date
    }

    /// Forgets the last reading: after a seek, or a change of pace
    mutating func reset() {
        observed = nil
    }

    /// Where the chant stands at `date`, sounding at `rate`
    func time(at date: Date, rate: Double) -> Double {
        playing ? media + date.timeIntervalSince(wall) * rate : media
    }
}

// MARK: - ChantPlayError

/// Why a chant the reader asked for is not sounding, said wherever it
/// was asked for: the chant's page, the mini player, the practice
enum ChantPlayError: Equatable {
    /// The recording is not in the app
    case missing
    /// The recording would not load
    case failed

    var message: String {
        switch self {
        case .missing: return "This chant's recording is missing."
        case .failed:  return "The chant couldn't be played."
        }
    }

    /// The same, short enough for a caption under a disc
    var caption: String {
        switch self {
        case .missing: return "Recording missing"
        case .failed:  return "Couldn't play"
        }
    }
}
