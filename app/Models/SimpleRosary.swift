//
//  SimpleRosary.swift
//  Lumen Viae
//
//  The pure parts of the simple Rosary: one player for every form,
//  every prayer said aloud from the moment PRAY is pressed, a pill at the
//  top to go to any part of the Rosary (`RosaryStop`), a speaker to mute
//  the voice while the Rosary goes on at the recording's own pace, and
//  the words being said lit from the recording's real timings
//  (`TimedLine`). A meditation set with no recording opens as text to
//  read, and someone who came to the Rosary to learn it begins on St.
//  Alphonsus Liguori's meditations with the helps on (`SimpleRosary`).
//
//  Abraham, Nov 2026: "Yes, only Rosary". It was the One Rosary beta
//  behind a switch; the switch and the Rosary it replaced are gone.
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

    /// Whether every prayer is said aloud: always, except a meditation
    /// set with no recording, which opens as text to read
    static func praysAloud(form: RosaryForm, setHasRecording: Bool = true) -> Bool {
        form == .meditation ? setHasRecording : true
    }

    /// Whether a meditation set opens as text to read: a set none of
    /// whose meditations has a recording. With one, it stays in the
    /// player, and the meditation can be opened as text from it.
    static func opensAsText(setHasRecording: Bool) -> Bool {
        !setHasRecording
    }

    /// Whether the words are lit: only from a recording's real lines,
    /// muted or not. Nil for a recording with none.
    static func highlightedLine(timings: [TimedLine]?, at time: Double) -> Int? {
        guard let timings, !timings.isEmpty else { return nil }
        return timings.lineIndex(at: time)
    }

    /// How far through the lit line the voice is, 0 to 1, from the
    /// line's own start and end in the recording: what a line too tall
    /// for the words is scrolled through by. Nil when no line is lit.
    static func litLineProgress(timings: [TimedLine]?, at time: Double) -> Double? {
        guard let timings, let index = highlightedLine(timings: timings, at: time) else { return nil }
        let line = timings[index]
        guard line.end > line.start else { return 0 }
        return min(max((time - line.start) / (line.end - line.start), 0), 1)
    }

    /// Whether someone begins on the beginner's path — St. Alphonsus
    /// Liguori's meditations with the helps on, after a page that lets
    /// them say no: whoever said in onboarding (or
    /// Settings) that they came to learn the Rosary
    ///
    /// Once they say no ("No thanks, I'll choose") it is not offered
    /// again (`declined`). To ask every time again, set
    /// `remembersDecline` false: that is the one place it is read.
    static func beginnerPath(intentions: [PrayerIntention], declined: Bool = false) -> Bool {
        intentions.contains(.learning) && !(remembersDecline && declined)
    }

    /// Whether a "No thanks" on the beginner's page is kept, so the page
    /// is not offered again
    static let remembersDecline = true

    /// The beginner's path as the doors to today's Rosary ask it, from
    /// the settings
    static func offersBeginnerPath(_ settings: UserSettings) -> Bool {
        beginnerPath(
            intentions: settings.intentions,
            declined: settings.declinedBeginnerRosary
        )
    }

    /// The set the beginner's path opens: St. Alphonsus Liguori's for the
    /// mysteries, or, where he wrote none (the Luminous), the first set
    /// offered
    static func beginnerSet(from summaries: [MeditationSetSummary]) -> MeditationSetSummary? {
        summaries.first {
            ($0.author ?? "").localizedCaseInsensitiveContains("Liguori")
                || $0.name.localizedCaseInsensitiveContains("Liguori")
        } ?? summaries.first
    }

    /// The paragraph of a page that holds a timed line, so the reader
    /// follows the voice by what it is really saying: matched on the
    /// line's opening words, with case, accents and spacing folded. Nil
    /// when no paragraph holds it, and then the page is not moved.
    static func paragraph(of line: String, in paragraphs: [String]) -> Int? {
        func fold(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        let words = fold(line).split(separator: " ").prefix(6).joined(separator: " ")
        guard !words.isEmpty else { return nil }
        return paragraphs.firstIndex { fold($0).contains(words) }
    }

    /// The one size every prayer's words are set at on the players, the
    /// Creed as the Glory Be: the text-size slider (0 to 1) across 15 to
    /// 22 points. Capped there, since the column stands beside the beads
    /// and a larger size left a few words to a line
    static let wordsSizeRange: ClosedRange<CGFloat> = 15...22

    static func wordsSize(scale: Double) -> CGFloat {
        let clamped = CGFloat(min(max(scale, 0), 1))
        return wordsSizeRange.lowerBound + clamped * (wordsSizeRange.upperBound - wordsSizeRange.lowerBound)
    }

    /// The words the column sets for a prayer: the recording's own lines
    /// where it has them, so what is lit is what is said; otherwise the
    /// app's lines
    static func displayedLines(timings: [TimedLine]?, fallback: [String]) -> [String] {
        guard let timings, !timings.isEmpty else { return fallback }
        return timings.map(\.text)
    }
}
