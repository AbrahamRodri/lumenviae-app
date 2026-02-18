//
//  RosaryMethodsView.swift
//  Lumen Viae
//
//  Presented as a sheet from the onboarding "Methods of Praying the Rosary" button.
//  Explains the different meditation styles available in the app.
//

import SwiftUI

// MARK: - RosaryMethodsView

struct RosaryMethodsView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("METHODS OF PRAYING")
                            .font(AppFonts.headlineFont(11))
                            .tracking(3)
                            .foregroundColor(AppColors.gold)

                        Text("The Rosary")
                            .font(AppFonts.headlineFont(24))
                            .foregroundColor(AppColors.cream)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(10)
                            .background(AppColors.cardBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                Divider()
                    .background(AppColors.gold.opacity(0.2))

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Intro
                        Text("There are several ways to pray the Rosary. Each method uses the same structure of mysteries and prayers, but brings a different focus or spiritual lens to the meditations.")
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 28)

                        // Method cards
                        VStack(spacing: 16) {
                            MethodDetailCard(
                                icon: "rosette",
                                tag: "DEFAULT",
                                title: "Standard Meditations",
                                description: "The classic approach to the Rosary. Each mystery is accompanied by a traditional meditation on its scriptural scene, its deeper meaning, and the virtue or fruit it invites you to cultivate in your daily life.\n\nThis is the recommended starting point for most people."
                            )

                            MethodDetailCard(
                                icon: "person.fill",
                                tag: "SAINTS",
                                title: "Saint Meditations",
                                description: "Meditations composed by or attributed to specific saints — such as St. Louis de Montfort, St. Alphonsus Liguori, or St. John Paul II. Each saint offers a unique spiritual lens shaped by their own devotion, charism, and theological insight.\n\nIdeal for those exploring different traditions of Marian spirituality."
                            )

                            MethodDetailCard(
                                icon: "heart.text.square",
                                tag: "INTENTIONAL",
                                title: "Intentional Meditations",
                                description: "Pray through a set of mysteries from a specific life perspective or vocation — as a father or mother, in times of suffering, for discernment, or in gratitude. The same mysteries speak in different ways depending on where you are in life.\n\nThese meditations are especially useful when you are bringing a particular intention to prayer."
                            )

                            MethodDetailCard(
                                icon: "text.book.closed",
                                tag: "COMING SOON",
                                title: "Scriptural Rosary",
                                description: "A more contemplative form in which a different scripture verse is offered for each individual bead — not just each mystery. This slows the prayer significantly, anchoring every Hail Mary in a specific passage of the Gospel.\n\nThis method will be available in a future update.",
                                isComingSoon: true
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - MethodDetailCard

private struct MethodDetailCard: View {
    let icon: String
    let tag: String
    let title: String
    let description: String
    var isComingSoon: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon + tag row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isComingSoon ? AppColors.textSecondary.opacity(0.08) : AppColors.gold.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(isComingSoon ? AppColors.textSecondary : AppColors.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag)
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(2)
                        .foregroundColor(isComingSoon ? AppColors.textSecondary.opacity(0.6) : AppColors.gold.opacity(0.7))

                    Text(title)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(isComingSoon ? AppColors.textSecondary : AppColors.cream)
                }

                Spacer()
            }

            // Description
            Text(description)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(isComingSoon ? AppColors.textSecondary.opacity(0.6) : AppColors.textSecondary)
                .lineSpacing(5)
        }
        .padding(18)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isComingSoon ? AppColors.textSecondary.opacity(0.1) : AppColors.gold.opacity(0.15),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Preview

#Preview {
    RosaryMethodsView()
}
