//
//  ConsecrationDayOverviewView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION DAY OVERVIEW - TODAY'S DAY LANDING PAGE
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Auto-loads today's day based on the start date.
//  Shows the day number, phase info, what's included, and a button to start.
//
//  ═══════════════════════════════════════════════════════════════════════════

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

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - consistent app gradient
            AppColors.appGradient
                .ignoresSafeArea()

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

                    Spacer()
                        .frame(height: 32)

                    // Start Button
                    if !isCompleted || isToday {
                        startButton
                    } else {
                        completedBadge
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
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
            if let day = day, let phase = phase {
                VStack(spacing: 8) {
                    // Phase progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.cardBackground.opacity(0.8))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.gold)
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
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 24))
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

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            viewModel.resetPrayers()
            path.append(ConsecrationRoute.prayerFlow(dayNumber: displayDayNumber))
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCompleted ? "arrow.counterclockwise" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))

                Text(isCompleted ? "Review Day" : "Begin Today's Prayer")
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

    // MARK: - Completed Badge

    private var completedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
            Text("Day Completed")
                .font(AppFonts.headlineFont(16))
        }
        .foregroundColor(AppColors.gold)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.gold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                )
        )
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
                    Image(systemName: "wrench.and.screwdriver")
                    Text("Testing Controls")
                        .font(AppFonts.bodyFont(12))
                    Spacer()
                    Image(systemName: showDebugControls ? "chevron.up" : "chevron.down")
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
                            Image(systemName: "forward.fill")
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
                            Image(systemName: "arrow.counterclockwise")
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
