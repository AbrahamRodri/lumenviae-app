//
//  HomeView.swift
//  Lumen Viae
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Home screen: header, day label, featured mystery card,
//  Sacred Mysteries grid, Today's Prayer, the reading shelf, and the
//  daily quote as its colophon.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = HomeViewModel()

    /// Today's celebration, for the band at the head of the page
    @State private var todayInChurch = TodayInChurch()

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
                header

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Starts clear of the dissolve below the header
                        DayPrayerLabel(label: viewModel.dayLabel)
                            .padding(.top, 30)
                            .devotionalEntrance(delay: 0.04)

                    featuredMysterySection
                        .padding(.top, 16)
                        .devotionalEntrance(delay: 0.10)

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

                    // The day's three practices, between the mysteries
                    // and the colophon: the Mass, the Office, and the
                    // preparation, each standing on its own live fact.
                    TodaysPrayerSection(today: todayInChurch)
                    .padding(.horizontal, 20)
                    .padding(.top, 44)
                    .devotionalEntrance(delay: 0.22)

                    // The books, after the Church's own day and before
                    // the colophon: what is being read is a quieter
                    // thing than what is being prayed, and belongs
                    // nearer the foot of the page than the head.
                    ReadingShelfSection()
                        .padding(.top, 40)
                        .devotionalEntrance(delay: 0.34)

                    // The quote closes the page — it is set as a
                    // colophon, and a page ends on its colophon, not on
                    // furniture. Its ornament rules also draw the line
                    // between the shelf and the page's foot.
                    QuoteSection(
                        quote: viewModel.currentQuote.text,
                        author: viewModel.currentQuote.author,
                        source: viewModel.currentQuote.source
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120) // Clears the tab bar and its fade
                    .devotionalEntrance(delay: 0.34)
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
        .task {
            await todayInChurch.load()
        }
        // The feast is the one thing on this page that goes stale by the
        // clock. Home does not rebuild on foreground, so it re-asks on
        // the way back in; `load()` returns at once unless the day turned.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // The feast turns at midnight; the canonical hour turns
            // eight times a day, and its own timer may have slept
            // through a suspension.
            CanonicalClock.shared.refresh()
            Task { await todayInChurch.load() }
        }
    }

    // MARK: - Subviews

    /// The wordmark, framed by the glass on the left and the app's two
    /// chrome doors on the right. The flame stays in the Chapel.
    private var header: some View {
        HeaderView(
            onSearchTap: { router.navigateToExplore() },
            onSettingsTap: { router.navigateToSettings() },
            onAboutTap: { router.push(.about) }
        )
    }

    /// Reloads the interrupted session's meditation set and jumps back to
    /// the saved mystery. Resolution (bundled → API → offline download)
    /// is shared with the picker via MeditationSetResolver.
    private func resumeInterruptedPrayer() {
        guard let session = PrayerResumeService.shared.inProgress,
              !isResuming, router.path.isEmpty else { return }

        // The Scriptural Rosary is bundled whole: nothing to load, and
        // its own screen to return to
        if session.isScripturalRosary {
            guard let category = MysteryCategory(fromAPIString: session.category) else { return }
            router.push(.scripturalRosaryPrayer(ScripturalRosaryLaunch(
                category: category,
                startIndex: session.mysteryIndex,
                startBead: session.beadIndex ?? 0,
                priorSeconds: session.accumulatedSeconds,
                startedAt: session.startedAt
            )))
            return
        }

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
                startAtBead: session.beadIndex ?? 0,
                priorSeconds: session.accumulatedSeconds,
                startedAt: session.startedAt
            )
        }
    }

    /// The day's mysteries, set large — the schedule is computed on
    /// device, so there is nothing to wait for.
    @ViewBuilder
    private var featuredMysterySection: some View {
        FeaturedMysteryCard(
            category: viewModel.todaysCategory,
            onBeginPrayer: {
                router.navigateToMeditationSelection(category: viewModel.todaysCategory)
            },
            onPrayInScripture: {
                router.push(.scripturalRosary)
            }
        )
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(Motion.crossfade, value: isLoading)
        .animation(Motion.crossfade, value: errorMessage)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
                HStack(spacing: 14) {
                    AppIcon(session.isScripturalRosary ? "ch-bible" : "ch-rosary", size: 26)
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

                    // The play disc gives way to the spinner by a
                    // crossfade, not a swap, while the set loads
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.gold)
                                .transition(.opacity.combined(with: .scale(scale: 0.7)))
                        } else {
                            AppIcon("ph-play-fill", size: 14)
                                .foregroundColor(AppColors.background)
                                .padding(10)
                                .background(Circle().fill(AppColors.goldGradient))
                                .transition(.opacity.combined(with: .scale(scale: 0.7)))
                        }
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

/// The day's mysteries, set large in the arch: a kicker saying they are
/// today's, the devotion's name, and the two ways to pray it.
///
/// The card used to headline the *first* mystery of the five — "The
/// Annunciation", its passage beneath — which made one decade the
/// card's subject when the button prays all of them. It now names the
/// devotion the button begins. Nothing stands between the title and
/// the button: the days the mysteries are prayed were tried there and
/// cut, since the label above the arch already says which day it is.
///
/// Background image fills the card via `.overlay` so it never
/// affects layout sizing.
///
/// ## Layout
/// ```
/// ┌─────────────────────────────┐
/// │                             │
/// │      [mystery image]        │  ← Full-bleed painting
/// │   ╭─────────────────────╮   │
/// │   │  TODAY'S MYSTERIES  │   │  ← Kicker
/// │   ╰─────────────────────╯   │
/// │                             │
/// │  The Sorrowful Mysteries    │  ← The devotion
/// │                             │
/// │   ┌───────────────────┐     │
/// │   │ PRAY WITH A MEDIT…│     │  ← The one gold act
/// │   └───────────────────┘     │
/// │   THE SCRIPTURAL ROSARY ›   │  ← The other way to pray it
/// └─────────────────────────────┘
/// ```
struct FeaturedMysteryCard: View {

    // MARK: - Properties

    /// The day's mystery category (Joyful, Sorrowful, etc.)
    let category: MysteryCategory

    /// Action triggered when "Begin Prayer" is tapped
    var onBeginPrayer: () -> Void = {}

    /// The quiet line under it: the same mysteries, prayed a verse to a
    /// bead — the Scriptural Rosary's door on the home page
    var onPrayInScripture: () -> Void = {}

    // MARK: - Body

    var body: some View {
        ArchHero(imageName: category.cardImageName) {
            HeroBadge("TODAY'S MYSTERIES")
            devotionTitle
            beginPrayerButton
            prayInScriptureLink
        }
    }

    // MARK: - Subviews

    /// The devotion's name — "The Sorrowful Mysteries" — the thing the
    /// button beneath begins.
    private var devotionTitle: some View {
        Text("The \(category.devotionTitle)")
            .font(AppFonts.headlineFont(24))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
    }

    /// Primary CTA button — the screen's one filled gold shape, in the
    /// same words the Chapel's focus block uses for the same act.
    ///
    /// It says what will be on the beads. It read "Begin the Rosary"
    /// until the Scriptural Rosary's line came to stand under it, and
    /// then two lines said "Rosary" and neither said how the two
    /// differed: this one opens the shelf of meditation sets, the line
    /// beneath opens the Gospel on the beads. Named by the meditation,
    /// the pair read as two ways of praying the same mysteries. The
    /// raised medallion still says "Pray", because it is the
    /// *configurable* act: a tap runs whatever the user chose, a hold
    /// opens the tray.
    private var beginPrayerButton: some View {
        GoldCTAButton(title: "Pray with a Meditation", action: onBeginPrayer)
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }

    /// The Scriptural Rosary, offered where the day's mysteries are
    /// offered. The card already names the passage the mystery is drawn
    /// from; this is the way to pray that passage a verse to a bead. It
    /// used to be reachable only from Explore and the Pray tray, and a
    /// devotion nobody can find from the home page is not a devotion the
    /// app has. Quiet gold, under the one filled act, never beside it.
    ///
    /// Named, not described: an earlier "Or pray it in Scripture" read
    /// as a footnote to the button above it, and a door should say where
    /// it goes.
    private var prayInScriptureLink: some View {
        QuietGoldButton(
            title: "The Scriptural Rosary",
            trailingIcon: "ph-caret-right",
            size: 10,
            color: AppColors.gold.opacity(0.85),
            action: onPrayInScripture
        )
        // The button keeps its 44pt target; the stack's rhythm keeps
        // its own spacing
        .padding(.vertical, -8)
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
                        imageFocal: category.cardFocalPoint
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
