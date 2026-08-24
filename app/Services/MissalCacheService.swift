//
//  MissalCacheService.swift
//  Lumen Viae
//
//  Disk cache for the Daily Missal, so a basement chapel with no signal
//  still gets the right propers. Every fetched day is kept, the next
//  week is prefetched quietly, and propers for a date never change —
//  a cached day is never stale, only pruned once it is well past.
//
//  Lives in Application Support/Missal, excluded from iCloud backup
//  like the offline library: everything here is re-downloadable.
//

import Foundation

final class MissalCacheService {

    static let shared = MissalCacheService()

    private let directory: URL

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("Missal", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    // MARK: - Propers

    private func properURL(for day: String) -> URL {
        directory.appendingPathComponent("proper_\(day).json")
    }

    func saveProper(_ propers: [MissalProper], for day: String) {
        guard let data = try? encoder.encode(propers) else { return }
        try? data.write(to: properURL(for: day), options: .atomic)
    }

    func loadProper(for day: String) -> [MissalProper]? {
        guard let data = try? Data(contentsOf: properURL(for: day)) else { return nil }
        return try? decoder.decode([MissalProper].self, from: data)
    }

    func hasProper(for day: String) -> Bool {
        FileManager.default.fileExists(atPath: properURL(for: day).path)
    }

    /// Removes cached days before the given "yyyy-MM-dd" string. The file
    /// names sort as dates, so string comparison is date comparison.
    func pruneProper(before day: String) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for file in files where file.hasPrefix("proper_") {
            let cachedDay = file
                .replacingOccurrences(of: "proper_", with: "")
                .replacingOccurrences(of: ".json", with: "")
            if cachedDay < day {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(file))
            }
        }
    }

    // MARK: - Ordo

    private var ordoURL: URL { directory.appendingPathComponent("ordo.json") }

    func saveOrdo(_ sections: [MissalSection]) {
        guard let data = try? encoder.encode(sections) else { return }
        try? data.write(to: ordoURL, options: .atomic)
    }

    func loadOrdo() -> [MissalSection]? {
        guard let data = try? Data(contentsOf: ordoURL) else { return nil }
        return try? decoder.decode([MissalSection].self, from: data)
    }

    // MARK: - Calendar

    private func calendarURL(for year: Int) -> URL {
        directory.appendingPathComponent("calendar_\(year).json")
    }

    func saveCalendar(_ days: [MissalCalendarDay], for year: Int) {
        guard let data = try? encoder.encode(days) else { return }
        try? data.write(to: calendarURL(for: year), options: .atomic)
    }

    func loadCalendar(for year: Int) -> [MissalCalendarDay]? {
        guard let data = try? Data(contentsOf: calendarURL(for: year)) else { return nil }
        return try? decoder.decode([MissalCalendarDay].self, from: data)
    }
}
