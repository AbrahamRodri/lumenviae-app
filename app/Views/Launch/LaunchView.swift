//
//  LaunchView.swift
//  Lumen Viae
//
//  Splash screen shown when the app first launches.
//

import SwiftUI

/// Splash screen displayed while the app loads.
///
/// Shows the app logo and name with an elegant fade-in animation,
/// then transitions to the main content once images are preloaded.
struct LaunchView: View {

    // MARK: - State

    /// Controls the fade-in animation of elements
    @State private var opacity: Double = 0

    /// Controls the scale animation of the logo
    @State private var scale: Double = 0.8

    /// Called when launch sequence completes
    var onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App icon/logo — a rosary, glowing like a votive candle
                AppIcon("ch-rosary", size: 88)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .breathingGlow(
                        AppColors.gold,
                        radius: 18,
                        dimOpacity: 0.25,
                        brightOpacity: 0.55,
                        period: 2.2
                    )
                    .scaleEffect(scale)

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
            // Track start time to ensure minimum display duration
            let startTime = Date()
            let minimumDuration: TimeInterval = 3.0

            // Animate in
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }

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
