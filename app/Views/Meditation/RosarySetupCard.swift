//
//  RosarySetupCard.swift
//  Lumen Viae
//
//  How this Rosary will be prayed, chosen on the title page before PRAY:
//  who reads, how fast, whether every prayer is said aloud, and whether
//  the beads are counted on the screen. The Rosary is set up the way
//  one sets a table before sitting down, rather than discovered in the
//  player's sheet once the first decade is already moving.
//
//  On the page it is one quiet ruled line — what is set, said in a few
//  words, and a caret — and the choices themselves stand in a sheet. The
//  choices once stood open on the page, a filled card of capsules and
//  switches over the painting, and the title page read as a settings
//  form with PRAY at its foot.
//
//  Every choice is the same setting the player's playback sheet and
//  Settings keep — the voice catalogue, the remembered speed,
//  `UserSettings.prayAloud` and `prayOnBeads` — so the defaults are
//  whatever was chosen last, and a change made here holds in the Rosary
//  and can be changed again there.
//
//  For the four sets of the Rosary it also offers the prayers some add
//  after the closing prayer (`RosaryClosingExtra`), the same switches as
//  Settings; the Seven Sorrows chaplet closes in its own way, so its
//  sets do not offer them.
//

import SwiftUI

/// Which title page the choices stand on: the Scriptural Rosary has its
/// beads always, so it offers no bead counter; the Rosary Aloud is said
/// aloud always as well, so it offers no switch for that either
enum RosarySetupKind {
    case meditation
    case scriptural
    case plain

    /// Whether every prayer is said aloud, as this kind of Rosary will
    /// pray it: the setting, except where there is no other way
    func praysAloud(_ settings: UserSettings) -> Bool {
        self == .plain || settings.prayAloud
    }
}

// MARK: - RosarySetupCard

/// The line on the title page: HOW YOU'LL PRAY over what is set, and a
/// caret to the sheet that sets it
struct RosarySetupCard: View {

    /// The set's mysteries, when known: the chaplet offers no closing
    /// prayers
    var category: MysteryCategory? = nil
    var kind: RosarySetupKind = .meditation

    @Environment(UserSettings.self) private var settings
    @State private var showsChoices = false

    var body: some View {
        Button {
            showsChoices = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOW YOU'LL PRAY")
                        .font(AppFonts.labelFont(9))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold.opacity(0.8))

                    Text(RosarySetup.line(kind: kind, category: category, settings: settings))
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.7))
            }
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .overlay(alignment: .top) { rule }
            .overlay(alignment: .bottom) { rule }
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("How you'll pray")
        .accessibilityValue(RosarySetup.line(kind: kind, category: category, settings: settings))
        .accessibilityHint("Choose the voice, the speed, and how the prayers are said")
        .sheet(isPresented: $showsChoices) {
            RosarySetupSheet(category: category, kind: kind)
                .presentationDetents([.large])
                .sheetGround()
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.2))
            .frame(height: AppLine.hairline)
    }
}

// MARK: - RosarySetup

/// What is set, said in words, for the line on the page
enum RosarySetup {

    /// "Female voice · 1× · Every prayer aloud · On the beads"
    static func line(kind: RosarySetupKind, category: MysteryCategory?, settings: UserSettings) -> String {
        var parts = [
            "\(NarrationVoiceCatalog.shared.chosenVoice.name) voice",
            PlaybackSpeedChoice.rateLabel(AudioService.shared.playbackRate)
        ]
        switch kind {
        case .meditation:
            parts.append(settings.prayAloud ? "Every prayer aloud" : "The meditation aloud")
            parts.append(settings.prayOnBeads ? "On the beads" : "Your own count")
        case .scriptural:
            parts.append(settings.prayAloud ? "Every prayer aloud" : "Read in silence")
        case .plain:
            // Aloud is what it is; the line says only what can change
            break
        }
        if category != .sevenSorrows, kind.praysAloud(settings) {
            let extras = settings.closingExtras
            if !extras.isEmpty {
                parts.append("+ " + extras.map(\.shortTitle).joined(separator: ", "))
            }
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - RosarySetupSheet

/// The choices, in the sheet grammar: the voice and speed as capsules,
/// then ruled rows each with its own switch
private struct RosarySetupSheet: View {

    let category: MysteryCategory?
    let kind: RosarySetupKind

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(kicker: "Before you begin", title: "How you'll pray") {
                    SheetHeaderAction(title: "Done") { dismiss() }
                }

                SheetSectionLabel("Voice")
                NarrationVoiceChoice()
                    .padding(.horizontal, SheetMetrics.gutter)

                SheetSectionLabel("Speed")
                PlaybackSpeedChoice()
                    .padding(.horizontal, SheetMetrics.gutter)

                SheetSectionLabel("The prayers")
                // The Rosary Aloud has no switch here: a Rosary said
                // aloud is the whole of it, so its note stands alone
                if kind != .plain {
                    switchRow(
                        UserSettings.prayAloudTitle,
                        detail: UserSettings.prayAloudDetail(
                            isOn: settings.prayAloud,
                            onBeads: kind == .scriptural || settings.prayOnBeads
                        ),
                        icon: "ph-hands-praying",
                        isOn: $settings.prayAloud
                    )
                }
                if kind == .meditation {
                    switchRow(
                        UserSettings.beadCounterTitle,
                        detail: UserSettings.beadCounterDetail(isOn: settings.prayOnBeads),
                        icon: "ch-rosary",
                        isOn: $settings.prayOnBeads
                    )
                }


                if category != .sevenSorrows {
                    SheetSectionLabel("After the Rosary")
                    ForEach(RosaryClosingExtra.allCases, id: \.self) { extra in
                        switchRow(
                            extra.title,
                            detail: extra.detail,
                            icon: extra.icon,
                            isOn: Binding(
                                get: { settings.isChosen(extra) },
                                set: { settings.setChosen(extra, $0) }
                            )
                        )
                    }
                    SheetNote(kind == .plain
                        ? "Said aloud after the closing prayer."
                        : "Said aloud after the closing prayer, when every prayer is said aloud.")
                }
            }
            .padding(.bottom, 24)
        }
    }

    /// A ruled row whose whole width is its switch
    private func switchRow(_ title: String, detail: String, icon: String, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(Motion.settle) { isOn.wrappedValue.toggle() }
        } label: {
            SheetRow(title, detail: detail, icon: icon, detailLineLimit: nil) {
                BeadSwitch(isOn: isOn.wrappedValue)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
        .accessibilityHint(detail)
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - SetupTogglePill

/// A named switch as one capsule: the icon, the words, and a bead for a
/// knob. The whole pill is the target; the switch inside it is only the
/// drawing.
struct SetupTogglePill: View {

    let icon: String
    let title: String
    @Binding var isOn: Bool
    var hint: String = ""

    var body: some View {
        Button {
            withAnimation(Motion.settle) { isOn.toggle() }
        } label: {
            HStack(spacing: 7) {
                AppIcon(icon, size: 14)
                    .foregroundColor(isOn ? AppColors.gold : AppColors.cream.opacity(0.6))

                Text(title)
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream.opacity(isOn ? 1 : 0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                BeadSwitch(isOn: isOn)
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(AppColors.cardElevated))
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - BeadSwitch

/// A switch in the app's own hand: a hairline track with a bead for its
/// knob. On, the bead is lit with the same gold sheen as a prayed bead
/// on the strand and rests at the right on a track washed with gold;
/// off, it is a hollow bead at the left on a track barely there. The
/// knob travels with `Motion.settle`, so the change is seen, not just
/// the result.
struct BeadSwitch: View {
    let isOn: Bool

    private let width: CGFloat = 38
    private let height: CGFloat = 22
    private let knob: CGFloat = 16

    var body: some View {
        let travel = (width - knob) / 2 - 3

        ZStack {
            Capsule()
                .fill(isOn ? AppColors.gold.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    Capsule().strokeBorder(
                        isOn ? AppColors.gold.opacity(0.75) : AppColors.cream.opacity(0.3),
                        lineWidth: AppLine.hairline
                    )
                )

            Circle()
                .fill(isOn ? AnyShapeStyle(AppColors.goldGradient) : AnyShapeStyle(AppColors.cream.opacity(0.12)))
                .overlay(
                    Circle().strokeBorder(
                        isOn ? Color.clear : AppColors.cream.opacity(0.6),
                        lineWidth: 1
                    )
                )
                .frame(width: knob, height: knob)
                .shadow(color: isOn ? AppColors.gold.opacity(0.5) : .clear, radius: 4)
                .offset(x: isOn ? travel : -travel)
        }
        .frame(width: width, height: height)
        .animation(Motion.settle, value: isOn)
        .accessibilityHidden(true)
    }
}
