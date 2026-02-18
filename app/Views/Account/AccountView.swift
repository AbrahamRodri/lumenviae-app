//
//  AccountView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/11/26.
//

import SwiftUI

struct AccountView: View {
    @State private var audioAutoPlay = false
    @State private var dailyRemindersEnabled = true
    @State private var textSizeValue: Double = 0.5
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            // Background gradient
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    AccountHeaderView()

                    // Disclaimer Banner
                    DisclaimerBanner()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    // Profile Section
                    ProfileSection()
                        .padding(.top, 12)

                    // Prayer Experience Section
                    AccountSection(title: "PRAYER EXPERIENCE") {
                        VStack(spacing: 0) {
                            // Audio Auto-play
                            ToggleRow(
                                icon: "speaker.wave.2",
                                title: "Audio Auto-play",
                                isOn: $audioAutoPlay
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // Gregorian Chant
                            NavigationRow(
                                icon: "music.note",
                                title: "Gregorian Chant",
                                subtitle: "Background ambiance"
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // Text Size
                            TextSizeRow(value: $textSizeValue)
                        }
                    }
                    .padding(.top, 24)

                    // Devotion Section
                    AccountSection(title: "DEVOTION") {
                        VStack(spacing: 0) {
                            // Daily Reminders
                            ToggleRow(
                                icon: "bell",
                                title: "Daily Reminders",
                                subtitle: "06:00 AM • Angelus",
                                isOn: $dailyRemindersEnabled
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // Language
                            NavigationRow(
                                icon: "character.book.closed",
                                title: "Language",
                                value: "Latin & English"
                            )
                        }
                    }
                    .padding(.top, 24)

                    // About Section
                    AccountSection(title: "ABOUT") {
                        VStack(spacing: 0) {
                            NavigationRow(
                                icon: "info.circle",
                                title: "About Lumen Viae"
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            // App intro / onboarding replay
                            Button {
                                showOnboarding = true
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "book.pages")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppColors.textSecondary)
                                        .frame(width: 24)

                                    Text("App Introduction")
                                        .font(AppFonts.bodyFont(16))
                                        .foregroundColor(AppColors.cream)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            NavigationRow(
                                icon: "shield",
                                title: "Privacy Policy"
                            )

                            Divider()
                                .background(AppColors.gold.opacity(0.2))

                            NavigationRow(
                                icon: "questionmark.circle",
                                title: "Help & Support"
                            )
                        }
                    }
                    .padding(.top, 24)

                    // Footer
                    AccountFooter()
                        .padding(.top, 48)
                        .padding(.bottom, 120)
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(onComplete: { showOnboarding = false })
        }
    }
}

// MARK: - Account Header
struct AccountHeaderView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }

            Spacer()

            Text("Account")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)

            Spacer()

            // Invisible spacer for centering
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.clear)
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
            // Profile Image
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

            // Name
            Text("Maria Rossi")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)

            // Membership Status
            Text("Premium Member")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.gold)
        }
    }
}

// MARK: - Account Section Container
struct AccountSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text(title)
                .font(AppFonts.bodyFont(12))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 20)

            // Section Content Card
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
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)

            // Text
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

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Navigation Row
struct NavigationRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var value: String? = nil

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                // Text
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

                // Value (if provided)
                if let value = value {
                    Text(value)
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Chevron
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
                // Icon
                Image(systemName: "textformat.size")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)

                Text("Text Size")
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)

                Spacer()
            }

            // Slider
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

// MARK: - Disclaimer Banner

struct DisclaimerBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Text("COMING SOON")
                    .font(AppFonts.bodyFont(12))
                    .tracking(1)
                    .foregroundColor(AppColors.gold)

                Spacer()
            }

            Text("These settings are not yet functional in this version. Full feature support coming soon.")
                .font(AppFonts.bodyFont(13))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .lineSpacing(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Account Footer
struct AccountFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            // App Icon
            Image(systemName: "church.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.gold.opacity(0.5))

            // Version
            Text("Lumen Viae v1.0.0")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)

            // Tagline
            Text("Ad Majorem Dei Gloriam")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.gold.opacity(0.6))
        }
    }
}

#Preview {
    AccountView()
}
