//
//  OfficeCalendarSheet.swift
//  Lumen Viae
//
//  The date's sheet: one month of the breviary's calendar as a grid,
//  the missal's own — drawn by `LiturgicalMonthGrid`, which both books
//  share. The office names no vestment colour, so each day carries its
//  class instead: a gold mark that burns brighter for the greater
//  feasts, so a month reads at a glance the way a finger down a printed
//  ribbon does. Beneath the grid, the truth about offline: how much of
//  the month is already on this device, and a way to save the rest.
//
//  Months are fetched whole and kept on disk beside the cached hours.
//

import SwiftUI

struct OfficeCalendarSheet: View {

    /// Called with the chosen date; the sheet dismisses itself.
    let onSelect: (Date) -> Void

    /// First day of the displayed month
    @State private var month: Date

    /// The breviary's calendar, keyed "yyyy-MM-dd"
    @State private var days: [String: OfficeDay] = [:]

    /// Months whose calendar is here. A month is only recorded once it
    /// has actually arrived — see `loadMonth`.
    @State private var loadedMonths: Set<String> = []

    /// The month on screen could not be reached and holds nothing.
    @State private var loadFailed = false
    @State private var isLoading = false

    /// How many of the month's days are on this device, hours and all
    @State private var savedCount = 0

    /// The in-flight month download, if any, and the token that says
    /// whose it is.
    @State private var downloadTask: Task<Void, Never>?
    @State private var downloadGeneration = 0
    @State private var isDownloading = false

    private let calendar = Calendar.current

    init(onSelect: @escaping (Date) -> Void) {
        self.onSelect = onSelect
        _month = State(
            initialValue: LiturgicalCalendarFormat.firstOfMonth(
                containing: .now, calendar: Calendar.current
            )
        )
    }

    // MARK: - Body

    var body: some View {
        MissalSheetShell(title: "") {
            LiturgicalMonthGrid(
                month: $month,
                title: { title(of: entry(for: $0)) },
                spokenTitle: { spokenTitle($0) },
                onSelect: onSelect,
                dayMark: { date, _ in dayMark(date) },
                offline: { offlineRow }
            )
        }
        .task { await loadMonth() }
        .onChange(of: month) {
            // Stepping the month puts down whatever the last one was
            // saving: the reader has moved on, and the row they are
            // looking at is not the one downloading.
            cancelDownload()
            refreshSavedCount()
            Task { await loadMonth() }
        }
        .onAppear { refreshSavedCount() }
        .onDisappear { cancelDownload() }
    }

    // MARK: - The day's mark

    /// The office names no colour, so a day is marked by its class —
    /// and a feria carries no mark at all, an unlit dot on every
    /// ordinary day being just noise across the month.
    private func dayMark(_ date: Date) -> some View {
        let rank = OfficeRank(entry(for: date)?.celebration?.rank)
        return Circle()
            .fill(AppColors.gold.opacity(rank.markOpacity))
            .frame(width: rank.markSize, height: rank.markSize)
            .frame(height: 5.5)
    }

    private func entry(for date: Date) -> OfficeDay? {
        days[OfficeAPIService.dayString(for: date)]
    }

    /// A day the calendar titles, or the season line it falls under — a
    /// feria is a real answer, not a blank. A month that could not be
    /// reached says so rather than calling every day an em dash.
    private func title(of entry: OfficeDay?) -> String {
        guard let entry else {
            if isLoading { return "…" }
            return loadFailed ? "The calendar could not be reached" : "—"
        }
        if let celebration = entry.celebration?.title, !celebration.isEmpty {
            return celebration
        }
        if let text = entry.detail?.text, !text.isEmpty {
            return text
        }
        return "Feria"
    }

    /// The spoken name of a cell: the date, then the day the calendar
    /// keeps — a mark of light tells VoiceOver nothing at all.
    private func spokenTitle(_ date: Date) -> String {
        let day = LiturgicalCalendarFormat.spokenDate.string(from: date)
        guard let entry = entry(for: date) else { return day }
        return "\(day). \(title(of: entry))"
    }

    // MARK: - Offline

    /// The month's offline standing, told honestly: what is saved, and a
    /// way to save the rest. An office, once assembled for a date, never
    /// changes — a saved month is a settled matter.
    private var offlineRow: some View {
        HStack(spacing: 10) {
            if monthFullySaved {
                AppIcon("ph-check-circle-fill", size: 18)
                    .foregroundColor(AppColors.gold.opacity(0.75))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(offlineTitle)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream)

                Text(offlineDetail)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 8)

            if isDownloading {
                ProgressView()
                    .tint(AppColors.gold)
            } else if loadFailed {
                // Nothing here to save, and a retry is the only useful
                // act on a month that never arrived.
                QuietGoldButton(
                    title: "Try again",
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 11,
                    size: 10,
                    color: AppColors.gold
                ) {
                    Task { await loadMonth(retrying: true) }
                }
            } else if !monthFullySaved {
                Button {
                    downloadMonth()
                } label: {
                    Text("SAVE")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel(
                    "Save \(LiturgicalCalendarFormat.monthName.string(from: month)) for offline"
                )
            }
        }
        .frame(minHeight: 44)
    }

    private var monthDates: [Date] {
        LiturgicalCalendarFormat.monthDates(of: month, calendar: calendar)
    }

    private var monthDayCount: Int { monthDates.count }

    private var monthFullySaved: Bool {
        monthDayCount > 0 && savedCount >= monthDayCount
    }

    private var offlineTitle: String {
        let name = LiturgicalCalendarFormat.monthName.string(from: month)
        if loadFailed { return "\(name) could not be reached" }
        if monthFullySaved { return "\(name) is saved for offline" }
        if isDownloading { return "Saving \(name) for offline" }
        if savedCount > 0 { return "Part of \(name) is saved for offline" }
        return "\(name) is not yet saved for offline"
    }

    private var offlineDetail: String {
        if loadFailed { return "Check your connection" }
        return monthFullySaved
            ? "\(monthDayCount) days · all eight hours"
            : "\(savedCount) of \(monthDayCount) days on this device · eight hours each"
    }

    /// A day counts as saved only when every one of its hours is here.
    /// Half a day is no use in a chapel with no signal, and saying "12
    /// of 31" while nine of those twelve are missing Matins would be a
    /// lie of the kind this row exists to avoid.
    private func refreshSavedCount() {
        savedCount = monthDates.filter { isSaved(OfficeAPIService.dayString(for: $0)) }.count
    }

    private func isSaved(_ dayKey: String) -> Bool {
        let cache = OfficeCacheService.shared
        guard cache.hasDay(for: dayKey) else { return false }
        return CanonicalHour.allCases.allSatisfy { cache.hasHour(for: dayKey, hour: $0) }
    }

    // MARK: - Saving the month

    /// Puts down the download in flight and retires its token, so
    /// nothing it does on the way out can speak for the month now on
    /// screen.
    private func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadGeneration &+= 1
        isDownloading = false
    }

    /// Fetches the month's missing days one by one, quietly; whatever
    /// lands before a failure stays saved. Sequential on purpose — a
    /// month is eight hours a day, and none of them should race the
    /// reader's own page for the connection.
    private func downloadMonth() {
        guard !isDownloading else { return }
        isDownloading = true

        downloadGeneration &+= 1
        let generation = downloadGeneration

        let missing = monthDates
            .map { OfficeAPIService.dayString(for: $0) }
            .filter { !isSaved($0) }

        downloadTask = Task {
            let api = OfficeAPIService.shared
            let cache = OfficeCacheService.shared

            for dayKey in missing {
                guard !Task.isCancelled else { break }

                if !cache.hasDay(for: dayKey),
                   let fetched = try? await api.fetchDay(day: dayKey) {
                    cache.saveDay(fetched, for: dayKey)
                }

                for hour in CanonicalHour.allCases {
                    guard !Task.isCancelled else { break }
                    guard !cache.hasHour(for: dayKey, hour: hour) else { continue }
                    if let fetched = try? await api.fetchHour(day: dayKey, hour: hour) {
                        cache.saveHour(fetched, for: dayKey, hour: hour)
                    }
                }

                // Count up rather than re-walk: a full sweep stats every
                // day of the month times eight, and calling it once per
                // day made saving a month a quadratic pile of file
                // checks on the main actor. The sweep at the end still
                // settles the true figure.
                if generation == downloadGeneration, isSaved(dayKey) {
                    savedCount += 1
                }
            }

            // Only the download still holding the token may report. A
            // cancelled one unwinds after the reader has stepped the
            // month and perhaps started saving that one; without this
            // its tail cleared the new download's spinner and left SAVE
            // showing over a reading in flight.
            guard generation == downloadGeneration else { return }
            isDownloading = false
            refreshSavedCount()
        }
    }

    // MARK: - Calendar Data

    /// Loads the visible month's calendar.
    ///
    /// A month is recorded as loaded only once it has actually arrived.
    /// Marking it before the fetch — which is what this did — meant one
    /// failed request left the month permanently blank: every retry
    /// returned on the guard, and the sheet said nothing was wrong.
    private func loadMonth(retrying: Bool = false) async {
        let year = calendar.component(.year, from: month)
        let monthNumber = calendar.component(.month, from: month)
        let key = "\(year)-\(monthNumber)"
        let requested = month

        guard retrying || !loadedMonths.contains(key) else { return }

        isLoading = true
        loadFailed = false

        let entries = await monthEntries(year: year, month: monthNumber)

        // The reader may have stepped away while this was in flight; a
        // late answer must not draw over the month now on screen.
        guard requested == month else { return }

        isLoading = false
        if entries.isEmpty {
            loadFailed = true
            return
        }

        loadedMonths.insert(key)
        for day in entries {
            days[day.date] = day
        }
    }

    private func monthEntries(year: Int, month: Int) async -> [OfficeDay] {
        if let stored = OfficeCacheService.shared.loadCalendar(year: year, month: month) {
            return stored.days
        }
        guard let fetched = try? await OfficeAPIService.shared.fetchCalendar(year: year, month: month) else {
            return []
        }
        OfficeCacheService.shared.saveCalendar(fetched)
        return fetched.days
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            OfficeCalendarSheet { _ in }
                .presentationDetents([.height(560)])
        }
}
