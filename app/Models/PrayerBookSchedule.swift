//
//  PrayerBookSchedule.swift
//  Lumen Viae
//
//  The Prayer Book's hours and seasons: which of the day's three orders
//  the hour belongs to, when it turns, which Angelus bell is kept, and
//  the season's song to Mary.
//

import Foundation

extension PrayerBook {

    /// The hour the book's day begins. Morning Prayers are said from
    /// four, and Night Prayers said after midnight belong to the night
    /// before, not to the day they spill into.
    nonisolated static let dayBeginsAtHour = 4

    /// Which of the day's three orders the hour belongs to: the morning
    /// until eleven, the Angelus through the noon and evening bells
    /// until eight, and night after that.
    static func dayOrder(at date: Date = Date(), calendar: Calendar = .current) -> PrayerOrder {
        let hour = calendar.component(.hour, from: date)
        let id: String
        switch hour {
        case dayBeginsAtHour..<11:  id = morningOrderID
        case 11..<20: id = angelusOrderID
        default:      id = nightOrderID
        }
        return order(id)!
    }

    /// When the hour's order is said, in the words every surface that
    /// names it shares — the Prayers page's strip, home's hour row and
    /// the Chapel's Prayers tile: "On waking", "At noon", "At 6 PM", "At
    /// bedtime"
    nonisolated static func dayOrderMoment(
        at date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case dayBeginsAtHour..<11:  return "On waking"
        case 11..<15: return "At noon"
        case 15..<20: return "At 6 PM"
        default:      return "At bedtime"
        }
    }

    /// The next moment the book's hour turns — the order for the hour, or
    /// the moment it names, giving way: four, eleven, three and eight
    /// o'clock. Read off `dayOrderMoment` itself, whose turns include
    /// `dayOrder`'s and the book's day's, so the three can never disagree.
    /// None of them is an hour of the Office, so `CanonicalClock` sleeps
    /// through every one.
    nonisolated static func nextTurn(after date: Date, calendar: Calendar = .current) -> Date {
        let moment = dayOrderMoment(at: date, calendar: calendar)
        var hour = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        for _ in 0..<24 {
            guard let next = calendar.date(byAdding: .hour, value: 1, to: hour) else { break }
            hour = next
            if dayOrderMoment(at: hour, calendar: calendar) != moment { return hour }
        }
        return date.addingTimeInterval(3600)
    }

    // MARK: The day's three hours, in plain words

    /// What the Prayers page calls one of the day's three orders on its
    /// strip of hours: MORNING, NOON, EVENING, NIGHT. The middle station is
    /// the Angelus at noon and at 6 PM, named for the bell being kept
    /// (`angelusBellKept`), which is also the bell its PRAYED reads:
    /// NOON until three, the noon bell still to come before eleven, and
    /// EVENING from three until the day turns at four. The six o'clock
    /// morning bell has no station of its own, since MORNING is Morning
    /// Prayers', so the strip never says NOON at five, nor NOON offered
    /// for an Angelus said at the evening bell. (`offered` names the
    /// state in code; the reader sees PRAYED.)
    static func hourName(of order: PrayerOrder, at date: Date = Date(), calendar: Calendar = .current) -> String {
        switch order.id {
        case morningOrderID: return "Morning"
        case nightOrderID:   return "Night"
        default:             return angelusBellKept(at: date, calendar: calendar).name
        }
    }

    /// Where one of the day's orders stands at `date`: prayed today (the
    /// reader sees "Prayed"), the hour it is now, or when it is said, in
    /// `dayOrderMoment`'s words. Never "missed" — a morning not prayed by
    /// night still reads "On waking".
    enum HourStanding: Equatable {
        case offered
        case now
        case at(String)
    }

    static func standing(
        of order: PrayerOrder,
        at date: Date = Date(),
        offered: Bool,
        calendar: Calendar = .current
    ) -> HourStanding {
        if offered { return .offered }
        if dayOrder(at: date, calendar: calendar).id == order.id { return .now }
        switch order.id {
        case morningOrderID: return .at("On waking")
        case nightOrderID:   return .at("At bedtime")
        default:
            return .at(angelusBellKept(at: date, calendar: calendar) == .evening ? "At 6 PM" : "At noon")
        }
    }

    /// The two Angelus bells the Prayers page's strip keeps: noon's and the
    /// evening's. The bell at six in the morning has no station of its
    /// own; an Angelus said then counts for the day (`wasOffered`), which
    /// is the rule's measure, but not for the noon bell still to come.
    enum AngelusBell: Equatable {
        case noon
        case evening

        /// The bell's name on the strip
        var name: String {
            switch self {
            case .noon:    return "Noon"
            case .evening: return "Evening"
            }
        }

        /// The clock hour from which an Angelus said counts for the bell
        var keptFromHour: Int {
            switch self {
            case .noon:    return 11
            case .evening: return 15
            }
        }
    }

    /// The Angelus bell being kept at `date`: noon's from the day's turn at
    /// four, still to come before eleven, and the evening's from three on
    /// past midnight, until the day turns again
    static func angelusBellKept(at date: Date = Date(), calendar: Calendar = .current) -> AngelusBell {
        let hour = calendar.component(.hour, from: date)
        return hour < dayBeginsAtHour || hour >= AngelusBell.evening.keptFromHour ? .evening : .noon
    }

    /// From when an Angelus said counts for the bell being kept: noon's
    /// from eleven, the evening's from three, and after midnight still the
    /// evening before's, as the prayer day keeps it. Before eleven it is
    /// noon's eleven o'clock, still ahead, so nothing yet offers it: an
    /// Angelus said at six in the morning leaves PRAY THE ANGELUS, not
    /// AGAIN. One prayed at noon is the noon bell's; by evening the evening
    /// bell asks for its own. The rule of prayer still counts the Angelus
    /// once a day (`wasOffered`); only the Prayers page's strip keeps the
    /// bells apart.
    static func angelusBellBegan(at date: Date = Date(), calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        let today = calendar.startOfDay(for: date)
        let day = hour < dayBeginsAtHour
            ? calendar.date(byAdding: .day, value: -1, to: today) ?? today
            : today
        let bell = angelusBellKept(at: date, calendar: calendar)
        return calendar.date(bySettingHour: bell.keptFromHour, minute: 0, second: 0, of: day) ?? day
    }

    /// Whether `order` is offered for the hour it is now: the day's offering
    /// for most, and the bell's for the Angelus
    static func isOfferedNow(
        _ order: PrayerOrder,
        at date: Date = Date(),
        offeredToday: Bool,
        lastOffered: Date?,
        calendar: Calendar = .current
    ) -> Bool {
        guard offeredToday else { return false }
        guard order.id == angelusOrderID else { return true }
        guard let lastOffered else { return false }
        return lastOffered >= angelusBellBegan(at: date, calendar: calendar) && lastOffered <= date
    }

    /// One short plain line saying what one of the day's three orders
    /// is, as the Prayers page's card and home's hour row set it under
    /// the order's name. Any other order is its own detail.
    static func daySummary(of order: PrayerOrder, on date: Date = Date()) -> String {
        switch order.id {
        case morningOrderID:
            return "Giving the day to God."
        case angelusOrderID:
            return isEastertide(date)
                ? "The Easter prayer to Mary, said in place of the Angelus."
                : "A short prayer to Mary at 6 AM, noon and 6 PM."
        case nightOrderID:
            return "A look back on the day, ending with a song to Mary."
        default:
            return order.detail
        }
    }

    // MARK: Seasons

    /// Easter Sunday to the Saturday after Pentecost: Queen of Heaven
    /// (the Regina Cæli) stands in the Angelus's place
    static func isEastertide(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)
        guard let easter = ScheduleService.easterSunday(year: year, calendar: calendar),
              let trinity = calendar.date(byAdding: .day, value: 56, to: easter)
        else { return false }
        return day >= easter && day < trinity
    }

    /// The song to Mary the Church sings at Bedtime Prayer on `date`
    static func antiphon(on date: Date, calendar: Calendar = .current) -> MarianAntiphon {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)

        if let advent = ScheduleService.adventStart(year: year, calendar: calendar),
           let eve = calendar.date(byAdding: .day, value: -1, to: advent),
           day >= eve {
            return .almaRedemptoris
        }
        guard let purification = calendar.date(from: DateComponents(year: year, month: 2, day: 2)),
              let easter = ScheduleService.easterSunday(year: year, calendar: calendar),
              let trinityEve = calendar.date(byAdding: .day, value: 55, to: easter)
        else { return .salveRegina }

        if day < purification { return .almaRedemptoris }
        if day < easter { return .aveReginaCaelorum }
        if day < trinityEve { return .reginaCaeli }
        return .salveRegina
    }
}
