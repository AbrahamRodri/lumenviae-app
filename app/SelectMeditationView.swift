//
//  SelectMeditationView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct SelectMeditationView: View {
    let mysteryType: String
    let dayLabel: String

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "2a2518"),
                    Color(hex: "1a1a2e"),
                    Color(hex: "1a1a2e")
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                MeditationHeaderView(
                    mysteryType: mysteryType,
                    dayLabel: dayLabel
                )

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Subtitle
                        Text("Select a meditation set")
                            .font(AppFonts.italicFont(18))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 24)
                            .padding(.bottom, 8)

                        // Meditation Options (uses MeditationOptionCard component)
                        MeditationOptionCard(
                            title: "Traditional Meditations",
                            description: "Classic meditations from the saints focusing on the virtue of each mystery.",
                            iconName: "building.columns",
                            hasAudio: true
                        )

                        MeditationOptionCard(
                            title: "St. Louis de Montfort",
                            description: "Deeply theological reflections aimed at total consecration through Mary.",
                            iconName: "book.closed",
                            hasAudio: true
                        )

                        MeditationOptionCard(
                            title: "Scriptural Rosary",
                            description: "Scripture verses for each bead, drawing you deeper into the Gospel.",
                            iconName: "text.quote",
                            hasAudio: false
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                Spacer()
            }

            // Bottom Streak Widget (uses StreakWidget component)
            VStack {
                Spacer()
                StreakWidget(days: 12)
            }
        }
    }
}

// MARK: - Meditation Header View
struct MeditationHeaderView: View {
    let mysteryType: String
    let dayLabel: String

    var body: some View {
        VStack(spacing: 8) {
            // Back button row
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.gold)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Day label
            Text(dayLabel.uppercased())
                .font(AppFonts.bodyFont(12))
                .tracking(4)
                .foregroundColor(AppColors.gold)
                .padding(.top, 16)

            // Mystery title
            Text(mysteryType.uppercased())
                .font(AppFonts.headlineFont(32))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            // Gold underline
            Rectangle()
                .fill(AppColors.gold)
                .frame(width: 60, height: 2)
                .padding(.top, 8)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    SelectMeditationView(
        mysteryType: "Sorrowful\nMysteries",
        dayLabel: "Tuesdays & Fridays"
    )
}
