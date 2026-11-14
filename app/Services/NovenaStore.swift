//
//  NovenaStore.swift
//  Lumen Viae
//
//  The novenas under way on this phone and the ones finished, kept in
//  UserDefaults, and their reminders: one dated notification for each day
//  still to pray, and one the day after the last date if days are open
//  ("Your novena is still here"), then silence. Nothing leaves the phone.
//
//  The reminders' identifiers all begin "novena.", so the daily
//  reminder's and the Angelus's rescheduling, which remove only their own
//  identifiers, never touch them.
//

import Foundation
import Observation
import UserNotifications

@Observable
final class NovenaStore {
    static let shared = NovenaStore()

    /// Under way, by novena id
    private(set) var progress: [String: NovenaProgress]
    /// Finished, newest first
    private(set) var history: [FinishedNovena]

    /// A reminder tapped: the novena and day it named, for the app to open
    var requested: NovenaRequest?

    @ObservationIgnored private let defaults: UserDefaults
    /// False in tests: nothing is laid on the system's notification center
    @ObservationIgnored private let schedulesNotifications: Bool

    private enum Key {
        static let progress = "novenas.progress"
        static let history = "novenas.history"
    }

    nonisolated static let category = "LUMEN_NOVENA"
    nonisolated static let novenaKey = "novenaID"
    nonisolated static let dayKey = "novenaDay"

    init(defaults: UserDefaults = .standard, schedulesNotifications: Bool = true) {
        self.defaults = defaults
        self.schedulesNotifications = schedulesNotifications
        let decoder = JSONDecoder()
        progress =
            defaults.data(forKey: Key.progress)
            .flatMap { try? decoder.decode([String: NovenaProgress].self, from: $0) } ?? [:]
        history =
            defaults.data(forKey: Key.history)
            .flatMap { try? decoder.decode([FinishedNovena].self, from: $0) } ?? []
    }

    // MARK: - Changing a novena

    func begin(
        _ novena: PrayerBookDocument.Novena, on day: Date = PrayerDay.now, intention: String? = nil,
        reminder: DateComponents? = nil
    ) {
        let trimmed = intention?.trimmingCharacters(in: .whitespacesAndNewlines)
        progress[novena.id] = NovenaProgress(
            novenaID: novena.id, length: novena.length, beginning: day,
            intention: trimmed?.isEmpty == false ? trimmed : nil, reminder: reminder)
        save()
        reschedule(novena, now: day)
    }

    /// Marks a day prayed (the AMEN on its last step). The last day
    /// finishes the novena: it moves to the history, and finished stays
    /// finished.
    func markPrayed(_ number: Int, of novena: PrayerBookDocument.Novena, now: Date = PrayerDay.now) {
        guard var p = progress[novena.id] else { return }
        p.markPrayed(number)
        if p.isFinished {
            progress[novena.id] = nil
            history.insert(FinishedNovena(novenaID: novena.id, finished: now, intention: p.intention), at: 0)
        } else {
            progress[novena.id] = p
        }
        save()
        reschedule(novena, now: now)
    }

    func pickUp(_ novena: PrayerBookDocument.Novena, now: Date = PrayerDay.now) {
        change(novena, now: now) { $0.pickUp(on: now) }
    }

    func beginAgain(_ novena: PrayerBookDocument.Novena, now: Date = PrayerDay.now) {
        change(novena, now: now) { $0.beginAgain(on: now) }
    }

    func setReminder(
        _ reminder: DateComponents?, showingIntention: Bool, for novena: PrayerBookDocument.Novena,
        now: Date = PrayerDay.now
    ) {
        change(novena, now: now) {
            $0.reminder = reminder
            $0.remindsWithIntention = showingIntention
        }
    }

    func setIntention(_ intention: String?, for novena: PrayerBookDocument.Novena) {
        let trimmed = intention?.trimmingCharacters(in: .whitespacesAndNewlines)
        change(novena, now: PrayerDay.now) { $0.intention = trimmed?.isEmpty == false ? trimmed : nil }
    }

    /// Ends a novena not finished: it is let go, with its reminders, and
    /// not kept in the history
    func end(_ novenaID: String) {
        progress[novenaID] = nil
        save()
        removeReminders(of: novenaID)
    }

    private func change(
        _ novena: PrayerBookDocument.Novena, now: Date, _ body: (inout NovenaProgress) -> Void
    ) {
        guard var p = progress[novena.id] else { return }
        body(&p)
        progress[novena.id] = p
        save()
        reschedule(novena, now: now)
    }

    private func save() {
        let encoder = JSONEncoder()
        defaults.set(try? encoder.encode(progress), forKey: Key.progress)
        defaults.set(try? encoder.encode(history), forKey: Key.history)
    }

    // MARK: - Reminders

    /// One reminder to be laid: when, and what it says
    struct Reminder: Equatable {
        var identifier: String
        var fire: DateComponents
        var title: String
        var body: String
        var day: Int?
    }

    /// What the reminders of a novena under way are, from `now` on: a pure
    /// list, so the words and dates can be tested without the system
    static func reminders(
        for p: NovenaProgress, novena: PrayerBookDocument.Novena, now: Date, calendar: Calendar = .current
    ) -> [Reminder] {
        guard let time = p.reminder, !p.isFinished else { return [] }
        func fire(on day: Date) -> DateComponents? {
            var c = calendar.dateComponents([.year, .month, .day], from: day)
            c.hour = time.hour
            c.minute = time.minute
            guard let at = calendar.date(from: c), at > now else { return nil }
            return c
        }
        let name = novena.listTitle ?? novena.title
        var list: [Reminder] = p.daysToRemind(from: now, calendar: calendar).compactMap { entry in
            guard let at = fire(on: entry.date) else { return nil }
            let body: String
            if p.remindsWithIntention, let intention = p.intention {
                body = String(intention.prefix(75))
            } else {
                body = dayLine(entry.day, of: p.length, novenaID: novena.id)
            }
            return Reminder(
                identifier: "novena.\(novena.id).\(entry.day)", fire: at,
                title: String(
                    localized: "Day \(entry.day) of \(p.length) · \(name)",
                    comment: "Novena reminder title: the day, the novena's length and its short name"),
                body: body, day: entry.day)
        }
        // The day after the last date, if days are still open then
        if let last = p.date(ofDay: p.length, calendar: calendar),
            let at = fire(on: PrayerDay.adding(days: 1, to: last, calendar: calendar))
        {
            list.append(
                Reminder(
                    identifier: "novena.\(novena.id).after", fire: at,
                    title: String(
                        localized: "novena.reminder.stillHere.title", defaultValue: "Your novena is still here",
                        comment: "Novena reminder the day after its last date, when days are open"),
                    body: String(
                        localized: "novena.reminder.stillHere.body",
                        defaultValue: "Pick it up where you left off, whenever you like.",
                        comment: "Novena reminder the day after its last date: its text"),
                    day: nil))
        }
        return list
    }

    /// The day's own line. Days 4 and 6 name knots, so they are the Undoer
    /// of Knots novena's own; any other novena hears day 2's on those days.
    static func dayLine(_ day: Int, of length: Int, novenaID: String) -> String {
        let knots = novenaID == "undoer_of_knots"
        if day == length {
            return String(
                localized: "novena.reminder.last", defaultValue: "Today is the last day of your novena.",
                comment: "Novena reminder on its last day")
        }
        switch day {
        case 1:
            return String(
                localized: "novena.reminder.day1", defaultValue: "Your novena begins today. Come when you are ready.",
                comment: "Novena reminder, day 1")
        case 3:
            return String(
                localized: "novena.reminder.day3", defaultValue: "A quiet moment with Our Lady.",
                comment: "Novena reminder, day 3")
        case 4 where knots:
            return String(
                localized: "novena.reminder.day4.knots", defaultValue: "Bring her the knot you carry today.",
                comment: "Undoer of Knots novena reminder, day 4")
        case 5 where length == 9:
            return String(
                localized: "novena.reminder.day5", defaultValue: "The middle day. Today's prayer is ready.",
                comment: "Novena reminder, day 5 of 9")
        case 6 where knots:
            return String(
                localized: "novena.reminder.day6.knots", defaultValue: "Bring Mary what you cannot untie.",
                comment: "Undoer of Knots novena reminder, day 6")
        case 7:
            return String(
                localized: "novena.reminder.day7", defaultValue: "Come as you are. Day 7 is here.",
                comment: "Novena reminder, day 7")
        case length - 1:
            return String(
                localized: "novena.reminder.nextToLast", defaultValue: "One more day after this one.",
                comment: "Novena reminder on the day before its last")
        default:
            return String(
                localized: "novena.reminder.day2", defaultValue: "Today's prayer is here for you.",
                comment: "Novena reminder, day 2 and any day without a line of its own")
        }
    }

    /// Lays a novena's reminders again from `now`: its old ones removed,
    /// none for a novena finished, ended or without a reminder time
    func reschedule(_ novena: PrayerBookDocument.Novena, now: Date = PrayerDay.now) {
        guard schedulesNotifications else { return }
        let list = progress[novena.id].map { Self.reminders(for: $0, novena: novena, now: now) } ?? []
        let id = novena.id
        Task {
            let center = UNUserNotificationCenter.current()
            await Self.removeReminders(of: id, from: center)
            for reminder in list {
                let content = UNMutableNotificationContent()
                content.title = reminder.title
                content.body = reminder.body
                content.sound = .default
                content.categoryIdentifier = Self.category
                content.userInfo = [Self.novenaKey: id, Self.dayKey: reminder.day ?? 0]
                let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.fire, repeats: false)
                try? await center.add(
                    UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
            }
        }
    }

    private func removeReminders(of novenaID: String) {
        guard schedulesNotifications else { return }
        Task { await Self.removeReminders(of: novenaID, from: UNUserNotificationCenter.current()) }
    }

    private static func removeReminders(of novenaID: String, from center: UNUserNotificationCenter) async {
        let prefix = "novena.\(novenaID)."
        let ids = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

/// A novena reminder's tap: which novena, and which day (0 for the one
/// the day after the last date)
struct NovenaRequest: Equatable {
    var novenaID: String
    var day: Int
}
