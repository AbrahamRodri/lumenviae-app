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
//  It is prayed one of two ways, chosen in Settings and in the ⚙ sheet
//  (`UserSettings.prayOnBeads`):
//
//  On the beads, the whole Rosary hangs as one strand at the right
//  edge and the bead — not the mystery — is the unit the hand moves
//  through. The meditation belongs to the Our Father bead: it is heard
//  or read there, and the ten Hail Marys are prayed with only the
//  count beside you — beside the bead itself, in the strand's margin,
//  where the eye and the thumb are. Swipe down and the next bead comes
//  to hand; the mystery turns on its own when the next Our Father
//  arrives. There are no arrows between mysteries, because nothing but
//  the beads moves the Rosary forward, and on the final bead AMEN hangs
//  under the bead's name. The foot holds only the title, the
//  narration's transport and the utility row, and nothing on it changes
//  from bead to bead: a status row that once stood above the transport
//  re-wrapped its cue on every swipe and shoved the controls with it.
//
//  Off the beads, the player moves a decade at a time, for a hand that
//  keeps its own count on a rosary: swiping left/right moves between
//  mysteries, and the arrows flanking the transport do the same thing a
//  swipe does.
//
//  Either way, tapping the artwork clears the chrome for undistracted
//  contemplation, and completing the Rosary is always a deliberate tap
//  on AMEN, never a swipe.
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
    ///
    /// Both players teach their swipe once: left between mysteries off
    /// the beads, down a bead on them. On the beads the hint floats over
    /// the painting above the controls, so its coming and going never
    /// moves them.
    @State private var swipeHint: SwipeHintPhase = .pending

    /// The bead controls' measured height, so the hint can stand just
    /// above them
    @State private var controlsHeight: CGFloat = 0

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

    /// How far a swipe under way has drawn the strand, in points. The
    /// string follows the finger, so a move is felt before it is made.
    @State private var strandDrag: CGFloat = 0

    /// Whether the drag under way is the strand's. Decided once, from
    /// the first movement past the threshold, and held for the rest of
    /// the gesture: a drag that begins sideways is not a bead swipe and
    /// never becomes one.
    @State private var dragArmed: Bool?

    /// Which way the hand last moved, so the words arrive from the side
    /// the string came from: down the string for the next bead, up it
    /// for the one before.
    @State private var travel: BeadTravel = .forward

    /// Bumped each time the decade turns; the strand's ripple answers
    @State private var turnPulse = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// True while the meditation text is open over the player.
    ///
    /// Read straight off `prayerImageMode`, the persisted memory of which
    /// surface this person prays on: someone who left in the reader comes
    /// back to the reader. Kept derived rather than mirrored in `@State`
    /// so the setting and the screen cannot disagree.
    private var readerOpen: Bool { !userSettings.prayerImageMode }

    /// Whether the Rosary is prayed on the beads (see the header)
    private var onBeads: Bool { userSettings.prayOnBeads }

    let meditationSet: MeditationSet

    /// When the devotion originally began (carried through resumes for
    /// snapshot continuity; never used for duration)
    private let sessionStartedAt: Date

    /// The room the outer transport arrows are given on each side. Fixed
    /// and equal so the play button sits dead center.
    private static let transportSlotWidth: CGFloat = 52

    init(launch: PrayerLaunch) {
        self.meditationSet = launch.meditationSet
        self.sessionStartedAt = launch.startedAt
        self._viewModel = State(initialValue: PrayerSessionViewModel(
            meditationSet: launch.meditationSet,
            startAtIndex: launch.startIndex,
            startAtBead: launch.startBead,
            priorSeconds: launch.priorSeconds
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            // The reader slides the whole height of the glass, not of its
            // safe-area frame: its gradient bleeds past that frame at both
            // ends, and `.move(edge: .bottom)` — which travels exactly one
            // frame height — left a strip of it standing at the foot of
            // the screen until the transition ended and it blinked out.
            let screenHeight = geometry.size.height
                + geometry.safeAreaInsets.top
                + geometry.safeAreaInsets.bottom

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
                        painting: painting,
                        viewModel: viewModel,
                        actions: trackActions,
                        showsBeadRow: onBeads,
                        beadCue: readerBeadCue(for: meditation),
                        beadCountsDown: travel == .back,
                        onFinish: finishRosary,
                        onClose: { setReaderOpen(false) }
                    )
                    .transition(.offset(y: screenHeight))
                    .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // A background rather than a bottom layer in the stack: a sibling
        // that ignores the safe area takes the safe area away from every
        // other sibling, and both surfaces here have chrome that has to
        // sit above the home indicator
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .simultaneousGesture(prayerSwipeGesture)
        // One haptic for one move, keyed on the mystery and the bead
        // together: stepping across a decade's end changes both at once,
        // and two modifiers would tick twice in one frame — a stumble on
        // the app's quietest screen. The decade turning lands heavier
        // than a bead; a bead is the lightest tick there is.
        .sensoryFeedback(trigger: viewModel.beadPosition) { old, new in
            if new.mystery != old.mystery {
                return .impact(weight: onBeads ? .medium : .light)
            }
            return .selection
        }
        .task(id: viewModel.currentMysteryIndex) {
            saveResumePosition()
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
        // The whole Rosary said aloud, or not: on arrival, and whenever
        // the playback sheet or Settings turns it on or off mid-Rosary
        .task(id: userSettings.prayAloud) {
            await viewModel.setPrayAloud(userSettings.prayAloud)
        }
        // The last Amen said aloud: felt in the pocket, as the glowing
        // AMEN is seen on the screen
        .sensoryFeedback(.success, trigger: viewModel.isSpokenFinished) { old, new in !old && new }
        // The voice changed under the Rosary - from the playback sheet,
        // or Settings on another screen - so the mystery under the hand
        // is heard again in the new one, carrying on if it was playing
        .onChange(of: userSettings.narrationVoiceSlug) {
            Task { await viewModel.narrationVoiceChanged() }
        }
        // A bead prayed is a place to come back to, the same as a decade;
        // and a bead moved means the hint has done its work
        .onChange(of: viewModel.currentBeadIndex) {
            saveResumePosition()
            dismissSwipeHint()
        }
        .task(id: swipeHintMayShow) {
            // A first Rosary only, and only once there is something to
            // swipe and it has had a moment to settle — arriving with the
            // screen, or over a meditation still being heard, would read
            // as chrome
            guard swipeHintMayShow, !userSettings.hasSeenPrayerSwipeHint else { return }
            try? await Task.sleep(for: .seconds(onBeads ? 0.8 : 1.6))
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
        // hint has done its work; on the beads it is the decade turning,
        // which the strand marks with a ripple
        .onChange(of: viewModel.currentMysteryIndex) {
            dismissSwipeHint()
            turnPulse += 1
        }
        // The meditation heard, the locked strand comes alive where it
        // hangs: a ripple leaves the bead under the hand, and a light tick
        // says the beads are now the hand's
        .onChange(of: viewModel.beadsUnlocked) { wasUnlocked, isUnlocked in
            if celebratesUnlock(from: wasUnlocked, to: isUnlocked) { turnPulse += 1 }
        }
        .sensoryFeedback(trigger: viewModel.beadsUnlocked) { wasUnlocked, isUnlocked in
            celebratesUnlock(from: wasUnlocked, to: isUnlocked) ? .impact(weight: .light) : nil
        }
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
                .presentationBackground(AppColors.background)

            case .playback:
                PlaybackSettingsSheet()
                    .presentationDetents([.height(PlaybackSettingsSheet.height)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)

            case .feedback:
                FeedbackView(
                    context: trackActions.feedbackContext,
                    initialTopic: .meditations
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)

            case .tray:
                PrayerTrackTray(
                    actions: trackActions,
                    placement: .player,
                    pendingHandoff: $pendingHandoff
                )
                    // The tray opens as tall as it measures
                    // (`fittedSheetDetent`)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
            }
        }
    }

    /// Whether the beads coming up earn the ripple and the tick: on the
    /// beads, newly unlocked, and because the meditation was heard. Beads
    /// opened because the narration would not load are only opened —
    /// nothing was heard, and the error beside them is no occasion for a
    /// flourish.
    private func celebratesUnlock(from wasUnlocked: Bool, to isUnlocked: Bool) -> Bool {
        onBeads && isUnlocked && !wasUnlocked && viewModel.audioErrorMessage == nil
    }

    /// Whether the swipe hint has anything to teach yet: off the beads the
    /// page is swiped at once; on them, once the beads unlock.
    private var swipeHintMayShow: Bool {
        !onBeads || viewModel.beadsUnlocked
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
        withAnimation(Motion.panel) {
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

    /// What to do on the bead under the hand, for the reader's bead row
    /// — in the reader a vertical swipe is the page scrolling, so the
    /// row is tapped, and the cue says so. The player carries no cue:
    /// the bead is named beside the strand, and the one-time hint
    /// teaches the swipe. The meditation is heard or read on the Our
    /// Father; the Hail Marys are only counted; the decade prayed, the
    /// next mystery is named so the turn is expected. Nil on the final
    /// bead, where AMEN stands in the cue's place.
    private func readerBeadCue(for meditation: Meditation) -> String? {
        if viewModel.isLastBeadOfRosary { return nil }
        if viewModel.isDecadePrayed {
            let next = meditationSet.mysteryCategory?.mysteryLabel(ordinal: viewModel.currentMysteryIndex + 2)
                ?? "The \(Constants.ordinalWord(viewModel.currentMysteryIndex + 2)) Mystery"
            return "\(next) follows on the next tap."
        }
        if viewModel.currentBeadIndex == 0 {
            let act = meditation.hasAudio ? "Listen to" : "Read"
            return "\(act) the meditation, then tap for the first Hail Mary"
        }
        return "Tap for the next bead"
    }

    // MARK: - The Painting

    /// The personal painting for the mystery currently being prayed.
    /// A meditation set's artwork belongs only to its preview page; it
    /// must never replace the mystery image in the player or reader.
    private var painting: PrayerPainting? {
        // A closure, not the bare `PrayerPainting.bundled` reference:
        // the module is MainActor by default, so that reference is a
        // main-actor function value being handed to a nonisolated
        // generic, which reads as a call from no actor at all. A
        // closure literal isn't Sendable, so it inherits this view's
        // isolation and the call stays on the main actor.
        bundledPaintingName.flatMap { PrayerPainting.bundled($0) }
    }

    private var bundledPaintingName: String? {
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
            audioURL: viewModel.currentRemoteAudioURL,
            voice: viewModel.currentNarrationVoice,
            shareText: "\(title) — a meditation from \(meditationSet.name) on Lumen Viae",
            feedbackContext: FeedbackContext(
                meditationTitle: title,
                setName: meditationSet.name
            ),
            onAddReflection: { activeSheet = .journal },
            onGiveFeedback: { activeSheet = .feedback },
            onEndSession: { router.popToRoot() }
        )
    }

    // MARK: - Gestures

    /// One drag, read two ways.
    ///
    /// On the beads a vertical swipe walks the strand — down for the
    /// next bead, up for the one before — and stands aside while the
    /// reader is open, where a vertical drag is the page scrolling.
    /// Off the beads a horizontal swipe moves between mysteries, in the
    /// reader too, since the reader has no arrows of its own.
    ///
    /// A gesture is a shortcut, never the only way: every move it makes
    /// is also a tap — the bead row, the arrows — since VoiceOver and
    /// Switch Control cannot deliver a drag.
    private var prayerSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                guard onBeads, !readerOpen else { return }
                let t = value.translation
                if dragArmed == nil {
                    dragArmed = abs(t.height) > abs(t.width) * 1.2
                }
                guard dragArmed == true else { return }
                // At either end of the Rosary the string gives only a
                // little, and comes back
                // Locked until the meditation is heard, the string gives the
                // same little it gives at either end of the Rosary
                let resisted = beadsLocked || voiceHoldsStrand
                    || (t.height > 0 ? viewModel.isLastBeadOfRosary : viewModel.isFirstBeadOfRosary)
                strandDrag = RosaryStrandView.follow(t.height, resisted: resisted)
            }
            .onEnded { value in
                defer { dragArmed = nil }
                // While the voice says the opening prayers, or waits on its
                // recordings, the hand has nowhere to go: a stray swipe
                // skipped the Creed for good, or was undone a moment later
                // when the voice began where it had meant to
                if voiceHoldsStrand {
                    if onBeads { settleStrand() }
                    return
                }
                if onBeads {
                    guard !readerOpen else { return }
                    handleBeadSwipe(value)
                } else {
                    handleMysterySwipe(value)
                }
            }
    }

    /// Down for the next bead, up for the one before: mostly vertical,
    /// and either far enough or flicked. Short of that the string comes
    /// back to rest. A forward swipe on the final bead does nothing —
    /// the Rosary is completed only by AMEN.
    private func handleBeadSwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        let flung = value.predictedEndTranslation.height
        guard abs(dy) > abs(dx) * 1.2,
              abs(dy) >= 60 || abs(flung) >= 120 else {
            settleStrand()
            return
        }

        if dy > 0 {
            prayForward()
        } else {
            prayBack()
        }
    }

    /// The string let go short of a bead, or tugged at an end of the
    /// Rosary, coming back to where it was.
    private func settleStrand() {
        withAnimation(Motion.beadSettle) { strandDrag = 0 }
    }

    /// Left for the next mystery, right for the one before. The angle
    /// gate keeps vertical reading scrolls from ever counting, and a
    /// forward swipe on the last mystery does nothing.
    private func handleMysterySwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }

        if dx < 0 {
            guard !viewModel.isLastMystery else { return }
            travel = .forward
            withAnimation(Motion.decadeTurn) {
                _ = viewModel.nextMystery()
            }
        } else {
            // A drag begun on the left bezel is the navigation
            // stack's interactive pop. Stepping back a mystery on
            // the way out of the flow resets audio mid-transition
            // and lands the user somewhere they didn't ask for.
            guard value.startLocation.x > 40 else { return }
            travel = .back
            withAnimation(Motion.decadeTurn) {
                viewModel.previousMystery()
            }
        }
    }

    /// One bead forward along the strand. The swipe, the bead row and
    /// the reader's row all come here. On the final bead there is
    /// nowhere to go — the string settles, and only AMEN finishes.
    /// The strand hangs locked until the meditation under the hand has been
    /// heard: a swipe only tugs it and lets it back, and the rotor's bead
    /// actions leave it where it is. The reader's bead row, which moves the
    /// view model directly, is never locked.
    private var beadsLocked: Bool {
        onBeads && !viewModel.beadsUnlocked
    }

    /// The spoken Rosary has the hand: the opening prayers are being
    /// said on the pendant, or the recordings are still being fetched.
    /// The player's own previous and next prayer buttons still move it.
    private var voiceHoldsStrand: Bool {
        viewModel.spokenStatus != nil || isOnOpeningPendant
    }

    private func prayForward() {
        guard !viewModel.isLastBeadOfRosary, !beadsLocked else {
            settleStrand()
            return
        }
        travel = .forward
        withAnimation(Motion.beadSlide) {
            _ = viewModel.prayForward()
            strandDrag = 0
        }
    }

    /// One bead back along the strand, into the previous decade from
    /// an Our Father. On the first bead the string only settles.
    private func prayBack() {
        guard !viewModel.isFirstBeadOfRosary, !beadsLocked else {
            settleStrand()
            return
        }
        travel = .back
        withAnimation(Motion.beadSlide) {
            viewModel.prayBack()
            strandDrag = 0
        }
    }

    // MARK: - Player

    private var playerLayer: some View {
        GeometryReader { geometry in
            let fullHeight = geometry.size.height
                + geometry.safeAreaInsets.top
                + geometry.safeAreaInsets.bottom

            VStack(spacing: 0) {
                playerHeader
                    .padding(.top, 12)

                Spacer()

                if let meditation = viewModel.currentMeditation {
                    if onBeads {
                        beadControls(meditation: meditation)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsHeight = $0 }
                    } else {
                        decadeControls(meditation: meditation)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                // The beads' one-time hint floats over the painting just
                // above the controls, so the controls never move for it
                if onBeads, swipeHint == .showing {
                    PrayerSwipeHint(onBeads: true)
                        // Clear of the frost's darkest band, where a
                        // capsule set right against the controls was
                        // lost against the ground
                        .padding(.bottom, controlsHeight + 36)
                        .transition(.opacity)
                }
            }
            .overlay {
                // The Rosary's one strand, hung at the right edge, sliding
                // a bead at a time under the hand, with the bead's name
                // beside it and AMEN under that on the final bead. Inside
                // the chrome layer so it goes with the chrome when the
                // painting is tapped. The strand takes no touches of its
                // own; only the AMEN does.
                //
                // On a mystery whose meditation has not yet been heard it
                // hangs greyed and locked (`beadsUnlocked`), named for when
                // it opens, and does not move under the finger; the
                // narration's end brings it to life where it hangs.
                //
                // Not while the opening prayers are said aloud: they are
                // prayed on the pendant, drawn on the stage, and the
                // decade's strand comes in with the first mystery.
                if onBeads, !isOnOpeningPendant {
                    Color.clear
                        .rosaryStrand(
                            viewModel.strand,
                            activeIndex: viewModel.strandIndex,
                            fullHeight: fullHeight,
                            topInset: geometry.safeAreaInsets.top,
                            dragOffset: strandDrag,
                            turnPulse: turnPulse,
                            activeLabel: viewModel.beadLabelLines,
                            locked: !viewModel.beadsUnlocked,
                            onAmen: viewModel.isLastBeadOfRosary ? { finishRosary() } : nil,
                            amenBeckons: viewModel.isSpokenFinished
                        )
                }
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .background {
                // The painting, its frost and its scrim — the ground the
                // Scriptural Rosary prays on too, so it lives apart. The
                // controls sit inside the safe area, so the proxy reports
                // the inset height; the stage is handed the glass.
                //
                // While the opening or closing prayers are said aloud the
                // pendant stands there instead: those prayers are not the
                // mystery's, and its painting arrives with its decade.
                ZStack {
                    if let pendant = viewModel.spokenPendant {
                        PendantStage(
                            pendant: pendant,
                            width: geometry.size.width,
                            fullHeight: fullHeight,
                            heightFraction: 0.46,
                            topFraction: 0.165
                        )
                        .transition(.opacity)
                    } else {
                        PrayerPaintingStage(
                            painting: painting,
                            paintingID: viewModel.currentMysteryIndex,
                            chromeHidden: chromeHidden,
                            width: geometry.size.width,
                            fullHeight: fullHeight
                        ) {
                            dismissSwipeHint()
                            withAnimation(Motion.chrome) {
                                chromeHidden.toggle()
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .animation(Motion.decadeTurn, value: viewModel.spokenPendant == nil)
            }
        }
    }

    /// The way out on the left. On the beads, the set's name stands in
    /// the centre — the strand at the edge already says where the
    /// Rosary is; off them, the Rosary's own strand of mysteries stands
    /// there instead. Everything else this screen can do lives with the
    /// controls at the foot, where the hand already is.
    private var playerHeader: some View {
        ZStack {
            if onBeads {
                Text(meditationSet.name.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.goldLight)
                    .shadow(color: .black.opacity(0.6), radius: 6, y: 1)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                    .transition(.opacity)
            } else {
                RosaryBeadProgress(
                    total: viewModel.totalMysteries,
                    completed: viewModel.currentMysteryIndex,
                    activeIndex: viewModel.currentMysteryIndex,
                    beadSize: 8
                )
                .frame(width: 150)
                .transition(.opacity)
            }

            HStack {
                PrayerHeaderButton(icon: "ph-x", size: 18, label: "End prayer") {
                    router.popToRoot()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Controls, on the Beads

    /// The foot of the player prayed on the beads: the name of what is
    /// playing, the narration's transport, and the utility row — and
    /// nothing that changes from bead to bead. The bead itself is named
    /// beside the strand. No arrows — the beads are the only way
    /// forward; a hand that cannot swipe prays them through the title's
    /// rotor actions.
    private func beadControls(meditation: Meditation) -> some View {
        VStack(spacing: 0) {
            spokenOrMysteryTitle(meditation: meditation, showsMysteryName: true)
                // Clear of the strand at the right edge, which is not
                // hung while the opening prayers are said
                .padding(.trailing, isOnOpeningPendant ? 0 : 100)
                .padding(.horizontal, 22)
                .accessibilityElement(children: .combine)
                .accessibilityValue(viewModel.beadLabel)
                .accessibilityHint(
                    beadsLocked
                        ? "The beads unlock when the meditation ends"
                        : (viewModel.isLastBeadOfRosary ? "" : "Swipe down, or use the actions, for the next bead")
                )
                .accessibilityAction(named: "Next bead", prayForward)
                .accessibilityAction(named: "Previous bead", prayBack)

            if let errorMessage = viewModel.audioErrorMessage {
                Text(errorMessage)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
            }

            spokenLine

            // The narration can be replayed from any bead, so the
            // transport stands at full strength on every one; a mystery
            // with nothing to play shows no transport at all
            if meditation.hasAudio || viewModel.isPrayingAloud {
                narrationTransport
                    .padding(.top, 18)
                    .transition(.opacity)
            }

            utilityRow
                .padding(.top, meditation.hasAudio || viewModel.isPrayingAloud ? 18 : 12)
                .padding(.bottom, 16)
        }
        .padding(.top, 6)
        .animation(Motion.decadeTurn, value: meditation.hasAudio)
    }

    /// The ±10s flanking the play button, and nothing else — or, while
    /// the whole Rosary is said aloud, the prayer before and the prayer
    /// after, since ten seconds is most of a Hail Mary.
    private var narrationTransport: some View {
        HStack(spacing: 22) {
            backTransportButton(size: 24)
            playControl
            forwardTransportButton(size: 24)
        }
    }

    /// Back ten seconds, or back a prayer when said aloud
    private func backTransportButton(size: CGFloat) -> some View {
        let aloud = viewModel.isPrayingAloud
        let ready = aloud ? viewModel.spokenStatus == nil : transportReady
        return TransportButton(
            icon: .symbol(aloud ? "backward.end" : "gobackward.10"),
            size: aloud ? size - 4 : size,
            label: aloud ? "Previous prayer" : "Back 10 seconds"
        ) {
            if aloud { viewModel.stepSpokenPrayer(forward: false) } else { viewModel.skipBackward() }
        }
        .disabled(!ready)
        .opacity(ready ? 1 : 0.35)
    }

    /// Forward ten seconds, or on a prayer when said aloud
    private func forwardTransportButton(size: CGFloat) -> some View {
        let aloud = viewModel.isPrayingAloud
        let ready = aloud ? viewModel.spokenStatus == nil : transportReady
        return TransportButton(
            icon: .symbol(aloud ? "forward.end" : "goforward.10"),
            size: aloud ? size - 4 : size,
            label: aloud ? "Next prayer" : "Forward 10 seconds"
        ) {
            if aloud { viewModel.stepSpokenPrayer(forward: true) } else { viewModel.skipForward() }
        }
        .disabled(!ready)
        .opacity(ready ? 1 : 0.35)
    }

    private var transportReady: Bool {
        !viewModel.isLoadingAudio && viewModel.totalDuration > 0
    }

    /// The play button, dimmed and still while the recordings are being
    /// fetched: pressed then, it did nothing
    private var playControl: some View {
        let preparing = viewModel.spokenStatus != nil
        return NarrationPlayControl(viewModel: viewModel, diameter: 56)
            .disabled(preparing)
            .opacity(preparing ? 0.45 : 1)
    }

    // MARK: - Controls, a Decade at a Time

    /// The foot of the player prayed off the beads: the name of what is
    /// playing, the transport with the mystery arrows on its outside,
    /// and the utility row.
    private func decadeControls(meditation: Meditation) -> some View {
        VStack(spacing: 0) {
            spokenOrMysteryTitle(meditation: meditation, showsMysteryName: false)
                .padding(.horizontal, 22)

            if let errorMessage = viewModel.audioErrorMessage {
                Text(errorMessage)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
            }

            spokenLine

            if swipeHint == .showing {
                PrayerSwipeHint()
                    .padding(.top, 14)
                    .transition(.opacity)
            }

            decadeTransportRow(meditation: meditation)
                .padding(.horizontal, 18)
                .padding(.top, swipeHint == .showing ? 20 : 30)

            utilityRow
                .padding(.top, 22)
                .padding(.bottom, 16)
        }
    }

    /// The decade on the outside, the narration on the inside: bare
    /// arrows step between mysteries, the ±10s flank the play button, and
    /// on the last mystery the right-hand arrow gives way to AMEN.
    private func decadeTransportRow(meditation: Meditation) -> some View {
        HStack(spacing: 0) {
            // Present on the first mystery too, just faded: a control that
            // vanishes and reappears makes the row rearrange itself under
            // the thumb, and the arrow is half of how this screen reads
            TransportButton(
                icon: .asset("ph-arrow-left"),
                size: 20,
                label: "Previous mystery"
            ) {
                travel = .back
                withAnimation(Motion.decadeTurn) { viewModel.previousMystery() }
            }
            .disabled(viewModel.isFirstMystery)
            .opacity(viewModel.isFirstMystery ? 0.25 : 1)
            .accessibilityHidden(viewModel.isFirstMystery)
            .frame(width: Self.transportSlotWidth)

            Spacer(minLength: 0)

            if meditation.hasAudio || viewModel.isPrayingAloud {
                backTransportButton(size: 22)

                Spacer(minLength: 10)

                playControl

                Spacer(minLength: 10)

                forwardTransportButton(size: 22)
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
            // The last Amen said aloud: the check is the one thing left,
            // and it glows for it rather than a line saying so
            .beckoning(viewModel.isSpokenFinished)
            .frame(width: Self.transportSlotWidth)
        }
    }

    // MARK: - Shared Furniture

    /// While the Rosary is said aloud: before it begins, the recordings
    /// being fetched; off the beads, the prayer being said, in the
    /// title's small capitals. On the beads the strand already names the
    /// bead under the hand, and a second name here changed with every
    /// swipe — the foot must not change from bead to bead. Off the beads
    /// the line is the only readout, so it keeps one line's room for as
    /// long as the voice prays, and only its words change. When the
    /// recordings could not be had, what went wrong and the control that
    /// puts it right (`SpokenRosaryNotice`).
    @ViewBuilder
    private var spokenLine: some View {
        if let failure = viewModel.spokenFailure {
            SpokenRosaryNotice(failure: failure) {
                Task { await viewModel.retrySpoken() }
            }
            .padding(.top, 10)
            .transition(.opacity)
        } else if let status = viewModel.spokenStatus {
            spokenLineText(status, lit: false)
        } else if viewModel.isPrayingAloud, !onBeads {
            // On the pendant the title already names the prayer
            let caption = viewModel.spokenPendant == nil ? viewModel.spokenCaption : nil
            spokenLineText(caption ?? " ", lit: true)
                .accessibilityHidden(caption == nil)
        }
    }

    private func spokenLineText(_ line: String, lit: Bool) -> some View {
        Text(line.uppercased())
            .font(AppFonts.labelFont(10))
            .tracking(2)
            .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 30)
            .padding(.top, 8)
            .contentTransition(.opacity)
            .animation(Motion.words, value: line)
            .accessibilityLabel(line)
    }

    /// What is playing, and where the Rosary stands. Left-aligned and
    /// sitting directly on what follows, so the name and the act read as
    /// one block. On the beads the mystery's own name rides beneath the
    /// meditation's title — the strand names the decade by numeral only.
    ///
    /// The words crossfade in place rather than the block being torn
    /// down and rebuilt: a re-identified block is laid out twice over
    /// for the length of its transition, and the foot would stand
    /// taller for half a second on every turn of the decade.
    /// Whether the opening prayers are being said aloud right now
    private var isOnOpeningPendant: Bool {
        viewModel.spokenPendant?.phase == .opening
    }

    /// The mystery's title — or, while the opening and closing prayers
    /// are said aloud, theirs: the first mystery's name over the Creed
    /// said the decade had begun when it had not.
    @ViewBuilder
    private func spokenOrMysteryTitle(meditation: Meditation, showsMysteryName: Bool) -> some View {
        if let pendant = viewModel.spokenPendant {
            PendantTitleBlock(
                pendant: pendant,
                leadsInto: pendant.phase == .opening
                    ? PendantTitleBlock.leadIn(to: mysteryKicker)
                    : nil
            )
        } else {
            titleBlock(meditation: meditation, showsMysteryName: showsMysteryName)
        }
    }

    private func titleBlock(meditation: Meditation, showsMysteryName: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(mysteryKicker.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)
                .contentTransition(.opacity)

            Text(meditation.displayTitle)
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)

            // Not when the meditation is simply named after its mystery
            // — the same words twice, one under the other, read as a
            // mistake
            if showsMysteryName,
               let mystery = viewModel.currentMystery,
               mystery.name.caseInsensitiveCompare(meditation.displayTitle) != .orderedSame {
                Text(mystery.name)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .padding(.top, 3)
                    .contentTransition(.opacity)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        // The new mystery's name arrives the way the decade turned:
        // from above when the Rosary moved on, from below when it
        // stepped back
        .beadWordsArrival(trigger: viewModel.currentMysteryIndex, from: travel, still: reduceMotion, distance: 8)
        .animation(Motion.decadeTurn, value: viewModel.currentMysteryIndex)
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
    /// Only once the user has actually advanced — a decade or a bead —
    /// glancing at a set's first mystery and backing out must neither
    /// pin a resume card nor overwrite a genuinely interrupted session.
    private func saveResumePosition() {
        let mystery = viewModel.currentMysteryIndex
        let bead = viewModel.currentBeadIndex
        guard mystery > 0 || bead > 0 else { return }
        PrayerResumeService.shared.save(
            setId: meditationSet.id,
            setName: meditationSet.name,
            category: meditationSet.category,
            mysteryIndex: mystery,
            beadIndex: bead,
            startedAt: sessionStartedAt,
            accumulatedSeconds: viewModel.sessionDuration
        )
    }

    /// The arrow's move off the beads: the next mystery, or from the
    /// last one the end of the Rosary.
    private func handleNextMystery() {
        travel = .forward
        let advanced = withAnimation(Motion.decadeTurn) {
            viewModel.nextMystery()
        }
        guard !advanced else { return }
        finishRosary()
    }

    /// Completed all mysteries — records the Rosary and moves to the
    /// completion screen. The AMEN tap, on either surface, comes here.
    private func finishRosary() {
        PrayerResumeService.shared.clear()
        Task {
            try? await viewModel.recordCompletion()
        }
        router.navigateToCompletion(CompletedPrayer(
            category: meditationSet.mysteryCategory,
            devotionName: meditationSet.name,
            durationSeconds: viewModel.sessionDuration
        ))
    }
}

// MARK: - PlayerSheet

/// What the player can put over itself. One case at a time, by design.
private enum PlayerSheet: String, Identifiable {
    case journal
    case playback
    case tray
    case feedback

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
