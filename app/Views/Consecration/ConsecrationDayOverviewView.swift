//
//  ConsecrationDayOverviewView.swift
//  Lumen Viae
//
//  Auto-loads today's day based on the start date.
//  Shows the day number, phase info, what's included, and a button to start.
//

import SwiftUI

// MARK: - ConsecrationDayOverviewView

struct ConsecrationDayOverviewView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath
    @Environment(ConsecrationViewModel.self) private var viewModel

    /// Optional specific day to view (for viewing past days)
    var dayNumber: Int?

    // MARK: - Computed Properties

    private var displayDayNumber: Int {
        dayNumber ?? viewModel.todaysDayNumber
    }

    private var day: ConsecrationDay? {
        ConsecrationData.day(displayDayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    private var isToday: Bool {
        displayDayNumber == viewModel.todaysDayNumber
    }

    private var isCompleted: Bool {
        viewModel.isDayCompleted(displayDayNumber)
    }

    private var prayers: [ConsecrationPrayer] {
        guard let phase = phase else { return [] }
        return ConsecrationData.prayers(for: phase)
    }

    private var consecrationDateFormatted: String {
        guard let progress = viewModel.progress else { return "" }
        let calendar = Calendar.current
        if let consecrationDate = calendar.date(byAdding: .day, value: 33, to: progress.startDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: consecrationDate)
        }
        return ""
    }

    private var phaseProgressText: String {
        guard let day = day, let phase = phase else { return "" }
        return "Day \(day.dayWithinPhase) of \(phase.dayCount)"
    }

    // MARK: - State

    @State private var showDebugControls: Bool = false
    @State private var showRestartConfirm: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background — each phase carries its own quiet tint so the
            // 33-day journey visibly progresses
            if let phase {
                LinearGradient(
                    colors: phase.gradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                AppColors.appGradient
                    .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // Hero Section - Day Number
                    heroSection

                    Spacer()
                        .frame(height: 40)

                    // Phase Card
                    phaseCard

                    Spacer()
                        .frame(height: 16)

                    // Consecration Date (compact)
                    if !consecrationDateFormatted.isEmpty {
                        consecrationDateCard
                    }

                    // Journey strip — revisit any past day (only at the root;
                    // pushed past-day views stay focused on their one day)
                    if dayNumber == nil {
                        Spacer()
                            .frame(height: 16)
                        journeySection
                    }

                    Spacer()
                        .frame(height: 32)

                    // Start Button
                    startButton

                    // Restart / start over (root only)
                    if dayNumber == nil {
                        Spacer()
                            .frame(height: 28)
                        restartSection
                    }

                    // Debug Controls (for testing)
                    #if DEBUG
                    Spacer()
                        .frame(height: 24)
                    debugControls
                    #endif

                    Spacer()
                        .frame(height: 120)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let dayNumber = dayNumber {
                viewModel.loadDay(dayNumber)
            } else {
                viewModel.loadCurrentDay()
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Day Number - Large and prominent
            VStack(spacing: 4) {
                Text("DAY")
                    .font(AppFonts.bodyFont(14))
                    .tracking(4)
                    .foregroundColor(AppColors.gold)

                Text("\(displayDayNumber)")
                    .font(.system(size: 72, weight: .light, design: .serif))
                    .foregroundColor(AppColors.cream)

                Text("of 34")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }

            // Completed badge if applicable
            if isCompleted {
                HStack(spacing: 6) {
                    AppIcon("ph-check-circle-fill", size: 14)
                    Text("Completed")
                        .font(AppFonts.bodyFont(14))
                }
                .foregroundColor(AppColors.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppColors.gold.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Phase Card

    private var phaseCard: some View {
        VStack(spacing: 16) {
            // Phase Header
            VStack(spacing: 6) {
                Text(phase?.displayName.uppercased() ?? "")
                    .font(AppFonts.bodyFont(11))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Text(phase?.subtitle ?? "")
                    .font(AppFonts.headlineFont(18))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
            }

            // Phase Progress (Day X of Y in this phase)
            if let day = day, phase != nil {
                VStack(spacing: 8) {
                    // Phase progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.cardBackground.opacity(0.8))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(phase?.accentColor ?? AppColors.gold)
                                .frame(width: geometry.size.width * day.phaseProgress)
                        }
                    }
                    .frame(height: 4)

                    Text(phaseProgressText)
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.gold.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Consecration Date Card

    private var consecrationDateCard: some View {
        HStack(spacing: 16) {
            AppIcon("ph-calendar-dots", size: 24)
                .foregroundColor(AppColors.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("CONSECRATION")
                    .font(AppFonts.bodyFont(10))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)

                Text(consecrationDateFormatted)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream)
            }

            Spacer()

            // Overall progress indicator
            Text("\(Int(viewModel.progressPercentage * 100))%")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.gold)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground.opacity(0.6))
        )
    }

    // MARK: - Journey Strip

    /// One tappable chip per day: completed days show a check, missed days
    /// stay reachable, future days are locked. This is how a user who
    /// missed Day 14 gets back to it.
    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR JOURNEY")
                .font(AppFonts.bodyFont(11))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...34, id: \.self) { day in
                            journeyDayChip(day)
                                .id(day)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onAppear {
                    proxy.scrollTo(viewModel.todaysDayNumber, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func journeyDayChip(_ day: Int) -> some View {
        let completed = viewModel.isDayCompleted(day)
        let accessible = viewModel.canAccessDay(day)
        let isCurrent = day == viewModel.todaysDayNumber

        return Button {
            guard accessible else { return }
            if day == viewModel.todaysDayNumber {
                viewModel.loadCurrentDay()
            } else {
                path.append(ConsecrationRoute.dayOverview(dayNumber: day))
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(
                        completed
                            ? AppColors.background
                            : (accessible ? AppColors.cream : AppColors.textSecondary.opacity(0.5))
                    )

                if completed {
                    AppIcon("ph-check", size: 8)
                        .foregroundColor(AppColors.background.opacity(0.8))
                }
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(completed ? AppColors.gold : AppColors.cardBackground.opacity(accessible ? 0.9 : 0.4))
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        isCurrent ? AppColors.goldLight : AppColors.gold.opacity(accessible ? 0.35 : 0.1),
                        lineWidth: isCurrent ? 1.5 : 0.5
                    )
            )
        }
        .disabled(!accessible)
        .accessibilityLabel(
            "Day \(day)\(completed ? ", completed" : "")\(isCurrent ? ", today" : "")\(accessible ? "" : ", locked")"
        )
    }

    // MARK: - Restart

    private var restartSection: some View {
        Button {
            showRestartConfirm = true
        } label: {
            Text("Restart Consecration")
                .font(AppFonts.bodyFont(13))
                .foregroundColor(AppColors.textSecondary)
                .underline()
        }
        .confirmationDialog(
            "Restart your consecration?",
            isPresented: $showRestartConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase Progress and Start Over", role: .destructive) {
                viewModel.abandonConsecration()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your day progress will be erased so you can begin again. Journal reflections you have written are kept in your Journal.")
        }
    }

    // MARK: - Start Button

    private var startButtonTitle: String {
        if isCompleted { return "Review Day" }
        return isToday ? "Begin Today's Prayer" : "Complete This Day"
    }

    private var startButton: some View {
        Button {
            viewModel.resetPrayers()
            path.append(ConsecrationRoute.prayerFlow(dayNumber: displayDayNumber))
        } label: {
            HStack(spacing: 10) {
                AppIcon(isCompleted ? "ph-arrow-counter-clockwise" : "ph-play-fill", size: 15)
                    .font(.system(size: 14, weight: .semibold))

                Text(startButtonTitle)
                    .font(AppFonts.headlineFont(16))
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Debug Controls

    #if DEBUG
    private var debugControls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    showDebugControls.toggle()
                }
            } label: {
                HStack {
                    AppIcon("ph-wrench", size: 12)
                    Text("Testing Controls")
                        .font(AppFonts.bodyFont(12))
                    Spacer()
                    AppIcon(showDebugControls ? "ph-caret-up" : "ph-caret-down", size: 12)
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.cardBackground.opacity(0.5))
                )
            }

            if showDebugControls {
                VStack(spacing: 8) {
                    // Advance Day Button
                    Button {
                        viewModel.debugAdvanceDay()
                    } label: {
                        HStack {
                            AppIcon("ph-skip-forward-fill", size: 14)
                            Text("Advance to Next Day")
                                .font(AppFonts.bodyFont(14))
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                        )
                    }

                    // Reset Consecration Button
                    Button {
                        viewModel.debugResetConsecration()
                    } label: {
                        HStack {
                            AppIcon("ph-arrow-counter-clockwise", size: 14)
                            Text("Reset Consecration")
                                .font(AppFonts.bodyFont(14))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                    }

                    // Current day info
                    Text("Start: \(viewModel.progress?.startDate ?? Date(), style: .date)")
                        .font(AppFonts.bodyFont(10))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.cardBackground.opacity(0.3))
                )
            }
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationDayOverviewView(path: .constant(NavigationPath()))
            .environment(ConsecrationViewModel())
    }
}
