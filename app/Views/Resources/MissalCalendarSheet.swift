//
//  MissalCalendarSheet.swift
//  Lumen Viae
//
//  The date pill's sheet: one month of the 1962 calendar as a grid,
//  each day carrying its vestment colour as a small dot. Tap a day to
//  open its Mass; step months with the chevrons. Beneath the grid, the
//  truth about offline — how much of the month is already on this
//  device, and a way to save the rest.
//
//  The grid itself is `LiturgicalMonthGrid`, which the breviary's
//  calendar draws too; what belongs to the missal alone is the vestment
//  mark, the feast's name, and the offline line.
//
//  The year's calendar is fetched once and kept on disk beside the
//  cached propers.
//

import SwiftUI

struct MissalCalendarSheet: View {

    /// Called with the chosen date; the sheet dismisses itself.
    let onSelect: (Date) -> Void

    /// First day of the displayed month
    @State private var month: Date

    /// The 1962 calendar, keyed "yyyy-MM-dd"
    @State private var days: [String: MissalCalendarDay] = [:]

    /// Years already loaded (or attempted) this presentation
    @State private var loadedYears: Set<Int> = []

    /// How many of the month's days are cached on disk
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
                title: { days[MissalAPIService.dayString(for: $0)]?.title ?? "—" },
                spokenTitle: { spokenTitle($0) },
                onSelect: onSelect,
                dayMark: { date, isToday in dayMark(date, isToday: isToday) },
                offline: { offlineRow }
            )
        }
        .task { await loadYears() }
        .onChange(of: month) {
            // Stepping the month puts down whatever the last one was
            // saving: the reader has moved on, and the row they are
            // looking at is not the one downloading.
            cancelDownload()
            refreshSavedCount()
            Task { await loadYears() }
        }
        .onAppear { refreshSavedCount() }
        .onDisappear { cancelDownload() }
    }

    // MARK: - The day's mark

    /// The vestment the day is kept in, as a small dot.
    private func dayMark(_ date: Date, isToday: Bool) -> some View {
        let entry = days[MissalAPIService.dayString(for: date)]
        let vestment = entry?.colors?.first.flatMap { MissalVestment(rawValue: $0) }

        return Circle()
            .fill(vestment?.swatch ?? .clear)
            .frame(width: 5, height: 5)
            .opacity(isToday ? 1 : 0.65)
    }

    // MARK: - Naming a day

    /// The spoken name of a cell: the date, then the feast the calendar
    /// gives it — a dot of colour tells a sighted reader nothing about
    /// which feast it is, and told VoiceOver nothing at all.
    private func spokenTitle(_ date: Date) -> String {
        let day = LiturgicalCalendarFormat.spokenDate.string(from: date)
        guard let title = days[MissalAPIService.dayString(for: date)]?.title,
              !title.isEmpty else { return day }
        return "\(day). \(title)"
    }

    // MARK: - Offline

    /// The month's offline standing, told honestly: what is saved, and
    /// a way to save the rest. Propers for a date never change, so a
    /// saved month is a settled matter.
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
        if monthFullySaved { return "\(name) is saved for offline" }
        if savedCount > 0 { return "Part of \(name) is saved for offline" }
        return "\(name) is not yet saved for offline"
    }

    private var offlineDetail: String {
        monthFullySaved
            ? "\(monthDayCount) days · propers and the Ordinary"
            : "\(savedCount) of \(monthDayCount) days on this device"
    }

    private func refreshSavedCount() {
        savedCount = monthDates.filter {
            MissalCacheService.shared.hasProper(for: MissalAPIService.dayString(for: $0))
        }.count
    }

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
    /// lands before a failure stays saved.
    private func downloadMonth() {
        guard !isDownloading else { return }
        isDownloading = true

        downloadGeneration &+= 1
        let generation = downloadGeneration

        let missing = monthDates
            .map { MissalAPIService.dayString(for: $0) }
            .filter { !MissalCacheService.shared.hasProper(for: $0) }

        downloadTask = Task {
            for day in missing {
                guard !Task.isCancelled else { break }
                if let fetched = try? await MissalAPIService.shared.fetchPropers(day: day) {
                    MissalCacheService.shared.saveProper(fetched, for: day)
                    // Count up rather than re-walk: `refreshSavedCount`
                    // stats every day of the month, and calling it once
                    // per download made saving a month O(days²) file
                    // checks on the main actor. The sweep at the end
                    // still settles the true figure.
                    if generation == downloadGeneration { savedCount += 1 }
                }
            }
            if MissalCacheService.shared.loadOrdo() == nil,
               let ordo = try? await MissalAPIService.shared.fetchOrdo() {
                MissalCacheService.shared.saveOrdo(ordo)
            }
            // Only the download still holding the token may report. A
            // cancelled one unwinds after the reader has stepped the
            // month and perhaps started saving that one; without this
            // its tail cleared the new download's spinner and left SAVE
            // showing over a fetch in flight.
            guard generation == downloadGeneration else { return }
            isDownloading = false
            refreshSavedCount()
        }
    }

    // MARK: - Calendar Data

    /// Loads the 1962 calendar for the visible month's year.
    ///
    /// A year is recorded as loaded only once it has actually arrived.
    /// Marking it before the fetch meant one failed request left every
    /// month of that year blank for the life of the sheet, with each
    /// step back returning on the guard.
    private func loadYears() async {
        let year = calendar.component(.year, from: month)
        guard !loadedYears.contains(year) else { return }

        let entries = await yearEntries(year)
        guard !entries.isEmpty else { return }

        loadedYears.insert(year)
        for day in entries {
            days[day.id] = day
        }
    }

    private func yearEntries(_ year: Int) async -> [MissalCalendarDay] {
        if let stored = MissalCacheService.shared.loadCalendar(for: year) {
            return stored
        }
        guard let fetched = try? await MissalAPIService.shared.fetchCalendar(year: year) else {
            return []
        }
        MissalCacheService.shared.saveCalendar(fetched, for: year)
        return fetched
    }
}

// MARK: - Preview

#Preview {
    MissalCalendarSheet { _ in }
}
