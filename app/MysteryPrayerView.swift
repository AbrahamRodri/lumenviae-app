//
//  MysteryPrayerView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/11/26.
//
//  This view displays a single mystery during the prayer flow.
//  Users progress through 5 mysteries, each with meditation content,
//  scripture, and optional audio.

import SwiftUI

struct MysteryPrayerView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: PrayerSessionViewModel

    let meditationSet: MeditationSet

    init(meditationSet: MeditationSet) {
        self.meditationSet = meditationSet
        self._viewModel = State(initialValue: PrayerSessionViewModel(meditationSet: meditationSet))
    }

    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                MysteryProgressHeader(
                    current: viewModel.currentMysteryIndex + 1,
                    total: viewModel.totalMysteries,
                    onClose: { router.popToRoot() }
                )

                // Current meditation content
                if let meditation = viewModel.currentMeditation {
                    // Mystery Image (fixed height, not in scroll)
                    MysteryImageView(imageURL: nil) // TODO: Add image URL to API
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Mystery Info
                    MysteryInfoSection(
                        mysteryType: meditationSet.mysteryCategory?.displayName ?? "",
                        mysteryNumber: viewModel.currentMysteryIndex + 1,
                        mysteryTitle: meditation.displayTitle
                    )
                    .padding(.top, 20)

                    // Scripture / Meditation content - scrollable
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Meditation content
                            Text(meditation.content)
                                .font(AppFonts.bodyFont(17))
                                .foregroundColor(AppColors.cream.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)

                            // Scripture reference if available
                            if let reference = meditation.mystery?.scriptureReference {
                                Text(reference)
                                    .font(AppFonts.italicFont(14))
                                    .foregroundColor(AppColors.gold.opacity(0.8))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                    Spacer()
                }

                // Fixed bottom section - always visible
                VStack(spacing: 12) {
                    // Audio Controls (if audio available)
                    if viewModel.currentMeditation?.hasAudio == true {
                        AudioControlsView(
                            isPlaying: $viewModel.isPlaying,
                            currentTime: $viewModel.currentTime,
                            totalTime: viewModel.totalDuration
                        )
                        .padding(.horizontal, 20)
                    }

                    // Next Mystery Button
                    NextMysteryButton(
                        isLastMystery: viewModel.isLastMystery,
                        action: handleNextMystery
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .background(AppColors.background)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadCurrentAudio()
        }
        .onChange(of: viewModel.currentMysteryIndex) { _, _ in
            Task {
                await viewModel.loadCurrentAudio()
            }
        }
    }

    private func handleNextMystery() {
        if viewModel.nextMystery() {
            // Moved to next mystery
        } else {
            // Completed all mysteries - navigate to completion
            Task {
                try? await viewModel.recordCompletion()
            }
            router.navigateToCompletion()
        }
    }
}

// MARK: - Progress Header

struct MysteryProgressHeader: View {
    let current: Int
    let total: Int
    var onClose: () -> Void = {}

    private var progress: CGFloat {
        CGFloat(current) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("MYSTERY \(current) OF \(total)")
                    .font(AppFonts.bodyFont(14))
                    .tracking(3)
                    .foregroundColor(AppColors.gold)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.gold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.2))
                        .frame(height: 3)

                    // Progress fill
                    Rectangle()
                        .fill(AppColors.gold)
                        .frame(width: geometry.size.width * progress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Mystery Image

struct MysteryImageView: View {
    let imageURL: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)

            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(AppColors.gold)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textSecondary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Placeholder
                Image(systemName: "hands.and.sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Mystery Info Section

struct MysteryInfoSection: View {
    let mysteryType: String
    let mysteryNumber: Int
    let mysteryTitle: String

    private var ordinalNumber: String {
        let ordinals = ["First", "Second", "Third", "Fourth", "Fifth"]
        guard mysteryNumber >= 1 && mysteryNumber <= 5 else { return "" }
        return ordinals[mysteryNumber - 1]
    }

    var body: some View {
        VStack(spacing: 8) {
            // Category label
            Text("THE \(ordinalNumber.uppercased()) \(mysteryType.uppercased()) MYSTERY")
                .font(AppFonts.bodyFont(12))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            // Mystery title
            Text(mysteryTitle)
                .font(AppFonts.italicFont(32))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Gold divider
            Rectangle()
                .fill(AppColors.gold)
                .frame(width: 50, height: 2)
                .padding(.top, 8)
        }
    }
}

// MARK: - Audio Controls

struct AudioControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    let totalTime: Double

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Progress slider
            VStack(spacing: 4) {
                Slider(value: $currentTime, in: 0...max(totalTime, 1))
                    .tint(AppColors.gold)

                HStack {
                    Text(formatTime(currentTime))
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Text(formatTime(totalTime))
                        .font(AppFonts.bodyFont(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Playback controls
            HStack(spacing: 40) {
                // Rewind 10s
                Button(action: {
                    currentTime = max(0, currentTime - 10)
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Play/Pause
                Button(action: {
                    isPlaying.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.goldLight)
                            .frame(width: 64, height: 64)

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.background)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }

                // Forward 30s
                Button(action: {
                    currentTime = min(totalTime, currentTime + 30)
                }) {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Next Mystery Button

struct NextMysteryButton: View {
    let isLastMystery: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(isLastMystery ? "Complete" : "Next Mystery")
                    .font(AppFonts.bodyFont(16))
                    .tracking(1)

                Image(systemName: isLastMystery ? "checkmark" : "arrow.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(AppColors.goldLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    MysteryPrayerView(meditationSet: MockDataService.meditationSet(for: .sorrowful))
        .environment(AppRouter())
}
