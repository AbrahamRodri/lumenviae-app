//
//  WidgetSnapshot+App.swift
//  Lumen Viae
//
//  Building the widgets' snapshot from the app's state. In the app only:
//  the widget extension reads `WidgetSnapshot` and never builds one.
//

import Foundation

// MARK: - Building one

extension WidgetSnapshot {

    /// The snapshot from the app's state, pure, so a test can build one.
    /// `novenaName` gives a novena's short name by its id.
    @MainActor
    static func make(
        resume: InProgressPrayer?,
        novenas: [String: NovenaProgress],
        novenaName: (String) -> String?,
        prayerDays: Set<Date>,
        consecration: ConsecrationProgress?,
        liturgicalDay: LiturgicalDay?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WidgetSnapshot {
        let today = PrayerDay.day(of: now, calendar: calendar)

        let rosary = resume.map(rosaryState(of:))

        let novenaList: [Novena] = novenas.values.compactMap { (progress: NovenaProgress) -> Novena? in
            let standing = progress.standing(on: now, calendar: calendar)
            let todays: Int?
            let current: Int
            switch standing {
            case .finished:
                return nil
            case .underWay(let day, let open):
                todays = day
                current = day ?? open.first ?? min(progress.dayNumber(on: now, calendar: calendar), progress.length)
            case .welcomeBack(let firstOpen):
                todays = nil
                current = firstOpen
            }
            let dayToday = progress.dayNumber(on: now, calendar: calendar)
            return Novena(
                id: progress.novenaID,
                name: novenaName(progress.novenaID) ?? progress.novenaID,
                length: progress.length,
                prayedDays: progress.prayed.sorted(),
                todaysDay: todays,
                currentDay: max(1, min(current, progress.length)),
                prayedToday: progress.prayed.contains(dayToday)
            )
        }
        .sorted { lhs, rhs in
            if (lhs.todaysDay != nil) != (rhs.todaysDay != nil) { return lhs.todaysDay != nil }
            return lhs.id < rhs.id
        }

        // Sunday to Saturday, as the Prayer Record's week, whatever the locale
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1
        let weekStart = sundayFirst.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let week = (0..<7).map { PrayerDay.adding(days: $0, to: weekStart, calendar: calendar) }
            .filter { prayerDays.contains($0) }
        let record = Record(
            daysInARow: PrayerHistoryService.currentStreak(in: prayerDays, today: today, calendar: calendar),
            prayedToday: prayerDays.contains(today),
            thisWeek: week
        )

        let consecrationState = consecration.map { progress -> Consecration in
            let number = min(progress.daysSinceStart(asOf: now) + 1, 34)
            return Consecration(
                startDate: progress.startDate,
                hasBegun: progress.hasBegun(asOf: now),
                dayNumber: number,
                dayTitle: ConsecrationData.day(number)?.title ?? "",
                todayPrayed: progress.isDayCompleted(number),
                isCompleted: progress.isCompleted
            )
        }

        return WidgetSnapshot(
            rosary: rosary,
            novenas: novenaList,
            record: record,
            consecration: consecrationState,
            liturgicalDay: liturgicalDay
        )
    }

    /// Where the Rosary left off stands, for the widget
    private static func rosaryState(of prayer: InProgressPrayer) -> Rosary {
        let kind = prayer.kind ?? .meditationSet
        return Rosary(
            category: prayer.category,
            form: kind.rawValue,
            setName: kind == .meditationSet ? prayer.setName : "",
            mysteryIndex: prayer.mysteryIndex,
            beadIndex: prayer.beadIndex,
            savedAt: prayer.savedAt
        )
    }
}
