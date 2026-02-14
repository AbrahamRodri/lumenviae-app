//
//  HomeView.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  ═══════════════════════════════════════════════════════════════════════════
//  HOME SCREEN - THE MAIN LANDING VIEW
//  ═══════════════════════════════════════════════════════════════════════════
//
//  This is the first screen users see when opening the app.
//
//  ## Layout (top to bottom)
//  1. Header (app name + menu/notification buttons)
//  2. Day label (e.g., "WEDNESDAY PRAYER")
//  3. Featured mystery card (today's recommended mystery)
//  4. Sacred Mysteries grid (2x2 grid of all mystery types)
//  5. Daily inspirational quote
//
//  ## Data Flow
//  ```
//  HomeViewModel
//      │
//      ├── todaysCategory (from ScheduleService)
//      ├── mysteries (from APIService)
//      ├── featuredMystery (first mystery of today's set)
//      └── currentQuote (from MockDataService)
//  ```
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - HomeView

/// The main home screen displaying today's mystery and navigation to all mysteries.
///
/// ## SwiftUI Concepts
///
/// ### @Environment
/// `@Environment` reads a value from the SwiftUI environment.
/// Here we read the `AppRouter` that was injected by ContentView.
/// This lets us navigate from anywhere without passing the router down
/// through every view.
///
/// ### @State with ViewModel
/// The ViewModel is marked `@State` because HomeView "owns" it.
/// The ViewModel uses `@Observable`, so SwiftUI automatically
/// re-renders when its properties change.
///
/// ### .task modifier
/// `.task { }` runs async code when the view appears.
/// It automatically cancels if the view disappears.
/// Preferred over `.onAppear` for async work.
///
struct HomeView: View {

    // MARK: - Dependencies

    /// Router for navigating to meditation selection screen.
    /// Injected via ContentView's `.environment(router)`.
    @Environment(AppRouter.self) private var router

    /// ViewModel managing this screen's data and state.
    @State private var viewModel = HomeViewModel()

    // MARK: - State

    /// Controls whether the menu sheet is displayed
    @State private var showingMenu = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient extending to edges
            AppColors.appGradient
                .ignoresSafeArea()

            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HeaderView(onMenuTap: { showingMenu = true })

                    DayPrayerLabel(label: viewModel.dayLabel)
                        .padding(.top, 16)

                    featuredMysterySection
                        .padding(.top, 16)

                    SacredMysteriesSection(
                        categories: viewModel.allCategories,
                        onSelectCategory: { category in
                            router.navigateToMeditationSelection(category: category)
                        }
                    )
                    .padding(.top, 32)

                    QuoteSection(
                        quote: viewModel.currentQuote.text,
                        author: viewModel.currentQuote.author
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 100) // Extra space for tab bar
                }
            }
        }
        // Load mysteries when view appears
        .task {
            await viewModel.loadMysteries()
        }
        // Menu sheet
        .sheet(isPresented: $showingMenu) {
            MenuView(isPresented: $showingMenu)
        }
    }

    // MARK: - Subviews

    /// The featured mystery card, showing either content or a loading placeholder.
    @ViewBuilder
    private var featuredMysterySection: some View {
        if let featuredMystery = viewModel.featuredMystery {
            FeaturedMysteryCard(
                category: viewModel.todaysCategory,
                mystery: featuredMystery,
                onBeginPrayer: {
                    router.navigateToMeditationSelection(category: viewModel.todaysCategory)
                }
            )
        } else if viewModel.isLoading {
            FeaturedMysteryCardPlaceholder()
        }
    }
}

// MARK: - DayPrayerLabel

/// Displays the current day's prayer label with decorative gradient lines.
///
/// Example: "━━━━ WEDNESDAY PRAYER ━━━━"
///
/// The gradients fade from transparent to gold, creating an elegant
/// divider effect around the text.
struct DayPrayerLabel: View {
    /// The label text (e.g., "WEDNESDAY PRAYER")
    let label: String

    /// Reusable gradient for the decorative lines
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
                .font(AppFonts.bodyFont(12))
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

    /// The mystery to display (e.g., "The Annunciation")
    let mystery: Mystery

    /// Action triggered when "Begin Prayer" is tapped
    var onBeginPrayer: () -> Void = {}

    // MARK: - Body

    var body: some View {
        Rectangle()
            .fill(Color(hex: "0f1a26"))
            .frame(height: 380)
            .overlay(
                Image(category.cardImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.25))
            )
            .clipped()
            .drawingGroup()
            .overlay(
                Rectangle()
                    .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
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
    }

    // MARK: - Subviews

    /// "JOYFUL MYSTERIES" badge
    private var categoryBadge: some View {
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
    }

    /// Mystery name (e.g., "The Annunciation")
    private var mysteryTitle: some View {
        Text(mystery.name)
            .font(AppFonts.headlineFont(28))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.center)
    }

    /// Scripture reference (e.g., "Luke 1:26-38")
    @ViewBuilder
    private var scriptureReference: some View {
        if let reference = mystery.scriptureReference {
            Text(reference)
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
    }

    /// Primary CTA button
    private var beginPrayerButton: some View {
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

}

// MARK: - FeaturedMysteryCardPlaceholder

/// Loading placeholder shown while the featured mystery is being fetched.
///
/// Displays a loading spinner centered in a card-shaped container,
/// maintaining the same dimensions as the actual FeaturedMysteryCard.
struct FeaturedMysteryCardPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.cardBackground)
            .frame(height: 380)
            .overlay(
                ProgressView()
                    .tint(AppColors.gold)
            )
            .overlay(
                Rectangle()
                    .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - SacredMysteriesSection

/// A 2x2 grid displaying all four mystery categories.
///
/// Each card is tappable and navigates to the meditation selection
/// for that category. This provides quick access to any mystery type,
/// not just today's featured mystery.
///
/// ## SwiftUI Concepts
///
/// ### LazyVGrid
/// A grid that only creates views when they're needed (scrolled into view).
/// "Lazy" means it's memory-efficient for large grids.
/// - `columns`: Defines how many columns and their sizing
/// - `GridItem(.flexible())`: Column that fills available space
///
/// ### ForEach with id: \.self
/// Iterates over a collection and creates a view for each item.
/// `id: \.self` tells SwiftUI to use the item itself as the identifier
/// (works because MysteryCategory conforms to Hashable).
///
struct SacredMysteriesSection: View {

    // MARK: - Properties

    /// All mystery categories to display (Joyful, Sorrowful, Glorious, Luminous)
    let categories: [MysteryCategory]

    /// Callback when a category card is tapped
    var onSelectCategory: ((MysteryCategory) -> Void)?

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
                MysteryCard(
                    title: category.displayName,
                    subtitle: category.subtitle,
                    gradientColors: category.gradientColors,
                    cardImageName: category.cardImageName
                )
                .onTapGesture {
                    onSelectCategory?(category)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
