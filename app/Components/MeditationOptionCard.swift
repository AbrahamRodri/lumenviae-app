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

    /// Descriptive labels shown as a quiet line under the title
    var labels: [String] = []

    /// Asset icon name (Phosphor "ph-*" or Christicons "ch-*"),
    /// or nil for a clean text-only card
    var iconName: String? = nil

    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title row with favorite star
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(AppFonts.headlineFont(17))
                            .foregroundColor(AppColors.cream)
                            .minimumScaleFactor(0.85)

                        if !labels.isEmpty {
                            Text(labels.joined(separator: "  ·  ").uppercased())
                                .font(AppFonts.labelFont(10))
                                .tracking(2)
                                .foregroundColor(AppColors.accentSoft)
                        }
                    }

                    Spacer()

                    if let onToggleFavorite {
                        Button(action: onToggleFavorite) {
                            AppIcon(isFavorite ? "ph-star-fill" : "ph-star", size: 17)
                                .foregroundColor(isFavorite ? AppColors.gold : AppColors.textSecondary.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                        // Balance the tap target's padding so the star
                        // aligns with the card's edge visually
                        .padding(.top, -8)
                        .padding(.trailing, -8)
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

                    if let iconName {
                        AppIcon(iconName, size: 34)
                            .foregroundColor(AppColors.gold.opacity(0.45))
                    }
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
            labels: ["Traditional"],
            iconName: "ch-church",
            isFavorite: true,
            onToggleFavorite: {}
        )

        MeditationOptionCard(
            title: "St. Louis de Montfort",
            description: "Deeply theological reflections aimed at total consecration through Mary.",
            labels: ["Saints", "Marian"],
            iconName: "ch-bible",
            onToggleFavorite: {}
        )

        MeditationOptionCard(
            title: "In Times of Suffering",
            description: "Praying the mysteries when carrying a heavy cross of your own."
        )
    }
    .padding()
    .background(AppColors.background)
}
