//
//  OfficeCacheService.swift
//  Lumen Viae
//
//  Disk cache for the Divine Office, so a chapel with no signal still
//  gets the right hour. An office, once assembled for a date, never
//  changes — a cached hour is never stale, only pruned once it is well
//  past. Every file name carries the rubrical version, so a future
//  version setting can never read another version's page.
//
//  Lives in Application Support/Office, excluded from iCloud backup
//  like the missal's cache: everything here is re-downloadable.
//

import Foundation

final class OfficeCacheService {

    static let shared = OfficeCacheService()

    private let directory: URL

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("Office", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private var version: String { OfficeAPIService.version }

    // MARK: - Hours

    private func hourURL(for day: String, hour: CanonicalHour) -> URL {
        directory.appendingPathComponent("hour_\(version)_\(day)_\(hour.rawValue).json")
    }

    func saveHour(_ office: OfficeHour, for day: String, hour: CanonicalHour) {
        guard let data = try? encoder.encode(office) else { return }
        try? data.write(to: hourURL(for: day, hour: hour), options: .atomic)
    }

    func loadHour(for day: String, hour: CanonicalHour) -> OfficeHour? {
        guard let data = try? Data(contentsOf: hourURL(for: day, hour: hour)) else { return nil }
        return try? decoder.decode(OfficeHour.self, from: data)
    }

    func hasHour(for day: String, hour: CanonicalHour) -> Bool {
        FileManager.default.fileExists(atPath: hourURL(for: day, hour: hour).path)
    }

    // MARK: - Days

    private func dayURL(for day: String) -> URL {
        directory.appendingPathComponent("day_\(version)_\(day).json")
    }

    func saveDay(_ office: OfficeDay, for day: String) {
        guard let data = try? encoder.encode(office) else { return }
        try? data.write(to: dayURL(for: day), options: .atomic)
    }

    func loadDay(for day: String) -> OfficeDay? {
        guard let data = try? Data(contentsOf: dayURL(for: day)) else { return nil }
        return try? decoder.decode(OfficeDay.self, from: data)
    }

    func hasDay(for day: String) -> Bool {
        FileManager.default.fileExists(atPath: dayURL(for: day).path)
    }

    // MARK: - Calendar

    private func calendarURL(year: Int, month: Int) -> URL {
        directory.appendingPathComponent(
            "calendar_\(version)_\(year)-\(String(format: "%02d", month)).json"
        )
    }

    func saveCalendar(_ calendar: OfficeCalendarMonth) {
        guard let data = try? encoder.encode(calendar) else { return }
        try? data.write(to: calendarURL(year: calendar.year, month: calendar.month), options: .atomic)
    }

    func loadCalendar(year: Int, month: Int) -> OfficeCalendarMonth? {
        guard let data = try? Data(contentsOf: calendarURL(year: year, month: month)) else { return nil }
        return try? decoder.decode(OfficeCalendarMonth.self, from: data)
    }

    // MARK: - Pruning

    /// Removes cached hours and days before the given "yyyy-MM-dd"
    /// string. The date sits in a fixed position of each file name and
    /// sorts as a date, so string comparison is date comparison. Month
    /// calendars are small and few; they stay.
    func prune(before day: String) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for file in files {
            let cachedDay: String?
            if file.hasPrefix("hour_\(version)_") {
                cachedDay = String(file.dropFirst("hour_\(version)_".count).prefix(10))
            } else if file.hasPrefix("day_\(version)_") {
                cachedDay = String(file.dropFirst("day_\(version)_".count).prefix(10))
            } else {
                cachedDay = nil
            }
            if let cachedDay, cachedDay < day {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(file))
            }
        }
    }
}
