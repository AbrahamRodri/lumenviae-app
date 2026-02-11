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
    let imageName: String
    let gradientColors: [Color]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 0.5)
                )

            // Arrow button
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppColors.background.opacity(0.2))
                            .overlay(
                                Circle()
                                    .strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 0.5)
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.gold)
                    }
                    .padding(12)
                }
                Spacer()
            }

            // Background icon
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: imageName)
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.cream.opacity(0.15))
                    Spacer()
                }
                Spacer()
            }

            // Content
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
        .frame(height: 160)
    }
}

#Preview {
    MysteryCard(
        title: "Joyful",
        subtitle: "The Incarnation",
        imageName: "figure.stand",
        gradientColors: [Color(hex: "3d3522"), Color(hex: "2a2518")]
    )
    .padding()
    .background(AppColors.background)
}
