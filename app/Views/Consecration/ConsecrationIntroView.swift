//
//  ConsecrationIntroView.swift
//  Lumen Viae
//
//  Shown when the user has no active consecration.
//  Introduces the 33-Day Total Consecration and allows the user to select
//  a feast day to consecrate on. The start date is calculated automatically.
//

import SwiftUI

// MARK: - ConsecrationIntroView

struct ConsecrationIntroView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath
    @Environment(ConsecrationViewModel.self) private var viewModel

    @State private var selectedFeast: MarianFeastDay? = nil
    @State private var showFeastPicker: Bool = false
    @State private var showCustomStart: Bool = false
    @State private var customStartDay: Int = 1

    // MARK: - Computed Properties

    private var sortedFeasts: [MarianFeastDay] {
        MarianFeastDay.sortedByNextOccurrence()
    }

    private var canBeginToday: Bool {
        guard let feast = selectedFeast else { return false }
        return feast.canStartToday()
    }

    /// Catch-up day for a feast whose 33-day preparation window has already
    /// begun but whose feast hasn't passed: the day number today would be so
    /// that Day 34 lands on the feast. Nil when a normal Day-1 start applies.
    private func catchUpDay(for feast: MarianFeastDay) -> Int? {
        guard !feast.canStartToday(),
              let feastDate = feast.nextOccurrence() else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysUntilFeast = calendar.dateComponents(
            [.day],
            from: today,
            to: calendar.startOfDay(for: feastDate)
        ).day ?? 0
        let dayToday = 34 - daysUntilFeast
        guard (2...33).contains(dayToday) else { return nil }
        return dayToday
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Hero Section
                    heroSection

                    // Description
                    descriptionSection

                    // The Four Phases
                    phasesSection

                    // Feast Day Selection
                    feastDaySelectionSection

                    // Begin Button
                    if canBeginToday {
                        beginButton
                    } else if let feast = selectedFeast, let day = catchUpDay(for: feast) {
                        catchUpButton(day: day)
                    }

                    // Custom start (begin at any day)
                    customStartSection

                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Default to first feast (Annunciation is traditional)
            if selectedFeast == nil {
                selectedFeast = MarianFeastDay.find("annunciation")
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Icon
            AppIcon("ph-flame-fill", size: 56)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Title
            Text("33-Day Consecration")
                .font(AppFonts.headlineFont(28))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Total Consecration to Jesus through Mary")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(spacing: 16) {
            Text("A 33-day spiritual preparation to consecrate yourself entirely to Jesus Christ through the hands of the Blessed Virgin Mary.")
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Each day includes prayers, spiritual reading, and journaling to deepen your relationship with Christ and Mary.")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Phases Section

    private var phasesSection: some View {
        VStack(spacing: 12) {
            Text("THE JOURNEY")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            VStack(spacing: 8) {
                phaseRow(number: "1-12", title: "Preparatory Period", subtitle: "Emptying of the World")
                phaseRow(number: "13-19", title: "Week One", subtitle: "Knowledge of Self")
                phaseRow(number: "20-26", title: "Week Two", subtitle: "Knowledge of Mary")
                phaseRow(number: "27-33", title: "Week Three", subtitle: "Knowledge of Jesus")
                phaseRow(number: "34", title: "Consecration Day", subtitle: "Total Consecration")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func phaseRow(number: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Text("Day \(number)")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.gold)
                .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream)
                Text(subtitle)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Feast Day Selection

    private var feastDaySelectionSection: some View {
        VStack(spacing: 16) {
            Text("SELECT CONSECRATION DAY")
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            // Selected feast display
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFeastPicker.toggle()
                }
            } label: {
                HStack {
                    AppIcon("ph-calendar-dots", size: 18)
                        .foregroundColor(AppColors.gold)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedFeast?.name ?? "Select a Feast Day")
                            .font(AppFonts.bodyFont(16))
                            .foregroundColor(AppColors.cream)

                        if let feast = selectedFeast, let date = feast.nextOccurrence() {
                            Text(date, style: .date)
                                .font(AppFonts.bodyFont(12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    AppIcon("ph-caret-down", size: 14)
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(showFeastPicker ? 180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            // Feast picker list
            if showFeastPicker {
                feastPickerList
            }

            // Start date info
            if let feast = selectedFeast {
                startDateInfo(for: feast)
            }
        }
    }

    private var feastPickerList: some View {
        VStack(spacing: 0) {
            ForEach(sortedFeasts) { feast in
                feastRow(feast)

                if feast.id != sortedFeasts.last?.id {
                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
    }

    private func feastRow(_ feast: MarianFeastDay) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFeast = feast
                showFeastPicker = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(feast.name)
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(selectedFeast?.id == feast.id ? AppColors.gold : AppColors.cream)

                    if let date = feast.nextOccurrence() {
                        Text(date, style: .date)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                // Tag showing when user can start
                if feast.canStartToday() {
                    Text("Start Today")
                        .font(AppFonts.bodyFont(10))
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.gold)
                        )
                } else if let day = catchUpDay(for: feast) {
                    Text("Catch Up · Day \(day)")
                        .font(AppFonts.bodyFont(10))
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(AppColors.gold.opacity(0.6), lineWidth: 1)
                        )
                } else if let startDate = feast.nextStartDate() {
                    let daysUntilStart = daysUntil(startDate)
                    Text("in \(daysUntilStart) day\(daysUntilStart == 1 ? "" : "s")")
                        .font(AppFonts.bodyFont(10))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(AppColors.textSecondary.opacity(0.4), lineWidth: 1)
                        )
                }

                if selectedFeast?.id == feast.id {
                    AppIcon("ph-check", size: 14)
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(12)
        }
    }

    /// Calculate days until a given date
    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: target)
        return max(0, components.day ?? 0)
    }

    private func startDateInfo(for feast: MarianFeastDay) -> some View {
        VStack(spacing: 8) {
            if let startDate = feast.nextStartDate(), let feastDate = feast.nextOccurrence() {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day 1 (Start)")
                            .font(AppFonts.bodyFont(10))
                            .foregroundColor(AppColors.textSecondary)
                        Text(startDate, style: .date)
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.cream)
                    }

                    Spacer()

                    AppIcon("ph-arrow-right", size: 15)
                        .foregroundColor(AppColors.gold)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Day 34 (Consecration)")
                            .font(AppFonts.bodyFont(10))
                            .foregroundColor(AppColors.textSecondary)
                        Text(feastDate, style: .date)
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(AppColors.gold)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground.opacity(0.6))
                )

                if feast.canStartToday() {
                    HStack(spacing: 6) {
                        AppIcon("ph-check-circle-fill", size: 13)
                            .foregroundColor(.green)
                        Text("Today is the start date for this feast!")
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(.green)
                    }
                } else if let day = catchUpDay(for: feast) {
                    HStack(spacing: 6) {
                        AppIcon("ph-clock-counter-clockwise", size: 13)
                            .foregroundColor(AppColors.gold)
                        Text("Preparation is underway — begin today at Day \(day)")
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.gold)
                    }
                } else {
                    Text("You can begin on \(startDate, style: .date)")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Begin Button

    private var beginButton: some View {
        Button {
            if let startDate = selectedFeast?.nextStartDate() {
                viewModel.startConsecration(on: startDate)
            }
        } label: {
            HStack {
                Text("Begin Consecration")
                    .font(AppFonts.headlineFont(16))

                AppIcon("ph-arrow-right", size: 15)
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Catch-Up Button

    /// Offered when the 33-day window for the selected feast has already begun.
    /// Starting at a later day lets Day 34 still land on the feast.
    private func catchUpButton(day: Int) -> some View {
        VStack(spacing: 10) {
            Button {
                viewModel.startConsecration(startingAt: day)
            } label: {
                HStack {
                    Text("Begin Today at Day \(day)")
                        .font(AppFonts.headlineFont(16))

                    AppIcon("ph-arrow-right", size: 15)
                }
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("The preparation for this feast has already begun. Start today at Day \(day) and your consecration day will still fall on the feast.")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Custom Start Section

    /// Lets the user begin at any day of the 33-day preparation, independent
    /// of feast alignment (e.g., following along in a book or group).
    private var customStartSection: some View {
        VStack(spacing: 16) {
            // Divider with "OR"
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.25))
                    .frame(height: 1)
                Text("OR")
                    .font(AppFonts.bodyFont(11))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
                Rectangle()
                    .fill(AppColors.gold.opacity(0.25))
                    .frame(height: 1)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustomStart.toggle()
                }
            } label: {
                HStack {
                    AppIcon("ph-calendar-dots", size: 16)
                        .foregroundColor(AppColors.gold)

                    Text("Start at Any Day")
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)

                    Spacer()

                    AppIcon("ph-caret-down", size: 14)
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(showCustomStart ? 180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            if showCustomStart {
                customStartPicker
            }
        }
    }

    private var customStartPicker: some View {
        VStack(spacing: 16) {
            // Day picker
            Picker("Start Day", selection: $customStartDay) {
                ForEach(1...33, id: \.self) { day in
                    Text(customStartLabel(for: day))
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)
                        .tag(day)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .colorScheme(.dark)

            // Phase context for the chosen day
            if let phase = ConsecrationPhase.phase(for: customStartDay) {
                Text("\(phase.displayName) — \(phase.subtitle)")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.gold.opacity(0.8))
            }

            // Resulting consecration date
            Text("Your consecration day will be \(consecrationDate(startingAt: customStartDay), style: .date).")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.startConsecration(startingAt: customStartDay)
            } label: {
                HStack {
                    Text("Begin Today at Day \(customStartDay)")
                        .font(AppFonts.headlineFont(16))

                    AppIcon("ph-arrow-right", size: 15)
                }
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground.opacity(0.6))
        )
    }

    private func customStartLabel(for day: Int) -> String {
        day == 1 ? "Day 1 — from the beginning" : "Day \(day)"
    }

    /// The date Day 34 lands on when today counts as `day`.
    private func consecrationDate(startingAt day: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: 34 - day,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationIntroView(path: .constant(NavigationPath()))
            .environment(ConsecrationViewModel())
    }
}
