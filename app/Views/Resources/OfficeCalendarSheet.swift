//
//  OfficeCalendarSheet.swift
//  Lumen Viae
//
//  The coming weeks of the breviary's calendar under the 1960 rubrics.
//  Tap a day to open its hours, or jump straight to any date. Months
//  are fetched whole and kept on disk beside the cached hours.
//

import SwiftUI

struct OfficeCalendarSheet: View {

    /// How far ahead the list looks
    private static let daysAhead = 35

    /// Called with the chosen date; the sheet dismisses itself.
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var rows: [Row] = []
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var jumpDate = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    private struct Row: Identifiable {
        let date: Date
        let day: OfficeDay
        var id: String { day.id }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            jumpRow
                .padding(.horizontal, 24)
                .padding(.top, 16)

            if isLoading && rows.isEmpty {
                loadingState
            } else if loadFailed && rows.isEmpty {
                errorState
            } else {
                dayList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background.ignoresSafeArea())
        .task { await loadCalendar() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("THE BREVIARY'S CALENDAR")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.7))

                Text("The days ahead")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                AppIcon("ph-x", size: 15)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.leading, 24)
        .padding(.trailing, 10)
        .padding(.top, 14)
    }

    /// A date picker for anywhere the list doesn't reach
    private var jumpRow: some View {
        HStack {
            Text("JUMP TO A DATE")
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            Spacer()

            DatePicker("Jump to a date", selection: $jumpDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppColors.gold)
                .onChange(of: jumpDate) { _, newValue in
                    choose(newValue)
                }
        }
    }

    // MARK: - Day List

    private var dayList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows) { row in
                    dayRow(row)

                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: 0.5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private func dayRow(_ row: Row) -> some View {
        let isSunday = calendar.component(.weekday, from: row.date) == 1
        // Sundays and the higher classes stand out of the run of ferias
        let rank = row.day.celebration?.rank ?? ""
        let isNotable = isSunday || rank.hasPrefix("I.") || rank.hasPrefix("II.")

        return Button {
            choose(row.date)
        } label: {
            HStack(spacing: 14) {
                VStack(spacing: 1) {
                    Text(Self.weekdayFormatter.string(from: row.date).uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                        .foregroundColor(isSunday ? AppColors.gold : AppColors.textSecondary)

                    Text(Self.dayNumberFormatter.string(from: row.date))
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream.opacity(isNotable ? 1 : 0.75))
                }
                .frame(width: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.day.celebration?.title ?? row.day.detail?.text ?? "Feria")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(isNotable ? AppColors.cream : AppColors.cream.opacity(0.75))
                        .multilineTextAlignment(.leading)

                    // A commemoration line beneath a titled day, the way
                    // the engine's own calendar prints one
                    if row.day.celebration != nil,
                       let detail = row.day.detail, detail.label != "Tempora",
                       let text = detail.text {
                        Text(text)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                if let rank = row.day.celebration?.rank {
                    Text(rank.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.2)
                        .foregroundColor(AppColors.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            ProgressView()
                .tint(AppColors.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Text("The calendar could not be reached.")
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.textSecondary)

            QuietGoldButton(
                title: "Try again",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 11,
                size: 10,
                color: AppColors.gold
            ) {
                Task { await loadCalendar() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }

    // MARK: - Loading

    private func choose(_ date: Date) {
        onSelect(date)
        dismiss()
    }

    private func loadCalendar() async {
        guard rows.isEmpty else { return }
        isLoading = true
        loadFailed = false

        let today = calendar.startOfDay(for: .now)

        // The horizon's months — this one, and the next when the list
        // crosses into it
        var months: [(year: Int, month: Int)] = []
        for offset in [0, Self.daysAhead - 1] {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let pair = (calendar.component(.year, from: date), calendar.component(.month, from: date))
            if !months.contains(where: { $0 == pair }) {
                months.append(pair)
            }
        }

        var entries: [String: OfficeDay] = [:]
        for (year, month) in months {
            for day in await monthEntries(year: year, month: month) {
                entries[day.date] = day
            }
        }

        var built: [Row] = []
        for offset in 0..<Self.daysAhead {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today),
                  let day = entries[OfficeAPIService.dayString(for: date)] else { continue }
            built.append(Row(date: date, day: day))
        }

        rows = built
        loadFailed = built.isEmpty
        isLoading = false
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

    // MARK: - Formatters

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    OfficeCalendarSheet { _ in }
}
