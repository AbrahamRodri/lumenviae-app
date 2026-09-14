//
//  ScripturalRosaryPrayerView.swift
//  Lumen Viae
//
//  The Scriptural Rosary prayed: a verse of Scripture for every bead,
//  standing in the middle of the mystery's painting, with the whole
//  Rosary hanging as one strand at the right edge.
//
//  The bead is the unit. Swipe down and the string slides a bead, the
//  next verse taking the last one's place; swipe up and the bead before
//  returns. Our Father beads are larger and carry the decade's numeral,
//  so the next mystery is seen approaching up the string several beads
//  before it arrives, and the turn is simply what happens when that
//  bead comes to hand — the painting and the kicker change with it.
//  Nothing else moves the Rosary forward: no arrows, no swipe between
//  mysteries. On the last bead of all the cue gives way to AMEN, and
//  finishing is always that deliberate tap, never a swipe.
//
//  The same stage the meditation's player prays on (`PrayerPaintingStage`,
//  veiled rather than seated, since the verse stands over the middle
//  of the picture), the same strand, the same rule. What differs is
//  what each bead carries: here, its verse.
//
//  Tapping the painting clears the chrome, verse and all, for
//  contemplation; the way out is the × at the top left, always.
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// When the devotion originally began (carried through resumes for
    /// snapshot continuity; never used for duration)
    private let sessionStartedAt: Date

    init(launch: ScripturalRosaryLaunch) {
        self.sessionStartedAt = launch.startedAt
        self._viewModel = State(initialValue: ScripturalRosaryViewModel(
            category: launch.category,
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

            ZStack {
                // The verse, standing in the middle of the picture
                verseColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    header
                        .padding(.top, 12)

                    Spacer()

                    foot
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                // The Rosary's one strand, hung at the right edge where the
                // meditation's player hangs it too. Inside the chrome layer
                // so it goes with the chrome when the painting is tapped.
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
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .background {
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
                .presentationDetents([
                    .height(prayerTrayHeight(for: .player, actions: trackActions))
                ])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.cardBackground)
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
            shareText: "\(shareLine) · \(mysteryName), the Scriptural Rosary on Lumen Viae",
            feedbackContext: FeedbackContext(
                meditationTitle: mysteryName,
                setName: ScripturalRosaryViewModel.devotionName
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
            Text("Scriptural Rosary".uppercased())
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

    // MARK: - The Verse

    /// The room the verse is given: the strand and its labels take the
    /// right of the screen, so the words stop well short of it.
    private static let verseTrailingInset: CGFloat = 150

    /// The verse's size follows the Prayer Experience text size the Aa
    /// sets, standing a little above the reading size — it is the only
    /// thing on the screen, and a verse is read at arm's length.
    private var verseSize: CGFloat {
        userSettings.meditationFontSize + 3
    }

    /// Where the Rosary stands, the words for the bead, and what the
    /// bead is. Crossfades as one between beads; the strand beside it
    /// moves its own bead.
    ///
    /// Every line crossfades in place — the kicker with the decade, the
    /// verse and its citation with the bead — rather than the column
    /// being torn down and rebuilt: a re-identified column is laid out
    /// twice over for the length of its transition, and its height
    /// would jump on every swipe.
    private var verseColumn: some View {
        let reading = viewModel.reading

        return VStack(alignment: .leading, spacing: 18) {
            // Two lines, set the same: where the Rosary stands in gold,
            // the mystery's name beneath it in cream
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.mysteryKicker.uppercased())
                    .foregroundColor(AppColors.gold)
                    .contentTransition(.opacity)
                Text((viewModel.currentMystery?.name ?? "").uppercased())
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .contentTransition(.opacity)
            }
            .font(AppFonts.labelFont(10))
            .tracking(2.5)
            .fixedSize(horizontal: false, vertical: true)
            .beadWordsArrival(trigger: viewModel.currentMysteryIndex, from: travel, still: reduceMotion, distance: 8)
            .animation(Motion.decadeTurn, value: viewModel.currentMysteryIndex)

            beadWords(reading)
                // Dims as the finger draws the string, and arrives from
                // the side the string came from once the bead has changed
                .opacity(1 - wordsDim)
                .beadWordsArrival(trigger: viewModel.beadPosition, from: travel, still: reduceMotion)
                .animation(Motion.words, value: viewModel.beadPosition)
        }
        // The words are the tap target, not the gutter beside them: a
        // tap in the strand's column belongs to the painting
        .contentShape(Rectangle())
        .onTapGesture(perform: prayForward)
        .onLongPressGesture(perform: prayBack)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(viewModel.isLastBeadOfRosary ? "" : "Tap for the next bead")
        .accessibilityAction(named: "Next bead", prayForward)
        .accessibilityAction(named: "Previous bead", prayBack)
        .padding(.leading, 30)
        .padding(.trailing, Self.verseTrailingInset)
    }

    /// What the bead says: the verse, its citation and count, the fruit
    /// on the Our Father, and what to do next — or AMEN.
    private func beadWords(_ reading: BeadReading) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(reading.text)
                .font(AppFonts.readingItalicFont(verseSize))
                .foregroundColor(AppColors.cream)
                .lineSpacing(ReadingTypography.quoteLineSpacing(for: verseSize))
                .shadow(color: .black.opacity(0.5), radius: 10, y: 1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)

            // The citation and the bead, on one line where the column
            // is wide enough for both, and on two where it is not — a
            // long citation beside a long count would otherwise be cut
            // to "HAIL MARY · 1 OF…"
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    citation(reading.reference)
                    Text(beadCount.uppercased())
                        .foregroundColor(AppColors.cream.opacity(0.6))
                        .lineLimit(1)
                        .fixedSize()
                        .contentTransition(.numericText(countsDown: travel == .back))
                }

                VStack(alignment: .leading, spacing: 8) {
                    citation(reading.reference)
                    Text(beadCount.uppercased())
                        .foregroundColor(AppColors.cream.opacity(0.6))
                        .lineLimit(1)
                        .contentTransition(.numericText(countsDown: travel == .back))
                }
            }
            .font(AppFonts.labelFont(9))
            .tracking(1.5)

            if let footnote = reading.footnote {
                Text(footnote.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }

            // What to do next — or, on the last bead of all, AMEN. One
            // slot for both, so they crossfade over each other
            ZStack(alignment: .leading) {
                if viewModel.isLastBeadOfRosary {
                    GoldCTAButton(
                        title: "Amen",
                        prominence: .inline,
                        showsCross: false,
                        trailingIcon: "ph-check",
                        fullWidth: false,
                        action: finishRosary
                    )
                    .accessibilityLabel("Amen — finish the Rosary")
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                } else {
                    Text(beadCue)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream.opacity(0.6))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                        .transition(.opacity)
                }
            }
            .padding(.top, 6)
        }
    }

    /// The citation and its hairline, or nothing on the Glory Be, which
    /// has none.
    @ViewBuilder
    private func citation(_ reference: String?) -> some View {
        if let reference {
            HStack(spacing: 14) {
                Text(reference.uppercased())
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .lineLimit(1)
                    .fixedSize()
                    .contentTransition(.opacity)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.4))
                    .frame(width: 1, height: 10)
            }
        }
    }

    /// The bead in words, beside the citation: OUR FATHER, HAIL MARY ·
    /// 4 OF 10, and DECADE COMPLETE where the Glory Be is said.
    private var beadCount: String {
        viewModel.isDecadePrayed ? "Decade complete" : viewModel.beadLabel
    }

    /// What to do on the bead under the hand. The decade prayed, the
    /// next mystery is named so the turn is expected.
    private var beadCue: String {
        if viewModel.isDecadePrayed {
            let next = viewModel.category.mysteryLabel(ordinal: viewModel.currentMysteryIndex + 2)
            return "\(next) follows on the next swipe."
        }
        if viewModel.currentBeadIndex == 0 {
            return "Swipe down for the first Hail Mary"
        }
        return "Swipe down for the next bead · swipe up to go back"
    }

    private var accessibilityText: String {
        let reading = viewModel.reading
        var parts = [viewModel.mysteryKicker, viewModel.currentMystery?.name ?? "", beadCount]
        if let reference = reading.reference { parts.append(reference) }
        if !reading.text.isEmpty { parts.append(reading.text) }
        if let footnote = reading.footnote { parts.append(footnote) }
        return parts.filter { !$0.isEmpty }.joined(separator: ". ")
    }

    // MARK: - Foot

    /// Where the Rosary stands among its mysteries, and the ⋯. The
    /// strand of mysteries reports position only — the strand at the
    /// edge carries the living bead, so this one keeps still.
    private var foot: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                RosaryBeadProgress(
                    total: viewModel.totalMysteries,
                    completed: viewModel.currentMysteryIndex,
                    activeIndex: viewModel.currentMysteryIndex,
                    beadSize: 8,
                    breathes: false
                )
                .frame(width: 130)

                Text(viewModel.strand.standing(
                    mystery: viewModel.currentMysteryIndex,
                    category: viewModel.category
                ).uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .animation(Motion.decadeTurn, value: viewModel.currentMysteryIndex)

            ReaderChromeButton(
                icon: "ph-dots-three",
                size: 23,
                tint: Self.utilityTint,
                label: "More"
            ) {
                activeSheet = .tray
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }

    /// Quieter than the reader's chrome: these sit over the painting,
    /// which is already carrying the eye.
    private static let utilityTint = AppColors.cream.opacity(0.7)

    // MARK: - Helper Functions

    /// One bead forward along the strand. The swipe, the tap and the
    /// rotor all come here; a `false` at the end of the Rosary is left
    /// alone, because only AMEN finishes it.
    private func prayForward() {
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
    /// settles.
    private func prayBack() {
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
            kind: .scripturalRosary,
            setId: 0,
            setName: ScripturalRosaryViewModel.devotionName,
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
            devotionName: ScripturalRosaryViewModel.devotionName,
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
