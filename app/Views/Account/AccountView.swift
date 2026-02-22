//
//  AccountView.swift
//  Lumen Viae
//

import SwiftUI

struct AccountView: View {
    @Environment(UserSettings.self) private var userSettings
    @State private var showOnboarding = false
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpSupport = false

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AccountHeaderView()

                    ProfileSection()
                        .padding(.top, 24)

                    // MARK: Prayer Experience
                    AccountSection(title: "PRAYER EXPERIENCE") {
                        VStack(spacing: 0) {
                            TextSizeRow(value: Bindable(userSettings).textSizeScale)

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            PrayerLanguageRow(
                                selectedLanguage: Bindable(userSettings).prayerLanguagePreference
                            )
                        }
                    }
                    .padding(.top, 24)

                    // MARK: Devotion
                    AccountSection(title: "DEVOTION") {
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
                    }
                    .padding(.top, 24)

                    // MARK: About
                    AccountSection(title: "ABOUT") {
                        VStack(spacing: 0) {
                            ActionRow(icon: "info.circle", title: "About Lumen Viae") {
                                showAbout = true
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            ActionRow(icon: "book.pages", title: "App Introduction") {
                                showOnboarding = true
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            ActionRow(icon: "shield", title: "Privacy Policy") {
                                showPrivacyPolicy = true
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            ActionRow(icon: "questionmark.circle", title: "Help & Support") {
                                showHelpSupport = true
                            }
                        }
                    }
                    .padding(.top, 24)

                    AccountFooter()
                        .padding(.top, 48)
                        .padding(.bottom, 120)
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(onComplete: { showOnboarding = false })
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicySheet()
        }
        .sheet(isPresented: $showHelpSupport) {
            HelpSupportSheet()
        }
    }
}

// MARK: - Account Header

struct AccountHeaderView: View {
    var body: some View {
        HStack {
            Spacer()

            Text("Account")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .overlay(
            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Profile Section

struct ProfileSection: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 80, height: 80)

                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.textSecondary)
            }
            .overlay(
                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
            )

            Text("Faithful Pilgrim")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)
        }
    }
}

// MARK: - Account Section Container

struct AccountSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 20)

            content
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Action Row (tappable, no navigation value)

struct ActionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Text Size Row

struct TextSizeRow: View {
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                Text("Text Size")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                Spacer()
            }

            HStack(spacing: 12) {
                Text("A")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(AppColors.textSecondary)

                Slider(value: $value, in: 0...1)
                    .tint(AppColors.gold)

                Text("A")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Prayer Language Row

struct PrayerLanguageRow: View {
    @Binding var selectedLanguage: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                Text("Prayer Language")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(PrayerLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language.rawValue
                    }) {
                        HStack {
                            Text(language.rawValue)
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(
                                    selectedLanguage == language.rawValue
                                        ? AppColors.gold
                                        : AppColors.cream
                                )

                            Spacer()

                            if selectedLanguage == language.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.gold)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedLanguage == language.rawValue
                                        ? AppColors.gold.opacity(0.15)
                                        : AppColors.cardBackground.opacity(0.3)
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Reminder Time Row

struct ReminderTimeRow: View {
    @Binding var hour: Int
    @Binding var minute: Int

    // Build a Date from current hour/minute for the DatePicker
    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = hour
                comps.minute = minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                hour = comps.hour ?? 6
                minute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 18))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)

            Text("Reminder Time")
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream)

            Spacer()

            DatePicker(
                "",
                selection: reminderDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .colorScheme(.dark)
            .accentColor(AppColors.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Account Footer

struct AccountFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "church.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.gold.opacity(0.5))

            Text("Lumen Viae v1.0.0")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)

            Text("Ad Majorem Dei Gloriam")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.gold.opacity(0.6))
        }
    }
}

// MARK: - About Sheet

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Icon
                        VStack(spacing: 16) {
                            Image(systemName: "church.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.gold)

                            Text("Lumen Viae")
                                .font(AppFonts.headlineFont(28))
                                .foregroundColor(AppColors.cream)

                            Text("Light of the Way")
                                .font(AppFonts.italicFont(16))
                                .foregroundColor(AppColors.gold.opacity(0.8))
                        }
                        .padding(.top, 32)

                        // Description
                        VStack(alignment: .leading, spacing: 16) {
                            InfoBlock(
                                title: "Our Mission",
                                text: "Lumen Viae is a Catholic Rosary companion designed to deepen your prayer life. Through guided meditations, scripture, and reflection, the app accompanies you through all five mysteries of the Rosary — Joyful, Sorrowful, Glorious, and Luminous."
                            )

                            InfoBlock(
                                title: "How to Pray the Rosary",
                                text: "Each Rosary consists of five decades (mysteries). For each mystery, meditate on the scene, pray one Our Father, ten Hail Marys, and a Glory Be. The app guides you through all five, with optional meditations from saints and scripture."
                            )

                            InfoBlock(
                                title: "Daily Schedule",
                                text: "The traditional schedule assigns a set of mysteries to each day of the week: Joyful on Monday, Thursday, and Saturday; Sorrowful on Tuesday and Friday; Glorious on Sunday and Wednesday."
                            )
                        }
                        .padding(.horizontal, 24)

                        // Version
                        VStack(spacing: 4) {
                            Text("Version 1.0.0")
                                .font(AppFonts.bodyFont(13))
                                .foregroundColor(AppColors.textSecondary)

                            Text("Ad Majorem Dei Gloriam")
                                .font(AppFonts.italicFont(13))
                                .foregroundColor(AppColors.gold.opacity(0.6))
                        }
                        .padding(.bottom, 48)
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Policy Sheet

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacy Policy")
                                .font(AppFonts.headlineFont(26))
                                .foregroundColor(AppColors.cream)

                            Text("Last updated: February 2026")
                                .font(AppFonts.bodyFont(13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.top, 32)

                        InfoBlock(
                            title: "Data We Collect",
                            text: "Lumen Viae collects minimal data to provide the prayer experience. This includes your prayer history (mystery type, date, duration) stored locally on your device, and optional journal entries stored locally. No personal information is required to use the app."
                        )

                        InfoBlock(
                            title: "Local Storage",
                            text: "All prayer records, journal entries, and preferences are stored locally on your device using Apple's SwiftData framework. This data never leaves your device unless you explicitly back it up through iCloud (governed by Apple's privacy policy)."
                        )

                        InfoBlock(
                            title: "Network Requests",
                            text: "The app fetches meditation content and audio from our secure server (lumenviae.fly.dev). No personal identifiers are sent in these requests. We do not use analytics SDKs or third-party tracking."
                        )

                        InfoBlock(
                            title: "Notifications",
                            text: "If you enable daily reminders, the app schedules local notifications on your device. These are processed entirely on-device by iOS. We do not use push notification services."
                        )

                        InfoBlock(
                            title: "Children's Privacy",
                            text: "This app is suitable for all ages. We do not knowingly collect any personal data from users of any age."
                        )

                        InfoBlock(
                            title: "Contact",
                            text: "Questions about privacy? Reach us at support@lumenviae.app"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

// MARK: - Help & Support Sheet

struct HelpSupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("Help & Support")
                            .font(AppFonts.headlineFont(26))
                            .foregroundColor(AppColors.cream)
                            .padding(.top, 32)

                        InfoBlock(
                            title: "How do I begin praying?",
                            text: "From the home screen, tap \"Begin Prayer\" on the featured mystery card, or tap any mystery from the grid below. You'll be guided through a short meditation before the Rosary begins."
                        )

                        InfoBlock(
                            title: "What are the different mysteries?",
                            text: "There are four sets of mysteries: Joyful (Monday, Thursday, Saturday), Sorrowful (Tuesday, Friday), and Glorious (Sunday, Wednesday). Luminous mysteries, added by Pope John Paul II, are available any day from the home grid."
                        )

                        InfoBlock(
                            title: "How does audio work?",
                            text: "If a meditation set includes guided audio, playback controls will appear during the prayer. Tap the play button to start. Use the skip buttons to move forward or backward 10 seconds."
                        )

                        InfoBlock(
                            title: "Why are some meditations unavailable?",
                            text: "Meditation content is fetched from our server. If you're offline or content hasn't been added yet, some sets may not be available. Check your internet connection and try again."
                        )

                        InfoBlock(
                            title: "How do I adjust text size?",
                            text: "Go to Account → Prayer Experience → Text Size. Drag the slider toward the larger \"A\" to increase the meditation text size."
                        )

                        InfoBlock(
                            title: "Daily reminders aren't working",
                            text: "Make sure notifications are enabled for Lumen Viae in your iPhone's Settings → Notifications. Then toggle Daily Reminders off and back on in the app to reschedule."
                        )

                        InfoBlock(
                            title: "Contact Us",
                            text: "For other questions or feedback, email us at support@lumenviae.app — we'd love to hear from you."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

// MARK: - Info Block (shared by sheets)

private struct InfoBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.headlineFont(16))
                .foregroundColor(AppColors.gold)

            Text(text)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    AccountView()
        .environment(UserSettings.shared)
}
