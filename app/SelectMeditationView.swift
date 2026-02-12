//
//  SelectMeditationView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct SelectMeditationView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: MeditationSelectionViewModel

    let category: MysteryCategory

    init(category: MysteryCategory) {
        self.category = category
        self._viewModel = State(initialValue: MeditationSelectionViewModel(category: category))
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    category.gradientColors.first ?? Color(hex: "2a2518"),
                    AppColors.background,
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                MeditationHeaderView(
                    category: category,
                    onBack: { router.pop() }
                )

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Subtitle
                        Text("Select a meditation set")
                            .font(AppFonts.italicFont(18))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 24)
                            .padding(.bottom, 8)

                        // Loading state
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppColors.gold)
                                .padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.top, 40)
                        } else {
                            // Meditation Options
                            ForEach(viewModel.meditationSets) { meditationSet in
                                MeditationOptionCard(
                                    title: meditationSet.name,
                                    description: meditationSet.description ?? "",
                                    iconName: iconName(for: meditationSet.name),
                                    hasAudio: true,
                                    onTap: {
                                        Task {
                                            await selectMeditationSet(meditationSet)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                Spacer()
            }

            // Loading overlay when fetching full set
            if viewModel.isLoadingSet {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(AppColors.gold)
                                .scaleEffect(1.5)
                            Text("Loading meditation...")
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(AppColors.cream)
                        }
                    )
            }

            // Bottom Streak Widget
            VStack {
                Spacer()
                StreakWidget(days: 12)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadMeditationSets()
        }
    }

    // MARK: - Helpers

    private func iconName(for setName: String) -> String {
        let name = setName.lowercased()
        if name.contains("traditional") {
            return "building.columns"
        } else if name.contains("louis") || name.contains("montfort") {
            return "book.closed"
        } else if name.contains("scriptural") {
            return "text.quote"
        } else {
            return "sparkles"
        }
    }

    private func selectMeditationSet(_ summary: MeditationSetSummary) async {
        do {
            let fullSet = try await viewModel.loadFullMeditationSet(id: summary.id)
            router.navigateToPrayerSession(meditationSet: fullSet)
        } catch {
            // Error handling - stay on current screen
            print("Failed to load meditation set: \(error)")
        }
    }
}

// MARK: - Meditation Header View

struct MeditationHeaderView: View {
    let category: MysteryCategory
    var onBack: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            // Back button row
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.gold)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Day label
            Text(category.daysPrayed.uppercased())
                .font(AppFonts.bodyFont(12))
                .tracking(4)
                .foregroundColor(AppColors.gold)
                .padding(.top, 16)

            // Mystery title
            Text("\(category.displayName.uppercased())\nMYSTERIES")
                .font(AppFonts.headlineFont(32))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            // Gold underline
            Rectangle()
                .fill(AppColors.gold)
                .frame(width: 60, height: 2)
                .padding(.top, 8)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    SelectMeditationView(category: .sorrowful)
        .environment(AppRouter())
}
