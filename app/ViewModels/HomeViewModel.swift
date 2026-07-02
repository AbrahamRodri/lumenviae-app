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

    /// Mysteries for today's category, loaded from local data.
    let mysteries: [Mystery]

    /// Mystery categories for the home screen grid (excludes Luminous, includes Seven Sorrows).
    let allCategories: [MysteryCategory] = MysteryCategory.homeCategories

    // MARK: - Dependencies

    private let scheduleService: ScheduleService.Type

    // MARK: - Initialization

    init(scheduleService: ScheduleService.Type = ScheduleService.self) {
        self.scheduleService = scheduleService
        self.todaysCategory = scheduleService.categoryForToday()
        self.mysteries = MysteryData.mysteries(for: todaysCategory)
    }

    // MARK: - Computed Properties

    /// The first mystery of today's set, shown in the featured card.
    var featuredMystery: Mystery? {
        mysteries.first
    }

    /// Day label for the header (e.g., "WEDNESDAY PRAYER")
    var dayLabel: String {
        scheduleService.dayLabel
    }

    /// Today's inspirational quote
    var currentQuote: (text: String, author: String) {
        MockDataService.todaysQuote
    }
}
