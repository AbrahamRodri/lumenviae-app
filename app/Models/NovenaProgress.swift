//
//  NovenaProgress.swift
//  Lumen Viae
//
//  A novena under way on this phone: which days have been prayed (a set,
//  never a count), the dates its days fall on, the intention and the
//  reminder time. Pure values; `NovenaStore` keeps them.
//
//  The rule (design plan, round 3): Day N belongs to the Nth prayer day
//  from the start, so today's day is fixed by the date. A past day not
//  prayed is open, and may be prayed on any later day without moving the
//  others; days ahead cannot be prayed early. Three or more open days, or
//  a novena past its last date with days open, asks to pick up, begin
//  again or end. Picking up makes today the first open day and runs the
//  rest from today. Days are prayer days (`PrayerDay`), turning at four in
//  the morning.
//

import Foundation

nonisolated struct NovenaProgress: Codable, Equatable, Sendable {
    var novenaID: String
    /// The number of days, copied from the novena when begun
    var length: Int
    /// The days prayed, 1 to `length`
    var prayed: Set<Int> = []
    /// From this day on, the days run one a day from `anchorDate`. It is
    /// day 1 and the start until the novena is picked up again.
    var anchorDay: Int = 1
    /// The prayer day (`PrayerDay.day(of:)`) `anchorDay` falls on
    var anchorDate: Date
    /// What it is prayed for, kept on the phone only; nil when none given
    var intention: String?
    /// The reminder's time of day; nil when no reminder
    var reminder: DateComponents?
    /// Whether the reminder may say the intention; off unless she turns it on
    var remindsWithIntention = false

    /// Where a novena stands on a given day
    enum Standing: Equatable, Sendable {
        /// Every day prayed
        case finished
        /// Under way: today's day (nil when today's is prayed and none is
        /// left today) and the earlier days still open
        case underWay(today: Int?, open: [Int])
        /// Three or more days open, or the last date passed with days open:
        /// the "Welcome back" card, picking up at `firstOpen`
        case welcomeBack(firstOpen: Int)
    }

    init(
        novenaID: String, length: Int, beginning day: Date, intention: String? = nil,
        reminder: DateComponents? = nil, calendar: Calendar = .current
    ) {
        self.novenaID = novenaID
        self.length = length
        self.anchorDate = PrayerDay.day(of: day, calendar: calendar)
        self.intention = intention
        self.reminder = reminder
    }

    /// The prayer day day `number` falls on, for days from the anchor on;
    /// nil for an earlier day, which is always prayed or was before a
    /// pick-up
    func date(ofDay number: Int, calendar: Calendar = .current) -> Date? {
        guard number >= anchorDay, number <= length else { return nil }
        return PrayerDay.adding(days: number - anchorDay, to: anchorDate, calendar: calendar)
    }

    /// The day number `day` (a prayer day) is, which may be below 1 before
    /// the start or past `length` after the last date
    func dayNumber(on day: Date, calendar: Calendar = .current) -> Int {
        let from = calendar.startOfDay(for: anchorDate)
        let to = calendar.startOfDay(for: PrayerDay.day(of: day, calendar: calendar))
        let apart = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        return anchorDay + apart
    }

    var isFinished: Bool { prayed.isSuperset(of: 1...length) }

    func standing(on day: Date, calendar: Calendar = .current) -> Standing {
        if isFinished { return .finished }
        let today = dayNumber(on: day, calendar: calendar)
        let open = (1..<min(max(today, 1), length + 1)).filter { !prayed.contains($0) }
        if let first = open.first, open.count >= 3 || today > length {
            return .welcomeBack(firstOpen: first)
        }
        let todays = (1...length).contains(today) && !prayed.contains(today) ? today : nil
        return .underWay(today: todays, open: open)
    }

    /// Whether day `number` may be prayed on `day`: today's, or an earlier
    /// one still open, never one ahead
    func canPray(_ number: Int, on day: Date, calendar: Calendar = .current) -> Bool {
        guard (1...length).contains(number), !prayed.contains(number) else { return false }
        return number <= dayNumber(on: day, calendar: calendar)
    }

    mutating func markPrayed(_ number: Int) {
        guard (1...length).contains(number) else { return }
        prayed.insert(number)
    }

    /// Today becomes the first open day, and the rest run from today
    mutating func pickUp(on day: Date, calendar: Calendar = .current) {
        guard let first = (1...length).first(where: { !prayed.contains($0) }) else { return }
        anchorDay = first
        anchorDate = PrayerDay.day(of: day, calendar: calendar)
    }

    /// Day 1 is today; the intention and the reminder time are kept
    mutating func beginAgain(on day: Date, calendar: Calendar = .current) {
        prayed = []
        anchorDay = 1
        anchorDate = PrayerDay.day(of: day, calendar: calendar)
    }

    /// The days still to be reminded of, from `day` on, each with its
    /// prayer day: today's if not yet prayed, and every day after it
    func daysToRemind(from day: Date, calendar: Calendar = .current) -> [(day: Int, date: Date)] {
        let first = max(dayNumber(on: day, calendar: calendar), anchorDay, 1)
        guard first <= length else { return [] }
        return (first...length).compactMap { number in
            guard !prayed.contains(number),
                let date = date(ofDay: number, calendar: calendar)
            else { return nil }
            return (number, date)
        }
    }
}

/// A novena finished, kept in a small history with its intention
nonisolated struct FinishedNovena: Codable, Equatable, Sendable {
    var novenaID: String
    var finished: Date
    var intention: String?
}

/// What the Rosary player needs to pray a novena's day: the day laid out
/// for the script, and the words the screen names it by
struct NovenaDayContext {
    var novenaID: String
    /// "Undoer of Knots"
    var shortName: String
    var dayNumber: Int
    var length: Int
    var intention: String?
    var day: SpokenNovenaDay

    /// "Day 4 of 9"
    var dayLine: String {
        String(localized: "Day \(dayNumber) of \(length)", comment: "Novena: which day of how many, like Day 4 of 9")
    }
}

extension NovenaDayContext {
    /// A day of a novena the Prayer Book holds, laid out for the Rosary;
    /// nil when the book has no such novena or day, or the day prays no
    /// Rosary. In a debug build, `debug_knots` is a sample day made only of
    /// texts already public (St Irenaeus, tr. 1885; the Sub tuum), for
    /// trying the day before the server serves the real one.
    static func resolve(novenaID: String, day number: Int, intention: String? = nil) -> NovenaDayContext? {
        guard let novena = novena(novenaID), let day = novena.day(number),
            let laid = SpokenNovenaDay.make(
                from: day,
                book: { id in PrayerBook.prayer(id).map { ($0.title, $0.english) } })
        else { return nil }
        return NovenaDayContext(
            novenaID: novena.id, shortName: novena.listTitle ?? novena.title, dayNumber: number,
            length: novena.length, intention: intention, day: laid)
    }

    /// The novena the Prayer Book holds under `id`
    static func novena(_ id: String) -> PrayerBookDocument.Novena? {
        if let found = LibraryContent.prayerBook.novenas.first(where: { $0.id == id }) { return found }
        #if DEBUG
            if id == "debug_knots" { return debugKnots }
        #endif
        return nil
    }

    #if DEBUG
        static let debugKnots: PrayerBookDocument.Novena = {
            let invocation = PrayerBookDocument.Part(
                kind: "invocation", id: "debug_knots_invocation", text: "Mary, Undoer of Knots, pray for me.")
            let days = (1...9).map { n in
                PrayerBookDocument.Day(
                    number: n, title: "Day \(n)",
                    parts: [
                        .init(kind: "opening", prayerID: "act_of_contrition"),
                        .init(kind: "rosary", decades: [1, 2, 3]),
                        .init(
                            kind: "meditation", id: "debug_knots_meditation",
                            text:
                                "And thus also it was that the knot of Eve's disobedience was loosed by the obedience of Mary. For what the virgin Eve had bound fast through unbelief, this did the virgin Mary set free through faith.",
                            source: "St Irenaeus, Against Heresies III.22.4 (tr. 1885)"),
                        invocation,
                        .init(kind: "rosary", decades: [4, 5]),
                        .init(kind: "closing", prayerID: "sub_tuum"),
                        invocation,
                    ])
            }
            return PrayerBookDocument.Novena(
                id: "debug_knots", title: "Our Lady, Undoer of Knots", listTitle: "Undoer of Knots",
                detail: "", prayerID: "sub_tuum", chapterID: "our_lady", length: 9, days: days)
        }()
    #endif
}
