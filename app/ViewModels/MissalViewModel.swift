//
//  MissalViewModel.swift
//  Lumen Viae
//
//  State for the Daily Missal: which day is open, its celebrations, and
//  which one is being read. Days already fetched this session are kept,
//  so stepping back to yesterday never refetches it.
//

import Foundation
import Observation

@Observable
final class MissalViewModel {

    // MARK: - Dependencies

    private let api: MissalAPIService
    private let diskCache = MissalCacheService.shared
    private let calendar = Calendar.current

    /// The coming week is stored to disk once per session
    private var hasPrefetched = false

    // MARK: - State

    /// The day being read, always a start-of-day value
    private(set) var date: Date

    /// Every celebration on that day — usually one, three on Christmas
    private(set) var propers: [MissalProper] = []

    /// Which celebration is open when the day carries more than one
    var selectedIndex = 0

    var isLoading = false
    var errorMessage: String?

    /// Days fetched this session, keyed by their start-of-day date
    private var cache: [Date: [MissalProper]] = [:]

    // MARK: - Initialization

    init(api: MissalAPIService = .shared) {
        self.api = api
        self.date = Calendar.current.startOfDay(for: .now)
    }

    // MARK: - Derived

    var selectedProper: MissalProper? {
        guard propers.indices.contains(selectedIndex) else { return propers.first }
        return propers[selectedIndex]
    }

    var isToday: Bool { calendar.isDateInToday(date) }

    /// "Monday, August 24"
    var dateLabel: String { Self.displayFormatter.string(from: date) }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    // MARK: - Loading

    @MainActor
    func load() async {
        if let cached = cache[date] {
            propers = cached
            errorMessage = nil
            prefetchWeekAhead()
            return
        }

        let requested = date
        let day = MissalAPIService.dayString(for: requested)
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await api.fetchPropers(day: day)
            cache[requested] = fetched
            diskCache.saveProper(fetched, for: day)
            // A slow answer for a day the reader has already stepped away
            // from still caches, but must not overwrite the open page.
            if requested == date {
                propers = fetched
            }
        } catch {
            // No connection — a chapel basement — but propers for a date
            // never change, so a stored day is as good as a fresh one.
            if let stored = diskCache.loadProper(for: day) {
                cache[requested] = stored
                if requested == date {
                    propers = stored
                }
            } else if requested == date {
                errorMessage = "The missal could not be reached. Check your connection and try again."
            }
        }

        if requested == date {
            isLoading = false
        }
        prefetchWeekAhead()
    }

    /// Quietly stores the coming week — and the Ordo — to disk after a
    /// successful load, so a chapel with no signal still has the right
    /// page. Once per session; days well past are pruned.
    private func prefetchWeekAhead() {
        guard !hasPrefetched, !propers.isEmpty else { return }
        hasPrefetched = true

        let api = self.api
        let diskCache = self.diskCache
        let calendar = self.calendar
        let today = calendar.startOfDay(for: .now)

        Task {
            for offset in 0...7 {
                guard let ahead = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
                let day = MissalAPIService.dayString(for: ahead)
                guard !diskCache.hasProper(for: day) else { continue }
                if let fetched = try? await api.fetchPropers(day: day) {
                    diskCache.saveProper(fetched, for: day)
                }
            }

            if diskCache.loadOrdo() == nil, let ordo = try? await api.fetchOrdo() {
                diskCache.saveOrdo(ordo)
            }

            if let horizon = calendar.date(byAdding: .day, value: -30, to: today) {
                diskCache.pruneProper(before: MissalAPIService.dayString(for: horizon))
            }
        }
    }

    @MainActor
    func retry() async {
        cache[date] = nil
        await load()
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
        selectedIndex = 0
        propers = cache[date] ?? []
        errorMessage = nil
    }
}
