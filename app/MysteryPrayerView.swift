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
    // MARK: - Properties
    let currentMystery: Int  // 1-5
    let totalMysteries: Int  // Usually 5
    let mysteryType: String  // e.g., "SORROWFUL"
    let mysteryTitle: String
    let scriptureText: String
    let scriptureReference: String
    let imageURL: String?

    // Audio state (UI only for now)
    @State private var isPlaying = false
    @State private var currentTime: Double = 45  // seconds
    @State private var totalTime: Double = 180   // 3 minutes

    // Dismiss action
    var onClose: () -> Void = {}
    var onNextMystery: () -> Void = {}

    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                MysteryProgressHeader(
                    current: currentMystery,
                    total: totalMysteries,
                    onClose: onClose
                )

                // Mystery Image (fixed height, not in scroll)
                MysteryImageView(imageURL: imageURL)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // Mystery Info
                MysteryInfoSection(
                    mysteryType: mysteryType,
                    mysteryNumber: currentMystery,
                    mysteryTitle: mysteryTitle
                )
                .padding(.top, 20)

                // Scripture - scrollable area with more room
                // Future: This will auto-scroll with audio, fading in/out
                ScrollView(showsIndicators: false) {
                    ScriptureSection(
                        text: scriptureText,
                        reference: scriptureReference
                    )
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: .infinity)

                // Fixed bottom section - always visible
                VStack(spacing: 12) {
                    // Audio Controls
                    AudioControlsView(
                        isPlaying: $isPlaying,
                        currentTime: $currentTime,
                        totalTime: totalTime
                    )
                    .padding(.horizontal, 20)

                    // Next Mystery Button
                    NextMysteryButton(
                        isLastMystery: currentMystery == totalMysteries,
                        action: onNextMystery
                    )
                    .padding(.horizontal, 20)
                }
                .background(AppColors.background)
            }
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
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(height: 280)
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

// MARK: - Scripture Section
/// Displays the scripture passage and reference.
///
/// ## Future Enhancement: Auto-Scrolling Text
/// When audio is playing, the text will:
/// - Auto-scroll from bottom to top synced with audio
/// - Fade in at the bottom edge
/// - Fade out at the top edge
/// - Current line/phrase highlighted
/// This creates a teleprompter-like reading experience.
struct ScriptureSection: View {
    let text: String
    let reference: String

    var body: some View {
        VStack(spacing: 16) {
            // Scripture text
            Text("\"\(text)\"")
                .font(AppFonts.bodyFont(17))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Reference
            Text(reference)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.gold.opacity(0.8))
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
                Slider(value: $currentTime, in: 0...totalTime)
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
                            .offset(x: isPlaying ? 0 : 2)  // Optical centering for play icon
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
    MysteryPrayerView(
        currentMystery: 1,
        totalMysteries: 5,
        mysteryType: "Sorrowful",
        mysteryTitle: "The Agony in the Garden",
        scriptureText: "Then Jesus came with them to a place called Gethsemane, and he said to his disciples, 'Sit here while I go over there and pray.' He took along Peter and the two sons of Zebedee, and began to feel sorrow and distress.",
        scriptureReference: "Matthew 26:36-37",
        imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/68/Christ_in_Gethsemane.jpg"
    )
}
