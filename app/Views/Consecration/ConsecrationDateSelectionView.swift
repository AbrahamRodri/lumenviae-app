//
//  ConsecrationDateSelectionView.swift
//  Lumen Viae
//
//  The final onboarding step: choosing the consecration day. The user
//  selects a Marian feast (Day 34) and the start date is calculated
//  automatically — with a catch-up start when the feast's window has
//  already begun, and a custom start for praying along with a book or
//  group. Ported from the original single-page intro.
//

import SwiftUI

// MARK: - ConsecrationDateSelectionView

struct ConsecrationDateSelectionView: View {

    // MARK: - Properties

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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 48)

                VStack(spacing: 14) {
                    Text("SELECT CONSECRATION DAY")
                        .font(AppFonts.bodyFont(12))
                        .tracking(3)
                        .foregroundColor(AppColors.gold)

                    Text("End on a Marian Feast")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)

                    Text("The consecration traditionally concludes on a feast of Our Lady. Choose the feast — your 33 days of preparation count back from it.")
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // A finished consecration is honored, not forgotten
                if let completed = viewModel.completedProgress {
                    Spacer()
                        .frame(height: 24)
                    completedBanner(completed)
                }

                Spacer()
                    .frame(height: 28)

                feastSelector

                if showFeastPicker {
                    Spacer()
                        .frame(height: 12)
                    feastPickerList
                }

                if let feast = selectedFeast {
                    Spacer()
                        .frame(height: 16)
                    startDateInfo(for: feast)
                }

                Spacer()
                    .frame(height: 28)

                if canBeginToday {
                    beginButton
                } else if let feast = selectedFeast, let day = catchUpDay(for: feast) {
                    catchUpButton(day: day)
                }

                Spacer()
                    .frame(height: 28)

                customStartSection

                Spacer()
                    .frame(height: 110)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Default to the nearest feast the user can act on today —
            // start or catch up — rather than one months away; fall back
            // to the next upcoming feast.
            if selectedFeast == nil {
                selectedFeast = sortedFeasts.first {
                    $0.canStartToday() || catchUpDay(for: $0) != nil
                } ?? sortedFeasts.first
            }
        }
    }

    // MARK: - Completed Banner

    /// Shown when a past consecration was completed: honors the date and
    /// frames starting again as a renewal.
    private func completedBanner(_ progress: ConsecrationProgress) -> some View {
        let dateText: String = {
            guard let date = progress.completedAt else { return "" }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }()

        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                AppIcon("ph-seal-check-fill", size: 16)
                Text("Consecration Completed")
                    .font(AppFonts.headlineFont(15))
            }
            .foregroundColor(AppColors.gold)

            if !dateText.isEmpty {
                Text("Totus tuus — consecrated \(dateText)")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.cream.opacity(0.85))
            }

            Text("Many renew their consecration each year. You may begin the preparation again whenever you wish.")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.gold.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Feast Selector

    private var feastSelector: some View {
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
    ZStack {
        AppColors.appGradient.ignoresSafeArea()
        ConsecrationDateSelectionView()
            .environment(ConsecrationViewModel())
    }
}
