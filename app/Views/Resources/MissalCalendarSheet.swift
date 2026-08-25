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
//  The year's calendar is fetched once and kept on disk beside the
//  cached propers.
//

import SwiftUI

struct MissalCalendarSheet: View {

    /// Called with the chosen date; the sheet dismisses itself.
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    /// First day of the displayed month
    @State private var month: Date

    /// The 1962 calendar, keyed "yyyy-MM-dd"
    @State private var days: [String: MissalCalendarDay] = [:]

    /// Years already loaded (or attempted) this presentation
    @State private var loadedYears: Set<Int> = []

    /// How many of the month's days are cached on disk
    @State private var savedCount = 0

    /// The day being read out under the grid — the one under the
    /// finger while a cell is pressed, today's the rest of the time.
    @State private var focused: Date?

    /// The in-flight month download, if any
    @State private var downloadTask: Task<Void, Never>?
    @State private var isDownloading = false

    private let calendar = Calendar.current

    init(onSelect: @escaping (Date) -> Void) {
        self.onSelect = onSelect
        let now = Calendar.current.startOfDay(for: .now)
        let components = Calendar.current.dateComponents([.year, .month], from: now)
        _month = State(initialValue: Calendar.current.date(from: components) ?? now)
    }

    // MARK: - Body

    var body: some View {
        MissalSheetShell(title: "") {
            VStack(spacing: 0) {
                monthHeader

                OrnamentDivider()
                    .frame(width: 118)
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                weekdayRow
                    .padding(.bottom, 8)

                dayGrid

                feastLine
                    .padding(.top, 12)

                offlineRow
                    .padding(.top, 16)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.1))
                            .frame(height: 0.5)
                    }
                    .padding(.top, 18)
            }
        }
        .task { await loadYears() }
        .onChange(of: month) {
            Task { await loadYears() }
            refreshSavedCount()
        }
        .onAppear { refreshSavedCount() }
        .onDisappear { downloadTask?.cancel() }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            PrayerHeaderButton(icon: "ph-caret-left", size: 14, label: "Previous month") {
                step(by: -1)
            }

            Spacer()

            Text(monthTitle)
                .font(AppFonts.headlineFont(12))
                .tracking(3.5)
                .foregroundColor(AppColors.gold)

            Spacer()

            PrayerHeaderButton(icon: "ph-caret-right", size: 14, label: "Next month") {
                step(by: 1)
            }
        }
    }

    /// "AUGUST MMXXVI" — the month in words, the year in numerals a
    /// missal would carve.
    private var monthTitle: String {
        let name = Self.monthFormatter.string(from: month).uppercased()
        let year = calendar.component(.year, from: month)
        return "\(name) \(Self.roman(year))"
    }

    private func step(by value: Int) {
        guard let stepped = calendar.date(byAdding: .month, value: value, to: month) else { return }
        downloadTask?.cancel()
        isDownloading = false
        month = stepped
    }

    // MARK: - Weekdays

    /// Weekday letters in the user's own week order
    private var weekdayLetters: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }

    private var weekdayRow: some View {
        HStack(spacing: 2) {
            ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, letter in
                Text(letter)
                    .font(AppFonts.labelFont(9))
                    .tracking(1)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Day Grid

    /// The month's dates padded to full weeks — nil for the blank
    /// leading and trailing cells.
    private var gridDates: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: month)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: month))
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(gridDates.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 42)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let entry = days[MissalAPIService.dayString(for: date)]
        let vestment = entry?.colors?.first.flatMap { MissalVestment(rawValue: $0) }

        return Button {
            onSelect(date)
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(isToday ? AppFonts.semiboldBodyFont(14) : AppFonts.readingFont(14))
                    .foregroundColor(isToday ? AppColors.gold : AppColors.cream)

                Circle()
                    .fill(vestment?.swatch ?? .clear)
                    .frame(width: 5, height: 5)
                    .opacity(isToday ? 1 : 0.65)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isToday ? AppColors.gold.opacity(0.09) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isToday ? AppColors.gold.opacity(0.55) : Color.clear,
                        lineWidth: 0.5
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        // Reading the feast out under the grid on touch-down, not on a
        // second tap: pressing a day names it, lifting opens it — the
        // way a finger runs down the ribbon of a printed missal. One
        // tap still opens the Mass.
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if focused != date { focused = date }
                }
        )
        .accessibilityLabel(feastLabel(date, entry: entry))
    }

    // MARK: - Feast Line

    /// What the old day list answered — "what feast is this Sunday?" —
    /// without a row per day: the calendar's own title for whichever
    /// day is under the finger, today's until one is.
    private var feastLine: some View {
        let date = focused ?? Date()
        let entry = days[MissalAPIService.dayString(for: date)]

        return VStack(spacing: 3) {
            Text(Self.feastDateFormatter.string(from: date).uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.7))

            Text(entry?.title ?? "—")
                .font(AppFonts.headlineFont(15))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 46)
        .animation(.timingCurve(0, 0, 0.58, 1, duration: 0.18), value: date)
        .accessibilityHidden(true)
    }

    /// The spoken name of a cell: the date, then the feast the calendar
    /// gives it — a dot of colour tells a sighted reader nothing about
    /// which feast it is, and told VoiceOver nothing at all.
    private func feastLabel(_ date: Date, entry: MissalCalendarDay?) -> String {
        let day = Self.accessibilityFormatter.string(from: date)
        guard let title = entry?.title, !title.isEmpty else { return day }
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
                .accessibilityLabel("Save \(Self.monthFormatter.string(from: month)) for offline")
            }
        }
        .frame(minHeight: 44)
    }

    private var monthDayCount: Int {
        calendar.range(of: .day, in: .month, for: month)?.count ?? 0
    }

    private var monthFullySaved: Bool {
        monthDayCount > 0 && savedCount >= monthDayCount
    }

    private var offlineTitle: String {
        let name = Self.monthFormatter.string(from: month)
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

    private var monthDates: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    }

    /// Fetches the month's missing days one by one, quietly; whatever
    /// lands before a failure stays saved.
    private func downloadMonth() {
        guard !isDownloading else { return }
        isDownloading = true

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
                    savedCount += 1
                }
            }
            if MissalCacheService.shared.loadOrdo() == nil,
               let ordo = try? await MissalAPIService.shared.fetchOrdo() {
                MissalCacheService.shared.saveOrdo(ordo)
            }
            isDownloading = false
            refreshSavedCount()
        }
    }

    // MARK: - Calendar Data

    /// Loads the 1962 calendar for the visible month's year, once.
    private func loadYears() async {
        let year = calendar.component(.year, from: month)
        guard !loadedYears.contains(year) else { return }
        loadedYears.insert(year)

        for day in await yearEntries(year) {
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

    // MARK: - Formatters

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    /// "TUESDAY · 25 AUGUST"
    private static let feastDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE '·' d MMMM"
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    /// 2026 → "MMXXVI"
    private static func roman(_ number: Int) -> String {
        let values: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]
        var remainder = max(0, number)
        var result = ""
        for (value, numeral) in values {
            while remainder >= value {
                result += numeral
                remainder -= value
            }
        }
        return result
    }
}

// MARK: - Preview

#Preview {
    MissalCalendarSheet { _ in }
}
