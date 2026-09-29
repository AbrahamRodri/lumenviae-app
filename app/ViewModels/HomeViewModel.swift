//
//  HomeViewModel.swift
//  Lumen Viae
//
//  State and logic for the home screen.
//

import Foundation

@Observable
final class HomeViewModel {

    // MARK: - State

    /// Mystery categories for the home screen grid (excludes Luminous, includes Seven Sorrows).
    let allCategories: [MysteryCategory] = MysteryCategory.homeCategories

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

    /// Day label for the header (e.g., "WEDNESDAY PRAYER")
    var dayLabel: String {
        scheduleService.dayLabel
    }

    /// Today's quotation on the Rosary
    var currentQuote: RosaryQuote {
        RosaryQuotes.today
    }
}
