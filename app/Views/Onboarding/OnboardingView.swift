//
//  OnboardingView.swift
//  Lumen Viae
//
//  First-run introduction, shown once on first launch and re-runnable
//  from About.
//
//  The order follows two things good first runs have in common: ask
//  what the person came for before showing them anything, and give
//  before asking. The notification question comes only after they have
//  prayed a few beads on the strand.
//
//    1. Welcome        what the app is, in one sentence
//    2. Intention      "What brings you to the Rosary?" Multi-select;
//                      it picks the reminder copy, the For You slide,
//                      and the last slide's first act
//    3. Voice          what you'll hear: the meditation alone, or the
//                      whole Rosary said aloud (userSettings.prayAloud)
//    4. The beads      where you will count, each way shown working: the
//                      strand on the screen swiped a bead at a time, or
//                      arrows stepping a mystery at a time for a hand on
//                      its own rosary (userSettings.prayOnBeads). Asked
//                      only with the meditation alone; with the whole
//                      Rosary aloud the voice moves the beads, and the
//                      introduction is eight slides
//    5. For you        what the app holds for the reasons chosen, in
//                      place of a tour of everything
//    6. Colors         the theme; the whole app re-themes as you tap
//    7. Language       English, Latin, or both, previewed on the Ave
//    8. Reminder       an hour already chosen (evening), so the act is
//                      one tap and says exactly what it will do
//    9. The threshold  the cross and the Sign; the button does the first
//                      step it names, or the user looks around first
//
//  Slides three and four are the "Rosary ways to pray" handoff's, in its
//  words, which the Rosary's own pages and Settings share.
//
//  The strand of progress opens with its first bead already lit: a count
//  that starts at zero reads as a long way still to go.
//
//  The words are plain on purpose. Each line says what a thing is or does
//  before it says anything beautiful about it, uses the Church's own
//  terms ("today's mysteries", "Total Consecration"), and quotes the
//  Douay-Rheims with its own numbering. No durations, no streaks, and
//  nothing said on Our Lady's behalf.
//
//  A quiet Skip rides beside the strand until the last slide. Nothing
//  asked here is required: every choice has a sound default and lives in
//  Settings afterwards.
//
//  The pages travel and nothing else does. The painting behind the slides
//  and the dark ground under their words are one layer each, standing
//  still while the slides pass over them, and both are drawn from where
//  the pages actually stand (`OnboardingStage.progress`, in page units)
//  rather than from the page that has settled — so the painting
//  crossfades under the thumb instead of waiting for the swipe to finish.
//

import SwiftUI
import UserNotifications

// MARK: - OnboardingFirstStep

/// What the last slide's button does once the introduction is over.
/// Carried out by whoever presented onboarding, because only the app's
/// own router can reach the Rosary or a page.
enum OnboardingFirstStep: Equatable {
    /// Today's mysteries, straight to prayer
    case todaysRosary
    /// How to Pray the Rosary
    case howToPray

    func perform(with router: AppRouter) {
        switch self {
        case .todaysRosary: router.run(.todaysRosary)
        case .howToPray:    router.push(.howToPray)
        }
    }
}

// MARK: - OnboardingPage

/// The nine slides, in order. At file scope because the slide layout and
/// the stage behind it are each told which slide they are drawing.
private enum OnboardingPage: Int, CaseIterable {
    case welcome, intention, voice, beads, forYou, colors, language, reminder, threshold

    /// The slides as they are shown. The beads slide stands only when the
    /// voice reads the meditation alone: with the whole Rosary said
    /// aloud, the voice moves the beads on the screen and there is
    /// nothing to choose.
    static func sequence(praysAloud: Bool) -> [OnboardingPage] {
        allCases.filter { $0 != .beads || !praysAloud }
    }
}

// MARK: - OnboardingStage

/// Where the words of one slide stand on the glass. Nonisolated because
/// `onGeometryChange` measures off the main actor.
private nonisolated struct WordsExtent: Equatable {
    var top: CGFloat
    var bottom: CGFloat

    func interpolated(to other: WordsExtent, amount: CGFloat) -> WordsExtent {
        WordsExtent(
            top: top + (other.top - top) * amount,
            bottom: bottom + (other.bottom - bottom) * amount
        )
    }
}

/// Where the pages stand, and where each slide's words stand on them.
///
/// Observed rather than held as view state so that a value changing on
/// every frame of a swipe redraws only the two layers that read it — the
/// painting and the ground under the words — and no slide.
@Observable
private final class OnboardingStage {

    /// The slides as they stand side by side. Every position below is a
    /// place in this, never a slide's own number: the beads slide comes
    /// and goes with the voice slide's answer, and the slides after it
    /// move up a place.
    var sequence: [OnboardingPage]

    /// The pages' position in page units: 2.4 means the third slide is
    /// two fifths of the way off to the left.
    var progress: CGFloat = 0

    /// The slides with any part of them on the glass: the one being left
    /// and the one arriving. Kept whole, so a slide is not rebuilt on
    /// every frame of a swipe.
    var visiblePages: ClosedRange<Int> = 0...0

    /// Where each slide's words stand, reported by the slide itself
    var wordExtents: [OnboardingPage: WordsExtent] = [:]

    /// The place the pages have settled on, or are past the middle of
    var settledIndex = 0

    /// A slide a button has turned to, whose title VoiceOver should read
    /// once it arrives. A turn made by the hand asks for nothing: the
    /// reader is already where they meant to be.
    var focusRequest: OnboardingPage?

    init(sequence: [OnboardingPage]) {
        self.sequence = sequence
    }

    /// The slide at a place in the sequence
    func page(at index: Int) -> OnboardingPage? {
        sequence.indices.contains(index) ? sequence[index] : nil
    }

    /// A slide's place in the sequence, or nil while it is not shown
    func index(of page: OnboardingPage) -> Int? {
        sequence.firstIndex(of: page)
    }

    func isVisible(_ page: OnboardingPage) -> Bool {
        index(of: page).map(visiblePages.contains) ?? false
    }

    /// The ground's extent for where the pages stand now: the slide being
    /// left and the one arriving, interpolated, so the dark breathes with
    /// the swipe instead of stepping at the end of it.
    var wordExtent: WordsExtent? {
        let low = Int(progress.rounded(.down))
        let high = Int(progress.rounded(.up))
        let lowWords = page(at: low).flatMap { wordExtents[$0] }
        let highWords = page(at: high).flatMap { wordExtents[$0] }
        guard let from = lowWords ?? highWords,
              let to = highWords ?? lowWords else { return nil }
        return from.interpolated(to: to, amount: progress - CGFloat(low))
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {

    /// Called with the step the user chose on the last slide, or nil when
    /// they would rather look around first.
    var onComplete: (OnboardingFirstStep?) -> Void

    private typealias Page = OnboardingPage

    /// The one space the words are measured in and the ground is drawn in
    static let stageSpace = "onboarding-stage"

    @State private var stage = OnboardingStage(
        sequence: OnboardingPage.sequence(praysAloud: UserSettings.shared.prayAloud)
    )

    /// The place in the sequence the pages have settled on, or are past
    /// the middle of
    @State private var currentPage = 0

    /// What the scroll is told to show, for the acts that turn the page:
    /// a slide's own number, which is its id in the scroll
    @State private var scrolledPage: Int? = Page.welcome.rawValue

    /// Set while the pages are put down for a jump across several of
    /// them (Skip), and taken up again on the other side
    @State private var pagesVeiled = false

    @State private var showMethodsSheet = false

    /// The reminder hour, chosen before the slide is ever seen. Most
    /// people keep a default, and one already set turns the slide's act
    /// into a single tap that says what it will do, where an empty choice
    /// left a grey button that could not be pressed. Nil keeps a re-run's
    /// existing reminder at its own time (`initialReminderHour`).
    @State private var selectedReminderHour: Int? = OnboardingView.initialReminderHour

    /// True once the reminder slide's act or its Not Now has been pressed
    @State private var reminderAnswered = false

    /// The time of a reminder already kept at an hour none of the slide's
    /// three choices name, offered first so a re-run can leave it be
    private let keptReminderTime: String? = OnboardingView.initialReminderHour == nil
        ? UserSettings.shared.reminderTimeLabel
        : nil

    /// Seeded from settings so re-running onboarding reflects the choice
    @State private var selectedIntentions: Set<PrayerIntention> = Set(UserSettings.shared.intentions)

    /// Seeded from settings so re-running onboarding reflects the choice
    @State private var selectedLanguage: PrayerLanguage = UserSettings.shared.prayerLanguage

    /// Whether the player hangs the strand. On unless the user has turned
    /// it off; chosen on the beads slide, where both ways are shown working.
    @State private var praysOnBeads = UserSettings.shared.prayOnBeads

    /// Whether the voice says every prayer, or reads the meditation alone
    /// (`UserSettings.prayAloud`). Chosen on the voice slide; it decides
    /// whether the beads slide is asked at all.
    @State private var praysAloud = UserSettings.shared.prayAloud

    private var totalPages: Int { stage.sequence.count }

    /// The slide after this one in the sequence as it now stands
    private func page(after page: Page) -> Page {
        stage.index(of: page).flatMap { stage.page(at: $0 + 1) } ?? .threshold
    }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            OnboardingBackdrop(stage: stage)

            OnboardingWordGround(stage: stage)

            VStack(spacing: 0) {
                header

                pages
            }
        }
        .coordinateSpace(.named(Self.stageSpace))
        .sheet(isPresented: $showMethodsSheet) {
            RosaryMethodsView()
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        // Saved as they change rather than on Continue, so a user who
        // swipes past a slide keeps what they chose on it
        .onChange(of: selectedIntentions) { _, chosen in
            UserSettings.shared.onboardingIntentions =
                PrayerIntention.allCases.filter { chosen.contains($0) }.map(\.rawValue)
        }
        .onChange(of: selectedLanguage) { _, language in
            UserSettings.shared.prayerLanguagePreference = language.rawValue
        }
        .onChange(of: praysOnBeads) { _, onBeads in
            UserSettings.shared.prayOnBeads = onBeads
        }
        .onChange(of: praysAloud) { _, aloud in
            UserSettings.shared.prayAloud = aloud
        }
    }

    // MARK: - The Pages

    /// The slides, laid side by side and turned by the hand.
    ///
    /// A paging scroll rather than a `TabView`, because the stage behind
    /// them is drawn from where the pages actually stand: a TabView's
    /// selection changes only once the swipe has settled, and the painting
    /// began its crossfade after the finger had already finished.
    private var pages: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(stage.sequence, id: \.self) { page in
                    slide(page)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(page.rawValue)
                }
            }
            .scrollTargetLayout()
            .onGeometryChange(for: CGFloat.self) { proxy in
                let pageWidth = proxy.size.width / CGFloat(totalPages)
                guard pageWidth > 0 else { return 0 }
                return -proxy.frame(in: .scrollView(axis: .horizontal)).minX / pageWidth
            } action: { measured in
                pagesMoved(to: measured)
            }
        }
        // One slide to a swipe, however hard it is thrown: paging alone
        // carries its momentum on and a flick can skip a slide, and no
        // question here may be passed over by accident.
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrolledPage)
        .opacity(pagesVeiled ? 0 : 1)
    }

    @ViewBuilder
    private func slide(_ page: Page) -> some View {
        switch page {
        case .welcome:   welcomeSlide
        case .intention: intentionSlide
        case .voice:     voiceSlide
        case .beads:     beadsSlide
        case .forYou:    forYouSlide
        case .colors:    colorsSlide
        case .language:  languageSlide
        case .reminder:  reminderSlide
        case .threshold: thresholdSlide
        }
    }

    /// The pages have moved: tell the stage, and note which slide is
    /// being read and which are on the glass at all.
    private func pagesMoved(to measured: CGFloat) {
        let position = min(max(measured, 0), CGFloat(totalPages - 1))

        // A jump across several pages (Skip) arrives as one step. A swipe
        // never moves that far in a frame, so the paintings can tell the
        // two apart: they cross-dissolve for a jump and follow the finger
        // for a swipe.
        if abs(position - stage.progress) > 1.05 {
            withAnimation(Motion.decadeTurn) { stage.progress = position }
        } else {
            stage.progress = position
        }

        let settled = Int(position.rounded())
        if settled != currentPage { currentPage = settled }
        if settled != stage.settledIndex { stage.settledIndex = settled }

        let arriving = Int(position.rounded(.down))...Int(position.rounded(.up))
        if arriving != stage.visiblePages { stage.visiblePages = arriving }
    }

    /// Turns to a slide. A neighbour is scrolled to; anything further off
    /// — Skip, from the first slide to the last — would whip six slides
    /// past the eye, so the pages are put down and taken up again on the
    /// other side while the paintings dissolve between them.
    private func go(to page: Page) {
        guard let target = stage.index(of: page), target != currentPage else { return }
        stage.focusRequest = page

        guard abs(target - currentPage) > 1 else {
            withAnimation(Motion.travel(0.4)) { scrolledPage = page.rawValue }
            return
        }

        withAnimation(Motion.ease(0.2), completionCriteria: .logicallyComplete) {
            pagesVeiled = true
        } completion: {
            var cut = Transaction()
            cut.disablesAnimations = true
            withTransaction(cut) { scrolledPage = page.rawValue }

            withAnimation(Motion.ease(0.34).delay(0.08)) { pagesVeiled = false }
        }
    }

    // MARK: - Chrome

    /// Where you are, told on a strand of beads rather than a row of dots:
    /// the app counts everything else this way. The bead of the slide
    /// you are on is already lit.
    private var header: some View {
        ZStack {
            RosaryBeadProgress(
                total: totalPages,
                completed: currentPage + 1,
                activeIndex: currentPage,
                beadSize: 8
            )
            .frame(width: 190)
            .animation(.easeInOut(duration: 0.35), value: currentPage)
            .animation(Motion.crossfade, value: totalPages)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(currentPage + 1) of \(totalPages)")

            HStack {
                Spacer()
                skipButton
            }
        }
        // Skip's height, kept after Skip has gone: sized by its contents,
        // the head shrank to the strand on the last slide and the strand
        // rose eight points as the page arrived.
        .frame(minHeight: 44)
        // Clear of the clock and the island above it: at 18 the strand
        // was crowded against the status bar rather than standing under it.
        .padding(.top, 34)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var skipButton: some View {
        if currentPage < totalPages - 1 {
            Button {
                go(to: .threshold)
            } label: {
                Text("Skip")
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 1)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .transition(.opacity)
            .accessibilityHint("Skips to the end of the introduction")
        }
    }

    private func continueButton(_ title: String, to page: Page) -> some View {
        GoldCTAButton(title: title, glyph: .chevron, action: {
            go(to: page)
        })
    }

    // MARK: - 1. Welcome

    private var welcomeSlide: some View {
        OnboardingSlideLayout(
            title: "Lumen Viae",
            titleNote: "Light of the Way",
            page: .welcome,
            stage: stage
        ) {
            OnboardingLead(
                "A quiet place to pray the Rosary, with Scripture and a meditation on each mystery.",
                italic: true
            )
        } bottomContent: {
            continueButton("Begin", to: .intention)
        }
    }

    // MARK: - 2. Intention

    private var intentionSlide: some View {
        OnboardingSlideLayout(
            title: "What Brings You to the Rosary?",
            page: .intention,
            stage: stage
        ) {
            VStack(spacing: 18) {
                OnboardingLead("Choose any that fit. Your answers shape your reminders and where we suggest you begin.")

                VStack(spacing: 10) {
                    ForEach(PrayerIntention.allCases) { intention in
                        OnboardingChoiceCard(
                            label: intention.displayName,
                            detail: intention.detail,
                            mark: .check,
                            isSelected: selectedIntentions.contains(intention)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedIntentions.contains(intention) {
                                    selectedIntentions.remove(intention)
                                } else {
                                    selectedIntentions.insert(intention)
                                }
                            }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedIntentions)
            }
        } bottomContent: {
            continueButton("Continue", to: .voice)
        }
    }

    // MARK: - 3. What You'll Hear

    private static let meditationOnlyLead =
        "The voice reads the meditation, then you say the prayers yourself."
    private static let wholeRosaryLead =
        "The voice leads every prayer, bead by bead, and you answer along."

    /// How much of the Rosary the voice says (`UserSettings.prayAloud`),
    /// asked first of the two because it decides whether the beads
    /// question is needed at all. The words are the "Rosary ways to pray"
    /// handoff's, which the Rosary's own pages and Settings share.
    private var voiceSlide: some View {
        OnboardingSlideLayout(
            // With the whole Rosary said aloud the beads question stands
            // aside, and "1 of 2" promised a second that never came
            kicker: praysAloud ? "Make it yours" : "Make it yours · 1 of 2",
            title: "What You'll Hear",
            page: .voice,
            stage: stage
        ) {
            VStack(spacing: 14) {
                OnboardingLeadSlot(
                    praysAloud ? Self.wholeRosaryLead : Self.meditationOnlyLead,
                    reserving: [Self.meditationOnlyLead, Self.wholeRosaryLead]
                )

                DecadeVoicePreview(praysAloud: praysAloud)

                VStack(spacing: 10) {
                    OnboardingChoiceCard(
                        label: "Meditation Only",
                        detail: "The meditation is read aloud; you say the prayers",
                        isSelected: !praysAloud
                    ) {
                        choose(aloud: false)
                    }

                    OnboardingChoiceCard(
                        label: "Whole Rosary",
                        detail: "Every prayer is said aloud; answer along",
                        isSelected: praysAloud
                    ) {
                        choose(aloud: true)
                    }
                }
                .sensoryFeedback(.selection, trigger: praysAloud)

                Text("Every Rosary will begin this way. You can change it on any Rosary's page, or in Settings.")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.cream.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } bottomContent: {
            continueButton("Continue", to: page(after: .voice))
        }
    }

    /// Chooses what the voice says, and stands the beads slide aside or
    /// back. That slide is the next one over, off the glass, so it comes
    /// and goes without a transition; only the strand of progress above
    /// gains or loses a bead.
    private func choose(aloud: Bool) {
        guard aloud != praysAloud else { return }
        withAnimation(Motion.ease(0.25)) { praysAloud = aloud }

        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) { stage.sequence = Page.sequence(praysAloud: aloud) }
    }

    // MARK: - 4. Where Will You Count?

    private static let onScreenLead =
        "The beads are on the screen. Swipe for each Hail Mary, and the next mystery begins on its own."
    private static let ownRosaryLead =
        "Keep count on your own beads. The screen moves a mystery at a time."

    /// The prayer screen's one new idea, tried rather than described, and
    /// chosen rather than imposed. On the screen, a strand moves under the
    /// thumb a bead at a time and turns to the next mystery by itself. On
    /// one's own rosary, the player moves a mystery at a time for a hand
    /// that keeps its own count. Whichever is chosen is the one shown
    /// working, in the same slot, so the slide never grows or jumps as it
    /// changes. The same setting Settings calls the Bead counter
    /// (`UserSettings.beadCounterTitle`), in the handoff's words.
    ///
    /// Asked only when the voice reads the meditation alone: with the
    /// whole Rosary aloud, the voice moves the beads on the screen.
    private var beadsSlide: some View {
        OnboardingSlideLayout(
            kicker: "Make it yours · 2 of 2",
            title: "Where Will You Count?",
            page: .beads,
            stage: stage
        ) {
            VStack(spacing: 18) {
                OnboardingLeadSlot(
                    praysOnBeads ? Self.onScreenLead : Self.ownRosaryLead,
                    reserving: [Self.onScreenLead, Self.ownRosaryLead]
                )

                ZStack {
                    if praysOnBeads {
                        BeadStrandDemo()
                            .transition(.opacity)
                    } else {
                        MysteryStepDemo()
                            .transition(.opacity)
                    }
                }
                .frame(height: BeadStrandDemo.height)
                .animation(Motion.crossfade, value: praysOnBeads)

                VStack(spacing: 10) {
                    OnboardingChoiceCard(
                        label: "On My Rosary",
                        detail: "Count on your own rosary; the screen moves a mystery at a time",
                        isSelected: !praysOnBeads
                    ) {
                        withAnimation(Motion.ease(0.25)) { praysOnBeads = false }
                    }

                    OnboardingChoiceCard(
                        label: "On the Screen",
                        detail: "The beads are on the screen; swipe for each Hail Mary",
                        isSelected: praysOnBeads
                    ) {
                        withAnimation(Motion.ease(0.25)) { praysOnBeads = true }
                    }
                }
                .sensoryFeedback(.selection, trigger: praysOnBeads)
            }
        } bottomContent: {
            continueButton("Continue", to: .forYou)
        }
    }

    // MARK: - 5. For You

    private var primaryIntention: PrayerIntention? {
        PrayerIntention.allCases.first { selectedIntentions.contains($0) }
    }

    /// One thing the app offers, drawn as a line with its glyph
    private struct Offer: Hashable {
        let icon: String
        let text: String
    }

    /// What the app holds for each reason, most useful first. Named
    /// plainly, with the full names a newcomer can look up, never the
    /// app's own shorthand (Consecrate, the flame, the Chapel).
    private static func offers(for intention: PrayerIntention) -> [Offer] {
        switch intention {
        case .peace:
            return [
                Offer(icon: "ph-book-open", text: "A meditation on each mystery, to read or to hear"),
                Offer(icon: "ch-bible", text: "The Scriptural Rosary, with a verse for every bead"),
                Offer(icon: "ph-note-pencil", text: "A private journal, kept only on your phone")
            ]
        case .habit:
            return [
                Offer(icon: "ph-calendar-dots", text: "Today's mysteries, set by the traditional weekday order"),
                Offer(icon: "ph-bell", text: "One gentle reminder a day, at the hour you choose"),
                Offer(icon: "ph-flame", text: "A quiet record of the days you pray")
            ]
        case .devotion:
            return [
                Offer(icon: "ch-consecration", text: "St. Louis de Montfort's 33-day preparation for Total Consecration"),
                Offer(icon: "ph-crown", text: "True Devotion to Mary, the complete book"),
                Offer(icon: "ch-sorrowful-heart", text: "The Chaplet of the Seven Sorrows")
            ]
        case .learning:
            return [
                Offer(icon: "ch-rosary", text: "How to Pray the Rosary in three short lessons, then Your First Rosary, guided"),
                Offer(icon: "ph-hands-praying", text: "Every prayer written out, in English or in Latin"),
                Offer(icon: "ph-book-open", text: "A meditation on each mystery, to read or to hear")
            ]
        }
    }

    private static let generalOffers = [
        Offer(icon: "ph-calendar-dots", text: "Today's mysteries, set by the traditional weekday order"),
        Offer(icon: "ph-book-open", text: "A meditation on each mystery, to read or to hear"),
        Offer(icon: "ch-consecration", text: "St. Louis de Montfort's 33-day preparation for Total Consecration"),
        Offer(icon: "ch-altar", text: "The 1962 Missal and the Divine Office for each day")
    ]

    /// With several reasons chosen, each one's best line comes first, so
    /// no reason is crowded out by another's second and third.
    private var offers: [Offer] {
        let lists = PrayerIntention.allCases
            .filter { selectedIntentions.contains($0) }
            .map { Self.offers(for: $0) }
        guard !lists.isEmpty else { return Self.generalOffers }

        var chosen: [Offer] = []
        for rank in 0..<3 {
            for list in lists where rank < list.count && !chosen.contains(list[rank]) {
                chosen.append(list[rank])
            }
        }
        return Array(chosen.prefix(4))
    }

    private var forYouCopy: (title: String, lead: String) {
        switch primaryIntention {
        case .peace:
            return ("Stillness in a Busy Day", "Pray one mystery at a time, with words to rest your mind on.")
        case .habit:
            return ("A Rosary Every Day", "The day's prayer is set out for you each morning.")
        case .devotion:
            return ("Closer to Our Lady", "Pray with Mary, and learn from the saints who loved her.")
        case .learning:
            return ("Learning the Rosary", "Everything you need to begin is here.")
        case nil:
            return ("What You Will Find", "The Rosary is at the heart of the app. Around it are other prayers of the Church.")
        }
    }

    private var forYouSlide: some View {
        OnboardingSlideLayout(
            title: forYouCopy.title,
            page: .forYou,
            stage: stage
        ) {
            VStack(spacing: 22) {
                OnboardingLead(forYouCopy.lead)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(offers, id: \.self) { offer in
                        OfferRow(icon: offer.icon, text: offer.text)
                    }
                }
            }
        } bottomContent: {
            VStack(spacing: 4) {
                continueButton("Continue", to: .colors)

                QuietGoldButton(title: "Kinds of Meditation", trailingIcon: "ph-caret-right") {
                    showMethodsSheet = true
                }
                .frame(minHeight: 44)
            }
        }
    }

    // MARK: - 6. Colors

    private var colorsSlide: some View {
        OnboardingSlideLayout(
            title: "Choose Your Colors",
            page: .colors,
            stage: stage
        ) {
            VStack(spacing: 18) {
                OnboardingLead("Pick the colors you find easiest to pray with. The whole app changes as you tap.")

                OnboardingThemePicker()
            }
        } bottomContent: {
            continueButton("Continue", to: .language)
        }
    }

    // MARK: - 7. Language

    private func detail(for language: PrayerLanguage) -> String {
        switch language {
        case .english:           return "Every prayer in English"
        case .latin:             return "The traditional language of the Roman liturgy"
        case .both:              return "Latin first, English beneath each line"
        case .latinUnderEnglish: return "English first, Latin beneath each line"
        }
    }

    /// Three choices, not four. English-first pairing is kept for Settings
    /// and shown here only to someone who has already chosen it, so a
    /// re-run never hides the choice they made.
    private var languageChoices: [PrayerLanguage] {
        PrayerLanguage.allCases.filter { $0 != .latinUnderEnglish || selectedLanguage == .latinUnderEnglish }
    }

    private var languageSlide: some View {
        OnboardingSlideLayout(
            title: "Choose a Language",
            page: .language,
            stage: stage
        ) {
            VStack(spacing: 16) {
                OnboardingLead("Pray in English, in Latin, or in both, with the English beneath each line of Latin.")

                LanguagePreviewCard(language: selectedLanguage)

                VStack(spacing: 10) {
                    ForEach(languageChoices) { language in
                        OnboardingChoiceCard(
                            label: language.rawValue,
                            detail: detail(for: language),
                            isSelected: selectedLanguage == language
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedLanguage = language
                            }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedLanguage)
            }
        } bottomContent: {
            continueButton("Continue", to: .reminder)
        }
    }

    // MARK: - 8. Reminder

    /// Label, the hour as the button says it, the row's detail, and the
    /// hour (24h). Noon is an hour of the Angelus; morning and evening are
    /// not tied to it, so they do not claim it.
    private static let reminderOptions: [(label: String, spoken: String, detail: String, hour: Int)] = [
        ("Morning", "6 AM", "6 AM, to begin the day with prayer", 6),
        ("Noon", "Noon", "12 PM, when the Angelus bells ring", 12),
        ("Evening", "8 PM", "8 PM, to end the day with prayer", 20)
    ]

    /// The reminder slide's first choice. A first run offers evening. A
    /// re-run starts from the reminder already kept — its hour when it is
    /// one of the three, nil (keep it as it is) when it is not — because
    /// one tap on the slide's act would otherwise move a 6:45 AM reminder
    /// to 8 PM.
    private static var initialReminderHour: Int? {
        let settings = UserSettings.shared
        guard UserDefaults.standard.bool(forKey: "hasSeenOnboarding"),
              settings.remindersEnabled else { return 20 }
        let offered = settings.reminderMinute == 0
            && reminderOptions.contains { $0.hour == settings.reminderHour }
        return offered ? settings.reminderHour : nil
    }

    private var reminderSlide: some View {
        let denied = UserSettings.shared.notificationAuthorizationDenied
        let spoken = selectedReminderHour
            .flatMap { hour in Self.reminderOptions.first { $0.hour == hour }?.spoken }
            ?? keptReminderTime
            ?? ""

        return OnboardingSlideLayout(
            title: "A Daily Reminder",
            page: .reminder,
            stage: stage
        ) {
            VStack(spacing: 18) {
                OnboardingLead("Choose a time, and we will send one gentle reminder each day.")

                VStack(spacing: 10) {
                    if let keptReminderTime {
                        OnboardingChoiceCard(
                            label: "Your Current Time",
                            detail: "\(keptReminderTime), as you set it",
                            isSelected: selectedReminderHour == nil
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedReminderHour = nil
                            }
                        }
                    }

                    ForEach(Self.reminderOptions, id: \.hour) { option in
                        OnboardingChoiceCard(
                            label: option.label,
                            detail: option.detail,
                            isSelected: selectedReminderHour == option.hour
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedReminderHour = option.hour
                            }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedReminderHour)

                // The system prompt is raised by this slide's own button,
                // so a refusal happens in plain sight. Until then the line
                // says the question is coming, so the iPhone's own words
                // are expected rather than sprung; afterwards it keeps a
                // refusal in sight rather than letting the user leave
                // believing an hour was set that can never ring.
                Text(denied
                     ? "Notifications are off for Lumen Viae. Turn them on in the Settings app, then choose a time in Settings, under Devotion."
                     : UserSettings.shared.notificationAuthorizationGranted
                        ? "You can change the time or turn it off in Settings."
                        : "Your iPhone will then ask once whether Lumen Viae may send it. You can change the time or turn it off in Settings.")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.cream.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } bottomContent: {
            VStack(spacing: 4) {
                GoldCTAButton(
                    title: denied ? "Continue" : "Remind Me at \(spoken)",
                    action: reminderAct
                )

                QuietGoldButton(title: "Not Now") {
                    reminderAnswered = true
                    UserSettings.shared.remindersEnabled = false
                    go(to: .threshold)
                }
                .frame(minHeight: 44)
            }
        }
    }

    private func reminderAct() {
        reminderAnswered = true
        // Already refused: there is no hour left to set, so the button's
        // only remaining job is to move on.
        guard !UserSettings.shared.notificationAuthorizationDenied else {
            go(to: .threshold)
            return
        }
        // Hold this slide until the system has asked and been answered.
        // Raised from a property observer's detached Task, the dialog
        // landed on the next slide, with nothing on screen explaining what
        // was being asked.
        Task {
            let settings = UserSettings.shared

            // The system's question first, asked once. Each setting below
            // syncs the reminder as it changes, and set while the question
            // was still open each put a request of its own: the system
            // answered all but the one it showed with "not allowed", and
            // those switched the chosen reminder off while the slide moved
            // on as though it were set.
            let center = UNUserNotificationCenter.current()
            if await center.notificationSettings().authorizationStatus == .notDetermined {
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                guard granted else {
                    // As a refusal always has: the reminder put off, and
                    // the slide's line saying where to undo it
                    settings.remindersEnabled = false
                    await settings.refreshNotificationsWithoutPrompting()
                    return
                }
            }

            // Nil keeps the time the reminder already had
            if let hour = selectedReminderHour {
                settings.reminderHour = hour
                settings.reminderMinute = 0
            }
            settings.remindersEnabled = true
            await settings.syncNotifications()
            // A refusal earns a beat: the line on the slide now says what
            // happened and where to undo it.
            guard !settings.notificationAuthorizationDenied else { return }
            go(to: .threshold)
        }
    }

    /// A reminder is on until someone says otherwise, and the permission
    /// it needs is asked for on the reminder slide alone. Skipped or
    /// swiped past, that question was never put, and Settings would show
    /// a reminder switched on that could never ring. It is put off
    /// instead, honestly; the Settings switch asks when it is turned on.
    /// A reminder the phone already allows is left as it is.
    private func settleUnaskedReminder() {
        guard !reminderAnswered else { return }
        Task {
            let status = await UNUserNotificationCenter.current()
                .notificationSettings().authorizationStatus
            guard status == .notDetermined else { return }
            UserSettings.shared.remindersEnabled = false
        }
    }

    // MARK: - 9. The Threshold

    /// A Rosary is begun with the cross in your hand and the Sign, so the
    /// last slide is set as the first moment of the prayer: the crucifix,
    /// and the words said while holding it.
    ///
    /// Its button does what it says. "Enter" used to land the user on the
    /// home screen and leave them to find the Rosary; now it opens today's
    /// mysteries, or, for someone learning, the guide to praying them.
    private var firstStep: (title: String, glyph: GoldCTAButton.Glyph, step: OnboardingFirstStep) {
        selectedIntentions.contains(.learning)
            ? ("Learn How to Pray It", .chevron, .howToPray)
            : ("Pray Today's Rosary", .play, .todaysRosary)
    }

    /// The closing line for the reason given. Learning speaks first when it
    /// is among them, because its first step is different from the rest.
    private var closingLine: String {
        if selectedIntentions.contains(.learning) {
            // Only a promise the chosen way of praying keeps: the strand
            // on the screen counts, and so does a voice that says every
            // prayer and moves the beads with it
            return praysOnBeads || praysAloud
                ? "Everyone who prays the Rosary began with one Hail Mary. The app counts the beads for you."
                : "Everyone who prays the Rosary began with one Hail Mary."
        }
        switch primaryIntention {
        case .peace:
            return "May each decade bring you stillness. Today's mysteries are ready when you are."
        case .habit:
            return "Faithfulness grows one day at a time. Begin with today's mysteries."
        case .devotion:
            return "With Mary, we look on the face of Christ in every mystery."
        case .learning, nil:
            return "Today's mysteries are ready when you are."
        }
    }

    private var thresholdSlide: some View {
        OnboardingSlideLayout(
            title: "In the Name of the Father",
            usesCross: true,
            page: .threshold,
            stage: stage
        ) {
            VStack(spacing: 16) {
                Text("and of the Son, and of the Holy Spirit. Amen.")
                    .font(AppFonts.italicFont(16))
                    .foregroundColor(AppColors.accentSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    // No ornament divider beneath: its own small cross
                    // stood under the struck one, two crosses for one idea
                    .padding(.bottom, 6)

                OnboardingLead(closingLine, italic: true)
            }
        } bottomContent: {
            VStack(spacing: 4) {
                GoldCTAButton(title: firstStep.title, glyph: firstStep.glyph) {
                    settleUnaskedReminder()
                    onComplete(firstStep.step)
                }

                QuietGoldButton(title: "Look Around First") {
                    settleUnaskedReminder()
                    onComplete(nil)
                }
                .frame(minHeight: 44)
            }
        }
    }
}

// MARK: - OnboardingBackdrop

/// The paintings behind the slides: one layer, standing still while the
/// pages travel over it, crossfading from where the pages actually are
/// rather than from the page that has settled.
///
/// They used to fill the whole screen under a scrim, and the words were
/// set across the painting wherever they happened to fall: the title over
/// somebody's face, the cross medallion on Our Lady's. Hung high and
/// dissolved to clear, a painting keeps its faces in the light and the
/// words stand on the page's own dark ground. It ends in nothing, never
/// in a flat colour, because the page beneath is a different shade at
/// every height.
private struct OnboardingBackdrop: View {

    let stage: OnboardingStage

    /// How far down the glass a painting hangs before it has gone
    static let reach: CGFloat = 0.72

    /// The paintings the slides are set against, chosen for what each
    /// slide asks: the Annunciation for a beginning · the Finding in the
    /// Temple for what a soul comes looking for · Cana, where Our Lady
    /// says "whatsoever he shall say to you, do ye", for what you will
    /// hear · the Visitation for a journey made step by step · the
    /// Nativity for a gift laid out · the Transfiguration for choosing a
    /// light · Pentecost for tongues · the Agony for "could you not watch
    /// one hour with me" · the Coronation for the send-off.
    private static let paintings: [OnboardingPage: String] = [
        .welcome: "joyful_annunciation",
        .intention: "joyful_finding",
        .voice: "luminous_cana",
        .beads: "joyful_visitation",
        .forYou: "joyful_nativity",
        .colors: "luminous_transfiguration",
        .language: "glorious_pentecost",
        .reminder: "sorrowful_agony",
        .threshold: "glorious_coronation"
    ]

    /// The painting being left, at full strength, with the one arriving
    /// over it at the fraction of the way the pages have come. Known by
    /// its slide rather than its place, because the beads slide coming
    /// and going moves every slide after it up or down a place.
    private struct Layer: Identifiable {
        let id: OnboardingPage
        let name: String
        let opacity: Double
    }

    private var layers: [Layer] {
        let low = Int(stage.progress.rounded(.down))
        let high = Int(stage.progress.rounded(.up))
        let arriving = Double(stage.progress - CGFloat(low))

        var stacked: [Layer] = []
        if let page = stage.page(at: low), let name = Self.paintings[page] {
            stacked.append(Layer(id: page, name: name, opacity: 1))
        }
        if high != low, arriving > 0.001,
           let page = stage.page(at: high), let name = Self.paintings[page] {
            stacked.append(Layer(id: page, name: name, opacity: arriving))
        }
        return stacked
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ForEach(layers) { layer in
                    OnboardingPainting(
                        imageName: layer.name,
                        size: CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height * Self.reach
                        )
                    )
                    .opacity(layer.opacity)
                    .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            // One dissolve over the pair, never one each: masked
            // separately, the painting underneath read through the
            // dissolve even where the one arriving was already opaque,
            // and it popped as it left.
            .mask(alignment: .top) {
                LinearGradient(
                    // Gone well before the slide's longest body reaches
                    // up into it: the busier paintings (the
                    // Transfiguration's crowd, Cana's table) read
                    // through the words at anything later
                    gradient: Gradient.smoothDissolve(from: 0.32, to: 0.9),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: geometry.size.height * Self.reach)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// One painting, hung in the top of the glass.
///
/// Built afresh each time it comes into view on purpose: it arrives a
/// touch large and settles over several seconds, so the artwork keeps
/// drifting after the swipe has finished, the way a held shot does.
private struct OnboardingPainting: View {

    let imageName: String
    let size: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Flipped on appear: one way, once.
    @State private var settled = false

    var body: some View {
        CachedAssetImage(imageName, focal: UnitPoint(x: 0.5, y: 0.3))
            .frame(width: size.width, height: size.height)
            .scaleEffect(settled || reduceMotion ? 1 : 1.08, anchor: .top)
            .animation(reduceMotion ? nil : .easeOut(duration: 11), value: settled)
            .clipped()
            .overlay(veil)
            .onAppear { settled = true }
    }

    /// Mixed in the theme's own deep ground, so the colors chosen on slide
    /// five change the light on the painting at once. Heaviest at the
    /// head, where the strand of progress and Skip are read against it.
    private var veil: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.backgroundDeep.opacity(0.6), location: 0),
                .init(color: AppColors.backgroundDeep.opacity(0.16), location: 0.2),
                .init(color: AppColors.backgroundDeep.opacity(0.2), location: 0.5),
                .init(color: AppColors.backgroundDeep.opacity(0.55), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - OnboardingWordGround

/// The page's own dark under the words, as one layer that stands still
/// while the pages travel over it.
///
/// It used to be drawn behind each slide's own words, sixty points wider
/// than the slide on either side so that it would have no edge for the
/// eye to find. Side by side during a swipe, two of them overlapped in
/// the gutter, and the overlap read as a black band standing between the
/// slides — one of them arriving, besides, before its slide did. There is
/// one ground now, and its head and foot are interpolated between the
/// slide being left and the one arriving, so it breathes with the swipe
/// instead of sliding with it.
///
/// Darkest from just above the title, where the painting is still strong,
/// and dissolved to nothing at both ends, because the page beneath it is
/// a different shade at every height.
private struct OnboardingWordGround: View {

    let stage: OnboardingStage

    /// How far above the words the dark begins, and how far past their
    /// foot it has gone
    private static let rise: CGFloat = 90
    private static let fall: CGFloat = 40

    @State private var appeared = false

    var body: some View {
        GeometryReader { geometry in
            if let extent = stage.wordExtent {
                let top = extent.top - Self.rise

                LinearGradient(
                    stops: [
                        .init(color: AppColors.backgroundDeep.opacity(0), location: 0),
                        .init(color: AppColors.backgroundDeep.opacity(0.78), location: 0.2),
                        .init(color: AppColors.backgroundDeep.opacity(0.7), location: 0.75),
                        .init(color: AppColors.backgroundDeep.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(
                    width: geometry.size.width,
                    height: max(extent.bottom + Self.fall - top, 0)
                )
                .offset(y: top)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.55), value: appeared)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { appeared = true }
    }
}

// MARK: - OnboardingSlideLayout

/// The sizes a slide is set in. A slide takes the roomy metrics when they
/// fit the screen and the tight ones when they don't, so a short phone
/// loses air rather than gaining a scroll bar.
private struct SlideMetrics {
    let title: CGFloat
    let spacing: CGFloat
    let cross: CGFloat

    static let roomy = SlideMetrics(title: 27, spacing: 16, cross: 40)
    static let tight = SlideMetrics(title: 23, spacing: 11, cross: 30)
}

/// A slide: title, body, and fixed buttons at the foot.
///
/// The body settles at the foot of the page, beside its act, and the room
/// above it is left to the painting. A slide is meant to be taken in at a
/// glance, so it is sized to the screen rather than scrolled:
/// `ViewThatFits` tries the roomy metrics, then the tight ones, and
/// scrolls only as the last resort (the largest accessibility text sizes).
///
/// Everything is centred. Some slides once set a left-aligned paragraph
/// under a centred title, and the page read as two layouts at once.
private struct OnboardingSlideLayout<Content: View, Bottom: View>: View {

    /// Small engraved capitals over the title, naming the pair of slides
    /// that make the Rosary one's own ("MAKE IT YOURS · 1 OF 2")
    let kicker: String?

    let title: String

    /// Small capitals under the title (the welcome's translation)
    let titleNote: String?

    /// Strikes the Latin cross above the title. The last slide only,
    /// where it is the crucifix a Rosary is begun on.
    let usesCross: Bool

    /// Which slide this is. It tells the stage where its words stand —
    /// the dark ground under them is drawn there, once for all eight —
    /// and reads back from it whether the slide is on the glass yet.
    let page: OnboardingPage
    let stage: OnboardingStage

    let content: () -> Content
    let bottomContent: () -> Bottom

    init(
        kicker: String? = nil,
        title: String,
        titleNote: String? = nil,
        usesCross: Bool = false,
        page: OnboardingPage,
        stage: OnboardingStage,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder bottomContent: @escaping () -> Bottom
    ) {
        self.kicker = kicker
        self.title = title
        self.titleNote = titleNote
        self.usesCross = usesCross
        self.page = page
        self.stage = stage
        self.content = content
        self.bottomContent = bottomContent
    }

    /// True once this slide has played its entrance (plays only once)
    @State private var revealed = false

    /// VoiceOver's place, moved to the title when a button has turned the
    /// page here. Left alone, it stayed on the Continue that had just
    /// been pressed, a page away and off the glass.
    @AccessibilityFocusState private var titleFocused: Bool

    private var isSettledHere: Bool { stage.index(of: page) == stage.settledIndex }

    /// True once any part of the slide is on the glass. The entrance
    /// plays as the slide arrives rather than once it has landed: a slide
    /// that waits for the swipe to settle comes in blank and fills
    /// afterwards, in plain sight.
    private var isArriving: Bool { stage.isVisible(page) }

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .vertical) {
                slideBody(.roomy)
                slideBody(.tight)
                // The last resort, for the largest accessibility text
                // sizes. It must not bounce when the words already fit:
                // a scroll view with nothing to scroll still swallows the
                // sideways drag that turns the page, and the beads slide,
                // the tallest of the eight, could not be swiped off.
                ScrollView(showsIndicators: false) { slideBody(.tight) }
                    .scrollBounceBehavior(.basedOnSize)
            }

            // No ground of its own. A fade to the page colour used to sit
            // behind the buttons and showed as a band across every slide:
            // the page beneath is darker than that colour at the foot.
            //
            // The slide is sized to the paging scroll view's container,
            // which runs under the home indicator, so the act has to ask
            // for that clearance itself: without it the button sat on the
            // very edge of the glass with the indicator across its foot.
            bottomContent()
                .padding(.horizontal, 28)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .safeAreaPadding(.bottom)
                .staggeredReveal(revealed, delay: 0.3)
        }
        .onAppear {
            if isArriving { revealed = true }
        }
        .onChange(of: isArriving) { _, arriving in
            if arriving { revealed = true }
        }
        .onChange(of: isSettledHere) { _, here in
            guard here, stage.focusRequest == page else { return }
            stage.focusRequest = nil
            titleFocused = true
        }
    }

    private func slideBody(_ metrics: SlideMetrics) -> some View {
        VStack(spacing: metrics.spacing) {
            Spacer(minLength: 0)

            // Where the words stand is reported rather than shaded here:
            // the painting's fade is fixed to the glass, but a slide's
            // words are not — a tall one (four choices, a preview)
            // reaches up into the crowd of the Transfiguration or Cana's
            // table, and the faces read through the title. The one ground
            // follows the words of whichever slides are on the glass.
            words(metrics)
                .reportsWordExtent { stage.wordExtents[page] = $0 }

            Spacer(minLength: 0)
                .frame(maxHeight: 26)
        }
        .frame(maxWidth: .infinity)
    }

    private func words(_ metrics: SlideMetrics) -> some View {
        VStack(spacing: metrics.spacing) {
            if usesCross {
                LatinCross()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: metrics.cross * 0.64, height: metrics.cross)
                    .shadow(color: AppColors.gold.opacity(0.45), radius: 12)
                    .padding(.bottom, 2)
                    .staggeredReveal(revealed, delay: 0)
            }

            VStack(spacing: 10) {
                if let kicker {
                    Text(kicker.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(Motion.crossfade, value: kicker)
                }

                Text(title)
                    .font(AppFonts.headlineFont(metrics.title))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(Motion.crossfade, value: title)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)

                if let titleNote {
                    Text(titleNote.uppercased())
                        .font(AppFonts.labelFont(11))
                        .tracking(4)
                        .foregroundColor(AppColors.gold)
                }
            }
            .shadow(color: AppColors.backgroundDeep.opacity(0.9), radius: 10)
            .padding(.horizontal, 24)
            .staggeredReveal(revealed, delay: 0.08)

            content()
                .padding(.horizontal, 28)
                // Never let a line be squeezed to one row and cut with an
                // ellipsis: without this a body text silently compresses
                // rather than let the tight metrics, or the scroll, be chosen.
                .fixedSize(horizontal: false, vertical: true)
                .staggeredReveal(revealed, delay: 0.18)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Staggered Reveal Modifier

private extension View {
    /// Fades and floats content in after `delay` once `revealed` is true.
    func staggeredReveal(_ revealed: Bool, delay: Double) -> some View {
        modifier(StaggeredReveal(revealed: revealed, delay: delay))
    }

    /// Reports where a slide's words stand on the glass.
    func reportsWordExtent(_ report: @escaping (WordsExtent) -> Void) -> some View {
        modifier(WordExtentReporter(report: report))
    }
}

/// A slide's parts arriving one after another, each rising a little as it
/// fades in. Under Reduce Motion the rise and the stagger fall away and
/// the fade is shorter; the crossfade itself remains.
private struct StaggeredReveal: ViewModifier {
    let revealed: Bool
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed || reduceMotion ? 0 : 14)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.3)
                    : .easeOut(duration: 0.55).delay(delay),
                value: revealed
            )
    }
}

/// Tells the stage where one slide's words stand, measured in the stage's
/// own space so that the ground under them can be drawn once for all
/// eight slides.
///
/// The report waits on the view appearing: `ViewThatFits` measures
/// candidates it does not draw, and a slide set in metrics that were
/// never chosen must not be the one the ground is sized to.
private struct WordExtentReporter: ViewModifier {

    let report: (WordsExtent) -> Void

    @State private var measured: WordsExtent?
    @State private var drawn = false

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: WordsExtent.self) { proxy in
                let frame = proxy.frame(in: .named(OnboardingView.stageSpace))
                return WordsExtent(top: frame.minY, bottom: frame.maxY)
            } action: { extent in
                measured = extent
                if drawn { report(extent) }
            }
            .onAppear {
                drawn = true
                if let measured { report(measured) }
            }
    }
}

// MARK: - Supporting Components

/// A slide's lead sentence, centred under its title
private struct OnboardingLead: View {
    let text: String
    var italic = false

    init(_ text: String, italic: Bool = false) {
        self.text = text
        self.italic = italic
    }

    var body: some View {
        Text(text)
            .font(italic ? AppFonts.italicFont(17) : AppFonts.bodyFont(16))
            .foregroundColor(AppColors.cream.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(ReadingTypography.lineSpacing(for: 16) * 0.7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .shadow(color: AppColors.backgroundDeep.opacity(0.9), radius: 8)
    }
}

/// A lead whose words change with the slide's choice. One slot, as tall
/// as the longest of its sentences, with the new sentence crossfading
/// whole over the old: a lead that re-wrapped as it faded, a line longer
/// or shorter, pushed everything beneath it up and down with each tap.
private struct OnboardingLeadSlot: View {
    let text: String
    let alternatives: [String]

    init(_ text: String, reserving alternatives: [String]) {
        self.text = text
        self.alternatives = alternatives
    }

    var body: some View {
        ZStack {
            ForEach(alternatives, id: \.self) { alternative in
                OnboardingLead(alternative)
                    .hidden()
            }

            OnboardingLead(text)
                .id(text)
                .transition(.opacity)
        }
        .animation(Motion.crossfade, value: text)
    }
}

/// The voice slide's decade: its four parts, and who says each. The
/// meditation is always the voice's; the prayers are yours unless the
/// whole Rosary is said aloud.
private struct DecadeVoicePreview: View {
    let praysAloud: Bool

    private static let parts = ["The meditation", "Our Father", "Ten Hail Marys", "Glory Be"]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.parts.enumerated()), id: \.offset) { index, part in
                row(part, byVoice: index == 0 || praysAloud)
            }
        }
        .overlay(alignment: .top) { rule }
        .animation(Motion.ease(0.25), value: praysAloud)
    }

    private func row(_ part: String, byVoice: Bool) -> some View {
        HStack(spacing: 12) {
            Text(part)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .trailing) {
                tag(byVoice: byVoice)
                    .id(byVoice)
                    .transition(.opacity)
            }
        }
        .frame(minHeight: 40)
        .overlay(alignment: .bottom) { rule }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(part): \(byVoice ? "said by the voice" : "said by you")")
    }

    private func tag(byVoice: Bool) -> some View {
        HStack(spacing: 5) {
            AppIcon(byVoice ? "ph-speaker-high" : "ph-hands-praying", size: 12)
            Text(byVoice ? "VOICE" : "YOU")
                .font(AppFonts.labelFont(9))
                .tracking(1.8)
        }
        .foregroundColor(byVoice ? AppColors.goldLight : AppColors.textSecondary)
    }

    private var rule: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.2))
            .frame(height: AppLine.hairline)
    }
}

/// A choice on any slide, drawn as the "Rosary ways to pray" handoff
/// draws the voice and beads slides' choices: the name over one italic
/// line, a mark at the trailing edge, and the chosen card washed in gold.
/// One card for every slide, so a question reads the same whichever slide
/// asks it.
private struct OnboardingChoiceCard: View {

    /// A radio where one choice excludes the others; a check where any
    /// number may be chosen (the reasons for coming)
    enum Mark {
        case radio, check
    }

    let label: String
    let detail: String
    let mark: Mark
    let isSelected: Bool
    let action: () -> Void

    init(
        label: String,
        detail: String,
        mark: Mark = .radio,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.detail = detail
        self.mark = mark
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(AppFonts.titleFont(14))
                        .foregroundColor(AppColors.cream)

                    Text(detail)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                switch mark {
                case .radio:
                    OnboardingRadio(isOn: isSelected)
                case .check:
                    if isSelected {
                        AppIcon("ph-check-circle-fill", size: 20)
                            .foregroundColor(AppColors.gold)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    } else {
                        AppIcon("ph-circle", size: 20)
                            .foregroundColor(AppColors.gold.opacity(0.35))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppColors.gold.opacity(0.07) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(isSelected ? 0.7 : 0.18), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.ease(0.25), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The handoff's radio: a thick ring in gold light when chosen, a fine
/// one in gold when not
private struct OnboardingRadio: View {
    let isOn: Bool

    var body: some View {
        Circle()
            .strokeBorder(
                isOn ? AppColors.goldLight : AppColors.gold.opacity(0.35),
                lineWidth: isOn ? 5 : 1.2
            )
            .frame(width: 18, height: 18)
    }
}

/// One thing the app offers: a glyph in its disc and a line beside it
private struct OfferRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(width: 36, height: 36)
                AppIcon(icon, size: 16)
                    .foregroundColor(AppColors.gold)
            }

            Text(text)
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream.opacity(0.88))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Slide three: the strand the prayer screen hangs, working.
///
/// The same `RosaryStrandView` and the same arithmetic as both players, so
/// what is learned here is exactly what happens there: swipe down for the
/// next bead, up for the one before, the Glory Be said on the next
/// decade's Our Father bead, and the mystery turning on its own with the
/// ripple and the medium beat. The Joyful Mysteries, as the familiar set.
private struct BeadStrandDemo: View {

    private static let strand = RosaryStrand(decades: 5, hailMarys: 10)

    /// Six beads' length of string in the window. The slide's demo slot is
    /// held to it in both ways of praying, so choosing never moves the page.
    static let height = RosaryStrandView.rowHeight * 6

    private static let mysteries = [
        "The Annunciation",
        "The Visitation",
        "The Nativity",
        "The Presentation",
        "The Finding in the Temple"
    ]

    private static let ordinals = ["First", "Second", "Third", "Fourth", "Fifth"]

    @State private var mystery = 0
    @State private var bead = 0
    @State private var dragOffset: CGFloat = 0
    @State private var turnPulse = 0

    /// False until the first bead is moved; until then the column says
    /// what to do instead of what to pray
    @State private var hasMoved = false

    private var strand: RosaryStrand { Self.strand }
    private var position: BeadPosition { BeadPosition(mystery: mystery, bead: bead) }
    private var isAtStart: Bool { mystery == 0 && bead == 0 }
    private var isAtEnd: Bool { mystery == strand.decades - 1 && bead == strand.decadeLength }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            reading

            RosaryStrandView(
                strand: strand,
                activeIndex: strand.index(mystery: mystery, bead: bead),
                height: Self.height,
                dragOffset: dragOffset,
                turnPulse: turnPulse,
                activeLabel: strand.labelLines(bead: bead)
            )
        }
        .frame(height: Self.height)
        .contentShape(Rectangle())
        // Simultaneous, so a sideways swipe begun on the beads still
        // turns the onboarding page
        .simultaneousGesture(swipe)
        .onTapGesture { step(forward: true) }
        .sensoryFeedback(.selection, trigger: position)
        .sensoryFeedback(.impact(weight: .medium), trigger: turnPulse)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Practice beads. The \(Self.ordinals[mystery]) Joyful Mystery, \(strand.label(bead: bead))")
        .accessibilityHint("Swipe up or down to move between beads")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(forward: true)
            case .decrement: step(forward: false)
            @unknown default: break
            }
        }
    }

    /// The mystery, and the first words of the prayer on this bead. Both
    /// hold their room whatever they say, so nothing moves as they change.
    private var reading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The \(Self.ordinals[mystery]) Joyful Mystery".uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.opacity)

            Text(Self.mysteries[mystery])
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.cream)
                .lineLimit(2, reservesSpace: true)
                .contentTransition(.opacity)

            ZStack(alignment: .topLeading) {
                Text(hasMoved ? openingWords : "Try it here. Swipe down on the beads.")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.cream.opacity(hasMoved ? 0.8 : 0.62))
                    .lineLimit(4, reservesSpace: true)
                    .id(hasMoved ? prayerKind : "hint")
                    .transition(.opacity)
            }
        }
        .animation(Motion.words, value: position)
        .animation(Motion.crossfade, value: hasMoved)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var prayerKind: String {
        if bead == 0 { return "our-father" }
        return bead > strand.hailMarys ? "glory-be" : "hail-mary"
    }

    private var openingWords: String {
        switch prayerKind {
        case "our-father": return "Our Father, who art in heaven, hallowed be thy name."
        case "glory-be":   return "Glory be to the Father, and to the Son, and to the Holy Spirit."
        default:           return "Hail Mary, full of grace, the Lord is with thee."
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let travel = value.translation.height
                guard abs(travel) > abs(value.translation.width) else { return }
                dragOffset = RosaryStrandView.follow(travel, resisted: travel > 0 ? isAtEnd : isAtStart)
            }
            .onEnded { value in
                let travel = value.translation.height
                let isVertical = abs(travel) > abs(value.translation.width)
                if isVertical, travel > 28, !isAtEnd {
                    step(forward: true)
                } else if isVertical, travel < -28, !isAtStart {
                    step(forward: false)
                } else {
                    withAnimation(Motion.beadSettle) { dragOffset = 0 }
                }
            }
    }

    /// One bead along the string. From a decade's Glory Be the hand moves
    /// to the next mystery on the same bead, so the string stays put and
    /// the ripple marks the turn.
    private func step(forward: Bool) {
        withAnimation(Motion.beadSlide) {
            dragOffset = 0
            if forward {
                guard !isAtEnd else { return }
                if bead < strand.decadeLength {
                    bead += 1
                } else {
                    mystery += 1
                    bead = 0
                    turnPulse += 1
                }
            } else {
                guard !isAtStart else { return }
                if bead > 0 {
                    bead -= 1
                } else {
                    mystery -= 1
                    bead = strand.decadeLength
                }
            }
            hasMoved = true
        }
    }
}

/// Slide three without the beads: the decade-at-a-time screen, for a hand
/// that keeps its own count. Arrows step between the mysteries, as they
/// flank the player's transport, and nothing counts the Hail Marys.
private struct MysteryStepDemo: View {

    private static let mysteries = [
        "The Annunciation",
        "The Visitation",
        "The Nativity",
        "The Presentation",
        "The Finding in the Temple"
    ]

    private static let ordinals = ["First", "Second", "Third", "Fourth", "Fifth"]

    @State private var mystery = 0

    var body: some View {
        VStack(spacing: 18) {
            // The five mysteries as a strand of their own, prayed ones lit
            HStack(spacing: 14) {
                ForEach(0..<Self.mysteries.count, id: \.self) { index in
                    RosaryBead(
                        state: index < mystery ? .prayed : (index == mystery ? .active : .ahead),
                        size: 13
                    )
                }
            }
            .animation(Motion.beadSlide, value: mystery)

            VStack(spacing: 6) {
                Text("The \(Self.ordinals[mystery]) Joyful Mystery".uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
                    .contentTransition(.opacity)

                Text(Self.mysteries[mystery])
                    .font(AppFonts.headlineFont(19))
                    .foregroundColor(AppColors.cream)
                    .contentTransition(.opacity)
            }
            .animation(Motion.words, value: mystery)

            HStack(spacing: 16) {
                arrow("ph-caret-left", label: "Previous mystery", enabled: mystery > 0) {
                    mystery -= 1
                }

                Text("Ten Hail Marys, counted on your own rosary")
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                arrow("ph-caret-right", label: "Next mystery", enabled: mystery < Self.mysteries.count - 1) {
                    mystery += 1
                }
            }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: mystery)
    }

    private func arrow(
        _ icon: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(Motion.settle) { action() }
        } label: {
            AppIcon(icon, size: 16)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
                )
                .contentShape(Circle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label)
    }
}

/// The three palettes. Selecting one re-themes the entire app instantly
/// (ThemeManager is @Observable and every colour flows through
/// AppColors), so the onboarding itself is the live preview.
private struct OnboardingThemePicker: View {

    /// Observed so the checkmark moves the moment the theme changes
    private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 10) {
            ForEach(AppTheme.allCases) { theme in
                OnboardingThemeRow(
                    theme: theme,
                    isSelected: themeManager.current == theme
                ) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        ThemeManager.shared.current = theme
                    }
                }
            }

            // A line for each palette, the small reward for trying them.
            // One slot, crossfading, with its room held for two lines so
            // the rows above never move.
            ZStack {
                verse(for: themeManager.current)
                    .id(themeManager.current)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .animation(Motion.crossfade, value: themeManager.current)
        }
        .sensoryFeedback(.selection, trigger: themeManager.current)
    }

    /// Scripture in the Douay-Rheims, with its own numbering, as the
    /// rest of the app quotes it
    private func words(for theme: AppTheme) -> (text: String, source: String) {
        switch theme {
        case .marianBlue: return ("“Tota pulchra es, Maria.” Thou art all fair, O Mary.", "Antiphon of the Immaculate Conception")
        case .midnight:   return ("“Be still and see that I am God.”", "Psalm 45:11")
        case .candlelit:  return ("“Thy word is a lamp to my feet.”", "Psalm 118:105")
        }
    }

    private func verse(for theme: AppTheme) -> some View {
        let words = words(for: theme)
        return VStack(spacing: 6) {
            Text(words.text)
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.accentSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)

            Text(words.source.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.7))
        }
    }
}

/// A single theme choice: swatch trio, name, character line, and check.
private struct OnboardingThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Swatch trio: background, card, and gold. The stack fans
                // open and the gold lights when this theme is chosen. It
                // fans inside a fixed width, so the names beside every row
                // stand on one line whichever row is chosen.
                HStack(spacing: isSelected ? 3 : -8) {
                    swatch(theme.palette.background)
                    swatch(theme.palette.card)
                    swatch(theme.palette.gold)
                        .shadow(color: theme.palette.gold.opacity(isSelected ? 0.7 : 0), radius: 6)
                }
                .frame(width: 78, alignment: .leading)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(AppFonts.titleFont(14))
                        .foregroundColor(AppColors.cream)

                    Text(theme.detail)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                OnboardingRadio(isOn: isSelected)
            }
            // The same card as every other choice in the introduction
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppColors.gold.opacity(0.07) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppColors.gold.opacity(isSelected ? 0.7 : 0.18), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(SacredCardButtonStyle())
        .animation(Motion.ease(0.25), value: isSelected)
        .accessibilityLabel("\(theme.displayName) colors")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func swatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay(Circle().strokeBorder(AppColors.cream.opacity(0.25), lineWidth: AppLine.hairline))
    }
}

/// The opening of the Hail Mary in the chosen format, laid out as the
/// prayer screens lay it, so each choice shows what it means before it
/// is made.
private struct LanguagePreviewCard: View {
    let language: PrayerLanguage

    private static let latin = "Ave Maria, gratia plena, Dominus tecum."
    private static let english = "Hail Mary, full of grace, the Lord is with thee."

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                AppIcon("ph-hands-praying", size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Text("The Hail Mary")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.cream.opacity(0.62))

                Spacer()
            }

            ZStack(alignment: .topLeading) {
                lines
                    .id(language)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.quoteBackground.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.2), lineWidth: AppLine.hairline)
        )
        .animation(Motion.crossfade, value: language)
    }

    @ViewBuilder
    private var lines: some View {
        switch language {
        case .english:
            primary(Self.english)
        case .latin:
            primary(Self.latin)
        case .both:
            pair(primary: Self.latin, secondary: Self.english)
        case .latinUnderEnglish:
            pair(primary: Self.english, secondary: Self.latin)
        }
    }

    private func primary(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.bodyFont(16))
            .foregroundColor(AppColors.cream)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func pair(primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            self.primary(primary)

            Text(secondary)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.62))
                .padding(.leading, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: { _ in })
}
