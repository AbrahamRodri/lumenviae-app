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
    @Environment(\.dismiss) private var dismiss

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

                    // All mystery categories in a grid
                    mysteryGrid
                        .padding(.horizontal, 20)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
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
            Text("All Mysteries")
                .font(AppFonts.headlineFont(28))
                .foregroundColor(AppColors.goldLight)

            Text("Select a mystery type to begin prayer")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
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
                MysteryCard(
                    title: category.displayName,
                    subtitle: category.subtitle,
                    gradientColors: category.gradientColors,
                    cardImageName: category.cardImageName
                )
                .onTapGesture {
                    router.navigateToMeditationSelection(category: category)
                }
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
