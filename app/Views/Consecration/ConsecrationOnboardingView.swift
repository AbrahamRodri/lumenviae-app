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

    @Binding var path: NavigationPath
    @Environment(ConsecrationViewModel.self) private var viewModel

    /// Once the introduction has been walked (or skipped), later visits
    /// go straight to the date step — after a restart, re-reading four
    /// pages of catechesis would be a wall, not a welcome.
    @AppStorage("hasSeenConsecrationOnboarding") private var hasSeenOnboarding = false

    @State private var step: ConsecrationOnboardingStep = .threshold

    /// Drives the slide direction of step transitions
    @State private var movingForward = true

    /// Guards the initial returning-user jump so it doesn't re-fire when
    /// this view reappears after a push
    @State private var hasAppeared = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

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
                        DevotionStepView(onContinue: { advance(to: .rhythm) })
                            .transition(stepTransition)
                    case .rhythm:
                        RhythmStepView(onContinue: { advance(to: .journey) })
                            .transition(stepTransition)
                    case .journey:
                        JourneyStepView(onContinue: { advance(to: .chooseDay) })
                            .transition(stepTransition)
                    case .chooseDay:
                        ConsecrationDateSelectionView()
                            .transition(stepTransition)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            if hasSeenOnboarding {
                step = .chooseDay
            }
        }
    }

    // MARK: - Navigation

    private func advance(to newStep: ConsecrationOnboardingStep) {
        movingForward = true
        withAnimation(.easeInOut(duration: 0.4)) {
            step = newStep
        }
        if newStep == .chooseDay {
            hasSeenOnboarding = true
        }
    }

    private func goBack() {
        guard let previous = ConsecrationOnboardingStep(rawValue: step.rawValue - 1) else { return }
        movingForward = false
        withAnimation(.easeInOut(duration: 0.4)) {
            step = previous
        }
    }

    private func skipToChooser() {
        movingForward = true
        withAnimation(.easeInOut(duration: 0.4)) {
            step = .chooseDay
        }
        hasSeenOnboarding = true
    }

    private var stepTransition: AnyTransition {
        movingForward
            ? .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
            : .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            // Progress dots (centered independently of the side buttons)
            HStack(spacing: 6) {
                ForEach(ConsecrationOnboardingStep.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? AppColors.gold : AppColors.cardBackground)
                        .frame(width: s == step ? 20 : 8, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
                }
            }

            HStack {
                // Back — also how a returning user reaches the
                // educational pages again from the date step
                if step != .threshold {
                    Button {
                        goBack()
                    } label: {
                        AppIcon("ph-caret-left", size: 16)
                            .foregroundColor(AppColors.cream.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.cardBackground))
                    }
                    .accessibilityLabel("Back")
                }

                Spacer()

                if step.isEducational {
                    Button("Skip") {
                        skipToChooser()
                    }
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(height: 36)
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Staggered Reveal

/// Fades content in with a slight rise, on a delay — so each step's
/// content arrives as a paced sequence rather than a wall.
private struct StaggeredReveal: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
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

/// Gold gradient primary button used by every step
private struct OnboardingContinueButton: View {
    let title: String
    var icon: String = "ph-arrow-right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(AppFonts.headlineFont(16))
                AppIcon(icon, size: 15)
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

/// Small gold tracked label above each step's title
private struct StepLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFonts.bodyFont(12))
            .tracking(3)
            .foregroundColor(AppColors.gold)
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
                Spacer(minLength: 16)

                // The Coronation of the Virgin (Velázquez): Mary crowned
                // by the Trinity — the image of Totus Tuus, and the
                // mystery this 33-day path ends on
                arch
                    .fill(AppColors.cardBackground)
                    .frame(height: 350)
                    .overlay(
                        CachedAssetImage("glorious_coronation")
                            .aspectRatio(contentMode: .fill)
                            .overlay(Color.black.opacity(0.15))
                    )
                    .clipShape(arch)
                    .overlay(
                        arch.strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                    )
                    .overlay(
                        arch.inset(by: 5)
                            .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 0.5)
                    )
                    .breathingGlow(
                        AppColors.gold,
                        radius: 18,
                        dimOpacity: 0.10,
                        brightOpacity: 0.22,
                        period: 3.8
                    )
                    .staggeredReveal(delay: 0.1)

                Spacer(minLength: 28)

                VStack(spacing: 14) {
                    StepLabel(text: "TOTUS TUUS")

                    Text("Total Consecration")
                        .font(AppFonts.headlineFont(32))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)

                    Text("to Jesus through Mary")
                        .font(AppFonts.italicFont(18))
                        .foregroundColor(AppColors.textSecondary)
                }
                .staggeredReveal(delay: 0.4)

                // A finished consecration is honored, not forgotten
                if viewModel.completedProgress != nil {
                    Spacer(minLength: 16)
                    completedNote
                        .staggeredReveal(delay: 0.55)
                }

                Spacer(minLength: 28)

                OnboardingContinueButton(title: "Discover the Devotion", action: onContinue)
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

private struct DevotionStepView: View {
    let onContinue: () -> Void

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    StepLabel(text: "THE DEVOTION")

                    Text("What Is Total Consecration?")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                }
                .staggeredReveal(delay: 0.1)

                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    // Icons are Christicons, chosen for meaning: the rosary
                    // as the Marian way, the heart that receives the gift,
                    // the baptismal candle behind the promise.
                    devotionCard(
                        icon: "ch-rosary",
                        title: "The Way",
                        text: "Give yourself entirely to Jesus Christ through the hands of His mother — the way St. Louis de Montfort taught in True Devotion to Mary.",
                        delay: 0.35
                    )

                    devotionCard(
                        icon: "ch-sacred-heart",
                        title: "The Gift",
                        text: "Your prayers, works, joys, and sufferings — all of it entrusted to Mary, who forms Christ in you.",
                        delay: 0.55
                    )

                    devotionCard(
                        icon: "ch-candle",
                        title: "The Promise",
                        text: "A perfect renewal of your baptismal vows — everything given back to God, nothing held back.",
                        delay: 0.75
                    )
                }

                Spacer(minLength: 28)

                OnboardingContinueButton(title: "Continue", action: onContinue)
                    .staggeredReveal(delay: 0.95)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }

    private func devotionCard(icon: String, title: String, text: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 14) {
            AppIcon(icon, size: 22)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppColors.gold.opacity(0.1))
                        .overlay(Circle().stroke(AppColors.gold.opacity(0.25), lineWidth: 1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)

                Text(text)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground.opacity(0.6))
        )
        .staggeredReveal(delay: delay)
    }
}

// MARK: - Step 3: The Daily Rhythm

private struct RhythmStepView: View {
    let onContinue: () -> Void

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    StepLabel(text: "EACH DAY")

                    Text("A Short Daily Rhythm")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                }
                .staggeredReveal(delay: 0.1)

                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    rhythmRow(
                        icon: "ch-praying-hands",
                        title: "Pray",
                        text: "The prayers of the preparation — Veni Creator, Ave Maris Stella, the litanies — with chanted audio.",
                        delay: 0.35
                    )

                    rhythmRow(
                        icon: "ch-bible",
                        title: "Read",
                        text: "A short spiritual reading chosen for the day, from Scripture and True Devotion.",
                        delay: 0.55
                    )

                    rhythmRow(
                        icon: "ph-note-pencil",
                        title: "Reflect",
                        text: "One question to sit with, and a journal to answer it in.",
                        delay: 0.75
                    )
                }

                Spacer(minLength: 20)

                Text("Ten to fifteen minutes a day.")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .staggeredReveal(delay: 0.9)

                Spacer(minLength: 28)

                OnboardingContinueButton(title: "Continue", action: onContinue)
                    .staggeredReveal(delay: 1.05)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }

    private func rhythmRow(icon: String, title: String, text: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 16) {
            AppIcon(icon, size: 22)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppColors.gold.opacity(0.1))
                        .overlay(Circle().stroke(AppColors.gold.opacity(0.25), lineWidth: 1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.headlineFont(17))
                    .foregroundColor(AppColors.cream)

                Text(text)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground.opacity(0.6))
        )
        .staggeredReveal(delay: delay)
    }
}

// MARK: - Step 4: The Journey

private struct JourneyStepView: View {
    let onContinue: () -> Void

    var body: some View {
        StaticSlide {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    StepLabel(text: "THE JOURNEY")

                    Text("The Path to Consecration")
                        .font(AppFonts.headlineFont(26))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.center)
                }
                .staggeredReveal(delay: 0.1)

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    ForEach(Array(ConsecrationPhase.allCases.enumerated()), id: \.element) { index, phase in
                        journeyRow(phase, delay: 0.35 + Double(index) * 0.15)
                    }
                }

                Spacer(minLength: 20)

                // No-guilt: the schedule serves the user, not the reverse
                Text("Miss a day? Every day stays open — return whenever you can.")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .staggeredReveal(delay: 1.15)

                Spacer(minLength: 28)

                OnboardingContinueButton(
                    title: "Choose My Consecration Day",
                    icon: "ph-calendar-dots",
                    action: onContinue
                )
                .staggeredReveal(delay: 1.3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
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
        return range.count == 1 ? "Day \(range.lowerBound)" : "\(range.lowerBound)\u{2013}\(range.upperBound)"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationOnboardingView(path: .constant(NavigationPath()))
            .environment(ConsecrationViewModel())
    }
}
