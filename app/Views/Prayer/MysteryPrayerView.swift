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
//  The screen is a player: the mystery's artwork above, and beneath it
//  the name of what is playing, where it stands, and the controls. The
//  meditation text is not a mode this screen switches into — it opens
//  as a reader over the top (`MeditationReaderView`), so the narration
//  never stops to change surfaces and the way back is always the same
//  button.
//
//  Navigation is gesture-first: swiping left/right moves between
//  mysteries, tapping the artwork clears the chrome for undistracted
//  contemplation, and the arrows flanking the transport do the same
//  thing a swipe does. Completing the Rosary is always a deliberate
//  tap on AMEN, never a swipe.
//

import SwiftUI

struct MysteryPrayerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var userSettings
    @State private var viewModel: PrayerSessionViewModel
    /// The one sheet this screen presents at a time.
    @State private var activeSheet: PlayerSheet?

    /// An act the ⋯ tray asked for, run once the tray is actually gone.
    /// Sequenced on `onDismiss` rather than a timer: presenting into a
    /// dismissal drops the new presentation.
    @State private var pendingHandoff: (() -> Void)?

    /// Where the first-Rosary swipe hint stands. One value rather than a
    /// pair of booleans so "shown and already retired" cannot be reached:
    /// the hint's own timer, a move between mysteries, and a tap on the
    /// painting all race for it, and the race has to settle once.
    @State private var swipeHint: SwipeHintPhase = .pending

    enum SwipeHintPhase {
        /// Waiting for the screen to settle
        case pending
        /// On screen
        case showing
        /// Had its turn; never comes back this session
        case retired
    }

    /// True while a tap on the artwork has cleared the chrome
    @State private var chromeHidden = false

    /// True while the meditation text is open over the player.
    ///
    /// Read straight off `prayerImageMode`, the persisted memory of which
    /// surface this person prays on: someone who left in the reader comes
    /// back to the reader. Kept derived rather than mirrored in `@State`
    /// so the setting and the screen cannot disagree.
    private var readerOpen: Bool { !userSettings.prayerImageMode }

    let meditationSet: MeditationSet

    /// When the devotion originally began (carried through resumes for
    /// snapshot continuity; never used for duration)
    private let sessionStartedAt: Date

    /// The room the outer transport arrows are given on each side. Fixed
    /// and equal so the play button sits dead center.
    private static let transportSlotWidth: CGFloat = 52

    /// Opening and closing the reader. A spring rather than a curve —
    /// the panel should arrive with some weight behind it.
    private static let readerMotion = Animation.spring(response: 0.42, dampingFraction: 0.86)

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
            // Deliberately still while the reader rises over it. Scaling
            // and fading it looked right in the abstract and stuttered in
            // practice: the player holds two full-screen blurred copies
            // of the painting, and animating its geometry re-rasterizes
            // both on every frame of the transition. The reader's own
            // slide carries the movement; the player just waits.
            playerLayer
                .allowsHitTesting(!readerOpen)

            if readerOpen, let meditation = viewModel.currentMeditation {
                MeditationReaderView(
                    meditation: meditation,
                    mysteryKicker: mysteryKicker,
                    artworkAsset: artworkAsset,
                    viewModel: viewModel,
                    actions: trackActions,
                    onClose: { setReaderOpen(false) }
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        // A background rather than a bottom layer in the stack: a sibling
        // that ignores the safe area takes the safe area away from every
        // other sibling, and both surfaces here have chrome that has to
        // sit above the home indicator
        .background(AppColors.background.ignoresSafeArea())
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
        .task {
            // A first Rosary only, and only once it has had a moment to
            // settle — arriving with the screen would read as chrome
            guard !userSettings.hasSeenPrayerSwipeHint else { return }
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled, swipeHint == .pending else { return }
            // Spent the moment it is shown, not when it is dismissed:
            // this is the first Rosary a person ever prays, and leaving
            // the flow early should not earn them a second showing
            userSettings.hasSeenPrayerSwipeHint = true
            withAnimation(.easeInOut(duration: 0.5)) { swipeHint = .showing }
        }
        // The hint's own life, owned by a task that exists only while it is
        // on screen. Counting it down inside the task that raised it meant
        // one cancellation — a sheet, a re-render — could leave the hint up
        // for the rest of the Rosary.
        .task(id: swipeHint) {
            guard swipeHint == .showing else { return }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            dismissSwipeHint()
        }
        // Any move between mysteries — by swipe or by arrow — means the
        // hint has done its work
        .onChange(of: viewModel.currentMysteryIndex) { dismissSwipeHint() }
        .onDisappear {
            // Leaving the prayer flow (close, completion, or back) must not
            // leave meditation audio playing over other screens.
            viewModel.stopAudio()
        }
        // Exactly one `.sheet` on this view. Two of them stacked here — a
        // journal editor and a playback tray — meant SwiftUI honored one
        // and silently dropped the rest, including the ⋯ tray attached
        // further down the hierarchy.
        .sheet(item: $activeSheet, onDismiss: runPendingHandoff) { sheet in
            switch sheet {
            case .journal:
                JournalEntryEditorView(
                    category: meditationSet.mysteryCategory,
                    mysteryTitle: viewModel.currentMeditation?.displayTitle,
                    mysteryIndex: viewModel.currentMysteryIndex,
                    isMidPrayer: true
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)

            case .playback:
                PlaybackSettingsSheet()
                    .presentationDetents([.height(310)])
                    .presentationDragIndicator(.visible)

            case .tray:
                PrayerTrackTray(
                    actions: trackActions,
                    placement: .player,
                    pendingHandoff: $pendingHandoff
                )
                    .presentationDetents([
                        .height(prayerTrayHeight(for: .player, actions: trackActions))
                    ])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.cardBackground)
            }
        }
    }

    /// Takes the hint off screen. Safe to call more than once — its own
    /// timer, a move between mysteries, and a tap on the painting all
    /// race for it.
    private func dismissSwipeHint() {
        guard swipeHint != .retired else { return }
        withAnimation(.easeInOut(duration: 0.4)) { swipeHint = .retired }
    }

    // MARK: - Reader

    /// Opens or closes the reader, remembering which surface this person
    /// prays on for next time.
    private func setReaderOpen(_ open: Bool) {
        withAnimation(Self.readerMotion) {
            userSettings.prayerImageMode = !open
            chromeHidden = false
        }
    }

    // MARK: - Track Context

    /// "The Fourth Joyful Mystery" — the app's name for where the Rosary
    /// stands, used as the kicker on both surfaces.
    private var mysteryKicker: String {
        meditationSet.mysteryCategory?.mysteryLabel(ordinal: viewModel.currentMysteryIndex + 1)
            ?? "The \(Constants.ordinalWord(viewModel.currentMysteryIndex + 1)) Mystery"
    }

    private var artworkAsset: String? {
        Constants.mysteryImageURL(
            category: meditationSet.category,
            index: viewModel.currentMysteryIndex
        )
    }

    /// What the ⋯ menus can do with the meditation on screen. Assembled
    /// here so the player and the reader offer exactly the same acts.
    private var trackActions: PrayerTrackActions {
        let meditation = viewModel.currentMeditation
        let title = meditation?.displayTitle ?? meditationSet.name
        return PrayerTrackActions(
            meditationId: meditation?.id ?? 0,
            audioURL: meditation?.hasAudio == true ? meditation?.audioUrl : nil,
            shareText: "\(title) — a meditation from \(meditationSet.name) on Lumen Viae",
            feedbackSubject: "Feedback: \(title) (\(meditationSet.name))",
            onAddReflection: { activeSheet = .journal },
            onEndSession: { router.popToRoot() }
        )
    }

    // MARK: - Gestures

    /// Horizontal swipe moves between mysteries. The angle gate keeps
    /// vertical reading scrolls from ever counting, and a forward swipe
    /// on the last mystery does nothing — the Rosary is completed only by
    /// the explicit AMEN tap.
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

    // MARK: - Player

    private var playerLayer: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                playerHeader
                    .padding(.top, 8)

                Spacer()

                if let meditation = viewModel.currentMeditation {
                    playerControls(meditation: meditation)
                }
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                // The controls now sit inside the safe area, so the proxy
                // reports the inset height. The artwork and scrim bleed past
                // it in both directions and have to be sized against the
                // glass, not against the room left over for the chrome.
                let fullHeight = geometry.size.height
                    + geometry.safeAreaInsets.top
                    + geometry.safeAreaInsets.bottom

                ZStack {
                    AppColors.background
                        .ignoresSafeArea()

                    // Artwork with a frosted foot, tapped to clear the chrome
                    artworkLayer(width: geometry.size.width, fullHeight: fullHeight)

                    // Scrim so the title and controls stay legible over art
                    scrimOverlay(fullHeight: fullHeight)
                }
            }
        }
    }

    /// The mystery's artwork, pulled low on the screen. Its lower band is
    /// the artwork itself blurred — a frosted transition into the controls
    /// instead of a hard dark gradient — so more of the painting survives.
    /// With the chrome tapped away the painting takes the whole screen.
    private func artworkLayer(width: CGFloat, fullHeight: CGFloat) -> some View {
        // The frost keeps the chrome-up height in both states. It is only
        // ever visible with the chrome up, and animating its geometry
        // would re-blur two full-screen copies on every frame of the tap.
        //
        // Seated higher than the painting would like: the player's title,
        // scrubber, transport and utility row are four bands of chrome,
        // and they need ground of their own to sit on.
        let seatedHeight = fullHeight * 0.78
        let artHeight = chromeHidden ? fullHeight : seatedHeight

        return VStack(spacing: 0) {
            Group {
                if let artworkAsset {
                    mysteryArtwork(
                        artworkAsset,
                        width: width,
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
            dismissSwipeHint()
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
                        .init(color: .clear, location: chromeHidden ? 0.88 : 0.74),
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
                              radius: 5, from: 0.74, to: 0.88)
                    blurLayer(assetName, width: width, height: frostHeight,
                              radius: 13, from: 0.84, to: 0.95)
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

    /// Lighter than a hard fade — the frosted band underneath does half
    /// the legibility work, so more painting shows through.
    private func scrimOverlay(fullHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: fullHeight * 0.44)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.background.opacity(0.45), location: 0.40),
                    .init(color: AppColors.background.opacity(0.9), location: 0.68),
                    .init(color: AppColors.background, location: 0.86)
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

    /// The way out on the left, and the decade's bead strand fixed in the
    /// center. Everything else this screen can do lives with the controls
    /// at the foot, where the hand already is.
    private var playerHeader: some View {
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
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Controls

    private func playerControls(meditation: Meditation) -> some View {
        VStack(spacing: 0) {
            titleBlock(meditation: meditation)
                .padding(.horizontal, 22)

            if let errorMessage = viewModel.audioErrorMessage {
                Text(errorMessage)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
            }

            if swipeHint == .showing {
                PrayerSwipeHint()
                    .padding(.top, 14)
                    .transition(.opacity)
            }

            transportRow(meditation: meditation)
                .padding(.horizontal, 18)
                .padding(.top, swipeHint == .showing ? 12 : 18)

            utilityRow
                .padding(.top, 6)
                .padding(.bottom, 6)
        }
    }

    /// What is playing, and the ⋯ that holds everything you might want to
    /// do with it. Left-aligned and sitting directly on the transport, so
    /// the name and the act that starts it read as one block.
    private func titleBlock(meditation: Meditation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(mysteryKicker.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(meditation.displayTitle)
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(viewModel.currentMysteryIndex)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: viewModel.currentMysteryIndex)
    }

    /// The decade on the outside, the narration on the inside: bare
    /// arrows step between mysteries, the ±10s flank the play button, and
    /// on the last mystery the right-hand arrow gives way to AMEN.
    private func transportRow(meditation: Meditation) -> some View {
        HStack(spacing: 0) {
            // Present on the first mystery too, just faded: a control that
            // vanishes and reappears makes the row rearrange itself under
            // the thumb, and the arrow is half of how this screen reads
            TransportButton(
                icon: .asset("ph-arrow-left"),
                size: 20,
                label: "Previous mystery"
            ) {
                withAnimation(.easeInOut(duration: 0.4)) { viewModel.previousMystery() }
            }
            .disabled(viewModel.isFirstMystery)
            .opacity(viewModel.isFirstMystery ? 0.25 : 1)
            .accessibilityHidden(viewModel.isFirstMystery)
            .frame(width: Self.transportSlotWidth)

            Spacer(minLength: 0)

            if meditation.hasAudio {
                let ready = !viewModel.isLoadingAudio && viewModel.totalDuration > 0

                TransportButton(icon: .symbol("gobackward.10"), label: "Back 10 seconds") {
                    viewModel.skipBackward()
                }
                .disabled(!ready)
                .opacity(ready ? 1 : 0.35)

                Spacer(minLength: 10)

                NarrationPlayControl(viewModel: viewModel, diameter: 56)

                Spacer(minLength: 10)

                TransportButton(icon: .symbol("goforward.10"), label: "Forward 10 seconds") {
                    viewModel.skipForward()
                }
                .disabled(!ready)
                .opacity(ready ? 1 : 0.35)
            }

            Spacer(minLength: 0)

            // The last decade's forward move is the one that ends the
            // Rosary, so the arrow becomes a check
            TransportButton(
                icon: .asset(viewModel.isLastMystery ? "ph-check" : "ph-arrow-right"),
                size: viewModel.isLastMystery ? 21 : 20,
                label: viewModel.isLastMystery ? "Amen — finish the Rosary" : "Next mystery",
                action: handleNextMystery
            )
            .frame(width: Self.transportSlotWidth)
        }
    }

    /// Under the audio: how the narration plays, the way into the text,
    /// and everything else this meditation can do.
    private var utilityRow: some View {
        HStack(spacing: 40) {
            ReaderChromeButton(
                icon: "ph-faders",
                size: 21,
                tint: Self.utilityTint,
                label: "Playback settings"
            ) {
                activeSheet = .playback
            }

            ReaderChromeButton(
                icon: "ph-book-open",
                size: 21,
                tint: Self.utilityTint,
                label: "Read the meditation"
            ) {
                setReaderOpen(true)
            }

            ReaderChromeButton(
                icon: "ph-dots-three",
                size: 23,
                tint: Self.utilityTint,
                label: "More"
            ) {
                activeSheet = .tray
            }
        }
    }

    /// Quieter than the reader's chrome: these sit over the painting,
    /// which is already carrying the eye.
    private static let utilityTint = AppColors.cream.opacity(0.7)

    // MARK: - Helper Functions

    /// Runs whatever the tray handed over, exactly once.
    private func runPendingHandoff() {
        let action = pendingHandoff
        pendingHandoff = nil
        action?()
    }

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

// MARK: - PlayerSheet

/// What the player can put over itself. One case at a time, by design.
private enum PlayerSheet: String, Identifiable {
    case journal
    case playback
    case tray

    var id: String { rawValue }
}

// MARK: - PrayerHeaderButton

/// A circular scrim button used in the prayer flow header.
struct PrayerHeaderButton: View {
    let icon: String
    var size: CGFloat = 16
    var label: String

    /// The glyph's color — white over artwork; gold when the button is a
    /// toggle in its "on" state (a pinned set)
    var tint: Color = .white

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(icon, size: size)
                .foregroundColor(tint)
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
