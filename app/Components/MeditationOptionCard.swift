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

    /// Pinned to the top of the picker. A pin, not a star: the list
    /// isn't rated, it's ordered — this set is the one you keep coming
    /// back to, so it sits where you can reach it.
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(AppFonts.headlineFont(17))
                            .foregroundColor(AppColors.cream)
                            .minimumScaleFactor(0.85)

                        if !labels.isEmpty {
                            Text(labels.map { MeditationLabel.displayName($0) }.joined(separator: "  ·  ").uppercased())
                                .font(AppFonts.labelFont(10))
                                .tracking(2)
                                .foregroundColor(AppColors.accentSoft)
                        }
                    }

                    Spacer()

                    if let onToggleFavorite {
                        Button(action: onToggleFavorite) {
                            // Filled and gold when pinned, outline and
                            // quiet when not — the set's own pairing.
                            AppIcon(isFavorite ? "ph-push-pin-fill" : "ph-push-pin", size: 18)
                                .foregroundColor(isFavorite ? AppColors.gold : AppColors.textSecondary.opacity(0.55))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isFavorite ? "Unpin this set" : "Pin this set to the top")
                        // Balance the tap target's padding so the pin
                        // aligns with the card's edge visually
                        .padding(.top, -12)
                        .padding(.trailing, -12)
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
            // A pinned set carries a brighter rim, so the pinned ones
            // read as a group even once they're scrolled among the rest
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        AppColors.gold.opacity(isFavorite ? 0.55 : 0.3),
                        lineWidth: isFavorite ? 1 : 0.5
                    )
            )
            .animation(.easeOut(duration: 0.25), value: isFavorite)
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
            iconName: "ph-crown-fill",
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
