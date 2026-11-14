//
//  ScripturalRosaryPrayerView.swift
//  Lumen Viae
//
//  The Scriptural Rosary and the Audio Rosary prayed, on the one player
//  every form of the Rosary shares (`MysteryPrayerView` is a meditation
//  set's): every prayer said aloud from the moment PRAY is pressed,
//  play and pause between Back and Next, the beads at the right edge
//  (tapped, never needing to be), a pill at the head to go to any part
//  and a speaker to mute the voice while the Rosary goes on at the
//  recording's own pace. The Scriptural Rosary sets a verse for each
//  Hail Mary; the Audio Rosary sets the prayer being said. Words are lit
//  only from a recording's real timings (`SimpleRosary`).
//
//  When the recordings cannot be had it is still a Rosary: the notice
//  says why, and the beads are prayed from the page in silence.
//  Finishing is always a deliberate tap on AMEN.
//
//  Abraham, Nov 2026: "Yes, only Rosary". The screen it replaced (a
//  strand to swipe, or a mystery at a time, chosen by Audio and
//  Counting) is gone.
//

import SwiftUI

struct ScripturalRosaryPrayerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.phoneTypeSize) private var phoneTypeSize

    /// The player follows the phone's Larger Text past the app's cap, to
    /// `playerMaximum` (Abraham's yes, 10 Nov: "Yes, build it"); at the
    /// accessibility sizes it makes room for the larger words
    private var playerIsLarge: Bool { min(phoneTypeSize, .playerMaximum).isAccessibilitySize }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ScripturalRosaryViewModel

    /// The one sheet this screen presents at a time.
    @State private var activeSheet: ScripturalSheet?

    /// An act the ⋯ tray asked for, run once the tray is actually gone.
    /// Sequenced on `onDismiss` rather than a timer: presenting into a
    /// dismissal drops the new presentation.
    @State private var pendingHandoff: (() -> Void)?

    /// True while a tap on the artwork has cleared the chrome
    @State private var chromeHidden = false

    /// Which way the hand last moved, so the words arrive from the side
    /// the string came from
    @State private var travel: BeadTravel = .forward

    /// Bumped each time the decade turns; the strand's ripple answers
    @State private var turnPulse = 0

    /// Bumped each time the hand steps the voice a prayer on or back on
    /// the pendant, where no bead of the strand moves to be felt
    @State private var prayerStepPulse = 0

    /// When the devotion originally began (carried through resumes for
    /// snapshot continuity; never used for duration)
    private let sessionStartedAt: Date

    init(launch: ScripturalRosaryLaunch) {
        self.sessionStartedAt = launch.startedAt
        self._viewModel = State(initialValue: ScripturalRosaryViewModel(
            category: launch.category,
            form: launch.form,
            startAtIndex: launch.startIndex,
            startAtBead: launch.startBead,
            priorSeconds: launch.priorSeconds
        ))
    }

    var body: some View {
        oneRosaryLayer
            .followsPhoneTypeSize(upTo: .playerMaximum)
        // A background rather than a bottom layer in the stack: a sibling
        // that ignores the safe area takes the safe area away from every
        // other sibling, and the chrome has to sit above the home indicator
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        // One haptic for one move, keyed on the mystery and the bead
        // together: stepping across a decade's end changes both at once,
        // and two modifiers would tick twice in one frame — a stumble on
        // the app's quietest screen. The decade turning lands heavier
        // than a bead.
        .sensoryFeedback(trigger: viewModel.beadPosition) { old, new in
            if new.mystery != old.mystery { return .impact(weight: .medium) }
            return .selection
        }
        // A prayer stepped on the pendant ticks as a bead does
        .sensoryFeedback(.selection, trigger: prayerStepPulse)
        // A bead prayed is a place to come back to, the same as a decade
        .onChange(of: viewModel.beadPosition, initial: true) { saveResumePosition() }
        // The decade turning, which the strand marks with a ripple
        .onChange(of: viewModel.currentMysteryIndex) { turnPulse += 1 }
        // The whole Rosary said aloud, or not: on arrival, and whenever
        // the speaker here or Settings turns it on or off. The Rosary
        // Aloud is said aloud whatever the setting
        .task(id: aloudWanted) {
            // With the phone locked the view does not re-evaluate, so a
            // decade the voice moved on to reports back here to be kept
            // as the place to resume. Value copies and a weak model: the
            // View's @State box holds the model that holds this closure.
            viewModel.onMysteryChanged = { [weak viewModel, sessionStartedAt] index in
                guard let viewModel else { return }
                PrayerResumeService.shared.save(
                    kind: viewModel.resumeKind,
                    setId: 0,
                    setName: viewModel.displayName,
                    category: viewModel.category.rawValue,
                    mysteryIndex: index,
                    beadIndex: viewModel.currentBeadIndex,
                    startedAt: sessionStartedAt,
                    accumulatedSeconds: viewModel.sessionDuration
                )
            }
            await viewModel.setPrayAloud(aloudWanted)
        }
        // Another voice chosen — in Settings, or from the notice when this
        // one has not been recorded: the Rosary carries on in it, paused
        // if it was paused
        .onChange(of: userSettings.narrationVoiceSlug) {
            guard viewModel.isPrayingAloud else { return }
            Task { await viewModel.restartSpoken() }
        }
        // The last Amen said aloud: felt in the pocket, as the glowing
        // AMEN is seen on the screen
        .sensoryFeedback(.success, trigger: viewModel.isSpokenFinished) { old, new in !old && new }
        // The chrome comes back on its own where it is needed: when the
        // pendant takes the painting's place — the ground that was tapped
        // to clear it is gone — and when the Rosary reaches its end, where
        // AMEN is the one thing left to do
        .onChange(of: viewModel.spokenPendant == nil) { _, noPendant in
            if !noPendant { showChrome() }
        }
        .onChange(of: viewModel.isSpokenFinished) { _, finished in
            if finished { showChrome() }
        }
        .onChange(of: viewModel.isLastBeadOfRosary) { _, last in
            if last { showChrome() }
        }
        // Leaving the Rosary must not leave it being said over other screens
        .onDisappear {
            viewModel.stopSpeaking()
        }
        // Exactly one `.sheet` on this view — two stacked here would have
        // SwiftUI honor one and silently drop the rest.
        .sheet(item: $activeSheet, onDismiss: runPendingHandoff) { sheet in
            switch sheet {
            case .journal:
                JournalEntryEditorView(
                    category: viewModel.category,
                    mysteryTitle: viewModel.currentMystery?.name,
                    mysteryIndex: viewModel.currentMysteryIndex,
                    isMidPrayer: true
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
                    // At the accessibility sizes its rows outgrow the
                    // measured height, so it opens full
                    .presentationDetents(playerIsLarge ? [.large] : [
                        .height(ReaderTextOptionsSheet.height(
                            showsNarrationOptions: false,
                            showsPartsToggle: true))
                    ])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.playerMaximum)

            case .playback:
                PlaybackSettingsSheet()
                    .presentationDetents(PlaybackSettingsSheet.detents(for: min(phoneTypeSize, .playerMaximum)))
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.playerMaximum)

            case .feedback:
                FeedbackView(
                    context: trackActions.feedbackContext,
                    initialTopic: .meditations
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .stops:
                RosaryStopsSheet(
                    title: viewModel.displayName,
                    stops: viewModel.stops,
                    current: viewModel.currentStop,
                    mysteryNames: MysteryData.mysteries(for: viewModel.category).map(\.name),
                    isChaplet: viewModel.category == .sevenSorrows
                ) { stop in
                    travel = .forward
                    viewModel.jump(to: stop)
                }
                .dynamicTypeSize(...DynamicTypeSize.playerMaximum)

            case .tray:
                PrayerTrackTray(
                    actions: trackActions,
                    placement: .player,
                    pendingHandoff: $pendingHandoff
                )
                // The tray opens as tall as it measures (`fittedSheetDetent`)
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.playerMaximum)
            }
        }
    }

    // MARK: - The Painting

    /// The mystery's own painting, the one the meditation's player shows
    /// for the same mystery.
    private var painting: PrayerPainting? {
        // A closure, not the bare `PrayerPainting.bundled` reference —
        // see the meditation player for why
        Constants.mysteryImageURL(
            category: viewModel.category.rawValue,
            index: viewModel.currentMysteryIndex
        ).flatMap { PrayerPainting.bundled($0) }
    }

    /// What the ⋯ tray can do here. The player's own tray, given a
    /// devotion with no narration: it offers a reflection, feedback and
    /// a share, and never a download of silence.
    private var trackActions: PrayerTrackActions {
        let mysteryName = viewModel.currentMystery?.name ?? viewModel.mysteryKicker
        let reading = viewModel.reading
        return PrayerTrackActions(
            meditationId: 0,
            audioURL: nil,
            // No narration, so no voice is heard here; the chosen one is
            // the honest answer to "which voice", and nothing reads it
            // while `audioURL` is nil - the tray offers no download.
            voice: NarrationVoiceCatalog.shared.chosenSlug,
            // The words on screen, for a friend, with the app's link
            shareText: viewModel.isPlain
                ? ShareText.compose(title: viewModel.displayName, body: mysteryName, byline: nil)
                : ShareText.compose(title: mysteryName, body: reading.text, byline: reading.reference),
            feedbackContext: FeedbackContext(
                meditationTitle: mysteryName,
                setName: viewModel.displayName
            ),
            onAddReflection: { activeSheet = .journal },
            onGiveFeedback: { activeSheet = .feedback },
            onEndSession: { router.popToRoot() }
        )
    }

    // MARK: - Gestures

    /// Whether every prayer is said aloud: always, on every form
    private var aloudWanted: Bool {
        SimpleRosary.praysAloud(form: RosaryForm(viewModel.form))
    }

    /// Whether the beads are held still: while the recordings are being
    /// fetched before the voice begins, when a move would be taken back
    /// the moment the voice began.
    private var beadsHeld: Bool {
        viewModel.spokenStatus != nil
    }

    /// Whether a move is a prayer rather than a bead: while the voice is
    /// on the pendant — the opening prayers, the closing, and the cross
    /// the Rosary ends on. The pendant is not on the strand, so there is
    /// no bead to move the hand to; the swipe, the tap and the rotor step
    /// the voice one prayer on or back instead. The beads were once held
    /// still here, and the Creed and the pendant's prayers — two minutes
    /// of every Rosary said aloud — could be neither passed over by
    /// someone who prays them daily nor said again after a knock at the
    /// door.
    private var movesByPrayer: Bool {
        viewModel.spokenPendant != nil
    }

    // MARK: - The Reading

    /// The room the words are given at the right: the strand's beads
    /// and their numerals take the edge, and the words stop short of
    /// them. Measured from the glass, as the strand is.

    /// The words' size follows the Prayer Experience text size the Aa
    /// sets, a point above the reading size. Set in the Medium face:
    /// the italic thinned to hairlines over the painting, and a verse
    /// read at arm's length over a picture needs its weight.
    private var verseSize: CGFloat {
        userSettings.meditationFontSize + 1
    }

    /// The Rosary Aloud's prayers are longer than any verse — the Our
    /// Father runs to ten lines at the verse's size — so they are set a
    /// size down at a closer leading, and still read at arm's length
    private var wordsSize: CGFloat {
        viewModel.isPlain ? verseSize - 2 : verseSize
    }

    /// Which prayer of the pendant is shown: the two Signs of the Cross,
    /// the three Hail Marys and the Holy Father's three prayers each told
    /// apart, so the words crossfade at every step
    private static func pendantKey(_ pendant: SpokenPendant) -> String {
        "\(pendant.heading)|\(pendant.title)|\(pendant.prayerID)"
    }

    // MARK: - Helper Functions

    /// One bead forward along the strand. The swipe, the tap and the
    /// rotor all come here; a `false` at the end of the Rosary is left
    /// alone, because only AMEN finishes it. On the pendant, and on the
    /// last bead while the voice has the closing prayers still to say,
    /// it is the next prayer instead.
    private func prayForward() {
        guard !beadsHeld else { return }
        if movesByPrayer || viewModel.canStepOnIntoClosing {
            stepPrayer(forward: true)
            return
        }
        guard !viewModel.isLastBeadOfRosary else { return }
        travel = .forward
        withAnimation(reduceMotion ? nil : Motion.beadSlide) {
            _ = viewModel.prayForward()
        }
    }

    /// One bead back along the strand, into the previous decade if the
    /// hand is on an Our Father. On the first bead the string only
    /// settles — unless the voice is saying the first decade, when it
    /// goes back into the opening prayers, one prayer at a time.
    private func prayBack() {
        guard !beadsHeld else { return }
        if movesByPrayer || viewModel.canStepBackIntoOpening {
            stepPrayer(forward: false)
            return
        }
        guard !viewModel.isFirstBeadOfRosary else { return }
        travel = .back
        withAnimation(reduceMotion ? nil : Motion.beadSlide) {
            viewModel.prayBack()
        }
    }

    /// One prayer on or back, said by the voice from its first word: the
    /// move on the pendant, where the strand has no bead to give
    private func stepPrayer(forward: Bool) {
        travel = forward ? .forward : .back
        let moved = withAnimation(Motion.words) {
            viewModel.stepSpokenPrayer(forward: forward)
        }
        if moved { prayerStepPulse += 1 }
    }

    /// A tap on the ground — the painting, or the pendant in its place —
    /// clears the chrome for contemplation, or brings it back
    private func toggleChrome() {
        withAnimation(Motion.chrome) { chromeHidden.toggle() }
    }

    private func showChrome() {
        guard chromeHidden else { return }
        withAnimation(Motion.chrome) { chromeHidden = false }
    }

    /// Runs whatever the tray handed over, exactly once.
    private func runPendingHandoff() {
        let action = pendingHandoff
        pendingHandoff = nil
        action?()
    }

    /// Remembers the position so an interrupted Rosary can resume. Only
    /// once the user has actually advanced — a decade or a bead —
    /// opening the first mystery and backing out must neither pin a
    /// resume card nor overwrite a genuinely interrupted session.
    private func saveResumePosition(evenAtTheStart: Bool = false) {
        let mystery = viewModel.currentMysteryIndex
        let bead = viewModel.currentBeadIndex
        guard mystery > 0 || bead > 0 || evenAtTheStart else { return }
        PrayerResumeService.shared.save(
            kind: viewModel.resumeKind,
            setId: 0,
            setName: viewModel.displayName,
            category: viewModel.category.rawValue,
            mysteryIndex: mystery,
            beadIndex: bead,
            startedAt: sessionStartedAt,
            accumulatedSeconds: viewModel.sessionDuration
        )
    }

    /// Completed all mysteries — the record is local only; there is no
    /// set on the server to credit.
    private func finishRosary() {
        PrayerResumeService.shared.clear()
        router.navigateToCompletion(CompletedPrayer(
            category: viewModel.category,
            devotionName: viewModel.devotionName,
            durationSeconds: viewModel.sessionDuration
        ))
    }
}

// MARK: - The Player

/// The Scriptural and Audio Rosaries pray on
/// the meditation's player (`MysteryPrayerView`'s beta layer): the same
/// rail at the same place, the same column with the verse as its words,
/// Back and Next at the foot, and the same row of the voice's sheet, the
/// text's and the ⋯ beneath. Off, nothing here is drawn.
extension ScripturalRosaryPrayerView {

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

    fileprivate func tappableBeads(_ rail: OneRosaryRail) -> Set<Int> {
        guard viewModel.spokenPendant == nil, !beadsHeld else { return [] }
        let strand = viewModel.strand
        let active = viewModel.strandIndex
        let near = max(active - 4, 0)...min(active + 4, strand.count - 1)
        return Set(
            near.filter { strand.canTap($0, from: active, onGloryBe: viewModel.isDecadePrayed) }
                .map { rail.index(strandIndex: $0) })
    }

    /// The words at one size for every prayer, the Creed as the Glory Be
    /// Whether the prayer's words and the beads are shown (the player's
    /// Aa); the pill and the prayer's name always are
    fileprivate var showsWordsAndBeads: Bool { userSettings.rosaryShowsWordsAndBeads }

    fileprivate var simpleWordsSize: CGFloat { SimpleRosary.wordsSize(scale: userSettings.textSizeScale) }

    /// The voice is announcing the mystery, before its Our Father
    private var isAnnouncing: Bool {
        viewModel.spoken?.currentSegment?.kind == .announcement
    }

    /// The timed lines of what the voice is saying, where it is the words
    /// the column sets: never an announcement's
    fileprivate var shownTimings: [TimedLine]? {
        guard let segment = viewModel.spoken?.currentSegment, segment.kind != .announcement else { return nil }
        // The recordings are English: in Spanish a prayer is shown in
        // its Spanish words, unlit, never swapped for the English lines
        if SimpleRosary.keepsOwnWords(segment.kind, spanish: SpanishContent.isActive) { return nil }
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
                OneRosaryColumn<EmptyView>.wordsTop(fullHeight: fullHeight, large: playerIsLarge)
                    - OneRosaryColumn<EmptyView>.headHeight(large: playerIsLarge)
                    - geometry.safeAreaInsets.top,
                12 + 44 + 14
            )

            VStack(spacing: 0) {
                let placed = OneRosaryColumn<EmptyView>.layout(
                    showsWords: showsWordsAndBeads, columnTop: columnTop, headerFoot: 12 + 44 + 14)
                oneRosaryColumn
                    .announcesRosaryPlace(spokenPlace)
                    .padding(.leading, 28)
                    .padding(.trailing, OneRosaryColumn<EmptyView>.trailingInset(large: playerIsLarge))
                    .padding(.top, placed.top)
                    .padding(.bottom, placed.bottom)
                    .frame(maxHeight: .infinity, alignment: placed.alignment)
                    .animation(Motion.crossfade, value: showsWordsAndBeads)

                oneRosaryFoot
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                oneRosaryHeader
                    .padding(.top, 12)
            }
            .oneRosaryRail(
                rail,
                activeIndex: railIndex(rail),
                fullHeight: fullHeight,
                topInset: geometry.safeAreaInsets.top,
                turnPulse: turnPulse,
                tappable: tappableBeads(rail),
                complete: oneRosaryComplete,
                closing: oneRosaryOnClose,
                hidden: !showsWordsAndBeads,
                large: playerIsLarge
            ) { index in
                if case .strand(let bead) = rail.target(at: index) { goToBead(bead) }
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .background {
                ZStack {
                    // As the meditation's player: the painting on every
                    // step, veiled deeper on the pendant, whose cross is
                    // the rail's alone
                    PrayerPaintingStage(
                        painting: painting,
                        seatedFraction: OneRosaryColumn<EmptyView>.paintingFraction(large: playerIsLarge),
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
                        .opacity(viewModel.spokenPendant != nil && !chromeHidden ? (showsWordsAndBeads ? 1 : 0.45) : 0)

                    // The words put away, the painting shows: a light
                    // shade for what remains in place of the column's
                    OneRosaryColumnScrim()
                        .opacity(chromeHidden || !showsWordsAndBeads ? 0 : 1)
                    OneRosaryQuietScrim()
                        .opacity(!chromeHidden && !showsWordsAndBeads ? 1 : 0)
                }
                .animation(Motion.decadeTurn, value: viewModel.spokenPendant == nil)
                .animation(Motion.crossfade, value: showsWordsAndBeads)
            }
        }
    }

    /// The way out
    fileprivate var oneRosaryHeader: some View {
        OneRosaryHeader(onClose: { router.popToRoot() }) {
            RosaryStopsPill(
                stops: viewModel.stops,
                current: viewModel.currentStop,
                isChaplet: viewModel.category == .sevenSorrows
            ) { activeSheet = .stops }
        } trailing: {
            if viewModel.isPrayingAloud, viewModel.spokenFailure == nil {
                SimpleRosaryMuteButton(isMuted: viewModel.isMuted) { viewModel.toggleMuted() }
            }
        }
    }

    /// The hand on the closing prayers, back at the medal or the cross
    fileprivate var oneRosaryOnClose: Bool {
        if case .closing = viewModel.currentPendantStep { return true }
        return viewModel.spokenPendant?.phase == .closing
    }

    /// The last step, the whole Rosary prayed
    fileprivate var oneRosaryComplete: Bool {
        viewModel.isPrayingAloud && viewModel.spokenFailure == nil
            ? viewModel.isSpokenFinished
            : viewModel.isLastBeadOfRosary
    }

    /// Where the hand is, as VoiceOver is told when the voice moves it on
    private var spokenPlace: String {
        if let pendant = viewModel.spokenPendant {
            return RosaryPlace.spoken(
                title: pendant.heading,
                bead: OneRosaryColumn<EmptyView>.pendantLabel(pendant, count: viewModel.silentPendantCount))
        }
        return RosaryPlace.spoken(title: viewModel.currentMystery?.name ?? "", bead: viewModel.beadLabel)
    }

    @ViewBuilder
    fileprivate var oneRosaryColumn: some View {
        if let pendant = viewModel.spokenPendant {
            let lines = SilentPendant.lines(of: pendant.prayerID, in: userSettings.prayerLanguage)
            OneRosaryColumn(
                title: pendant.heading,
                place: OneRosaryColumn<EmptyView>.place(mystery: nil, of: viewModel.strand.decades, phase: pendant.phase),
                bead: OneRosaryColumn<EmptyView>.pendantLabel(pendant, count: viewModel.silentPendantCount),
                wordsKey: Self.pendantKey(pendant) + (viewModel.silentPendantCount ?? ""),
                showsWords: showsWordsAndBeads
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    SpokenRosaryWords(
                        lines: SimpleRosary.displayedLines(timings: shownTimings, fallback: lines),
                        timed: shownTimings != nil,
                        highlighted: { viewModel.spokenHighlightedLine },
                        lineProgress: { viewModel.spokenLineProgress },
                        size: simpleWordsSize
                    )
                    AITranslationNote(prayerID: pendant.prayerID)
                }
            }
            .accessibilityElement(children: .combine)
        } else {
            let reading = viewModel.reading
            OneRosaryColumn(
                title: viewModel.currentMystery?.name ?? "",
                place: OneRosaryColumn<EmptyView>.place(mystery: viewModel.currentMysteryIndex, of: viewModel.strand.decades),
                bead: viewModel.beadLabel,
                wordsKey: "\(viewModel.beadPosition.mystery).\(viewModel.beadPosition.bead).\(isAnnouncing)",
                showsWords: showsWordsAndBeads
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    SpokenRosaryWords(
                        lines: isAnnouncing
                            ? SimpleRosary.announcementLines(
                                category: viewModel.category,
                                ordinal: viewModel.currentMysteryIndex + 1,
                                name: viewModel.currentMystery?.name)
                            : SimpleRosary.displayedLines(
                                timings: shownTimings,
                                fallback: reading.text.components(separatedBy: "\n")
                                    + (reading.closingPrayer.map { [$0] } ?? [])),
                        timed: shownTimings != nil,
                        highlighted: { viewModel.spokenHighlightedLine },
                        lineProgress: { viewModel.spokenLineProgress },
                        size: simpleWordsSize
                    )
                    if !isAnnouncing, let reference = reading.reference {
                        Text(reference.uppercased())
                            .font(AppFonts.labelFont(12))
                            .tracking(1.5)
                            .foregroundColor(AppColors.goldLight)
                            .lineLimit(1)
                    }
                    if !isAnnouncing, let footnote = reading.footnote {
                        Text(footnote.uppercased())
                            .font(AppFonts.labelFont(12))
                            .tracking(1.5)
                            .foregroundColor(AppColors.cream.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAction(named: "Next bead", prayForward)
            .accessibilityAction(named: "Previous bead", prayBack)
        }
    }

    fileprivate var oneRosaryFoot: some View {
        let aloud = viewModel.isPrayingAloud
        return VStack(spacing: 0) {
            if aloud {
                if let failure = viewModel.spokenFailure {
                    SpokenRosaryNotice(failure: failure) {
                        Task { await viewModel.restartSpoken() }
                    }
                    .transition(.opacity)
                } else {
                    if let status = viewModel.spokenStatus {
                        Text(status.uppercased())
                            .font(AppFonts.labelFont(12))
                            .tracking(2)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.bottom, 8)
                    }
                }
            }

            OneRosaryFooter(
                canGoBack: !beadsHeld
                    && (!viewModel.isFirstBeadOfRosary || viewModel.canStepBackIntoOpening
                        || (aloud && viewModel.spokenPendant != nil)),
                canGoOn: !beadsHeld && !viewModel.isSpokenFinished,
                isLast: oneRosaryComplete,
                amenBeckons: viewModel.isSpokenFinished,
                // The voice's play and pause, between Back and Next,
                // while every prayer is said aloud
                play: aloud && viewModel.spokenFailure == nil
                    ? OneRosaryPlayDisc(
                        glyph: viewModel.isSpeaking ? .pause : .play,
                        isLoading: viewModel.spokenStatus != nil,
                        isEnabled: !viewModel.isSpokenFinished
                    ) { viewModel.toggleSpeaking() }
                    : nil,
                onBack: prayBack,
                onNext: prayForward,
                onAmen: finishRosary
            )
            .padding(.horizontal, 22)
            .padding(.top, 16)

            // The meditation's player's row, the same three
            OneRosaryUtilityRow(items: [
                OneRosaryUtilityRow.voice { activeSheet = .playback },
                OneRosaryUtilityRow.text { activeSheet = .text },
                OneRosaryUtilityRow.more { activeSheet = .tray },
            ])
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .animation(Motion.crossfade, value: aloud)
    }

    /// A tap on a bead of the rail: the hand taken there, unless the
    /// recordings are still being fetched
    fileprivate func goToBead(_ index: Int) {
        guard !beadsHeld, !movesByPrayer else { return }
        travel = index > viewModel.strandIndex ? .forward : .back
        withAnimation(reduceMotion ? nil : Motion.beadSlide) {
            viewModel.goToBead(at: index)
        }
    }
}

// MARK: - The Prayer on the Pendant, for VoiceOver

private extension View {

    /// The prayer on the pendant as one element — where it stands, what
    /// it is, and its words — that steps the voice a prayer on or back,
    /// since VoiceOver cannot swipe the pendant. AMEN, beside it on the
    /// closing prayers, stays a button of its own.
    func pendantPrayerElement(label: String, step: @escaping (Bool) -> Void) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint("Double-tap for the next prayer")
            // A double-tap is the sighted tap on the column
            .accessibilityAction { step(true) }
            .accessibilityAction(named: "Next prayer") { step(true) }
            .accessibilityAction(named: "Previous prayer") { step(false) }
    }
}

// MARK: - ScripturalSheet

/// What the screen can put over itself. One case at a time, by design.
private enum ScripturalSheet: String, Identifiable {
    case journal
    case text
    /// The voice, the speed and the Rosary's choices,
    /// as the meditation's player opens them
    case playback
    case tray
    case feedback
    /// The simple Rosary: every part of the Rosary, to go to
    case stops

    var id: String { rawValue }
}

// MARK: - Preview

#Preview {
    ScripturalRosaryPrayerView(launch: ScripturalRosaryLaunch(category: .joyful))
        .environment(AppRouter())
        .environment(UserSettings.shared)
}

#Preview("The Rosary Aloud") {
    ScripturalRosaryPrayerView(launch: ScripturalRosaryLaunch(category: .joyful, form: .plain))
        .environment(AppRouter())
        .environment(UserSettings.shared)
}
