//
//  LiturgicalMonthGrid.swift
//  Lumen Viae
//
//  One month of a liturgical calendar as a grid — the shape both the
//  missal's date pill and the breviary's raise. Roman-numeral month at
//  the head, chevrons either side, the weeks below, and under them the
//  day whichever finger is resting names.
//
//  The two books differ in exactly three places, and those are the
//  three this takes from its caller: the mark a day carries (the
//  missal's vestment colour, the office's class), what the day is
//  called, and the honest line about what is saved for offline. Every
//  other part — the stepping, the padding of the weeks, the press-to-
//  name gesture, the numerals — is one calendar drawn twice, and was
//  for a while literally two copies of the same four hundred lines.
//

import SwiftUI

// MARK: - LiturgicalMonthGrid

struct LiturgicalMonthGrid<DayMark: View, Offline: View>: View {

    /// The displayed month, owned by the sheet — stepping it is what
    /// tells the sheet to load and to put down any download in flight.
    @Binding var month: Date

    /// The calendar's own title for a day: a feast, a season line, or
    /// "Feria". Never blank — a day with no answer still gets one.
    let title: (Date) -> String

    /// The spoken name of a cell. A mark of light tells VoiceOver
    /// nothing at all, so the day is read out with what it keeps.
    let spokenTitle: (Date) -> String

    /// Called with the chosen date. The sheet dismisses itself.
    let onSelect: (Date) -> Void

    /// The day's mark, drawn by the book that knows what it means.
    @ViewBuilder let dayMark: (Date, _ isToday: Bool) -> DayMark

    /// The offline line, with its own counts and its own SAVE.
    @ViewBuilder let offline: () -> Offline

    @Environment(\.dismiss) private var dismiss

    /// The day being read out under the grid — the one under the finger
    /// while a cell is pressed, today's the rest of the time.
    @State private var focused: Date?

    private let calendar = Calendar.current

    // MARK: - Body

    var body: some View {
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

            offline()
                .padding(.top, 16)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.1))
                        .frame(height: 0.5)
                }
                .padding(.top, 18)
        }
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

    /// "AUGUST MMXXVI" — the month in words, the year in the numerals a
    /// liturgical book would carve.
    private var monthTitle: String {
        let name = LiturgicalCalendarFormat.monthName.string(from: month).uppercased()
        let year = calendar.component(.year, from: month)
        return "\(name) \(LiturgicalCalendarFormat.roman(year))"
    }

    private func step(by value: Int) {
        guard let stepped = calendar.date(byAdding: .month, value: value, to: month) else { return }
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

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(
                Array(LiturgicalCalendarFormat.gridDates(of: month, calendar: calendar).enumerated()),
                id: \.offset
            ) { _, date in
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

        return Button {
            onSelect(date)
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(isToday ? AppFonts.semiboldBodyFont(14) : AppFonts.readingFont(14))
                    .foregroundColor(isToday ? AppColors.gold : AppColors.cream)

                dayMark(date, isToday)
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
        // Reading the day out under the grid on touch-down, not on a
        // second tap: pressing a day names it, lifting opens it — the
        // way a finger runs down the ribbon of a printed book. One tap
        // still opens the day.
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if focused != date { focused = date }
                }
        )
        .accessibilityLabel(spokenTitle(date))
    }

    // MARK: - Feast Line

    /// What a day list answered — "what is kept this Sunday?" — without
    /// a row per day: the calendar's own title for whichever day is
    /// under the finger, today's until one is.
    private var feastLine: some View {
        // Today's *day*, not this instant. `Date()` here handed the
        // animation below a new value on every pass of the body, which
        // a scroll or a download's progress reports many times a
        // second, and the readout re-animated over nothing.
        let date = focused ?? calendar.startOfDay(for: .now)

        return VStack(spacing: 3) {
            Text(LiturgicalCalendarFormat.feastDate.string(from: date).uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.7))

            Text(title(date))
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
}

// MARK: - LiturgicalCalendarFormat

/// The numerals and date shapes both calendars are set in, and the
/// arithmetic of laying a month out in weeks.
enum LiturgicalCalendarFormat {

    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    /// "TUESDAY · 25 AUGUST"
    static let feastDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE '·' d MMMM"
        return formatter
    }()

    static let spokenDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    /// 2026 → "MMXXVI"
    static func roman(_ number: Int) -> String {
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

    /// Every day of the month, in order.
    static func monthDates(of month: Date, calendar: Calendar) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    }

    /// The month's dates padded to full weeks — nil for the blank
    /// leading and trailing cells.
    static func gridDates(of month: Date, calendar: Calendar) -> [Date?] {
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

    /// The first day of the month a date falls in — where a calendar
    /// sheet opens.
    static func firstOfMonth(containing date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month], from: start)
        return calendar.date(from: components) ?? start
    }
}
