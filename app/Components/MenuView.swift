//
//  MenuView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/13/26.
//

import SwiftUI

struct MenuView: View {
    @Binding var isPresented: Bool
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("MENU")
                        .font(AppFonts.bodyFont(14))
                        .tracking(3)
                        .foregroundColor(AppColors.gold)

                    Spacer()

                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.2))
                    .frame(height: 1)
                    .padding(.bottom, 24)

                // Menu Items
                VStack(alignment: .leading, spacing: 0) {
                    MenuItemButton(
                        icon: "book.closed",
                        title: "How to Pray the Rosary",
                        action: { }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "sparkles",
                        title: "Finding the Mysteries in Scripture",
                        action: { }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "heart.fill",
                        title: "Marian Theology Library",
                        action: { }
                    )

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 20)

                    MenuItemButton(
                        icon: "candle.fill",
                        title: "St. Carlo Acutis",
                        subtitle: "Digital Altar",
                        action: { }
                    )
                }

                Spacer()

                // Disclaimer
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.gold.opacity(0.8))

                        Text("COMING SOON")
                            .font(AppFonts.bodyFont(11))
                            .tracking(1)
                            .foregroundColor(AppColors.gold)
                    }

                    Text("Menu features are not yet functional.")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.cream.opacity(0.7))
                        .lineSpacing(1)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.cardBackground.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 1)
                )
                .padding(.bottom, 16)

                // Footer with version
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.2))
                        .frame(height: 1)

                    Text("Lumen Viae v1.0.0")
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)

                    Text("Ad Majorem Dei Gloriam")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.gold.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - MenuItem Button

struct MenuItemButton: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.gold)
                    .frame(width: 24)

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

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    MenuView(isPresented: .constant(true))
        .environment(AppRouter())
}
