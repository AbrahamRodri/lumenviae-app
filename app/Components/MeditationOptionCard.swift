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
    let iconName: String
    let hasAudio: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title row with audio indicator
                HStack(alignment: .center) {
                    Text(title)
                        .font(AppFonts.headlineFont(20))
                        .foregroundColor(AppColors.cream)

                    Spacer()

                    if hasAudio {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
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

                    Image(systemName: iconName)
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
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
    }
    .padding()
    .background(AppColors.background)
}
