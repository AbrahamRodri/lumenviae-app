//
//  PrayerAudioControls.swift
//  Lumen Viae
//
//  The narration transport for the prayer flow: the controls under the
//  title, and the playback settings tray reached from the bottom bar.
//
//  These live apart from MysteryPrayerView because the reader shows the
//  same narration in a condensed form, and both surfaces should agree
//  about what a play button looks like.
//

import SwiftUI

// MARK: - Time Formatting

/// How the narration's position is spoken. There is no position bar on
/// screen, so this exists for VoiceOver — and for the day one returns.
enum NarrationClock {

    /// "3 minutes 20 seconds", not "3:20".
    static func spoken(_ seconds: Double) -> String {
        // Int(Double.nan) traps, and a not-yet-loaded track reports nan
        // for its duration before the asset resolves.
        guard seconds.isFinite, seconds > 0 else { return "0 seconds" }
        let whole = Int(seconds)
        let mins = whole / 60
        let secs = whole % 60
        let minutes = "\(mins) minute\(mins == 1 ? "" : "s")"
        let sec = "\(secs) second\(secs == 1 ? "" : "s")"
        if mins == 0 { return sec }
        if secs == 0 { return minutes }
        return "\(minutes) \(sec)"
    }
}

// MARK: - Transport Button

/// One control in the transport row. Everything but the play button is
/// a quiet glyph — gold is spent on the act, not on the skips.
struct TransportButton: View {

    let icon: TransportGlyph
    var size: CGFloat = 22
    var label: String
    var action: () -> Void

    enum TransportGlyph {
        /// A vendored Phosphor/Christicons asset
        case asset(String)
        /// An SF Symbol, for glyphs that encode a number (the ±10s skips)
        case symbol(String)
    }

    var body: some View {
        Button(action: action) {
            Group {
                switch icon {
                case .asset(let name):
                    AppIcon(name, size: size)
                case .symbol(let name):
                    Image(systemName: name)
                        .font(.system(size: size, weight: .light))
                }
            }
            .foregroundColor(AppColors.gold)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Play Button

/// The one gold act on the player: a filled disc that starts and stops
/// the narration.
struct NarrationPlayButton: View {

    let isPlaying: Bool
    var isLoading: Bool = false
    var diameter: CGFloat = 64
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.goldGradient)
                    .frame(width: diameter, height: diameter)
                    .haloGlow(AppColors.gold, radius: diameter * 0.16, intensity: 0.38)

                if isLoading {
                    ProgressView()
                        .tint(AppColors.background)
                } else {
                    // The vendored glyphs the app's other two players
                    // use. Their play triangle is drawn centered, so it
                    // needs no nudge of its own either.
                    AppIcon(isPlaying ? "ph-pause-fill" : "ph-play-fill", size: diameter * 0.36)
                        .foregroundColor(AppColors.background)
                }
            }
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(isLoading ? "Loading audio" : (isPlaying ? "Pause" : "Play"))
    }
}

/// The play button together with the position VoiceOver reads from it.
///
/// It exists only to keep the read of `currentTime` in a leaf. The
/// narration clock ticks twice a second, and `@Observable` makes whoever
/// reads it re-render — so building this string in the prayer screen's
/// body rebuilt the whole screen, blurred artwork and all, at 2 Hz for
/// the length of every meditation.
struct NarrationPlayControl: View {

    let viewModel: PrayerSessionViewModel
    var diameter: CGFloat = 64

    var body: some View {
        let ready = !viewModel.isLoadingAudio && viewModel.totalDuration > 0

        NarrationPlayButton(
            isPlaying: viewModel.isPlaying,
            isLoading: viewModel.isLoadingAudio,
            diameter: diameter
        ) {
            viewModel.isPlaying.toggle()
        }
        .disabled(!ready)
        // With no scrubber on screen there is nothing else for VoiceOver
        // to read position from, or to seek with
        .accessibilityValue(
            ready
                ? "\(NarrationClock.spoken(viewModel.currentTime)) of \(NarrationClock.spoken(viewModel.totalDuration))"
                : "Not ready"
        )
        .accessibilityHint(ready ? "Swipe up or down to move through the narration" : "")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: viewModel.skipForward(15)
            case .decrement: viewModel.skipBackward(15)
            @unknown default: break
            }
        }
    }
}

// MARK: - Playback Settings

/// The tray beside the reader button: how fast the voice reads, and the
/// background music that isn't built yet.
///
/// The music row ships disabled rather than hidden on purpose — it is
/// the honest shape of the tray, and hiding it would mean redrawing the
/// tray the day it lands.
struct PlaybackSettingsSheet: View {

    @Environment(\.dismiss) private var dismiss

    /// Read straight from the service so the tray agrees with whatever
    /// the Lock Screen or CarPlay last set.
    private var audio: AudioService { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Playback")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
                Spacer()
                ReaderChromeButton(
                    icon: "ph-x",
                    size: 15,
                    tint: AppColors.textSecondary,
                    label: "Close",
                    action: dismiss.callAsFunction
                )
            }
            .padding(.leading, 24)
            .padding(.trailing, 10)
            .padding(.top, 14)

            speedSection
                .padding(.horizontal, 24)
                .padding(.top, 18)

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var speedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPEED")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            HStack(spacing: 8) {
                ForEach(AudioService.supportedRates, id: \.self) { rate in
                    let selected = audio.playbackRate == rate
                    Button {
                        audio.setPlaybackRate(rate)
                    } label: {
                        Text(Self.rateLabel(rate))
                            .font(AppFonts.bodyFont(14))
                            .foregroundColor(selected ? AppColors.background : AppColors.cream.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                Capsule()
                                    .fill(selected ? AppColors.goldLight : AppColors.cardElevated)
                            )
                    }
                    .accessibilityLabel("\(Self.rateLabel(rate)) speed")
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
        }
    }

    // A "BACKGROUND MUSIC" section stood here holding one dimmed,
    // untappable row that said "Coming soon" — the whole section was a
    // promise rather than a control. A sheet the user opened mid-Rosary
    // is the wrong place to advertise unbuilt work; bring the section
    // back with the feature, not before it.

    /// "1×" rather than "1.0×", but "1.25×" in full — %g drops trailing
    /// zeros without rounding away a significant digit.
    private static func rateLabel(_ rate: Double) -> String {
        "\(String(format: "%g", rate))×"
    }
}

// MARK: - Preview

#Preview("Transport") {
    HStack(spacing: 18) {
        TransportButton(icon: .asset("ph-arrow-left"), size: 18, label: "Previous") {}
        TransportButton(icon: .symbol("gobackward.10"), label: "Back 10") {}
        NarrationPlayButton(isPlaying: false, diameter: 56) {}
        TransportButton(icon: .symbol("goforward.10"), label: "Forward 10") {}
        TransportButton(icon: .asset("ph-arrow-right"), size: 18, label: "Next") {}
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}

#Preview("Settings") {
    Color.black.sheet(isPresented: .constant(true)) {
        PlaybackSettingsSheet()
            .presentationDetents([.height(330)])
    }
}
