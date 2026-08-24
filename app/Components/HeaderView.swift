//
//  HeaderView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//
//  Home header: the wordmark alone. The old menu button moved into the
//  Me page's Library card, and the streak flame into its Prayer Streak
//  card — the home screen keeps a single job: today's prayer.
//

import SwiftUI

struct HeaderView: View {
    /// Opens Explore. A small glass in the corner, not a bar — the
    /// header stays the wordmark's.
    var onSearchTap: (() -> Void)?

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(Constants.appName)
                    .font(AppFonts.titleFont(22))
                    .tracking(4)
                    .foregroundColor(AppColors.gold)

                Text(Constants.appTagline)
                    .font(AppFonts.bodyFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            if let onSearchTap {
                HStack {
                    Spacer()

                    Button(action: onSearchTap) {
                        AppIcon("ph-magnifying-glass", size: 18)
                            .foregroundColor(AppColors.gold.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}

// MARK: - StreakFlame

/// The streak tracker in the header, with a one-time attention arc when
/// the screen loads:
///
///   1. The streak number appears large, pulsing twice to catch the eye
///   2. It becomes the flame, which glows warmly for a moment
///   3. Everything settles into a small, still icon — static from then
///      on, so it never competes for attention after the initial load
///
/// At rest: lit gold when today's Rosary is done, a dim ember when not.
struct StreakFlame: View {
    let streak: Int
    let isLit: Bool
    var onTap: (() -> Void)?

    /// True while the opening pulsing number is on screen.
    /// Seeded in init so the number is there from the first frame —
    /// no flame flash before the intro starts.
    @State private var showingNumber: Bool

    /// True during the flame's brief warm glow after the hand-off
    @State private var glowing = false

    /// Drives the number's double pulse (fires once)
    @State private var pulseTrigger = false

    /// Small bounce as tap feedback
    @State private var flare = false

    init(streak: Int, isLit: Bool, onTap: (() -> Void)? = nil) {
        self.streak = streak
        self.isLit = isLit
        self.onTap = onTap
        _showingNumber = State(initialValue: streak > 0)
    }

    var body: some View {
        Button {
            flare.toggle()
            onTap?()
        } label: {
            ZStack {
                // Act I: the pulsating streak number
                if showingNumber {
                    Text("\(streak)")
                        .font(AppFonts.headlineFont(22))
                        .foregroundColor(AppColors.goldLight)
                        .keyframeAnimator(
                            initialValue: 1.0,
                            trigger: pulseTrigger
                        ) { view, scale in
                            view.scaleEffect(scale)
                        } keyframes: { _ in
                            KeyframeTrack {
                                CubicKeyframe(1.0, duration: 0.3)
                                CubicKeyframe(1.3, duration: 0.35)
                                CubicKeyframe(1.0, duration: 0.35)
                                CubicKeyframe(1.25, duration: 0.35)
                                CubicKeyframe(1.0, duration: 0.4)
                            }
                        }
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }

                // Act II & III: the flame — briefly aglow, then at rest
                if !showingNumber {
                    VStack(spacing: 1) {
                        ZStack {
                            // Warm glow, present only during the hand-off
                            Circle()
                                .fill(AppColors.goldLight.opacity(0.4))
                                .frame(width: 30, height: 30)
                                .blur(radius: 6)
                                .opacity(glowing ? 1 : 0)

                            AppIcon("ph-flame-fill", size: 20)
                                .foregroundStyle(flameColor)
                                .keyframeAnimator(
                                    initialValue: 1.0,
                                    trigger: flare
                                ) { view, scale in
                                    view.scaleEffect(scale, anchor: .bottom)
                                } keyframes: { _ in
                                    KeyframeTrack {
                                        CubicKeyframe(1.18, duration: 0.16)
                                        CubicKeyframe(0.96, duration: 0.16)
                                        CubicKeyframe(1.0, duration: 0.18)
                                    }
                                }
                        }
                        .frame(height: 26)

                        // Streak count as the candle's base
                        if streak > 0 {
                            Text("\(streak)")
                                .font(AppFonts.headlineFont(12))
                                .foregroundColor(isLit ? AppColors.goldLight : AppColors.gold.opacity(0.6))
                        }
                    }
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear(perform: runIntro)
        .accessibilityLabel(streakAccessibilityLabel)
    }

    /// Flame color: brighter while glowing, gold at rest, dim ember when
    /// today's prayer hasn't happened yet.
    private var flameColor: LinearGradient {
        if glowing || isLit {
            return LinearGradient(
                colors: [AppColors.goldLight, AppColors.gold],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [AppColors.gold.opacity(0.45), AppColors.gold.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Plays the load-time sequence once: pulse → flame glow → still.
    private func runIntro() {
        // Nothing to announce without a streak — rest quietly from the start
        guard streak > 0, showingNumber else { return }

        pulseTrigger.toggle()

        // Hand off: the number becomes the flame, glowing warmly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                showingNumber = false
                glowing = true
            }

            // Settle: the glow fades and the icon goes still for good
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeOut(duration: 0.9)) {
                    glowing = false
                }
            }
        }
    }

    private var streakAccessibilityLabel: String {
        let base = streak == 1 ? "1 day prayer streak" : "\(streak) day prayer streak"
        return isLit ? "\(base), prayed today" : base
    }
}

#Preview {
    HeaderView()
        .background(AppColors.background)
}
