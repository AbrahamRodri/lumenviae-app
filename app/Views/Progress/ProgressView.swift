//
//  ProgressView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  PROGRESS VIEW - SACRED RECORD OF PRAYER HISTORY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Displays the user's prayer history and statistics:
//  - Monthly calendar showing prayer days
//  - Devotions offered by category
//  - Inspirational scripture quote
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI
import SwiftData

// MARK: - PrayerProgressView

/// The main Progress tab view showing prayer statistics.
struct PrayerProgressView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PrayerSession.completedAt, order: .reverse) private var sessions: [PrayerSession]

    // MARK: - State

    @State private var service: PrayerHistoryService?
    @State private var displayedMonth: Date = Date()

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0d0d1a"),
                    Color(hex: "1a1a2e"),
                    Color(hex: "0d0d1a")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Month Navigation
                    monthNavigationSection

                    // Calendar
                    calendarCard

                    // Devotions Offered
                    devotionsSection

                    // Quote
                    quoteSection

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .onAppear {
            service = PrayerHistoryService(modelContext: modelContext)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Sacred Record")
                .font(AppFonts.italicFont(32))
                .foregroundColor(AppColors.cream)

            Text("LUMEN VIAE")
                .font(AppFonts.bodyFont(12))
                .tracking(4)
                .foregroundColor(AppColors.gold.opacity(0.7))
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationSection: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthName)
                    .font(AppFonts.headlineFont(24))
                    .foregroundColor(AppColors.cream)

                Text(yearString)
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.gold.opacity(0.8))
            }

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.horizontal, 8)
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    private var monthName: String {
        Self.monthFormatter.string(from: displayedMonth)
    }

    private var yearString: String {
        "Anno Domini \(Self.yearFormatter.string(from: displayedMonth))"
    }

    private func previousMonth() {
        withAnimation {
            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }

    private func nextMonth() {
        withAnimation {
            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 16) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                    Text(day)
                        .font(AppFonts.bodyFont(10))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let calendarData = generateCalendarData()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 12) {
                ForEach(calendarData, id: \.id) { day in
                    CalendarDayCell(
                        day: day.dayNumber,
                        isCurrentMonth: day.isCurrentMonth,
                        isToday: day.isToday,
                        prayerCount: day.prayerCount
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
        )
    }

    private func generateCalendarData() -> [CalendarDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get first day of displayed month
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }

        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1

        // Get number of days in month
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        let daysInMonth = range.count

        // Get previous month's days to fill
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
              let previousRange = calendar.range(of: .day, in: .month, for: previousMonth) else { return [] }
        let daysInPreviousMonth = previousRange.count

        var days: [CalendarDay] = []

        // Previous month's trailing days
        for i in 0..<firstWeekday {
            let dayNum = daysInPreviousMonth - firstWeekday + i + 1
            let date = calendar.date(byAdding: .day, value: -(firstWeekday - i), to: firstOfMonth)!
            days.append(CalendarDay(
                dayNumber: dayNum,
                isCurrentMonth: false,
                isToday: false,
                prayerCount: prayerCount(for: date),
                date: date
            ))
        }

        // Current month's days
        for day in 1...daysInMonth {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            let isToday = calendar.isDate(date, inSameDayAs: today)
            days.append(CalendarDay(
                dayNumber: day,
                isCurrentMonth: true,
                isToday: isToday,
                prayerCount: prayerCount(for: date),
                date: date
            ))
        }

        // Next month's leading days (fill to 42 cells for 6 rows)
        let remainingDays = 42 - days.count
        for day in 1...remainingDays {
            let date = calendar.date(byAdding: .day, value: daysInMonth + day - 1, to: firstOfMonth)!
            days.append(CalendarDay(
                dayNumber: day,
                isCurrentMonth: false,
                isToday: false,
                prayerCount: prayerCount(for: date),
                date: date
            ))
        }

        return days
    }

    /// Pre-builds a [startOfDay: count] lookup from all sessions.
    /// O(n) once, instead of O(n) per calendar cell.
    private var prayerCountsByDay: [Date: Int] {
        let cal = Calendar.current
        var counts: [Date: Int] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.completedAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    private func prayerCount(for date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return prayerCountsByDay[startOfDay] ?? 0
    }

    // MARK: - Devotions Section

    private var devotionsSection: some View {
        VStack(spacing: 16) {
            Text("Devotions Offered")
                .font(AppFonts.italicFont(20))
                .foregroundColor(AppColors.gold)

            VStack(spacing: 0) {
                ForEach(Array(devotionRows.enumerated()), id: \.offset) { index, row in
                    DevotionRow(
                        name: row.name,
                        count: row.count,
                        color: row.color
                    )

                    if index < devotionRows.count - 1 {
                        Divider()
                            .background(AppColors.gold.opacity(0.2))
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var devotionRows: [(name: String, count: Int, color: Color)] {
        let categoryBreakdown = service?.rosariesByCategory() ?? [:]
        return [
            ("Joyful Mysteries", categoryBreakdown[.joyful] ?? 0, AppColors.gold),
            ("Sorrowful Mysteries", categoryBreakdown[.sorrowful] ?? 0, AppColors.gold),
            ("Glorious Mysteries", categoryBreakdown[.glorious] ?? 0, AppColors.gold),
            ("Luminous Mysteries", categoryBreakdown[.luminous] ?? 0, AppColors.gold.opacity(0.5)),
            ("Seven Sorrows", 0, AppColors.gold) // Placeholder for future
        ]
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(spacing: 16) {
            // Quotation marks
            Text("❝")
                .font(.system(size: 32))
                .foregroundColor(AppColors.gold.opacity(0.6))

            Text("\"Pray without ceasing. In all things give thanks; for this is the will of God in Christ Jesus concerning you.\"")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 20)

            Text("– 1 THESSALONIANS 5:17-18")
                .font(AppFonts.bodyFont(12))
                .tracking(1)
                .foregroundColor(AppColors.gold.opacity(0.7))
        }
        .padding(.top, 24)
    }
}

// MARK: - CalendarDay Model

struct CalendarDay: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let prayerCount: Int
    let date: Date
}

// MARK: - CalendarDayCell

struct CalendarDayCell: View {
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let prayerCount: Int

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Today circle
                if isToday {
                    Circle()
                        .strokeBorder(AppColors.gold, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }

                Text("\(day)")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(dayTextColor)
            }
            .frame(height: 32)

            // Prayer indicator
            if prayerCount > 0 {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.gold)
                    .rotationEffect(.degrees(180))
            } else {
                Color.clear
                    .frame(height: 8)
            }
        }
        .frame(height: 44)
    }

    private var dayTextColor: Color {
        if !isCurrentMonth {
            return AppColors.textSecondary.opacity(0.4)
        }
        if prayerCount > 0 {
            return AppColors.gold
        }
        return AppColors.cream
    }
}

// MARK: - DevotionRow

struct DevotionRow: View {
    let name: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(name)
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.cream)

            Spacer()

            Text("\(count)")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.gold)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview {
    PrayerProgressView()
        .modelContainer(for: PrayerSession.self, inMemory: true)
}
