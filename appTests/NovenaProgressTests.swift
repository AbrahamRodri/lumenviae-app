import Foundation
import Testing

@testable import app

@Suite("Novena progress")
struct NovenaProgressTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Chicago")!
        return c
    }()

    /// Noon on 14 Nov 2026 plus `days`
    private func day(_ days: Int, hour: Int = 12) -> Date {
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: hour))!
        return calendar.date(byAdding: .day, value: days, to: start)!
    }

    private func begun() -> NovenaProgress {
        NovenaProgress(novenaID: "undoer_of_knots", length: 9, beginning: day(0), calendar: calendar)
    }

    @Test func theDayIsFixedByTheDate() {
        let p = begun()
        #expect(p.dayNumber(on: day(0), calendar: calendar) == 1)
        #expect(p.dayNumber(on: day(3), calendar: calendar) == 4)
        #expect(p.standing(on: day(0), calendar: calendar) == .underWay(today: 1, open: []))
    }

    @Test func halfPastTwelveCountsForTheEveningBefore() {
        let p = begun()
        // 12:30 AM on the 15th is still the 14th's prayer day
        #expect(p.dayNumber(on: day(1, hour: 0).addingTimeInterval(30 * 60), calendar: calendar) == 1)
        #expect(p.dayNumber(on: day(1, hour: 5), calendar: calendar) == 2)
    }

    @Test func aMissedDayIsOpenAndMovesNothing() {
        var p = begun()
        p.markPrayed(1)
        p.markPrayed(2)
        // Day 3 not prayed; it is now day 4
        #expect(p.standing(on: day(3), calendar: calendar) == .underWay(today: 4, open: [3]))
        #expect(p.canPray(3, on: day(3), calendar: calendar))
        p.markPrayed(3)
        #expect(p.standing(on: day(3), calendar: calendar) == .underWay(today: 4, open: []))
    }

    @Test func daysAheadCannotBePrayedEarly() {
        let p = begun()
        #expect(!p.canPray(2, on: day(0), calendar: calendar))
        #expect(p.canPray(1, on: day(0), calendar: calendar))
    }

    @Test func threeOpenDaysWelcomeBack() {
        var p = begun()
        p.markPrayed(1)
        #expect(p.standing(on: day(4), calendar: calendar) == .welcomeBack(firstOpen: 2))
    }

    @Test func pastTheLastDateWithADayOpenWelcomesBack() {
        var p = begun()
        for d in 1...8 { p.markPrayed(d) }
        #expect(p.standing(on: day(9), calendar: calendar) == .welcomeBack(firstOpen: 9))
    }

    @Test func pickingUpRunsTheRestFromToday() {
        var p = begun()
        p.markPrayed(1)
        p.pickUp(on: day(6), calendar: calendar)
        #expect(p.standing(on: day(6), calendar: calendar) == .underWay(today: 2, open: []))
        #expect(p.date(ofDay: 9, calendar: calendar) == PrayerDay.day(of: day(13), calendar: calendar))
        #expect(p.prayed == [1])
    }

    @Test func beginningAgainKeepsTheIntention() {
        var p = NovenaProgress(
            novenaID: "undoer_of_knots", length: 9, beginning: day(0), intention: "My brother",
            calendar: calendar)
        p.markPrayed(1)
        p.beginAgain(on: day(5), calendar: calendar)
        #expect(p.prayed.isEmpty)
        #expect(p.intention == "My brother")
        #expect(p.standing(on: day(5), calendar: calendar) == .underWay(today: 1, open: []))
    }

    @Test func finishedStaysFinished() {
        var p = begun()
        for d in 1...9 { p.markPrayed(d) }
        #expect(p.standing(on: day(30), calendar: calendar) == .finished)
    }

    @Test func aTwentyFiveDayNovenaIsNotNine() {
        let p = NovenaProgress(novenaID: "st_andrew", length: 25, beginning: day(0), calendar: calendar)
        #expect(p.standing(on: day(20), calendar: calendar) == .welcomeBack(firstOpen: 1))
        #expect(p.daysToRemind(from: day(0), calendar: calendar).count == 25)
    }

    @Test func remindersSkipDaysPrayedAndStopAfterTheLast() {
        var p = begun()
        p.markPrayed(1)
        let days = p.daysToRemind(from: day(0), calendar: calendar).map(\.day)
        #expect(days == Array(2...9))
        #expect(p.daysToRemind(from: day(20), calendar: calendar).isEmpty)
    }
}

@Suite("Novena document")
struct NovenaDocumentTests {
    private let json = """
        {"version":"v1","prayers":[{"id":"memorare","title":"Memorare","english":"Remember"},
          {"id":"knots_twin","title":"Novena","english":"Day 1"}],
         "chapters":[{"id":"our_lady","numeral":"XI","title":"Mary","latin_title":"De B.V.M.","prayer_ids":["memorare","knots_twin"]}],
         "novenas":[{"id":"undoer_of_knots","title":"Our Lady, Undoer of Knots","detail":"Nine days.",
           "prayer_id":"knots_twin","chapter_id":"our_lady","length":1,"feast":{"kind":"unknown-shape","month":"x"},
           "days":[{"number":1,"title":"Day 1","parts":[
             {"kind":"rosary","decades":[1,2,3]},
             {"kind":"meditation","id":"knots_meditation","title":null,"text":"Words.","source":"St Irenaeus"},
             {"kind":"rosary","decades":[4,5]},
             {"kind":"closing","prayer_id":"memorare","times":null},
             {"kind":"something_new","id":"x","text":"Shown plain."}]}]}]}
        """

    @Test func aBookWithNovenasDecodes() throws {
        let book = try JSONDecoder().decode(PrayerBookDocument.self, from: Data(json.utf8))
        #expect(book.novenas.count == 1)
        let knots = try #require(book.novenas.first)
        #expect(knots.feast == nil)  // a feast that does not read is dropped, not fatal
        #expect(knots.day(1)?.parts.first?.decades == [1, 2, 3])
        #expect(knots.day(1)?.parts[3].prayerID == "memorare")
        #expect(book.novenaProblem(prayerIDs: Set(book.prayers.map(\.id))) == nil)
    }

    @Test func aBookFromBeforeNovenasHasNone() throws {
        let book = try JSONDecoder().decode(
            PrayerBookDocument.self,
            from: Data(#"{"prayers":[{"id":"a","title":"A","english":"x"}],"chapters":[]}"#.utf8))
        #expect(book.novenas.isEmpty)
        let written = String(decoding: try JSONEncoder().encode(book), as: UTF8.self)
        #expect(!written.contains("novenas"))
    }

    @Test func aNovenaNamingAMissingPrayerIsRefused() throws {
        var book = try JSONDecoder().decode(PrayerBookDocument.self, from: Data(json.utf8))
        book.novenas[0].days[0].parts[3].prayerID = "nowhere"
        #expect(book.novenaProblem(prayerIDs: Set(book.prayers.map(\.id))) != nil)
        book = try JSONDecoder().decode(PrayerBookDocument.self, from: Data(json.utf8))
        book.novenas[0].length = 9
        #expect(book.novenaProblem(prayerIDs: Set(book.prayers.map(\.id))) != nil)
    }
}

@MainActor @Suite("Novena reminders")
struct NovenaReminderTests {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Chicago")!
        return c
    }()

    private func at(_ days: Int, hour: Int) -> Date {
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: hour))!
        return calendar.date(byAdding: .day, value: days, to: start)!
    }

    private let knots = PrayerBookDocument.Novena(
        id: "undoer_of_knots", title: "Our Lady, Undoer of Knots", listTitle: "Undoer of Knots",
        detail: "", prayerID: "twin", chapterID: "our_lady", length: 9, days: [])

    private func progress(intention: String? = nil, shows: Bool = false) -> NovenaProgress {
        var p = NovenaProgress(
            novenaID: knots.id, length: 9, beginning: at(0, hour: 9), intention: intention,
            reminder: DateComponents(hour: 20, minute: 0), calendar: calendar)
        p.remindsWithIntention = shows
        return p
    }

    @Test func oneReminderADayThenStillHere() {
        let list = NovenaStore.reminders(for: progress(), novena: knots, now: at(0, hour: 9), calendar: calendar)
        #expect(list.map(\.day) == [1, 2, 3, 4, 5, 6, 7, 8, 9, nil])
        #expect(list[0].fire.hour == 20)
        #expect(list[0].fire.day == 14)
        #expect(list[8].fire.day == 22)
        #expect(list[9].identifier == "novena.undoer_of_knots.after")
        #expect(list[9].fire.day == 23)
    }

    @Test func todaysReminderIsLeftOutOncePastItsTime() {
        let list = NovenaStore.reminders(for: progress(), novena: knots, now: at(0, hour: 21), calendar: calendar)
        #expect(list.first?.day == 2)
    }

    @Test func aDayPrayedEarlyHasNoReminder() {
        var p = progress()
        p.markPrayed(1)
        let list = NovenaStore.reminders(for: p, novena: knots, now: at(0, hour: 10), calendar: calendar)
        #expect(!list.contains { $0.day == 1 })
    }

    @Test func noTimeMeansNoReminders() {
        var p = progress()
        p.reminder = nil
        #expect(NovenaStore.reminders(for: p, novena: knots, now: at(0, hour: 9), calendar: calendar).isEmpty)
    }

    @Test func theIntentionOnlyWhenTurnedOn() {
        let off = NovenaStore.reminders(
            for: progress(intention: "For my mother"), novena: knots, now: at(0, hour: 9), calendar: calendar)
        #expect(!off[0].body.contains("mother"))
        let on = NovenaStore.reminders(
            for: progress(intention: "For my mother", shows: true), novena: knots, now: at(0, hour: 9),
            calendar: calendar)
        #expect(on[0].body == "For my mother")
    }

    @Test func theKnotsLinesBelongToThisNovenaAlone() {
        #expect(NovenaStore.dayLine(4, of: 9, novenaID: "undoer_of_knots").contains("knot"))
        #expect(!NovenaStore.dayLine(4, of: 9, novenaID: "st_joseph").contains("knot"))
        #expect(NovenaStore.dayLine(9, of: 9, novenaID: "st_joseph").contains("last day"))
        #expect(!NovenaStore.dayLine(3, of: 9, novenaID: "x").lowercased().contains("missed"))
    }
}
