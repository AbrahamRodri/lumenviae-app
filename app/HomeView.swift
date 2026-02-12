//
//  HomeView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Main home screen showing today's mystery and quick access to all mysteries.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HeaderView()

                    // Day label
                    DayPrayerLabel(label: viewModel.dayLabel)
                        .padding(.top, 16)

                    // Featured mystery card
                    if let featuredMystery = viewModel.featuredMystery {
                        FeaturedMysteryCard(
                            category: viewModel.todaysCategory,
                            mystery: featuredMystery,
                            onBeginPrayer: {
                                router.navigateToMeditationSelection(category: viewModel.todaysCategory)
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    } else if viewModel.isLoading {
                        FeaturedMysteryCardPlaceholder()
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    // Sacred Mysteries grid
                    SacredMysteriesSection(
                        categories: viewModel.allCategories,
                        onSelectCategory: { category in
                            router.navigateToMeditationSelection(category: category)
                        }
                    )
                    .padding(.top, 32)

                    // Quote section
                    QuoteSection(
                        quote: viewModel.currentQuote.text,
                        author: viewModel.currentQuote.author
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            await viewModel.loadMysteries()
        }
    }
}

// MARK: - Day Prayer Label

struct DayPrayerLabel: View {
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0), AppColors.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(label)
                .font(AppFonts.bodyFont(12))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .fixedSize()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.gold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Featured Mystery Card

struct FeaturedMysteryCard: View {
    let category: MysteryCategory
    let mystery: Mystery
    var onBeginPrayer: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2d3a4a"),
                            Color(hex: "1a2433"),
                            Color(hex: "0f1a26")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 380)

            // Content overlay
            VStack(spacing: 16) {
                // Mystery type badge
                Text("\(category.displayName.uppercased()) MYSTERIES")
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.goldLight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppColors.background.opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.goldLight.opacity(0.8), lineWidth: 0.5)
                    )

                // Mystery title
                Text(mystery.name)
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)

                // Scripture reference
                if let reference = mystery.scriptureReference {
                    Text(reference)
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }

                // Begin Prayer button
                Button(action: onBeginPrayer) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))

                        Text("BEGIN PRAYER")
                            .font(AppFonts.bodyFont(14))
                            .tracking(2)
                    }
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.goldLight)
                    .cornerRadius(30)
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        AppColors.background.opacity(0.7),
                        AppColors.background.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Featured Mystery Card Placeholder

struct FeaturedMysteryCardPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(AppColors.cardBackground)
            .frame(height: 380)
            .overlay(
                ProgressView()
                    .tint(AppColors.gold)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Sacred Mysteries Section

struct SacredMysteriesSection: View {
    let categories: [MysteryCategory]
    var onSelectCategory: ((MysteryCategory) -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Sacred Mysteries")
                    .font(AppFonts.headlineFont(22))
                    .foregroundColor(AppColors.goldLight)

                Spacer()

                Button(action: {}) {
                    Text("VIEW ALL")
                        .font(AppFonts.bodyFont(12))
                        .tracking(1)
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.horizontal, 20)

            // 2x2 Grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(categories, id: \.self) { category in
                    MysteryCard(
                        title: category.displayName,
                        subtitle: category.subtitle,
                        imageName: category.iconName,
                        gradientColors: category.gradientColors
                    )
                    .onTapGesture {
                        onSelectCategory?(category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
