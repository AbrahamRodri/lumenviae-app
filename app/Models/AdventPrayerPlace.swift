//
//  AdventPrayerPlace.swift
//  Lumen Viae
//
//  Where the two Advent prayers open in their season: the O Antiphons
//  at today's antiphon (17 to 23 December), the Advent wreath's collects
//  at this week's Sunday. Read on the 21st, the antiphons once opened at
//  the 17th, four antiphons above the day's (batch 5, item 3).
//

import Foundation

enum AdventPrayerPlace {
    static let antiphonsID = "o_antiphons"
    static let wreathID = "advent_wreath_collects"

    /// The stanza (an index into `PrayAlongView.stanzas`) holding today's
    /// heading, or nil out of season, for any other prayer, or for a text
    /// whose headings are not the ones counted on
    static func stanza(of prayerID: String, in stanzas: [String], on date: Date, calendar: Calendar = .current) -> Int? {
        let headings = stanzas.indices.filter { isHeading(stanzas[$0]) }
        switch prayerID {
        case antiphonsID:
            // One heading a day, 17 to 23 December
            guard headings.count == 7, let day = antiphonDay(on: date, calendar: calendar) else { return nil }
            return headings[day - 17]
        case wreathID:
            // A heading over all four, then one for each Sunday
            guard headings.count >= 4, let week = adventWeek(on: date, calendar: calendar) else { return nil }
            return headings[headings.count - 4 + week - 1]
        default:
            return nil
        }
    }

    /// 17 to 23 for the days of the O Antiphons, else nil
    static func antiphonDay(on date: Date, calendar: Calendar = .current) -> Int? {
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard parts.month == 12, let day = parts.day, (17...23).contains(day) else { return nil }
        return day
    }

    /// The week of Advent, 1 to 4, from the eve of its First Sunday to
    /// 24 December. Each week runs from its Sunday's eve, so a Saturday
    /// reads the coming Sunday's collect (the website's rule,
    /// `Book.advent_cards/2`, and design's This Season frame)
    static func adventWeek(on date: Date, calendar: Calendar = .current) -> Int? {
        let year = calendar.component(.year, from: date)
        guard let start = ScheduleService.adventStart(year: year, calendar: calendar),
              let christmasEve = calendar.date(from: DateComponents(year: year, month: 12, day: 24))
        else { return nil }
        let day = calendar.startOfDay(for: date)
        let first = calendar.startOfDay(for: start)
        let days = calendar.dateComponents([.day], from: first, to: day).day ?? 0
        guard days >= -1, day <= christmasEve else { return nil }
        return min((days + 1) / 7 + 1, 4)
    }

    /// A stanza that is only a rubric, "[December 18.]", in one language
    /// or paired with its Latin
    static func isHeading(_ stanza: String) -> Bool {
        let parts = stanza.components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: "|||") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return !parts.isEmpty && parts.allSatisfy { $0.hasPrefix("[") && $0.hasSuffix("]") }
    }
}
