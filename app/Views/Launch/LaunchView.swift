//
//  LaunchView.swift
//  Lumen Viae
//
//  Splash screen shown when the app first launches.
//

import SwiftUI

/// Splash screen displayed while the app loads.
///
/// Shows the launch mark where the system launch screen left it, fades
/// in the app's name beneath it, then transitions to the main content once images are preloaded.
struct LaunchView: View {

    // MARK: - State

    /// Fades in the theme's ground and the words beneath the mark
    @State private var opacity: Double = 0

    /// Called when launch sequence completes
    var onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background: the launch screen's own flat ground first, so
            // the hand-over from it is seamless, then the theme's
            // gradient fading in over it
            Color("LaunchBackground")
                .ignoresSafeArea()

            AppColors.appGradient
                .ignoresSafeArea()
                .opacity(opacity)

            // The mark stands where the system launch screen drew it
            // (`LaunchMark` at its own size, centred on the whole
            // screen over `LaunchBackground`), already in full, so the
            // hand-over from the system's screen to this one does not
            // move it; only the words beneath it fade in
            Color.clear.overlay {
                Image("LaunchMark")
                    .accessibilityHidden(true)
                    .overlay(alignment: .bottom) {
                        // App name
                        VStack(spacing: 10) {
                            Text("LUMEN VIAE")
                                .font(AppFonts.headlineFont(30))
                                .tracking(6)
                                .foregroundColor(AppColors.cream)

                            Text("Light of the Way")
                                .font(AppFonts.italicFont(16))
                                .foregroundColor(AppColors.gold.opacity(0.8))
                        }
                        .fixedSize()
                        // Hung 24 points under the mark's foot
                        .alignmentGuide(.bottom) { d in d[.top] - 24 }
                        .opacity(opacity)
                    }
            }
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Loading indicator
                ProgressView()
                    .tint(AppColors.gold)
                    .scaleEffect(0.8)

                Text("Preparing your prayer experience...")
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.bottom, 60)
            }
            .opacity(opacity)
        }
        .task {
            // Track start time to ensure minimum display duration —
            // just long enough for the words to fade in; image preloading
            // finishes in well under a second.
            let startTime = Date()
            let minimumDuration: TimeInterval = 1.0

            // Animate in
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
            }

            // Warm the API and prefetch today's meditation sets so the
            // Pray button starts instantly. Fire-and-forget: a Fly.io cold
            // start can take many seconds and must not hold the splash
            // hostage — the Pray button shows a spinner if tapped early.
            MeditationCacheService.shared.startPrefetch(category: ScheduleService.categoryForToday())

            // Preload images while showing splash
            await ImageCacheService.shared.preloadImages()

            // Ensure at least 1 second has passed
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < minimumDuration {
                let remaining = minimumDuration - elapsed
                try? await Task.sleep(for: .seconds(remaining))
            }

            // Transition to main app
            onComplete()
        }
    }
}

#Preview {
    LaunchView(onComplete: {})
}
