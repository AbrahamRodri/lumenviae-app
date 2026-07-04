//
//  SelectMeditationView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  The meditation picker. Scales from a handful of sets to a large
//  library: favorited sets pin to the top, and when the API sends
//  labels, a chip row lets the user combine them to narrow the list
//  while unfiltered browsing groups sets by their primary label.
//

import SwiftUI

struct SelectMeditationView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: MeditationSelectionViewModel

    init(category: MysteryCategory) {
        self._viewModel = State(initialValue: MeditationSelectionViewModel(category: category))
    }

    /// Preview/testing entry point with a pre-configured view model
    init(viewModel: MeditationSelectionViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    private var category: MysteryCategory { viewModel.category }

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
                            setList
                                .devotionalEntrance(delay: 0.05)
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

    // MARK: - Set List

    private var setList: some View {
        VStack(spacing: 16) {
            // Label filter chips (only once the API sends labels)
            if viewModel.hasLabels {
                labelChips
            }

            // Favorites pinned above everything
            if !viewModel.favoriteSets.isEmpty {
                SectionHeading(title: "Favorites")
                    .padding(.top, 4)

                ForEach(viewModel.favoriteSets) { meditationSet in
                    card(for: meditationSet)
                }
            }

            // Grouped / filtered sets
            ForEach(viewModel.sections) { section in
                if let title = section.title {
                    SectionHeading(title: title)
                        .padding(.top, 4)
                }

                ForEach(section.sets) { meditationSet in
                    card(for: meditationSet)
                }
            }

            // Filter matched nothing
            if viewModel.filterCameUpEmpty && viewModel.favoriteSets.isEmpty {
                VStack(spacing: 12) {
                    Text("Nothing carries all of those labels")
                        .font(AppFonts.italicFont(16))
                        .foregroundColor(AppColors.textSecondary)

                    Button(action: { withAnimation(.easeOut(duration: 0.2)) { viewModel.clearLabels() } }) {
                        Text("Clear filters")
                            .font(AppFonts.bodyFont(14))
                            .tracking(1)
                            .foregroundColor(AppColors.gold)
                    }
                }
                .padding(.top, 32)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.selectedLabels)
    }

    private func card(for meditationSet: MeditationSetSummary) -> some View {
        MeditationOptionCard(
            title: meditationSet.name,
            description: meditationSet.description ?? "",
            labels: meditationSet.labels ?? [],
            iconName: iconName(for: meditationSet.name),
            isFavorite: viewModel.isFavorite(meditationSet),
            onToggleFavorite: {
                withAnimation(.easeOut(duration: 0.25)) {
                    viewModel.toggleFavorite(meditationSet)
                }
            },
            onTap: {
                Task {
                    await selectMeditationSet(meditationSet)
                }
            }
        )
    }

    // MARK: - Label Chips

    private var labelChips: some View {
        VStack(spacing: 6) {
            // All labels share the row width — nothing to scroll
            HStack(spacing: 8) {
                ForEach(viewModel.allLabels, id: \.self) { label in
                    LabelChip(
                        title: label,
                        isSelected: viewModel.isSelected(label),
                        action: { viewModel.toggleLabel(label) }
                    )
                }
            }

            if !viewModel.selectedLabels.isEmpty {
                HStack {
                    Spacer()
                    Button(action: { withAnimation(.easeOut(duration: 0.2)) { viewModel.clearLabels() } }) {
                        Text("Reset")
                            .font(AppFonts.bodyFont(13))
                            .tracking(1)
                            .foregroundColor(AppColors.gold)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func iconName(for setName: String) -> String? {
        let name = setName.lowercased()
        if name.contains("traditional") {
            return "ch-church"
        } else if name.contains("louis") || name.contains("montfort") {
            return "ch-bible"
        } else if name.contains("scriptural") {
            return "ph-scroll"
        } else {
            return nil
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

// MARK: - Label Chip

/// One toggleable filter capsule in the label row
private struct LabelChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(11))
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.cardElevated : AppColors.cardBackground.opacity(0.6))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? AppColors.gold.opacity(0.7) : AppColors.gold.opacity(0.15),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Section Heading

/// Small tracked-gold heading flanked by hairlines, matching the
/// journal's month headers
private struct SectionHeading: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.4))
                .frame(height: 1)
                .frame(maxWidth: 40)

            Text(title.uppercased())
                .font(AppFonts.headlineFont(13))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .fixedSize()

            Rectangle()
                .fill(AppColors.gold.opacity(0.4))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
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

// MARK: - Previews

#Preview("Live API") {
    SelectMeditationView(category: .sorrowful)
        .environment(AppRouter())
}

/// The full future experience: a large labeled catalog with two sets
/// already favorited. Exercises chips (multi-select + horizontal
/// scroll), section grouping, the pinned Favorites section, and the
/// empty-filter state (try selecting "Scripture" + "Vocation").
#Preview("Labeled catalog") {
    let sample: [MeditationSetSummary] = [
        MeditationSetSummary(
            id: 1, name: "Traditional Meditations", category: "joyful",
            description: "Classic meditations on the virtue of each mystery.",
            labels: ["Traditional"]
        ),
        MeditationSetSummary(
            id: 2, name: "Scriptural Rosary", category: "joyful",
            description: "A verse of Scripture to carry through every bead.",
            labels: ["Traditional", "Scripture"]
        ),
        MeditationSetSummary(
            id: 3, name: "St. Louis de Montfort", category: "joyful",
            description: "Total consecration through the hands of Mary.",
            labels: ["Saints", "Marian"]
        ),
        MeditationSetSummary(
            id: 4, name: "St. Alphonsus Liguori", category: "joyful",
            description: "Affections and resolutions from the Doctor of prayer.",
            labels: ["Saints"]
        ),
        MeditationSetSummary(
            id: 5, name: "St. John Paul II", category: "joyful",
            description: "Contemplating the face of Christ with Mary.",
            labels: ["Saints", "Marian"]
        ),
        MeditationSetSummary(
            id: 6, name: "St. Josemaría Escrivá", category: "joyful",
            description: "Finding God in the ordinary moments of each mystery.",
            labels: ["Saints", "Vocation"]
        ),
        MeditationSetSummary(
            id: 7, name: "As a Father", category: "joyful",
            description: "The Joyful mysteries through the vocation of fatherhood.",
            labels: ["Intentions", "Vocation"]
        ),
        MeditationSetSummary(
            id: 8, name: "As a Mother", category: "joyful",
            description: "Contemplating Mary's motherhood in your own.",
            labels: ["Intentions", "Vocation", "Marian"]
        ),
        MeditationSetSummary(
            id: 9, name: "In Times of Suffering", category: "joyful",
            description: "Praying alongside Christ when carrying your own cross.",
            labels: ["Intentions"]
        ),
        MeditationSetSummary(
            id: 10, name: "In Gratitude", category: "joyful",
            description: "Receiving each mystery as a gift already given.",
            labels: ["Intentions"]
        ),
        MeditationSetSummary(
            id: 11, name: "Lectio Divina Rosary", category: "joyful",
            description: "Slow, prayerful reading woven through the decades.",
            labels: ["Scripture"]
        ),
        MeditationSetSummary(
            id: 12, name: "Parish Mission Set", category: "joyful",
            description: "An unlabeled set — lands in the trailing More section.",
            labels: nil
        )
    ]

    return SelectMeditationView(
        viewModel: MeditationSelectionViewModel(
            category: .joyful,
            favorites: FavoritesService(previewFavorites: [3, 9]),
            preloadedSets: sample
        )
    )
    .environment(AppRouter())
}

/// Fallback when the API sends no labels: a flat list, no chips,
/// with starring still available.
#Preview("Unlabeled catalog (fallback)") {
    let sample: [MeditationSetSummary] = [
        MeditationSetSummary(
            id: 1, name: "Traditional Meditations", category: "sorrowful",
            description: "Classic meditations on the virtue of each mystery.",
            labels: nil
        ),
        MeditationSetSummary(
            id: 2, name: "St. Louis de Montfort", category: "sorrowful",
            description: "Total consecration through the hands of Mary.",
            labels: nil
        ),
        MeditationSetSummary(
            id: 3, name: "Scriptural Rosary", category: "sorrowful",
            description: "A verse of Scripture to carry through every bead.",
            labels: nil
        )
    ]

    return SelectMeditationView(
        viewModel: MeditationSelectionViewModel(
            category: .sorrowful,
            favorites: FavoritesService(previewFavorites: [1]),
            preloadedSets: sample
        )
    )
    .environment(AppRouter())
}
