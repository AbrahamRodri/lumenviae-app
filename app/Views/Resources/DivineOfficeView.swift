//
//  DivineOfficeView.swift
//  Lumen Viae
//
//  The Divine Office: the pre-Vatican II Breviarium Romanum under the
//  1960 rubrics, served by the Lumen Viae API from the Divinum Officium
//  engine. A day is stepped like turning pages — the same navigator as
//  the missal — and its eight canonical hours wait in a ruled ledger,
//  each named in English with the breviary's own name and its
//  traditional time beside it.
//
//  The ledger never waits on the network: the hours are the hours. Only
//  the day's calendar line travels, and when it cannot be reached the
//  page says so quietly and leaves every hour tappable.
//

import SwiftUI

struct DivineOfficeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = OfficeViewModel()
    @State private var openHour: CanonicalHour?
    @State private var showCalendar = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            content
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        // Not "Menu": the Office is reached from home,
                        // the Library card, Explore, and the Pray tray.
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        .sheet(isPresented: $showCalendar) {
            OfficeCalendarSheet { chosen in
                Task { await viewModel.jump(to: chosen) }
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $openHour) { hour in
            OfficeHourView(viewModel: viewModel, hour: hour)
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                dateNavigator
                    .padding(.bottom, 18)

                dayHeader
                    .padding(.bottom, 10)

                hoursLedger

                endBlock
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Date Navigator

    private var dateNavigator: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                stepButton(icon: "ph-caret-left", label: "Previous day", days: -1)

                // The date is a door to the calendar — the coming
                // feasts, and a jump to any day
                Button {
                    showCalendar = true
                } label: {
                    VStack(spacing: 3) {
                        Text("THE DIVINE OFFICE")
                            .font(AppFonts.labelFont(10))
                            .tracking(2.5)
                            .foregroundColor(AppColors.gold.opacity(0.7))

                        HStack(spacing: 7) {
                            Text(viewModel.dateLabel)
                                .font(AppFonts.headlineFont(19))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            AppIcon("ph-caret-down", size: 9)
                                .foregroundColor(AppColors.gold.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("Open the calendar")

                stepButton(icon: "ph-caret-right", label: "Next day", days: 1)
            }

            if !viewModel.isToday {
                QuietGoldButton(
                    title: "Return to today",
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 10,
                    size: 10
                ) {
                    Task { await viewModel.goToToday() }
                }
            }
        }
        .padding(.top, 8)
    }

    private func stepButton(icon: String, label: String, days: Int) -> some View {
        Button {
            Task { await viewModel.step(by: days) }
        } label: {
            AppIcon(icon, size: 16)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    // MARK: - Day Header

    /// The day's place in the calendar, once known. Loading and failure
    /// both stay quiet — the ledger is the page's substance.
    @ViewBuilder
    private var dayHeader: some View {
        VStack(spacing: 10) {
            if let day = viewModel.day {
                if let tempora = day.detail?.text {
                    Text(tempora.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let celebration = day.celebration {
                    Text(celebration.title)
                        .font(AppFonts.headlineFont(23))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let rank = celebration.rank {
                        Text(rank.uppercased())
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                if let note = day.note {
                    Text(note)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                }
            } else if viewModel.isLoadingDay {
                ProgressView()
                    .tint(AppColors.gold)
                    .padding(.vertical, 14)
            } else if viewModel.dayUnavailable {
                VStack(spacing: 8) {
                    Text("The day's feast could not be reached.")
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)

                    QuietGoldButton(
                        title: "Try again",
                        leadingIcon: "ph-arrow-counter-clockwise",
                        leadingIconSize: 10,
                        size: 10
                    ) {
                        Task { await viewModel.retryDay() }
                    }
                }
            }

            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hours Ledger

    /// The eight canonical hours, ruled like the set page's ledger. On
    /// today's page, a small gold mark stands beside the hour whose
    /// traditional time holds the present moment.
    private var hoursLedger: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(CanonicalHour.allCases) { hour in
                hourRow(hour)

                if hour != CanonicalHour.allCases.last {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.12))
                        .frame(height: 0.5)
                }
            }
        }
    }

    private func hourRow(_ hour: CanonicalHour) -> some View {
        let isPresent = viewModel.presentHour == hour

        return Button {
            openHour = hour
        } label: {
            HStack(spacing: 14) {
                // The present hour's mark — a lit candle beside the line
                // being prayed now, absent on any other day's page
                Circle()
                    .fill(isPresent ? AppColors.gold : Color.clear)
                    .frame(width: 5, height: 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hour.label)
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream.opacity(isPresent ? 1 : 0.85))

                    Text("\(hour.latinName) · \(hour.timeOfDay)")
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(isPresent ? "\(hour.label), the present hour" : hour.label)
    }

    // MARK: - End Block

    private var endBlock: some View {
        VStack(spacing: 16) {
            OrnamentDivider()
                .padding(.horizontal, 30)
                .padding(.top, 24)

            Text("Breviarium Romanum 1962 · texts served by The Divinum Officium Project")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DivineOfficeView()
    }
    .environment(UserSettings.shared)
}
