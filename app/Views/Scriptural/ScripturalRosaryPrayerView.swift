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
//  Counted on one's own rosary (Counting: On My Rosary, offered while
//  the verses are read in silence), the strand is taken down and the
//  screen moves a mystery at a time, as the meditation's player does
//  off the beads: the column's head names what the hand counts, and
//  beneath it the whole decade is set at once — the Our Father's
//  announcement, a verse for each Hail Mary, the Glory Be — scrolled,
//  and crossfading whole when the mystery turns. Arrows flank the
//  mysteries' beads at the foot, the last becoming AMEN's check, and a
//  swipe left or right does what they do. The Scriptural Rosary once
//  counted only on the screen; its verses are as much for the hand that
//  keeps its own count.
//
//  The Holy Rosary prays here too (`SpokenForm.plain`; it was the
//  Rosary Aloud): the same
//  screen, said aloud whatever the setting, each bead carrying the
//  prayer being said on it instead of a verse. When the recordings
//  cannot be had it is still a Rosary — the notice says why, and the
//  beads are prayed from the page in silence.
//
//  While the opening and closing prayers are said on the pendant, the
//  same moves step the voice a prayer at a time — the pendant has no bead
//  of the strand to move to — and in the Rosary Aloud the column sets
//  each of those prayers' words, with the pendant hung beside them in
//  the strand's place. While the recordings are still being fetched the
//  beads are held: a move then would be undone the moment the voice
//  began.
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

    /// Bumped each time the hand steps the voice a prayer on or back on
    /// the pendant, where no bead of the strand moves to be felt
    @State private var prayerStepPulse = 0

    /// Where the foot begins, from the top of the glass: the pendant
    /// hangs clear of it. Placed by fractions of the glass alone, the
    /// cross's foot stood on the play disc.
    @State private var footTop: CGFloat?

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
                        pendantColumn(pendant)
                            .transition(.opacity)
                    } else if countsOnScreen {
                        readingColumn
                            .transition(.opacity)
                    } else {
                        decadeColumn
                            .transition(.opacity)
                    }
                }
                .padding(.top, readingTop(fullHeight: fullHeight, topInset: geometry.safeAreaInsets.top))
                .animation(Motion.decadeTurn, value: viewModel.spokenPendant == nil)
                .animation(Motion.crossfade, value: countsOnScreen)
                // The column is given the glass above the foot and no
                // more, so words too long for it — a prayer at a large
                // text size — can never push the foot off the screen
                .frame(maxHeight: .infinity, alignment: .top)

                foot
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).minY
                    } action: { top in
                        footTop = top
                    }
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
                // first mystery. Nor in the Rosary Aloud's closing, where
                // the pendant hangs in the strand's own place
                if countsOnScreen,
                   viewModel.spokenPendant?.phase != .opening,
                   !(viewModel.isPlain && viewModel.spokenPendant != nil) {
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
                        // In the Rosary Aloud, whose column sets the
                        // prayer's words, the pendant hangs beside them
                        // where the strand hangs through the decades, at
                        // the strand's scale and level with the words'
                        // head; laid under them, even dimmed, the cross
                        // ran through the Creed's lines
                        PendantStage(
                            pendant: pendant,
                            width: geometry.size.width,
                            fullHeight: fullHeight,
                            heightFraction: viewModel.isPlain ? 0.435 : 0.4,
                            topFraction: viewModel.isPlain
                                ? RosaryStrandView.windowTop(fullHeight: fullHeight) / max(fullHeight, 1)
                                : 0.355,
                            bottomLimit: footTop.map { $0 - Self.pendantFootClearance },
                            trailingColumn: viewModel.isPlain ? Self.readingTrailingInset : nil
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
        // A prayer stepped on the pendant ticks as a bead does
        .sensoryFeedback(.selection, trigger: prayerStepPulse)
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
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .text:
                ReaderTextOptionsSheet(showsNarrationOptions: false)
                    .presentationDetents([
                        .height(ReaderTextOptionsSheet.height(showsNarrationOptions: false))
                    ])
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

            case .tray:
                PrayerTrackTray(
                    actions: trackActions,
                    placement: .player,
                    pendingHandoff: $pendingHandoff
                )
                // The tray opens as tall as it measures (`fittedSheetDetent`)
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
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
                ? "\(mysteryName), the Holy Rosary on Lumen Viae"
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
                // On one's own rosary the string is not on the screen to
                // follow the finger; the swipe is read when it ends
                guard !beadsHeld, countsOnScreen else { return }
                let t = value.translation
                if dragArmed == nil {
                    dragArmed = abs(t.height) > abs(t.width) * 1.2
                }
                // On the pendant a swipe steps the voice, and the strand
                // it is not prayed on stays where it hangs
                guard dragArmed == true, !movesByPrayer else { return }
                // At either end of the Rosary the string gives only a
                // little, and comes back
                let resisted = t.height > 0 ? viewModel.isLastBeadOfRosary : viewModel.isFirstBeadOfRosary
                strandDrag = RosaryStrandView.follow(t.height, resisted: resisted)
            }
            .onEnded { value in
                defer { dragArmed = nil }
                guard countsOnScreen else {
                    handleMysterySwipe(value)
                    return
                }
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

    /// Whether the beads are counted on the screen: always while the
    /// voice says every prayer, which moves them itself, and otherwise as
    /// Counting says (`RosaryForm.countsOnScreen`). Off the screen the
    /// Rosary moves a mystery at a time, for a hand keeping count on its
    /// own rosary.
    private var countsOnScreen: Bool {
        RosaryForm(viewModel.form).countsOnScreen(
            aloud: userSettings.prayAloud,
            onBeads: userSettings.prayOnBeads
        )
    }

    /// Left for the next mystery, right for the one before, while the
    /// beads are counted on one's own rosary. The angle gate keeps the
    /// decade's scroll from ever counting, and a forward swipe on the
    /// last mystery does nothing — only AMEN finishes.
    private func handleMysterySwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }

        if dx < 0 {
            guard !viewModel.isLastMystery else { return }
            nextMystery()
        } else {
            // A drag begun on the left bezel is the navigation stack's
            // way back, not a step back a mystery on the way out
            guard value.startLocation.x > 40 else { return }
            previousMystery()
        }
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
            Text((viewModel.isPlain ? "The Holy Rosary" : "Scriptural Rosary").uppercased())
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

    /// How far a prayer of the Rosary Aloud may come down to be on the
    /// page whole. At 0.7 the Our Father was cut off at "who trespass
    /// a…" at the largest reading sizes, and the Creed, twice its length,
    /// at "the living and the dea…": a smaller prayer is still the
    /// prayer, and one cut short is not
    private static let prayerMinimumScale: CGFloat = 0.45

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

    /// The column while the voice is on the pendant.
    ///
    /// The Scriptural Rosary names the prayer and where it leads, over
    /// the pendant; its column carries Scripture, and the prayers are
    /// the voice's. The Rosary Aloud sets the prayer itself, laid out as
    /// its decades are — where it stands, what is said, the words — so
    /// the Creed and the Hail, Holy Queen are on the page as they are
    /// said, like every Hail Mary. They once showed only their names,
    /// and they are the prayers someone learning by ear knows least.
    ///
    /// Either way the column steps the voice a prayer on at a tap and
    /// back at a hold, as the verse column steps a bead, and through the
    /// closing prayers AMEN stays where it stood on the last bead: shown
    /// on the Glory Be, it once vanished for the Hail, Holy Queen and
    /// came back only after the last Amen.
    private func pendantColumn(_ pendant: SpokenPendant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.isPlain {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pendant.heading.uppercased())
                        .font(AppFonts.labelFont(9.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.9))
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

                    // No second line kept in reserve, as the mystery's
                    // name keeps one: that name holds over ten beads,
                    // and this one changes with every prayer, words and
                    // all, so there is nothing below it to keep still —
                    // and the Creed needs the line
                    Text(pendant.title)
                        .font(AppFonts.headlineFont(20))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
                        .contentTransition(.opacity)
                        .animation(Motion.words, value: pendant.title)
                }
                // Read with the words, as one element
                .accessibilityHidden(true)

                // One view to a prayer, crossfading whole in its slot, as
                // a bead's words do
                ZStack(alignment: .topLeading) {
                    pendantWords(pendant)
                        .id(Self.pendantKey(pendant))
                        .transition(.opacity)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .animation(Motion.crossfade, value: Self.pendantKey(pendant))
            } else {
                PendantTitleBlock(
                    pendant: pendant,
                    leadsInto: pendant.phase == .opening
                        ? PendantTitleBlock.leadIn(to: viewModel.mysteryKicker)
                        : nil
                )
                .pendantPrayerElement(
                    label: pendantAccessibilityText(pendant),
                    step: stepPrayer(forward:)
                )

                if pendant.phase == .closing {
                    amenButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { stepPrayer(forward: true) }
        .onLongPressGesture { stepPrayer(forward: false) }
        .padding(.leading, viewModel.isPlain ? 28 : 32)
        // The strand hangs beside the closing prayers, and the words keep
        // the measure they have in the decades either side of them
        .padding(.trailing, viewModel.isPlain || pendant.phase == .closing ? Self.readingTrailingInset : 32)
    }

    /// The Rosary Aloud's words for the prayer on the pendant, and on the
    /// closing prayers the AMEN that finishes the Rosary
    private func pendantWords(_ pendant: SpokenPendant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let lines = viewModel.spokenPendantLines {
                // At the decades' leading while the prayer fits whole; the
                // Creed at the largest sizes closes its lines up as well
                // as coming down, since a leading given in points does
                // not shrink with the letters, and at the decades' own it
                // was still cut short a line and a half from its Amen
                ViewThatFits(in: .vertical) {
                    pendantText(lines, leading: wordsLeading)
                        .fixedSize(horizontal: false, vertical: true)
                    pendantText(lines, leading: (wordsSize * 0.12).rounded())
                        .minimumScaleFactor(Self.prayerMinimumScale)
                }
                .layoutPriority(1)
                .pendantPrayerElement(
                    label: pendantAccessibilityText(pendant),
                    step: stepPrayer(forward:)
                )
            }

            if pendant.phase == .closing {
                amenButton
                    .padding(.top, 8)
            }
        }
    }

    private func pendantText(_ lines: [String], leading: CGFloat) -> some View {
        Text(pendantParagraph(lines))
            .font(AppFonts.bodyFont(wordsSize))
            .foregroundColor(AppColors.cream)
            .lineSpacing(leading)
            .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
            .multilineTextAlignment(.leading)
    }

    /// A prayer's lines as one paragraph, the way the decades' prayers
    /// are set, with a rubric line — "Let us pray." — in the rubric red
    /// and the italic a printed book gives it, out of its brackets: a
    /// direction, which the voice does not say, not words to be prayed
    private func pendantParagraph(_ lines: [String]) -> AttributedString {
        var paragraph = AttributedString()
        for (index, line) in lines.enumerated() {
            if index > 0 { paragraph += AttributedString(" ") }
            if PrayerMarkup.isRubric(line) {
                var rubric = AttributedString(PrayerMarkup.rubric(line))
                rubric.font = AppFonts.readingItalicFont(wordsSize)
                rubric.foregroundColor = Rubric.red
                paragraph += rubric
            } else {
                paragraph += Rubric.rubricated(line)
            }
        }
        return paragraph
    }

    /// Which prayer of the pendant is shown: the two Signs of the Cross,
    /// the three Hail Marys and the Holy Father's three prayers each told
    /// apart, so the words crossfade at every step
    private static func pendantKey(_ pendant: SpokenPendant) -> String {
        "\(pendant.heading)|\(pendant.title)|\(pendant.prayerID)"
    }

    private func pendantAccessibilityText(_ pendant: SpokenPendant) -> String {
        let words = (viewModel.spokenPendantLines ?? [])
            .map { PrayerMarkup.isRubric($0) ? PrayerMarkup.rubric($0) : $0 }
            .joined(separator: " ")
        return [pendant.heading, pendant.title, words]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    /// AMEN — the one act that finishes a Rosary; a swipe never does.
    /// It beckons once the voice has said the last Amen.
    private var amenButton: some View {
        GoldCTAButton(
            title: "Amen",
            prominence: .inline,
            trailingIcon: "ph-check",
            fullWidth: false,
            action: finishRosary
        )
        .accessibilityLabel("Amen — finish the Rosary")
        .beckoning(viewModel.isSpokenFinished)
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
                .minimumScaleFactor(viewModel.isPlain ? Self.prayerMinimumScale : 1)
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
                    .minimumScaleFactor(viewModel.isPlain ? Self.prayerMinimumScale : 1)
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
                amenButton
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

    // MARK: - On One's Own Rosary

    /// The decade set whole, for a hand keeping count on its own rosary:
    /// what the hand counts and the mystery's name at the head, held
    /// still, and beneath them the Our Father's announcement, a verse for
    /// each Hail Mary named as the bead is, and the Glory Be. Too long for
    /// the glass, so it scrolls, dissolving at the foot; it crossfades
    /// whole when the mystery turns, as a bead's words do on the strand.
    private var decadeColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(decadeCount.uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

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
            .accessibilityElement(children: .combine)

            ZStack(alignment: .topLeading) {
                ScrollView(showsIndicators: false) {
                    decadeWords
                        .padding(.bottom, 28)
                }
                .scrollBounceBehavior(.basedOnSize)
                .id(viewModel.currentMysteryIndex)
                .transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.9),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .animation(Motion.decadeTurn, value: viewModel.currentMysteryIndex)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .accessibilityAction(named: "Next mystery") {
            if viewModel.isLastMystery { finishRosary() } else { nextMystery() }
        }
        .accessibilityAction(named: "Previous mystery", previousMystery)
    }

    /// What the hand counts on the decade: "Our Father · Ten Hail Marys ·
    /// Glory Be", seven to a sorrow of the chaplet
    private var decadeCount: String {
        let hailMarys = viewModel.hailMarys == 7 ? "Seven" : viewModel.hailMarys == 10 ? "Ten" : "\(viewModel.hailMarys)"
        return "Our Father · \(hailMarys) Hail Marys · Glory Be"
    }

    /// Every bead's words in order, each under the bead's own name
    private var decadeWords: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(0...(viewModel.hailMarys + 1), id: \.self) { bead in
                decadeBead(bead)
            }
        }
    }

    private func decadeBead(_ bead: Int) -> some View {
        let reading = viewModel.reading(bead: bead)
        let size = userSettings.meditationFontSize

        return VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.strand.label(bead: bead).uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(1.8)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 4, y: 1)

            Text(reading.text)
                .font(AppFonts.bodyFont(size))
                .foregroundColor(AppColors.cream)
                .lineSpacing((size * 0.35).rounded())
                .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
                .fixedSize(horizontal: false, vertical: true)

            if let closing = reading.closingPrayer {
                Text(closing)
                    .font(AppFonts.bodyFont(size))
                    .foregroundColor(AppColors.cream)
                    .lineSpacing((size * 0.35).rounded())
                    .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            if let reference = reading.reference {
                Text(reference.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))
            }

            if let footnote = reading.footnote {
                Text(footnote.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.cream.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The mystery before, faded on the first — present, so the foot
    /// never rearranges itself under the thumb
    private var previousMysteryArrow: some View {
        TransportButton(icon: .asset("ph-arrow-left"), size: 20, label: "Previous mystery", action: previousMystery)
            .disabled(viewModel.isFirstMystery)
            .opacity(viewModel.isFirstMystery ? 0.25 : 1)
            .accessibilityHidden(viewModel.isFirstMystery)
    }

    /// The mystery after — and on the last, the check that is AMEN: the
    /// forward move that ends the Rosary is the one that finishes it
    private var nextMysteryArrow: some View {
        TransportButton(
            icon: .asset(viewModel.isLastMystery ? "ph-check" : "ph-arrow-right"),
            size: viewModel.isLastMystery ? 21 : 20,
            label: viewModel.isLastMystery ? "Amen — finish the Rosary" : "Next mystery"
        ) {
            if viewModel.isLastMystery {
                finishRosary()
            } else {
                nextMystery()
            }
        }
    }

    private func nextMystery() {
        travel = .forward
        withAnimation(Motion.decadeTurn) {
            _ = viewModel.nextMystery()
        }
    }

    private func previousMystery() {
        guard !viewModel.isFirstMystery else { return }
        travel = .back
        withAnimation(Motion.decadeTurn) {
            viewModel.previousMystery()
        }
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
            .frame(maxWidth: .infinity)
            // Counted on one's own rosary, the arrows that move a mystery
            // at a time stand either side of where the Rosary stands.
            // Laid over the readout rather than beside it, so it keeps
            // its place and its height whichever way the beads are counted
            .overlay(alignment: .leading) {
                if !countsOnScreen { previousMysteryArrow.transition(.opacity) }
            }
            .overlay(alignment: .trailing) {
                if !countsOnScreen { nextMysteryArrow.transition(.opacity) }
            }
            .animation(Motion.crossfade, value: countsOnScreen)

            HStack(spacing: 28) {
                // Whole Rosary or read in silence, from the Rosary itself:
                // this screen has no playback sheet to put it in. Named
                // in words — the Audio choice's own — and drawn as a
                // switch; a bare speaker here read as a volume control.
                // The Holy Rosary has no such choice to offer
                if !viewModel.isPlain {
                    SetupTogglePill(
                        icon: RosaryChoice.audio.icon,
                        title: RosaryChoice.audio.name(of: true, for: .scriptural),
                        isOn: Bindable(userSettings).prayAloud,
                        hint: RosaryChoice.audio.note(for: userSettings.prayAloud, form: .scriptural)
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

    /// The air between the pendant's cross and the top of the foot
    private static let pendantFootClearance: CGFloat = 10

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
    /// alone, because only AMEN finishes it. On the pendant, and on the
    /// last bead while the voice has the closing prayers still to say,
    /// it is the next prayer instead.
    private func prayForward() {
        guard !beadsHeld else {
            settleStrand()
            return
        }
        if movesByPrayer || viewModel.canStepOnIntoClosing {
            stepPrayer(forward: true)
            return
        }
        guard !viewModel.isLastBeadOfRosary else {
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
    /// settles — unless the voice is saying the first decade, when it
    /// goes back into the opening prayers, one prayer at a time.
    private func prayBack() {
        guard !beadsHeld else {
            settleStrand()
            return
        }
        if movesByPrayer || viewModel.canStepBackIntoOpening {
            stepPrayer(forward: false)
            return
        }
        guard !viewModel.isFirstBeadOfRosary else {
            settleStrand()
            return
        }
        travel = .back
        withAnimation(Motion.beadSlide) {
            viewModel.prayBack()
            strandDrag = 0
        }
    }

    /// One prayer on or back, said by the voice from its first word: the
    /// move on the pendant, where the strand has no bead to give
    private func stepPrayer(forward: Bool) {
        settleStrand()
        travel = forward ? .forward : .back
        let moved = withAnimation(Motion.words) {
            viewModel.stepSpokenPrayer(forward: forward)
        }
        if moved { prayerStepPulse += 1 }
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
