//
//  ScripturalRosaryPrayerView.swift
//  Lumen Viae
//
//  The Scriptural Rosary prayed: a verse of Scripture for every bead,
//  set over the mystery's painting, with the whole Rosary hanging as
//  one strand at the right edge.
//
//  The bead is the unit. Swipe down and the string slides a bead, the
//  next verse taking the last one's place; swipe up and the bead before
//  returns. Our Father beads are larger and carry the decade's numeral,
//  so the next mystery is seen approaching up the string several beads
//  before it arrives, and the turn is simply what happens when that
//  bead comes to hand — the painting and the mystery's name change with
//  it. Nothing else moves the Rosary forward: no arrows, no swipe
//  between mysteries. On the last bead of all the cue gives way to
//  AMEN, and finishing is always that deliberate tap, never a swipe.
//
//  The reading is a column hung beneath the header and anchored there:
//  the bead's name, the mystery's name, and under them the words for
//  the bead, which crossfade in place as one block while everything
//  above them holds still. An earlier draft centred the column on the
//  glass and let each Text change under its own crossfade: a longer
//  verse pushed the whole column up, the lines re-wrapped mid-fade,
//  and the words were unreadable for exactly as long as the animation
//  lasted. Where the Rosary stands is said once, under the beads at
//  the foot; the cue says what to do only where that is news.
//
//  The same stage the meditation's player prays on (`PrayerPaintingStage`,
//  veiled rather than seated, since the words stand over the picture),
//  the same strand, the same rule. What differs is what each bead
//  carries: here, its verse.
//
//  Tapping the painting clears the chrome, verse and all, for
//  contemplation; the way out is the × at the top left, always.
//
//  The Rosary Aloud prays here too (`SpokenForm.plain`): the same
//  screen, said aloud whatever the setting, each bead carrying the
//  prayer being said on it instead of a verse. When the recordings
//  cannot be had it is still a Rosary — the notice says why, and the
//  beads are prayed from the page in silence.
//
//  While the opening prayers are said on the pendant, or the recordings
//  are still being fetched, the beads are held: a swipe there would
//  skip the opening for good, or be undone the moment the voice began.
//

import SwiftUI

struct ScripturalRosaryPrayerView: View {
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var userSettings
    @State private var viewModel: ScripturalRosaryViewModel

    /// The one sheet this screen presents at a time.
    @State private var activeSheet: ScripturalSheet?

    /// An act the ⋯ tray asked for, run once the tray is actually gone.
    /// Sequenced on `onDismiss` rather than a timer: presenting into a
    /// dismissal drops the new presentation.
    @State private var pendingHandoff: (() -> Void)?

    /// True while a tap on the artwork has cleared the chrome
    @State private var chromeHidden = false

    /// How far a swipe under way has drawn the strand, in points. The
    /// string follows the finger, and the verse dims a little as it
    /// goes, so a move is felt before it is made.
    @State private var strandDrag: CGFloat = 0

    /// Whether the drag under way is the strand's — decided once, from
    /// the first movement past the threshold, and held
    @State private var dragArmed: Bool?

    /// Which way the hand last moved, so the words arrive from the side
    /// the string came from
    @State private var travel: BeadTravel = .forward

    /// Bumped each time the decade turns; the strand's ripple answers
    @State private var turnPulse = 0

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
        GeometryReader { geometry in
            let fullHeight = geometry.size.height
                + geometry.safeAreaInsets.top
                + geometry.safeAreaInsets.bottom

            VStack(spacing: 0) {
                // The reading, hung level with the top of the strand's
                // window: the head of the column never moves, and a
                // bead's words change beneath it with nothing further
                // down to shove
                // While the opening or closing prayers are said aloud the
                // column names them, and the pendant hangs below it
                Group {
                    if let pendant = viewModel.spokenPendant {
                        PendantTitleBlock(
                            pendant: pendant,
                            leadsInto: pendant.phase == .opening
                                ? PendantTitleBlock.leadIn(to: viewModel.mysteryKicker)
                                : nil
                        )
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                    } else {
                        readingColumn
                            .transition(.opacity)
                    }
                }
                .padding(.top, readingTop(fullHeight: fullHeight, topInset: geometry.safeAreaInsets.top))
                .animation(Motion.decadeTurn, value: viewModel.spokenPendant == nil)
                // The column is given the glass above the foot and no
                // more, so words too long for it — a prayer at a large
                // text size — can never push the foot off the screen
                .frame(maxHeight: .infinity, alignment: .top)

                foot
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Laid over the column rather than stacked above it, so the
            // column's place is read from the glass alone and never waits
            // on the header being measured
            .overlay(alignment: .top) {
                header
                    .padding(.top, 12)
            }
            .overlay {
                // The Rosary's one strand, hung at the right edge where the
                // meditation's player hangs it too. Inside the chrome layer
                // so it goes with the chrome when the painting is tapped.
                // Not while the opening prayers are said aloud: they are
                // prayed on the pendant, and the strand comes in with the
                // first mystery
                if viewModel.spokenPendant?.phase != .opening {
                Color.clear
                    .rosaryStrand(
                        viewModel.strand,
                        activeIndex: viewModel.strandIndex,
                        fullHeight: fullHeight,
                        topInset: geometry.safeAreaInsets.top,
                        dragOffset: strandDrag,
                        turnPulse: turnPulse
                    )
                    .allowsHitTesting(false)
                }
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .background {
                // The pendant in place of the painting while the opening
                // and closing prayers are said aloud: they are not the
                // mystery's, and its painting arrives with its decade
                ZStack {
                    if let pendant = viewModel.spokenPendant {
                        PendantStage(
                            pendant: pendant,
                            width: geometry.size.width,
                            fullHeight: fullHeight,
                            heightFraction: 0.4,
                            topFraction: 0.355
                        )
                        .transition(.opacity)
                    } else {
                        PrayerPaintingStage(
                            painting: painting,
                            style: .veiled,
                            paintingID: viewModel.currentMysteryIndex,
                            chromeHidden: chromeHidden,
                            width: geometry.size.width,
                            fullHeight: fullHeight
                        ) {
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
        // A background rather than a bottom layer in the stack: a sibling
        // that ignores the safe area takes the safe area away from every
        // other sibling, and the chrome has to sit above the home indicator
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .simultaneousGesture(beadSwipeGesture)
        // One haptic for one move, keyed on the mystery and the bead
        // together: stepping across a decade's end changes both at once,
        // and two modifiers would tick twice in one frame — a stumble on
        // the app's quietest screen. The decade turning lands heavier
        // than a bead.
        .sensoryFeedback(trigger: viewModel.beadPosition) { old, new in
            if new.mystery != old.mystery { return .impact(weight: .medium) }
            return .selection
        }
        // A bead prayed is a place to come back to, the same as a decade
        .onChange(of: viewModel.beadPosition, initial: true) { saveResumePosition() }
        // The decade turning, which the strand marks with a ripple
        .onChange(of: viewModel.currentMysteryIndex) { turnPulse += 1 }
        // The whole Rosary said aloud, or not: on arrival, and whenever
        // the speaker here or Settings turns it on or off. The Rosary
        // Aloud is said aloud whatever the setting
        .task(id: userSettings.prayAloud) {
            // With the phone locked the view does not re-evaluate, so a
            // decade the voice moved on to reports back here to be kept
            // as the place to resume. Value copies and a weak model: the
            // View's @State box holds the model that holds this closure.
            viewModel.onMysteryChanged = { [weak viewModel, sessionStartedAt] index in
                guard let viewModel else { return }
                PrayerResumeService.shared.save(
                    kind: viewModel.resumeKind,
                    setId: 0,
                    setName: viewModel.devotionName,
                    category: viewModel.category.rawValue,
                    mysteryIndex: index,
                    beadIndex: viewModel.currentBeadIndex,
                    startedAt: sessionStartedAt,
                    accumulatedSeconds: viewModel.sessionDuration
                )
            }
            await viewModel.setPrayAloud(viewModel.praysAloud(setting: userSettings.prayAloud))
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

            case .text:
                ReaderTextOptionsSheet(showsNarrationOptions: false)
                    .presentationDetents([
                        .height(ReaderTextOptionsSheet.height(showsNarrationOptions: false))
                    ])
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
                // The tray opens as tall as it measures (`fittedSheetDetent`)
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
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
        let shareLine = reading.reference.map { "\(reading.text) — \($0)" } ?? reading.text
        return PrayerTrackActions(
            meditationId: 0,
            audioURL: nil,
            // No narration, so no voice is heard here; the chosen one is
            // the honest answer to "which voice", and nothing reads it
            // while `audioURL` is nil - the tray offers no download.
            voice: NarrationVoiceCatalog.shared.chosenSlug,
            shareText: viewModel.isPlain
                ? "\(mysteryName), the Rosary Aloud on Lumen Viae"
                : "\(shareLine) · \(mysteryName), the Scriptural Rosary on Lumen Viae",
            feedbackContext: FeedbackContext(
                meditationTitle: mysteryName,
                setName: viewModel.devotionName
            ),
            onAddReflection: { activeSheet = .journal },
            onGiveFeedback: { activeSheet = .feedback },
            onEndSession: { router.popToRoot() }
        )
    }

    // MARK: - Gestures

    /// Down for the next bead, up for the one before: mostly vertical,
    /// and either far enough or flicked. A forward swipe on the final
    /// bead does nothing — the Rosary is completed only by AMEN.
    ///
    /// A gesture is a shortcut, never the only way: the verse column
    /// prays the bead forward on a tap and back on a hold, since
    /// VoiceOver and Switch Control cannot deliver a drag.
    private var beadSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                guard !beadsHeld else { return }
                let t = value.translation
                if dragArmed == nil {
                    dragArmed = abs(t.height) > abs(t.width) * 1.2
                }
                guard dragArmed == true else { return }
                // At either end of the Rosary the string gives only a
                // little, and comes back
                let resisted = t.height > 0 ? viewModel.isLastBeadOfRosary : viewModel.isFirstBeadOfRosary
                strandDrag = RosaryStrandView.follow(t.height, resisted: resisted)
            }
            .onEnded { value in
                defer { dragArmed = nil }
                guard !beadsHeld else {
                    settleStrand()
                    return
                }
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
    }

    /// Whether the beads are held still: while the opening prayers are
    /// said on the pendant, which is not on the strand, and while the
    /// recordings are being fetched before the voice begins. A move then
    /// would skip the opening for good, or be taken back by the voice.
    private var beadsHeld: Bool {
        viewModel.spokenStatus != nil || viewModel.spokenPendant?.phase == .opening
    }

    /// The string let go short of a bead, or tugged at an end of the
    /// Rosary, coming back to where it was.
    private func settleStrand() {
        withAnimation(Motion.beadSettle) { strandDrag = 0 }
    }

    /// How much the words have dimmed as the finger draws the string —
    /// gone by a bead's length
    private var wordsDim: Double {
        min(abs(strandDrag) / RosaryStrandView.rowHeight, 1) * 0.45
    }

    // MARK: - Header

    /// The way out on the left, the devotion's name in the centre, and
    /// the size of the reading on the right.
    private var header: some View {
        ZStack {
            Text((viewModel.isPlain ? "The Rosary Aloud" : "Scriptural Rosary").uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.goldLight)
                .shadow(color: .black.opacity(0.6), radius: 6, y: 1)
                .lineLimit(1)

            HStack {
                PrayerHeaderButton(icon: "ph-x", size: 18, label: "End prayer") {
                    router.popToRoot()
                }
                Spacer()
                PrayerHeaderButton(icon: "ph-text-aa", size: 18, label: "Text options") {
                    activeSheet = .text
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - The Reading

    /// The header's reach below the safe area — its 12pt top padding and
    /// its 44pt buttons — and a little air. The column never begins
    /// higher than this, whatever the glass.
    private static let headerClearance: CGFloat = 12 + 44 + 14

    /// Where the column begins: its head stands level with the top of
    /// the strand's window, both read from `RosaryStrandView.windowTop`,
    /// so they agree by construction. An earlier cut aimed at "the first
    /// bead", which is wherever the string's resting offset happens to
    /// leave one, and measured the header to get there, so the column
    /// jumped once when the measurement came in.
    private func readingTop(fullHeight: CGFloat, topInset: CGFloat) -> CGFloat {
        max(RosaryStrandView.windowTop(fullHeight: fullHeight) - topInset, Self.headerClearance)
    }

    /// The room the words are given at the right: the strand's beads
    /// and their numerals take the edge, and the words stop short of
    /// them. Measured from the glass, as the strand is.
    private static let readingTrailingInset: CGFloat = 104

    /// The words' size follows the Prayer Experience text size the Aa
    /// sets, a point above the reading size. Set in the Medium face:
    /// the italic thinned to hairlines over the painting, and a verse
    /// read at arm's length over a picture needs its weight.
    private var verseSize: CGFloat {
        userSettings.meditationFontSize + 1
    }

    /// Between the quote leading and the prose leading: a verse of
    /// eight lines reads as one paragraph without the lines touching
    private var verseLeading: CGFloat {
        (verseSize * 0.4).rounded()
    }

    /// The Rosary Aloud's prayers are longer than any verse — the Our
    /// Father runs to ten lines at the verse's size — so they are set a
    /// size down at a closer leading, and still read at arm's length
    private var wordsSize: CGFloat {
        viewModel.isPlain ? verseSize - 2 : verseSize
    }

    private var wordsLeading: CGFloat {
        viewModel.isPlain ? (wordsSize * 0.3).rounded() : verseLeading
    }

    /// The bead, the mystery, and the words for the bead — a column
    /// whose head holds still while the words beneath it change.
    ///
    /// The words are the tap target, not the gutter beside them: a tap
    /// in the strand's column belongs to the painting.
    private var readingColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            columnHead
            beadWordsSlot
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: prayForward)
        .onLongPressGesture(perform: prayBack)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(viewModel.isLastBeadOfRosary ? "" : "Tap for the next bead")
        .accessibilityAction(named: "Next bead", prayForward)
        .accessibilityAction(named: "Previous bead", prayBack)
        .padding(.leading, 28)
        .padding(.trailing, Self.readingTrailingInset)
    }

    /// The bead under the hand in small capitals, and the mystery's
    /// name beneath it in the display face — the same kicker-and-title
    /// the meditation's player sets, with the bead as the kicker. The
    /// name keeps two lines' room whether it needs them or not, so the
    /// words below never move when a longer name arrives with the
    /// decade; with a one-line name the second line is the air before
    /// the verse.
    private var columnHead: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.beadLabel.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.9))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
                .contentTransition(.numericText(countsDown: travel == .back))
                .animation(Motion.words, value: viewModel.beadPosition)

            Text(viewModel.currentMystery?.name ?? "")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
                .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
                .contentTransition(.opacity)
                .animation(Motion.decadeTurn, value: viewModel.currentMysteryIndex)
        }
    }

    /// One slot for the words of whichever bead is under the hand. The
    /// words for a bead — its verse, its citation, the fruit on an Our
    /// Father, the cue where there is one — are one view identified by
    /// the bead, and the bead changing crossfades the whole block in
    /// place over the one leaving: nothing reflows, nothing slides.
    /// Letting each Text change under its own crossfade re-wrapped the
    /// lines as they faded, which cannot be read for as long as it
    /// lasts; the block is also what dims as the finger draws the
    /// string, so a move is felt before it is made.
    private var beadWordsSlot: some View {
        ZStack(alignment: .topLeading) {
            beadWords(viewModel.reading)
                .id(viewModel.beadPosition)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .animation(Motion.crossfade, value: viewModel.beadPosition)
        .opacity(1 - wordsDim)
    }

    /// What the bead says: the verse, its citation, the fruit on the Our
    /// Father, and what to do next where that is news — or AMEN.
    private func beadWords(_ reading: BeadReading) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // A verse keeps its full height; a prayer of the Rosary
            // Aloud, the Our Father at ten lines, gives way to the room
            // it has, a little smaller rather than cut short
            Text(reading.text)
                .font(AppFonts.bodyFont(wordsSize))
                .foregroundColor(AppColors.cream)
                .lineSpacing(wordsLeading)
                .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(viewModel.isPlain ? 0.7 : 1)
                .fixedSize(horizontal: false, vertical: !viewModel.isPlain)
                .layoutPriority(1)

            // The Fatima Prayer after the Glory Be: a paragraph of its
            // own, set the same, with a paragraph's air above it
            if let closing = reading.closingPrayer {
                Text(closing)
                    .font(AppFonts.bodyFont(wordsSize))
                    .foregroundColor(AppColors.cream)
                    .lineSpacing(wordsLeading)
                    .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(viewModel.isPlain ? 0.7 : 1)
                    .fixedSize(horizontal: false, vertical: !viewModel.isPlain)
                    .padding(.top, 4)
            }

            if let reference = reading.reference {
                Text(reference.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .lineLimit(1)
            }

            if let footnote = reading.footnote {
                Text(footnote.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.cream.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // On the last bead of all, AMEN — the one act that finishes
            // a Rosary; a swipe never does
            if viewModel.isLastBeadOfRosary {
                GoldCTAButton(
                    title: "Amen",
                    prominence: .inline,
                    trailingIcon: "ph-check",
                    fullWidth: false,
                    action: finishRosary
                )
                .accessibilityLabel("Amen — finish the Rosary")
                .beckoning(viewModel.isSpokenFinished)
                .padding(.top, 8)
            } else if let cue = beadCue {
                Text(cue)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    /// What to do on the bead under the hand, only where it is news: on
    /// the first bead of the Rosary, how the beads are moved; the decade
    /// prayed, the next mystery by name, so the turn is expected. Every
    /// other bead says nothing — a cue repeated fifty times is chrome.
    private var beadCue: String? {
        if viewModel.isDecadePrayed {
            let next = viewModel.category.mysteryLabel(ordinal: viewModel.currentMysteryIndex + 2)
            return "\(next) follows on the next swipe."
        }
        // In the Rosary Aloud the voice moves the beads, and how to move
        // them by hand is news only once the voice cannot
        if viewModel.isFirstBeadOfRosary,
           !viewModel.isPlain || viewModel.spokenFailure != nil {
            return "Swipe down for the first Hail Mary, and up for the bead before."
        }
        return nil
    }

    private var accessibilityText: String {
        let reading = viewModel.reading
        var parts = [viewModel.beadLabel, viewModel.currentMystery?.name ?? ""]
        if !reading.text.isEmpty { parts.append(reading.text) }
        if let closing = reading.closingPrayer { parts.append(closing) }
        if let reference = reading.reference { parts.append(reference) }
        if let footnote = reading.footnote { parts.append(footnote) }
        if let cue = beadCue { parts.append(cue) }
        return parts.filter { !$0.isEmpty }.joined(separator: ". ")
    }

    // MARK: - Foot

    /// Where the Rosary stands among its mysteries — the five beads and
    /// the mystery's ordinal name, said here and nowhere else — and the
    /// ⋯. The strand of mysteries reports position only; the strand at
    /// the edge carries the living bead, so this one keeps still.
    private var foot: some View {
        VStack(spacing: 18) {
            if viewModel.isPrayingAloud {
                spokenControls
            }

            VStack(spacing: 8) {
                RosaryBeadProgress(
                    total: viewModel.totalMysteries,
                    completed: viewModel.currentMysteryIndex,
                    activeIndex: viewModel.currentMysteryIndex,
                    beadSize: 8,
                    breathes: false
                )
                .frame(width: 130)

                Text((viewModel.spokenPendant?.heading ?? viewModel.mysteryKicker).uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .animation(Motion.decadeTurn, value: viewModel.currentMysteryIndex)

            HStack(spacing: 28) {
                // Said aloud or read in silence, from the Rosary itself:
                // this screen has no playback sheet to put it in. Named
                // in words and drawn as the same switch the set's page
                // uses — a bare speaker here read as a volume control.
                // The Rosary Aloud has no such choice to offer
                if !viewModel.isPlain {
                    SetupTogglePill(
                        icon: "ph-hands-praying",
                        title: UserSettings.prayAloudTitle,
                        isOn: Bindable(userSettings).prayAloud,
                        hint: UserSettings.prayAloudDetail(isOn: userSettings.prayAloud)
                    )
                    .frame(width: 172)
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
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }

    /// While the Rosary is said aloud: the prayer being said — or the
    /// recordings being fetched first — and the one control it needs.
    /// The beads move with the voice, and a swipe moves the voice. When
    /// the recordings could not be had, what went wrong and the control
    /// that puts it right; after the last Amen, nothing — AMEN glows.
    ///
    /// The caption and the play disc keep their room whether or not
    /// they are shown, so the foot stands the same height from the first
    /// fetch to the last Amen: the disc arriving when the recordings
    /// were ready, and leaving after the Amen, once pushed everything
    /// above it up and down. The notice takes the same slot, laid over
    /// the room the controls keep.
    private var spokenControls: some View {
        let failure = viewModel.spokenFailure

        return ZStack {
            speakingControls
                .opacity(failure == nil ? 1 : 0)
                .allowsHitTesting(failure == nil)
                .accessibilityHidden(failure != nil)

            if let failure {
                SpokenRosaryNotice(failure: failure) {
                    Task { await viewModel.restartSpoken() }
                }
                .transition(.opacity)
            }
        }
        // Room for the notice as well as the controls, so the notice
        // arriving does not move the foot either
        .frame(minHeight: Self.spokenSlotHeight)
        .animation(Motion.crossfade, value: failure)
        .transition(.opacity)
    }

    /// The spoken controls' room: a two-line caption over the 48pt disc,
    /// or the notice's two lines over its one control
    private static let spokenSlotHeight: CGFloat = 100

    private var speakingControls: some View {
        let line = viewModel.spokenStatus
            ?? (viewModel.spokenPendant == nil ? viewModel.spokenCaption : nil)
        let showsDisc = viewModel.spokenStatus == nil && !viewModel.isSpokenFinished

        return VStack(spacing: 10) {
            // Two lines kept whether the caption needs them or not,
            // and kept when there is no caption at all
            Text((line ?? "").uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .foregroundColor(viewModel.spokenStatus == nil ? AppColors.goldLight : AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .contentTransition(.opacity)
                .animation(Motion.words, value: line)
                .accessibilityHidden(line == nil)

            NarrationPlayButton(
                isPlaying: viewModel.isSpeaking,
                diameter: 48
            ) {
                viewModel.toggleSpeaking()
            }
            .opacity(showsDisc ? 1 : 0)
            .allowsHitTesting(showsDisc)
            .accessibilityHidden(!showsDisc)
            .animation(Motion.crossfade, value: showsDisc)
        }
    }

    /// Quieter than the reader's chrome: these sit over the painting,
    /// which is already carrying the eye.
    private static let utilityTint = AppColors.cream.opacity(0.7)

    // MARK: - Helper Functions

    /// One bead forward along the strand. The swipe, the tap and the
    /// rotor all come here; a `false` at the end of the Rosary is left
    /// alone, because only AMEN finishes it.
    private func prayForward() {
        guard !beadsHeld, !viewModel.isLastBeadOfRosary else {
            settleStrand()
            return
        }
        travel = .forward
        withAnimation(Motion.beadSlide) {
            _ = viewModel.prayForward()
            strandDrag = 0
        }
    }

    /// One bead back along the strand, into the previous decade if the
    /// hand is on an Our Father. On the first bead the string only
    /// settles.
    private func prayBack() {
        guard !beadsHeld, !viewModel.isFirstBeadOfRosary else {
            settleStrand()
            return
        }
        travel = .back
        withAnimation(Motion.beadSlide) {
            viewModel.prayBack()
            strandDrag = 0
        }
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
    private func saveResumePosition() {
        let mystery = viewModel.currentMysteryIndex
        let bead = viewModel.currentBeadIndex
        guard mystery > 0 || bead > 0 else { return }
        PrayerResumeService.shared.save(
            kind: viewModel.resumeKind,
            setId: 0,
            setName: viewModel.devotionName,
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

// MARK: - ScripturalSheet

/// What the screen can put over itself. One case at a time, by design.
private enum ScripturalSheet: String, Identifiable {
    case journal
    case text
    case tray
    case feedback

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
