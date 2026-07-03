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
            // Background gradient with category color fade
            LinearGradient(
                colors: [
                    category.gradientColors.first ?? AppColors.cardBackground,
                    AppColors.background,
                    AppColors.backgroundDeep
                ],
                startPoint: .top,
                endPoint: .bottom
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
                            ForEach(Array(viewModel.meditationSets.enumerated()), id: \.element.id) { index, meditationSet in
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
                                .devotionalEntrance(delay: Double(index) * 0.07)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 0.92),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

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
            return "ch-church"
        } else if name.contains("louis") || name.contains("montfort") {
            return "ch-bible"
        } else if name.contains("scriptural") {
            return "ph-scroll"
        } else {
            return "ph-sparkle"
        }
    }

    private func selectMeditationSet(_ summary: MeditationSetSummary) async {
        do {
            let fullSet = try await viewModel.loadFullMeditationSet(id: summary.id)
            router.navigateToPrayerSession(meditationSet: fullSet)
        } catch {
            // Error handling - stay on current screen
            #if DEBUG
            print("Failed to load meditation set: \(error)")
            #endif
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
                    AppIcon("ph-caret-left", size: 20)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Day label
            Text(category.daysPrayed.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(4)
                .foregroundColor(AppColors.gold)
                .padding(.top, 16)

            // Mystery title
            Text("\(category.displayName.uppercased())\nMYSTERIES")
                .font(AppFonts.headlineFont(30))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)

            // Ornamental underline
            OrnamentDivider(showsCross: false)
                .frame(width: 160)
                .padding(.top, 8)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    SelectMeditationView(category: .sorrowful)
        .environment(AppRouter())
}
