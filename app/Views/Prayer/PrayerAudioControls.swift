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
        // After the last Amen said aloud there is nothing left to play;
        // the button stands aside, and AMEN is what glows
        let ready = !viewModel.isLoadingAudio && viewModel.totalDuration > 0
            && !viewModel.isSpokenFinished

        NarrationPlayButton(
            isPlaying: viewModel.isPlaying,
            isLoading: viewModel.isLoadingAudio,
            diameter: diameter
        ) {
            viewModel.isPlaying.toggle()
        }
        .disabled(!ready)
        .opacity(viewModel.isSpokenFinished ? 0.35 : 1)
        .animation(Motion.crossfade, value: viewModel.isSpokenFinished)
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

/// The tray beside the reader button: which voice reads, how fast it
/// reads, whether the whole Rosary is said aloud, and whether the player
/// is prayed on the beads.
///
/// The voice and the beads toggle live here as well as in Settings
/// because this is the one settings surface the player has: someone
/// who finds the strand, or the narrator, is not for them mid-Rosary
/// should not have to leave the Rosary to say so, and someone who
/// changed it should be able to find it again from the same place.
struct PlaybackSettingsSheet: View {

    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss

    /// The sheet's height, for its detent: the header, the voices and
    /// the speeds under their labels, and the rows for the bead counter
    /// and for praying aloud, whose lines can run to three
    static let height: CGFloat = 530

    /// The detents the player gives it: its own height, or at the
    /// accessibility text sizes the whole glass, where the rows once
    /// stood crushed into 530 points, one switch's name over another's
    static func detents(for size: DynamicTypeSize) -> Set<PresentationDetent> {
        size.isAccessibilitySize ? [.large] : [.height(height)]
    }

    var body: some View {
        @Bindable var settings = userSettings

        // Scrolls only when the words outgrow the sheet
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Playback") {
                    SheetHeaderAction(title: "Done") { dismiss() }
                }

                SheetSectionLabel("Voice")

                NarrationVoiceChoice()
                    .padding(.horizontal, SheetMetrics.gutter)

                SheetSectionLabel("Speed")

                PlaybackSpeedChoice()
                    .padding(.horizontal, SheetMetrics.gutter)

                // The same section, in the same order, as the set's page
                // (`RosarySetupSheet`): Pray aloud once stood here under
                // "The beads", after the counter, and the two sheets that
                // hold the same two switches described them differently
                SheetSectionLabel("The prayers")

                // The whole row answers, as it does in Settings
                SheetToggleRow(
                    title: UserSettings.prayAloudTitle,
                    detail: UserSettings.prayAloudDetail(isOn: settings.prayAloud, onBeads: settings.prayOnBeads),
                    icon: "ph-hands-praying",
                    isOn: $settings.prayAloud,
                    showsDivider: true
                )

                SheetToggleRow(
                    title: UserSettings.beadCounterTitle,
                    detail: UserSettings.beadCounterDetail(isOn: settings.prayOnBeads),
                    icon: "ch-rosary",
                    isOn: $settings.prayOnBeads,
                    showsDivider: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .sheetGround()
    }

    // A "BACKGROUND MUSIC" section stood here holding one dimmed,
    // untappable row that said "Coming soon" — the whole section was a
    // promise rather than a control. A sheet the user opened mid-Rosary
    // is the wrong place to advertise unbuilt work; bring the section
    // back with the feature, not before it.
}

// MARK: - Choices Shared With the Set's Page

/// The voices as capsules: two or three words that fit one row, each a
/// choice of its own. A choice takes effect on the narration playing,
/// which the player hears through the settings change. Shared by the
/// playback sheet and the set's page, so the choice looks the same
/// wherever it is made.
struct NarrationVoiceChoice: View {

    /// Capsule height: 44 in the sheet, a little less on the set's page
    var height: CGFloat = 44

    private var voices: NarrationVoiceCatalog { .shared }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(voices.voices) { voice in
                let selected = voices.chosenSlug == voice.slug
                Button {
                    voices.choose(voice)
                } label: {
                    Text(voice.name)
                        .font(AppFonts.bodyFont(14))
                        .foregroundColor(selected ? AppColors.background : AppColors.cream.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .background(
                            Capsule()
                                .fill(selected ? AppColors.goldLight : AppColors.cardElevated)
                        )
                }
                .accessibilityLabel(voice.displayName)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .dynamicTypeSize(...Self.largestCapsuleType)
    }

    /// How large the words in a row of choices may grow. Past this the
    /// speed row's "0.75×" was cut to "0…." — a choice no one could
    /// read — so the voices and the speed stop growing here, and their
    /// words shrink a little rather than cut.
    static let largestCapsuleType = DynamicTypeSize.accessibility1
}

/// The narration's speed on a slider, half speed to double in twentieths,
/// its value beside it and a quiet way back to 1× at its end. Five fixed
/// capsules once stood here, and a voice a little too slow at 1× and a
/// little too quick at 1.25× had nowhere between them to go.
///
/// The value is read straight from the service, so the slider agrees
/// with whatever the Lock Screen or CarPlay last set. A drag is heard as
/// it goes when something is playing, and kept only when the finger
/// lifts; a speed chosen before the Rosary begins is the one its first
/// narration plays at.
struct PlaybackSpeedChoice: View {

    private var audio: AudioService { .shared }

    /// The speed under the thumb while it is dragged; the service's own
    /// otherwise
    @State private var draft: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shown: Double { draft ?? audio.playbackRate }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(Self.rateLabel(shown))
                    .font(AppFonts.bodyFont(16))
                    .monospacedDigit()
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .frame(minWidth: 50, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { shown },
                        set: { raw in
                            let rate = Self.detented(raw)
                            draft = rate
                            // Heard as it is dragged, kept on release
                            if audio.isPlaying { audio.setPlaybackRate(rate, remember: false) }
                        }
                    ),
                    in: AudioService.rateRange,
                    onEditingChanged: { editing in
                        guard !editing, let draft else { return }
                        audio.setPlaybackRate(draft)
                        self.draft = nil
                    }
                )
                .tint(AppColors.gold)
                // The system's unlit track all but vanishes on this
                // ground, and at the slow end the thumb stood alone with
                // nothing to say where it could go
                .background(
                    Capsule()
                        .fill(AppColors.cream.opacity(0.16))
                        .frame(height: 4)
                )
            }
            // One adjustable element for VoiceOver, a quarter at a step:
            // a twentieth at a swipe was a long way from 1× to 2×
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Narration speed")
            .accessibilityValue(Self.spokenRate(shown))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: audio.setPlaybackRate((shown * 4).rounded(.down) / 4 + 0.25)
                case .decrement: audio.setPlaybackRate((shown * 4).rounded(.up) / 4 - 0.25)
                @unknown default: break
                }
            }

            // Outlined, so it reads as the way back rather than as the
            // slider's far end; always there, only faded at 1×, so the
            // track never changes length under the thumb
            Button {
                withAnimation(reduceMotion ? nil : Motion.settle) {
                    audio.setPlaybackRate(1)
                }
            } label: {
                Text("1×")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.gold)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 48, minHeight: 30)
                    .overlay(
                        Capsule().strokeBorder(AppColors.gold.opacity(0.45), lineWidth: AppLine.hairline)
                    )
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .disabled(shown == 1)
            .opacity(shown == 1 ? 0.3 : 1)
            .accessibilityLabel("Back to normal speed")
            .accessibilityHidden(shown == 1)
        }
        .frame(minHeight: 44)
        // The thumb landing on 1× is felt, the one speed with a name
        .sensoryFeedback(.selection, trigger: shown == 1) { wasOne, isOne in isOne && !wasOne }
        .dynamicTypeSize(...NarrationVoiceChoice.largestCapsuleType)
    }

    /// Within a hair of 1× the thumb settles on it; everywhere else it
    /// keeps to the twentieths
    static func detented(_ raw: Double) -> Double {
        abs(raw - 1) < 0.04 ? 1 : AudioService.resolvedRate(raw)
    }

    /// "1×" rather than "1.0×", but "1.25×" in full — %g drops trailing
    /// zeros without rounding away a significant digit.
    static func rateLabel(_ rate: Double) -> String {
        "\(String(format: "%g", rate))×"
    }

    /// What VoiceOver says: "1.25 times", or at 1× "normal speed"
    static func spokenRate(_ rate: Double) -> String {
        rate == 1 ? "Normal speed" : "\(String(format: "%g", rate)) times"
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
            .presentationDetents([.height(PlaybackSettingsSheet.height)])
            .presentationBackground(AppColors.background)
            .environment(UserSettings.shared)
    }
}
