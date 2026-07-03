//
//  MysteryPrayerView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/11/26.
//
//  This view displays a single mystery during the prayer flow.
//  Users progress through 5 mysteries, each with meditation content,
//  scripture, and optional audio.
//
//  Two view modes:
//  - Image View: Full-screen artwork with mystery info overlay (default)
//  - Text View: Meditation text takes precedence, no image

import SwiftUI

struct MysteryPrayerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var userSettings
    @State private var viewModel: PrayerSessionViewModel
    @State private var showingJournalEditor = false
    @State private var isImageMode = true // Toggle between image and text views

    let meditationSet: MeditationSet

    init(meditationSet: MeditationSet) {
        self.meditationSet = meditationSet
        self._viewModel = State(initialValue: PrayerSessionViewModel(meditationSet: meditationSet))
    }

    var body: some View {
        ZStack {
            if isImageMode {
                // MARK: - Image Mode (Full-screen artwork)
                imageViewMode
            } else {
                // MARK: - Text Mode (Meditation content focus)
                textViewMode
            }
        }
        .navigationBarHidden(true)
        .task(id: viewModel.currentMysteryIndex) {
            await viewModel.loadCurrentAudio()
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

    // MARK: - Image View Mode
    private var imageViewMode: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                AppColors.background
                    .ignoresSafeArea()

                // Image fills top 80% of screen with gradient fade
                VStack(spacing: 0) {
                    if let assetName = Constants.mysteryImageURL(
                        category: meditationSet.category,
                        index: viewModel.currentMysteryIndex
                    ) {
                        Image(assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.80)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(AppColors.cardBackground)
                            .frame(height: geometry.size.height * 0.70)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .id(viewModel.currentMysteryIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentMysteryIndex)

                // Gradient overlay
                VStack {
                    Spacer()
                        .frame(height: geometry.size.height * 0.60)

                    LinearGradient(
                        colors: [
                            .clear,
                            AppColors.background.opacity(0.9),
                            AppColors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .drawingGroup()
                .ignoresSafeArea()

                // Content overlay
                VStack(spacing: 0) {
                    // Top header bar
                    imageViewHeader
                        .padding(.top, 8)

                    Spacer()

                    // Bottom content card
                    if let meditation = viewModel.currentMeditation {
                        imageViewBottomCard(meditation: meditation)
                    }
                }
            }
        }
    }

    private var imageViewHeader: some View {
        HStack {
            // Close button
            PrayerHeaderButton(icon: "ph-x", size: 18, label: "End prayer") {
                router.popToRoot()
            }

            Spacer()

            // Toggle to reading/text mode button
            PrayerHeaderButton(icon: "ph-text-align-left", label: "Reading mode") {
                withAnimation(.easeInOut(duration: 0.3)) { isImageMode.toggle() }
            }

            // Journal button
            PrayerHeaderButton(icon: "ph-note-pencil", label: "Add journal note") {
                showingJournalEditor = true
            }
        }
        .padding(.horizontal, 16)
    }

    private func imageViewBottomCard(meditation: Meditation) -> some View {
        VStack(spacing: 16) {
            // Decade progress as a strand of rosary beads
            RosaryBeadProgress(
                total: viewModel.totalMysteries,
                completed: viewModel.currentMysteryIndex,
                activeIndex: viewModel.currentMysteryIndex,
                beadSize: 8
            )
            .frame(width: 150)

            // Mystery info - no card, just text
            VStack(spacing: 12) {
                // Mystery label
                Text("THE \(ordinalNumber(viewModel.currentMysteryIndex + 1).uppercased()) \(meditationSet.mysteryCategory?.displayName.uppercased() ?? "") MYSTERY")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                // Mystery title
                Text(meditation.displayTitle)
                    .font(AppFonts.headlineFont(25))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                // Scripture reference only (no quote text)
                if let reference = meditation.mystery?.scriptureReference {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.5))
                            .frame(width: 20, height: 1)
                        Text(reference)
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.accentSoft)
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.5))
                            .frame(width: 20, height: 1)
                    }
                }
            }
            .padding(.horizontal, 24)
            .id(viewModel.currentMysteryIndex)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.4), value: viewModel.currentMysteryIndex)

            // Audio controls
            if viewModel.currentMeditation?.hasAudio == true {
                AudioControlsView(
                    isPlaying: $viewModel.isPlaying,
                    currentTime: $viewModel.currentTime,
                    totalTime: viewModel.totalDuration
                )
                .padding(.horizontal, 20)
            }

            // Navigation buttons
            navigationButtons
                .padding(.bottom, 16)
        }
    }

    // MARK: - Text View Mode
    private var textViewMode: some View {
        ZStack {
            // Background gradient
            AppColors.appGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                textViewHeader

                // Current meditation content
                if let meditation = viewModel.currentMeditation {
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
                            // Scripture reference
                            if let reference = meditation.mystery?.scriptureReference {
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(AppColors.gold.opacity(0.5))
                                        .frame(width: 20, height: 1)
                                    Text(reference)
                                        .font(AppFonts.italicFont(14))
                                        .foregroundColor(AppColors.accentSoft)
                                    Rectangle()
                                        .fill(AppColors.gold.opacity(0.5))
                                        .frame(width: 20, height: 1)
                                }
                                .padding(.top, 8)
                            }

                            // Meditation content, opened by an illuminated initial
                            DropCapText(
                                text: meditation.content,
                                bodySize: userSettings.meditationFontSize,
                                capSize: userSettings.meditationFontSize * 2.4,
                                textColor: AppColors.cream.opacity(0.92)
                            )
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 16)
                        }
                        // Extra padding so content can scroll behind controls
                        .padding(.top, 12)
                        .padding(.bottom, 200)
                        .id(viewModel.currentMysteryIndex)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.currentMysteryIndex)
                    }
                    .frame(maxHeight: .infinity)
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
                    colors: [.clear, AppColors.background],
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

                    // Navigation buttons
                    navigationButtons
                        .padding(.bottom, 8)
                }
                .background(AppColors.background)
            }
        }
    }

    private var textViewHeader: some View {
        VStack(spacing: 14) {
            HStack {
                // Close button (left side, matching image view)
                PrayerHeaderButton(icon: "ph-x", size: 18, label: "End prayer") {
                    router.popToRoot()
                }

                Spacer()

                // Toggle view mode
                PrayerHeaderButton(icon: "ph-image", label: "Image mode") {
                    withAnimation(.easeInOut(duration: 0.3)) { isImageMode.toggle() }
                }

                // Journal note shortcut
                PrayerHeaderButton(icon: "ph-note-pencil", label: "Add journal note") {
                    showingJournalEditor = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Decade progress as a strand of rosary beads
            RosaryBeadProgress(
                total: viewModel.totalMysteries,
                completed: viewModel.currentMysteryIndex,
                activeIndex: viewModel.currentMysteryIndex,
                beadSize: 8
            )
            .frame(width: 170)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Shared Components

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Previous Mystery Button — quiet outline, secondary
            Button(action: {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.previousMystery()
                }
            }) {
                HStack(spacing: 6) {
                    AppIcon("ph-arrow-left", size: 12)
                    Text("PREV")
                        .font(AppFonts.labelFont(11))
                        .tracking(1.5)
                }
                .foregroundColor(AppColors.gold)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    Capsule().fill(AppColors.background.opacity(0.6))
                )
                .overlay(
                    Capsule().strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(GoldCTAButtonStyle())
            .disabled(viewModel.currentMysteryIndex == 0)
            .opacity(viewModel.currentMysteryIndex == 0 ? 0.4 : 1.0)

            Spacer()

            // Next Mystery Button — gold, primary
            Button(action: handleNextMystery) {
                HStack(spacing: 6) {
                    Text(viewModel.isLastMystery ? "AMEN" : "NEXT")
                        .font(AppFonts.labelFont(11))
                        .tracking(1.5)
                    AppIcon(viewModel.isLastMystery ? "ph-check" : "ph-arrow-right", size: 12)
                }
                .foregroundColor(AppColors.background)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(
                    Capsule().fill(AppColors.goldGradient)
                )
                .overlay(
                    Capsule().strokeBorder(AppColors.goldLight.opacity(0.6), lineWidth: 0.5)
                )
                .haloGlow(AppColors.gold, radius: 8, intensity: 0.3)
            }
            .buttonStyle(GoldCTAButtonStyle())
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.currentMysteryIndex)
    }

    // MARK: - Helper Functions

    private func ordinalNumber(_ number: Int) -> String {
        let ordinals = ["First", "Second", "Third", "Fourth", "Fifth"]
        guard number >= 1 && number <= 5 else { return "" }
        return ordinals[number - 1]
    }

    private func handleNextMystery() {
        let finished = withAnimation(.easeInOut(duration: 0.4)) {
            viewModel.nextMystery()
        }
        guard finished else { return }

        // Completed all mysteries - navigate to completion
        Task {
            try? await viewModel.recordCompletion()
        }
        router.navigateToCompletion()
    }
}

// MARK: - PrayerHeaderButton

/// A circular scrim button used in the prayer flow header.
struct PrayerHeaderButton: View {
    let icon: String
    var size: CGFloat = 16
    var label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(icon, size: size)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(label)
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
        VStack(spacing: 10) {
            // Category label
            Text("THE \(ordinalNumber.uppercased()) \(mysteryType.uppercased()) MYSTERY")
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(AppColors.gold)

            // Mystery title
            Text(mysteryTitle)
                .font(AppFonts.headlineFont(27))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 20)

            // Ornamental divider
            OrnamentDivider(showsCross: false)
                .frame(width: 150)
                .padding(.top, 6)
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
                // Rewind 10s (SF symbol — it encodes the "10" glyph)
                Button(action: {
                    currentTime = max(0, currentTime - 10)
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(AppColors.gold)
                }

                // Play/Pause
                Button(action: {
                    isPlaying.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.goldGradient)
                            .frame(width: 64, height: 64)
                            .haloGlow(AppColors.gold, radius: 10, intensity: 0.4)

                        AppIcon(isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 24)
                            .foregroundColor(AppColors.background)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }
                .buttonStyle(GoldCTAButtonStyle())

                // Forward 10s (SF symbol — it encodes the "10" glyph)
                Button(action: {
                    currentTime = min(totalTime, currentTime + 10)
                }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24, weight: .light))
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
