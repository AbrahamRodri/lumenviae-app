//
//  ChantPracticeView.swift
//  Lumen Viae
//
//  Learning a chant by heart. A chant is learned in four steps, the
//  learner's own to take:
//
//    1 Listen        hear it sung
//    2 Read along    follow the words as the singer sings them
//    3 Sing along    the singer sings, then you sing it back
//    4 On your own   you sing first, then the singer sings it to you
//
//  The practice is two quiet screens rather than one busy one (the
//  "Chant practice" design, option C, Oct 2026). It opens on the path:
//  the chant's painting and the four steps as beads on a thread, each
//  saying once what it is, over BEGIN or CONTINUE. The singing screen is
//  then little more than the line, over the painting veiled: the step's
//  name (the way back to the path), the line sung, Again, the play disc
//  and the score, and the one gold act forward. Repeat, Speed and Hide
//  words stand behind the faders.
//
//  For a chant whose lines have been timed (`Chant.lines`), each step goes
//  a line at a time — the line sung, again if asked, three times if
//  asked, slower if asked, and the next when the learner says they have
//  it. For every other chant each step is the whole chant, with its words
//  from the Prayer Book; no timing is guessed.
//
//  Nothing is scored. The last step ends on the learner's own word that
//  they know it by heart, which is kept on their shelf.
//
//  Presented full screen over a chant's page; the path carries its ✕.
//

import SwiftUI

struct ChantPracticeView: View {

    let chant: Chant

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var player = ChantPlayer.shared
    private var shelf: ChantShelfStore

    /// Which of the practice's screens is up
    enum Stage {
        /// The painting and the four steps, where the practice opens
        case path
        /// The line being learned, and the controls for it
        case singing
        /// The learner's word that they know it by heart, kept
        case learned
    }

    @State private var stage: Stage = .path
    @State private var step: ChantLearningStep = .listen
    @State private var line = 0
    @State private var repeatsWanted = 1
    @State private var timesSung = 0
    @State private var hidden: Hiding = .none
    @State private var showsOptions = false
    @State private var showsScore = false

    /// Whether the learner had begun this chant before this practice
    /// opened: BEGIN on a first visit, CONTINUE after
    @State private var hadBegun = false

    /// Whether the learner has taken a step yet: opening the practice is
    /// not beginning to learn, so nothing is kept until they act
    @State private var hasActed = false

    /// Whether the practice set the singer singing, so closing it stops
    /// what it began and leaves alone what it found
    @State private var startedPlayback = false

    /// Whether the chant was already in the player when the practice
    /// opened: the library's, to be left as it was found
    @State private var foundHolding = false

    /// The shared player's pace and Repeat as the practice found them,
    /// given back when it closes: a slower pace and a repeat chosen for
    /// learning are not every later chant's
    @State private var found: (rate: Double, repeats: Bool)?

    /// How much of the words is hidden, for singing from memory
    typealias Hiding = ChantHiding

    /// Where the line left is kept (`PracticePlace`)
    private let places: UserDefaults

    init(chant: Chant, shelf: ChantShelfStore = .shared, places: UserDefaults = .standard) {
        self.chant = chant
        self.shelf = shelf
        self.places = places
    }

    private var lines: Bool { chant.hasLines }
    private var painting: String { ChantCatalog.painting(for: chant) }

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            // One slot: the three screens crossfade over each other, never
            // laid out one above the other
            ZStack {
                switch stage {
                case .path:
                    pathPage
                        .transition(.opacity)
                case .singing:
                    singingPage
                        .transition(.opacity)
                case .learned:
                    learnedPage
                        .transition(.opacity)
                }
            }
        }
        .animation(Motion.crossfade, value: stage)
        .sheet(isPresented: $showsOptions) {
            PracticeOptionsSheet(
                chant: chant,
                step: step,
                repeatsWanted: $repeatsWanted,
                hidden: $hidden
            )
            // As tall as its three rows, not half the glass over nothing
            .presentationDetents([.height(300), .large])
            .sheetGround()
            .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .sheet(isPresented: $showsScore) {
            // The practice keeps the transport: a second one in the sheet
            // would sing the whole chant over the line being learned
            ChantScoreSheet(chant: chant, showsTransport: false)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        .onAppear {
            found = (player.rate, player.repeats)
            foundHolding = player.holds(chant)
            hadBegun = shelf.step(of: chant.id) != nil || shelf.isLearned(chant.id)
            step = shelf.step(of: chant.id) ?? .listen
            if shelf.isLearned(chant.id) { step = .onYourOwn }
            // A line kept for a chant the shelf no longer has under way —
            // put down with Stop Learning, or learned — means nothing: a
            // new beginning starts on Listen at the first line
            if shelf.step(of: chant.id) == nil {
                PracticePlace.forget(chant.id, defaults: places)
            } else if lines, let kept = PracticePlace.line(of: chant.id, on: step, defaults: places),
                chant.lines.indices.contains(kept) {
                line = kept
            }
            hidden = step == .onYourOwn ? .half : .none
        }
        .onDisappear {
            keepPlace()
            player.setLineEnd(.goOn)
            if startedPlayback {
                if player.current.id == chant.id, player.error != nil {
                    // The chant would not play here: its failure is the
                    // practice's, and goes with it, or the mini player
                    // said so over every page after
                    player.relinquish()
                } else if !foundHolding, player.current.id == chant.id,
                   player.holds(chant) || player.isLoading {
                    // A chant the practice loaded, or is still loading, is
                    // the practice's to put away: left paused, it stood in
                    // the library's mini player at 0:00 when nothing had
                    // sounded, over the foot of every page
                    player.relinquish()
                } else {
                    player.pause()
                }
            }
            if let found {
                player.setRate(found.rate)
                player.repeats = found.repeats
            }
        }
        .onChange(of: player.linesFinished) { _, _ in
            lineSung()
        }
        .onChange(of: player.turn?.line) { _, turnLine in
            guard turnLine != nil, stage == .singing, player.holds(chant) else { return }
            AccessibilityNotification.Announcement(Self.turnCaption(step: step)).post()
        }
    }

    // MARK: - The path

    private var pathPage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        ChantPainting(name: painting, height: 430, dissolveFrom: 0.4)
                        pathTitle
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 0) {
                        ForEach(ChantLearningStep.allCases) { each in
                            PracticeStepRow(
                                step: each,
                                note: Self.note(of: each, timed: lines),
                                place: place(of: each),
                                lineNote: each == step && lines && line > 0
                                    ? "Line \(line + 1)" : nil,
                                isFirst: each == .listen,
                                isLast: each == .onYourOwn
                            ) {
                                choose(each)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                }
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(edges: .top)

            GoldCTAButton(
                title: Self.pathAction(begun: hadBegun || hasActed, learned: shelf.isLearned(chant.id)),
                glyph: .play
            ) {
                enter()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                AppIcon("ph-x", size: 17)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.background.opacity(0.55)))
                    .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .padding(.leading, 12)
            .padding(.top, 4)
            .accessibilityLabel("Close")
            .accessibilitySortPriority(-1)
        }
    }

    private var pathTitle: some View {
        VStack(spacing: 6) {
            Text(shelf.isLearned(chant.id) ? "LEARNED BY HEART" : "LEARN BY HEART")
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.goldLight)
            Text(chant.latinTitle)
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(lines ? "\(chant.englishTitle) · \(chant.lines.count) lines" : chant.englishTitle)
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .shadow(color: .black.opacity(0.55), radius: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Learn by heart: \(chant.spokenName)")
        .accessibilityAddTraits(.isHeader)
    }

    private func place(of each: ChantLearningStep) -> PracticeStepRow.Place {
        if shelf.isLearned(chant.id) || each.rawValue < step.rawValue { return .taken }
        return each == step ? .here : .ahead
    }

    // MARK: - Singing

    private var singingPage: some View {
        let turn = player.holds(chant) ? player.turn : nil
        return VStack(spacing: 0) {
            singingHeader

            if lines {
                PracticeLineThread(line: line, count: chant.lines.count)
                    .padding(.horizontal, 64)
                    .padding(.top, 14)
            }

            // A slot of its own, so a line leaving and the next arriving
            // crossfade over one another
            ZStack {
                words(lit: turn != nil || isSounding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 28)

            controls(turn: turn)
                .padding(.bottom, 22)

            GoldCTAButton(
                title: Self.forwardTitle(step: step, timed: lines, line: line, count: chant.lines.count),
                trailingIcon: isLastOfAll ? "ph-check" : nil
            ) {
                forward()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background {
            PracticeGround(painting: painting, dimmed: turn != nil)
        }
    }

    private var singingHeader: some View {
        HStack(spacing: 0) {
            Button {
                backToPath()
            } label: {
                HStack(spacing: 10) {
                    AppIcon("ph-caret-left", size: 15)
                        .foregroundColor(AppColors.gold)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title.uppercased())
                            .font(AppFonts.labelFont(11))
                            .tracking(2.2)
                            .foregroundColor(AppColors.goldLight)
                        if lines {
                            Text("LINE \(line + 1) OF \(chant.lines.count)")
                                .font(AppFonts.labelFont(9))
                                .tracking(1.8)
                                .foregroundColor(AppColors.cream.opacity(0.7))
                                .contentTransition(.chantCount(reduceMotion: reduceMotion))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .animation(Motion.crossfade, value: line)
            .accessibilityLabel(lines ? "\(step.title), line \(line + 1) of \(chant.lines.count)" : step.title)
            .accessibilityHint("Back to the four steps")

            Spacer(minLength: 8)

            Button {
                showsOptions = true
            } label: {
                AppIcon("ph-faders", size: 19)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("How to practise")
            .accessibilityHint("Repeat, speed and hiding the words")
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    // MARK: - Words

    @ViewBuilder
    private func words(lit: Bool) -> some View {
        if lines {
            let current = chant.lines[line]
            VStack(spacing: 14) {
                if step == .listen {
                    // Listening, the Latin is heard and not yet read
                    Text(current.english)
                        .font(AppFonts.readingItalicFont(25))
                        .foregroundColor(AppColors.cream.opacity(0.94))
                        .lineSpacing(4)
                } else {
                    Text(Self.hide(current.latin, hidden))
                        .font(AppFonts.readingFont(31))
                        .foregroundColor(lit ? AppColors.goldLight : AppColors.cream)
                        .lineSpacing(4)
                        .minimumScaleFactor(0.7)
                    Text(current.english)
                        .font(AppFonts.readingItalicFont(17))
                        .foregroundColor(AppColors.cream.opacity(0.78))
                        .lineSpacing(2)
                }
            }
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.6), radius: 8)
            .fixedSize(horizontal: false, vertical: true)
            .animation(Motion.crossfade, value: lit)
            .id(line)
            .transition(.opacity)
            .animation(Motion.words, value: line)
            .accessibilityElement(children: .combine)
        } else if let text = chant.words {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if step != .listen, let latin = text.latin {
                        Text(Self.hide(Self.plain(latin), hidden))
                            .font(AppFonts.readingFont(21))
                            .foregroundColor(AppColors.cream)
                            .lineSpacing(5)
                    }
                    if let english = text.english, step == .listen || step == .readAlong || text.latin == nil {
                        Text(Self.plain(english))
                            .font(AppFonts.readingItalicFont(17))
                            .foregroundColor(AppColors.cream.opacity(0.78))
                            .lineSpacing(3)
                    }
                }
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.6), radius: 8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.08),
                        .init(color: .black, location: 0.9),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            Text("The words of this chant are printed on its sheet music.")
                .font(AppFonts.readingItalicFont(17))
                .foregroundColor(AppColors.cream.opacity(0.78))
                .multilineTextAlignment(.center)
        }
    }

    private var isSounding: Bool {
        player.holds(chant) && player.isPlaying && (!lines || player.lineIndex == line)
    }

    // MARK: - Controls

    private func controls(turn: ChantTurn?) -> some View {
        HStack(alignment: .top, spacing: 30) {
            PracticeQuietControl(
                icon: lines ? "ph-repeat-once" : "ph-arrow-counter-clockwise",
                label: "Again",
                spokenLabel: lines ? "Play the line again" : "From the top"
            ) {
                again()
            }

            VStack(spacing: 10) {
                ZStack {
                    if let turn {
                        PracticeTurnDisc(turn: turn, length: turnLength(of: turn)) {
                            // The turn held, or taken up again
                            player.togglePlayback()
                        }
                        .transition(.opacity)
                    } else {
                        ChantPlayDisc(
                            isPlaying: player.isPlaying(chant),
                            isLoading: player.current.id == chant.id && player.isLoading,
                            size: 76,
                            label: chant.spokenNameAndSetting
                        ) {
                            play()
                        }
                        .transition(.opacity)
                    }
                }
                .frame(width: 88, height: 88)
                .animation(Motion.crossfade, value: turn != nil)

                Text(discCaption(turn: turn).uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.8)
                    .foregroundColor(turn != nil ? AppColors.goldLight : AppColors.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.opacity)
                    .animation(Motion.crossfade, value: discCaption(turn: turn))
                    .frame(width: 130)
                    .accessibilityHidden(true)
            }

            PracticeQuietControl(icon: "ph-music-note", label: "Score", spokenLabel: "The sheet music") {
                showsScore = true
            }
        }
    }

    /// The seconds the turn was given, for its ring: the line's length at
    /// the pace sounding, as the player reckons it
    private func turnLength(of turn: ChantTurn) -> TimeInterval {
        ChantTurn.length(of: chant.lines.indices.contains(turn.line) ? chant.lines[turn.line] : nil, speed: player.speed)
    }

    private func discCaption(turn: ChantTurn?) -> String {
        if turn != nil { return Self.turnCaption(step: step) }
        // The chant would not play: said where it was asked for, since the
        // mini player stands aside for the practice
        if player.current.id == chant.id, let error = player.error { return error.caption }
        if player.isPlaying(chant) { return "Tap to pause" }
        return Self.restCaption(step: step, timed: lines)
    }

    private var isLastLine: Bool { !lines || line == chant.lines.count - 1 }
    private var isLastOfAll: Bool { step == .onYourOwn && isLastLine }

    // MARK: - Learned

    private var learnedPage: some View {
        VStack(spacing: 0) {
            ChantPainting(name: painting, height: 470, dissolveFrom: 0.5)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 8) {
                AppIcon("ph-seal-check-fill", size: 46)
                    .foregroundColor(AppColors.gold)
                    .shadow(color: AppColors.gold.opacity(0.45), radius: 12)
                    .padding(.bottom, 10)
                    .accessibilityHidden(true)
                Text("LEARNED BY HEART")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                Text(chant.latinTitle)
                    .font(AppFonts.titleFont(30))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                Text(chant.englishTitle)
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            // Risen into the painting's dissolve, so the seal stands where
            // the painting gives way to the page
            .padding(.top, -70)
            .padding(.horizontal, 28)

            Text("Kept in Saved, under Learned.")
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .padding(.horizontal, 28)

            Spacer(minLength: 16)

            GoldCTAButton(title: "Done") {
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Acts

    /// From the path into the step the learner stands on, where they left it
    private func enter() {
        stage = .singing
        if !lines, step == .listen || step == .readAlong, player.holds(chant) {
            // A whole chant left on the path is taken up where it was
            // paused, not sung again from its top; a set it was being sung
            // in is put down first, or the set would go on to its next
            if !player.isPlaying(chant) {
                startedPlayback = true
                player.endQueue()
                player.togglePlayback()
            }
        } else {
            begin()
        }
    }

    /// A step chosen on the path: the one under way goes on where it was;
    /// any other is begun from its first line
    private func choose(_ chosen: ChantLearningStep) {
        if chosen == step {
            enter()
        } else {
            stage = .singing
            go(to: chosen)
        }
    }

    /// Back to the path: the singer rests, and the place is kept
    private func backToPath() {
        if startedPlayback, player.holds(chant) || player.turn != nil {
            player.setLineEnd(.goOn)
            player.pause()
        }
        keepPlace()
        stage = .path
    }

    /// Opens the step: a timed chant's line sung at once; a whole chant
    /// begun for listening and reading, and left for the learner to start
    /// when they sing it themselves
    private func begin() {
        timesSung = 0
        if lines {
            singLine()
        } else if step == .listen || step == .readAlong {
            if player.isPlaying(chant) {
                // Sounding already, in a set: it sings on, on its own
                player.endQueue()
            } else {
                singWhole()
            }
        }
    }

    /// The play disc: a timed chant's line sung as the step sings it, or
    /// the whole chant played and paused
    private func play() {
        acted()
        if lines, !player.holds(chant) || !player.isPlaying {
            singLine()
        } else {
            // Starting the chant is the practice's own act, and puts down
            // a set the chant was being sung in
            if !player.isPlaying(chant) {
                startedPlayback = true
                player.endQueue()
            }
            player.toggle(chant)
        }
    }

    /// The line under the hand, as the step sings it
    private func singLine() {
        guard lines else { return }
        startedPlayback = true
        switch step {
        case .listen, .readAlong:
            player.playLine(line, of: chant, then: .stop)
        case .singAlong:
            player.playLine(line, of: chant, then: .yourTurnThenStop)
        case .onYourOwn:
            player.yourTurnFirst(line, of: chant)
        }
    }

    /// A line has been sung to its end: again, if the learner asked for it
    /// more than once
    private func lineSung() {
        guard lines, player.holds(chant) else { return }
        timesSung += 1
        if timesSung < repeatsWanted, step == .listen || step == .readAlong {
            singLine()
        }
    }

    private func again() {
        acted()
        timesSung = 0
        if lines {
            singLine()
        } else {
            singWhole()
        }
    }

    /// The whole chant from its top, as the practice's own act: a set the
    /// chant was being sung in is put down, as practising a line puts it
    /// down, or the set would go on to its next chant mid-practice
    private func singWhole() {
        startedPlayback = true
        if player.holds(chant) {
            player.endQueue()
            player.restart()
        } else {
            player.play(chant)
        }
    }

    /// The learner's first act keeps the chant as under way, at the step
    /// they stand on; a chant learned and practised again keeps its mark
    private func acted() {
        guard !hasActed else { return }
        hasActed = true
        if !shelf.isLearned(chant.id) {
            shelf.setStep(step, for: chant.id)
        }
    }

    private func forward() {
        acted()
        if isLastOfAll {
            player.setLineEnd(.goOn)
            shelf.markLearned(chant.id)
            PracticePlace.forget(chant.id, defaults: places)
            withAnimation(reduceMotion ? nil : Motion.crossfade) { stage = .learned }
            return
        }
        if lines, !isLastLine {
            line += 1
            timesSung = 0
            keepPlace()
            singLine()
            return
        }
        if let next = step.next {
            go(to: next)
        }
    }

    private func go(to next: ChantLearningStep) {
        hasActed = true
        step = next
        line = 0
        hidden = next == .onYourOwn ? .half : .none
        // A chant learned and practised again keeps its mark
        if !shelf.isLearned(chant.id) {
            shelf.setStep(next, for: chant.id)
        }
        keepPlace()
        if lines {
            begin()
        } else if next == .onYourOwn, player.isPlaying(chant) {
            // From memory: the singer rests until asked
            player.togglePlayback()
        } else {
            begin()
        }
    }

    /// The line the learner stands on, kept with its step, so CONTINUE
    /// takes them back to it — but only once they have acted, since
    /// opening a practice is not beginning one
    private func keepPlace() {
        guard lines, hasActed, !shelf.isLearned(chant.id) else { return }
        PracticePlace.keep(line: line, of: chant.id, on: step, defaults: places)
    }

    // MARK: - Words for each moment

    /// What a step is, on the path: said once there, so the singing screen
    /// never has to
    static func note(of step: ChantLearningStep, timed: Bool) -> String {
        if timed {
            switch step {
            case .listen:    return "Hear each line sung"
            case .readAlong: return "Follow the Latin as it is sung"
            case .singAlong: return "The singer sings, then you"
            case .onYourOwn: return "You first, then the singer"
            }
        }
        switch step {
        case .listen:    return "Hear the whole chant sung"
        case .readAlong: return "Follow the words as it is sung"
        case .singAlong: return "Sing with the recording"
        case .onYourOwn: return "Sing from memory, then play it to check"
        }
    }

    /// The path's act: BEGIN on a first visit, CONTINUE once begun, and
    /// PRACTISE AGAIN for a chant already learned — the chant page's words
    static func pathAction(begun: Bool, learned: Bool) -> String {
        if learned { return "Practise again" }
        return begun ? "Continue" : "Begin"
    }

    /// The gold act on the singing screen: the next line, then the next
    /// step on a step's last line, and the learner's own word on the last
    /// line of all
    static func forwardTitle(step: ChantLearningStep, timed: Bool, line: Int, count: Int) -> String {
        let lastLine = !timed || line >= count - 1
        if step == .onYourOwn, lastLine { return "I know it by heart" }
        return lastLine ? "Next step" : "Next line"
    }

    /// Under the disc while it is the learner's turn
    static func turnCaption(step: ChantLearningStep) -> String {
        step == .onYourOwn ? "You sing first" : "Sing it back"
    }

    /// Under the disc while nothing sounds: what a tap on it will do
    static func restCaption(step: ChantLearningStep, timed: Bool) -> String {
        if timed {
            switch step {
            case .listen, .readAlong: return "Hear the line"
            case .singAlong: return "The singer, then you"
            case .onYourOwn: return "You, then the singer"
            }
        }
        switch step {
        case .listen, .readAlong: return "Hear it sung"
        case .singAlong: return "Sing with it"
        case .onYourOwn: return "Play it to check"
        }
    }

    // MARK: - Words, hidden

    /// The words with every other one, or every one, cut to its first
    /// letter (`ChantPracticeWords`)
    static func hide(_ text: String, _ hiding: Hiding) -> String {
        ChantPracticeWords.hidden(text, hiding)
    }

    /// The Prayer Book's grammar as plain lines to sing from
    static func plain(_ text: String) -> String {
        ChantPracticeWords.plain(text)
    }
}

// MARK: - PracticePlace

/// The line a learner left a step on, per chant, so CONTINUE takes them
/// back to it. The step itself is the shelf's (`ChantShelfStore`); the
/// line is kept beside it here, and only counts while the shelf still
/// stands the learner on the step it was kept with.
enum PracticePlace {
    static let key = "chantPractice.places"

    static func line(
        of chantID: String,
        on step: ChantLearningStep,
        defaults: UserDefaults = .standard
    ) -> Int? {
        guard let kept = (defaults.dictionary(forKey: key) as? [String: [Int]])?[chantID],
              kept.count == 2, kept[0] == step.rawValue else { return nil }
        return kept[1]
    }

    static func keep(line: Int, of chantID: String, on step: ChantLearningStep, defaults: UserDefaults = .standard) {
        var places = defaults.dictionary(forKey: key) as? [String: [Int]] ?? [:]
        places[chantID] = [step.rawValue, line]
        defaults.set(places, forKey: key)
    }

    static func forget(_ chantID: String, defaults: UserDefaults = .standard) {
        guard var places = defaults.dictionary(forKey: key) as? [String: [Int]] else { return }
        places[chantID] = nil
        defaults.set(places, forKey: key)
    }
}

// MARK: - PracticeStepRow

/// One step on the path: its bead on the thread, its name, what it is, and
/// where in it the learner stands. The whole row is a door into the step.
private struct PracticeStepRow: View {

    enum Place { case taken, here, ahead }

    let step: ChantLearningStep
    let note: String
    let place: Place
    let lineNote: String?
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                bead
                    .frame(width: 22)
                    .frame(maxHeight: .infinity)
                    .background(thread)

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(AppFonts.readingFont(19))
                        .foregroundColor(
                            place == .here ? AppColors.goldLight
                                : place == .ahead ? AppColors.cream.opacity(0.62) : AppColors.cream
                        )
                    Text(note)
                        .font(AppFonts.readingItalicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 11)

                if let lineNote {
                    Text(lineNote.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                }
            }
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel("Step \(step.rawValue) of 4, \(step.title). \(note)")
        .accessibilityValue(spokenPlace)
        .accessibilityAddTraits(place == .here ? .isSelected : [])
    }

    private var spokenPlace: String {
        switch place {
        case .taken: return "Taken"
        case .here:  return lineNote.map { "Under way, \($0.lowercased())" } ?? "Under way"
        case .ahead: return ""
        }
    }

    private var bead: some View {
        ZStack {
            Circle()
                .fill(place == .taken ? AppColors.gold : AppColors.background)
            Circle()
                .strokeBorder(
                    place == .here ? AppColors.goldLight : AppColors.gold.opacity(place == .taken ? 0 : 0.4),
                    lineWidth: place == .here ? 1.5 : 1
                )
        }
        .frame(width: place == .here ? 15 : 10, height: place == .here ? 15 : 10)
        .shadow(color: place == .here ? AppColors.gold.opacity(0.5) : .clear, radius: 5)
    }

    /// The thread the beads hang on, running through the row's bead
    private var thread: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.gold.opacity(isFirst ? 0 : place == .ahead ? 0.2 : 0.55))
                .frame(width: 1)
            Rectangle()
                .fill(AppColors.gold.opacity(isLast ? 0 : place == .taken ? 0.55 : 0.2))
                .frame(width: 1)
        }
    }
}

// MARK: - PracticeGround

/// The singing screen's ground: the chant's painting veiled, as the
/// Scriptural Rosary sets its mystery, and a scrim deepest where the line
/// is set, so the words read over the brightest painting. While it is the
/// learner's turn the painting steps further back.
private struct PracticeGround: View {
    let painting: String
    let dimmed: Bool

    var body: some View {
        ZStack {
            AppColors.backgroundDeep

            // The painting hangs off a clear view, so its fill never
            // widens the page it stands behind
            Color.clear
                .overlay {
                    CachedAssetImage(painting, focal: .center)
                }
                .clipped()
                .opacity(dimmed ? 0.14 : 0.28)
                .animation(Motion.crossfade, value: dimmed)

            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep.opacity(0.55), location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.15), location: 0.2),
                    .init(color: AppColors.backgroundDeep.opacity(0.6), location: 0.42),
                    .init(color: AppColors.backgroundDeep.opacity(0.65), location: 0.62),
                    .init(color: AppColors.backgroundDeep.opacity(0.8), location: 0.8),
                    .init(color: AppColors.backgroundDeep.opacity(0.92), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Deepest where the line is set, so a white cloth or a sky in
            // the painting never stands behind the words
            RadialGradient(
                colors: [AppColors.backgroundDeep.opacity(0.55), AppColors.backgroundDeep.opacity(0)],
                center: UnitPoint(x: 0.5, y: 0.45),
                startRadius: 20,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - PracticeLineThread

/// How far through the chant: a hairline, gold to the line sung
private struct PracticeLineThread: View {
    let line: Int
    let count: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let fraction = count > 1 ? CGFloat(line) / CGFloat(count - 1) : 1
            let x = geometry.size.width * fraction
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.textSecondary.opacity(0.3))
                    .frame(height: 1.5)
                Capsule()
                    .fill(AppColors.gold)
                    .frame(width: max(0, x), height: 1.5)
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: 7, height: 7)
                    .shadow(color: AppColors.goldLight.opacity(0.6), radius: 4)
                    .offset(x: x - 3.5)
            }
            .frame(height: geometry.size.height)
            // The bead travels the thread, or under Reduce Motion stands
            // at the line at once
            .animation(reduceMotion ? nil : Motion.settle, value: line)
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

// MARK: - PracticeQuietControl

/// A quiet round control with its name beneath: Again, Score
private struct PracticeQuietControl: View {
    let icon: String
    let label: String
    let spokenLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                AppIcon(icon, size: 19)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(AppColors.background.opacity(0.45)))
                    .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.32), lineWidth: AppLine.hairline))
                    .frame(height: 88)
                Text(label.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.8)
                    .foregroundColor(AppColors.cream.opacity(0.7))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel(spokenLabel)
    }
}

// MARK: - PracticeTurnDisc

/// The play disc while it is the learner's turn: the seconds left, and a
/// ring of gold running down around them. A tap holds the turn, and takes
/// it up again.
private struct PracticeTurnDisc: View {
    let turn: ChantTurn
    let length: TimeInterval
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // Paused, the turn keeps what was left of it, and says so still
            TimelineView(.animation(minimumInterval: 0.05, paused: turn.endsAt == nil)) { context in
                let left = turn.endsAt.map { max(0, $0.timeIntervalSince(context.date)) } ?? turn.remaining
                let share = length > 0 ? min(1, left / length) : 0
                ZStack {
                    Circle()
                        .fill(AppColors.cardBackground)
                    Circle()
                        .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: 1)
                    Circle()
                        .trim(from: 0, to: share)
                        .stroke(AppColors.goldLight, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(1)
                    Text(String(format: "%.0f", left.rounded(.up)))
                        .font(AppFonts.titleFont(26))
                        .foregroundColor(AppColors.goldLight.opacity(turn.endsAt == nil ? 0.55 : 1))
                        .monospacedDigit()
                }
                .frame(width: 76, height: 76)
                .shadow(color: AppColors.gold.opacity(0.35), radius: 14)
            }
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel("Your turn")
        .accessibilityValue(turn.endsAt == nil ? "Held" : "Singing")
        .accessibilityHint(turn.endsAt == nil ? "Takes up your turn" : "Holds your turn")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - PracticeOptionsSheet

/// How to practise: the few settings a learner changes once, if at all,
/// kept off the singing screen behind the faders
private struct PracticeOptionsSheet: View {
    let chant: Chant
    let step: ChantLearningStep
    @Binding var repeatsWanted: Int
    @Binding var hidden: ChantPracticeView.Hiding

    @Environment(\.dismiss) private var dismiss

    private var player = ChantPlayer.shared

    init(
        chant: Chant,
        step: ChantLearningStep,
        repeatsWanted: Binding<Int>,
        hidden: Binding<ChantPracticeView.Hiding>
    ) {
        self.chant = chant
        self.step = step
        _repeatsWanted = repeatsWanted
        _hidden = hidden
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SheetHeader(kicker: step.title, title: "How to practise") {
                    SheetHeaderAction(title: "Done") { dismiss() }
                }

                if chant.hasLines {
                    SheetRow("Repeat each line", detail: "The singer sings it once, or three times") {
                        PracticeChoicePill(
                            name: "Repeat each line",
                            options: ["Once", "3 times"],
                            selected: repeatsWanted == 1 ? 0 : 1
                        ) { repeatsWanted = $0 == 0 ? 1 : 3 }
                    }
                } else {
                    SheetRow("Repeat the chant", detail: "From the top when it ends") {
                        PracticeChoicePill(
                            name: "Repeat the chant",
                            options: ["Off", "On"],
                            selected: player.repeats ? 1 : 0
                        ) { player.repeats = $0 == 1 }
                    }
                }

                SheetRow("Speed", detail: speedDetail) {
                    PracticeChoicePill(name: "Speed", options: ["Normal", "Slower"], selected: speedChoice) {
                        player.setRate($0 == 0 ? 1.0 : 0.75)
                    }
                }

                SheetRow(
                    "Hide words",
                    detail: step == .listen
                        ? "Listening shows the English alone"
                        : "Each hidden word keeps its first letter",
                    showsDivider: false
                ) {
                    PracticeChoicePill(
                        name: "Hide words",
                        options: ChantPracticeView.Hiding.allCases.map(\.title),
                        selected: ChantPracticeView.Hiding.allCases.firstIndex(of: hidden)
                    ) { hidden = ChantPracticeView.Hiding.allCases[$0] }
                    .disabled(step == .listen)
                }
            }
            .padding(.bottom, 20)
        }
    }

    /// Normal at 1×, Slower under it; neither at a pace the Lock Screen set
    private var speedChoice: Int? {
        let speed = player.speed
        if speed < 1 { return 1 }
        return abs(speed - 1) < 0.01 ? 0 : nil
    }

    private var speedDetail: String {
        speedChoice == nil
            ? "Sounding at \(ChantPlayer.speedLabel(player.speed))"
            : "Slower is three quarters of the pace"
    }
}

// MARK: - PracticeChoicePill

/// Two or three named options in one pill, the chosen one lit: a
/// segmented control to VoiceOver
private struct PracticeChoicePill: View {
    let name: String
    let options: [String]
    let selected: Int?
    let choose: (Int) -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    choose(index)
                } label: {
                    Text(option)
                        .font(AppFonts.readingFont(15))
                        .foregroundColor(index == selected ? AppColors.goldLight : AppColors.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 11)
                        .frame(minHeight: 34)
                        .background(index == selected ? AppColors.gold.opacity(0.16) : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("\(name): \(option)")
                .accessibilityAddTraits(index == selected ? .isSelected : [])
            }
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
        .frame(minHeight: 44)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(Motion.choice, value: selected)
    }
}
