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
    @State private var showingJournalEditor = false

    let meditationSet: MeditationSet

    init(meditationSet: MeditationSet) {
        self.meditationSet = meditationSet
        self._viewModel = State(initialValue: PrayerSessionViewModel(meditationSet: meditationSet))
    }

    var body: some View {
        ZStack {
            // Background gradient
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                MysteryProgressHeader(
                    current: viewModel.currentMysteryIndex + 1,
                    total: viewModel.totalMysteries,
                    onClose: { router.popToRoot() },
                    onJournal: { showingJournalEditor = true }
                )

                // Current meditation content
                if let meditation = viewModel.currentMeditation {
                    // Mystery Image (fixed height, not in scroll)
                    MysteryImageView(
                        imageURL: Constants.mysteryImageURL(
                            category: meditationSet.category,
                            index: viewModel.currentMysteryIndex
                        )
                    )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Mystery Info
                    MysteryInfoSection(
                        mysteryType: meditationSet.mysteryCategory?.displayName ?? "",
                        mysteryNumber: viewModel.currentMysteryIndex + 1,
                        mysteryTitle: meditation.displayTitle
                    )
                    .padding(.top, 20)

                    // Scripture / Meditation content - scrollable with padding for controls
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
                        // Extra padding so content can scroll behind controls
                        .padding(.top, 20)
                        .padding(.bottom, 180)
                    }
                    .frame(maxHeight: .infinity)
                    .overlay(alignment: .top) {
                        // Top gradient fade for scroll content
                        LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "1a1a2e").opacity(0.85), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        .allowsHitTesting(false)
                    }
                } else {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                    Spacer()
                }
            }

            // Fixed bottom section - floating over content with gradient fade
            VStack(spacing: 0) {
                Spacer()

                // Gradient fade zone above controls
                LinearGradient(
                    colors: [.clear, Color(hex: "1a1a2e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .allowsHitTesting(false)

                // Controls with solid background
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

                    // Previous and Next buttons row
                    HStack(spacing: 12) {
                        // Previous Mystery Button
                        Button(action: {
                            viewModel.previousMystery()
                            Task {
                                await viewModel.loadCurrentAudio()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Prev")
                                    .font(AppFonts.bodyFont(13))
                                    .tracking(0.5)
                            }
                            .foregroundColor(AppColors.background)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppColors.goldLight)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.currentMysteryIndex == 0)
                        .opacity(viewModel.currentMysteryIndex == 0 ? 0.5 : 1.0)

                        Spacer()

                        // Next Mystery Button
                        Button(action: handleNextMystery) {
                            HStack(spacing: 4) {
                                Text("Next")
                                    .font(AppFonts.bodyFont(13))
                                    .tracking(0.5)
                                Image(systemName: viewModel.isLastMystery ? "checkmark" : "arrow.right")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppColors.background)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppColors.goldLight)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .background(Color(hex: "1a1a2e"))
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
        .sheet(isPresented: $showingJournalEditor) {
            JournalEntryEditorView(
                category: meditationSet.mysteryCategory,
                mysteryTitle: viewModel.currentMeditation?.displayTitle,
                mysteryIndex: viewModel.currentMysteryIndex,
                isMidPrayer: true
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
    var onJournal: () -> Void = {}

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

                // Journal note shortcut
                Button(action: onJournal) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.gold.opacity(0.8))
                }
                .padding(.trailing, 12)

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

            if let assetName = imageURL {
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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
            // Playback controls
            HStack(spacing: 40) {
                // Rewind 10s
                Button(action: {
                    currentTime = max(0, currentTime - 10)
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.gold)
                }

                // Play/Pause
                Button(action: {
                    isPlaying.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.gold)
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
                        .foregroundColor(AppColors.gold)
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    MysteryPrayerView(meditationSet: MockDataService.meditationSet(for: .sorrowful, includeAudio: true))
        .environment(AppRouter())
}
