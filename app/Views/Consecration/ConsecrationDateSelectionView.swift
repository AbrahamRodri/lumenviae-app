//
//  ConsecrationDateSelectionView.swift
//  Lumen Viae
//
//  The final onboarding step: choosing the consecration day. One clean
//  list of Marian feasts — actionable ones carry a chip — with a fixed
//  bottom bar that always shows the resulting dates and the one action.
//  Starting mid-preparation ("catch up") keeps Day 34 on the feast.
//  A custom start (praying along with a book or group) lives in a sheet
//  so the page itself stays quiet.
//

import SwiftUI

// MARK: - ConsecrationDateSelectionView

struct ConsecrationDateSelectionView: View {

    // MARK: - Properties

    @Environment(ConsecrationViewModel.self) private var viewModel

    @State private var selectedFeast: MarianFeastDay? = nil
    @State private var showCustomStart: Bool = false
    @State private var customStartDay: Int = 1

    // MARK: - Feast Availability

    /// What selecting a feast means today
    private enum FeastAvailability {
        case startToday(Date)      // today is Day 1
        case catchUp(Int)          // window already open — join at this day
        case waitUntil(Date)       // Day 1 is still in the future
    }

    private var sortedFeasts: [MarianFeastDay] {
        MarianFeastDay.sortedByNextOccurrence()
    }

    private func availability(for feast: MarianFeastDay) -> FeastAvailability? {
        if feast.canStartToday(), let start = feast.nextStartDate() {
            return .startToday(start)
        }
        if let day = catchUpDay(for: feast) {
            return .catchUp(day)
        }
        if let start = feast.nextStartDate() {
            return .waitUntil(start)
        }
        return nil
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
        VStack(spacing: 0) {
            header
                .padding(.top, 16)
                .padding(.horizontal, 32)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if let completed = viewModel.completedProgress {
                        completedNote(completed)
                            .padding(.bottom, 8)
                    }

                    ForEach(sortedFeasts) { feast in
                        feastRow(feast)
                    }

                    customStartLink
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            bottomBar
        }
        .onAppear {
            // Default to the nearest feast the user can act on today —
            // start or catch up — rather than one months away; fall back
            // to the next upcoming feast.
            if selectedFeast == nil {
                selectedFeast = sortedFeasts.first {
                    if let a = availability(for: $0) {
                        switch a {
                        case .waitUntil: return false
                        default: return true
                        }
                    }
                    return false
                } ?? sortedFeasts.first
            }
        }
        .sheet(isPresented: $showCustomStart) {
            customStartSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text("Choose Your Feast")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)

            Text("The consecration ends on a feast of Our Lady — your 33 days count back from it.")
                .font(AppFonts.bodyFont(13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Completed Note

    /// One quiet line honoring a finished consecration
    private func completedNote(_ progress: ConsecrationProgress) -> some View {
        HStack(spacing: 6) {
            AppIcon("ph-seal-check-fill", size: 13)

            if let date = progress.completedAt {
                Text("Consecrated \(date, style: .date) — renew whenever you wish")
            } else {
                Text("Consecration completed — renew whenever you wish")
            }
        }
        .font(AppFonts.bodyFont(12))
        .foregroundColor(AppColors.gold)
    }

    // MARK: - Feast Rows

    private func feastRow(_ feast: MarianFeastDay) -> some View {
        let isSelected = selectedFeast?.id == feast.id

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFeast = feast
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(feast.name)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    if let date = feast.nextOccurrence() {
                        Text(date, style: .date)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                availabilityChip(for: feast)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppColors.gold.opacity(0.1) : AppColors.cardBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? AppColors.gold.opacity(0.7) : AppColors.gold.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// A chip only when the feast is actionable today — everything else
    /// stays quiet
    @ViewBuilder
    private func availabilityChip(for feast: MarianFeastDay) -> some View {
        switch availability(for: feast) {
        // A row chip is not a call to action, so it reads as one of a
        // pair with its catch-up sibling rather than as a small gold
        // button competing with the real one at the foot of the screen.
        case .startToday:
            Text("Today")
                .font(AppFonts.bodyFont(11))
                .fontWeight(.semibold)
                .foregroundColor(AppColors.goldLight)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(AppColors.gold.opacity(0.15)))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1))

        case .catchUp(let day):
            Text("Day \(day)")
                .font(AppFonts.bodyFont(11))
                .fontWeight(.semibold)
                .foregroundColor(AppColors.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1))

        default:
            EmptyView()
        }
    }

    // MARK: - Custom Start Link

    private var customStartLink: some View {
        Button {
            showCustomStart = true
        } label: {
            HStack(spacing: 6) {
                Text("Start at any day instead")
                    .font(AppFonts.bodyFont(14))
                AppIcon("ph-caret-right", size: 11)
            }
            .foregroundColor(AppColors.textSecondary)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Bottom Bar

    /// Always shows what the selection means — the resulting dates and
    /// the one action
    @ViewBuilder
    private var bottomBar: some View {
        if let feast = selectedFeast,
           let avail = availability(for: feast),
           let feastDate = feast.nextOccurrence() {
            VStack(spacing: 12) {
                summaryLine(for: avail, feastDate: feastDate)
                actionButton(for: avail, feast: feast)
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 104)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(height: 1)
            }
        }
    }

    private func summaryLine(for avail: FeastAvailability, feastDate: Date) -> some View {
        Group {
            switch avail {
            case .startToday:
                Text("Day 1 · today   →   Day 34 · \(feastDate, style: .date)")
            case .catchUp(let day):
                Text("Day \(day) · today   →   Day 34 · \(feastDate, style: .date)")
            case .waitUntil(let start):
                Text("Day 1 · \(start, style: .date)   →   Day 34 · \(feastDate, style: .date)")
            }
        }
        .font(AppFonts.bodyFont(12))
        .foregroundColor(AppColors.textSecondary)
    }

    @ViewBuilder
    private func actionButton(for avail: FeastAvailability, feast: MarianFeastDay) -> some View {
        switch avail {
        case .startToday(let start):
            goldButton("Begin Consecration") {
                viewModel.startConsecration(on: start)
            }

        case .catchUp(let day):
            goldButton("Begin Today at Day \(day)") {
                viewModel.startConsecration(startingAt: day)
            }

        case .waitUntil(let start):
            // Not actionable yet — state when it becomes so, quietly
            Text("Begins \(start, style: .date)")
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground.opacity(0.6))
                )
        }
    }

    /// Beginning the consecration is the screen's one act, and it comes
    /// from the app's CTA system rather than a third copy of it.
    private func goldButton(_ title: String, action: @escaping () -> Void) -> some View {
        GoldCTAButton(title: title, action: action)
    }

    // MARK: - Custom Start Sheet

    private var customStartSheet: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Start at Any Day")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
                    .padding(.top, 28)

                Text("Praying along with a book or a group? Begin wherever they are.")
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Picker("Start Day", selection: $customStartDay) {
                    ForEach(1...33, id: \.self) { day in
                        Text("Day \(day)")
                            .font(AppFonts.bodyFont(16))
                            .foregroundColor(AppColors.cream)
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .colorScheme(.dark)

                VStack(spacing: 6) {
                    if let phase = ConsecrationPhase.phase(for: customStartDay) {
                        Text("\(phase.displayName) — \(phase.subtitle)")
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.gold.opacity(0.8))
                    }

                    Text("Consecration day: \(consecrationDate(startingAt: customStartDay), style: .date)")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                goldButton("Begin Today at Day \(customStartDay)") {
                    showCustomStart = false
                    viewModel.startConsecration(startingAt: customStartDay)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.visible)
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
