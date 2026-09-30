//
//  ScheduleWeekTests.swift
//  Lumen Viae Tests
//
//  The sets each schedule's week prays, which the home page's grid shows
//  before the Seven Sorrows: the traditional week without the Luminous,
//  the modern one with them on Thursday, each in the week's order.
//

import Testing
@testable import app

@MainActor
struct ScheduleWeekTests {

    @Test func traditionalWeekHasNoLuminous() {
        #expect(ScheduleService.weekCategories(in: .traditional) == [.joyful, .sorrowful, .glorious])
    }

    @Test func modernWeekAddsTheLuminousAfterTheGlorious() {
        #expect(ScheduleService.weekCategories(in: .modern) == [.joyful, .sorrowful, .glorious, .luminous])
    }

    /// Every set the week names is one the grid shows, so no weekday's
    /// mysteries are only behind VIEW ALL
    @Test(arguments: MysterySchedule.allCases)
    func everyWeekdaysSetIsInTheWeek(_ schedule: MysterySchedule) {
        let week = ScheduleService.weekCategories(in: schedule)
        for category in MysteryCategory.allCategories where category != .sevenSorrows {
            let prayed = ScheduleService.daysPrayed(category, in: schedule) != nil
            #expect(week.contains(category) == prayed, "\(category) on \(schedule)")
        }
    }
}
