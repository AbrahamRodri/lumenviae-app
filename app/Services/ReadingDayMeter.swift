//
//  ReadingDayMeter.swift
//  Lumen Viae
//
//  The day's reading measure: how much the reader means to read each
//  day, and how much of today has been read so far. One measure for the
//  whole shelf — a quarter-hour in Thérèse and ten minutes in Montfort
//  are one day's reading, not two ledgers.
//
//  A measure, never a scoreboard. Today's minutes reset silently each
//  morning; a missed day is never counted against the reader, never
//  chained into a streak, and never carried anywhere as a failure. The
//  dial fills toward the goal and that is the whole of what it does.
//
//  Two rules keep the count honest, and both are load-bearing:
//
//  Reading is what the reader does with the app in front of them, so
//  the clock stops when the app leaves the foreground and is re-armed
//  when it comes back. A phone in a pocket is not reading.
//
//  Reads never write. `rollDayIfNeeded` mutates and persists, so it is
//  called only from the counting paths; the figures a view asks for are
//  pure, and answer for today whether or not the stamp has been rolled
//  yet. A getter that wrote would be writing during SwiftUI's own
//  update pass.
//

import Foundation
import SwiftUI

// MARK: - ReadingGoal

/// How much the reader means to read each day, in their own words.
///
/// The raw value is a stable slug because it is what gets persisted:
/// were it the sentence, a copy edit would fail `init(rawValue:)` for
/// everyone who had chosen that measure and silently move them back to
/// the default. The sentence lives in `title`.
enum ReadingGoal: String, CaseIterable, Identifiable {
    case fewMinutes = "few-minutes"
    case quarterHour = "quarter-hour"
    case halfHour = "half-hour"
    case chapterADay = "chapter"

    var id: String { rawValue }

    /// The measure as the reader chose it.
    var title: String {
        switch self {
        case .fewMinutes: return "A few minutes a day"
        case .quarterHour: return "A quarter-hour a day"
        case .halfHour: return "Half an hour a day"
        case .chapterADay: return "A chapter a day"
        }
    }

    /// The measure in minutes — nil for the chapter measure, which is
    /// counted in chapters finished rather than minutes sat.
    var minutes: Int? {
        switch self {
        case .fewMinutes: return 5
        case .quarterHour: return 15
        case .halfHour: return 30
        case .chapterADay: return nil
        }
    }

    /// "A quarter-hour of reading" — the goal band's own phrasing.
    /// Written out rather than derived from the title: the chapter
    /// measure is not a span of reading and must not be phrased as one.
    var readingPhrase: String {
        switch self {
        case .fewMinutes: return "A few minutes of reading"
        case .quarterHour: return "A quarter-hour of reading"
        case .halfHour: return "Half an hour of reading"
        case .chapterADay: return "A chapter a day"
        }
    }

    /// Reads a stored value written before the raw values were slugs.
    /// The measures were once persisted as their own sentences.
    static func stored(_ raw: String) -> ReadingGoal? {
        if let goal = ReadingGoal(rawValue: raw) { return goal }
        return allCases.first { $0.title == raw }
    }
}

// MARK: - ReadingDayMeter

/// Counts the day's reading: minutes with a book open and in front of
/// the reader, and chapters read to their end. Backed by UserDefaults;
/// yesterday is simply gone.
@MainActor
@Observable
final class ReadingDayMeter {

    static let shared = ReadingDayMeter()

    private static let secondsKey = "readingMeter.seconds"
    private static let chaptersKey = "readingMeter.chapters"
    private static let dayKey = "readingMeter.day"

    /// Seconds already committed for today
    private var storedSeconds: Double = 0

    /// Chapters finished today
    private var storedChapters: Int = 0

    /// The day the stored figures belong to
    private var dayStamp: String = ""

    /// When the open reader began counting, nil when none is open or
    /// the app is in the background.
    private var sessionStart: Date?

    /// How many reader screens are on. Counted rather than flagged, for
    /// the reason `LibraryListeningSession` gives: a push runs the
    /// arriving screen's `onAppear` and the leaving screen's
    /// `onDisappear` in an order SwiftUI does not promise, and a
    /// cancelled back-swipe fires both. A bare flag stops counting for
    /// the rest of a reading the moment either happens.
    private var screens = 0

    /// Pinned to a fixed locale and calendar: the stamp is persisted and
    /// compared against a later one, so it must not shift under the
    /// device's own calendar or numbering system.
    private static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private init() {
        let d = UserDefaults.standard
        dayStamp = d.string(forKey: Self.dayKey) ?? ""
        storedSeconds = d.double(forKey: Self.secondsKey)
        storedChapters = d.integer(forKey: Self.chaptersKey)
    }

    private static var todayStamp: String {
        stampFormatter.string(from: Date())
    }

    /// Whether the stored figures belong to a day that has passed. Pure:
    /// the reads below answer for today without rolling the stamp, and
    /// the counting paths roll it when they write.
    private var isStale: Bool {
        dayStamp != Self.todayStamp
    }

    // MARK: - The day's figures
    //
    // All pure. Nothing here mutates or persists, so a view body may
    // ask freely — including across midnight, where these simply begin
    // answering zero before any counting path has rolled the stamp.

    /// Minutes read today, including the reading under way right now.
    var minutesToday: Int {
        guard !isStale else { return 0 }
        var seconds = storedSeconds
        if let sessionStart {
            // Clamped: the system clock is not monotonic, and a
            // correction that moves it backwards must not read as
            // negative minutes.
            seconds += max(0, Date().timeIntervalSince(sessionStart))
        }
        return max(0, Int(seconds / 60))
    }

    /// Chapters finished today.
    var chaptersToday: Int {
        isStale ? 0 : storedChapters
    }

    /// How far today's reading has come toward the goal, 0…1.
    func fraction(toward goal: ReadingGoal) -> Double {
        if let minutes = goal.minutes {
            guard minutes > 0 else { return 0 }
            return min(1, max(0, Double(minutesToday) / Double(minutes)))
        }
        return chaptersToday > 0 ? 1 : 0
    }

    /// "A quarter-hour of reading · 6 of 15 minutes so far"
    func goalLine(for goal: ReadingGoal) -> String {
        if let minutes = goal.minutes {
            return "\(goal.readingPhrase) · \(min(minutesToday, minutes)) of \(minutes) minutes so far"
        }
        switch chaptersToday {
        case 0: return "\(goal.readingPhrase) · not yet today"
        case 1: return "\(goal.readingPhrase) · one read today"
        default: return "\(goal.readingPhrase) · \(chaptersToday) read today"
        }
    }

    // MARK: - Counting

    /// A reader screen has come up — start counting. Also the way the
    /// clock is re-armed when the app returns to the foreground, so it
    /// is idempotent in the clock and counted in the screens.
    func enterReader() {
        rollDayIfNeeded()
        screens += 1
        if sessionStart == nil { sessionStart = Date() }
    }

    /// The reader screen is gone — commit what it counted, once the
    /// last one has actually settled.
    func leaveReader() {
        screens = max(0, screens - 1)
        // Deferred by one turn of the run loop, for the same reason
        // `LibraryListeningSession.leaveScreen` defers: the count is
        // only believed once a push or a cancelled swipe has settled.
        Task { @MainActor [weak self] in
            guard let self, screens == 0 else { return }
            pause()
        }
    }

    /// The app is in front of the reader again. Re-arms the clock that
    /// `pause` stopped, without touching the screen count — the reader
    /// screen never went away, only the foreground did.
    func resume() {
        rollDayIfNeeded()
        guard screens > 0, sessionStart == nil else { return }
        sessionStart = Date()
    }

    /// Commits the reading under way and stops the clock — called when
    /// the app leaves the foreground, so time spent with the phone in a
    /// pocket is never counted as reading. `resume` re-arms it.
    func pause() {
        rollDayIfNeeded()
        guard let start = sessionStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 0 { storedSeconds += elapsed }
        sessionStart = nil
        persist()
    }

    /// A chapter was read to its end — the chapter measure's own count.
    func noteChapterFinished() {
        rollDayIfNeeded()
        storedChapters += 1
        persist()
    }

    // MARK: - Plumbing

    /// Today's figures belong to today. Yesterday's are let go without
    /// comment — the measure starts each morning at nothing owed.
    ///
    /// Called only from the counting paths above, never from a read:
    /// this writes observed state and persists, which during a view's
    /// own update pass is undefined behaviour.
    private func rollDayIfNeeded() {
        let today = Self.todayStamp
        guard dayStamp != today else { return }
        dayStamp = today
        storedSeconds = 0
        storedChapters = 0
        if sessionStart != nil { sessionStart = Date() }
        persist()
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(dayStamp, forKey: Self.dayKey)
        d.set(storedSeconds, forKey: Self.secondsKey)
        d.set(storedChapters, forKey: Self.chaptersKey)
    }
}
