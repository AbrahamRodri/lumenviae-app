//
//  WidgetSnapshot+App.swift
//  Lumen Viae
//
//  Building the widgets' snapshot from the app's state, every word in the
//  app's language. In the app only: the widget extension reads
//  `WidgetSnapshot` and never builds one.
//

import Foundation

extension WidgetSnapshot {

    /// How many days the snapshot runs, today first: a phone left that
    /// long without opening the app still shows the right mysteries
    static let daysKept = 8

    /// What the snapshot needs to know of a novena besides its progress
    struct NovenaInfo {
        var name: String
        var painting: String?
    }

    /// The snapshot from the app's state, pure but for the bundled words
    /// it reads, so a test can build one
    @MainActor
    static func make(
        resume: InProgressPrayer?,
        novenas: [String: NovenaProgress],
        novenaInfo: (String) -> NovenaInfo?,
        prayerDays: Set<Date>,
        consecration: ConsecrationProgress?,
        liturgicalDay: (String) -> LiturgicalDay?,
        spanish: Bool = SpanishContent.isActive,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WidgetSnapshot {
        let days = (0..<daysKept).compactMap { offset -> Day? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            // Noon of each day: its calendar day and its prayer day agree
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let at = offset == 0 ? now : noon
            return day(
                at: at, novenas: novenas, novenaInfo: novenaInfo, prayerDays: prayerDays,
                consecration: consecration, liturgicalDay: liturgicalDay(dayKey(at, calendar: calendar)),
                spanish: spanish, calendar: calendar)
        }
        return WidgetSnapshot(
            labels: labels(calendar: calendar),
            days: days,
            hours: CanonicalHour.allCases.map(hour(_:)),
            rosary: resume.flatMap { rosaryState(of: $0, calendar: calendar) }
        )
    }

    // MARK: - A day

    @MainActor
    private static func day(
        at date: Date,
        novenas: [String: NovenaProgress],
        novenaInfo: (String) -> NovenaInfo?,
        prayerDays: Set<Date>,
        consecration: ConsecrationProgress?,
        liturgicalDay: LiturgicalDay?,
        spanish: Bool,
        calendar: Calendar
    ) -> Day {
        let category = ScheduleService.category(for: date)
        let quote = RosaryQuotes.quote(spanish: spanish, on: date)
        let weekday = weekdayName(of: date)
        return Day(
            date: dayKey(date, calendar: calendar),
            todayLine: String(
                localized: "Today · \(weekday)",
                comment: "Widgets: the kicker over today's mysteries, Today and the weekday, like Today · Monday"),
            dateLine: "\(weekday) · \(dayAndMonth(of: date))",
            dateLineFull: fullDateFormatter.string(from: date),
            mysteries: mysteries(of: category),
            quote: quote.text,
            quoteAuthor: quote.author,
            angelus: angelus(on: date),
            liturgicalDay: liturgicalDay,
            novenas: novenaStates(novenas, info: novenaInfo, at: date, calendar: calendar),
            record: record(prayerDays: prayerDays, at: date, calendar: calendar),
            consecration: consecration.map { consecrationState($0, at: date, calendar: calendar) }
        )
    }

    @MainActor
    private static func mysteries(of category: MysteryCategory) -> Mysteries {
        let all = MysteryData.mysteries(for: category)
        let first = all.first?.name ?? ""
        return Mysteries(
            category: category.rawValue,
            title: category.devotionTitle,
            shortTitle: category.displayName,
            names: all.map(\.name),
            paintings: all.indices.compactMap { Constants.mysteryImageURL(category: category.rawValue, index: $0) },
            firstLine: String(
                localized: "First, \(lowercasingFirstLetter(first))",
                comment: "Widgets, Today's Mysteries: the first mystery to be prayed, its article in lower case, like First, the Annunciation")
        )
    }

    @MainActor
    private static func angelus(on date: Date) -> Angelus {
        let order = PrayerBook.order(PrayerBook.angelusOrderID)
        let eastertide = PrayerBook.isEastertide(date)
        let firstWords = order?.prayers(on: date).first.map { firstLine(of: $0.english) } ?? ""
        let shortName = eastertide
            ? String(localized: "Regina Cæli", comment: "Widgets, the Angelus on the Lock Screen: the Easter season's song, the Regina Caeli, in a small circle; keep the Latin")
            : String(localized: "Angelus", comment: "Widgets, the Angelus on the Lock Screen: its short name, in a small circle and in Angelus at 12:00")
        return Angelus(
            title: order?.title(on: date) ?? String(localized: "The Angelus"),
            shortName: shortName,
            firstLine: firstWords,
            prayLine: eastertide
                ? String(localized: "Pray the Queen of Heaven", comment: "Widgets, the Angelus at its hour in the Easter season: the invitation, when the Regina Caeli is said in its place")
                : String(localized: "Pray the Angelus", comment: "Widgets, the Angelus at its hour: the invitation"),
            // Each bell said as the app says it, so the morning's and the
            // evening's 6 are told apart on a line with no word beneath
            atLines: [
                String(localized: "\(shortName) at 6 AM", comment: "Widgets, the Angelus on the Lock Screen's line above the clock: the morning bell"),
                String(localized: "\(shortName) at noon", comment: "Widgets, the Angelus on the Lock Screen's line above the clock: the noon bell"),
                String(localized: "\(shortName) at 6 PM", comment: "Widgets, the Angelus on the Lock Screen's line above the clock: the evening bell"),
            ]
        )
    }

    /// The first line of a prayer's words, without its ℣ or ℟
    static func firstLine(of text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        var trimmed = line
        for mark in ["℣.", "℟.", "℣", "℟"] where trimmed.hasPrefix(mark) {
            trimmed = String(trimmed.dropFirst(mark.count))
            break
        }
        return trimmed.replacingOccurrences(of: "|||", with: "").trimmingCharacters(in: .whitespaces)
    }

    @MainActor
    private static func hour(_ hour: CanonicalHour) -> Hour {
        Hour(
            beginsAt: hour.beginsAtClockHour,
            name: hour.plainName,
            churchName: hour.label,
            painting: PrayerBookPainting.office(hour).resolvedAsset,
            firstLine: String(
                localized: "O God, come to my assistance.",
                comment: "Widgets, Hours of Prayer: the first words of every hour of the Divine Office (Deus in adjutorium), in the breviary's English")
        )
    }

    // MARK: - The Rosary left off

    @MainActor
    private static func rosaryState(of prayer: InProgressPrayer, calendar: Calendar) -> Rosary? {
        guard let category = MysteryCategory(fromAPIString: prayer.category) else { return nil }
        let kind = prayer.kind ?? .meditationSet
        let mysteries = MysteryData.mysteries(for: category)
        let index = max(0, min(prayer.mysteryIndex, mysteries.count - 1))
        let chaplet = category == .sevenSorrows
        let ordinal = ordinalFormatter.string(from: NSNumber(value: index + 1)) ?? "\(index + 1)"
        return Rosary(
            category: prayer.category,
            form: kind.rawValue,
            setName: kind == .meditationSet ? prayer.setName : "",
            mysteryIndex: prayer.mysteryIndex,
            beadIndex: prayer.beadIndex,
            savedAt: prayer.savedAt,
            prayerDay: prayerDayKey(prayer.savedAt, calendar: calendar),
            title: category.devotionTitle,
            shortTitle: category.displayName,
            mysteryName: mysteries.indices.contains(index) ? mysteries[index].name : "",
            painting: Constants.mysteryImageURL(category: category.rawValue, index: index) ?? "",
            placeLine: chaplet
                ? String(localized: "\(ordinal) sorrow", comment: "Widgets, Continue Your Rosary: which sorrow of the chaplet the hand is on, its number as an ordinal figure, like 4th sorrow")
                : String(localized: "\(ordinal) mystery", comment: "Widgets, Continue Your Rosary: which mystery the hand is on, its number as an ordinal figure, like 4th mystery"),
            beadLine: prayer.beadLabel ?? "",
            hailMarys: chaplet ? 7 : 10
        )
    }

    // MARK: - Novenas

    @MainActor
    private static func novenaStates(
        _ novenas: [String: NovenaProgress], info: (String) -> NovenaInfo?, at date: Date, calendar: Calendar
    ) -> [Novena] {
        novenas.values.compactMap { (progress: NovenaProgress) -> Novena? in
            // A novena the Prayer Book no longer holds (the Undoer of Knots,
            // taken off in Nov 2026) is not shown: it stood under its raw id
            // at "Day 4 of 9", and its link opened nothing. Its days are
            // kept, and it comes back if the novena does
            guard let about = info(progress.novenaID) else { return nil }
            let todays: Int?
            let current: Int
            switch progress.standing(on: date, calendar: calendar) {
            case .finished:
                return nil
            case .underWay(let day, let open):
                todays = day
                current = day ?? open.first ?? min(progress.dayNumber(on: date, calendar: calendar), progress.length)
            case .welcomeBack(let firstOpen):
                todays = nil
                current = firstOpen
            }
            let shown = max(1, min(current, progress.length))
            let prayedToday = progress.prayed.contains(progress.dayNumber(on: date, calendar: calendar))
            return Novena(
                id: progress.novenaID,
                name: about.name,
                painting: about.painting,
                length: progress.length,
                prayedDays: progress.prayed.sorted(),
                todaysDay: todays,
                currentDay: shown,
                prayedToday: prayedToday,
                dayLine: String(localized: "Day \(shown) of \(progress.length)", comment: "Novena: which day of how many, like Day 4 of 9"),
                statusLine: prayedToday
                    ? String(localized: "widget.novena.prayedToday", defaultValue: "Prayed today", comment: "Widgets, Novena: today's day of the novena has been prayed")
                    : String(localized: "widget.novena.notYet", defaultValue: "Not yet prayed today", comment: "Widgets, Novena: today's day of the novena is still to pray; never a reproach")
            )
        }
        .sorted { lhs, rhs in
            if (lhs.todaysDay != nil) != (rhs.todaysDay != nil) { return lhs.todaysDay != nil }
            return lhs.id < rhs.id
        }
    }

    // MARK: - The prayer record

    @MainActor
    private static func record(prayerDays: Set<Date>, at date: Date, calendar: Calendar) -> Record {
        let today = PrayerDay.day(of: date, calendar: calendar)
        // Sunday to Saturday, as the Prayer Record's week, whatever the locale
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1
        let weekStart = sundayFirst.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let week = (0..<7).map { PrayerDay.adding(days: $0, to: weekStart, calendar: calendar) }
        let streak = PrayerHistoryService.currentStreak(in: prayerDays, today: today, calendar: calendar)
        return Record(
            daysInARow: streak,
            prayedToday: prayerDays.contains(today),
            line: StreakWidget.figureLine(streak: streak),
            week: week.map { prayerDays.contains($0) },
            todayInWeek: week.firstIndex(of: today) ?? 0
        )
    }

    // MARK: - The consecration

    @MainActor
    private static func consecrationState(_ progress: ConsecrationProgress, at date: Date, calendar: Calendar) -> Consecration {
        let number = max(1, min(progress.daysSinceStart(asOf: date) + 1, 34))
        let feast = calendar.date(byAdding: .day, value: 33, to: progress.startDate) ?? progress.startDate
        return Consecration(
            hasBegun: progress.hasBegun(asOf: date),
            dayNumber: number,
            dayLine: number >= 34
                ? String(localized: "Consecration Day")
                : String(localized: "Day \(number) of 33"),
            dayTitle: ConsecrationData.day(number)?.title ?? "",
            painting: (ConsecrationPhase.phase(for: number) ?? .preparatory).heroImageName,
            todayPrayed: progress.isDayCompleted(number),
            isCompleted: progress.isCompleted,
            // The year where it is not this one, as Home's row says it (#203)
            beginsLine: String(localized: "Begins \(dayAndMonth(of: progress.startDate, seenOn: date, calendar: calendar))"),
            feastLine: String(
                localized: "For the feast of \(dayAndMonth(of: feast, seenOn: date, calendar: calendar))",
                comment: "Widgets, Consecration chosen ahead: the feast its 33 days end on, by its date, like For the feast of 2 February")
        )
    }

    // MARK: - Words every widget shares

    private static func labels(calendar: Calendar) -> Labels {
        Labels(
            continueWord: String(localized: "Continue"),
            begin: String(localized: "Begin"),
            todaysRosary: String(localized: "Today's Rosary"),
            novena: String(localized: "widget.novena", defaultValue: "Novena", comment: "Widgets, Novena: the kicker over the novena's name"),
            aWordForToday: String(localized: "A Word for Today", comment: "Widgets: the title of the daily quotation widget"),
            currentStreak: String(localized: "CURRENT STREAK"),
            now: String(localized: "Now"),
            hoursOfPrayer: String(localized: "Hours of Prayer"),
            consecration: String(localized: "Consecration"),
            yourNovenas: String(localized: "Your Novenas"),
            beginANovena: String(localized: "BEGIN A NOVENA"),
            todaysMass: String(localized: "Today's Mass"),
            massFallbackLine: String(localized: "Prayers and readings for today"),
            consecrationTitle: String(localized: "Consecration to Mary"),
            consecrationInvite: String(localized: "A 33-day preparation to give yourself to Jesus through Mary"),
            consecrated: String(localized: "Consecrated"),
            angelusTimes: angelusTimes,
            angelusHourNames: [
                String(localized: "widget.angelus.morning", defaultValue: "Morning", comment: "Widgets, the Angelus: the 6 AM bell's name, under its time"),
                String(localized: "Noon"),
                String(localized: "widget.angelus.evening", defaultValue: "Evening", comment: "Widgets, the Angelus: the 6 PM bell's name, under its time"),
            ],
            angelusAtTheHour: [
                String(localized: "widget.angelus.atSix", defaultValue: "It is six in the morning", comment: "Widgets, the Angelus through the hour of its 6 AM bell: the kicker over Pray the Angelus"),
                String(localized: "widget.angelus.atNoon", defaultValue: "It is noon", comment: "Widgets, the Angelus through the hour of its noon bell: the kicker over Pray the Angelus"),
                String(localized: "widget.angelus.atEighteen", defaultValue: "It is six in the evening", comment: "Widgets, the Angelus through the hour of its 6 PM bell: the kicker over Pray the Angelus"),
            ],
            weekInitials: weekInitials(calendar: calendar)
        )
    }

    /// The bells' hours, as the clock shows them: "6:00", "12:00", "6:00"
    /// on a twelve-hour phone, the word beneath saying which
    static var angelusTimes: [String] {
        let twentyFour = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("H") ?? false
        return [6, 12, 18].map { hour in
            let shown = twentyFour ? hour : (hour > 12 ? hour - 12 : hour)
            return twentyFour ? String(format: "%02d:00", shown) : "\(shown):00"
        }
    }

    private static func weekInitials(calendar: Calendar) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguage.code)
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        return symbols.map { $0.uppercased(with: formatter.locale) }
    }

    // MARK: - Formatting

    private static func weekdayName(of date: Date) -> String {
        let name = weekdayFormatter.string(from: date)
        return name.prefix(1).uppercased(with: weekdayFormatter.locale) + name.dropFirst()
    }

    private static func dayAndMonth(of date: Date) -> String {
        dayMonthFormatter.string(from: date)
    }

    /// The day and month, and the year too when it is not the year of the
    /// day it is read on: "11 January 2027" in November 2026
    private static func dayAndMonth(of date: Date, seenOn day: Date, calendar: Calendar) -> String {
        calendar.component(.year, from: date) == calendar.component(.year, from: day)
            ? dayMonthFormatter.string(from: date)
            : dayMonthYearFormatter.string(from: date)
    }

    private static func lowercasingFirstLetter(_ text: String) -> String {
        text.prefix(1).lowercased() + text.dropFirst()
    }

    private static let weekdayFormatter = languageFormatter(english: "EEEE", template: "EEEE")

    private static let dayMonthFormatter = languageFormatter(english: "d MMMM", template: "dMMMM")

    private static let dayMonthYearFormatter = languageFormatter(english: "d MMMM yyyy", template: "dMMMMyyyy")

    private static let fullDateFormatter = languageFormatter(english: "EEEE, d MMMM", template: "EEEEdMMMM")

    /// A date in the app's language: the designed English pattern, or the
    /// language's own order for the same parts
    private static func languageFormatter(english pattern: String, template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguage.code)
        if AppLanguage.code.hasPrefix("en") {
            formatter.dateFormat = pattern
        } else {
            formatter.setLocalizedDateFormatFromTemplate(template)
        }
        return formatter
    }

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale(identifier: AppLanguage.code)
        return formatter
    }()
}
