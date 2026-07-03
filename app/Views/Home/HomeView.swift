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
                            .padding(.top, 16)
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
                        author: viewModel.currentQuote.author
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 100) // Extra space for tab bar
                    .devotionalEntrance(delay: 0.24)
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

// MARK: - DayPrayerLabel

/// The current day's prayer label with decorative gradient lines on each side,
/// e.g. "━━━━ WEDNESDAY PRAYER ━━━━".
struct DayPrayerLabel: View {
    let label: String

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
                .font(AppFonts.labelFont(11))
                .tracking(3)  // Letter spacing for elegance
                .foregroundColor(AppColors.gold)
                .fixedSize()  // Prevent text from being compressed

            // Right decorative line (fades out to right)
            Rectangle()
                .fill(fadeOutGradient)
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
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

    /// The cathedral-window arch that frames the mystery image
    private var arch: GothicArchShape { GothicArchShape(riseRatio: 0.34) }

    var body: some View {
        // Arch shape drives size; image goes in .overlay so it never
        // expands layout bounds, then everything clips to the arch.
        arch
            .fill(AppColors.cardBackground)
            .frame(height: 410)
            .overlay(
                CachedAssetImage(category.cardImageName)
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.25))
            )
            .clipShape(arch)
            .overlay(
                arch.strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
            )
            .overlay(
                arch.inset(by: 5)
                    .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(alignment: .bottom) {
                VStack(spacing: 16) {
                    categoryBadge
                    mysteryTitle
                    scriptureReference
                    beginPrayerButton
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
            .breathingGlow(
                AppColors.gold,
                radius: 18,
                dimOpacity: 0.10,
                brightOpacity: 0.22,
                period: 3.8
            )
    }

    // MARK: - Subviews

    /// "JOYFUL MYSTERIES" badge - always available (uses category)
    private var categoryBadge: some View {
        Text("\(category.displayName.uppercased()) MYSTERIES")
            .font(AppFonts.labelFont(9))
            .tracking(2.5)
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
    }

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

    /// Primary CTA button
    private var beginPrayerButton: some View {
        Button(action: onBeginPrayer) {
            HStack(spacing: 10) {
                LatinCross()
                    .fill(AppColors.background)
                    .frame(width: 10, height: 14)
                Text("BEGIN PRAYER")
                    .font(AppFonts.labelFont(13))
                    .tracking(2.5)
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(AppColors.goldGradient))
            .overlay(
                Capsule()
                    .strokeBorder(AppColors.goldLight.opacity(0.6), lineWidth: 0.5)
            )
            .haloGlow(AppColors.gold, radius: 9, intensity: 0.3)
        }
        .buttonStyle(GoldCTAButtonStyle())
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
                        cardImageName: category.cardImageName
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
