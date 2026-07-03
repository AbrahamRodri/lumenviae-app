//
//  ReminderSettingsSheet.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  REMINDER SETTINGS SHEET - QUICK ACCESS FROM THE HOME HEADER BELL
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Presented when the user taps the bell in the home header. Exposes the
//  same daily reminder settings as the Account tab (shared UserSettings),
//  reusing ToggleRow and ReminderTimeRow from AccountView.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - ReminderSettingsSheet

struct ReminderSettingsSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.gold)

                        Text("Daily Reminders")
                            .font(AppFonts.headlineFont(22))
                            .foregroundColor(AppColors.cream)

                        Text("A gentle call to prayer, once a day.")
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 28)

                    // Settings card (same rows as the Account tab)
                    VStack(spacing: 0) {
                        ToggleRow(
                            icon: "bell",
                            title: "Daily Reminders",
                            subtitle: userSettings.remindersEnabled
                                ? userSettings.reminderTimeLabel
                                : "Off",
                            isOn: Bindable(userSettings).remindersEnabled
                        )

                        if userSettings.remindersEnabled {
                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            ReminderTimeRow(
                                hour: Bindable(userSettings).reminderHour,
                                minute: Bindable(userSettings).reminderMinute
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: userSettings.remindersEnabled)
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    // Permission hint when reminders are on but iOS denied access
                    if userSettings.remindersEnabled && !userSettings.notificationAuthorizationGranted {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.gold.opacity(0.8))

                            Text("Notifications look disabled for Lumen Viae. Enable them in Settings → Notifications so reminders can reach you.")
                                .font(AppFonts.bodyFont(12))
                                .foregroundColor(AppColors.cream.opacity(0.75))
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.cardBackground.opacity(0.8))
                        )
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    Text("You can also change this anytime in Account → Devotion.")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Preview

#Preview {
    ReminderSettingsSheet()
        .environment(UserSettings.shared)
}
