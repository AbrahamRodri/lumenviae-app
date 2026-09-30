//
//  HomeViewModel.swift
//  Lumen Viae
//
//  State and logic for the home screen.
//

import Foundation

@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    private let scheduleService: ScheduleService.Type

    // MARK: - Initialization

    init(scheduleService: ScheduleService.Type = ScheduleService.self) {
        self.scheduleService = scheduleService
    }

    // MARK: - Computed Properties

    /// Today's mystery category, on the schedule the user keeps. Read
    /// fresh rather than kept: Settings is pushed over home, and a
    /// schedule changed there has to be on the card when Back returns.
    var todaysCategory: MysteryCategory {
        scheduleService.categoryForToday()
    }

    /// The grid's sets: the ones the week prays on the user's schedule, in
    /// the week's order, then the Seven Sorrows — Joyful, Sorrowful,
    /// Glorious and the Sorrows on the traditional schedule, with the
    /// Luminous after the Glorious on the modern one. Read fresh for the
    /// same reason as `todaysCategory`.
    var allCategories: [MysteryCategory] {
        scheduleService.weekCategories() + [.sevenSorrows]
    }

    /// Day label for the header (e.g., "WEDNESDAY PRAYER")
    var dayLabel: String {
        scheduleService.dayLabel
    }

    /// Today's quotation on the Rosary
    var currentQuote: RosaryQuote {
        RosaryQuotes.today
    }
}
