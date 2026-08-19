//
//  SelectMeditationView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  The meditation picker, read as a shelf.
//
//  Kinds of meditation sit behind a filter button — most visits don't
//  narrow by kind, and an always-visible chip row was competing with the
//  sets themselves. The shelf reads two ways: a gallery of half-width
//  tiles, or a plain ruled list. Pinned sets stay above whatever is
//  showing. Tapping a set opens it — what it is, who wrote it, how the
//  first mystery begins — before the Rosary starts.
//

import SwiftUI

/// How the shelf is laid out. Remembered between visits — a view
/// preference, not a devotion setting, so it stays out of UserSettings.
enum MeditationPickerViewMode: String {
    case gallery
    case list
}

struct SelectMeditationView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: MeditationSelectionViewModel

    /// Whether the kind-of-meditation tray is disclosed
    @State private var isFilterOpen = false

    /// Set on the tap that pushes a detail and cleared when the picker
    /// reappears, so a double-tap before the transition covers the shelf
    /// can't push the same screen twice.
    @State private var isOpeningSet = false

    /// Gallery by default. The tiles are the browsing reading — they
    /// carry air around each set and invite a tap into the set's own
    /// page, where the painting and the voice are. The ruled list is the
    /// scanning reading, for anyone who already knows what they're
    /// after; the choice is remembered once it's made.
    @AppStorage("meditationPicker.viewMode")
    private var viewMode: MeditationPickerViewMode = .gallery

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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
                MeditationHeaderView(
                    category: category,
                    onBack: { router.pop() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // The header names the screen; a second line
                        // saying "select a meditation set" over a shelf of
                        // meditation sets says nothing twice.
                        Color.clear.frame(height: 30)

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppColors.gold)
                                .padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            errorState(error)
                        } else if viewModel.meditationSets.isEmpty {
                            emptyCatalogState
                        } else {
                            shelf
                                .devotionalEntrance(delay: 0.05)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }
                // The shelf dissolves rather than stopping — raised and
                // lengthened at the foot so the last row softens well
                // before the tab bar instead of meeting it at an edge.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.07),
                            .init(color: .black, location: 0.84),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear { isOpeningSet = false }
        .task {
            await viewModel.loadMeditationSets()
        }
    }

    // MARK: - Shelf

    private var shelf: some View {
        VStack(spacing: 30) {
            controlsRow

            if isFilterOpen {
                filterTray
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            results
        }
        .animation(.easeOut(duration: 0.22), value: viewModel.selectedLabels)
        .animation(.easeOut(duration: 0.22), value: isFilterOpen)
        .animation(.easeOut(duration: 0.22), value: viewMode)
    }

    // MARK: - Controls

    /// How many sets are showing, and how the shelf is read. The count
    /// turns into "6 OF 14 SETS" whenever something is narrowing — that
    /// second form is how the user knows a filter is on.
    private var controlsRow: some View {
        HStack(spacing: 6) {
            Text(countLabel.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            if viewModel.hasLabels {
                ChromeToggle(
                    icon: "ph-funnel",
                    label: "Filter by kind",
                    isOn: isFilterOpen || !viewModel.selectedLabels.isEmpty,
                    badge: viewModel.selectedLabels.count,
                    action: { isFilterOpen.toggle() }
                )

                // A hairline between the funnel and the layout pair —
                // they do different jobs.
                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(width: 1, height: 26)
                    .padding(.horizontal, 3)
            }

            ChromeToggle(
                icon: "ph-cards",
                label: "Gallery",
                isOn: viewMode == .gallery,
                action: { viewMode = .gallery }
            )

            ChromeToggle(
                icon: "ph-list",
                label: "List",
                isOn: viewMode == .list,
                action: { viewMode = .list }
            )
        }
    }

    private var countLabel: String {
        let total = viewModel.totalSetCount
        let unit = total == 1 ? "set" : "sets"
        return viewModel.isNarrowed
            ? "\(viewModel.visibleSetCount) of \(total) \(unit)"
            : "\(total) \(unit)"
    }

    /// Kinds of meditation, disclosed.
    private var filterTray: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KIND OF MEDITATION")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                Spacer()

                if !viewModel.selectedLabels.isEmpty {
                    // A 44pt target that takes no more room in the row
                    // than its label, so the tray doesn't grow when it
                    // appears.
                    QuietGoldButton(
                        title: "Clear",
                        size: 10,
                        tracking: 1.8,
                        color: AppColors.gold.opacity(0.8),
                        horizontalPadding: 0
                    ) {
                        viewModel.clearLabels()
                    }
                    .padding(.vertical, -12)
                }
            }
            // A floor, not a ceiling — the heading grows with the text size
            .frame(minHeight: 20)

            // Chips keep their own width and wrap — an adaptive grid cut
            // them into equal columns, which shrank the long ones and left
            // ragged gaps between the short.
            ChipFlowLayout(spacing: 8) {
                ForEach(viewModel.allLabels, id: \.self) { label in
                    PickerChip(
                        title: MeditationLabel.displayName(label),
                        isSelected: viewModel.isSelected(label),
                        action: { viewModel.toggleLabel(label) }
                    )
                }
            }
        }
        .sacredCard(vertical: 18, horizontal: 18)
    }

    // MARK: - Results

    private var results: some View {
        VStack(spacing: 34) {
            if !viewModel.pinnedSets.isEmpty {
                group(title: "Pinned", sets: viewModel.pinnedSets)
            }

            ForEach(viewModel.sections) { section in
                group(
                    title: section.title.map { MeditationLabel.displayName($0) },
                    sets: section.sets,
                    // A headless remainder under the pinned group still
                    // needs a rule between them in the list
                    leadsWithRule: section.title == nil && !viewModel.pinnedSets.isEmpty
                )
            }

            if viewModel.cameUpEmpty {
                emptyState
            }
        }
    }

    @ViewBuilder
    private func group(
        title: String?,
        sets: [MeditationSetSummary],
        leadsWithRule: Bool = false
    ) -> some View {
        VStack(spacing: viewMode == .gallery ? 18 : 8) {
            if let title {
                SectionHeading(title: title)
            }

            switch viewMode {
            case .gallery:
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sets) { meditationSet in
                        MeditationSetTile(
                            title: meditationSet.name,
                            labels: meditationSet.labels ?? [],
                            setId: meditationSet.id,
                            artwork: meditationSet.artwork,
                            isPinned: viewModel.isPinned(meditationSet),
                            onTogglePin: {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    viewModel.togglePin(meditationSet)
                                }
                            },
                            onTap: { open(meditationSet) }
                        )
                    }
                }

            case .list:
                VStack(spacing: 0) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, meditationSet in
                        MeditationSetRow(
                            title: meditationSet.name,
                            labels: meditationSet.labels ?? [],
                            setId: meditationSet.id,
                            artwork: meditationSet.artwork,
                            isPinned: viewModel.isPinned(meditationSet),
                            showsDivider: index > 0 || leadsWithRule,
                            onTogglePin: {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    viewModel.togglePin(meditationSet)
                                }
                            },
                            onTap: { open(meditationSet) }
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No set carries all of those together")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            QuietGoldButton(
                title: "Clear filters",
                size: 10,
                color: AppColors.gold
            ) {
                viewModel.clearLabels()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    /// The catalog loaded and there is nothing in it yet for this
    /// devotion — say so, and offer to look again.
    private var emptyCatalogState: some View {
        VStack(spacing: 12) {
            Text("No meditations for the \(category.devotionTitle) yet.")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            QuietGoldButton(
                title: "Try again",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 11,
                size: 10,
                color: AppColors.gold
            ) {
                Task { await viewModel.retry() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    /// Opens a set's detail once per visit to the shelf
    private func open(_ meditationSet: MeditationSetSummary) {
        guard !isOpeningSet else { return }
        isOpeningSet = true
        router.navigateToMeditationSetDetail(meditationSet)
    }

    private func errorState(_ error: String) -> some View {
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
    }
}

// MARK: - Picker Chip

/// One toggleable capsule in the filter tray
private struct PickerChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .frame(minHeight: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.cardElevated : AppColors.cardBackground.opacity(0.6))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? AppColors.gold.opacity(0.7) : AppColors.gold.opacity(0.18),
                            lineWidth: 1
                        )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Chip Flow Layout

/// Lays chips out left to right at their own width, wrapping to a new
/// line when the next one won't fit.
private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    /// Fills the proposed width when there is one, so `placeSubviews`
    /// arranges against exactly the width `sizeThatFits` did — a tight
    /// content width fed back as bounds can differ by a floating-point
    /// ulp and wrap the last chip of the widest row on placement only.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let arrangement = arrange(subviews, in: proposal.width ?? .infinity)
        if let width = proposal.width, width.isFinite {
            return CGSize(width: width, height: arrangement.size.height)
        }
        return arrangement.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews, in: proposal.width ?? bounds.width)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(_ subviews: Subviews, in width: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

// MARK: - Chrome Toggle

/// A 44pt chrome square: filter, gallery, list. An 11pt-radius fill
/// inset 4pt so the target stays 44 while the shape reads ~36. Gold rim
/// when active, with an optional count riding the corner.
private struct ChromeToggle: View {
    let icon: String
    let label: String
    let isOn: Bool
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(icon, size: 17)
                .foregroundColor(isOn ? AppColors.goldLight : AppColors.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isOn ? AppColors.cardElevated : AppColors.cardBackground.opacity(0.5))
                        .padding(4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(
                            isOn ? AppColors.gold.opacity(0.7) : AppColors.gold.opacity(0.15),
                            lineWidth: 1
                        )
                        .padding(4)
                )
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text("\(badge)")
                            .font(AppFonts.labelFont(9))
                            .foregroundColor(AppColors.background)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Circle().fill(AppColors.goldGradient))
                            .padding(.top, -1)
                            .padding(.trailing, -1)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
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
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Meditation Header View

/// A working header for a chooser, not a hero for a landing page: the
/// way back and what you are choosing within.
///
/// The old one centred a 30pt all-gold title under a day label and an
/// ornament, taking a third of the screen before the first set — a
/// title card in front of a list. This is a nav bar: the back control
/// and the title on one line, the context beneath it, a hairline, and
/// then the sets. How many there are is said once, by the controls row
/// over the shelf, where it also reports what a filter left.
struct MeditationHeaderView: View {

    let category: MysteryCategory

    var onBack: () -> Void = {}

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
                    Text(category.devotionTitle)
                        .font(AppFonts.headlineFont(22))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(category.daysPrayed)
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
/// already pinned. Exercises the filter tray, section grouping, both
/// view modes, and the empty state (try "Scriptural" + "Intentions").
/// Labels are drawn only from the real vocabulary — Intentions, Saints,
/// Scriptural, Contemplative, Considerations.
#Preview("Labeled catalog") {
    let sample: [MeditationSetSummary] = [
        MeditationSetSummary(
            id: 1, name: "Traditional Meditations", category: "joyful",
            description: "Classic meditations on the virtue of each mystery.",
            labels: ["Contemplative"]
        ),
        MeditationSetSummary(
            id: 2, name: "Scriptural Rosary", category: "joyful",
            description: "A verse of Scripture to carry through every bead.",
            labels: ["Scriptural"]
        ),
        MeditationSetSummary(
            id: 3, name: "St. Louis de Montfort", category: "joyful",
            description: "Total consecration through the hands of Mary.",
            labels: ["Saints", "Contemplative"]
        ),
        MeditationSetSummary(
            id: 4, name: "St. Alphonsus Liguori", category: "joyful",
            description: "Affections and resolutions from the Doctor of prayer.",
            labels: ["Saints"]
        ),
        MeditationSetSummary(
            id: 5, name: "Bl. Anne Catherine Emmerich", category: "joyful",
            description: "The mysteries as she was given to see them.",
            labels: ["Saints", "Considerations"]
        ),
        MeditationSetSummary(
            id: 6, name: "St. Josemaría Escrivá", category: "joyful",
            description: "Finding God in the ordinary moments of each mystery.",
            labels: ["Saints", "Considerations"]
        ),
        MeditationSetSummary(
            id: 7, name: "As a Father", category: "joyful",
            description: "The Joyful mysteries through the vocation of fatherhood.",
            labels: ["Intentions"]
        ),
        MeditationSetSummary(
            id: 8, name: "As a Mother", category: "joyful",
            description: "Contemplating Mary's motherhood in your own.",
            labels: ["Intentions", "Contemplative"]
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
            labels: ["Scriptural"]
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

/// Fallback when the API sends no labels: no filter button, a flat
/// shelf, pinning still available.
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
