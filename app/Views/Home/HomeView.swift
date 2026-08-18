//
//  HomeView.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Home screen: header, day label, featured mystery card,
//  Sacred Mysteries grid, and daily quote.
//

import SwiftUI
import SwiftData

// MARK: - HomeView

struct HomeView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel = HomeViewModel()

    /// SwiftData context for prayer history (streak data).
    @Environment(\.modelContext) private var modelContext

    /// Live query so the streak flame refreshes when a session is recorded.
    @Query(sort: \PrayerSession.completedAt, order: .reverse) private var sessions: [PrayerSession]

    /// Controls whether the menu sheet is displayed
    @State private var showingMenu = false

    /// Resume-card state while the interrupted session's set reloads
    @State private var isResuming = false
    @State private var resumeError: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient extending to edges
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Reading `sessions` here registers the @Query dependency,
                // so the flame refreshes the moment a Rosary is recorded.
                HeaderView(
                    onMenuTap: { showingMenu = true },
                    streak: sessions.isEmpty ? 0 : historyService.currentStreak(),
                    flameLit: sessions.isEmpty ? false : historyService.hasPrayedToday(),
                    onFlameTap: { router.selectedTab = .progress }
                )

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        DayPrayerLabel(label: viewModel.dayLabel)
                            // Starts clear of the dissolve below the header
                            .padding(.top, 36)
                            .devotionalEntrance()

                    featuredMysterySection
                        .padding(.top, 16)
                        .devotionalEntrance(delay: 0.08)

                    SacredMysteriesSection(
                        categories: viewModel.allCategories,
                        onSelectCategory: { category in
                            router.navigateToMeditationSelection(category: category)
                        },
                        onViewAll: {
                            router.navigateToAllMysteries()
                        }
                    )
                    .padding(.top, 32)
                    .devotionalEntrance(delay: 0.16)

                    QuoteSection(
                        quote: viewModel.currentQuote.text,
                        author: viewModel.currentQuote.author,
                        source: viewModel.currentQuote.source
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 120) // Clears the tab bar and its fade
                    .devotionalEntrance(delay: 0.24)
                    }
                }
                // Content dissolves as it rises toward the header instead of
                // stopping at a hard line. The ramp is weighted late so the
                // sliver of page visible above the resume card holds only a
                // few percent of the text underneath — a linear fade leaves
                // it legibly ghosting. The foot needs no fade: the tab bar
                // carries its own. Masked before the resume card is laid
                // over it, so that card stays fully crisp.
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.04), location: 0.55),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 32)
                        Rectangle().fill(.black)
                    }
                )
                // An unfinished Rosary floats over the content until the
                // user continues or dismisses it. It holds the top of the
                // page and keeps its shadow, but it no longer shouts:
                // returning to a Rosary should feel like an invitation,
                // not a summons.
                .overlay(alignment: .top) {
                    if let session = PrayerResumeService.shared.inProgress {
                        ResumePrayerCard(
                            session: session,
                            isLoading: isResuming,
                            errorMessage: resumeError,
                            onContinue: resumeInterruptedPrayer,
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    PrayerResumeService.shared.clear()
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .devotionalEntrance(delay: 0.04, drift: -10)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMenu) {
            MenuView(isPresented: $showingMenu)
        }
    }

    // MARK: - Subviews

    /// History service for the header's streak flame.
    /// The @Query-backed `sessions` keeps the header live: when a Rosary
    /// is recorded, the query changes and the body (and flame) refresh.
    private var historyService: PrayerHistoryService {
        PrayerHistoryService(modelContext: modelContext)
    }

    /// Reloads the interrupted session's meditation set and jumps back to
    /// the saved mystery. Resolution (bundled → API → offline download)
    /// is shared with the picker via MeditationSetResolver.
    private func resumeInterruptedPrayer() {
        guard let session = PrayerResumeService.shared.inProgress,
              !isResuming, router.path.isEmpty else { return }

        isResuming = true
        resumeError = nil
        let generation = router.generation

        Task {
            defer { isResuming = false }

            let set = try? await MeditationSetResolver.resolve(
                id: session.meditationSetId,
                categoryHint: session.category
            )

            guard let set else {
                resumeError = "Couldn't load — check your connection"
                return
            }
            // The user may have navigated while we loaded — never push then.
            guard router.generation == generation else { return }

            router.navigateToPrayerSession(
                meditationSet: set,
                startAtIndex: session.mysteryIndex,
                priorSeconds: session.accumulatedSeconds,
                startedAt: session.startedAt
            )
        }
    }

    /// The featured mystery card - data loaded instantly from local storage.
    @ViewBuilder
    private var featuredMysterySection: some View {
        if let mystery = viewModel.featuredMystery {
            FeaturedMysteryCard(
                category: viewModel.todaysCategory,
                mystery: mystery,
                onBeginPrayer: {
                    router.navigateToMeditationSelection(category: viewModel.todaysCategory)
                }
            )
        }
    }
}

// MARK: - ResumePrayerCard

/// Offers to continue an interrupted Rosary right where it left off.
struct ResumePrayerCard: View {
    let session: InProgressPrayer
    var isLoading: Bool
    var errorMessage: String?
    let onContinue: () -> Void
    let onDismiss: () -> Void

    private var mysteryLabel: String {
        let ordinal = session.mysteryIndex + 1
        guard let category = MysteryCategory(fromAPIString: session.category) else {
            return "\(Constants.ordinalWord(ordinal)) \(session.category.capitalized) Mystery"
        }
        // "The First Joyful Mystery" without its article, as the card
        // reads it in running text
        let label = category.mysteryLabel(ordinal: ordinal)
        return label.hasPrefix("The ") ? String(label.dropFirst(4)) : label
    }

    var body: some View {
        VStack(spacing: 8) {
            // ZStack (not .overlay on the button) so the dismiss X can
            // never inherit the continue button's disabled state.
            ZStack(alignment: .topTrailing) {
                continueButton
                    .disabled(isLoading)

                Button(action: onDismiss) {
                    AppIcon("ph-x", size: 10)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(8)
                }
                .accessibilityLabel("Dismiss unfinished Rosary")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
                HStack(spacing: 14) {
                    AppIcon("ch-rosary", size: 26)
                        .foregroundColor(AppColors.gold)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("CONTINUE YOUR ROSARY")
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.8))

                        Text(mysteryLabel)
                            .font(AppFonts.headlineFont(16))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(session.setName)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .tint(AppColors.gold)
                    } else {
                        AppIcon("ph-play-fill", size: 14)
                            .foregroundColor(AppColors.background)
                            .padding(10)
                            .background(Circle().fill(AppColors.goldGradient))
                    }
                }
                // The app's card shell — it floats, so it keeps its
                // shadow, but the gold no longer shouts over the hero
                // card behind it.
                .sacredCard(padding: 14)
                .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityLabel("Continue your Rosary at the \(mysteryLabel)")
    }
}

// MARK: - DayPrayerLabel

/// The current day's prayer label with decorative gradient lines on each side,
/// e.g. "━━━━ WEDNESDAY PRAYER ━━━━". Also carries the consecration's
/// countdown to the feast, which is the same ruled line at a quieter size.
struct DayPrayerLabel: View {
    let label: String

    var size: CGFloat = 11
    var tracking: CGFloat = 3
    var horizontalPadding: CGFloat = 40

    private var fadeInGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.gold.opacity(0), AppColors.gold],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var fadeOutGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.gold, AppColors.gold.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left decorative line (fades in from left)
            Rectangle()
                .fill(fadeInGradient)
                .frame(height: 1)

            // Day label text
            Text(label)
                .font(AppFonts.labelFont(size))
                .tracking(tracking)  // Letter spacing for elegance
                .foregroundColor(AppColors.gold)
                .fixedSize()  // Prevent text from being compressed

            // Right decorative line (fades out to right)
            Rectangle()
                .fill(fadeOutGradient)
                .frame(height: 1)
        }
        .padding(.horizontal, horizontalPadding)
    }
}

// MARK: - FeaturedMysteryCard

/// A large, prominent card showcasing today's featured mystery.
///
/// Background image fills the card via `.overlay` so it never
/// affects layout sizing. Text content sits at the bottom over
/// a gradient scrim for readability.
///
/// ## Layout
/// ```
/// ┌─────────────────────────────┐
/// │                             │
/// │      [mystery image]        │  ← Full-bleed photo
/// │   ╭─────────────────────╮   │
/// │   │  JOYFUL MYSTERIES   │   │  ← Category badge
/// │   ╰─────────────────────╯   │
/// │                             │
/// │     The Annunciation        │  ← Mystery title
/// │       Luke 1:26-38          │  ← Scripture reference
/// │                             │
/// │   ┌───────────────────┐     │
/// │   │   BEGIN PRAYER    │     │  ← CTA button
/// │   └───────────────────┘     │
/// └─────────────────────────────┘
/// ```
struct FeaturedMysteryCard: View {

    // MARK: - Properties

    /// The mystery category (Joyful, Sorrowful, etc.)
    let category: MysteryCategory

    /// The mystery to display (loaded instantly from local data)
    let mystery: Mystery

    /// Action triggered when "Begin Prayer" is tapped
    var onBeginPrayer: () -> Void = {}

    // MARK: - Body

    var body: some View {
        ArchHero(imageName: category.cardImageName) {
            HeroBadge("\(category.displayName.uppercased()) MYSTERIES")
            mysteryTitle
            scriptureReference
            beginPrayerButton
        }
    }

    // MARK: - Subviews

    /// Mystery name
    private var mysteryTitle: some View {
        Text(mystery.name)
            .font(AppFonts.headlineFont(24))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
    }

    /// Scripture reference
    @ViewBuilder
    private var scriptureReference: some View {
        if let reference = mystery.scriptureReference {
            Text(reference)
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.accentSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
    }

    /// Primary CTA button — the screen's one filled gold shape
    private var beginPrayerButton: some View {
        GoldCTAButton(title: "Begin prayer", action: onBeginPrayer)
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }

}

// MARK: - SacredMysteriesSection

/// A 2x2 grid of mystery category cards; each navigates to meditation
/// selection for that category.
struct SacredMysteriesSection: View {

    // MARK: - Properties

    /// Mystery categories to display on home (Joyful, Sorrowful, Glorious, Seven Sorrows)
    let categories: [MysteryCategory]

    /// Callback when a category card is tapped
    var onSelectCategory: ((MysteryCategory) -> Void)?

    /// Callback when VIEW ALL is tapped
    var onViewAll: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            sectionHeader
            mysteryGrid
        }
    }

    // MARK: - Subviews

    /// Section header with "Sacred Mysteries" title
    private var sectionHeader: some View {
        HStack {
            Text("Sacred Mysteries")
                .font(AppFonts.headlineFont(19))
                .foregroundColor(AppColors.goldLight)

            Spacer()

            Button(action: { onViewAll?() }) {
                HStack(spacing: 5) {
                    Text("VIEW ALL")
                        .font(AppFonts.labelFont(10))
                        .tracking(1.5)
                    AppIcon("ph-caret-right", size: 9)
                }
                .foregroundColor(AppColors.gold)
                .padding(.vertical, 8)
                .padding(.leading, 16)
            }
        }
        .padding(.horizontal, 20)
    }

    /// 2x2 grid of mystery category cards
    private var mysteryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(categories, id: \.self) { category in
                Button {
                    onSelectCategory?(category)
                } label: {
                    MysteryCard(
                        title: category.displayName,
                        subtitle: category.subtitle,
                        gradientColors: category.gradientColors,
                        cardImageName: category.cardImageName,
                        imageAlignment: category.cardImageAlignment,
                        imageOffset: category.cardImageOffset
                    )
                }
                .buttonStyle(SacredCardButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
