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

    /// Today's mystery category based on the traditional schedule.
    let todaysCategory: MysteryCategory

    /// Mystery categories for the home screen grid (excludes Luminous, includes Seven Sorrows).
    let allCategories: [MysteryCategory] = MysteryCategory.homeCategories

    // MARK: - Dependencies

    private let scheduleService: ScheduleService.Type

    // MARK: - Initialization

    init(scheduleService: ScheduleService.Type = ScheduleService.self) {
        self.scheduleService = scheduleService
        self.todaysCategory = scheduleService.categoryForToday()
    }

    // MARK: - Computed Properties

    /// Day label for the header (e.g., "WEDNESDAY PRAYER")
    var dayLabel: String {
        scheduleService.dayLabel
    }

    /// Today's quotation on the Rosary
    var currentQuote: RosaryQuote {
        RosaryQuotes.today
    }
}
