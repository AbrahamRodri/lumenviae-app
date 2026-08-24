//
//  MissalCalendarSheet.swift
//  Lumen Viae
//
//  "What feast is this Sunday?" — the coming weeks of the 1962
//  calendar. Tap a day to open its Mass, or jump straight to any date.
//  The year's calendar is fetched once and kept on disk beside the
//  cached propers.
//

import SwiftUI

struct MissalCalendarSheet: View {

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
        let day: MissalCalendarDay
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
                Text("THE 1962 CALENDAR")
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
        let vestment = row.day.colors?.first.flatMap { MissalVestment(rawValue: $0) }
        let isSunday = calendar.component(.weekday, from: row.date) == 1
        // Sundays and feasts stand out of the run of ferias
        let isNotable = isSunday || (row.day.rank ?? 4) <= 2

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

                if let vestment {
                    Circle()
                        .fill(vestment.swatch)
                        .frame(width: 6, height: 6)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.day.title)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(isNotable ? AppColors.cream : AppColors.cream.opacity(0.75))
                        .multilineTextAlignment(.leading)

                    if let commemorations = row.day.commemorations, !commemorations.isEmpty {
                        Text("Comm. \(commemorations.map(\.title).joined(separator: " · "))")
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                if let rankLabel = row.day.rankLabel {
                    Text(rankLabel.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.2)
                        .foregroundColor(AppColors.textSecondary.opacity(0.8))
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
        let year = calendar.component(.year, from: today)

        var entries: [String: MissalCalendarDay] = [:]
        for candidate in [year, year + 1] {
            // The next year matters only when the horizon crosses Dec 31
            guard candidate == year || calendar.component(.month, from: today) == 12 else { continue }
            for day in await yearEntries(candidate) {
                entries[day.id] = day
            }
        }

        var built: [Row] = []
        for offset in 0..<Self.daysAhead {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today),
                  let day = entries[MissalAPIService.dayString(for: date)] else { continue }
            built.append(Row(date: date, day: day))
        }

        rows = built
        loadFailed = built.isEmpty
        isLoading = false
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
    MissalCalendarSheet { _ in }
}
