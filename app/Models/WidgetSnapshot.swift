//
//  WidgetSnapshot.swift
//  Lumen Viae
//
//  Everything the Home Screen, Lock Screen and StandBy widgets show. The
//  app writes it into the App Group's container whenever it may have
//  changed (`WidgetSnapshotStore`), with every word already in the app's
//  language and every painting the widgets hang copied small beside it;
//  the widgets read only this, and fetch and compute nothing of their
//  own beyond choosing the day and the hour by the clock. So the widget
//  extension needs no string catalog, follows the app's language, and
//  cannot disagree with the app about a novena's day or the week's
//  mysteries.
//
//  Shared with the widget extension: plain values only. Building one
//  from the app's state is `WidgetSnapshot+App.swift`, in the app alone.
//

import Foundation

nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {

    /// The App Group both the app and the widget extension read
    static let appGroupID = "group.com.lumenviae.app"

    /// The snapshot's file in the App Group's container
    static let fileName = "widget-snapshot.json"

    /// The folder in the container holding the paintings the snapshot
    /// names, each `<name>.jpg`, small enough for a widget
    static let paintingsFolder = "paintings"

    /// Raised when a field changes meaning, so a widget can tell an older
    /// snapshot from a newer one
    static let currentVersion = 2

    var version = WidgetSnapshot.currentVersion

    /// The words every widget shares, in the app's language
    var labels: Labels

    /// Today and the days after it, each by its calendar date; the widget
    /// shows the one the clock is on, so a phone left a few days keeps
    /// the right mysteries without the app being opened
    var days: [Day]

    /// The eight hours of the Office, in the order of the day
    var hours: [Hour]

    /// The Rosary left off, where it stopped; nil when none is. Shown only
    /// on the prayer day it was left (`prayerDay`)
    var rosary: Rosary?

    // MARK: Parts

    struct Labels: Codable, Equatable, Sendable {
        var continueWord: String
        var begin: String
        var todaysRosary: String
        var novena: String
        var aWordForToday: String
        var currentStreak: String
        var now: String
        var hoursOfPrayer: String
        var consecration: String
        /// Where nothing is under way: "Your Novenas" over "Begin a novena"
        var yourNovenas: String
        var beginANovena: String
        /// Before the app has the day's propers: "Today's Mass" over
        /// "Prayers and readings for today"
        var todaysMass: String
        var massFallbackLine: String
        /// Where no consecration is chosen: "Consecration to Mary" over
        /// what it is; once made, "Consecrated"
        var consecrationTitle: String
        var consecrationInvite: String
        var consecrated: String
        /// The Angelus's three bells, in the order 6, 12, 18
        var angelusTimes: [String]
        /// "Morning", "Noon", "Evening"
        var angelusHourNames: [String]
        /// "It is noon", said through the hour of each bell
        var angelusAtTheHour: [String]
        /// Sunday first, one letter each: "S M T W T F S"
        var weekInitials: [String]
    }

    struct Day: Codable, Equatable, Sendable {
        /// "2026-11-16", the calendar day
        var date: String
        /// "Today · Monday"
        var todayLine: String
        /// "Monday · 16 November"
        var dateLine: String
        /// "Monday, 16 November", for the Lock Screen
        var dateLineFull: String
        var mysteries: Mysteries
        var quote: String
        var quoteAuthor: String
        var angelus: Angelus
        /// The day's feast as the Mass names it, when the app has the
        /// day's propers on the phone
        var liturgicalDay: LiturgicalDay?
        /// The novenas under way as this day's prayer day finds them, the
        /// one with a day still to pray first
        var novenas: [Novena]
        var record: Record
        /// The consecration under way or chosen ahead, as this day finds it
        var consecration: Consecration?
    }

    struct Mysteries: Codable, Equatable, Sendable {
        /// `MysteryCategory` raw value
        var category: String
        /// "Joyful Mysteries"
        var title: String
        /// "Joyful"
        var shortTitle: String
        /// The five (seven) mysteries' names
        var names: [String]
        /// Their paintings, by name
        var paintings: [String]
        /// "First, the Annunciation"
        var firstLine: String
    }

    struct Angelus: Codable, Equatable, Sendable {
        /// "The Angelus", or "Queen of Heaven" in the Easter season
        var title: String
        /// "Angelus", for the Lock Screen's circle
        var shortName: String
        var firstLine: String
        /// "Pray the Angelus"
        var prayLine: String
        /// "Angelus at 6 AM", "at noon", "at 6 PM": one for each bell
        var atLines: [String]
    }

    struct Hour: Codable, Equatable, Sendable {
        /// The clock hour it begins at
        var beginsAt: Int
        /// "Evening Prayer"
        var name: String
        /// "Vespers"
        var churchName: String
        var painting: String
        var firstLine: String
    }

    struct Rosary: Codable, Equatable, Sendable {
        /// `MysteryCategory` raw value ("sorrowful", "seven_sorrows")
        var category: String
        /// "meditation_set", "scriptural_rosary" or "rosary_aloud"
        var form: String
        /// The meditation set's name; empty for the other forms
        var setName: String
        /// 0-based: the mystery the hand was on
        var mysteryIndex: Int
        /// 0-based: the bead of that decade, 0 the Our Father; nil when
        /// the snapshot kept none
        var beadIndex: Int?
        var savedAt: Date
        /// "2026-11-16": the prayer day it was left on
        var prayerDay: String
        /// "Sorrowful Mysteries"
        var title: String
        /// "Sorrowful"
        var shortTitle: String
        /// "Jesus Carries the Cross"
        var mysteryName: String
        var painting: String
        /// "4th mystery"
        var placeLine: String
        /// "Hail Mary 6 of 10", or the prayer under the hand
        var beadLine: String
        /// The Hail Marys of a decade: 10, or 7 in the chaplet
        var hailMarys: Int
    }

    struct Novena: Codable, Equatable, Sendable {
        var id: String
        var name: String
        var painting: String?
        var length: Int
        /// The days prayed, 1 to `length`
        var prayedDays: [Int]
        /// Today's day while it is still to pray; nil once prayed, or when
        /// the novena waits to be picked up again
        var todaysDay: Int?
        /// The day the dashes stand on: today's, else the first open one
        var currentDay: Int
        var prayedToday: Bool
        /// "Day 4 of 9"
        var dayLine: String
        /// "Not yet prayed today" or "Prayed today"
        var statusLine: String
    }

    struct Record: Codable, Equatable, Sendable {
        /// Days in a row, as the Prayer Record counts them
        var daysInARow: Int
        var prayedToday: Bool
        /// "12 days in a row", "1 day so far", "Pray today to begin"
        var line: String
        /// Sunday to Saturday of this week: whether a Rosary was prayed
        var week: [Bool]
        /// Today's place in `week`
        var todayInWeek: Int
    }

    struct Consecration: Codable, Equatable, Sendable {
        /// False while it is chosen ahead and Day 1 has not come
        var hasBegun: Bool
        /// 1 to 34; 34 is the day of consecration
        var dayNumber: Int
        /// "Day 12 of 33", or the day of consecration
        var dayLine: String
        /// The day's title ("Humble Subjection")
        var dayTitle: String
        var painting: String
        var todayPrayed: Bool
        var isCompleted: Bool
        /// While it waits: "Begins 31 December"
        var beginsLine: String
        /// While it waits: "For the feast of 2 February"
        var feastLine: String
    }

    struct LiturgicalDay: Codable, Equatable, Sendable {
        var title: String
        /// "Lesser Feast", in the app's words
        var rank: String?
        /// "White"
        var colourName: String?
        /// The vestment's swatch, "#EDE7D6"
        var colourHex: String?
        var painting: String
    }
}

// MARK: - Reading

extension WidgetSnapshot {

    /// "2026-11-16" for the calendar day `date` falls on
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// The prayer day `date` belongs to, as a key: the day turns at four
    /// in the morning, as the app counts what was prayed
    static func prayerDayKey(_ date: Date, calendar: Calendar = .current) -> String {
        dayKey(date.addingTimeInterval(-4 * 3600), calendar: calendar)
    }

    /// The day the clock is on, or the last one kept when the app has not
    /// been opened for longer than the snapshot runs
    func day(at date: Date, calendar: Calendar = .current) -> Day? {
        let key = Self.dayKey(date, calendar: calendar)
        return days.first { $0.date == key } ?? days.last { $0.date < key } ?? days.first
    }

    /// The day whose prayers count now: before four in the morning, the
    /// evening before's
    func prayerDay(at date: Date, calendar: Calendar = .current) -> Day? {
        day(at: date.addingTimeInterval(-4 * 3600), calendar: calendar)
    }

    /// The Rosary left off, while its prayer day is still the one now
    func rosaryLeftOff(at date: Date, calendar: Calendar = .current) -> Rosary? {
        guard let rosary, rosary.prayerDay == Self.prayerDayKey(date, calendar: calendar) else { return nil }
        return rosary
    }

    /// The hour of the Office the clock is in
    func hour(at date: Date, calendar: Calendar = .current) -> Hour? {
        let clock = calendar.component(.hour, from: date)
        return hours.last { $0.beginsAt <= clock } ?? hours.last
    }

    /// Every painting the snapshot names, for copying beside it
    var paintingNames: Set<String> {
        var names = Set(hours.map(\.painting))
        if let rosary { names.insert(rosary.painting) }
        for day in days {
            names.formUnion(day.mysteries.paintings)
            if let painting = day.liturgicalDay?.painting { names.insert(painting) }
            names.formUnion(day.novenas.compactMap(\.painting))
            if let painting = day.consecration?.painting { names.insert(painting) }
        }
        names.insert(WidgetSnapshot.wordForTodayPainting)
        return names.filter { !$0.isEmpty }
    }

    /// The painting over A Word for Today at its largest
    static let wordForTodayPainting = "feast_our_lady_of_the_rosary"
}
