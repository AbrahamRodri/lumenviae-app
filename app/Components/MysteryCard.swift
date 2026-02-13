//
//  MysteryCard.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct MysteryCard: View {
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    var cardImageName: String? = nil

    var body: some View {
        // RoundedRectangle drives size; image goes in .overlay
        // so it never expands the card's layout bounds.
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom))
            .frame(height: 160)
            .overlay(
                Group {
                    if let cardImageName {
                        Image(cardImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.1), .black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.background.opacity(0.2))
                        .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 0.5))
                        .frame(width: 28, height: 28)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.gold)
                }
                .padding(12)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.headlineFont(20))
                        .foregroundColor(AppColors.cream)
                    Text(subtitle)
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 0.5)
            )
    }
}

#Preview {
    MysteryCard(
        title: "Joyful",
        subtitle: "The Incarnation",
        gradientColors: [Color(hex: "3d3522"), Color(hex: "2a2518")],
        cardImageName: "joyful_annunciation"
    )
    .padding()
    .background(AppColors.background)
}
