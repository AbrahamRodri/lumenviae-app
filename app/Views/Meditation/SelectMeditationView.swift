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

    /// The set whose detail load failed, driving the retry alert
    @State private var failedSet: MeditationSetSummary?

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
            // The theme's own gradient, as everywhere else. Fading the
            // top into the category's color washed the header into an
            // olive band — the Joyful and Luminous golds in particular
            // sit right on top of the gold type they carry.
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                MeditationHeaderView(
                    category: category,
                    setCount: viewModel.isLoading ? nil : viewModel.meditationSets.count,
                    onBack: { router.pop() }
                )

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // The header names the screen; a second line
                        // saying "select a meditation set" over a list of
                        // meditation sets says nothing twice.
                        Color.clear.frame(height: 8)

                        // Loading state
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppColors.gold)
                                .padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 16) {
                                Text(error)
                                    .font(AppFonts.bodyFont(14))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)

                                GoldCTAButton(
                                    title: "Try again",
                                    prominence: .inline,
                                    showsCross: false,
                                    fullWidth: false
                                ) {
                                    Task { await viewModel.retry() }
                                }
                            }
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
                AppColors.background.opacity(0.72)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 14) {
                            ProgressView()
                                .tint(AppColors.gold)

                            Text("PREPARING THE MEDITATIONS")
                                .font(AppFonts.labelFont(10))
                                .tracking(2.5)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
                        )
                    )
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadMeditationSets()
        }
        // A set failed to load (cold server or offline): offer a retry
        // instead of silently substituting content.
        .alert(
            "Couldn't load this meditation set",
            isPresented: Binding(
                get: { failedSet != nil },
                set: { if !$0 { failedSet = nil } }
            )
        ) {
            Button("Try Again") {
                if let summary = failedSet {
                    failedSet = nil
                    Task { await selectMeditationSet(summary) }
                }
            }
            Button("Cancel", role: .cancel) { failedSet = nil }
        } message: {
            Text("The server may still be waking up — it can take a few seconds. Downloading offline content in Account keeps every meditation available without a connection.")
        }
    }

    // MARK: - Set List

    private var setList: some View {
        VStack(spacing: 16) {
            // Label filter chips (only once the API sends labels)
            if viewModel.hasLabels {
                labelChips
            }

            // Pinned sets sit above everything
            if !viewModel.favoriteSets.isEmpty {
                SectionHeading(
                    title: "Pinned",
                    icon: "ph-push-pin-fill",
                    count: viewModel.favoriteSets.count
                )
                .padding(.top, 4)

                ForEach(viewModel.favoriteSets) { meditationSet in
                    card(for: meditationSet)
                }
            }

            // Grouped / filtered sets
            ForEach(viewModel.sections) { section in
                if let title = section.title {
                    SectionHeading(
                        title: MeditationLabel.displayName(title),
                        count: section.sets.count
                    )
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
                        title: MeditationLabel.displayName(label),
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
            // The Church's traditional meditations
            return "ch-church"
        } else if name.contains("louis") || name.contains("montfort") {
            // Crown = de Montfort/consecration app-wide (True Devotion
            // header, Consecrate tab)
            return "ph-crown-fill"
        } else if name.contains("scriptural") {
            // Scripture = the Bible glyph, as on Mysteries in Scripture
            return "ch-bible"
        } else {
            return nil
        }
    }

    private func selectMeditationSet(_ summary: MeditationSetSummary) async {
        // A cold server can answer long after the user gave up and
        // navigated away — never mutate navigation from a stale response.
        // The generation token bumps on ANY path change (including system
        // back-swipes), unlike a depth count, which can coincide across
        // different screens.
        let generation = router.generation

        do {
            let fullSet = try await viewModel.loadFullMeditationSet(id: summary.id)
            guard router.generation == generation else { return }
            router.navigateToPrayerSession(meditationSet: fullSet)
        } catch {
            guard router.generation == generation else { return }
            failedSet = summary
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

    /// A leading glyph for sections that have one — the pin above the
    /// sets the user pinned
    var icon: String?

    /// How many sets sit under this heading, on the right in italic —
    /// the same meta the cards elsewhere in the app carry
    var count: Int?

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                AppIcon(icon, size: 12)
                    .foregroundColor(AppColors.gold)
            }

            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)
                .fixedSize()

            Rectangle()
                .fill(AppColors.gold.opacity(0.25))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)

            if let count {
                Text(count == 1 ? "1 set" : "\(count) sets")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Meditation Header View

/// A working header for a chooser, not a hero for a landing page: the
/// way back, what you are choosing within, and how much there is.
///
/// The old one centred a 30pt all-gold title under a day label and an
/// ornament, taking a third of the screen before the first set — a
/// title card in front of a list. This is a nav bar: the back control
/// and the title on one line, the context beneath it, a hairline, and
/// then the sets.
struct MeditationHeaderView: View {

    let category: MysteryCategory

    /// How many sets are on offer, once they have loaded
    var setCount: Int?

    var onBack: () -> Void = {}

    private var contextLine: String {
        let days = category.daysPrayed
        guard let setCount, setCount > 0 else { return days }
        return "\(days)  ·  \(setCount == 1 ? "1 set" : "\(setCount) sets")"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    AppIcon("ph-caret-left", size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(category.displayName) Mysteries")
                        .font(AppFonts.headlineFont(22))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(contextLine)
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // No trailing glyph: the category's own icon is a star,
                // which in a list of pins reads as a control you can
                // press rather than a label.
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 12)

            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(height: 0.5)
        }
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
