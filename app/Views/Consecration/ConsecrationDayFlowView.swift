//
//  ConsecrationDayFlowView.swift
//  Lumen Viae
//
//  The day itself: the reading, then each of its prayers, as one screen
//  you move through rather than a chain of screens that push each other.
//
//  The Consecrate dashboard lets you enter anywhere — the hero opens the
//  reading, a prayer row opens that prayer — so this is built to be
//  entered anywhere and to walk in both directions from there. Swipe or
//  use PREV/NEXT; the dots say where you are in the day. AMEN, on the
//  last prayer, carries the day into its reflection.
//
//  The reading used to be a full-screen cover owned by the dashboard,
//  which meant continuing from it dismissed the cover, showed the
//  dashboard for a beat, and only then pushed the prayers. Making it the
//  first step here removes that flash entirely.
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
        startStep: ConsecrationDayStep = .reading
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
    @State private var cachedAudioUrls: [String: String] = [:]

    /// The day's index — every step of the day, reachable from any of them
    @State private var showDayIndex = false

    /// True once the chant's transport has scrolled above the page, so
    /// the header can carry a small play control in its place
    @State private var transportScrolledAway = false

    /// A chant that could not be fetched. The transport says so rather
    /// than sitting there dead — the prayer is still there to pray.
    @State private var audioError: String?

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

    /// The reading, then every prayer of the day
    private var steps: [ConsecrationDayStep] {
        [.reading] + prayers.indices.map { ConsecrationDayStep.prayer($0) }
    }

    private var currentStep: ConsecrationDayStep {
        guard stepIndex >= 0, stepIndex < steps.count else { return .reading }
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
    /// prayers; leaving the reading is better named by where it goes.
    private var forwardTitle: String {
        currentStep == .reading ? "Prayers" : "Next"
    }

    private var accessibleStepName: String {
        switch currentStep {
        case .reading: return "the reading"
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
            // environment — so it happens here rather than in init. It
            // runs once: popping back from the reflection must return to
            // the prayer the user left, not to the step they entered on.
            if let pending = pendingStart {
                stepIndex = steps.firstIndex(of: pending) ?? 0
                pendingStart = nil
            }
            loadAudioIfAvailable()
        }
        .onDisappear {
            audio.reset()
            // Hand the audio session back so other apps' audio can resume
            audio.deactivateSession()
        }
        .onChange(of: stepIndex) {
            audio.reset()
            audioError = nil
            loadAudioIfAvailable()
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
        case .reading:
            goToStep(0)
        case .prayer(let index):
            goToStep(index + 1)
        case .reflection:
            path.append(.journal(dayNumber: dayNumber))
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
    /// on the last prayer does nothing — the day is carried into its
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

    private func loadAudioIfAvailable() {
        guard let prayer = currentPrayer, prayer.hasAudio else { return }
        Task {
            // A downloaded chant plays offline and skips the presign hop
            if let local = OfflineContentService.shared.localPrayerAudioURL(prayerId: prayer.id) {
                await audio.loadAudio(
                    from: local.absoluteString,
                    title: prayer.title,
                    subtitle: "33-Day Consecration"
                )
                return
            }

            do {
                let presignedUrl: String
                if let cached = cachedAudioUrls[prayer.id] {
                    presignedUrl = cached
                } else {
                    presignedUrl = try await APIService.shared.fetchPrayerAudioUrl(prayerId: prayer.id)
                    cachedAudioUrls[prayer.id] = presignedUrl
                }
                await audio.loadAudio(
                    from: presignedUrl,
                    title: prayer.title,
                    subtitle: "33-Day Consecration"
                )
            } catch {
                // The prayer reads perfectly well without the chant — say
                // so once, quietly, rather than leaving a dead transport.
                audioError = "The chant couldn't be loaded. The prayer is here to pray."
            }
        }
    }

    private var audioPlayer: some View {
        ChantTransportBar(
            isPlaying: audio.isPlaying,
            isLoading: audio.isLoading,
            currentTime: audio.currentTime,
            duration: audio.duration,
            errorMessage: audioError ?? audio.errorMessage,
            onToggle: { audio.togglePlayback() },
            onSeek: { audio.seek(to: $0) }
        )
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
        transportScrolledAway && currentPrayer?.hasAudio == true
    }

    private var miniTransportButton: some View {
        Button {
            audio.togglePlayback()
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: 30, height: 30)

                AppIcon(audio.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 11)
                    .foregroundColor(AppColors.background)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(audio.isPlaying ? "Pause the chant" : "Play the chant")
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
                    case .reading:
                        readingStep
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

    private var readingStep: some View {
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

            ReadingText(
                text: day?.meditationText ?? "",
                size: settings.meditationFontSize,
                showsDropCap: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)

            if let source = day?.meditationSource {
                VStack(spacing: 14) {
                    OrnamentDivider()
                        .frame(width: 180)

                    Text(source)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
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

            if prayer.hasAudio {
                audioPlayer
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
            PrayerText(
                content: prayer.content,
                size: settings.meditationFontSize,
                alignment: .leading
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
    /// the single gold shape on screen is the act that finishes the day's
    /// prayers.
    private var navigationButtons: some View {
        HStack {
            QuietGoldButton(
                title: "Prev",
                leadingIcon: "ph-arrow-left",
                leadingIconSize: 11
            ) {
                goToStep(stepIndex - 1)
            }
            // Nothing to go back to on the reading: the control leaves
            // rather than sitting there greyed out
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
                    path.append(.journal(dayNumber: dayNumber))
                }
                .accessibilityLabel("Amen — finish the prayers and reflect")
            } else {
                QuietGoldButton(
                    title: forwardTitle,
                    trailingIcon: "ph-arrow-right",
                    trailingIconSize: 11,
                    color: AppColors.gold
                ) {
                    goToStep(stepIndex + 1)
                }
                .accessibilityLabel(currentStep == .reading ? "Go to the prayers" : "Next prayer")
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
private struct ChantTransportBar: View {

    let isPlaying: Bool
    let isLoading: Bool
    let currentTime: Double
    let duration: Double
    let errorMessage: String?
    let onToggle: () -> Void
    let onSeek: (Double) -> Void

    /// Where the thumb is while a drag is in progress, so the playhead
    /// doesn't fight the time observer under the user's finger
    @State private var scrubbing: Double?

    private var isReady: Bool { duration > 0 && errorMessage == nil }

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
                    .strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
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
                    .opacity(isReady ? 1 : 0.4)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isReady else { return }
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
            guard isReady else { return }
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
