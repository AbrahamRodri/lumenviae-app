//
//  ConsecrationOnboardingView.swift
//  Lumen Viae
//
//  Shown when the user has no active consecration. Instead of one long
//  page, the devotion is introduced as a paced sequence — atmosphere,
//  meaning, daily rhythm, the 33-day arc — ending in the one decision
//  that matters: choosing a consecration day.
//
//  First-time visitors walk the full sequence. Returning users (after a
//  restart, or having browsed before) land directly on the date step;
//  the educational pages stay one back-chevron away. Every educational
//  step is skippable.
//

import SwiftUI

// MARK: - ConsecrationOnboardingStep

enum ConsecrationOnboardingStep: Int, CaseIterable {
    case threshold   // Atmosphere: flame, title, Montfort's promise
    case devotion    // What Total Consecration is
    case rhythm      // What each day asks of you
    case journey     // The 33-day arc in four movements
    case chooseDay   // The commitment: pick the feast / start day

    var isEducational: Bool { self != .chooseDay }
}

// MARK: - ConsecrationOnboardingView

struct ConsecrationOnboardingView: View {

    // MARK: - Properties

    @Binding var path: [ConsecrationRoute]

    /// Whether the tab bar should step aside, read by the tab. It does
    /// while the reader walks the introduction — pages 2 to 5, each with
    /// a Back — and stands on the page the tab opens on: the welcome for
    /// a first visit, the feast chooser for a returning reader. The
    /// welcome has no Back, so without the bar there a reader who only
    /// looked in could leave the tab only by choosing a feast.
    @Binding var hidesTabBar: Bool

    @Environment(ConsecrationViewModel.self) private var viewModel

    /// Once the introduction has been walked (or skipped), later visits
    /// go straight to the date step — after a restart, re-reading four
    /// pages of catechesis would be a wall, not a welcome.
    @AppStorage("hasSeenConsecrationOnboarding") private var hasSeenOnboarding = false

    @State private var step: ConsecrationOnboardingStep = .threshold

    /// Whether the reader came into the pages from the one the tab
    /// opened on (see `hidesTabBar`)
    @State private var walking = false

    /// Guards the initial returning-user jump so it doesn't re-fire when
    /// this view reappears after a push
    @State private var hasAppeared = false

    /// The glass, measured: page 2's painting is sized from it, and the
    /// foot of a page without the tab bar sits clear of the home
    /// indicator by it
    @State private var metrics = IntroPageMetrics()

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            // Page 2's painting stands behind the bar, from the top of
            // the glass, and crossfades in and out with its page
            if step == .devotion {
                VStack(spacing: 0) {
                    AnnunciationPlate()
                        .frame(height: artHeight)
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea(edges: .top)
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                ZStack {
                    switch step {
                    case .threshold:
                        ThresholdStepView(onContinue: { advance(to: .devotion) })
                            .transition(stepTransition)
                    case .devotion:
                        DevotionStepView(
                            bottomClearance: footClearance,
                            onContinue: { advance(to: .rhythm) }
                        )
                        .transition(stepTransition)
                    case .rhythm:
                        RhythmStepView(
                            bottomClearance: footClearance,
                            onContinue: { advance(to: .journey) }
                        )
                        .transition(stepTransition)
                    case .journey:
                        JourneyStepView(
                            bottomClearance: footClearance,
                            onContinue: { advance(to: .chooseDay) }
                        )
                        .transition(stepTransition)
                    case .chooseDay:
                        // Above the tab bar when the tab opened here
                        ConsecrationDateSelectionView(
                            bottomClearance: walking ? footClearance : 104
                        )
                        .transition(stepTransition)
                    }
                }
                // Nothing may render outside the page's own width. Without
                // this, a step mid-transition draws past the screen edge.
                .clipped()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onGeometryChange(for: IntroPageMetrics.self) { proxy in
            IntroPageMetrics(
                fullHeight: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                topInset: proxy.safeAreaInsets.top,
                bottomInset: proxy.safeAreaInsets.bottom
            )
        } action: { measured in
            metrics = measured
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            if hasSeenOnboarding {
                step = .chooseDay
            }
        }
        .onChange(of: walking) { _, isWalking in
            hidesTabBar = isWalking
        }
        // Leaving — a consecration begun or scheduled, or the tab put
        // away — always gives the bar back
        .onDisappear {
            hidesTabBar = false
        }
    }

    // MARK: - Layout

    /// Page 2's painting: 470 points on a glass 844 tall, and the same
    /// share of any other, so its words, set from the foot of the page,
    /// meet its dissolving foot on every phone
    private var artHeight: CGFloat {
        guard metrics.fullHeight > 0 else { return 470 }
        return (metrics.fullHeight * 0.556).rounded()
    }

    /// A page's one act sits 40 points above the foot of the glass once
    /// the tab bar has stepped aside, and never closer than 12 to the
    /// home indicator. With the bar, it clears the bar as it always did.
    private var footClearance: CGFloat {
        walking ? max(12, 40 - metrics.bottomInset) : 120
    }

    // MARK: - Navigation

    private func advance(to newStep: ConsecrationOnboardingStep) {
        withAnimation(.easeInOut(duration: 0.4)) {
            step = newStep
            walking = newStep != .threshold
        }
        if newStep == .chooseDay {
            hasSeenOnboarding = true
        }
    }

    private func goBack() {
        guard let previous = ConsecrationOnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            step = previous
            walking = previous != .threshold
        }
    }

    private func skipToChooser() {
        withAnimation(.easeInOut(duration: 0.4)) {
            step = .chooseDay
            walking = true
        }
        hasSeenOnboarding = true
    }

    /// Steps cross-fade in place — the page never travels sideways. A
    /// sliding step reads as a swipeable carousel and invites a drag that
    /// does nothing, since the only way through is the button.
    private var stepTransition: AnyTransition {
        .opacity
    }

    // MARK: - Top Bar

    /// Over page 2's painting the bar's chrome turns to cream on a dark
    /// scrim, as a reader's does over art
    private var overArt: Bool { step == .devotion }

    private var topBar: some View {
        ZStack {
            // Progress (centered independently of the side buttons)
            progressSegments

            HStack {
                // Back — also how a returning user reaches the
                // educational pages again from the date step
                if step != .threshold {
                    Button {
                        goBack()
                    } label: {
                        AppIcon("ph-caret-left", size: 18)
                            .foregroundColor(AppColors.cream)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle().fill(overArt ? Color.black.opacity(0.3) : AppColors.cardBackground)
                            )
                            .overlay(
                                Circle().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(QuietGlyphButtonStyle())
                    .accessibilityLabel("Back")
                }

                Spacer()

                if step.isEducational {
                    Button("Skip") {
                        skipToChooser()
                    }
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(overArt ? AppColors.cream : AppColors.textSecondary)
                    // Kept to one line so it can't run into the progress
                    // centered behind it at the larger text sizes
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityHint("Goes to choosing your feast")
                }
            }
        }
        .frame(minHeight: 44)
    }

    /// Five capsules: the page you are on drawn long, the pages behind it
    /// lit, the pages ahead faint
    private var progressSegments: some View {
        HStack(spacing: 6) {
            ForEach(ConsecrationOnboardingStep.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(segmentColor(s))
                    .frame(width: s == step ? 22 : 8, height: 4)
            }
        }
        .animation(Motion.settle, value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(step.rawValue + 1) of \(ConsecrationOnboardingStep.allCases.count)")
    }

    private func segmentColor(_ s: ConsecrationOnboardingStep) -> Color {
        let lit = overArt ? AppColors.cream : AppColors.gold
        if s.rawValue <= step.rawValue { return lit }
        return (overArt ? AppColors.cream : AppColors.textSecondary).opacity(0.3)
    }
}

// MARK: - Page Metrics

/// The glass the introduction stands on, measured once per layout
private nonisolated struct IntroPageMetrics: Equatable {
    var fullHeight: CGFloat = 0
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0
}

// MARK: - Staggered Reveal

/// Fades content in with a slight rise, on a delay — so each step's
/// content arrives as a paced sequence rather than a wall.
private struct StaggeredReveal: ViewModifier {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            // With Reduce Motion, only the fade runs — the same bargain
            // DevotionalEntrance makes everywhere else in the app
            .offset(y: shown || reduceMotion ? 0 : 14)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    shown = true
                }
            }
            .onDisappear {
                shown = false
            }
    }
}

private extension View {
    func staggeredReveal(delay: Double) -> some View {
        modifier(StaggeredReveal(delay: delay))
    }
}

// MARK: - Static Slide

/// Locks a slide to one static, non-scrolling page — the layout
/// distributes itself with flexible spacers and everything fits. Only
/// when the content genuinely cannot fit (very small devices, very
/// large accessibility text) does it degrade to a scroll, so text is
/// never clipped.
///
/// The spacers between a slide's blocks must carry small minimums for
/// this to work: `ViewThatFits` measures the content's ideal height, and
/// a `Spacer(minLength: 28)` adds all 28 of those points to that
/// measurement whether or not the room is there. Generous gaps come from
/// the spacers *expanding* into leftover space, not from their minimums.
private struct StaticSlide<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView(showsIndicators: false) {
                content
            }
        }
    }
}

// MARK: - Shared Step Chrome

/// Each step's one act, drawn from the app's single CTA system rather
/// than a private copy of it: every step goes on, so every step's act
/// carries the same arrow.
private struct OnboardingContinueButton: View {
    let title: String
    var icon: String? = "ph-arrow-right"
    let action: () -> Void

    var body: some View {
        GoldCTAButton(
            title: title,
            trailingIcon: icon,
            action: action
        )
    }
}

/// The small gold capitals above each page's title, on every page of the
/// introduction and the feast chooser
struct ConsecrationIntroKicker: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.labelFont(12))
            .tracking(4)
            .foregroundColor(AppColors.gold)
            .multilineTextAlignment(.center)
    }
}

/// A fine gold rule between the parts of a card
struct ConsecrationIntroRule: View {
    var opacity: Double = 0.18

    var body: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(opacity))
            .frame(height: AppLine.hairline)
    }
}

// MARK: - Step 1: Threshold

private struct ThresholdStepView: View {
    let onContinue: () -> Void

    @Environment(ConsecrationViewModel.self) private var viewModel

    /// The cathedral-window arch that frames the Coronation — the same
    /// visual language as the Home hero
    private var arch: GothicArchShape { GothicArchShape(riseRatio: 0.34) }

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                Spacer(minLength: 10)

                // The Coronation of the Virgin (Velázquez): Mary crowned
                // by the Trinity — the image of Totus Tuus, and the
                // mystery this 33-day path ends on
                arch
                    .fill(AppColors.cardBackground)
                    .frame(height: 292)
                    .overlay(
                        CachedAssetImage("glorious_coronation")
                            .aspectRatio(contentMode: .fill)
                            .overlay(Color.black.opacity(0.15))
                    )
                    .clipShape(arch)
                    // The clip is drawn, not hit-tested: the filled painting
                    // stood above the arch and took Skip's taps from it.
                    // The arch is a picture, never a control
                    .allowsHitTesting(false)
                    .overlay(
                        arch.strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                    )
                    .overlay(
                        arch.inset(by: 5)
                            .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
                    )
                    .breathingGlow(
                        AppColors.gold,
                        radius: 18,
                        dimOpacity: 0.10,
                        brightOpacity: 0.22,
                        period: 3.8
                    )
                    .staggeredReveal(delay: 0.1)

                Spacer(minLength: 12)

                VStack(spacing: 14) {
                    ConsecrationIntroKicker(text: "ALL YOURS")

                    Text("Consecration to Mary")
                        .font(AppFonts.headlineFont(28))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)

                    Text("A 33-day preparation to give yourself to Jesus through Mary")
                        .font(AppFonts.italicFont(17))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .staggeredReveal(delay: 0.4)

                // A finished consecration is honored, not forgotten
                if viewModel.completedProgress != nil {
                    Spacer(minLength: 10)
                    completedNote
                        .staggeredReveal(delay: 0.55)
                }

                Spacer(minLength: 12)

                OnboardingContinueButton(title: "Learn how it works", action: onContinue)
                    .staggeredReveal(delay: 0.7)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }

    private var completedNote: some View {
        HStack(spacing: 8) {
            AppIcon("ph-seal-check-fill", size: 15)
            Text("You completed this consecration. Many renew it each year.")
                .font(AppFonts.bodyFont(13))
                .lineSpacing(3)
        }
        .foregroundColor(AppColors.gold)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.gold.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Step 2: The Devotion

/// The Annunciation over the head of page 2: Mary's own yes, the act a
/// consecration to her renews. Dark at the very top for the bar, clear
/// through the middle, and dissolving to clear at its foot — a plate
/// never ends on an edge.
private struct AnnunciationPlate: View {
    var body: some View {
        // Held about the angel and Mary, a little above the middle
        CachedAssetImage("joyful_annunciation", focal: UnitPoint(x: 0.5, y: 0.3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.55), location: 0),
                        .init(color: .black.opacity(0), location: 0.3),
                        .init(color: .black.opacity(0), location: 0.6),
                        .init(color: AppColors.background.opacity(0.7), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.55),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The words stand at the foot of the page, beneath the painting that
/// fills the room above them, and reach up into its dissolving foot.
private struct DevotionStepView: View {
    let bottomClearance: CGFloat
    let onContinue: () -> Void

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                // The painting's room: all that the words leave, and never
                // less than the bar's own depth onto it
                Spacer(minLength: 72)

                VStack(spacing: 14) {
                    ConsecrationIntroKicker(text: "The devotion")
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

                    Text("Everything you are, given to Jesus through Mary")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
                        .accessibilityAddTraits(.isHeader)

                    OrnamentDivider(showsCross: false)
                        .frame(width: 150)
                }
                .padding(.horizontal, 28)
                .devotionalEntrance()

                VStack(alignment: .leading, spacing: 14) {
                    line("I", Text("Your prayers, works, joys and sufferings, placed in her hands"))
                        .devotionalEntrance(delay: 0.08)

                    line("II", Text("A renewal of the promises of your baptism"))
                        .devotionalEntrance(delay: 0.16)

                    // The book by its full name: a newcomer has not heard of it
                    line(
                        "III",
                        Text("The way St. Louis de Montfort taught in his book \(Text("True Devotion to Mary").font(AppFonts.readingItalicFont(17)))")
                    )
                    .devotionalEntrance(delay: 0.24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 20)

                OnboardingContinueButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .devotionalEntrance(delay: 0.32)
            }
            .padding(.bottom, bottomClearance)
        }
    }

    /// One line of what the devotion is. The numeral is ornament, a
    /// printed list's, and VoiceOver reads the line alone.
    private func line(_ numeral: String, _ text: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(numeral)
                .font(AppFonts.labelFont(13))
                .foregroundColor(AppColors.gold)
                .frame(width: 18, alignment: .leading)
                .accessibilityHidden(true)

            text
                .font(AppFonts.readingFont(17))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Step 3: Each Day

/// What one day of the preparation holds, shown as the first day itself:
/// its title, its prayers and its readings read from the bundled plan,
/// in the order the day's page sets them — the prayers, then the
/// readings, then the reflection.
///
/// The page names what a day holds and never how long it takes. The
/// design offered "About fifteen quiet minutes", but the app gives no
/// estimate of time anywhere, and none would be true for long: the
/// second week adds a whole Rosary to every day.
private struct RhythmStepView: View {
    let bottomClearance: CGFloat
    let onContinue: () -> Void

    private var firstDay: ConsecrationDay? { ConsecrationData.day(1) }

    /// "Come, Creator Spirit · Hail, Star of the Sea · …", in English:
    /// the hymns' Latin names are their second names, not their first
    private var prayers: String {
        ConsecrationData.prayers(for: .preparatory)
            .map(\.title)
            .joined(separator: " \u{00B7} ")
    }

    /// "Matthew 5:1-19 · Guidance for the Twelve Days"
    private var readings: String {
        (firstDay?.readings ?? [])
            .sorted { $0.order < $1.order }
            .map(\.title)
            .joined(separator: " \u{00B7} ")
    }

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                VStack(spacing: 12) {
                    ConsecrationIntroKicker(text: "Each day")

                    Text("The same three steps each day")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text("Here is what your first day looks like.")
                        .font(AppFonts.italicFont(17))
                        .foregroundColor(AppColors.accentSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .devotionalEntrance()

                Spacer(minLength: 16)

                dayCard
                    .padding(.horizontal, 20)
                    .devotionalEntrance(delay: 0.08)

                Spacer(minLength: 14)

                // No guilt: the schedule serves the reader, not the reverse
                Text("Miss a day? Every day stays open. Return whenever you can.")
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
                    .devotionalEntrance(delay: 0.16)

                Spacer(minLength: 16)

                OnboardingContinueButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, 20)
                    .devotionalEntrance(delay: 0.24)
            }
            .padding(.bottom, bottomClearance)
        }
    }

    // MARK: Day 1, previewed

    private var dayCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("DAY 1")
                    .font(AppFonts.labelFont(11))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                Spacer(minLength: 0)

                if let title = firstDay?.title {
                    Text(title)
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)

            ConsecrationIntroRule()

            stepRow("I", title: "Pray", detail: prayers)

            ConsecrationIntroRule()

            stepRow("II", title: "Read", detail: readings)

            ConsecrationIntroRule()

            // The card's own padding closes beneath the last step
            stepRow("III", title: "Reflect", detail: "One question to sit with, and a journal to answer it in.", isLast: true)
        }
        .sacredCard(padding: 20, elevated: true)
    }

    /// One step of the day: its numeral in a ring (ornament), its name,
    /// and what it holds on Day 1
    private func stepRow(_ numeral: String, title: String, detail: String, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(numeral)
                .font(AppFonts.labelFont(11))
                .foregroundColor(AppColors.gold)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)

                Text(detail)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 16)
        .padding(.bottom, isLast ? 0 : 16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Step 4: The Journey

private struct JourneyStepView: View {
    let bottomClearance: CGFloat
    let onContinue: () -> Void

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                VStack(spacing: 14) {
                    ConsecrationIntroKicker(text: "THE JOURNEY")

                    Text("The Path to Consecration")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                }
                .staggeredReveal(delay: 0.1)

                Spacer(minLength: 14)

                VStack(spacing: 10) {
                    ForEach(Array(ConsecrationPhase.allCases.enumerated()), id: \.element) { index, phase in
                        journeyRow(phase, delay: 0.35 + Double(index) * 0.15)
                    }
                }

                // "Miss a day?" stood here; it is on page 3 now, beside
                // the day it speaks of
                Spacer(minLength: 12)

                OnboardingContinueButton(
                    title: "Choose my consecration day",
                    action: onContinue
                )
                .staggeredReveal(delay: 1.15)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, bottomClearance)
        }
    }

    private func journeyRow(_ phase: ConsecrationPhase, delay: Double) -> some View {
        let isFinal = phase == .consecrationDay

        return HStack(spacing: 14) {
            Text(dayRangeLabel(phase))
                .font(AppFonts.bodyFont(12))
                .foregroundColor(phase.accentColor)
                .frame(width: 52, alignment: .leading)

            // The phase's accent — the same quiet hue journey the 33 days
            // themselves walk, brightening toward the consecration
            Capsule()
                .fill(phase.accentColor)
                .frame(width: 3, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayName)
                    .font(AppFonts.headlineFont(isFinal ? 16 : 15))
                    .foregroundColor(isFinal ? AppColors.goldLight : AppColors.cream)

                Text(phase.subtitle)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground.opacity(isFinal ? 0.8 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFinal ? AppColors.gold.opacity(0.4) : AppColors.gold.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .staggeredReveal(delay: delay)
    }

    private func dayRangeLabel(_ phase: ConsecrationPhase) -> String {
        let range = phase.dayRange
        if phase == .consecrationDay { return "Consecration Day" }
        return range.count == 1 ? "Day \(range.lowerBound)" : "\(range.lowerBound)\u{2013}\(range.upperBound)"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationOnboardingView(path: .constant([]), hidesTabBar: .constant(false))
            .environment(ConsecrationViewModel())
    }
}
