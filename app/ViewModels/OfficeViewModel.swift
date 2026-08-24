//
//  OfficeViewModel.swift
//  Lumen Viae
//
//  State for the Divine Office: which day is open, its place in the
//  calendar, and each hour as it is read. Days and hours already fetched
//  this session are kept, so stepping back to yesterday never refetches.
//
//  The day's ledger of hours is bundled and always renders; only the
//  texts travel. A day whose calendar line cannot be reached still
//  offers its hours — each surfaces its own failure if it must.
//

import Foundation
import Observation

@Observable
final class OfficeViewModel {

    // MARK: - Dependencies

    private let api: OfficeAPIService
    private let diskCache = OfficeCacheService.shared
    private let calendar = Calendar.current

    /// Today and tomorrow are stored to disk once per session
    private var hasPrefetched = false

    // MARK: - State

    /// The day being read, always a start-of-day value
    private(set) var date: Date

    /// The open day's place in the calendar, once known
    private(set) var day: OfficeDay?

    /// True while the day's calendar line loads. The hours ledger does
    /// not wait on it.
    var isLoadingDay = false

    /// Set when the day's calendar line cannot be reached. Quietly
    /// noted, never a wall — the hours remain tappable.
    var dayUnavailable = false

    /// Days fetched this session, keyed by their start-of-day date
    private var dayCache: [Date: OfficeDay] = [:]

    /// Hours fetched this session, keyed by "day/hour"
    private var hourCache: [String: OfficeHour] = [:]

    // MARK: - Initialization

    init(api: OfficeAPIService = .shared) {
        self.api = api
        self.date = Calendar.current.startOfDay(for: .now)
    }

    // MARK: - Derived

    var isToday: Bool { calendar.isDateInToday(date) }

    /// "Monday, August 24"
    var dateLabel: String { Self.displayFormatter.string(from: date) }

    /// "2026-08-24" for the open day
    var dayString: String { OfficeAPIService.dayString(for: date) }

    /// The hour whose traditional time holds the present moment —
    /// marked in the ledger only when the open day is today.
    var presentHour: CanonicalHour? {
        guard isToday else { return nil }
        return CanonicalHour.present(atClockHour: calendar.component(.hour, from: .now))
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    // MARK: - Day Loading

    @MainActor
    func load() async {
        if let cached = dayCache[date] {
            day = cached
            dayUnavailable = false
            prefetchNearDays()
            return
        }

        let requested = date
        let dayKey = OfficeAPIService.dayString(for: requested)
        isLoadingDay = true
        dayUnavailable = false

        do {
            let fetched = try await api.fetchDay(day: dayKey)
            dayCache[requested] = fetched
            diskCache.saveDay(fetched, for: dayKey)
            // A slow answer for a day the reader has already stepped away
            // from still caches, but must not overwrite the open page.
            if requested == date {
                day = fetched
            }
        } catch {
            // No connection — but a day's calendar line never changes,
            // so a stored day is as good as a fresh one.
            if let stored = diskCache.loadDay(for: dayKey) {
                dayCache[requested] = stored
                if requested == date {
                    day = stored
                }
            } else if requested == date {
                dayUnavailable = true
            }
        }

        if requested == date {
            isLoadingDay = false
        }
        prefetchNearDays()
    }

    @MainActor
    func retryDay() async {
        dayCache[date] = nil
        await load()
    }

    // MARK: - Hour Loading

    /// One hour's full text: this session's copy, the disk's, or the
    /// API's, in that order. The disk is consulted before the network on
    /// purpose — an office never changes once assembled, and the cached
    /// page opens instantly in a chapel with no signal.
    @MainActor
    func loadHour(_ hour: CanonicalHour) async throws -> OfficeHour {
        let dayKey = dayString
        let cacheKey = "\(dayKey)/\(hour.rawValue)"

        if let held = hourCache[cacheKey] {
            return held
        }
        if let stored = diskCache.loadHour(for: dayKey, hour: hour) {
            hourCache[cacheKey] = stored
            return stored
        }

        let fetched = try await api.fetchHour(day: dayKey, hour: hour)
        hourCache[cacheKey] = fetched
        diskCache.saveHour(fetched, for: dayKey, hour: hour)
        return fetched
    }

    // MARK: - Prefetch

    /// Quietly stores today's and tomorrow's hours to disk after a
    /// successful load, so the evening's Compline and the morning's
    /// Lauds are already waiting. Once per session; days well past are
    /// pruned. Sequential on purpose: sixteen quiet requests, each fast
    /// once the server's month cache is warm, none racing the reader's
    /// own fetches for the connection.
    private func prefetchNearDays() {
        guard !hasPrefetched, day != nil else { return }
        hasPrefetched = true

        let api = self.api
        let diskCache = self.diskCache
        let calendar = self.calendar
        let today = calendar.startOfDay(for: .now)

        Task {
            for offset in 0...1 {
                guard let ahead = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
                let dayKey = OfficeAPIService.dayString(for: ahead)

                if !diskCache.hasDay(for: dayKey),
                   let fetched = try? await api.fetchDay(day: dayKey) {
                    diskCache.saveDay(fetched, for: dayKey)
                }

                for hour in CanonicalHour.allCases {
                    guard !diskCache.hasHour(for: dayKey, hour: hour) else { continue }
                    if let fetched = try? await api.fetchHour(day: dayKey, hour: hour) {
                        diskCache.saveHour(fetched, for: dayKey, hour: hour)
                    }
                }
            }

            if let horizon = calendar.date(byAdding: .day, value: -30, to: today) {
                diskCache.prune(before: OfficeAPIService.dayString(for: horizon))
            }
        }
    }

    // MARK: - Date Stepping

    @MainActor
    func step(by days: Int) async {
        guard let stepped = calendar.date(byAdding: .day, value: days, to: date) else { return }
        open(stepped)
        await load()
    }

    @MainActor
    func goToToday() async {
        open(.now)
        await load()
    }

    @MainActor
    func jump(to newDate: Date) async {
        open(newDate)
        await load()
    }

    private func open(_ newDate: Date) {
        date = calendar.startOfDay(for: newDate)
        day = dayCache[date]
        dayUnavailable = false
    }
}
