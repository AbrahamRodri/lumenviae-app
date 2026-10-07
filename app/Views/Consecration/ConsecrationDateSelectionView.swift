//
//  ConsecrationDateSelectionView.swift
//  Lumen Viae
//
//  The final onboarding step: choosing the consecration day. The feast
//  chosen stands in one card — the soonest by default — with its
//  Consecration Day and its Day 1; the other feasts are a short ruled
//  list beneath it, three of them until the rest are asked for, and a
//  tap on one moves it into the card. The one act begins on the chosen
//  feast's Day 1: today, or a later day the consecration then waits for
//  on a page of its own (`ConsecrationScheduledView`).
//
//  Only a preparation that can still begin on its Day 1 is offered, so
//  each one runs its full 33 days and ends on its feast. Joining partway
//  — praying along with a book or a group — lives in a sheet, so the
//  page itself stays quiet.
//

import SwiftUI

// MARK: - ConsecrationDateSelectionView

struct ConsecrationDateSelectionView: View {

    // MARK: - Properties

    /// Room beneath the act: clear of the tab bar where it stands, and
    /// of the home indicator where it has stepped aside
    var bottomClearance: CGFloat = 104

    @Environment(ConsecrationViewModel.self) private var viewModel

    /// The feast chosen; until one is, the soonest
    @State private var selectedID: String?
    @State private var showsAllFeasts = false
    @State private var showCustomStart: Bool = false
    @State private var customStartDay: Int = 1

    /// How many other feasts stand before "Show more feasts"
    private static let othersShown = 3

    // MARK: - Body

    var body: some View {
        let preparations = MarianFeastDay.upcomingPreparations()
        let selected = preparations.first { $0.id == selectedID } ?? preparations.first

        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 8)
                        .devotionalEntrance()

                    if let completed = viewModel.completedProgress {
                        completedNote(completed)
                            .padding(.top, 14)
                    }

                    if let selected {
                        chosenCard(selected, isSoonest: selected.id == preparations.first?.id)
                            .padding(.top, 22)
                            .devotionalEntrance(delay: 0.08)

                        otherFeasts(preparations.filter { $0.id != selected.id })
                            .padding(.top, 26)
                            .devotionalEntrance(delay: 0.16)
                    }

                    customStartLink
                        .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The list dissolves into the foot rather than ending on an edge
            .mask(scrollFootFade)

            if let selected {
                foot(selected)
                    .devotionalEntrance(delay: 0.24)
            }
        }
        .sheet(isPresented: $showCustomStart) {
            customStartSheet
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ConsecrationIntroKicker(text: "Your consecration day")

            Text("Choose your feast")
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("The 33 days end on a feast of Mary: your Consecration Day.")
                .font(AppFonts.italicFont(17))
                .foregroundColor(AppColors.accentSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
        .multilineTextAlignment(.center)
    }

    // MARK: - The Chosen Feast

    private func chosenCard(_ preparation: FeastPreparation, isSoonest: Bool) -> some View {
        let days = preparation.daysUntilStart()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                if isSoonest {
                    soonestBadge
                        .transition(.opacity)
                }

                Spacer(minLength: 0)

                FeastRadio(isOn: true)
            }

            Text(preparation.feast.name)
                .font(AppFonts.headlineFont(19))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .padding(.top, 14)

            Text(Self.longDate(preparation.feastDate, weekday: true))
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.accentSoft)
                .contentTransition(.opacity)
                .padding(.top, 4)

            ConsecrationIntroRule(opacity: 0.22)
                .padding(.top, 16)

            dayOneRow(preparation, days: days)
                .padding(.top, 14)
        }
        .animation(Motion.crossfade, value: preparation.id)
        .sacredCard(padding: 18, elevated: true, ruleOpacity: 0.7)
        .haloGlow(AppColors.gold, radius: 8, intensity: 0.12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chosenLabel(preparation, days: days, isSoonest: isSoonest))
    }

    /// Outlined, not filled: the page's one filled gold shape is its act
    private var soonestBadge: some View {
        Text("SOONEST")
            .font(AppFonts.labelFont(10))
            .tracking(2.5)
            .foregroundColor(AppColors.goldLight)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(AppColors.gold.opacity(0.15)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.6), lineWidth: AppLine.hairline))
    }

    /// DAY 1 · its date · how far off. Side by side where they fit, and
    /// the countdown beneath at the larger text sizes.
    private func dayOneRow(_ preparation: FeastPreparation, days: Int) -> some View {
        let label = Text("DAY 1")
            .font(AppFonts.labelFont(10.5))
            .tracking(2.5)
            .foregroundColor(AppColors.gold)

        let date = Text(days == 0 ? "Today" : Self.longDate(preparation.start, weekday: true))
            .font(AppFonts.bodyFont(15))
            .foregroundColor(AppColors.cream)

        let countdown = Text(Self.countdown(days))
            .font(AppFonts.italicFont(15))
            .foregroundColor(AppColors.textSecondary)

        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                label
                date
                Spacer(minLength: 8)
                if days > 0 { countdown }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    label
                    date
                }
                if days > 0 { countdown }
            }
        }
        .contentTransition(.opacity)
    }

    private func chosenLabel(_ preparation: FeastPreparation, days: Int, isSoonest: Bool) -> String {
        var parts = ["Chosen: \(preparation.feast.name), \(Self.longDate(preparation.feastDate, weekday: true))"]
        if isSoonest { parts.append("the soonest") }
        parts.append(days == 0
            ? "Day 1 is today"
            : "Day 1 is \(Self.longDate(preparation.start, weekday: true)), \(Self.countdown(days))")
        return parts.joined(separator: ". ") + "."
    }

    // MARK: - Other Feasts

    private func otherFeasts(_ others: [FeastPreparation]) -> some View {
        let shown = showsAllFeasts ? others : Array(others.prefix(Self.othersShown))

        return VStack(alignment: .leading, spacing: 0) {
            Text("OTHER FEASTS")
                .font(AppFonts.labelFont(10.5))
                .tracking(2.5)
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, 6)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(shown.enumerated()), id: \.element.id) { index, preparation in
                VStack(spacing: 0) {
                    if index > 0 {
                        ConsecrationIntroRule(opacity: 0.12)
                    }
                    feastRow(preparation)
                }
                .transition(.opacity)
            }

            if !showsAllFeasts && others.count > Self.othersShown {
                Button {
                    withAnimation(Motion.crossfade) {
                        showsAllFeasts = true
                    }
                } label: {
                    Text("Show more feasts")
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.gold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(SacredCardButtonStyle())
                .padding(.top, 4)
                .transition(.opacity)
                .accessibilityHint("Shows \(others.count - Self.othersShown) more")
            }
        }
        .animation(Motion.crossfade, value: shown.map(\.id))
    }

    private func feastRow(_ preparation: FeastPreparation) -> some View {
        Button {
            withAnimation(Motion.crossfade) {
                selectedID = preparation.id
            }
        } label: {
            HStack(spacing: 14) {
                FeastRadio(isOn: false)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preparation.feast.name)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Begins \(Self.longDate(preparation.start, weekday: false))")
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                Text(Self.shortDate(preparation.feastDate))
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.accentSoft)
            }
            .frame(minHeight: 52)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(
            "\(preparation.feast.name), \(Self.longDate(preparation.feastDate, weekday: true)). Day 1 is \(Self.longDate(preparation.start, weekday: true))."
        )
        .accessibilityHint("Chooses this feast")
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
            .frame(minHeight: 44)
        }
        .accessibilityHint("For praying along with a book or a group")
    }

    // MARK: - Foot

    /// The page's one act and the line beneath it
    private func foot(_ preparation: FeastPreparation) -> some View {
        let days = preparation.daysUntilStart()

        return VStack(spacing: 10) {
            GoldCTAButton(title: Self.beginTitle(preparation, days: days), glyph: .chevron) {
                viewModel.startConsecration(on: preparation.start)
            }
            .animation(Motion.crossfade, value: preparation.id)

            // True as it stands: a consecration chosen ahead can be put
            // back and another feast chosen until Day 1 (its waiting page
            // offers it); once begun, it can only be restarted
            Text(days == 0
                 ? "Your first day's prayers open right away."
                 : "You can choose another feast until Day 1 begins.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(Motion.crossfade, value: days == 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, bottomClearance)
    }

    private var scrollFootFade: some View {
        VStack(spacing: 0) {
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 24)
        }
    }

    // MARK: - Words for Dates

    /// "Saturday, November 21" — the year only when it is not this one
    static func longDate(_ date: Date, weekday: Bool, today: Date = Date()) -> String {
        var style = Date.FormatStyle.dateTime.month(.wide).day()
        if weekday { style = style.weekday(.wide) }
        if !Calendar.current.isDate(date, equalTo: today, toGranularity: .year) {
            style = style.year()
        }
        return date.formatted(style)
    }

    /// "Nov 21" — the year only when it is not this one
    static func shortDate(_ date: Date, today: Date = Date()) -> String {
        var style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        if !Calendar.current.isDate(date, equalTo: today, toGranularity: .year) {
            style = style.year()
        }
        return date.formatted(style)
    }

    /// "in 12 days", "tomorrow", "today"
    static func countdown(_ days: Int) -> String {
        if days <= 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days) days"
    }

    /// "Begin today", or "Begin on October 19"
    static func beginTitle(_ preparation: FeastPreparation, days: Int, today: Date = Date()) -> String {
        days <= 0
            ? "Begin today"
            : "Begin on \(longDate(preparation.start, weekday: false, today: today))"
    }

    // MARK: - Custom Start Sheet

    private var customStartSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                kicker: "Consecration to Mary",
                title: "Start at Any Day",
                lead: "Praying along with a book or a group? Begin wherever they are."
            )

            VStack(spacing: 14) {
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

                    Text("Consecration Day: \(consecrationDate(startingAt: customStartDay), style: .date)")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }

                GoldCTAButton(title: "Begin today at Day \(customStartDay)", glyph: .chevron) {
                    showCustomStart = false
                    viewModel.startConsecration(startingAt: customStartDay)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SheetMetrics.gutter)

            Spacer(minLength: 0)
        }
        .sheetGround()
        // Taller than the 440 it had: the sheet header keeps room above
        // its kicker for the drag indicator
        .presentationDetents([.height(490)])
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

// MARK: - FeastRadio

/// The chooser's radio: a gold ring with its dot for the feast chosen,
/// a faint empty ring for each of the others
private struct FeastRadio: View {
    let isOn: Bool

    var body: some View {
        let size: CGFloat = isOn ? 22 : 18

        Circle()
            .strokeBorder(
                isOn ? AppColors.gold : AppColors.textSecondary.opacity(0.5),
                lineWidth: isOn ? 1.5 : 1
            )
            .frame(width: size, height: size)
            .overlay {
                if isOn {
                    Circle()
                        .fill(AppColors.gold)
                        .frame(width: 10, height: 10)
                }
            }
            .accessibilityHidden(true)
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
