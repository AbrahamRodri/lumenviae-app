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
                book: { id in PrayerBook.prayer(id).map { ($0.title, $0.english, $0.origin) } })
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
                kind: "invocation", id: "debug_knots_invocation",
                text: String(localized: "Mary, Undoer of Knots, pray for me.", comment: "Undoer of Knots novena: the invocation said after its meditation and its closing prayer (Spanish: María, Desatanudos, Abraham 14 Nov)"))
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
                id: "debug_knots",
                title: String(localized: "Our Lady, Undoer of Knots", comment: "Undoer of Knots novena: its name (Spanish: Novena a la Virgen Desatanudos, Abraham 14 Nov)"),
                listTitle: String(localized: "Undoer of Knots", comment: "Undoer of Knots novena: its short name, under each step and in reminders (Spanish: Desatanudos)"),
                detail: "", prayerID: "sub_tuum", chapterID: "our_lady", length: 9,
                painting: "novena_undoer_of_knots", days: days)
        }()
    #endif
}

// MARK: - NovenaDays

/// A novena's days as its dashes draw them: prayed in gold, the day in
/// hand lit, an open day hollow, the days ahead quiet. Never a count of
/// misses (design plan, rules 2 and 3).
struct NovenaDays: Hashable {
    enum Mark: Hashable { case prayed, here, open, ahead }

    let length: Int
    let prayed: Set<Int>
    /// The day being prayed or shown
    let here: Int
    let open: Set<Int>

    func mark(_ day: Int) -> Mark {
        if prayed.contains(day) { return .prayed }
        if day == here { return .here }
        if open.contains(day) { return .open }
        return .ahead
    }

    /// The day `here` of a novena under way; a novena not begun counts
    /// nothing prayed
    static func of(_ progress: NovenaProgress?, length: Int, here: Int, on date: Date = Date()) -> NovenaDays {
        guard let progress else { return NovenaDays(length: length, prayed: [], here: here, open: []) }
        var open: Set<Int> = []
        switch progress.standing(on: date) {
        case .underWay(_, let days): open = Set(days)
        case .welcomeBack, .finished: break
        }
        return NovenaDays(length: progress.length, prayed: progress.prayed, here: here, open: open.subtracting([here]))
    }

    /// One sentence for VoiceOver, never nine marks: "Days 1 to 3
    /// prayed, day 4 today." / "Days 1 and 2 prayed, day 3 open."
    var spoken: String {
        var parts: [String] = []
        let done = prayed.sorted()
        if !done.isEmpty { parts.append(Self.spokenDays(done, prayed: true)) }
        let openDays = open.sorted()
        if !openDays.isEmpty { parts.append(Self.spokenDays(openDays, prayed: false)) }
        if !prayed.contains(here) {
            parts.append(String(localized: "day \(here) today", comment: "Novena dashes, VoiceOver: the day being prayed, as in Days 1 to 3 prayed, day 4 today"))
        }
        let sentence = parts.joined(separator: ", ")
        return sentence.prefix(1).uppercased() + sentence.dropFirst() + "."
    }

    private static func spokenDays(_ days: [Int], prayed: Bool) -> String {
        let run = days.count > 2 && days.last! - days.first! == days.count - 1
        let list: String
        if days.count == 1 {
            return prayed
                ? String(
                    localized: "novena.dashes.oneDayPrayed", defaultValue: "day \(days[0]) prayed",
                    comment: "Novena dashes, VoiceOver: one day prayed")
                : String(localized: "day \(days[0]) open", comment: "Novena dashes, VoiceOver: one past day not yet prayed")
        } else if run {
            list = String(localized: "\(days.first!) to \(days.last!)", comment: "Novena dashes, VoiceOver: a run of days, as in 1 to 3")
        } else {
            list = days.map(String.init).formatted(.list(type: .and))
        }
        return prayed
            ? String(localized: "days \(list) prayed", comment: "Novena dashes, VoiceOver: days prayed, as in days 1 to 3 prayed")
            : String(localized: "days \(list) open", comment: "Novena dashes, VoiceOver: past days not yet prayed")
    }
}

extension NovenaDayContext {
    /// Go to's title in a novena day: "Day 4 of the Novena"
    var goToTitle: String {
        String(localized: "Day \(dayNumber) of the Novena", comment: "Novena day, Go to sheet: its title")
    }
}

// MARK: - After a Novena Day

extension NovenaProgress {
    /// The line under "Day 4 prayed": when the next day falls and the
    /// mysteries it prays ("Day 5 is tomorrow, with the Glorious
    /// Mysteries."); nil once every day is prayed
    func nextDayLine(after day: Int, now: Date = PrayerDay.now, calendar: Calendar = .current) -> String? {
        guard let next = (1...length).first(where: { $0 > day && !prayed.contains($0) })
            ?? (1...length).first(where: { !prayed.contains($0) }),
            let date = date(ofDay: next, calendar: calendar)
        else { return nil }
        let today = PrayerDay.day(of: now, calendar: calendar)
        let mysteries = ScheduleService.category(for: date, calendar: calendar).devotionTitle
        if date <= today {
            return String(localized: "Day \(next) is open, with the \(mysteries).", comment: "Novena, after a day is prayed: the next day can be prayed now; the second part names its mysteries, like the Glorious Mysteries")
        }
        if PrayerDay.isSameDay(date, PrayerDay.adding(days: 1, to: today, calendar: calendar), calendar: calendar) {
            return String(localized: "Day \(next) is tomorrow, with the \(mysteries).", comment: "Novena, after a day is prayed: when the next day falls and its mysteries, like the Glorious Mysteries")
        }
        let weekday = date.formatted(.dateTime.weekday(.wide))
        return String(localized: "Day \(next) is on \(weekday), with the \(mysteries).", comment: "Novena, after a day is prayed: the weekday the next day falls on and its mysteries")
    }

    /// "Reminder at 8:00 PM." while a reminder is set
    var reminderLine: String? {
        guard let reminder, let time = Calendar.current.date(from: reminder) else { return nil }
        let clock = time.formatted(date: .omitted, time: .shortened)
        // Spanish's time ends on "p.m.", which takes no second period
        return String(localized: "Reminder at \(clock).", comment: "Novena, after a day is prayed: the daily reminder's time")
            .replacingOccurrences(of: "..", with: ".")
    }
}
