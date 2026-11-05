//
//  SimpleRosary.swift
//  Lumen Viae
//
//  The pure parts of the simple Rosary, which the One Rosary beta
//  (`UserSettings.oneRosaryBeta`) now is: one player for every form,
//  every prayer said aloud from the moment PRAY is pressed, a pill at the
//  top to go to any part of the Rosary (`RosaryStop`), a speaker to mute
//  the voice while the Rosary goes on at the recording's own pace, and
//  the words being said lit from the recording's real timings
//  (`TimedLine`). A meditation set with no recording opens as text to
//  read, and someone who came to the Rosary to learn it is offered the
//  Audio Rosary first (`SimpleRosary`).
//
//  Off, nothing here is read, and the app is as it was.
//

import Foundation

// MARK: - TimedLine

/// One line of a recording and where it falls in it, in seconds: the
/// server's `lines` on a narration (`POST /api/v2/meditations/audio`) and,
/// once served, on each recorded prayer (`/api/rosary/audio`). The words
/// are the ones the recording says. A recording with no lines is never
/// lit: its pace is never guessed.
struct TimedLine: nonisolated Codable, Hashable {
    let text: String
    let start: Double
    let end: Double
}

extension Array where Element == TimedLine {

    /// The line being said at `time`: the last one begun, held through
    /// the breath before the next. Nil before the first begins, and for
    /// a recording with no lines.
    func lineIndex(at time: Double) -> Int? {
        guard let first = first, time >= first.start else { return nil }
        return lastIndex { $0.start <= time }
    }
}

// MARK: - RosaryStop

/// A part of the Rosary the pill at the top of the player goes to: the
/// opening prayers, a mystery (with its meditation), or the closing
/// prayers. The chaplet of the Seven Sorrows has seven.
enum RosaryStop: Hashable {
    case opening
    case mystery(Int)
    case closing

    /// Every stop of a Rosary of `decades`, in order; the opening and
    /// closing only where they are prayed
    static func all(decades: Int, includesPendant: Bool) -> [RosaryStop] {
        let mysteries = (0..<max(decades, 0)).map(RosaryStop.mystery)
        return includesPendant ? [.opening] + mysteries + [.closing] : mysteries
    }

    /// The stop the hand is on: `phase` is where on the Rosary it is,
    /// nil on the decades
    static func current(phase: SpokenSegment.Phase?, mystery: Int) -> RosaryStop {
        switch phase {
        case .opening: return .opening
        case .closing: return .closing
        case .decade, nil: return .mystery(mystery)
        }
    }

    /// Where in a spoken Rosary's script a stop begins: the first opening
    /// prayer, a mystery's announcement (its meditation follows it), or
    /// the first closing prayer. Nil where the script has no such part.
    func scriptIndex(in script: [SpokenSegment]) -> Int? {
        switch self {
        case .opening: return script.firstIndex { $0.phase == .opening }
        case .mystery(let n): return script.firstIndex { $0.phase == .decade && $0.mystery == n }
        case .closing: return script.firstIndex { $0.phase == .closing }
        }
    }

    /// The stop's place in `stops`, for the pill's dashes
    func position(in stops: [RosaryStop]) -> Int {
        stops.firstIndex(of: self) ?? 0
    }
}

// MARK: - SimpleRosary

/// The simple Rosary's rules, kept pure so the tests can hold them
enum SimpleRosary {

    /// Whether every prayer is said aloud. With the beta on, always,
    /// except a meditation set with no recording, which opens as text to
    /// read. Off, as the Audio choice says, as it always was.
    static func praysAloud(beta: Bool, setting: Bool, form: RosaryForm, setHasRecording: Bool = true) -> Bool {
        guard beta else { return form.praysAloud(setting: setting) }
        return form == .meditation ? setHasRecording : true
    }

    /// Whether a meditation set opens as text to read: with the beta on,
    /// a set none of whose meditations has a recording. With one, it
    /// stays in the player, and there is no switching between the two.
    static func opensAsText(beta: Bool, setHasRecording: Bool) -> Bool {
        beta && !setHasRecording
    }

    /// Whether the words are lit: only from a recording's real lines,
    /// muted or not. Nil for a recording with none.
    static func highlightedLine(timings: [TimedLine]?, at time: Double) -> Int? {
        guard let timings, !timings.isEmpty else { return nil }
        return timings.lineIndex(at: time)
    }

    /// Whether someone is offered the Audio Rosary before the regular
    /// Rosary: with the beta on, whoever said in onboarding (or Settings)
    /// that they came to learn it
    static func beginnerGoesToAudioRosary(beta: Bool, intentions: [PrayerIntention]) -> Bool {
        beta && intentions.contains(.learning)
    }

    /// The words the column sets for a prayer: the recording's own lines
    /// where it has them, so what is lit is what is said; otherwise the
    /// app's lines
    static func displayedLines(timings: [TimedLine]?, fallback: [String]) -> [String] {
        guard let timings, !timings.isEmpty else { return fallback }
        return timings.map(\.text)
    }
}
