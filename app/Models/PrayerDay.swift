//
//  PrayerDay.swift
//  Lumen Viae
//
//  The day a prayer belongs to. It turns at four in the morning, not at
//  midnight: Night Prayers and a late Rosary said at half past twelve
//  belong to the evening they close, and the day that follows still asks
//  for its own. One rule for everything prayed — the history, the streak,
//  the Prayer Record, the Chapel's rule, the Pray button's Continue and
//  the Prayer Book's offered — so a Rosary and Night Prayers said
//  together after midnight are never counted on two different days.
//
//  What the Church's calendar decides stays on the calendar day: which
//  mysteries are today's, the Missal's and the Office's dates, the
//  consecration's day numbering, the liturgical seasons and feasts, and
//  the journal's TODAY.
//
//  A prayer day is named by the midnight of its calendar date, so it can
//  sit in a `Set<Date>` beside the calendar's own days and be drawn on a
//  calendar grid: 12:30 AM on a Wednesday is Tuesday's, and Tuesday is
//  named by Tuesday 00:00. The turn is read from the wall clock, so both
//  changes of the clocks leave it at four: the hour that springs forward
//  and the hour that falls back are both before it.
//

import Foundation

nonisolated enum PrayerDay {

    /// The hour the prayer day turns: the Prayer Book's, so there is one
    /// constant for the book's hours and for everything prayed
    static var beginsAtHour: Int { PrayerBook.dayBeginsAtHour }

    /// The present moment the prayer day is read against
    static var now: Date { Date() }

    /// The prayer day an instant belongs to, named by its calendar date's
    /// midnight: before four, the day before
    static func day(of instant: Date, calendar: Calendar = .current) -> Date {
        let midnight = calendar.startOfDay(for: instant)
        guard calendar.component(.hour, from: instant) < beginsAtHour,
              let before = calendar.date(byAdding: .day, value: -1, to: midnight)
        else { return midnight }
        return calendar.startOfDay(for: before)
    }

    /// Today's prayer day
    static func today(now: Date = PrayerDay.now, calendar: Calendar = .current) -> Date {
        day(of: now, calendar: calendar)
    }

    /// Whether a prayer day, named by any instant on its calendar date,
    /// is today's
    static func isToday(_ day: Date, now: Date = PrayerDay.now, calendar: Calendar = .current) -> Bool {
        calendar.isDate(day, inSameDayAs: today(now: now, calendar: calendar))
    }

    /// Whether two instants were prayed on the same prayer day
    static func isSameDay(_ first: Date, _ second: Date, calendar: Calendar = .current) -> Bool {
        day(of: first, calendar: calendar) == day(of: second, calendar: calendar)
    }

    /// The prayer day before or after this one
    static func adding(days: Int, to day: Date, calendar: Calendar = .current) -> Date {
        let midnight = calendar.startOfDay(for: day)
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: days, to: midnight) ?? midnight)
    }

    /// The instants a prayer day holds: from four on its calendar date to
    /// four on the next. Twenty-three hours when the clocks spring forward
    /// within it, twenty-five when they fall back.
    static func interval(of day: Date, calendar: Calendar = .current) -> DateInterval {
        let start = turn(on: day, calendar: calendar)
        let end = turn(on: adding(days: 1, to: day, calendar: calendar), calendar: calendar)
        return DateInterval(start: start, end: max(end, start))
    }

    /// The next moment the prayer day turns after `date`
    static func nextTurn(after date: Date, calendar: Calendar = .current) -> Date {
        let current = day(of: date, calendar: calendar)
        return turn(on: adding(days: 1, to: current, calendar: calendar), calendar: calendar)
    }

    /// Four o'clock on a calendar date. A zone whose clocks jump past four
    /// that night begins the day at the first moment after the gap.
    private static func turn(on day: Date, calendar: Calendar) -> Date {
        let midnight = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: beginsAtHour, minute: 0, second: 0, of: midnight)
            ?? midnight.addingTimeInterval(TimeInterval(beginsAtHour) * 3600)
    }
}
