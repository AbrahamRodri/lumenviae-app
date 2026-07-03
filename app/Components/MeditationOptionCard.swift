//
//  MeditationOptionCard.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct MeditationOptionCard: View {
    let title: String
    let description: String

    /// Asset icon name (Phosphor "ph-*" or Christicons "ch-*")
    let iconName: String

    let hasAudio: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title row with audio indicator
                HStack(alignment: .center) {
                    Text(title)
                        .font(AppFonts.headlineFont(17))
                        .foregroundColor(AppColors.cream)
                        .minimumScaleFactor(0.85)

                    Spacer()

                    if hasAudio {
                        AppIcon("ph-speaker-high", size: 16)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                // Description with icon
                HStack(alignment: .bottom) {
                    Text(description)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    AppIcon(iconName, size: 34)
                        .foregroundColor(AppColors.gold.opacity(0.45))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        MeditationOptionCard(
            title: "Traditional Meditations",
            description: "Classic meditations from the saints focusing on the virtue of each mystery.",
            iconName: "ch-church",
            hasAudio: true
        )

        MeditationOptionCard(
            title: "St. Louis de Montfort",
            description: "Deeply theological reflections aimed at total consecration through Mary.",
            iconName: "ch-bible",
            hasAudio: true
        )
    }
    .padding()
    .background(AppColors.background)
}
