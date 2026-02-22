//
//  ConsecrationPrayerFlowView.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION PRAYER FLOW - IMMERSIVE SEQUENTIAL PRAYER DISPLAY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Displays prayers one at a time in an immersive, full-screen view.
//  After the last prayer, navigates to the meditation view.
//
//  ═══════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - ConsecrationPrayerFlowView

struct ConsecrationPrayerFlowView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath

    let dayNumber: Int

    // MARK: - Environment

    @Environment(UserSettings.self) private var settings

    // MARK: - State

    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1.0

    // MARK: - Computed Properties

    private var prayers: [ConsecrationPrayer] {
        guard let phase = ConsecrationPhase.phase(for: dayNumber) else { return [] }
        return ConsecrationData.prayers(for: phase, language: settings.prayerLanguage)
    }

    private var currentPrayer: ConsecrationPrayer? {
        guard currentIndex < prayers.count else { return nil }
        return prayers[currentIndex]
    }

    private var isLastPrayer: Bool {
        currentIndex >= prayers.count - 1
    }

    private var phase: ConsecrationPhase? {
        ConsecrationPhase.phase(for: dayNumber)
    }

    // MARK: - Bilingual Formatting

    @ViewBuilder
    private func formattedPrayerText(_ content: String) -> some View {
        let lines = content.components(separatedBy: "\n")
        let isBilingual = settings.prayerLanguage == .both || settings.prayerLanguage == .latinUnderEnglish

        if isBilingual {
            formatBilingualPrayer(lines)
        } else {
            Text(content)
                .font(AppFonts.bodyFont(18))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
        }
    }

    @ViewBuilder
    private func formatBilingualPrayer(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty {
                    Spacer().frame(height: 4)
                } else if trimmed.contains("|||") {
                    formatBilingualPair(trimmed)
                } else {
                    Text(trimmed)
                        .font(AppFonts.bodyFont(18))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                }
            }
        }
    }

    @ViewBuilder
    private func formatBilingualPair(_ line: String) -> some View {
        let parts = line.components(separatedBy: "|||")

        VStack(alignment: .leading, spacing: 2) {
            if parts.count >= 1 {
                Text(parts[0].trimmingCharacters(in: .whitespaces))
                    .font(AppFonts.bodyFont(18))
                    .foregroundColor(AppColors.cream)
            }
            if parts.count >= 2 {
                Text(parts[1].trimmingCharacters(in: .whitespaces))
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.textSecondary.opacity(0.7))
                    .italic()
                    .padding(.leading, 12)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - use app gradient
            AppColors.appGradient
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Top Bar with close button and progress
                topBar
                    .padding(.top, 8)

                // Prayer Content
                if let prayer = currentPrayer {
                    prayerContent(prayer)
                        .opacity(opacity)
                }

                Spacer(minLength: 0)

                // Bottom Controls
                bottomControls
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            currentIndex = 0
            opacity = 1.0
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            // Close Button
            Button {
                path.removeLast()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.cream.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
            }

            Spacer()

            // Progress Indicator
            progressIndicator

            Spacer()

            // Spacer for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 6) {
            // Day indicator
            Text("DAY \(dayNumber)")
                .font(AppFonts.bodyFont(10))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<prayers.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentIndex ? AppColors.gold : AppColors.cardBackground)
                        .frame(width: index == currentIndex ? 20 : 8, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentIndex)
                }
            }
        }
    }

    // MARK: - Prayer Content

    private func prayerContent(_ prayer: ConsecrationPrayer) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)
                        .id("top")

                    // Prayer Title Section
                    VStack(spacing: 12) {
                        // Latin title (if available)
                        if let latinTitle = prayer.latinTitle {
                            Text(latinTitle.uppercased())
                                .font(AppFonts.bodyFont(11))
                                .tracking(3)
                                .foregroundColor(AppColors.gold)
                        }

                        // Main title
                        Text(prayer.title)
                            .font(AppFonts.headlineFont(26))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Decorative divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, AppColors.gold.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)

                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.gold.opacity(0.6))

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.gold.opacity(0.5), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 24)

                    // Prayer Text
                    formattedPrayerText(prayer.content)
                        .padding(.horizontal, 28)

                    // Bottom padding for scroll
                    Spacer()
                        .frame(height: 120)
                }
            }
            .onChange(of: currentIndex) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
        .mask(
            VStack(spacing: 0) {
                // Top fade
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Rectangle()
                    .fill(Color.black)

                // Bottom fade
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
        )
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Prayer counter
            Text("\(currentIndex + 1) of \(prayers.count)")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(AppColors.textSecondary)

            // Continue Button
            Button {
                if isLastPrayer {
                    // Navigate to meditation
                    path.append(ConsecrationRoute.meditation(dayNumber: dayNumber))
                } else {
                    // Animate transition to next prayer
                    withAnimation(.easeOut(duration: 0.15)) {
                        opacity = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        currentIndex += 1
                        withAnimation(.easeIn(duration: 0.2)) {
                            opacity = 1
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(isLastPrayer ? "Continue to Meditation" : "Continue")
                        .font(AppFonts.headlineFont(16))

                    Image(systemName: isLastPrayer ? "book.fill" : "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationPrayerFlowView(path: .constant(NavigationPath()), dayNumber: 1)
            .environment(ConsecrationViewModel())
    }
}
