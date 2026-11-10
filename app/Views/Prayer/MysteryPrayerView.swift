//
//  MysteryPrayerView.swift
//  app
//
//  Created by Abraham Rodriguez on 2/11/26.
//
//  The Rosary prayed with a meditation set: one player, the same for
//  every form of the Rosary (`ScripturalRosaryPrayerView` is the other
//  two's). Every prayer is said aloud from the moment PRAY is pressed,
//  with play and pause between Back and Next, the beads of the whole
//  Rosary at the right edge (tapped, never needing to be), a pill at the
//  head to go to any part, and a speaker to mute the voice while the
//  Rosary goes on at the recording's own pace. The words being said are
//  lit only from a recording's real timings (`SimpleRosary`).
//
//  A set with no recording opens as text (`MeditationReaderView`), and
//  over a set that is heard, READ THE MEDITATION opens the same reader
//  on a mystery's Our Father. Completing the Rosary is always a
//  deliberate tap on AMEN.
//
//  Abraham, Nov 2026: "Yes, only Rosary". The player it replaced (a
//  strand to swipe, or a decade at a time, chosen by Audio and Counting)
//  is gone.
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

    /// The bead controls' measured height, so the hint can stand just
    /// above them
    @State private var controlsHeight: CGFloat = 0

    /// True while a tap on the artwork has cleared the chrome
    @State private var chromeHidden = false

    /// Which way the hand last moved, so the words arrive from the side
    /// the string came from: down the string for the next bead, up it
    /// for the one before.
    @State private var travel: BeadTravel = .forward

    /// Bumped each time the decade turns; the strand's ripple answers
    @State private var turnPulse = 0

    /// The one-time hint that the beads take a tap
    @State private var tapHintShowing = false

    /// Rings the next bead once as the hint shows
    @State private var tapHintPulse = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The reader over the player. Not on the pendant: the opening and
    /// closing prayers have no meditation to read, and their words are
    /// on the player itself. A set with no recording is read in the
    /// reader; over a set that is heard, READ THE MEDITATION opens it
    private var readerShown: Bool {
        guard viewModel.silentPendantPrayer == nil else { return false }
        return readerIsTheRosary || simpleReaderOpen
    }

    /// The meditation opened as text from READ THE MEDITATION over a set
    /// that is heard. Not remembered: the next Rosary opens in the
    /// player again
    @State private var simpleReaderOpen = false

    /// The reader is the whole Rosary for a set with no recording; over
    /// a set that is heard, it is an aside that closes
    private var readerIsTheRosary: Bool {
        SimpleRosary.opensAsText(setHasRecording: meditationSet.hasAudio)
    }

    /// Whether every prayer is said aloud: always, for a set with a
    /// recording
    private var aloudWanted: Bool {
        SimpleRosary.praysAloud(form: .meditation, setHasRecording: meditationSet.hasAudio)
    }

    let meditationSet: MeditationSet

    /// When the devotion originally began (carried through resumes for
    /// snapshot continuity; never used for duration)
    private let sessionStartedAt: Date

    /// Where the pendant hangs from, and how much of the glass it may
    /// take when the foot leaves it the room
    private static let pendantTopFraction: CGFloat = 0.165
    private static let pendantHeightFraction: CGFloat = 0.46

    /// The pendant's height, fitted above the foot. Placed by fractions
    /// of the glass alone, at the largest text sizes its cross stood
    /// behind the prayer's name, the foot having grown up over it; it
    /// now gives up height to the foot rather than room, and at every
    /// other size it hangs as it always has.
    private func pendantHeightFraction(fullHeight: CGFloat, controlsTop: CGFloat) -> CGFloat {
        guard controlsHeight > 0, fullHeight > 0 else { return Self.pendantHeightFraction }
        let room = controlsTop - fullHeight * Self.pendantTopFraction - 16
        return min(Self.pendantHeightFraction, max(room, 0) / fullHeight)
    }

    /// The simple Rosary's beginner's path: one plain line on each step
    /// saying what to pray (`RosaryHelps`)
    let showsHelps: Bool

    init(launch: PrayerLaunch) {
        self.meditationSet = launch.meditationSet
        self.showsHelps = launch.showsHelps
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
                oneRosaryLayer
                    .allowsHitTesting(!readerShown)

                if readerShown, let meditation = viewModel.currentMeditation {
                    MeditationReaderView(
                        meditation: meditation,
                        mysteryKicker: mysteryKicker,
                        painting: painting,
                        viewModel: viewModel,
                        actions: trackActions,
                        showsBeadRow: true,
                        beadCue: readerBeadCue(for: meditation),
                        beadCountsDown: travel == .back,
                        onFinish: finishRosary,
                        // Read as text, the reader is the Rosary: closing
                        // it leaves the Rosary. Opened over a set that is
                        // heard, it closes back to the player
                        onClose: {
                            if readerIsTheRosary {
                                router.popToRoot()
                            } else {
                                withAnimation(Motion.panel) { simpleReaderOpen = false }
                            }
                        }
                    )
                    .transition(reduceMotion ? .opacity : .offset(y: screenHeight))
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
        // One haptic for one move, keyed on the mystery and the bead
        // together: stepping across a decade's end changes both at once,
        // and two modifiers would tick twice in one frame — a stumble on
        // the app's quietest screen. The decade turning lands heavier
        // than a bead; a bead is the lightest tick there is.
        .sensoryFeedback(trigger: viewModel.beadPosition) { old, new in
            if new.mystery != old.mystery {
                return .impact(weight: .medium)
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
        .task(id: aloudWanted) {
            await viewModel.setPrayAloud(aloudWanted)
        }
        // The last Amen said aloud: felt in the pocket, as the glowing
        // AMEN is seen on the screen
        .sensoryFeedback(.success, trigger: viewModel.isSpokenFinished) { old, new in !old && new }
        // The chrome comes back on its own where it is needed: when the
        // pendant takes the painting's place — the ground that was tapped
        // to clear it is gone — and when the Rosary reaches its end, where
        // AMEN is the one thing left to do
        .onChange(of: viewModel.pendant == nil) { _, noPendant in
            if !noPendant { showChrome() }
        }
        .onChange(of: viewModel.isSpokenFinished) { _, finished in
            if finished { showChrome() }
        }
        .onChange(of: viewModel.isLastBeadOfRosary) { _, last in
            if last { showChrome() }
        }
        // The voice changed under the Rosary - from the playback sheet,
        // or Settings on another screen - so the mystery under the hand
        // is heard again in the new one, carrying on if it was playing
        .onChange(of: userSettings.narrationVoiceSlug) {
            Task { await viewModel.narrationVoiceChanged() }
        }
        // A bead prayed is a place to come back to, the same as a decade
        .onChange(of: viewModel.currentBeadIndex) {
            saveResumePosition()
        }
        // Once, when the beads can first be tapped, that they can
        .task(id: beadTapHintMayShow && viewModel.pendant == nil) {
            guard beadTapHintMayShow, viewModel.pendant == nil,
                  !userSettings.hasSeenBeadTapHint else { return }
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            userSettings.hasSeenBeadTapHint = true
            withAnimation(.easeInOut(duration: 0.5)) { tapHintShowing = true }
            tapHintPulse += 1
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeInOut(duration: 0.6)) { tapHintShowing = false }
        }
        // The decade turning, which the rail marks with a ripple
        .onChange(of: viewModel.currentMysteryIndex) {
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
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .playback:
                PlaybackSettingsSheet()
                    .presentationDetents(PlaybackSettingsSheet.detents(for: dynamicTypeSize))
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .feedback:
                FeedbackView(
                    context: trackActions.feedbackContext,
                    initialTopic: .meditations
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .text:
                ReaderTextOptionsSheet(
                    showsNarrationOptions: false,
                    showsPartsToggle: true
                )
                    .presentationDetents([
                        .height(ReaderTextOptionsSheet.height(
                            showsNarrationOptions: false,
                            showsPartsToggle: true))
                    ])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .stops:
                RosaryStopsSheet(
                    title: meditationSet.name,
                    stops: viewModel.stops,
                    current: viewModel.currentStop,
                    mysteryNames: (0..<viewModel.totalMysteries).map { index in
                        let meditations = meditationSet.meditations ?? []
                        let fallback = MysteryData.mysteries(for: meditationSet.mysteryCategory ?? .joyful)
                        return (meditations.indices.contains(index) ? meditations[index].mystery?.name : nil)
                            ?? (fallback.indices.contains(index) ? fallback[index].name : "")
                    },
                    meditationTitles: (meditationSet.meditations ?? []).map(\.displayTitle),
                    isChaplet: meditationSet.mysteryCategory == .sevenSorrows
                ) { stop in
                    travel = .forward
                    viewModel.jump(to: stop)
                }
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)

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
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
    }

    /// Whether the beads coming up earn the ripple and the tick: on the
    /// beads, newly unlocked, and because the meditation was heard. Beads
    /// opened because the narration would not load are only opened —
    /// nothing was heard, and the error beside them is no occasion for a
    /// flourish.
    private func celebratesUnlock(from wasUnlocked: Bool, to isUnlocked: Bool) -> Bool {
        isUnlocked && !wasUnlocked && viewModel.audioErrorMessage == nil
    }

    /// Whether the hint that the beads take a tap has anything to teach
    /// yet: once the beads unlock, and never while the voice holds the
    /// hand on the pendant, where a tap on a bead does nothing.
    private var beadTapHintMayShow: Bool {
        viewModel.beadsUnlocked && !voiceHoldsStrand
            && viewModel.silentPendantPrayer == nil
    }

    // MARK: - The Chrome

    /// A tap on the ground — the painting, or the pendant in its place —
    /// clears the chrome for contemplation, or brings it back
    private func toggleChrome() {
        withAnimation(Motion.chrome) { chromeHidden.toggle() }
    }

    private func showChrome() {
        guard chromeHidden else { return }
        withAnimation(Motion.chrome) { chromeHidden = false }
    }

    // MARK: - Reader

    // MARK: - Track Context

    /// "The Fourth Joyful Mystery" — the app's name for where the Rosary
    /// stands, used as the kicker on both surfaces.
    private var mysteryKicker: String {
        meditationSet.mysteryCategory?.mysteryLabel(ordinal: viewModel.currentMysteryIndex + 1)
            ?? Self.unknownMysteryLabel(ordinal: viewModel.currentMysteryIndex + 1)
    }

    /// "The Fourth Mystery", for a set whose mysteries are not known
    private static func unknownMysteryLabel(ordinal: Int) -> String {
        String(
            localized: "The \(Constants.ordinalWord(ordinal)) Mystery",
            comment: "Prayer screen: a decade by its place when its set is not known; the ordinal is a word like Fourth"
        )
    }

    /// What to do on the bead under the hand, for the reader's bead row
    /// — in the reader a vertical swipe is the page scrolling, so the
    /// row is tapped, and the cue says so. The player carries no cue:
    /// the bead is named beside the strand, and the one-time hint
    /// teaches the swipe. The meditation is heard or read on the Our
    /// Father; the Hail Marys are only counted; the decade prayed, the
    /// next mystery is named so the turn is expected. Nil on the final
    /// bead, where AMEN stands in the cue's place.
    ///
    /// Said aloud, the voice moves the beads and there is nothing to be
    /// told to tap: the cue names the opening prayer being said, which
    /// the bead's own name ("Opening prayers") cannot, and is otherwise
    /// silent — it once told a person to tap for the first Hail Mary
    /// while the voice was saying the Creed.
    private func readerBeadCue(for meditation: Meditation) -> String? {
        if viewModel.isPrayingAloud {
            return viewModel.spokenPendant.map(\.title)
        }
        if viewModel.isLastBeadOfRosary { return nil }
        if viewModel.isDecadePrayed, viewModel.isLastMystery, !viewModel.lastMysteryEndsRosary {
            return String(
                localized: "The closing prayers follow on the next tap.",
                comment: "Meditation reader, bead row cue after the last decade: a tap goes on to the closing prayers"
            )
        }
        if viewModel.isDecadePrayed {
            let next = meditationSet.mysteryCategory?.mysteryLabel(ordinal: viewModel.currentMysteryIndex + 2)
                ?? Self.unknownMysteryLabel(ordinal: viewModel.currentMysteryIndex + 2)
            return String(
                localized: "\(next) follows on the next tap.",
                comment: "Meditation reader, bead row cue once a decade is prayed: the next mystery's title, like The Second Joyful Mystery"
            )
        }
        if viewModel.currentBeadIndex == 0 {
            return meditation.hasAudio
                ? String(
                    localized: "Listen to the meditation, then tap for the first Hail Mary",
                    comment: "Meditation reader, bead row cue on the Our Father bead of a meditation with narration"
                )
                : String(
                    localized: "Read the meditation, then tap for the first Hail Mary",
                    comment: "Meditation reader, bead row cue on the Our Father bead of a meditation with no narration"
                )
        }
        return String(localized: "Tap for the next bead", comment: "Meditation reader, bead row cue on a Hail Mary bead")
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
            shareText: ShareText.meditation(
                title: title,
                content: meditation?.content ?? "",
                author: meditation?.author ?? meditationSet.author,
                source: meditation?.source ?? meditationSet.source,
                setName: meditationSet.name
            ),
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

    /// One bead forward along the strand. The swipe, the bead row and
    /// the reader's row all come here. On the final bead there is
    /// nowhere to go — the string settles, and only AMEN finishes.
    /// The strand hangs locked until the meditation under the hand has been
    /// heard: a swipe only tugs it and lets it back, and the rotor's bead
    /// actions leave it where it is. The reader's bead row, which moves the
    /// view model directly, is never locked.
    private var beadsLocked: Bool {
        !viewModel.beadsUnlocked
    }

    /// The spoken Rosary has the hand: the opening prayers are being
    /// said on the pendant, or the recordings are still being fetched.
    /// The player's own previous and next prayer buttons still move it.
    private var voiceHoldsStrand: Bool {
        viewModel.voiceHoldsHand
    }

    private func prayForward() {
        guard !viewModel.isLastBeadOfRosary, !beadsLocked, !voiceHoldsStrand else { return }
        travel = .forward
        withAnimation(reduceMotion ? nil : Motion.beadSlide) {
            _ = viewModel.prayForward()
        }
    }

    /// One bead back along the strand, into the previous decade from
    /// an Our Father. On the first bead the string only settles.
    private func prayBack() {
        // Back from the first Our Father into the opening prayers just
        // left, even while its meditation is still to be heard: the lock
        // holds the beads ahead, not the prayers behind
        let intoOpening = viewModel.isFirstMystery && viewModel.currentBeadIndex == 0
            && viewModel.currentPendantStep == nil && viewModel.pendantShown
        guard !viewModel.isFirstBeadOfRosary, !beadsLocked || intoOpening, !voiceHoldsStrand else { return }
        travel = .back
        withAnimation(reduceMotion ? nil : Motion.beadSlide) {
            viewModel.prayBack()
        }
    }

    // MARK: - Controls

    private var transportReady: Bool {
        !viewModel.isLoadingAudio && viewModel.totalDuration > 0
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
        }
    }

    private func spokenLineText(_ line: String, lit: Bool) -> some View {
        Text(line.uppercased())
            .font(AppFonts.labelFont(12))
            .tracking(2)
            .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .padding(.horizontal, 30)
            .padding(.top, 8)
            .contentTransition(.opacity)
            .animation(Motion.words, value: line)
            .accessibilityLabel(line)
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
                    ? PendantTitleBlock.leadIn(
                        category: meditationSet.mysteryCategory,
                        ordinal: viewModel.currentMysteryIndex + 1
                    )
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
                // Wraps rather than cut: a Spanish name runs to 66 letters
                Text(mystery.name)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
    private func saveResumePosition(evenAtTheStart: Bool = false) {
        let mystery = viewModel.currentMysteryIndex
        let bead = viewModel.currentBeadIndex
        guard mystery > 0 || bead > 0 || evenAtTheStart else { return }
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

// MARK: - The Player

/// The meditation's player is the one
/// player both players become (`OneRosaryViews`): the rail of the whole
/// Rosary at the edge, the prayer under the hand in one column that never
/// moves, and Back and Next at the foot on every step. Off, nothing here
/// is drawn.
extension MysteryPrayerView {

    /// The rail: the pendant with the decades, while the opening and
    /// closing prayers are prayed (shown, or said by the voice)
    fileprivate var rail: OneRosaryRail {
        OneRosaryRail(
            strand: viewModel.strand,
            pendant: viewModel.silentPendant,
            showsPendant: userSettings.showsOpeningPrayers || viewModel.isPrayingAloud
        )
    }

    fileprivate func railIndex(_ rail: OneRosaryRail) -> Int {
        if let step = viewModel.currentPendantStep { return rail.index(of: step) }
        if let pendant = viewModel.spokenPendant { return rail.index(of: pendant) }
        return rail.index(strandIndex: viewModel.strandIndex)
    }

    /// The beads a tap may reach: on the decades, near the hand, as
    /// `RosaryStrand.canTap` allows, and never ahead while the meditation
    /// is still to be heard or while the voice holds the hand
    fileprivate func tappableBeads(_ rail: OneRosaryRail) -> Set<Int> {
        guard viewModel.pendant == nil, !voiceHoldsStrand else { return [] }
        let strand = viewModel.strand
        let active = viewModel.strandIndex
        let near = max(active - 4, 0)...min(active + 4, strand.count - 1)
        return Set(
            near.filter {
                strand.canTap($0, from: active, onGloryBe: viewModel.isDecadePrayed)
                    && (!beadsLocked || $0 < active)
            }
            .map { rail.index(strandIndex: $0) })
    }

    /// The hand on the closing prayers, back at the medal or the cross
    fileprivate var oneRosaryOnClose: Bool {
        if case .closing = viewModel.currentPendantStep { return true }
        return viewModel.spokenPendant?.phase == .closing
    }

    /// The last step, the whole Rosary prayed: AMEN stands, and the rail
    /// shows every bead gold
    fileprivate var oneRosaryComplete: Bool {
        viewModel.isPrayingAloud && viewModel.spokenFailure == nil
            ? viewModel.isSpokenFinished
            : viewModel.isLastBeadOfRosary
    }

    /// The words at one size for every prayer, the Creed as the Glory Be
    /// Whether the prayer's words and the beads are shown (the player's
    /// Aa); the pill and the prayer's name always are
    fileprivate var showsWordsAndBeads: Bool { userSettings.rosaryShowsWordsAndBeads }

    fileprivate var wordsSize: CGFloat { SimpleRosary.wordsSize(scale: userSettings.textSizeScale) }

    /// The beginner's path: the line for the hand's place, from the
    /// guide; never on the chaplet, which has none
    fileprivate var oneRosaryHelp: RosaryHelps.Line? {
        guard showsHelps, viewModel.spokenPendant == nil || viewModel.helpsPendantStep != nil,
              let category = meditationSet.mysteryCategory
        else { return nil }
        return RosaryHelps.line(
            for: category,
            pendantStep: viewModel.helpsPendantStep,
            mystery: viewModel.currentMysteryIndex,
            bead: viewModel.currentBeadIndex
        )
    }

    /// The voice is announcing the mystery, before its Our Father
    private var isAnnouncing: Bool {
        viewModel.spoken?.currentSegment?.kind == .announcement
    }

    /// The timed lines of what the voice is saying, where it is the words
    /// the column sets: never an announcement's
    fileprivate var shownTimings: [TimedLine]? {
        guard let segment = viewModel.spoken?.currentSegment, segment.kind != .announcement else { return nil }
        // The recordings are English: in Spanish a prayer, or a
        // meditation translated into Spanish, is shown in its Spanish
        // words, unlit, never swapped for the English lines
        if SimpleRosary.keepsOwnWords(
            segment.kind, spanish: SpanishContent.isActive,
            meditationIsSpanish: viewModel.currentMeditation?.isSpanish ?? false
        ) { return nil }
        return viewModel.spokenTimings
    }

    fileprivate var oneRosaryLayer: some View {
        GeometryReader { geometry in
            let fullHeight = geometry.size.height
                + geometry.safeAreaInsets.top
                + geometry.safeAreaInsets.bottom
            let rail = rail
            // The words' first line at one height on every step; the head
            // stands in its room above them
            let columnTop = max(
                OneRosaryColumn<EmptyView>.wordsTop(fullHeight: fullHeight)
                    - OneRosaryColumn<EmptyView>.headHeight
                    - geometry.safeAreaInsets.top,
                12 + 44 + 14
            )

            VStack(spacing: 0) {
                let placed = OneRosaryColumn<EmptyView>.layout(
                    showsWords: showsWordsAndBeads, columnTop: columnTop, headerFoot: 12 + 44 + 14)
                oneRosaryColumn
                    .announcesRosaryPlace(spokenPlace)
                    .padding(.leading, 28)
                    .padding(.trailing, 104)
                    .padding(.top, placed.top)
                    .padding(.bottom, placed.bottom)
                    .frame(maxHeight: .infinity, alignment: placed.alignment)
                    .animation(Motion.crossfade, value: showsWordsAndBeads)

                oneRosaryFoot
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsHeight = $0 }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                OneRosaryHeader(onClose: { router.popToRoot() }) {
                    RosaryStopsPill(
                        stops: viewModel.stops,
                        current: viewModel.currentStop,
                        isChaplet: meditationSet.mysteryCategory == .sevenSorrows
                    ) { activeSheet = .stops }
                } trailing: {
                    if viewModel.isPrayingAloud, viewModel.spokenFailure == nil {
                        SimpleRosaryMuteButton(isMuted: viewModel.isMuted) { viewModel.toggleMuted() }
                    }
                }
                .padding(.top, 12)
            }
            .oneRosaryRail(
                rail,
                activeIndex: railIndex(rail),
                fullHeight: fullHeight,
                topInset: geometry.safeAreaInsets.top,
                turnPulse: turnPulse,
                locked: viewModel.pendant == nil && !viewModel.beadsUnlocked,
                tappable: tappableBeads(rail),
                hintPulse: tapHintPulse,
                complete: oneRosaryComplete,
                closing: oneRosaryOnClose,
                hidden: !showsWordsAndBeads
            ) { index in
                if case .strand(let bead) = rail.target(at: index) { oneRosaryGoToBead(bead) }
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .background {
                ZStack {
                    // One stage on every step: the mystery's painting. On
                    // the opening and closing prayers it is the first (or
                    // last) mystery's, veiled deeper, and the pendant they
                    // are said on is the rail's alone, at its head: one
                    // cross, drawn once
                    PrayerPaintingStage(
                        painting: painting,
                        seatedFraction: OneRosaryColumn<EmptyView>.paintingFraction,
                        paintingID: viewModel.currentMysteryIndex,
                        chromeHidden: chromeHidden,
                        quiet: !showsWordsAndBeads,
                        width: geometry.size.width,
                        fullHeight: fullHeight
                    ) {
                        toggleChrome()
                    }
                    .transition(.opacity)

                    OneRosaryPendantVeil()
                        .opacity(viewModel.pendant != nil && !chromeHidden ? (showsWordsAndBeads ? 1 : 0.45) : 0)

                    // The words put away, the painting shows: a light
                    // shade for what remains in place of the column's
                    OneRosaryColumnScrim()
                        .opacity(chromeHidden || !showsWordsAndBeads ? 0 : 1)
                    OneRosaryQuietScrim()
                        .opacity(!chromeHidden && !showsWordsAndBeads ? 1 : 0)
                }
                .animation(Motion.decadeTurn, value: viewModel.pendant == nil)
                .animation(Motion.crossfade, value: showsWordsAndBeads)
            }
        }
    }

    /// Where the hand is, as VoiceOver is told when the voice moves it on
    private var spokenPlace: String {
        if let pendant = viewModel.pendant {
            return RosaryPlace.spoken(
                title: pendant.heading,
                bead: OneRosaryColumn<EmptyView>.pendantLabel(pendant, count: viewModel.silentPendantCount))
        }
        let title = viewModel.currentMystery?.name ?? viewModel.currentMeditation?.displayTitle ?? ""
        return RosaryPlace.spoken(title: title, bead: viewModel.beadLabel)
    }

    /// The column: where on the Rosary, the title, the bead, the words
    @ViewBuilder
    fileprivate var oneRosaryColumn: some View {
        if let pendant = viewModel.pendant {
            let lines = SilentPendant.lines(of: pendant.prayerID, in: userSettings.prayerLanguage)
            OneRosaryColumn(
                title: pendant.heading,
                place: OneRosaryColumn<EmptyView>.place(mystery: nil, of: viewModel.strand.decades, phase: pendant.phase),
                bead: OneRosaryColumn<EmptyView>.pendantLabel(pendant, count: viewModel.silentPendantCount),
                help: oneRosaryHelp,
                wordsKey: "\(pendant.heading)|\(pendant.title)|\(viewModel.silentPendantCount ?? "")",
                showsWords: showsWordsAndBeads
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    SpokenRosaryWords(
                        lines: SimpleRosary.displayedLines(timings: shownTimings, fallback: lines),
                        timed: shownTimings != nil,
                        highlighted: { viewModel.spokenHighlightedLine },
                        lineProgress: { viewModel.spokenLineProgress },
                        size: wordsSize
                    )
                    AITranslationNote(prayerID: pendant.prayerID)
                }
            }
            .accessibilityElement(children: .combine)
        } else {
            let locked = beadsLocked
            OneRosaryColumn(
                title: viewModel.currentMystery?.name ?? viewModel.currentMeditation?.displayTitle ?? "",
                place: OneRosaryColumn<EmptyView>.place(mystery: viewModel.currentMysteryIndex, of: viewModel.strand.decades),
                // The step line names the bead even while it waits; the
                // words under it say why
                bead: viewModel.beadLabel,
                help: oneRosaryHelp,
                tapHint: tapHintShowing && showsWordsAndBeads,
                wordsKey: "\(viewModel.beadPosition.mystery).\(viewModel.beadPosition.bead).\(locked).\(viewModel.isSpeakingMeditation).\(isAnnouncing)",
                showsWords: showsWordsAndBeads
            ) {
                if locked {
                    Text(
                        "The meditation is read first. The beads open when it ends.",
                        comment: "One Rosary beta, the player on a mystery's Our Father before its meditation has been heard: why the beads wait"
                    )
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                } else if viewModel.isSpeakingMeditation, let meditation = viewModel.currentMeditation {
                    // The meditation as it is read: its recording's own
                    // lines where it is timed, lit as they are said
                    SpokenRosaryWords(
                        lines: SimpleRosary.displayedLines(
                            timings: shownTimings,
                            fallback: ReadingText.paragraphs(of: meditation.content)),
                        timed: shownTimings != nil,
                        highlighted: { viewModel.spokenHighlightedLine },
                        lineProgress: { viewModel.spokenLineProgress },
                        size: wordsSize
                    )
                } else if isAnnouncing {
                    SimpleRosaryWords(
                        lines: SimpleRosary.announcementLines(
                            category: meditationSet.mysteryCategory,
                            ordinal: viewModel.currentMysteryIndex + 1,
                            name: viewModel.currentMystery?.name),
                        highlighted: nil,
                        lineProgress: nil,
                        size: wordsSize
                    )
                } else {
                    SpokenRosaryWords(
                        lines: SimpleRosary.displayedLines(timings: shownTimings, fallback: viewModel.beadLines),
                        timed: shownTimings != nil,
                        highlighted: { viewModel.spokenHighlightedLine },
                        lineProgress: { viewModel.spokenLineProgress },
                        size: wordsSize
                    )
                }
            }
            .accessibilityElement(children: .combine)
            // The footer's Next and Back: said aloud, they step the
            // voice a prayer, where prayForward moved the bead alone
            .accessibilityAction(named: "Next bead") { oneRosaryStep(forward: true) }
            .accessibilityAction(named: "Previous bead") { oneRosaryStep(forward: false) }
        }
    }

    /// The foot: what is narrated, the narration's transport, Back and
    /// Next, and the utility row — the same on every step
    fileprivate var oneRosaryFoot: some View {
        let aloud = viewModel.isPrayingAloud
        let meditation = viewModel.pendant == nil ? viewModel.currentMeditation : nil

        return VStack(spacing: 0) {
            if let errorMessage = viewModel.audioErrorMessage, viewModel.pendant == nil {
                Text(errorMessage)
                    .font(AppFonts.bodyFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 4)
            }

            spokenLine

            // The voice's play and pause stands between Back and Next,
            // in one place on every step
            OneRosaryFooter(
                canGoBack: aloud ? viewModel.spokenStatus == nil : !viewModel.isFirstBeadOfRosary,
                canGoOn: aloud
                    ? viewModel.spokenStatus == nil && !viewModel.isSpokenFinished
                    : !beadsLocked && !voiceHoldsStrand,
                // Said aloud, AMEN once the voice has said the last Amen;
                // until then Next steps the closing prayers
                isLast: oneRosaryComplete,
                amenBeckons: viewModel.isSpokenFinished,
                play: oneRosaryPlay(meditation: meditation),
                onBack: { oneRosaryStep(forward: false) },
                onNext: { oneRosaryStep(forward: true) },
                onAmen: finishRosary
            )
            .padding(.horizontal, 22)
            .padding(.top, 16)

            // The meditation's door, under Back and Next (Abraham, 10 Nov:
            // "read the meditation button below the back"), shown on the
            // step it belongs to: the mystery's Our Father, where it is
            // heard. Its line is kept on every step, so Back, the play and
            // Next never move under the thumb when it comes and goes.
            let showsReadLink = meditation != nil && viewModel.currentBeadIndex == 0
            OneRosaryReadLink { withAnimation(Motion.panel) { simpleReaderOpen = true } }
                .opacity(showsReadLink ? 1 : 0)
                .allowsHitTesting(showsReadLink)
                .accessibilityHidden(!showsReadLink)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.top, 12)

            // The same three on every step and on both players
            OneRosaryUtilityRow(items: [
                OneRosaryUtilityRow.voice { activeSheet = .playback },
                OneRosaryUtilityRow.text { activeSheet = .text },
                OneRosaryUtilityRow.more { activeSheet = .tray },
            ])
            .padding(.top, 2)
            .padding(.bottom, 8)
        }
        .animation(Motion.crossfade, value: meditation?.hasAudio)
        .animation(Motion.crossfade, value: viewModel.currentBeadIndex == 0)
    }

    /// The voice's play and pause in the footer: said aloud, the voice's,
    /// on every step; otherwise the meditation's, on its Our Father, where
    /// it is heard, and on any bead while it still sounds. Heard to its
    /// end, it offers to hear the meditation again from its start.
    fileprivate func oneRosaryPlay(meditation: Meditation?) -> OneRosaryPlayDisc? {
        if viewModel.isPrayingAloud {
            guard viewModel.spokenFailure == nil else { return nil }
            return OneRosaryPlayDisc(
                glyph: viewModel.isPlaying ? .pause : .play,
                isLoading: viewModel.spokenStatus != nil,
                isEnabled: !viewModel.isSpokenFinished
            ) {
                viewModel.isPlaying.toggle()
            }
        }
        guard meditation?.hasAudio == true,
            viewModel.currentBeadIndex == 0 || viewModel.isPlaying
        else { return nil }
        let total = viewModel.totalDuration
        let ended = !viewModel.isPlaying && total > 0 && viewModel.currentTime >= total - 0.75
        return OneRosaryPlayDisc(
            glyph: viewModel.isPlaying ? .pause : (ended ? .replay : .play),
            isLoading: viewModel.isLoadingAudio,
            isEnabled: transportReady
        ) {
            if ended { viewModel.currentTime = 0 }
            viewModel.isPlaying.toggle()
        }
    }

    /// Back and Next: a bead (or a prayer of the pendant) at a time, and
    /// said aloud, a prayer of the voice at a time
    fileprivate func oneRosaryStep(forward: Bool) {
        if viewModel.isPrayingAloud {
            travel = forward ? .forward : .back
            viewModel.stepSpokenPrayer(forward: forward)
        } else if forward {
            prayForward()
        } else {
            prayBack()
        }
    }

    /// A tap on a bead of the rail: the hand taken there
    fileprivate func oneRosaryGoToBead(_ index: Int) {
        guard !voiceHoldsStrand else { return }
        if beadsLocked, index > viewModel.strandIndex { return }
        travel = index > viewModel.strandIndex ? .forward : .back
        withAnimation(reduceMotion ? nil : Motion.beadSlide) {
            viewModel.goToBead(at: index)
        }
    }
}

// MARK: - PlayerSheet

/// What the player can put over itself. One case at a time, by design.
private enum PlayerSheet: String, Identifiable {
    case journal
    case playback
    case tray
    case feedback
    /// The text's size, as the Scriptural player has it
    case text
    /// The simple Rosary: every part of the Rosary, to go to
    case stops

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
