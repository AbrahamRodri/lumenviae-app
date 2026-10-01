//
//  ConsecrationDayFlowView.swift
//  Lumen Viae
//
//  The day itself: each of its prayers, then the reading, as one screen
//  you move through rather than a chain of screens that push each other.
//
//  The prayers come first because the day's plan asks for them first:
//  the Veni Creator and the Ave Maris Stella are said to ask for the
//  light the reading is then read by. A day that opened on the text and
//  prayed afterwards had that backwards.
//
//  The Consecrate dashboard lets you enter anywhere — the hero opens the
//  first prayer, a prayer row opens that prayer, the reading card opens
//  the reading — so this is built to be entered anywhere and to walk in
//  both directions from there. Swipe or use PREV/NEXT; the dots say
//  where you are in the day. AMEN, on the last step, carries the day
//  into its reflection — which stands in this screen's place in the
//  stack rather than on top of it, so leaving the reflection leaves the
//  day rather than reversing back through everything just finished.
//
//  The reading used to be a full-screen cover owned by the dashboard,
//  which meant continuing from it dismissed the cover, showed the
//  dashboard for a beat, and only then pushed the prayers. Making it a
//  step of this screen removes that flash entirely.
//

import SwiftUI
import AVFoundation

// MARK: - ConsecrationDayFlowView

struct ConsecrationDayFlowView: View {

    // MARK: - Properties

    @Binding var path: [ConsecrationRoute]

    let dayNumber: Int

    init(
        path: Binding<[ConsecrationRoute]>,
        dayNumber: Int,
        startStep: ConsecrationDayStep = .prayer(0)
    ) {
        self._path = path
        self.dayNumber = dayNumber
        self._pendingStart = State(initialValue: startStep)
    }

    // MARK: - Environment

    @Environment(UserSettings.self) private var settings
    @Environment(ConsecrationViewModel.self) private var viewModel

    // MARK: - State

    @State private var stepIndex: Int = 0

    /// The step to open on, consumed once on first appearance
    @State private var pendingStart: ConsecrationDayStep?

    /// The day's index — every step of the day, reachable from any of them
    @State private var showDayIndex = false

    /// True once the chant's transport has scrolled above the page, so
    /// the header can carry a small play control in its place
    @State private var transportScrolledAway = false

    /// A chant that would not play. The transport says so rather than
    /// sitting there dead — the prayer is still there to pray.
    @State private var audioError: String?

    /// In-flight chant load, cancelled when the step changes so a stale
    /// load cannot land over the prayer now on screen.
    @State private var audioLoadTask: Task<Void, Never>?
    @State private var isLoadingChant = false

    /// The day's claim on the shared player, taken for a step with a
    /// chant. The transport reads and drives the player only through it,
    /// so a player some other flow left paused, loading or failed is not
    /// this day's chant, and draws no pause glyph, spinner or error here;
    /// the day's teardown cannot silence whatever flow the user moved on
    /// to; and its Lock Screen arrows are the day's only while it holds
    /// the player.
    @State private var audioClaim: AudioClaim?

    /// The pace the day's chants are sung at: as the cantor sang them, as
    /// the Chant Library first plays them. A Rosary read at 1.5× has not
    /// thereby chosen a speed for sung Latin, so the pace is borrowed, and
    /// the app's narration speed comes back untouched when the claim ends.
    static let chantRate: AudioRatePolicy = .borrowed(1.0)

    /// The chant whose score is open over the day
    @State private var scoreChant: Chant?

    /// Lock Screen artwork for the chants. The Coronation of Mary is the
    /// nearest bundled image to the consecration's subject and matches the
    /// crown used as the consecration symbol elsewhere; swap in dedicated
    /// art here if one is ever added to the catalog.
    private let dayArtworkAsset = "glorious_coronation"

    private let audio = AudioService.shared

    // MARK: - Day

    private var day: ConsecrationDay? {
        ConsecrationData.day(dayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    private var prayers: [ConsecrationPrayer] {
        guard let phase else { return [] }
        return ConsecrationData.prayers(for: phase, language: settings.prayerLanguage)
    }

    private var readings: [ConsecrationReading] {
        day?.readings ?? []
    }

    /// Bounds-checked: a step index can outlive its day if the day
    /// changes under the flow.
    private func reading(at index: Int) -> ConsecrationReading? {
        guard index >= 0, index < readings.count else { return nil }
        return readings[index]
    }

    /// Every prayer, then every reading of the day
    private var steps: [ConsecrationDayStep] {
        prayers.indices.map { ConsecrationDayStep.prayer($0) }
            + readings.indices.map { ConsecrationDayStep.reading($0) }
    }

    private var currentStep: ConsecrationDayStep {
        guard stepIndex >= 0, stepIndex < steps.count else { return .prayer(0) }
        return steps[stepIndex]
    }

    private var currentPrayer: ConsecrationPrayer? {
        guard case .prayer(let index) = currentStep,
              index >= 0, index < prayers.count else { return nil }
        return prayers[index]
    }

    private var isFirstStep: Bool { stepIndex <= 0 }

    private var isLastStep: Bool { stepIndex >= steps.count - 1 }

    private var dayLabel: String {
        phase == .consecrationDay ? "CONSECRATION DAY" : "DAY \(dayNumber)"
    }

    /// What the quiet forward control says. "Next" is right between
    /// prayers; leaving the prayers, it says what comes next to do.
    private var forwardTitle: String {
        guard isLastPrayerStep else { return "Next" }
        return readings.count > 1 ? "Go to the readings" : "Go to the reading"
    }

    /// True on the final prayer, where forward leaves the prayers for
    /// the reading rather than turning to another page of the same kind.
    private var isLastPrayerStep: Bool {
        if case .prayer(let index) = currentStep { return index == prayers.count - 1 }
        return false
    }

    private var accessibleStepName: String {
        switch currentStep {
        case .reading(let index):
            return readings.count > 1
                ? "reading \(index + 1) of \(readings.count)"
                : "the reading"
        case .prayer(let index): return "prayer \(index + 1) of \(prayers.count)"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ConsecrationPhaseBackground(phase: phase)
                .ignoresSafeArea()

            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .simultaneousGesture(stepSwipeGesture)
        .sensoryFeedback(.impact(weight: .light), trigger: stepIndex)
        .onAppear {
            // Resolving the start step needs `prayers`, which needs the
            // environment — so it happens here rather than in init, and
            // is consumed once so a redraw can never drag the user back
            // to the step they entered on.
            if let pending = pendingStart {
                stepIndex = steps.firstIndex(of: pending) ?? 0
                pendingStart = nil
            }
            loadAudioIfAvailable()
        }
        .onDisappear {
            audioLoadTask?.cancel()
            audioLoadTask = nil
            // The day's chant stopped and the audio session handed back so
            // other apps' audio can resume — if the player is still the
            // day's; nothing at all if another flow has taken it since
            audioClaim?.release()
            audioClaim = nil
        }
        .onChange(of: stepIndex) {
            // Preserve the Lock Screen player across a step change — the
            // next chant republishes over it. Tearing it down collapsed the
            // player between every prayer of the day.
            audioClaim?.unload(preservingNowPlaying: true)
            audioError = nil
            loadAudioIfAvailable()
        }
        .sheet(item: $scoreChant) { chant in
            // The score alone: the day's own transport goes on sounding
            // beneath it
            ChantScoreSheet(chant: chant, showsTransport: false)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .onChange(of: steps.count) { _, newCount in
            // Changing the prayer language can change the set; never
            // leave the index pointing past the end.
            stepIndex = min(stepIndex, max(newCount - 1, 0))
        }
        .sheet(isPresented: $showDayIndex) {
            ConsecrationDayIndexSheet(
                dayNumber: dayNumber,
                prayers: prayers,
                current: currentDestination,
                isComplete: viewModel.isDayCompleted(dayNumber),
                onSelect: open
            )
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    /// Where the index should mark as "here"
    private var currentDestination: ConsecrationDayDestination {
        switch currentStep {
        case .reading: return .reading
        case .prayer(let index): return .prayer(index)
        }
    }

    /// The index can send the user anywhere in the day. Reading and
    /// prayers are steps of this screen; the reflection is its own.
    private func open(_ destination: ConsecrationDayDestination) {
        switch destination {
        case .prayer(let index):
            goToStep(index)
        case .reading:
            goToStep(prayers.count)
        case .reflection:
            openReflection()
        }
    }

    /// The reflection is the day's last place, not a screen stacked on
    /// top of its prayers — so it *replaces* the day flow in the stack
    /// rather than piling on it.
    ///
    /// Stacking meant leaving the reflection dropped you back into the
    /// prayer you had just finished, and then into the reading behind
    /// it: three taps to get out of a day you had already closed. Now
    /// one tap leaves the day, and the reflection's own index still
    /// walks back to any reading or prayer.
    private func openReflection() {
        let reflection = ConsecrationRoute.journal(dayNumber: dayNumber)

        if path.isEmpty {
            path.append(reflection)
        } else {
            path[path.count - 1] = reflection
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 8)

            stepContent

            Spacer(minLength: 0)

            navigationButtons
                .padding(.bottom, 16)
        }
    }

    // MARK: - Gestures

    /// Horizontal swipe moves through the day. The angle gate keeps
    /// vertical reading scrolls from ever counting, and a forward swipe
    /// on the last step does nothing — the day is carried into its
    /// reflection only by the explicit AMEN tap.
    private var stepSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }

                if dx < 0 {
                    guard !isLastStep else { return }
                    goToStep(stepIndex + 1)
                } else {
                    // A drag begun on the left bezel is the navigation
                    // stack's interactive pop. Stepping back on the way
                    // out resets audio mid-transition and lands the user
                    // somewhere they didn't ask for.
                    guard value.startLocation.x > 40, !isFirstStep else { return }
                    goToStep(stepIndex - 1)
                }
            }
    }

    private func goToStep(_ index: Int) {
        let clamped = min(max(index, 0), max(steps.count - 1, 0))
        guard clamped != stepIndex else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            stepIndex = clamped
        }
    }

    // MARK: - Audio

    /// Wires the Lock Screen arrows and AirPods presses to the day's steps,
    /// so a consecration can be prayed hands-off exactly like the Rosary.
    /// Re-called on every step change to keep the end-of-day availability
    /// honest.
    private func attachChantNavigation(to claim: AudioClaim) {
        claim.navigation = AudioNavigation(
            canGoNext: !isLastStep,
            canGoPrevious: !isFirstStep,
            onNext: { goToStep(stepIndex + 1) },
            onPrevious: { goToStep(stepIndex - 1) }
        )
    }

    /// The chant this prayer is sung to, from the Chant Library — the
    /// same bundled recording its page plays, so the day sounds in a
    /// chapel with no signal.
    private func chant(for prayer: ConsecrationPrayer) -> Chant? {
        ChantCatalog.chants(forPrayer: prayer.id).first
    }

    private var currentChant: Chant? {
        currentPrayer.flatMap(chant(for:))
    }

    /// Whether the shared player is still sounding the chant this day
    /// loaded: its claim holds the player, and the item is the one it
    /// loaded. The Chant Library sings some of the same recordings; by
    /// file and load generation, as this was once decided, the day and the
    /// library both held a recording they shared, and closing one silenced
    /// the other.
    private var ownsAudio: Bool { audioClaim?.holdsItem ?? false }

    private func loadAudioIfAvailable(thenPlay: Bool = false) {
        // A step with no chant takes nothing: the Lock Screen stays with
        // whatever holds it. It once took the arrows here anyway, over
        // audio it never loaded. The day's own claim from a step before
        // keeps its arrows, so the day can still be stepped from there.
        guard let prayer = currentPrayer, let chant = chant(for: prayer), let url = chant.audioURL else {
            if let claim = audioClaim, claim.isCurrent { attachChantNavigation(to: claim) }
            return
        }

        // Something else sounding — a chant the library is singing — keeps
        // the player, and its Lock Screen arrows, until the day's own play
        // is pressed (`ifIdle`). Loaded ahead, the day's chant silenced it
        // the moment the day opened, though nobody had asked the day to sing.
        let claim: AudioClaim
        if let held = audioClaim, held.isCurrent {
            claim = held
        } else {
            guard let taken = audio.claim(.consecration, rate: Self.chantRate, ifIdle: !thenPlay) else { return }
            claim = taken
            audioClaim = taken
        }
        attachChantNavigation(to: claim)

        // A step change while a load is in flight would let the stale
        // prayer's chant land over the one now on screen.
        audioLoadTask?.cancel()

        // The same recording the library left in the player, paused part
        // way, is loaded afresh by the claim, so the day's chant begins at
        // its top
        isLoadingChant = true
        audioLoadTask = Task {
            defer { isLoadingChant = false }
            let ready = await claim.load(
                url,
                title: prayer.title,
                subtitle: "Consecration to Mary",
                artworkAssetName: dayArtworkAsset,
                album: phase == .consecrationDay ? "Consecration Day" : "Day \(dayNumber)",
                queueIndex: stepIndex,
                queueCount: steps.count,
                claimNowPlaying: true
            )
            // Another step, or another flow took the player meanwhile:
            // nothing to say
            guard !Task.isCancelled, currentPrayer?.id == prayer.id, claim.isCurrent else { return }
            guard ready || claim.holdsItem else {
                // The prayer reads perfectly well without the chant — say
                // so once, quietly, rather than leaving a dead transport.
                audioError = "The chant couldn't be played. The prayer is here to pray."
                return
            }
            if thenPlay { claim.play() }
        }
    }

    private func audioPlayer(_ chant: Chant) -> some View {
        let loaded = audioClaim?.duration ?? 0
        return VStack(spacing: 6) {
            ChantTransportBar(
                isPlaying: audioClaim?.isPlaying ?? false,
                isLoading: isLoadingChant,
                currentTime: audioClaim?.currentTime ?? 0,
                duration: loaded > 0 ? loaded : chant.duration,
                errorMessage: audioError ?? audioClaim?.errorMessage,
                isReady: ownsAudio,
                onToggle: {
                    // A player another flow took back is loaded afresh,
                    // then played, rather than toggled on someone else
                    if ownsAudio { audioClaim?.togglePlayback() } else { loadAudioIfAvailable(thenPlay: true) }
                },
                onSeek: { audioClaim?.seek(to: $0) }
            )

            HStack(alignment: .center, spacing: 12) {
                // Wraps rather than truncates: at the largest text sizes a
                // two-line limit cut the singers' name off
                Text(ChantCatalog.credit)
                    .font(AppFonts.readingItalicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Button {
                    scoreChant = chant
                } label: {
                    Text("SHEET MUSIC")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.85))
                        .fixedSize()
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Show the sheet music")
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            PrayerHeaderButton(icon: "ph-x", size: 16, label: "Leave the day") {
                // A second tap during the pop animation would call
                // removeLast() on an empty path and crash
                if !path.isEmpty { path.removeLast() }
            }

            Spacer()

            ConsecrationDayIndexButton(
                dayLabel: dayLabel,
                stepCount: steps.count,
                currentStep: stepIndex,
                accessibleValue: "On \(accessibleStepName)"
            ) {
                showDayIndex = true
            }

            Spacer()

            // Balances the close button so the progress stays centered —
            // and holds the chant's play control once the transport
            // itself has scrolled off the top of the page.
            ZStack {
                Color.clear
                    .frame(width: 44, height: 44)

                if showsMiniTransport {
                    miniTransportButton
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 16)
    }

    /// True once the chant's transport has scrolled above the page and
    /// the prayer actually has one to reach.
    private var showsMiniTransport: Bool {
        transportScrolledAway && currentChant != nil
    }

    private var miniTransportButton: some View {
        Button {
            if ownsAudio { audioClaim?.togglePlayback() } else { loadAudioIfAvailable(thenPlay: true) }
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: 30, height: 30)

                AppIcon(audioClaim?.isPlaying == true ? "ph-pause-fill" : "ph-play-fill", size: 11)
                    .foregroundColor(AppColors.background)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(audioClaim?.isPlaying == true ? "Pause the chant" : "Play the chant")
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 34)
                        .id("top")

                    switch currentStep {
                    case .reading(let index):
                        readingStep(reading(at: index))
                    case .prayer:
                        if let prayer = currentPrayer {
                            prayerStep(prayer)
                        }
                    }

                    // Room to scroll clear of the controls
                    Spacer()
                        .frame(height: 120)
                }
                .id(stepIndex)
                .transition(.opacity)
            }
            .coordinateSpace(name: "dayFlow")
            .onChange(of: stepIndex) {
                proxy.scrollTo("top", anchor: .top)
                transportScrolledAway = false
            }
            .onPreferenceChange(TransportOffsetKey.self) { maxY in
                // maxY is measured from the top of the visible scroll
                // area, so a negative value means the transport has gone
                // above it. The threshold is the transport's own height,
                // so the button arrives as the bar leaves rather than
                // after a gap of nothing.
                let away = maxY < 0
                guard away != transportScrolledAway else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    transportScrolledAway = away
                }
            }
        }
        .mask(readingFade)
    }

    // MARK: - Reading Step

    /// One reading, under the day's own frame. A day that opens on Luke
    /// and closes on Montfort is two texts, so each gets its own step and
    /// stands under its own citation — the reader is never left guessing
    /// which work the words in front of them belong to.
    @ViewBuilder
    private func readingStep(_ reading: ConsecrationReading?) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text((phase?.subtitle ?? "").uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(3)
                    .foregroundColor(AppColors.gold)
                    .multilineTextAlignment(.center)

                Text(day?.title ?? "")
                    .font(AppFonts.headlineFont(25))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 26)

            OrnamentDivider(showsCross: false)
                .frame(width: 150)
                .padding(.vertical, 24)

            if let reading {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reading.title.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)

                    if let source = reading.source {
                        Text(source)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
                .padding(.bottom, 14)

                ReadingText(
                    text: reading.text,
                    size: settings.meditationFontSize,
                    showsDropCap: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
            }
        }
    }

    // MARK: - Prayer Step

    private func prayerStep(_ prayer: ConsecrationPrayer) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Latin title — skipped when it IS the main title (Latin
                // display modes), which would only duplicate it
                if let latinTitle = prayer.latinTitle,
                   latinTitle.caseInsensitiveCompare(prayer.title) != .orderedSame {
                    Text(latinTitle.uppercased())
                        .font(AppFonts.labelFont(11))
                        .tracking(3)
                        .foregroundColor(AppColors.gold)
                }

                Text(prayer.title)
                    .font(AppFonts.headlineFont(26))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            OrnamentDivider(showsCross: false)
                .frame(width: 150)
                .padding(.vertical, 24)

            if let chant = chant(for: prayer) {
                audioPlayer(chant)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    // Reports where the transport is, so the header can
                    // pick the chant up once it scrolls off the page
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: TransportOffsetKey.self,
                                value: proxy.frame(in: .named("dayFlow")).maxY
                            )
                        }
                    )
            }

            // Every prayer reads down the left edge, whatever the display
            // language. Centering single-language text put the same
            // prayer on two designs depending on a setting — and centered
            // prose, which most of these are, is the harder to read.
            // The prose prayers open on a versal, like the reading after
            // them; the hymns and litanies have their own shapes.
            PrayerText(
                content: prayer.content,
                size: settings.meditationFontSize,
                alignment: .leading,
                showsDropCap: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
        }
    }

    /// The page dissolves at both ends rather than cutting against the
    /// chrome.
    private var readingFade: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)

            Rectangle()
                .fill(Color.black)

            LinearGradient(
                colors: [.black, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        }
    }

    // MARK: - Navigation

    /// Two bare controls separated only by brightness, exactly as the
    /// Rosary flow carries them — and AMEN given a form of its own, so
    /// the single gold shape on screen is the act that closes the day.
    private var navigationButtons: some View {
        HStack {
            QuietGoldButton(
                title: "Back",
                leadingIcon: "ph-arrow-left",
                leadingIconSize: 11
            ) {
                goToStep(stepIndex - 1)
            }
            // Nothing to go back to on the first prayer: the control
            // leaves rather than sitting there greyed out
            .disabled(isFirstStep)
            .opacity(isFirstStep ? 0 : 1)
            .accessibilityHidden(isFirstStep)
            .accessibilityLabel("Previous step")

            Spacer()

            if isLastStep {
                GoldCTAButton(
                    title: "Amen",
                    prominence: .inline,
                    trailingIcon: "ph-check",
                    fullWidth: false
                ) {
                    openReflection()
                }
                .accessibilityLabel("Amen — close the day and reflect")
            } else {
                QuietGoldButton(
                    title: forwardTitle,
                    trailingIcon: "ph-arrow-right",
                    trailingIconSize: 11,
                    color: AppColors.gold
                ) {
                    goToStep(stepIndex + 1)
                }
                .accessibilityLabel(isLastPrayerStep ? "Go to the reading" : "Next")
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - TransportOffsetKey

/// Where the chant transport sits relative to the top of the page.
nonisolated private struct TransportOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat { .greatestFiniteMagnitude }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

// MARK: - ChantTransportBar

/// The chant transport: a struck rectangle carrying one gold act, the
/// line the chant is on, and the two times.
///
/// A rectangle rather than the Rosary's 74pt ring, because a
/// consecration prayer is read down the page while the chant runs
/// underneath it — the transport is a rule across the page, not a
/// centrepiece. It keeps the page's own language: background ground,
/// gold hairline, tracked label type, and the single filled gold circle
/// the app gives to a play control.
///
/// It reads the shared player only through what the day hands it, and
/// the day hands it the player's state only while the player is sounding
/// the day's own chant (`isReady`).
private struct ChantTransportBar: View {

    let isPlaying: Bool
    let isLoading: Bool
    let currentTime: Double
    let duration: Double
    let errorMessage: String?
    let isReady: Bool
    let onToggle: () -> Void
    let onSeek: (Double) -> Void

    /// Where the thumb is while a drag is in progress, so the playhead
    /// doesn't fight the time observer under the user's finger
    @State private var scrubbing: Double?

    private var canScrub: Bool { isReady && duration > 0 && errorMessage == nil }

    private var displayedTime: Double {
        scrubbing ?? currentTime
    }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(displayedTime / duration, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                playButton

                VStack(spacing: 6) {
                    scrubber

                    HStack {
                        Text(Self.time(displayedTime))
                        Spacer()
                        Text(Self.time(duration))
                    }
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.background.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: AppLine.hairline)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// A gold hairline with a small gold knob. The system `Slider` puts
    /// a large white capsule on the page — the one foreign shape in the
    /// whole flow — and its thumb can't be restyled.
    private var scrubber: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let knob: CGFloat = 11

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.cream.opacity(0.14))
                    .frame(height: 3)

                Capsule()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: max(width * progress, 3), height: 3)

                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: knob, height: knob)
                    .offset(x: (width - knob) * progress)
                    .opacity(canScrub ? 1 : 0.4)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard canScrub else { return }
                        let fraction = min(max(value.location.x / width, 0), 1)
                        scrubbing = fraction * duration
                    }
                    .onEnded { _ in
                        if let target = scrubbing { onSeek(target) }
                        scrubbing = nil
                    }
            )
        }
        .frame(height: 20)
        .accessibilityElement()
        .accessibilityLabel("Chant position")
        .accessibilityValue("\(Self.time(displayedTime)) of \(Self.time(duration))")
        .accessibilityAdjustableAction { direction in
            guard canScrub else { return }
            let step = 15.0
            switch direction {
            case .increment: onSeek(min(duration, currentTime + step))
            case .decrement: onSeek(max(0, currentTime - step))
            @unknown default: break
            }
        }
    }

    private var playButton: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: 38, height: 38)

                if isLoading {
                    SwiftUI.ProgressView()
                        .controlSize(.small)
                        .tint(AppColors.background)
                } else {
                    AppIcon(isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 14)
                        .foregroundColor(AppColors.background)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Loading the chant" : (isPlaying ? "Pause the chant" : "Play the chant"))
    }

    private static func time(_ seconds: Double) -> String {
        guard seconds > 0, !seconds.isNaN, !seconds.isInfinite else { return "0:00" }
        let whole = Int(seconds)
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationDayFlowView(path: .constant([]), dayNumber: 1)
            .environment(ConsecrationViewModel())
            .environment(UserSettings.shared)
    }
}
