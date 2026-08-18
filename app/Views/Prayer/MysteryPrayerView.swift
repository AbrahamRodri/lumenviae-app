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
//
//  Navigation is gesture-first: swiping left/right moves between
//  mysteries in both modes, tapping the artwork clears the chrome for
//  undistracted contemplation, and the one persistent button is the
//  quiet NEXT — which becomes the explicit AMEN on the last mystery.
//  Completing the Rosary is always a deliberate tap, never a swipe.
//

import SwiftUI

struct MysteryPrayerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var userSettings
    @State private var viewModel: PrayerSessionViewModel
    @State private var showingJournalEditor = false

    /// Image mode: true while a tap on the artwork has cleared the chrome
    @State private var chromeHidden = false

    /// Reading-mode scroll and follow-along bookkeeping
    @State private var reader = ReaderScrollModel()

    /// Measured height of the floating transport, so the reading page
    /// reserves the room the controls actually take — which is roughly
    /// half as much when the meditation carries no narration
    @State private var bottomChromeHeight: CGFloat = 0

    /// The fade the reading text scrolls up into, above the transport
    private static let transportFadeHeight: CGFloat = 130

    /// Room the reading page leaves for the floating header (buttons and
    /// bead strand, both fixed-size)
    private static let readerHeaderInset: CGFloat = 128

    let meditationSet: MeditationSet

    /// When the devotion originally began (carried through resumes for
    /// snapshot continuity; never used for duration)
    private let sessionStartedAt: Date

    /// Image vs. reading mode, persisted so the preference survives sessions
    private var isImageMode: Bool { userSettings.prayerImageMode }

    init(launch: PrayerLaunch) {
        self.meditationSet = launch.meditationSet
        self.sessionStartedAt = launch.startedAt
        self._viewModel = State(initialValue: PrayerSessionViewModel(
            meditationSet: launch.meditationSet,
            startAtIndex: launch.startIndex,
            priorSeconds: launch.priorSeconds
        ))
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
        .simultaneousGesture(mysterySwipeGesture)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.currentMysteryIndex)
        .task(id: viewModel.currentMysteryIndex) {
            saveResumePosition(at: viewModel.currentMysteryIndex)
            // The Lock Screen and AirPods move the mystery while this view
            // is not re-evaluating, so those moves report back here instead
            // of relying on the task re-running.
            //
            // Captures value copies and a weak view model rather than the
            // View: capturing `self` here would retain the struct, whose
            // @State box holds the view model that owns this closure.
            viewModel.onMysteryChanged = { [weak viewModel, meditationSet, sessionStartedAt] index in
                guard index > 0, let viewModel else { return }
                PrayerResumeService.shared.save(
                    setId: meditationSet.id,
                    setName: meditationSet.name,
                    category: meditationSet.category,
                    mysteryIndex: index,
                    startedAt: sessionStartedAt,
                    accumulatedSeconds: viewModel.sessionDuration
                )
            }
            await viewModel.loadCurrentAudio()
        }
        .onChange(of: viewModel.currentMysteryIndex) {
            // A fresh mystery starts with fresh reading state
            reader.reset()
        }
        .onChange(of: isImageMode) {
            chromeHidden = false
            reader.reset()
        }
        .onDisappear {
            // Leaving the prayer flow (close, completion, or back) must not
            // leave meditation audio playing over other screens.
            viewModel.stopAudio()
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

    // MARK: - Gestures

    /// Horizontal swipe moves between mysteries in both modes. The angle
    /// gate keeps vertical reading scrolls from ever counting, and a
    /// forward swipe on the last mystery does nothing — the Rosary is
    /// completed only by the explicit AMEN tap.
    ///
    /// A gesture is a shortcut, never the only way: every move it makes
    /// is also a button, since VoiceOver and Switch Control cannot
    /// deliver a drag.
    private var mysterySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }

                if dx < 0 {
                    guard !viewModel.isLastMystery else { return }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        _ = viewModel.nextMystery()
                    }
                } else {
                    // A drag begun on the left bezel is the navigation
                    // stack's interactive pop. Stepping back a mystery on
                    // the way out of the flow resets audio mid-transition
                    // and lands the user somewhere they didn't ask for.
                    guard value.startLocation.x > 40 else { return }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        viewModel.previousMystery()
                    }
                }
            }
    }

    // MARK: - Image View Mode

    private var imageViewMode: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                AppColors.background
                    .ignoresSafeArea()

                // Artwork with a frosted foot, tapped to clear the chrome
                artworkLayer(geometry)

                // Scrim so the title and controls stay legible over art
                scrimOverlay(geometry)

                // Content overlay — hidden entirely while contemplating
                VStack(spacing: 0) {
                    imageViewHeader
                        .padding(.top, 8)

                    Spacer()

                    if let meditation = viewModel.currentMeditation {
                        imageViewBottomCard(meditation: meditation)
                    }
                }
                .opacity(chromeHidden ? 0 : 1)
                .allowsHitTesting(!chromeHidden)
            }
        }
    }

    /// The mystery's artwork, pulled low on the screen. Its lower band is
    /// the artwork itself blurred — a frosted transition into the controls
    /// instead of a hard dark gradient — so more of the painting survives.
    /// With the chrome tapped away the painting takes the whole screen.
    private func artworkLayer(_ geometry: GeometryProxy) -> some View {
        // The frost keeps the chrome-up height in both states. It is only
        // ever visible with the chrome up, and animating its geometry
        // would re-blur two full-screen copies on every frame of the tap.
        let seatedHeight = geometry.size.height * 0.92
        let artHeight = chromeHidden ? geometry.size.height : seatedHeight

        return VStack(spacing: 0) {
            Group {
                if let assetName = Constants.mysteryImageURL(
                    category: meditationSet.category,
                    index: viewModel.currentMysteryIndex
                ) {
                    mysteryArtwork(
                        assetName,
                        width: geometry.size.width,
                        height: artHeight,
                        frostHeight: seatedHeight
                    )
                } else {
                    Rectangle()
                        .fill(AppColors.cardBackground)
                        .frame(height: artHeight)
                }
            }
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
        .id(viewModel.currentMysteryIndex)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentMysteryIndex)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.35)) {
                chromeHidden.toggle()
            }
        }
    }

    private func mysteryArtwork(
        _ assetName: String,
        width: CGFloat,
        height: CGFloat,
        frostHeight: CGFloat
    ) -> some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            // Seats the art on the background so it never ends on a hard
            // line: a fade to the background color right at the image's
            // foot, under the frost. Compact in contemplation — the art
            // should feel full-bleed, just not edge-cut.
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: chromeHidden ? 0.88 : 0.80),
                        .init(color: AppColors.background, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
            .overlay(
                // Two staggered blur layers fake a progressive blur: the
                // soft pass eases the sharp painting into the frost, the
                // strong pass deepens below it — no visible seam where
                // the blurring begins. Clipped so blur can't bleed past
                // the artwork's edges.
                //
                // The frost is the painting itself and not a material:
                // a material blurs the backdrop through a gray system
                // tint, which drains the color the paintings carry —
                // the deep blues in particular come back gray.
                ZStack {
                    blurLayer(assetName, width: width, height: frostHeight,
                              radius: 8, from: 0.55, to: 0.78)
                    blurLayer(assetName, width: width, height: frostHeight,
                              radius: 20, from: 0.70, to: 0.88)
                }
                .frame(width: width, height: frostHeight)
                // The frost exists to seat the title and controls; with the
                // chrome tapped away it has nothing to seat, so it lifts and
                // the painting shows sharp edge to edge.
                .opacity(chromeHidden ? 0 : 1)
                .allowsHitTesting(false),
                alignment: .top
            )
            .clipped()
    }

    private func blurLayer(
        _ assetName: String,
        width: CGFloat,
        height: CGFloat,
        radius: CGFloat,
        from: CGFloat,
        to: CGFloat
    ) -> some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .blur(radius: radius)
            .mask(
                // The frost tapers back out at the very foot — the blurred
                // copy would otherwise re-cut the same hard edge the
                // background fade underneath exists to remove.
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: from),
                        .init(color: .black, location: to),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    /// Lighter than the old hard fade — the frosted band underneath does
    /// half the legibility work, so more painting shows through.
    private func scrimOverlay(_ geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: geometry.size.height * 0.58)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.background.opacity(0.45), location: 0.45),
                    .init(color: AppColors.background.opacity(0.9), location: 0.78),
                    .init(color: AppColors.background, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .drawingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
        // Contemplation lifts the veil: most of the scrim goes with the
        // chrome, leaving only enough to keep the status bar readable
        .opacity(chromeHidden ? 0.3 : 1)
    }

    /// Close on the left, mode/journal on the right, and the decade's
    /// bead strand fixed in the center — the same anchor it has in
    /// reading mode, so switching modes doesn't rearrange the room.
    private var imageViewHeader: some View {
        ZStack {
            RosaryBeadProgress(
                total: viewModel.totalMysteries,
                completed: viewModel.currentMysteryIndex,
                activeIndex: viewModel.currentMysteryIndex,
                beadSize: 8
            )
            .frame(width: 150)

            HStack {
                PrayerHeaderButton(icon: "ph-x", size: 18, label: "End prayer") {
                    router.popToRoot()
                }

                Spacer()

                PrayerHeaderButton(icon: "ph-text-align-left", label: "Reading mode") {
                    withAnimation(.easeInOut(duration: 0.3)) { userSettings.prayerImageMode.toggle() }
                }

                PrayerHeaderButton(icon: "ph-note-pencil", label: "Add journal note") {
                    showingJournalEditor = true
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func imageViewBottomCard(meditation: Meditation) -> some View {
        VStack(spacing: 14) {
            // Mystery info — the title zone reserves two lines so one-line
            // titles don't shove everything else around between mysteries
            VStack(spacing: 7) {
                Text("THE \(Constants.ordinalWord(viewModel.currentMysteryIndex + 1).uppercased()) \(meditationSet.mysteryCategory?.displayName.uppercased() ?? "") MYSTERY")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                Text(meditation.displayTitle)
                    .font(AppFonts.headlineFont(25))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .frame(minHeight: 60)

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

            // Audio controls — a wider breath after the title cluster, which
            // itself sits tight (kicker, title, and verse read as one unit)
            if viewModel.currentMeditation?.hasAudio == true {
                AudioControlsView(
                    isPlaying: $viewModel.isPlaying,
                    currentTime: $viewModel.currentTime,
                    totalTime: viewModel.totalDuration,
                    isLoading: viewModel.isLoadingAudio,
                    errorMessage: viewModel.audioErrorMessage
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            // Navigation
            navigationButtons
                .padding(.bottom, 14)
        }
    }

    // MARK: - Text View Mode

    private var textViewMode: some View {
        ZStack {
            // Background gradient
            AppColors.appGradient
                .ignoresSafeArea()

            if let meditation = viewModel.currentMeditation {
                readerScroll(meditation)
            } else {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                    Spacer()
                }
            }

            // Fixed top chrome: full header, or the compact bar once
            // reading is underway
            VStack(spacing: 0) {
                readerTopChrome
                Spacer()
            }

            // Fixed bottom section - floating over content with gradient fade
            VStack(spacing: 0) {
                Spacer()

                // Taller fade plus a beat of solid ground before the play
                // button — the last legible line ends clear of the transport
                LinearGradient(
                    colors: [.clear, AppColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Self.transportFadeHeight)
                .allowsHitTesting(false)

                VStack(spacing: 12) {
                    if viewModel.currentMeditation?.hasAudio == true {
                        AudioControlsView(
                            isPlaying: $viewModel.isPlaying,
                            currentTime: $viewModel.currentTime,
                            totalTime: viewModel.totalDuration,
                            isLoading: viewModel.isLoadingAudio,
                            errorMessage: viewModel.audioErrorMessage
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    navigationButtons
                        .padding(.bottom, 8)
                }
                .background(AppColors.background)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: BottomChromeHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
            }
        }
        .onPreferenceChange(BottomChromeHeightKey.self) { height in
            bottomChromeHeight = height
        }
    }

    /// The meditation itself. The title block scrolls away with the text —
    /// once you're reading, only the compact bar and the transport remain —
    /// and while narration plays, the text follows along paragraph by
    /// paragraph.
    private func readerScroll(_ meditation: Meditation) -> some View {
        let paragraphs = ReadingText.paragraphs(of: meditation.content)
        let fontSize = userSettings.meditationFontSize

        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Title block — part of the page, not the chrome
                    MysteryInfoSection(
                        mysteryType: meditationSet.mysteryCategory?.displayName ?? "",
                        mysteryNumber: viewModel.currentMysteryIndex + 1,
                        mysteryTitle: meditation.displayTitle
                    )
                    // Clears the full floating header (buttons + beads)
                    .padding(.top, Self.readerHeaderInset)

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

                    // Paragraph-indexed so follow-along can address them
                    VStack(
                        alignment: .leading,
                        spacing: ReadingTypography.paragraphSpacing(for: fontSize)
                    ) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                            ReadingText(
                                text: paragraph,
                                size: fontSize,
                                showsDropCap: index == 0,
                                textColor: AppColors.cream.opacity(0.92)
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("para-\(index)")
                        }
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 16)
                }
                // Extra padding so content can scroll behind controls
                .padding(.bottom, bottomChromeHeight + Self.transportFadeHeight)
                .id(viewModel.currentMysteryIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentMysteryIndex)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ReaderScrollOffsetKey.self,
                            value: geo.frame(in: .named("reader")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "reader")
            .mask(readerFadeMask)
            .onPreferenceChange(ReaderScrollOffsetKey.self) { offset in
                reader.handleScroll(to: offset)
            }
            .overlay(alignment: .top) {
                NarrationFollow(
                    viewModel: viewModel,
                    reader: reader,
                    paragraphCount: paragraphs.count,
                    proxy: proxy
                )
            }
        }
    }

    /// Text dissolves as it rises toward the chrome instead of sliding
    /// behind a backdrop: gone at the very top, a ghost under the bead
    /// strand, fully legible a beat below it. The page background stays
    /// continuous, so there is no slab.
    ///
    /// The band tracks the chrome it exists to clear. Holding the full
    /// header's depth under the 52pt compact bar would erase three or
    /// four lines the reader is still on, in the very mode the collapse
    /// exists to give room to.
    private var readerFadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.08), location: 0.7),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: reader.collapsed ? 86 : 190)
            Rectangle().fill(.black)
        }
        .ignoresSafeArea(edges: .top)
    }

    @ViewBuilder
    private var readerTopChrome: some View {
        if reader.collapsed {
            // Compact bar: the way out, and where you are — nothing else
            ZStack {
                Text(viewModel.currentMeditation?.displayTitle.uppercased() ?? "")
                    .font(AppFonts.labelFont(11))
                    .tracking(2)
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 64)

                HStack {
                    PrayerHeaderButton(icon: "ph-x", size: 14, label: "End prayer") {
                        router.popToRoot()
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 52)
            .background(AppColors.background.opacity(0.94))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(height: 0.5)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            // No backdrop at all — any bounded slab reads as a blob over
            // the page. The chrome floats free; the fade mask on the
            // reader itself (readerScroll) dissolves the text before it
            // can rise behind these controls.
            VStack(spacing: 14) {
                HStack {
                    PrayerHeaderButton(icon: "ph-x", size: 18, label: "End prayer") {
                        router.popToRoot()
                    }

                    Spacer()

                    PrayerHeaderButton(icon: "ph-image", label: "Image mode") {
                        withAnimation(.easeInOut(duration: 0.3)) { userSettings.prayerImageMode.toggle() }
                    }

                    PrayerHeaderButton(icon: "ph-note-pencil", label: "Add journal note") {
                        showingJournalEditor = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                RosaryBeadProgress(
                    total: viewModel.totalMysteries,
                    completed: viewModel.currentMysteryIndex,
                    activeIndex: viewModel.currentMysteryIndex,
                    beadSize: 8
                )
                .frame(width: 170)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Shared Components

    /// Two bare controls, separated only by brightness: a quiet way back,
    /// and NEXT as a whisper. No capsule on either — nothing here should
    /// compete with the painting or the page. Only AMEN is given a form
    /// of its own, so the single gold shape on screen is the act that
    /// completes the Rosary.
    ///
    /// Swiping does the same, but a swipe cannot be the only way back —
    /// VoiceOver and Switch Control never deliver the drag, and there is
    /// no other route to a decade already passed.
    private var navigationButtons: some View {
        HStack {
            QuietGoldButton(
                title: "Prev",
                leadingIcon: "ph-arrow-left",
                leadingIconSize: 11
            ) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.previousMystery()
                }
            }
            // Nothing to go back to on the first mystery: the control
            // leaves rather than sitting there greyed out
            .disabled(viewModel.isFirstMystery)
            .opacity(viewModel.isFirstMystery ? 0 : 1)
            .accessibilityHidden(viewModel.isFirstMystery)
            .accessibilityLabel("Previous mystery")

            Spacer()

            if viewModel.isLastMystery {
                GoldCTAButton(
                    title: "Amen",
                    prominence: .inline,
                    trailingIcon: "ph-check",
                    fullWidth: false,
                    action: handleNextMystery
                )
                .accessibilityLabel("Amen — finish the Rosary")
            } else {
                QuietGoldButton(
                    title: "Next",
                    trailingIcon: "ph-arrow-right",
                    trailingIconSize: 11,
                    color: AppColors.gold,
                    action: handleNextMystery
                )
                .accessibilityLabel("Next mystery")
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Functions

    /// Remembers the position so an interrupted Rosary can resume.
    /// Only once the user has actually advanced — glancing at a set's first
    /// mystery and backing out must neither pin a resume card nor overwrite
    /// a genuinely interrupted session.
    private func saveResumePosition(at index: Int) {
        guard index > 0 else { return }
        PrayerResumeService.shared.save(
            setId: meditationSet.id,
            setName: meditationSet.name,
            category: meditationSet.category,
            mysteryIndex: index,
            startedAt: sessionStartedAt,
            accumulatedSeconds: viewModel.sessionDuration
        )
    }

    private func handleNextMystery() {
        let advanced = withAnimation(.easeInOut(duration: 0.4)) {
            viewModel.nextMystery()
        }
        guard !advanced else { return }

        // Completed all mysteries - navigate to completion
        PrayerResumeService.shared.clear()
        Task {
            try? await viewModel.recordCompletion()
        }
        router.navigateToCompletion(durationSeconds: viewModel.sessionDuration)
    }
}

// MARK: - ReaderScrollOffsetKey

/// Scroll offset of the reading content, for collapse-on-scroll.
nonisolated private struct ReaderScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - BottomChromeHeightKey

/// Measured height of the floating transport, so the reading page can
/// reserve what the controls occupy instead of a constant guessed for
/// the audio-present case.
nonisolated private struct BottomChromeHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - ReaderScrollModel

/// Reading-mode bookkeeping: whether the chrome has collapsed, and how
/// far the narration has carried the page.
///
/// A model rather than view state because the scroll offset arrives on
/// every frame of every scroll. As `@State` each of those writes
/// invalidated the whole prayer page — re-splitting the meditation and
/// rebuilding the reader — to move numbers nothing in the body reads.
/// Here only `collapsed` is observed, so only a real collapse redraws.
@Observable
final class ReaderScrollModel {

    /// True once reading has scrolled down far enough that the full
    /// header gives way to the compact bar (Hallow-style)
    var collapsed = false

    /// Last seen scroll offset, for scroll-direction detection
    @ObservationIgnored private var lastOffset: CGFloat = 0

    /// When the reader last moved the text themselves — follow-along
    /// stands aside for a few seconds after any manual scroll
    @ObservationIgnored private var lastManualScrollAt = Date.distantPast

    /// When follow-along last drove the scroll, so its own animated
    /// movement is never mistaken for the reader's hand
    @ObservationIgnored private var lastAutoScrollAt = Date.distantPast

    /// The paragraph follow-along last scrolled to
    @ObservationIgnored private var followTarget = 0

    /// The next offset report comes from a rebuilt page rather than the
    /// reader's hand: adopt it as the baseline instead of measuring the
    /// snap back to the top against the mystery just left — that jump
    /// reads as a manual scroll and mutes follow-along for four seconds
    /// at the start of every new decade.
    @ObservationIgnored private var needsBaseline = true

    /// A fresh mystery starts with fresh reading state.
    func reset() {
        collapsed = false
        lastOffset = 0
        lastManualScrollAt = .distantPast
        lastAutoScrollAt = .distantPast
        followTarget = 0
        needsBaseline = true
    }

    /// Collapse the chrome when scrolling down into the text; bring it
    /// back the moment the reader scrolls up, wherever they are. Any
    /// movement not caused by a recent follow-along animation counts as
    /// the reader's own scroll and pauses following.
    func handleScroll(to offset: CGFloat) {
        if needsBaseline {
            needsBaseline = false
            lastOffset = offset
            return
        }

        defer { lastOffset = offset }
        let delta = offset - lastOffset

        if abs(delta) > 2, Date().timeIntervalSince(lastAutoScrollAt) > 1.5 {
            lastManualScrollAt = Date()
        }

        if offset >= -40 || delta > 6 {
            if collapsed {
                withAnimation(.easeInOut(duration: 0.25)) { collapsed = false }
            }
        } else if delta < -6 {
            if !collapsed {
                withAnimation(.easeInOut(duration: 0.25)) { collapsed = true }
            }
        }
    }

    /// The paragraph the narration has reached, or nil when following
    /// should stand aside — the reader scrolled recently, or the page is
    /// already there.
    func paragraphToFollow(fraction: Double, paragraphCount: Int) -> Int? {
        guard paragraphCount > 0,
              Date().timeIntervalSince(lastManualScrollAt) > 4 else { return nil }

        let target = min(paragraphCount - 1, Int(fraction * Double(paragraphCount)))
        guard target != followTarget else { return nil }

        followTarget = target
        lastAutoScrollAt = Date()
        return target
    }
}

// MARK: - NarrationFollow

/// Keeps the visible paragraph in step with the narration. Without
/// per-word timings the mapping is proportional — paragraph N of M at
/// N/M of the audio — which tracks spoken pace closely enough.
///
/// It reads `currentTime` in its own body on purpose. Observed from the
/// prayer view, the twice-a-second time observer made the whole reading
/// page a dependency of the clock; here the tick invalidates a
/// zero-size view and nothing else.
private struct NarrationFollow: View {

    let viewModel: PrayerSessionViewModel
    let reader: ReaderScrollModel
    let paragraphCount: Int
    let proxy: ScrollViewProxy

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: viewModel.currentTime) { _, time in
                guard viewModel.isPlaying, viewModel.totalDuration > 0 else { return }

                let fraction = min(max(time / viewModel.totalDuration, 0), 1)
                guard let target = reader.paragraphToFollow(
                    fraction: fraction,
                    paragraphCount: paragraphCount
                ) else { return }

                withAnimation(.easeInOut(duration: 1.2)) {
                    proxy.scrollTo("para-\(target)", anchor: UnitPoint(x: 0.5, y: 0.3))
                }
            }
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
                .padding(13)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
                // Keep the hit area at the 44pt minimum even for small glyphs
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
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

    var body: some View {
        VStack(spacing: 10) {
            // Category label
            Text("THE \(Constants.ordinalWord(mysteryNumber).uppercased()) \(mysteryType.uppercased()) MYSTERY")
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

/// The narration transport: back 10, play/pause ringed by progress,
/// forward 10. No scrubber — the thin gold ring around the play button
/// is the whole story of where the narration stands, and the Lock
/// Screen scrubber covers the rare precise seek.
struct AudioControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    let totalTime: Double
    var isLoading: Bool = false
    var errorMessage: String? = nil

    /// Read directly so speed and the sleep timer stay in step with whatever
    /// the Lock Screen or CarPlay did to them while this screen was away.
    private var audio: AudioService { .shared }

    /// A message about a *recoverable* failure (the session was busy, the
    /// server reset) must not disable the button it tells the user to press.
    /// Readiness therefore depends on there being a track with a duration,
    /// not on the absence of a message.
    private var isReady: Bool { !isLoading && totalTime > 0 }

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return min(max(currentTime / totalTime, 0), 1)
    }

    /// The ring carries the position visually and there is no scrubber to
    /// read, so the play button speaks it and takes the adjust gesture —
    /// otherwise position is neither knowable nor settable under
    /// VoiceOver.
    private var positionDescription: String {
        guard isReady else { return "Not ready" }
        return "\(spoken(currentTime)) of \(spoken(totalTime))"
    }

    private func spoken(_ seconds: Double) -> String {
        // Int(Double.nan) traps — keep the guard local even though current
        // inputs are sanitized upstream in AudioService.
        guard seconds > 0, !seconds.isNaN, !seconds.isInfinite else { return "0 seconds" }
        let whole = Int(seconds)
        let mins = whole / 60
        let secs = whole % 60
        let minutes = "\(mins) minute\(mins == 1 ? "" : "s")"
        let sec = "\(secs) second\(secs == 1 ? "" : "s")"
        if mins == 0 { return sec }
        if secs == 0 { return minutes }
        return "\(minutes) \(sec)"
    }

    var body: some View {
        VStack(spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 44) {
                // Rewind 10s (SF symbol — it encodes the "10" glyph)
                Button(action: {
                    currentTime = max(0, currentTime - 10)
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                }
                .disabled(!isReady)
                .opacity(isReady ? 1 : 0.35)
                .accessibilityLabel("Back 10 seconds")

                // Play/Pause wrapped in the progress ring
                ZStack {
                    Circle()
                        .stroke(AppColors.gold.opacity(0.18), lineWidth: 2.5)
                        .frame(width: 74, height: 74)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppColors.goldLight,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 74, height: 74)
                        // The time observer ticks twice a second; a linear
                        // animation of the same length makes the ring sweep
                        // continuously instead of stepping
                        .animation(.linear(duration: 0.5), value: progress)

                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.goldGradient)
                                .frame(width: 60, height: 60)
                                .haloGlow(AppColors.gold, radius: 10, intensity: 0.4)

                            if isLoading {
                                ProgressView()
                                    .tint(AppColors.background)
                            } else {
                                // SF Symbols are optically centered as drawn
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(AppColors.background)
                            }
                        }
                    }
                    .buttonStyle(GoldCTAButtonStyle())
                    .disabled(!isReady)
                    .accessibilityLabel(isLoading ? "Loading audio" : (isPlaying ? "Pause" : "Play"))
                    .accessibilityValue(positionDescription)
                    .accessibilityHint(isReady ? "Swipe up or down to move through the narration" : "")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment:
                            currentTime = min(totalTime, currentTime + 15)
                        case .decrement:
                            currentTime = max(0, currentTime - 15)
                        @unknown default:
                            break
                        }
                    }
                }

                // Forward 10s (SF symbol — it encodes the "10" glyph)
                Button(action: {
                    currentTime = min(totalTime, currentTime + 10)
                }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                }
                .disabled(!isReady)
                .opacity(isReady ? 1 : 0.35)
                .accessibilityLabel("Forward 10 seconds")
            }

            secondaryControls
        }
    }

    /// Narration speed and the sleep timer.
    ///
    /// Deliberately quiet: gold is reserved for the finishing act, and on
    /// this screen that is the play button. These sit under it as plain
    /// labels so they are reachable without competing with the prayer.
    @ViewBuilder
    private var secondaryControls: some View {
        HStack(spacing: 28) {
            Button {
                let rates = AudioService.supportedRates
                let next = rates[((rates.firstIndex(of: audio.playbackRate) ?? 1) + 1) % rates.count]
                audio.setPlaybackRate(next)
            } label: {
                Text(rateLabel)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Narration speed")
            .accessibilityValue(rateLabel)
            .accessibilityHint("Cycles through available speeds")

            Button {
                if audio.sleepTimerIsActive {
                    audio.cancelSleepTimer()
                } else {
                    audio.stopAtEndOfCurrentTrack()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audio.sleepTimerIsActive ? "moon.fill" : "moon")
                        .font(.system(size: 13, weight: .light))
                    if audio.sleepTimerIsActive {
                        Text("Ends after this")
                            .font(AppFonts.bodyFont(13))
                    }
                }
                .foregroundColor(audio.sleepTimerIsActive ? AppColors.gold : AppColors.textSecondary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(audio.sleepTimerIsActive
                ? "Stop after this mystery, on. Double tap to keep praying."
                : "Stop after this mystery")
        }
        .opacity(isReady ? 1 : 0.35)
        .disabled(!isReady)
    }

    /// "1×" rather than "1.0×", but "1.25×" in full — %g drops trailing
    /// zeros without rounding away a significant digit.
    private var rateLabel: String {
        "\(String(format: "%g", audio.playbackRate))×"
    }
}


// MARK: - Preview

#Preview {
    MysteryPrayerView(
        launch: PrayerLaunch(
            meditationSet: MockDataService.meditationSet(for: .sorrowful, includeAudio: true)
        )
    )
    .environment(AppRouter())
    .environment(UserSettings.shared)
}
