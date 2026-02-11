//
//  StreakWidget.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct StreakWidget: View {
    let days: Int

    var body: some View {
        HStack(spacing: 16) {
            // Glowing orb
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "4a6a7a"),
                                Color(hex: "1a3a4a"),
                                AppColors.background
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)

                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(x: -5, y: -5)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT STREAK")
                    .font(AppFonts.bodyFont(11))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Text("\(days) Days of Prayer")
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)
            }

            Spacer()

            // Heart icon
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

#Preview {
    StreakWidget(days: 12)
        .background(AppColors.background)
}
