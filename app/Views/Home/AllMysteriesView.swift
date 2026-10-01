//
//  AllMysteriesView.swift
//  Lumen Viae
//
//  View All mysteries screen - includes all categories (Joyful, Sorrowful,
//  Glorious, Luminous, and Seven Sorrows).
//

import SwiftUI

// MARK: - AllMysteriesView

/// Displays all mystery categories including Luminous.
///
/// This view is accessed via "VIEW ALL" on the home screen and shows
/// the complete list of available mystery types for prayer.
struct AllMysteriesView: View {

    // MARK: - Dependencies

    @Environment(AppRouter.self) private var router

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .padding(.top, 16)
                        .devotionalEntrance()

                    // All mystery categories in a grid
                    mysteryGrid
                        .padding(.horizontal, 20)
                        .devotionalEntrance(delay: 0.1)

                    Spacer(minLength: 100)
                }
            }
            .topChromeFade()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { router.pop() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 16)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Rosary Mysteries")
                .font(AppFonts.headlineFont(28))
                .foregroundColor(AppColors.goldLight)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("Scenes from the lives of Jesus and Mary. Choose which to pray.")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }

    private var mysteryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(MysteryCategory.allCategories, id: \.self) { category in
                Button {
                    router.navigateToMeditationSelection(category: category)
                } label: {
                    MysteryCard(
                        title: category.displayName,
                        subtitle: category.subtitle,
                        gradientColors: category.gradientColors,
                        cardImageName: category.cardImageName,
                        imageFocal: category.cardFocalPoint
                    )
                }
                // The same settle the cards have on Home
                .buttonStyle(SacredCardButtonStyle())
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllMysteriesView()
            .environment(AppRouter())
    }
}
