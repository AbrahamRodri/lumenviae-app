//
//  RosaryConfirmPage.swift
//  Lumen Viae
//
//  The page a Rosary is confirmed on before it is prayed — the same page
//  for all three of its forms: a meditation set, the Scriptural Rosary
//  and the Holy Rosary (`RosaryForm`).
//
//  The painting fills the top and dissolves into the page; over its foot
//  the title block — a kicker, the name in Cinzel, one italic line. Then
//  YOUR ROSARY TODAY: the two choices that change the prayer, each set
//  out as a pill of two named options with a line beneath saying what the
//  chosen one does, and under them ruled rows for what else is set — the
//  voice and its speed, which mysteries. One gold act at the foot, PRAY,
//  and nothing beneath it.
//
//  The choices once stood in a sheet behind one quiet line ("Female voice
//  · 1× · Every prayer aloud · On the beads"), because open on the page
//  they were a filled card of capsules and switches three of them gold,
//  and the title page read as a settings form. What changed is how few
//  there are: two choices, each a single pill, the rest in rows. Whether
//  the voice says every prayer, and whether the beads are on the screen,
//  change what praying is like; they are shown before PRAY, where they
//  apply, rather than found after it. Counting is offered only while the
//  voice reads the meditation alone (`RosaryChoice.offered`).
//
//  Every choice here is the setting Settings, onboarding and the player's
//  playback sheet keep, so a change made on one page carries to the next
//  Rosary and to every other place it is offered.
//
//  Beneath the rows a page may add its own ledger — a meditation set's
//  meditations, its source, the copy saved on the device — scrolled to
//  past the choices, never between them and PRAY.
//

import SwiftUI

// MARK: - RosaryConfirmPage

struct RosaryConfirmPage<Painting: View, Choices: View, Ledger: View>: View {

    let kicker: String
    let title: String
    var subtitle: String?

    /// PRAY waits on content that is not yet in hand
    var prayEnabled: Bool = true

    /// Set while PRAY waits on the Rosary's content: the page dims under
    /// these words, and Back stays reachable above them, so a cold server
    /// never holds anyone here for the length of a timeout
    var preparing: String? = nil

    let onBack: () -> Void
    let onPray: () -> Void

    @ViewBuilder let painting: () -> Painting
    @ViewBuilder let choices: () -> Choices
    @ViewBuilder let ledger: () -> Ledger

    /// The painting's height, from the very top of the glass
    private static var paintingHeight: CGFloat { 360 }

    /// Where the title block begins, from the top of the glass: over the
    /// painting's foot, where it has begun to dissolve
    private static var titleTop: CGFloat { 212 }

    /// The room the scrolled content keeps clear of the fixed PRAY
    private static var footClearance: CGFloat { 132 }

    /// How far the chrome's ground has come in as the page is scrolled,
    /// 0 at rest to 1, in tenths — so a scroll redraws the page ten times
    /// at most, not on every frame
    @State private var headerGround: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    titleBlock
                        .padding(.top, Self.titleTop)
                        .padding(.horizontal, 28)
                        .devotionalEntrance()

                    choices()
                        .padding(.top, 22)
                        .padding(.horizontal, 24)
                        .devotionalEntrance(delay: 0.08)

                    // Well clear of the rows, so the ledger reads as its
                    // own part of the page rather than a second rule
                    ledger()
                        .padding(.top, 52)
                        .padding(.horizontal, 24)
                        .devotionalEntrance(delay: 0.16)
                }
                .frame(maxWidth: .infinity)
                // The painting rides with the page, behind the title, so
                // scrolling to the ledger carries it away
                .background(alignment: .top) {
                    paintingPlate
                }
                .padding(.bottom, Self.footClearance)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .global).minY
                } action: { top in
                    let ground = (min(max(-top / 120, 0), 1) * 10).rounded() / 10
                    if ground != headerGround { headerGround = ground }
                }
            }
            // The painting begins at the very top of the glass, under the
            // status bar, and the title is placed from there
            .ignoresSafeArea(edges: .top)

            // The one act, fixed at the foot
            VStack {
                Spacer()
                prayFoot
            }

            // The page's own deep ground behind the status bar and Back,
            // coming in only as the page scrolls: at rest the painting
            // runs to the top of the glass, and scrolled, the ledger once
            // ran on under Back with nothing between them
            VStack(spacing: 0) {
                // Solid behind the status bar, then fading out below Back
                Color.clear
                    .frame(height: 0)
                    .background(AppColors.backgroundDeep.ignoresSafeArea(edges: .top))

                LinearGradient(
                    stops: [
                        .init(color: AppColors.backgroundDeep, location: 0),
                        .init(color: AppColors.backgroundDeep.opacity(0.85), location: 0.55),
                        .init(color: AppColors.backgroundDeep.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 76)

                Spacer(minLength: 0)
            }
            .opacity(headerGround)
            .animation(Motion.crossfade, value: headerGround)
            .allowsHitTesting(false)

            if let preparing {
                preparingOverlay(preparing)
                    .transition(.opacity)
            }

            header
        }
        .animation(Motion.crossfade, value: preparing)
        .navigationBarHidden(true)
    }

    private func preparingOverlay(_ words: String) -> some View {
        AppColors.background.opacity(0.72)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(AppColors.gold)

                    Text(words.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
                )
            )
    }

    // MARK: - Painting

    /// Opaque over its first third, then dissolving to clear — a plate
    /// never ends on an edge — under a scrim that darkens the head for
    /// the Back button and settles into the page's own ground at the foot.
    private var paintingPlate: some View {
        painting()
            .frame(maxWidth: .infinity)
            .frame(height: Self.paintingHeight)
            .clipped()
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.35), location: 0),
                        .init(color: .black.opacity(0.1), location: 0.3),
                        .init(color: AppColors.background.opacity(0.7), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.35),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text(kicker.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(3)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

            Text(title)
                .font(AppFonts.titleFont(27))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.5), radius: 8, y: 1)
                .accessibilityAddTraits(.isHeader)

            if let subtitle {
                Text(subtitle)
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            PrayerHeaderButton(icon: "ph-caret-left", size: 16, label: "Back", action: onBack)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Pray

    /// PRAY, and nothing set beneath it — no count, never a duration.
    ///
    /// Its ground turns solid faster than the title pages' long scrim
    /// (`PrayFootScrim`): the ledger scrolls under this foot, and at that
    /// scrim's pace its lines still read through beneath the button.
    /// Tinted in `backgroundDeep`, where the page's gradient ends, so it
    /// only ever deepens.
    private var prayFoot: some View {
        GoldCTAButton(title: "Pray", glyph: .play, action: onPray)
            .disabled(!prayEnabled)
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: AppColors.backgroundDeep.opacity(0), location: 0),
                        .init(color: AppColors.backgroundDeep.opacity(0.92), location: 0.4),
                        // Solid well before the foot, which runs on under
                        // the home indicator
                        .init(color: AppColors.backgroundDeep, location: 0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            )
    }
}

// MARK: - RosaryChoicesSection

/// YOUR ROSARY TODAY: the choices a form offers, then its rows. Reads and
/// writes the settings themselves, so it agrees with every other place
/// they are offered.
struct RosaryChoicesSection: View {

    let form: RosaryForm

    /// The mysteries the Rosary will pray, when the page chooses them —
    /// the Mysteries row changes them
    var mysteries: Binding<MysteryCategory>? = nil

    /// A meditation set's mysteries, which it cannot change: the chaplet
    /// offers no prayers after the Rosary
    var category: MysteryCategory? = nil

    @Environment(UserSettings.self) private var settings
    @State private var sheet: RosaryChoicesSheet?

    /// The day's mysteries, marked in the Mysteries row and its sheet
    private let today = ScheduleService.categoryForToday()

    private var chosenCategory: MysteryCategory? { mysteries?.wrappedValue ?? category }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            YourRosaryTodayLabel()
                .padding(.bottom, 6)

            ForEach(RosaryChoice.offered(for: form, aloud: settings.prayAloud), id: \.self) { choice in
                RosaryChoiceGroup(choice: choice, form: form, value: binding(for: choice))
                    .transition(RosaryChoiceGroup.comingAndGoing)
            }

            // Voice & speed comes and goes with the Scriptural Rosary's
            // Audio, on Counting's timing, since nothing is spoken when
            // its verses are read in silence
            ForEach(RosaryInfoRow.rows(for: form, aloud: settings.prayAloud), id: \.self) { row in
                infoRow(row)
                    .transition(RosaryChoiceGroup.comingAndGoing)
            }
        }
        .animation(Motion.choice, value: settings.prayAloud)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .voice:
                VoiceAndSpeedSheet(form: form, category: chosenCategory)
                    .presentationDetents([.large])
                    .sheetGround()
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            case .mysteries:
                if let mysteries {
                    // As tall as its six rows, as the Pray tray is
                    MysteriesChoiceSheet(form: form, selection: mysteries, today: today)
                        .fittedSheetDetent(estimate: 520)
                        .sheetGround()
                        .dynamicTypeSize(...DynamicTypeSize.appMaximum)
                }
            }
        }
    }

    private func binding(for choice: RosaryChoice) -> Binding<Bool> {
        @Bindable var settings = settings
        switch choice {
        case .audio: return $settings.prayAloud
        case .counting: return $settings.prayOnBeads
        }
    }

    @ViewBuilder
    private func infoRow(_ row: RosaryInfoRow) -> some View {
        switch row {
        case .audio:
            RosaryInfoRowView(
                title: row.title,
                value: RosaryInfoRow.holyAudioValue,
                icon: "ph-speaker-high"
            )
        case .mysteries:
            RosaryInfoRowView(
                title: row.title,
                value: RosaryInfoRow.mysteriesValue(chosenCategory ?? today, today: today),
                hint: "Choose the mysteries"
            ) {
                sheet = .mysteries
            }
        case .voice:
            RosaryInfoRowView(
                title: row.title,
                value: RosaryInfoRow.voiceValue(
                    voice: NarrationVoiceCatalog.shared.chosenVoice.name,
                    // The app's speed, which a chant or a book sounding
                    // meanwhile may have borrowed the player from
                    rate: PlaybackSpeedChoice.rateLabel(AudioService.shared.appRate)
                ),
                hint: "Choose the voice and its speed"
            ) {
                sheet = .voice
            }
        }
    }
}

/// What the choices section can put over the page
private enum RosaryChoicesSheet: String, Identifiable {
    case voice
    case mysteries

    var id: String { rawValue }
}

// MARK: - YourRosaryTodayLabel

/// The section's name in small gold capitals, and a rule fading out
/// beside it
struct YourRosaryTodayLabel: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("YOUR ROSARY TODAY")
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .accessibilityAddTraits(.isHeader)

            LinearGradient(
                colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: AppLine.hairline)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - RosaryChoiceGroup

/// One choice: its glyph and name, the pill of its two options, and a
/// line saying what the chosen one does. Ruled off beneath.
struct RosaryChoiceGroup: View {

    let choice: RosaryChoice
    let form: RosaryForm
    @Binding var value: Bool

    /// How a choice arrives and leaves beneath another — Counting, as the
    /// Audio above it changes, and the Scriptural Rosary's Voice & speed
    /// row with it. Leaving, it is gone before the rows below close over
    /// its place; arriving, it waits for them to make room. As one plain
    /// fade on the rows' own timing, the rows slid through the choice
    /// while it was still half there, words over words.
    static let comingAndGoing: AnyTransition = .asymmetric(
        insertion: .opacity.animation(Motion.choice.delay(0.14)),
        removal: .opacity.animation(Motion.ease(0.1))
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AppIcon(choice.icon, size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .accessibilityHidden(true)

                Text(choice.title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.cream)
            }
            .accessibilityHidden(true)

            RosaryChoicePill(
                title: choice.title,
                options: choice.options(for: form),
                value: $value
            )

            Text(choice.note(for: value, form: form))
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(Motion.choice, value: value)
        }
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.15))
                .frame(height: AppLine.hairline)
        }
    }
}

// MARK: - RosaryChoicePill

/// Two named options side by side in one capsule, the chosen one raised
/// on the card surface inside a gold rim. The lit segment passes from
/// one to the other on `Motion.choice`. To VoiceOver it is a segmented
/// picker: the choice's name, each option, and which is selected.
struct RosaryChoicePill: View {

    /// The choice's name, for VoiceOver: "Audio"
    let title: String
    let options: [RosaryChoice.Option]
    @Binding var value: Bool

    /// False while the setting still stands at its default, never
    /// answered — the Prayer Book's, before it has asked. The lit option
    /// is only the default then, so a tap on it answers too.
    var isAnswered: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                segment(option)
            }
        }
        .padding(3)
        .overlay(
            Capsule()
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: 1)
        )
        .sensoryFeedback(.selection, trigger: [value, isAnswered])
        .accessibilityRepresentation {
            Picker(title, selection: $value) {
                ForEach(options, id: \.value) { option in
                    Text(option.name).tag(option.value)
                }
            }
            .pickerStyle(.segmented)
        }
        // A segmented picker does nothing when its selected segment is
        // chosen again, so while the lit option is only the default,
        // VoiceOver is offered it as an action of its own
        .accessibilityActions {
            if !isAnswered, let lit = options.first(where: { $0.value == value }) {
                Button("Choose \(lit.name)") { answer(with: lit.value) }
            }
        }
    }

    /// The reader's choice. Written even when it is the value already
    /// shown, since while unanswered that write is the answer.
    private func answer(with chosen: Bool) {
        withAnimation(Motion.choice) { value = chosen }
    }

    private func segment(_ option: RosaryChoice.Option) -> some View {
        let on = option.value == value

        return Button {
            guard !on || !isAnswered else { return }
            answer(with: option.value)
        } label: {
            Text(option.name.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.4)
                .foregroundColor(on ? AppColors.goldLight : AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Capsule().fill(on ? AppColors.cardElevated : Color.clear)
                )
                .overlay(
                    Capsule().strokeBorder(
                        on ? AppColors.gold.opacity(0.7) : Color.clear,
                        lineWidth: 1
                    )
                )
                .contentShape(Capsule())
        }
        // A row's settle, not a bare glyph's dip: half the pill scaling
        // to 0.9 and fading to 0.6 read as a jolt under the thumb
        .buttonStyle(SacredCardButtonStyle())
    }
}

// MARK: - RosaryChoiceSettingsRow

/// One of the Rosary's two choices as a Settings row, in the row a switch
/// once stood in: its glyph and name, the pill of its two options, and
/// what the chosen one does. A switch could say only on or off; the pill
/// says which of two ways, in the words every other place uses.
///
/// Counting holds only while the voice reads the meditation alone, so
/// with the Whole Rosary its row stands dimmed and says why, rather than
/// leaving a choice that changes nothing.
///
/// The Prayer Book's Aloud or In Silence stands beneath them as the same
/// row, in its own words (`PrayerBookAudio`), so the two read as one
/// family and never as one setting.
struct RosaryChoiceSettingsRow: View {

    let icon: String
    let title: String
    let options: [RosaryChoice.Option]
    @Binding var value: Bool

    /// What the chosen option does
    let note: (Bool) -> String

    /// False while another choice makes this one moot
    var isAvailable: Bool = true

    /// What the row says while it is not available
    var unavailableNote: String = "With the Whole Rosary, the voice moves the beads on the screen."

    /// False while the setting stands at a default nobody chose
    /// (`RosaryChoicePill.isAnswered`)
    var isAnswered: Bool = true

    /// One of the Rosary's two choices, in `RosaryChoice`'s words
    init(choice: RosaryChoice, value: Binding<Bool>, isAvailable: Bool = true) {
        self.init(
            icon: choice.icon,
            title: choice.title,
            options: choice.options(for: .meditation),
            value: value,
            isAvailable: isAvailable,
            note: { choice.note(for: $0) }
        )
    }

    init(
        icon: String,
        title: String,
        options: [RosaryChoice.Option],
        value: Binding<Bool>,
        isAvailable: Bool = true,
        isAnswered: Bool = true,
        note: @escaping (Bool) -> String
    ) {
        self.icon = icon
        self.title = title
        self.options = options
        self._value = value
        self.isAvailable = isAvailable
        self.isAnswered = isAnswered
        self.note = note
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AppIcon(icon, size: 18)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(AppColors.cream)
                    .accessibilityHidden(true)

                RosaryChoicePill(
                    title: title,
                    options: options,
                    value: $value,
                    isAnswered: isAnswered
                )
                .disabled(!isAvailable)
                .opacity(isAvailable ? 1 : 0.4)

                Text(isAvailable ? note(value) : unavailableNote)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .animation(Motion.choice, value: value)
        .animation(Motion.choice, value: isAvailable)
        .animation(Motion.choice, value: isAnswered)
    }
}

// MARK: - RosaryInfoRowView

/// A ruled row: what it is in small capitals, what is set beside it,
/// and a caret when a tap changes it — or, for a fact that is not a
/// choice, its own glyph and no tap at all.
struct RosaryInfoRowView: View {

    let title: String
    let value: String
    var icon: String = "ph-caret-right"
    var hint: String = ""
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityValue(value)
                .accessibilityHint(hint)
                .accessibilityAddTraits(.isButton)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityValue(value)
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Text(value)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.trailing)
                .contentTransition(.opacity)

            AppIcon(icon, size: 11)
                .foregroundColor(AppColors.gold.opacity(0.6))
        }
        .padding(.vertical, 10)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.15))
                .frame(height: AppLine.hairline)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - VoiceAndSpeedSheet

/// Who reads and how fast — and, for the four sets of the Rosary, the
/// prayers some add after it, which only a voice saying every prayer
/// says. In the sheet grammar: the voices as capsules, the speed on its
/// slider, then ruled rows each with its own switch.
private struct VoiceAndSpeedSheet: View {

    let form: RosaryForm
    let category: MysteryCategory?

    @Environment(UserSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(kicker: "Your Rosary today", title: "Voice & speed") {
                    SheetHeaderAction(title: "Done") { dismiss() }
                }

                SheetSectionLabel("Voice")
                NarrationVoiceChoice()
                    .padding(.horizontal, SheetMetrics.gutter)

                SheetSectionLabel("Speed")
                PlaybackSpeedChoice()
                    .padding(.horizontal, SheetMetrics.gutter)

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
                    SheetNote(form == .holy
                        ? "Said aloud after the closing prayer."
                        : "Said aloud after the closing prayer, with the Whole Rosary.")
                }
            }
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
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

// MARK: - MysteriesChoiceSheet

/// The five sets of mysteries and the chaplet, the chosen one lit and
/// checked, the day's marked TODAY. A tap chooses and closes: nothing is
/// remembered, and tomorrow's page opens on tomorrow's mysteries.
private struct MysteriesChoiceSheet: View {

    let form: RosaryForm
    @Binding var selection: MysteryCategory
    let today: MysteryCategory

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                kicker: form == .holy ? "The Holy Rosary" : "The Scriptural Rosary",
                title: "Mysteries"
            ) {
                SheetHeaderAction(title: "Done") { dismiss() }
            }

            ForEach(MysteryCategory.allCases, id: \.self) { category in
                let chosen = category == selection

                Button {
                    withAnimation(Motion.crossfade) { selection = category }
                    dismiss()
                } label: {
                    SheetRow(
                        category.devotionTitle,
                        // The check takes the trailing edge from TODAY when
                        // today's mysteries are the chosen ones, as they
                        // usually are: the line under the name says it
                        detail: chosen && category == today ? "Today · \(category.subtitle)" : category.subtitle,
                        icon: category.iconName,
                        accessory: chosen ? .check : (category == today ? .label("Today") : .none),
                        isLit: chosen
                    )
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel(category.devotionTitle + (category == today ? ", today's" : ""))
                .accessibilityAddTraits(chosen ? [.isSelected] : [])
            }
        }
        .padding(.bottom, 24)
    }
}
