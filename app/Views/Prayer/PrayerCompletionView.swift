//
//  PrayerCompletionView.swift
//  Lumen Viae
//
//  Displayed after completing all 5 mysteries of the Rosary.
//  Automatically records the completed prayer session to SwiftData and displays:
//  - Completion badge with checkmark
//  - Inspirational scripture quote
//  - Options to record reflection or return home
//

import SwiftUI
import SwiftData

struct PrayerCompletionView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    let meditationSet: MeditationSet

    /// Whether the session has been recorded (to prevent duplicates)
    @State private var hasRecordedSession = false

    /// Controls the post-prayer journal editor sheet
    @State private var showingJournalEditor = false

    /// Streak after recording this session (shown as celebration feedback)
    @State private var streakDays = 0

    /// Lifetime Rosaries completed, including this one
    @State private var totalRosaries = 0

    /// Drives the streak chip's entrance animation
    @State private var showStreakChip = false

    /// Devotional milestone reached exactly today (Triduum, Novena...), if any
    @State private var reachedMilestone: StreakMilestone?

    /// Sequenced reveal of the quote card and action buttons
    @State private var showQuote = false
    @State private var showButtons = false

    // Quote from MockDataService
    private var quote: (text: String, author: String) {
        MockDataService.todaysQuote
    }

    var body: some View {
        ZStack {
            // Full-screen background image
            CompletionBackgroundImage(
                gradientColors: meditationSet.mysteryCategory?.gradientColors ?? []
            )

            // Golden motes drifting upward, like incense in candlelight
            SacredParticles()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Content overlay
            VStack(spacing: 0) {
                // Header
                CompletionHeader(onClose: { router.popToRoot() })

                Spacer()

                // Completion badge and title — the sacred reveal:
                // light blooms, the ring draws itself, the check arrives,
                // and rings of light resonate outward like a bell
                CompletionBadge()
                    .padding(.bottom, 16)

                // Streak feedback - the key "come back tomorrow" moment
                if streakDays > 0 {
                    StreakCelebrationChip(
                        streakDays: streakDays,
                        totalRosaries: totalRosaries
                    )
                    .opacity(showStreakChip ? 1 : 0)
                    .scaleEffect(showStreakChip ? 1 : 0.85)
                    .padding(.bottom, reachedMilestone == nil ? 24 : 12)
                }

                // Devotional milestone celebration (shown only the day
                // a milestone is reached — rare enough to stay special)
                if let milestone = reachedMilestone {
                    MilestoneCelebrationCard(milestone: milestone)
                        .opacity(showStreakChip ? 1 : 0)
                        .scaleEffect(showStreakChip ? 1 : 0.9)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                }

                // Quote card
                CompletionQuoteCard(
                    quote: quote.text,
                    author: quote.author
                )
                .padding(.horizontal, 20)
                .opacity(showQuote ? 1 : 0)
                .offset(y: showQuote ? 0 : 16)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Record Devotion (Journal) - Primary
                    Button(action: { showingJournalEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 18))

                            Text("RECORD DEVOTION")
                                .font(AppFonts.bodyFont(16))
                                .tracking(2)
                        }
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.goldLight)
                        .cornerRadius(30)
                    }

                    // Return Home - Secondary
                    Button(action: { router.popToRoot() }) {
                        Text("RETURN HOME")
                            .font(AppFonts.bodyFont(16))
                            .tracking(2)
                            .foregroundColor(AppColors.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .opacity(showButtons ? 1 : 0)
            }
        }
        .navigationBarHidden(true)
        .sensoryFeedback(.success, trigger: showStreakChip)
        .onAppear {
            recordPrayerSession()

            withAnimation(.easeOut(duration: 0.8).delay(1.5)) { showQuote = true }
            withAnimation(.easeOut(duration: 0.8).delay(2.1)) { showButtons = true }
        }
        .sheet(isPresented: $showingJournalEditor) {
            JournalEntryEditorView(
                category: meditationSet.mysteryCategory,
                mysteryTitle: nil,
                mysteryIndex: nil,
                isMidPrayer: false
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    /// Records the completed prayer session to SwiftData.
    private func recordPrayerSession() {
        guard !hasRecordedSession else { return }
        guard let category = meditationSet.mysteryCategory else { return }

        let session = PrayerSession(
            category: category,
            completedAt: Date(),
            meditationType: meditationSet.name
        )
        modelContext.insert(session)
        hasRecordedSession = true

        // Compute progress feedback now that this session counts
        let service = PrayerHistoryService(modelContext: modelContext)
        streakDays = service.currentStreak()
        totalRosaries = service.totalRosaries()

        // Milestone fires only when today's prayer is the first of the day
        // (streak just advanced to exactly this milestone)
        if service.sessions(on: Date()).count == 1 {
            reachedMilestone = StreakMilestone.milestone(reachedAt: streakDays)
        }

        // The chip (and its success haptic) lands after the badge's
        // reveal sequence: bloom → ring draws → check → title.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showStreakChip = true
            }
        }
    }
}

// MARK: - Sacred Particles

/// Golden motes drifting slowly upward across the whole screen,
/// like incense smoke or dust caught in candlelight. Each particle's
/// path is deterministic (seeded), so the field is stable and calm.
struct SacredParticles: View {
    /// Number of motes on screen
    private let count = 26

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                for i in 0..<count {
                    let seed = Double(i)

                    // Each mote rises at its own gentle pace...
                    let speed = 0.010 + 0.020 * random(seed, 1)
                    let phase = random(seed, 2)
                    let progress = (t * speed + phase).truncatingRemainder(dividingBy: 1.0)
                    let y = size.height * (1.0 - progress)

                    // ...swaying side to side as it goes
                    let baseX = size.width * random(seed, 3)
                    let sway = sin(t * (0.3 + 0.5 * random(seed, 4)) + seed * 2.4) * 16
                    let x = baseX + sway

                    // Fade in near the bottom, out near the top
                    let fade = sin(progress * .pi)
                    let opacity = fade * (0.10 + 0.35 * random(seed, 5))
                    let radius = 1.0 + 2.4 * random(seed, 6)

                    let rect = CGRect(x: x - radius, y: y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.fill(
                        Ellipse().path(in: rect),
                        with: .color(AppColors.goldLight.opacity(opacity))
                    )
                }
            }
        }
    }

    /// Deterministic pseudo-random in 0..<1 from a seed and salt.
    private func random(_ seed: Double, _ salt: Double) -> Double {
        let v = sin(seed * 127.1 + salt * 311.7) * 43758.5453
        return v - v.rounded(.down)
    }
}

// MARK: - Glow Bloom

/// A soft radial light that blooms outward behind the badge —
/// the first beat of the completion sequence.
struct GlowBloom: View {
    @State private var bloomed = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        AppColors.gold.opacity(0.30),
                        AppColors.gold.opacity(0.08),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
            .scaleEffect(bloomed ? 1 : 0.15)
            .opacity(bloomed ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 1.6).delay(0.1)) {
                    bloomed = true
                }
            }
    }
}

// MARK: - Radiant Rays

/// Fine rays of gold light turning almost imperceptibly behind the
/// badge — a monstrance-like halo rather than confetti.
struct RadiantRays: View {
    @State private var angle: Angle = .degrees(0)
    @State private var visible = false

    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.32), AppColors.gold.opacity(0)],
                            startPoint: .center,
                            endPoint: .top
                        )
                    )
                    // Alternate long and short rays, like a monstrance
                    .frame(width: 2, height: index.isMultiple(of: 2) ? 130 : 92)
                    .offset(y: index.isMultiple(of: 2) ? -65 : -46)
                    .rotationEffect(.degrees(Double(index) * 22.5))
            }
        }
        .rotationEffect(angle)
        .opacity(visible ? 0.7 : 0)
        .blur(radius: 1)
        .onAppear {
            withAnimation(.easeIn(duration: 1.8).delay(0.6)) {
                visible = true
            }
            withAnimation(.linear(duration: 75).repeatForever(autoreverses: false)) {
                angle = .degrees(360)
            }
        }
    }
}

// MARK: - Resonance Ring

/// A single ring of light that expands outward from the badge and
/// fades — like the resonance after a bell is struck.
struct ResonanceRing: View {
    /// Seconds to wait before the ring sounds
    let delay: Double

    @State private var expand = false

    var body: some View {
        Circle()
            .strokeBorder(AppColors.gold.opacity(expand ? 0 : 0.5), lineWidth: 1)
            .frame(width: 64, height: 64)
            .scaleEffect(expand ? 4.4 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 2.2).delay(delay)) {
                    expand = true
                }
            }
    }
}

// MARK: - Milestone Celebration Card

/// One-time devotional milestone reward: "Novena — nine days of unbroken
/// devotion." Shown only on the day the milestone is reached.
struct MilestoneCelebrationCard: View {
    let milestone: StreakMilestone

    /// Drives the icon's celebratory bounce
    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.goldLight)
                    .symbolEffect(.bounce, value: celebrate)

                Text("MILESTONE REACHED")
                    .font(AppFonts.bodyFont(11))
                    .tracking(3)
                    .foregroundColor(AppColors.goldLight)

                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.goldLight)
                    .symbolEffect(.bounce, value: celebrate)
            }

            HStack(spacing: 10) {
                Image(systemName: milestone.icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(AppColors.gold)
                    .symbolEffect(.bounce, options: .speed(0.8), value: celebrate)

                Text(milestone.name)
                    .font(AppFonts.headlineFont(24))
                    .foregroundColor(AppColors.cream)
            }

            Text(milestone.blessing)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.gold.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppColors.goldLight.opacity(0.7), AppColors.gold.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            // The card fades in at ~1.8s with the streak chip;
            // the sparkle bounce lands just after it settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                celebrate = true
            }
        }
    }
}

// MARK: - Streak Celebration Chip

/// Progress feedback shown right after completing the Rosary:
/// current streak plus lifetime Rosaries offered.
struct StreakCelebrationChip: View {
    let streakDays: Int
    let totalRosaries: Int

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.goldLight)

                Text(streakDays == 1 ? "DAY 1 STREAK" : "\(streakDays) DAY STREAK")
                    .font(AppFonts.bodyFont(13))
                    .tracking(2)
                    .foregroundColor(AppColors.cream)
            }

            Rectangle()
                .fill(AppColors.gold.opacity(0.4))
                .frame(width: 1, height: 14)

            Text(totalRosaries == 1 ? "1 ROSARY OFFERED" : "\(totalRosaries) ROSARIES OFFERED")
                .font(AppFonts.bodyFont(13))
                .tracking(2)
                .foregroundColor(AppColors.cream)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(AppColors.background.opacity(0.8))
        )
        .overlay(
            Capsule()
                .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Background Image

struct CompletionBackgroundImage: View {
    var gradientColors: [Color] = []

    var body: some View {
        ZStack {
            // Base gradient with category colors if available
            LinearGradient(
                colors: gradientColors.isEmpty
                    ? [Color(hex: "0d0d1a"), Color(hex: "1a1a2e"), Color(hex: "0d0d1a")]
                    : gradientColors + [Color(hex: "1a1a2e"), Color(hex: "0d0d1a")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Gradient overlay for text readability
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "1a1a2e").opacity(0.6),
                    Color(hex: "1a1a2e").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header

struct CompletionHeader: View {
    var onClose: () -> Void = {}

    var body: some View {
        HStack {
            Text("LUMEN VIAE")
                .font(AppFonts.bodyFont(12))
                .tracking(4)
                .foregroundColor(AppColors.cream.opacity(0.8))

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.gold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Completion Badge

/// The animated seal of completion. The sequence, timed like a rite:
///   0.1s  light blooms softly behind the circle
///   0.2s  the circle draws itself closed
///   0.6s  the rays of the halo begin to appear
///   1.0s  the checkmark arrives; rings of light resonate outward
///   1.2s  the title emerges from light (blur) into focus
struct CompletionBadge: View {

    /// Circle stroke progress (0 → 1 draws it closed)
    @State private var circleProgress: CGFloat = 0

    /// Checkmark entrance
    @State private var showCheck = false

    /// Title reveal
    @State private var showTitle = false

    var body: some View {
        VStack(spacing: 16) {
            // Checkmark circle, haloed by bloom, rays, and resonance rings.
            // The halo lives in .background so its size never shifts layout.
            ZStack {
                Circle()
                    .trim(from: 0, to: circleProgress)
                    .stroke(
                        AppColors.gold.opacity(0.6),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)

                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.gold)
                    .scaleEffect(showCheck ? 1 : 0.3)
                    .opacity(showCheck ? 1 : 0)
            }
            .frame(width: 56, height: 56)
            .background {
                ZStack {
                    GlowBloom()
                    RadiantRays()
                    ResonanceRing(delay: 1.1)
                    ResonanceRing(delay: 1.45)
                }
            }

            // Title, emerging from light into focus
            VStack(spacing: 4) {
                Text("THE ROSARY")
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.gold)

                Text("IS COMPLETED")
                    .font(AppFonts.headlineFont(28))
                    .foregroundColor(AppColors.gold)
            }
            .opacity(showTitle ? 1 : 0)
            .blur(radius: showTitle ? 0 : 8)
            .offset(y: showTitle ? 0 : 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).delay(0.2)) {
                circleProgress = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.0)) {
                showCheck = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(1.2)) {
                showTitle = true
            }
        }
    }
}

// MARK: - Quote Card

struct CompletionQuoteCard: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 16) {
            // Opening quote mark
            Text("\u{201C}")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(AppColors.gold.opacity(0.5))
                .offset(y: 10)

            // Quote text
            Text(quote)
                .font(AppFonts.italicFont(18))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Author with decorative lines
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.5))
                    .frame(width: 24, height: 1)

                Text(author.uppercased())
                    .font(AppFonts.bodyFont(12))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.5))
                    .frame(width: 24, height: 1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.background.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    PrayerCompletionView(meditationSet: MockDataService.meditationSet(for: .joyful))
        .environment(AppRouter())
}
