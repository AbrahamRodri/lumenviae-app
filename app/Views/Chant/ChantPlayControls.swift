//
//  ChantPlayControls.swift
//  Lumen Viae
//
//  The controls a chant is played by: the dark play disc, the gold play
//  button of a chant's page, the scrubber, and a set's Play all.
//

import SwiftUI

// MARK: - ChantPlayDisc

/// The round play control: a dark disc lit through a gold rim, the one
/// shape the app gives to a play control that is not a page's act.
struct ChantPlayDisc: View {
    let isPlaying: Bool
    let isLoading: Bool
    var size: CGFloat = 46
    var label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)

                // Play, pause and the spinner crossfade over one another
                // rather than swapping under the thumb: three branches
                // sharing one slot, as the tile's own disc drew them
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.goldLight)
                            .scaleEffect(0.8)
                            .transition(.opacity)
                    } else if isPlaying {
                        AppIcon("ph-pause-fill", size: size * 0.32)
                            .foregroundColor(AppColors.goldLight)
                            .transition(.opacity)
                    } else {
                        AppIcon("ph-play-fill", size: size * 0.32)
                            .foregroundColor(AppColors.goldLight)
                            .transition(.opacity)
                    }
                }
                .animation(Motion.crossfade, value: isLoading)
                .animation(Motion.crossfade, value: isPlaying)
            }
            .frame(width: size, height: size)
            .shadow(color: AppColors.gold.opacity(0.3), radius: size * 0.2)
            // Drawn at its size, answering to 44 whatever that is
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(
            isLoading ? "Loading \(label)"
                : isPlaying ? "Pause \(label)" : "Play \(label)"
        )
    }
}

// MARK: - ChantScrubber

/// A gold hairline the finger can drag along — the consecration
/// transport's scrubber, at the weight of a rule. VoiceOver hears where it
/// stands as time, "1 minute 5 seconds of 3 minutes 20 seconds", and
/// moves it ten seconds at a swipe.
struct ChantScrubber: View {
    let progress: Double
    /// The recording's length, in seconds
    let duration: Double
    let isEnabled: Bool
    let onSeek: (Double) -> Void

    /// How far a swipe up or down moves the chant
    private static let step: Double = 10

    @State private var dragging: Double?

    private var shown: Double { dragging ?? progress }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.cream.opacity(0.14))
                    .frame(height: 3)
                Capsule()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: max(width * shown, 3), height: 3)
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: 11, height: 11)
                    .offset(x: (width - 11) * shown)
                    .opacity(isEnabled ? 1 : 0.4)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }
                        dragging = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { _ in
                        if let dragging { onSeek(dragging) }
                        dragging = nil
                    }
            )
        }
        .frame(height: 24)
        .accessibilityElement()
        .accessibilityLabel("Position in the chant")
        .accessibilityValue("\(ChantPlayer.spoken(shown * duration)) of \(ChantPlayer.spoken(duration))")
        .accessibilityAdjustableAction { direction in
            guard isEnabled, duration > 0 else { return }
            let step = Self.step / duration
            switch direction {
            case .increment: onSeek(min(1, progress + step))
            case .decrement: onSeek(max(0, progress - step))
            @unknown default: break
            }
        }
    }
}

// MARK: - ChantGoldPlayButton

/// The board's one gold act when it is a chant to sing: a gold disc with
/// the play or pause glyph dark upon it, haloed. Tonight's antiphon, the
/// chant's own page.
struct ChantGoldPlayButton: View {
    let isPlaying: Bool
    let isLoading: Bool
    var size: CGFloat = 56
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.goldGradient)
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.background)
                            .transition(.opacity)
                    } else if isPlaying {
                        AppIcon("ph-pause-fill", size: size * 0.34)
                            .transition(.opacity)
                    } else {
                        AppIcon("ph-play-fill", size: size * 0.34)
                            .offset(x: size * 0.03)
                            .transition(.opacity)
                    }
                }
                .foregroundColor(AppColors.background)
                .animation(Motion.crossfade, value: isLoading)
                .animation(Motion.crossfade, value: isPlaying)
            }
            .frame(width: size, height: size)
            .shadow(color: AppColors.gold.opacity(0.28), radius: 10)
            .shadow(color: AppColors.gold.opacity(0.14), radius: 22)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(isLoading ? "Loading \(label)" : isPlaying ? "Pause \(label)" : "Play \(label)")
    }
}

// MARK: - ChantSetPlayButton

/// A set's one gold act: Play all until the set is under way, then the
/// set's own pause and resume. It once began the set again from its
/// first chant at every tap.
struct ChantSetPlayButton: View {
    let queue: ChantQueue
    let title: String

    private var player = ChantPlayer.shared

    init(queue: ChantQueue, title: String) {
        self.queue = queue
        self.title = title
    }

    var body: some View {
        let singing = player.isSinging(queue)
        // A chant on its way counts as going on, unless a pause was asked
        // for while it arrived
        let going = singing && player.isGoingOn
        let word = !singing ? title
            : player.waitingForNext ? "Play next"
            : going ? "Pause" : "Resume"
        GoldCTAButton(title: word, glyph: going ? .none : .play) {
            if singing {
                player.pauseOrResume()
            } else {
                player.play(queue)
            }
        }
    }
}
