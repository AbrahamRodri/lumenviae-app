//
//  StreakWidget.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  ═══════════════════════════════════════════════════════════════════════════
//  STREAK WIDGET - DAILY PRAYER CONSISTENCY CARD
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Shows the current prayer streak as a living candle flame, this week's
//  prayer days, and progress toward the next devotional milestone
//  (Triduum, Novena, Consecration...).
//
//  Design rules:
//  - Only completed days are highlighted — missed days are never called
//    out, so a lapse invites rather than shames.
//  - The flame burns bright once today's prayer is done, and rests dim
//    (never extinguished) otherwise.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

struct StreakWidget: View {
    /// Current consecutive days of prayer
    let streak: Int

    /// Whether a Rosary was completed today
    let hasPrayedToday: Bool

    /// Prayer status for the current week, Sunday through Saturday
    let weekStatus: [(date: Date, didPray: Bool)]

    /// Drives the staggered entrance of the week dots
    @State private var dotsAppeared = false

    var body: some View {
        VStack(spacing: 16) {
            // Top row: living flame + streak count
            HStack(spacing: 16) {
                FlameOrb(isLit: hasPrayedToday)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT STREAK")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)

                    Text(streakLabel)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)
                        .contentTransition(.numericText())
                }

                Spacer()

                if hasPrayedToday {
                    HStack(spacing: 6) {
                        AppIcon("ph-check", size: 11)
                        Text("TODAY")
                            .font(AppFonts.labelFont(10))
                            .tracking(1)
                    }
                    .foregroundColor(AppColors.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppColors.goldLight))
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Weekly day dots (Sun-Sat), popping in one by one
            if !weekStatus.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(weekStatus.enumerated()), id: \.offset) { index, day in
                        WeekDayDot(
                            date: day.date,
                            didPray: day.didPray,
                            isToday: Calendar.current.isDateInToday(day.date)
                        )
                        .frame(maxWidth: .infinity)
                        .scaleEffect(dotsAppeared ? 1 : 0.4)
                        .opacity(dotsAppeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.65)
                                .delay(Double(index) * 0.06),
                            value: dotsAppeared
                        )
                    }
                }
            }

            // Next devotional milestone (goal gradient — always an
            // invitation ahead, never a warning about what could be lost)
            if let nextMilestone = StreakMilestone.next(after: streak) {
                MilestoneProgressLine(streak: streak, milestone: nextMilestone)
            }

            // Gentle nudge line
            Text(nudgeMessage)
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 1)
        )
        .onAppear { dotsAppeared = true }
    }

    private var streakLabel: String {
        switch streak {
        case 0: return "Begin Your Streak"
        case 1: return "1 Day of Prayer"
        default: return "\(streak) Days of Prayer"
        }
    }

    private var nudgeMessage: String {
        if hasPrayedToday {
            return "Your light shines today. Well done."
        }
        if streak > 0 {
            return "A quiet moment awaits, whenever you are ready."
        }
        return "Light the first candle — pray today."
    }
}

// MARK: - FlameOrb

/// The streak flame. Burns bright and flickers when today's prayer is
/// done; rests as a dim ember (never extinguished) when it isn't.
struct FlameOrb: View {
    let isLit: Bool

    var body: some View {
        ZStack {
            // Soft glow halo, breathing when lit
            Circle()
                .fill(AppColors.gold.opacity(isLit ? 0.35 : 0.10))
                .frame(width: 50, height: 50)
                .blur(radius: 6)
                .phaseAnimator([1.0, 1.15, 1.0]) { view, scale in
                    view.scaleEffect(isLit ? scale : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 1.6)
                }

            Circle()
                .fill(AppColors.gold.opacity(isLit ? 0.22 : 0.12))
                .frame(width: 50, height: 50)

            // Flickering flame
            AppIcon("ph-flame-fill", size: 22)
                .foregroundStyle(
                    isLit
                        ? LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [AppColors.gold.opacity(0.55), AppColors.gold.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .phaseAnimator([1.0, 1.08, 0.96, 1.05]) { view, scale in
                    view
                        .scaleEffect(isLit ? scale : 1.0, anchor: .bottom)
                } animation: { _ in
                    .easeInOut(duration: 0.5)
                }
        }
    }
}

// MARK: - MilestoneProgressLine

/// Thin progress bar toward the next devotional milestone,
/// e.g. "Novena · 3 days away".
struct MilestoneProgressLine: View {
    let streak: Int
    let milestone: StreakMilestone

    /// Animates the bar filling from zero on appear
    @State private var barAppeared = false

    private var daysAway: Int { milestone.days - streak }

    private var progress: Double {
        StreakMilestone.progressTowardNext(streak: streak)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.gold)

                    Text(milestone.name.uppercased())
                        .font(AppFonts.bodyFont(11))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                }

                Spacer()

                Text(daysAway == 1 ? "1 day away" : "\(daysAway) days away")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.background.opacity(0.6))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.gold, AppColors.goldLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * (barAppeared ? progress : 0)))
                        .animation(.easeOut(duration: 0.9).delay(0.3), value: barAppeared)
                }
            }
            .frame(height: 5)
        }
        .onAppear { barAppeared = true }
    }
}

// MARK: - WeekDayDot

/// A single day in the weekly streak row: weekday initial above a dot.
/// Prayed days glow gold; today is ringed; other days stay neutral.
private struct WeekDayDot: View {
    let date: Date
    let didPray: Bool
    let isToday: Bool

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // Narrow weekday: S, M, T...
        return f
    }()

    var body: some View {
        VStack(spacing: 6) {
            Text(Self.dayFormatter.string(from: date).uppercased())
                .font(AppFonts.bodyFont(10))
                .tracking(1)
                .foregroundColor(isToday ? AppColors.gold : AppColors.textSecondary)

            ZStack {
                Circle()
                    .fill(didPray ? AppColors.gold : AppColors.background.opacity(0.6))
                    .frame(width: 22, height: 22)

                if isToday {
                    Circle()
                        .strokeBorder(AppColors.goldLight, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                }

                if didPray {
                    AppIcon("ph-check", size: 9)
                        .foregroundColor(AppColors.background)
                }
            }
            .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakWidget(
            streak: 6,
            hasPrayedToday: true,
            weekStatus: (0..<7).map { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset - 3, to: Date())!
                return (date: date, didPray: offset < 4)
            }
        )

        StreakWidget(
            streak: 0,
            hasPrayedToday: false,
            weekStatus: (0..<7).map { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset - 3, to: Date())!
                return (date: date, didPray: false)
            }
        )
    }
    .padding(20)
    .background(AppColors.background)
}
