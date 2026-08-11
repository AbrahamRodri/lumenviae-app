//
//  PrayerIntentionSheet.swift
//  Lumen Viae
//
//  Editor for "What draws you here" — the intentions first chosen during
//  onboarding. They decide which pool of copy the daily reminder draws
//  from (see ReminderMessages.swift), so this has to stay changeable: what
//  drew someone to the Rosary in their first week is rarely what keeps
//  them at it a year on.
//
//  Multi-select, and selecting nothing is allowed — reminders simply fall
//  back to the neutral pool.
//

import SwiftUI

// MARK: - PrayerIntentionSheet

struct PrayerIntentionSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    /// The same detail lines the onboarding slide uses.
    private let details: [PrayerIntention: String] = [
        .peace: "Quiet moments in a busy life",
        .habit: "A faithful daily rhythm of prayer",
        .devotion: "Deepen your Marian devotion",
        .learning: "New to the Rosary, or returning after a while"
    ]

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        AppIcon("ph-heart", size: 32)
                            .foregroundColor(AppColors.gold)

                        Text("What Draws You Here")
                            .font(AppFonts.headlineFont(22))
                            .foregroundColor(AppColors.cream)

                        Text("Choose as many as are true. Your reminders follow.")
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    VStack(spacing: 0) {
                        ForEach(Array(PrayerIntention.allCases.enumerated()), id: \.element.id) { index, intention in
                            IntentionRow(
                                label: intention.rawValue,
                                detail: details[intention] ?? "",
                                isSelected: userSettings.hasIntention(intention)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    userSettings.toggleIntention(intention)
                                }
                            }

                            if index < PrayerIntention.allCases.count - 1 {
                                Divider()
                                    .background(AppColors.gold.opacity(0.2))
                            }
                        }
                    }
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    Text("Choose none and reminders keep to a gentle default.")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - IntentionRow

private struct IntentionRow: View {

    let label: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                AppIcon(isSelected ? "ph-check-circle-fill" : "ph-circle", size: 20)
                    .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary.opacity(0.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)

                    Text(detail)
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    PrayerIntentionSheet()
        .environment(UserSettings.shared)
}
