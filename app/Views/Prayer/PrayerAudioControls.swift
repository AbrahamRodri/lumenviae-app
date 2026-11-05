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
        guard seconds.isFinite, seconds > 0 else {
            return String(localized: "0 seconds", comment: "VoiceOver: a narration position or length of nothing yet")
        }
        let whole = Int(seconds)
        let mins = whole / 60
        let secs = whole % 60
        // "1 minute" and "1 second" come from the catalog's plural variations
        let minutes = String(
            localized: "\(mins) minutes",
            comment: "VoiceOver: part of a narration position or length, a number of minutes"
        )
        let sec = String(
            localized: "\(secs) seconds",
            comment: "VoiceOver: part of a narration position or length, a number of seconds"
        )
        if mins == 0 { return sec }
        if secs == 0 { return minutes }
        return String(
            localized: "\(minutes) \(sec)",
            comment: "VoiceOver: a narration position or length, minutes then seconds, like 3 minutes 20 seconds"
        )
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

    /// The glyph grows with the reader's text size, inside its 44pt frame
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

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
                    AppIcon(name, size: size * textScale)
                case .symbol(let name):
                    Image(systemName: name)
                        .font(.system(size: size * textScale, weight: .light))
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
        .accessibilityLabel(isLoading ? Text("Loading audio") : (isPlaying ? Text("Pause") : Text("Play")))
    }
}

// MARK: - Playback Settings

/// The player's Voice sheet: which voice reads, and how fast the
/// prayers are said (meditations are always read at 1×).
///
/// The voice lives here as well as in Settings because this is the
/// player's own settings surface: someone who finds the narrator is not
/// for them mid-Rosary should not have to leave the Rosary to say so.
struct PlaybackSettingsSheet: View {

    @Environment(\.dismiss) private var dismiss

    /// The sheet's height, for its detent: the header, the voices and
    /// the prayers' speed under their labels, and the speed's note
    static let height: CGFloat = 360

    /// The detents the player gives it: its own height, or at the
    /// accessibility text sizes the whole glass, where the rows once
    /// stood crushed into 530 points, one switch's name over another's
    static func detents(for size: DynamicTypeSize) -> Set<PresentationDetent> {
        size.isAccessibilitySize ? [.large] : [.height(height)]
    }

    var body: some View {
        // Scrolls only when the words outgrow the sheet
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: String(
                    localized: "Playback",
                    comment: "Playback settings sheet on the prayer screen: its title"
                )) {
                    SheetHeaderAction(title: String(
                        localized: "Done",
                        comment: "Sheet header button that closes the sheet"
                    )) { dismiss() }
                }

                SheetSectionLabel(String(
                    localized: "Voice",
                    comment: "Playback settings sheet: section label over the narration voices"
                ))

                NarrationVoiceChoice()
                    .padding(.horizontal, SheetMetrics.gutter)
                SheetNote(UserSettings.narrationVoiceCaption)

                SheetSectionLabel(String(
                    localized: "Prayer Speed",
                    comment: "Playback settings sheet: section label over the steps that set how fast the prayers are said"
                ))

                PlaybackSpeedChoice()
                    .padding(.horizontal, SheetMetrics.gutter)
                SheetNote(String(
                    localized: "Meditations are always read at 1×.",
                    comment: "Playback settings sheet: the note under the prayers' speed: it does not change the meditations"
                ))

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
                    Text(voice.displayName)
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

/// The prayers' speed as six steps, 0.8× to 1.3×, each a capsule as the
/// voices are. Abraham, Nov 2026: "the step buttons replace the speed
/// slider". A slider of twentieths from 0.7× to 1.7× stood here, and a
/// speed a reader had liked could not be found again.
///
/// It sets the app's speed (`appRate`), which the prayers are said at;
/// a meditation is always read at 1× (`SpokenRosaryPlayer.setPace`). The
/// value is read from the service, so a speed chosen on the Lock Screen
/// shows; one that is not a step (a 1.5× kept from the slider) lights
/// none, and a tap on a step takes the prayers there.
struct PlaybackSpeedChoice: View {

    /// The speeds offered, 1× among them
    static let steps: [Double] = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3]

    private var audio: AudioService { .shared }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Self.steps, id: \.self) { rate in
                let selected = Self.isChosen(rate, appRate: audio.appRate)
                Button {
                    withAnimation(reduceMotion ? nil : Motion.settle) { audio.setAppRate(rate) }
                } label: {
                    Text(Self.rateLabel(rate))
                        .font(AppFonts.bodyFont(14))
                        .monospacedDigit()
                        .foregroundColor(selected ? AppColors.background : AppColors.cream.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            Capsule()
                                .fill(selected ? AppColors.goldLight : AppColors.cardElevated)
                        )
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel(Self.spokenRate(rate))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .sensoryFeedback(.selection, trigger: audio.appRate)
        .dynamicTypeSize(...NarrationVoiceChoice.largestCapsuleType)
    }

    /// Whether a step is the speed the prayers are said at
    static func isChosen(_ step: Double, appRate: Double) -> Bool {
        abs(step - appRate) < 0.001
    }

    /// "1×" rather than "1.0×", but "1.25×" in full — %g drops trailing
    /// zeros without rounding away a significant digit.
    static func rateLabel(_ rate: Double) -> String {
        "\(String(format: "%g", rate))×"
    }

    /// What VoiceOver says: "1.25 times", or at 1× "normal speed"
    static func spokenRate(_ rate: Double) -> String {
        rate == 1
            ? String(localized: "Normal speed", comment: "VoiceOver: the narration speed at 1x")
            : String(
                localized: "\(String(format: "%g", rate)) times",
                comment: "VoiceOver: the narration speed as a multiple, like 1.25 times"
            )
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
