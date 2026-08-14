//
//  ConsecrationReadingSheet.swift
//  Lumen Viae
//
//  The day's spiritual reading, set as a page rather than a screen: a
//  bare top bar, the day's theme under an ornament rule, the text at
//  reading size with an illuminated initial, and one gold act at the
//  foot that carries the user into the prayers.
//
//  Opened from BEGIN TODAY'S PRAYER and from READ IN FULL — both land
//  here, so the reading is always where the day starts.
//

import SwiftUI

struct ConsecrationReadingSheet: View {

    // MARK: - Properties

    let dayNumber: Int

    /// Continues into the day's prayers. The overview owns the push, so
    /// the sheet never touches the navigation path itself.
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 26)
                            .padding(.top, 18)

                        if let text = day?.meditationText {
                            ReadingText(
                                text: text,
                                size: settings.meditationFontSize,
                                showsDropCap: true
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 26)
                            .padding(.top, 22)

                            closing
                                .padding(.horizontal, 26)
                                .padding(.top, 22)
                        }

                        Spacer(minLength: 40)
                    }
                }

                footer
            }
        }
        .devotionalEntrance(drift: 18)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            PrayerHeaderButton(icon: "ph-x", size: 16, label: "Close the reading") {
                dismiss()
            }

            Spacer()

            Text(dayLabel)
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.cream.opacity(0.85))

            Spacer()

            // Balances the close button so the label stays centered
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var dayLabel: String {
        guard let phase else { return "DAY \(dayNumber)" }
        if phase == .consecrationDay { return "CONSECRATION DAY" }
        return "DAY \(dayNumber) · \(phase.displayName.uppercased())"
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text((phase?.subtitle ?? "").uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            Text(day?.title ?? "")
                .font(AppFonts.headlineFont(25))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            OrnamentDivider(showsCross: false)
                .frame(width: 150)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Closing

    @ViewBuilder
    private var closing: some View {
        if let source = day?.meditationSource {
            VStack(spacing: 14) {
                OrnamentDivider()
                    .frame(width: 180)

                Text(source)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Footer

    /// The page dissolves into the act rather than stopping against it.
    private var footer: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [AppColors.background.opacity(0), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .allowsHitTesting(false)

            GoldCTAButton(title: "Continue to prayers", showsCross: false, action: onContinue)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .background(AppColors.background)
        }
    }
}

// MARK: - Preview

#Preview {
    ConsecrationReadingSheet(dayNumber: 33, onContinue: {})
        .environment(UserSettings.shared)
}
