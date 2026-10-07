//
//  MyChapelView.swift
//  Lumen Viae
//
//  My Chapel — the tab the old Me page held, rebuilt as a page the user
//  arranges themselves. A chapel is a room arranged by the one who
//  prays in it.
//
//  Two ideas drive it:
//
//  1. A single focus at the top: the first unoffered act on the rule of
//     prayer, set large, with one gold act. It advances on its own as
//     acts are offered.
//
//  2. Everything below is arrangeable in place. Press and hold (or tap
//     "Arrange this page"), then drag sections by their handles, tap them to
//     switch between full and half width, put them away into a tray,
//     and drag them back out. No separate customize sheet.
//
//  Nothing is ever deleted — the ✕ moves a section to the tray, and
//  the tray always holds it. What a hidden section shows keeps living
//  underneath: a stowed flame keeps counting.
//

import SwiftUI
import SwiftData

// MARK: - MyChapelView

struct MyChapelView: View {

    @Environment(UserSettings.self) private var settings
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    /// Sessions re-render the rule and the flame as prayers land.
    @Query(sort: \PrayerSession.completedAt, order: .reverse)
    private var sessions: [PrayerSession]

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    @State private var historyService: PrayerHistoryService?
    @State private var today = TodayInChurch()

    /// Today's prayer day, which turns at four in the morning, not at
    /// midnight (`PrayerDay`). Read by the rule's checks, so the focus, the
    /// Today tile and the flame roll over at four while the page is open.
    private var dayClock: PrayerDayClock { PrayerDayClock.shared }

    /// The chant's hold on the shared player outlives this view: a tab
    /// switch tears the page down, and a chant left singing with its
    /// transport deallocated could not be paused from anywhere.
    private let chantPlayer = ChantPlayer.shared

    @State private var showRuleEditor = false

    /// The new-reflection sheet, opened from the day strip's pencil
    @State private var showNewReflection = false

    /// The flame tile's three numbers, recomputed when a prayer lands
    /// rather than on every body pass — `weeklyPrayerStatus()` alone is
    /// seven predicate fetches, and this body runs on every scroll and
    /// drag frame.
    @State private var flameStats = FlameStats()

    struct FlameStats {
        var streak = 0
        var prayedToday = false
        var week: [(date: Date, didPray: Bool)] = []
    }

    // MARK: Arrange state

    /// What the finger holds mid-drag.
    private struct Carry: Equatable {
        let tile: ChapelTile
        let fromTray: Bool
        let span: Int
    }

    @State private var carrying: Carry?

    /// The finger, in the page's own space — the ghost rides here.
    @State private var carryPoint: CGPoint?

    /// The ghost's lean into the direction of travel, ±9°.
    @State private var tilt: Double = 0

    /// Where among the placed tiles the carried one would land.
    @State private var dropIndex: Int?

    /// Each placed tile's frame in the page's space, for drop math.
    @State private var tileFrames: [ChapelTile: CGRect] = [:]

    /// True for as long as a carry gesture is live. Unlike `onEnded`,
    /// gesture state unwinds on cancellation, which is the only signal
    /// the page gets when the ScrollView takes the touch back.
    @GestureState private var dragActive = false

    /// Where the finger was when the landing slot last moved. Opening a
    /// slot displaces the tiles the next reading is measured against, so
    /// without a little hysteresis the slot flickers between two
    /// positions while the finger sits still on a boundary.
    @State private var lastDropBoundaryY: CGFloat?

    /// The tray's height while arranging, so the page's foot can always
    /// scroll clear of it however many sections it holds
    @State private var trayHeight: CGFloat = 0

    private var arranging: Bool { router.chapelArranging }

    private static let space = "chapel"

    /// The page's head, which arranging scrolls back to
    private static let top = "chapel-top"

    // MARK: Body

    var body: some View {
        // Resolved once per pass. Each `ChapelAct` costs a SwiftData
        // fetch, Easter/season math, and a date format; read as a
        // computed property it was evaluated about eleven times per body
        // — twice in the focus block and twice in each of the four
        // strings it draws.
        let acts = resolvedActs
        let next = acts.first { !$0.done }

        return pageStack(acts: acts, next: next)
        .onAppear {
            if historyService == nil {
                historyService = PrayerHistoryService(modelContext: modelContext)
            }
            refreshFlameStats()
        }
        .onChange(of: sessions.count) { _, _ in refreshFlameStats() }
        .onChange(of: dayClock.today) { _, _ in refreshFlameStats() }
        .onDisappear {
            // Leaving the tab mid-arrange must give the tab bar back.
            // The router enforces this too — any navigation ends it —
            // but a plain tab switch that never touches the path lands
            // here first.
            if arranging { endArrange() }
        }
        // A drag that the enclosing ScrollView claims is cancelled, and
        // a cancelled gesture never calls `onEnded`. Without this the
        // page stays mid-carry: a dashed slot where a tile belongs and a
        // ghost frozen under a finger that is no longer down.
        .onChange(of: dragActive) { _, active in
            if !active { cancelCarry() }
        }
        .task { await today.load() }
        // The feast is the calendar day's: a page left open overnight
        // and brought back the next morning takes up the new day, so the
        // Liturgy's leaf and the feast beside it never disagree
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // The hour as well, as every page that shows it must: its
            // sleeping task may wake late after a suspension, and the
            // Liturgy's Office row would name the hour the page was left on
            CanonicalClock.shared.refresh()
            Task { await today.load() }
        }
        // And at the turn of the hour while it is open, which takes in
        // midnight (Matins); the load returns at once on the same day
        .onChange(of: CanonicalClock.shared.hour) { _, _ in
            Task { await today.load() }
        }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorSheet()
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
        // As the Journal opens a new entry
        .sheet(isPresented: $showNewReflection) {
            JournalEntryEditorView(isMidPrayer: false)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
                .dynamicTypeSize(...DynamicTypeSize.appMaximum)
        }
    }

    // MARK: - The page, in parts

    // The page is built from these parts, each a function of its own, so
    // the compiler checks one part at a time: written as one expression
    // in the body, it outgrew the type-checker's time and the build
    // stopped there.

    /// The ground, the scrolling page, and what is held above it while
    /// the page is arranged.
    private func pageStack(acts: [ChapelAct], next: ChapelAct?) -> some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            halo

            scrollingPage(acts: acts, next: next)

            if arranging {
                arrangeHeadOverlay
                trayOverlay
            }

            ghostOverlay
        }
        .coordinateSpace(name: Self.space)
        .sensoryFeedback(.impact(weight: .medium), trigger: arranging)
        // A light tick as a row lifts, by its grip or a chip
        .sensoryFeedback(.impact(weight: .light), trigger: carrying) { old, new in
            Self.lifts(old, new)
        }
    }

    /// Whether a carry has just begun, for the tick as a row lifts
    private static func lifts(_ old: Carry?, _ new: Carry?) -> Bool {
        old == nil && new != nil
    }

    private func scrollingPage(acts: [ChapelAct], next: ChapelAct?) -> some View {
        ScrollViewReader { scroller in
            ScrollView(showsIndicators: false) {
                pageColumn(acts: acts, next: next)
            }
            // The scroll stands still while a row is carried by its
            // grip, until it is set down
            .scrollDisabled(carrying != nil)
            // Arranged, the page folds to a list that fits the glass;
            // a hold far down the page would otherwise leave the list
            // scrolled out of sight above
            .onChange(of: arranging) { _, now in
                guard now else { return }
                withAnimation(reduceMotion ? nil : Motion.chrome) {
                    scroller.scrollTo(Self.top, anchor: .top)
                }
            }
        }
        // The dissolve is so a scrolled ledger row stops colliding
        // with the clock and the battery on its way off the page —
        // but it takes whatever sits in it, and with no inset the
        // day strip came to rest *inside* the band and read at
        // about seven-tenths opacity before anyone had scrolled. A
        // tab root has no Back capsule to clear, which is why this
        // once passed 0; the band is there either way, so the strip
        // is held clear of it like the first line on every other
        // page. Shallower than a pushed page's 48, because there is
        // no capsule to cover: 32 is enough to dissolve a row under
        // the clock, and every point beyond it is dead room above
        // the day.
        // While arranging, the head is held above the scroll at the
        // glass's top, so the scroll's room for it starts there too:
        // inset by the band as well, the rows began fifty points
        // below the line telling how to move them
        .topChromeFade(height: 32, inset: arranging ? 0 : 32)
    }

    private func pageColumn(acts: [ChapelAct], next: ChapelAct?) -> some View {
        VStack(spacing: 30) {
            headSlot(acts: acts, next: next)

            grid(acts: acts)
                .padding(.horizontal, 20)
                .padding(.top, arranging ? -12 : 0)

            if !arranging {
                footControl
                    .transition(footTransition)
            }
        }
        .padding(.bottom, arranging ? max(190, trayHeight + 20) : 190)
        // Press and hold the page itself. Behind the
        // content, not over it: as a `simultaneousGesture`
        // on the ScrollView this recognized *alongside*
        // every control, so holding the Rosary's gold act for
        // half a second both entered arrange mode and
        // started a Rosary. A control now wins its own
        // touch, and only the page between them arranges.
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 8) {
                    enterArrange()
                }
        }
    }

    /// The page's head and the arranging head share one slot: while the
    /// page is arranged it is being rearranged, not read, and the day,
    /// the focus and its gold act stand down for the list of sections.
    /// The arranging head itself is held above the scroll, so DONE
    /// cannot scroll away while the tab bar is gone; here it only keeps
    /// its room. The leaving head goes at once and the arriving one fades
    /// in, so the slot never lays out both together
    private func headSlot(acts: [ChapelAct], next: ChapelAct?) -> some View {
        ZStack(alignment: .top) {
            if arranging {
                arrangeHeader
                    .hidden()
                    .transition(modeTransition)
            } else {
                pageHead(acts: acts, next: next)
                    .transition(modeTransition)
            }
        }
        .animation(modeChange, value: arranging)
        .id(Self.top)
    }

    private var footTransition: AnyTransition {
        reduceMotion
            ? Self.stillModeSwap
            : AnyTransition.opacity.combined(with: .scale(scale: 0.96))
    }

    private func refreshFlameStats() {
        guard let historyService else { return }
        flameStats = FlameStats(
            streak: historyService.currentStreak(),
            prayedToday: historyService.hasPrayedToday(),
            week: historyService.weeklyPrayerStatus()
        )
    }

    // MARK: - The page's head

    /// Everything above the sections as the page is read: the day, the
    /// focus and the ornament under it, and the one-time coach.
    private func pageHead(acts: [ChapelAct], next: ChapelAct?) -> some View {
        VStack(spacing: 30) {
            dayStrip

            focusBlock(acts: acts, next: next)

            OrnamentDivider()
                .padding(.horizontal, 28)
                .padding(.top, -4)

            if !settings.chapelCoached {
                coachRibbon
            }
        }
    }

    /// How a mode's drawing gives way to the other's: the arriving one
    /// fades in, the leaving one goes at once, so the two are never laid
    /// out together — a full tile and its folded row overlapping in one
    /// slot held the tile's height until the fade had ended, and the
    /// page then jumped.
    private static let modeSwap = AnyTransition.asymmetric(insertion: .opacity, removal: .identity)

    /// The same swap under Reduce Motion, where the change of mode
    /// carries no animation (`modeChange`): the fade brings its own, so
    /// what arrives still fades in where it stands
    private static let stillModeSwap = AnyTransition.asymmetric(
        insertion: .opacity.animation(.easeOut(duration: 0.25)),
        removal: .identity
    )

    private var modeTransition: AnyTransition {
        reduceMotion ? Self.stillModeSwap : Self.modeSwap
    }

    /// The change of mode's own beat. Under Reduce Motion there is none:
    /// the tiles do not fold, nor the rows slide to their places — the
    /// page is redrawn where it stands, and only fades
    private var modeChange: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.25)
    }

    /// The arranging head held at the top of the glass, over the page's
    /// own ground, so the rows scroll away under it rather than through
    /// it — DONE is the only way out of arranging, and the tab bar has
    /// given way to the tray
    private var arrangeHeadOverlay: some View {
        VStack(spacing: 0) {
            arrangeHeader
                .padding(.bottom, 14)
                // Opaque behind every word of the head, and fading only in
                // the band beneath them. As one gradient its fade began
                // above the last line, and a row's border scrolled through
                // "or half."
                .background(alignment: .bottom) {
                    VStack(spacing: 0) {
                        AppColors.backgroundDeep

                        LinearGradient(
                            colors: [AppColors.backgroundDeep, AppColors.backgroundDeep.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 12)
                    }
                    .ignoresSafeArea(edges: .top)
                }

            Spacer(minLength: 0)
        }
        .transition(reduceMotion ? AnyTransition.opacity.animation(.easeOut(duration: 0.25)) : .opacity)
        .zIndex(20)
        // Drawn after the scroll, it would be read after every row
        .accessibilitySortPriority(1)
    }

    /// The head while the page is arranged: what the page is doing, how
    /// to do it, and DONE — the page's one gold act while the focus block
    /// stands down.
    private var arrangeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Text("Rearrange")
                    .font(AppFonts.titleFont(22))
                    .foregroundColor(AppColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)

                GoldCTAButton(
                    title: "Done",
                    prominence: .inline,
                    silhouette: .rounded(14),
                    trailingIcon: "ph-check",
                    fullWidth: false,
                    action: endArrange
                )
                .accessibilityLabel("Done arranging")
            }

            Text("Drag a section by its handle to move it. Tap one to make it full or half.")
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.accentSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    // MARK: - Ambient halo

    /// The radial warmth behind the focus block. Hung off a clear anchor
    /// as an overlay: the 480pt circle is wider than the page, and put
    /// in the layout directly it stretched the whole ZStack to its width.
    private var halo: some View {
        Color.clear
            .overlay(alignment: .top) {
                RadialGradient(
                    stops: [
                        .init(color: AppColors.gold.opacity(0.10), location: 0),
                        .init(color: AppColors.gold.opacity(0.03), location: 0.42),
                        .init(color: .clear, location: 0.68)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 240
                )
                .frame(width: 480, height: 480)
                .offset(y: -170)
            }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Day strip

    /// The liturgical day, marked with the day's colour. Fixed — never
    /// arrangeable — and carrying no chrome of its own.
    private var dayStrip: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Rectangle()
                    .fill(today.vestment?.swatch ?? AppColors.gold.opacity(0.45))
                    .frame(width: 7, height: 7)
                    .rotationEffect(.degrees(45))
                    // Sat on the first line's baseline, so a wrapped
                    // feast keeps the diamond beside its opening word
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                    .accessibilityHidden(true)

                // Tracked Cinzel resists compression, and a long feast
                // ("Beheading of St. John the Baptist") widened the whole
                // page — the frame holds the line to the room it has.
                // Held to two lines rather than one: the strip's whole
                // job is to read the day, and "Nativity of the Blessed
                // Virgin Ma…" does not read it. A feast that overruns
                // wraps at a word instead.
                Text(dayLine.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .lineSpacing(4)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)
                    .animation(Motion.crossfade, value: dayLine)
            }

            Spacer(minLength: 0)

            // The faders and the colophon used to ride here. They are
            // app-level chrome and now live in the home masthead, where
            // a first-time user actually looks for them; this strip is
            // left to read the liturgical day, which is its whole job.
            // The foot named both in words for a while as well, and that
            // duplicate is gone too — the masthead is the one door.
            //
            // The one exception is the journal's pencil. With the
            // Journal off the tab bar, a new reflection needs a door
            // that is always on the page — the Reflections tile can be
            // put away — and the Chapel is where reflections are kept
            Button { showNewReflection = true } label: {
                AppIcon("ph-pencil-simple", size: 17)
                    .foregroundColor(AppColors.gold)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                    )
                    // Drawn at 40, answering to 44
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(QuietGlyphButtonStyle())
            .accessibilityLabel("New reflection")
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(dayLine)
    }

    /// "Thursday · St. Monica" — the weekday alone until the feast is known.
    private var dayLine: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.wide))
        guard let feast = today.feastTitle else { return weekday }
        return "\(weekday) · \(feast)"
    }

    // MARK: - The rule, resolved for today

    /// The preparation under way. One chosen ahead waits off the rule
    /// until its Day 1, by the calendar as its days are numbered: there
    /// is nothing of it to pray before then.
    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted && $0.hasBegun() }
    }

    /// The user's rule as today sees it. Every act on it is one the app
    /// watches finish — the Rosary, the Scriptural Rosary, the chaplet,
    /// the consecration day — and checks itself.
    ///
    /// The Consecration is not chosen for the rule but joins it of its
    /// own accord while a preparation is under way — second, under the
    /// Rosary, where the design places it — and leaves when the
    /// preparation is done. The Mass, the Office and a meditation chosen
    /// by hand are off the rule (`PrayerShortcut.isRuleEligible`), and
    /// the row marked by hand went with them.
    private var resolvedActs: [ChapelAct] {
        var acts = settings.ruleItems.map { item in
            ChapelAct(
                shortcut: item,
                subtitle: subtitle(for: item),
                done: isDone(item),
                resume: PrayerResumeService.shared.continuation(for: item)
            )
        }
        if activeConsecration != nil {
            acts.insert(
                ChapelAct(
                    shortcut: .consecration,
                    subtitle: subtitle(for: .consecration),
                    done: isDone(.consecration),
                    day: activeConsecration?.currentDayNumber
                ),
                at: min(1, acts.count)
            )
        }
        return acts
    }

    private func isDone(_ item: PrayerShortcut) -> Bool {
        // Read first, whatever the act, so every row answers to the
        // day's turn at four — the Prayer Book's orders as well, which
        // ask the store about the moment itself
        let day = dayClock.today
        switch item {
        case .todaysRosary:
            // Any set of mysteries counts; the chaplet has its own row.
            return historyService?.sessions(onPrayerDay: day)
                .contains { $0.category != .sevenSorrows } ?? false

        case .sevenSorrows:
            return historyService?.sessions(onPrayerDay: day)
                .contains { $0.category == .sevenSorrows } ?? false

        case .scripturalRosary:
            // Its own row, by name: a Rosary prayed with a meditation
            // does not offer this one, though this one counts as the
            // day's Rosary above
            return historyService?.sessions(onPrayerDay: day)
                .contains { $0.meditationType == ScripturalRosaryViewModel.devotionName } ?? false

        case .rosaryAloud:
            // The same, by its own name
            return historyService?.sessions(onPrayerDay: day)
                .contains { $0.meditationType == ScripturalRosaryViewModel.aloudDevotionName } ?? false

        case .consecration:
            guard let progress = activeConsecration else { return false }
            return progress.isDayCompleted(progress.currentDayNumber)

        // Offered when prayed through to its Amen on the pray-along
        // screen; the Angelus counts once, at whichever bell
        case .morningPrayers, .angelus, .nightPrayers:
            return item.prayerOrderID.map { PrayerBookStore.shared.wasOffered($0) } ?? false

        case .mass, .office, .chooseMeditation:
            // Never on the rule (`isRuleEligible`)
            return false
        }
    }

    /// The row's second line: the live fact about the act, short enough
    /// to sit under its name on one line of the ledger.
    private func subtitle(for item: PrayerShortcut) -> String {
        switch item {
        case .todaysRosary:
            return ScheduleService.categoryForToday().devotionTitle
        // In the words the Pray tray uses for the same acts
        case .scripturalRosary, .rosaryAloud:
            return item.trayDetail(today: ScheduleService.categoryForToday(), praysAloud: true)
        case .consecration:
            guard let progress = activeConsecration else { return "Not yet begun" }
            let day = progress.currentDayNumber
            guard day <= 33 else { return "Consecration Day" }
            return "Day \(day) of 33 · \(ChapelConsecrationTile.phaseName(day: day))"
        case .sevenSorrows:
            return "Seven Hail Marys for each sorrow"
        // The three orders in the Prayers page's own words for when each
        // is said ("On waking", "At bedtime") and for the season's song
        // to Mary, read from the book rather than written again here
        case .morningPrayers:
            guard let order = Self.bookOrder(of: item) else { return item.subtitle }
            return "\(order.occasion) · \(order.prayers().count) prayers"
        case .angelus:
            return Self.bookOrder(of: item)?.occasion ?? item.subtitle
        case .nightPrayers:
            guard let order = Self.bookOrder(of: item) else { return item.subtitle }
            return "\(order.occasion) · \(PrayerBook.antiphon(on: Date()).name)"
        case .chooseMeditation, .mass, .office:
            // Never on the rule (`isRuleEligible`)
            return item.subtitle
        }
    }

    /// The Prayers page's order of prayer an act prays, if it prays one
    private static func bookOrder(of item: PrayerShortcut) -> PrayerOrder? {
        guard let id = item.prayerOrderID else { return nil }
        return PrayerBook.order(id)
    }

    private func handleAct(_ act: ChapelAct) {
        router.run(act.shortcut)
    }

    // MARK: - Focus block

    /// Everything the focus block says, derived from the first unoffered
    /// act — never stored.
    private func focusBlock(acts: [ChapelAct], next: ChapelAct?) -> some View {
        let ruleEmpty = acts.isEmpty

        let title = focusTitle(acts: acts, next: next)

        return VStack(spacing: 13) {
            Text(focusKicker(acts: acts, next: next).uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(
                    next == nil && !ruleEmpty
                        ? AppColors.gold
                        : AppColors.gold.opacity(0.7)
                )
                .contentTransition(.opacity)

            Text(title)
                .font(AppFonts.headlineFont(38))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)

            Text(focusDetail(acts: acts, next: next))
                .font(AppFonts.readingItalicFont(15.5))
                .foregroundColor(AppColors.cream.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .frame(maxWidth: 272)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)

            GoldCTAButton(title: focusAction(acts: acts, next: next), glyph: .chevron, fullWidth: false) {
                performFocusAction(acts: acts, next: next)
            }
            .padding(.top, 8)
        }
        // An act offered, the next one takes the block: the page's one
        // real change of state is a crossfade, never a hard swap
        .animation(Motion.crossfade, value: title)
        .padding(.horizontal, 28)
        .padding(.top, -18)
        // While arranging, the page is being rearranged, not read. The
        // tiles and the day strip already stand down; the focus block's
        // gold act is the largest target on the page and would otherwise
        // navigate away mid-arrange.
        .allowsHitTesting(!arranging)
    }

    private func focusKicker(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty { return "Daily prayers" }
        return next != nil ? "Next" : "All prayed today"
    }

    private func focusTitle(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty { return "Choose your daily prayers" }
        // True at any hour: the rule can be offered by half past six in
        // the morning, where "Rest now" sent someone back to bed. The
        // space before "God" does not break, so a title that needs two
        // lines reads "Thanks be / to God", never leaving "God" alone
        return next?.focusTitle ?? "Thanks be to\u{00A0}God"
    }

    private func focusDetail(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty {
            return "Pick the prayers you mean to pray each day, and this page will keep track of them."
        }
        guard let next else {
            return "You have prayed all your daily prayers today. They begin again tomorrow."
        }
        // Taken up where it stopped, as the guide's own welcome says it
        if let session = next.resume {
            return "You stopped at the \(session.placeLabel)."
        }
        switch next.shortcut {
        case .todaysRosary:
            return "The \(ScheduleService.categoryForToday().devotionTitle), with meditations drawn from the saints."
        case .sevenSorrows:
            return "Seven Hail Marys for each of Mary's seven sorrows, prayed on beads of their own."
        case .scripturalRosary:
            return "The \(ScheduleService.categoryForToday().devotionTitle), with a Bible verse for every Hail Mary."
        case .rosaryAloud:
            return "The \(ScheduleService.categoryForToday().devotionTitle), every prayer said aloud and the beads moving with the voice."
        case .mass:
            return "Today\u{2019}s prayers and readings, in the traditional Latin Mass (1962 Missal)."
        case .office:
            return "The Church\u{2019}s prayer for each hour of the day, the Divine Office."
        case .consecration:
            let day = activeConsecration.map { min($0.currentDayNumber, 33) }
            return day.map { "Day \($0) of 33, preparing to give yourself to Jesus through Mary." }
                ?? "A 33-day preparation to give yourself to Jesus through Mary."
        case .chooseMeditation:
            return "Browse today's meditations and choose one to pray."
        case .morningPrayers:
            return "Give the day to God before it begins: the Morning Offering and the acts of faith, hope and love."
        case .angelus:
            return PrayerBook.isEastertide(Date())
                ? "Queen of Heaven (Regina Cæli), the Easter season's prayer to Mary, said in place of the Angelus."
                : "A short prayer to Mary at 6 AM, noon and 6 PM, recalling the angel's message to her."
        case .nightPrayers:
            return "Look back over the day, ask forgiveness, and end with a song to Mary."
        }
    }

    private func focusAction(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty { return "Choose Prayers" }
        return next?.focusAction ?? "Pray the Rosary"
    }

    private func performFocusAction(acts: [ChapelAct], next: ChapelAct?) {
        if acts.isEmpty {
            showRuleEditor = true
        } else if let next {
            router.run(next.shortcut)
        } else {
            router.run(.todaysRosary)
        }
    }

    // MARK: - Coach ribbon

    /// One-time: the arranging gesture is invisible on its own, so the
    /// page says so once, until the user has arranged by any route.
    private var coachRibbon: some View {
        HStack(spacing: 13) {
            arrangeGlyph(size: 7, gap: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("This page is yours to arrange")
                    .font(AppFonts.bodyFont(14))
                    .foregroundColor(AppColors.cream)

                Text("Move, resize or hide sections")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button(action: enterArrange) {
                Text("SHOW ME")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
                    .padding(.leading, 6)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show me how to arrange the page")
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.gold.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
        )
        .padding(.horizontal, 20)
        .padding(.top, -6)
    }

    /// The 2×2 mark that stands for the arrangeable grid.
    private func arrangeGlyph(size: CGFloat, gap: CGFloat) -> some View {
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                bar(size, bright: true)
                bar(size, bright: false)
            }
            HStack(spacing: gap) {
                bar(size, bright: false)
                bar(size, bright: true)
            }
        }
        .accessibilityHidden(true)
    }

    private func bar(_ size: CGFloat, bright: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(AppColors.gold.opacity(bright ? 0.85 : 0.4))
            .frame(width: size, height: size)
    }

    // MARK: - The grid

    /// What the grid shows: the placed tiles, with the carried one — or
    /// a tray tile mid-drag — standing as the dashed slot at dropIndex.
    private var gridEntries: [ChapelPlacement] {
        var placed = settings.chapelLayout.filter(\.on)

        guard let carrying else { return placed }

        placed.removeAll { $0.tile == carrying.tile }
        let at = min(max(dropIndex ?? placed.count, 0), placed.count)
        placed.insert(
            ChapelPlacement(tile: carrying.tile, span: carrying.span, on: true),
            at: at
        )
        return placed
    }

    private func grid(acts: [ChapelAct]) -> some View {
        let entries = gridEntries
        // Each tile is a card of its own, so the gap need only part two
        // objects: 20 between full rows, 18 beside a row of halves, 12
        // between a pair of halves. Folded to rows while arranging, the
        // page closes to 10 every way.
        return ChapelGridLayout(
            columnGap: arranging ? 10 : 12,
            rowGap: arranging ? 10 : 20,
            halfRowGap: arranging ? 10 : 18
        ) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, placement in
                cell(placement, index: index, count: entries.count, acts: acts)
                    .chapelSpan(placement.span)
                    .id("tile-\(placement.tile.rawValue)")
            }
        }
        .animation(.easeOut(duration: 0.26), value: entries)
    }

    @ViewBuilder
    private func cell(_ placement: ChapelPlacement, index: Int, count: Int, acts: [ChapelAct]) -> some View {
        let isCarried = carrying?.tile == placement.tile

        ZStack {
            if isCarried {
                ChapelSlotView(span: placement.span)
            } else if arranging {
                // Folded to a row while the page is arranged: the whole
                // page fits the glass, and a section is carried past the
                // others rather than dragged down a page three thousand
                // points long
                ChapelArrangeRow(placement: placement)
                    .transition(modeTransition)
            } else {
                tileContent(placement, acts: acts)
                    .transition(modeTransition)
            }
        }
        .animation(modeChange, value: arranging)
        // A swipe on a row is the scroll's, and a tap turns it full or
        // half. The row is carried by its grip alone, laid over it below.
        // The whole row once carried at the first touch, and a swipe
        // meant to scroll the list moved a section to the top of the
        // page; then a hold anywhere on it carried it, laid beside the
        // scroll, and the scroll's pan never began from a row at all.
        .overlay { rowTouch(placement) }
        // The grip carries at once, through a hit area of its own above
        // the row's, the full height of the row and 44 wide. It stands
        // while the row is carried, since taking it away mid-drag would
        // cancel the drag.
        .overlay(alignment: .leading) { gripTouch(placement) }
        .overlay(alignment: .trailing) {
            if arranging && !isCarried {
                ChapelHideButton(tile: placement.tile, span: placement.span) {
                    putAway(placement.tile)
                }
            }
        }
        // Measured only while arranging. The page's coordinate space is
        // anchored on the ZStack outside the ScrollView, so a tile's
        // frame in it changes on every scroll tick — left ungated this
        // wrote seven `@State` values per frame during ordinary reading,
        // invalidating a body that fetches. `dropIndexAt` is the only
        // reader, and it only runs mid-carry.
        .overlay {
            if arranging {
                Color.clear
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .named(Self.space))
                    } action: { frame in
                        tileFrames[placement.tile] = frame
                    }
            }
        }
        .accessibilityElement(children: arranging ? .ignore : .contain)
        .accessibilityLabel(
            arranging
                ? "\(placement.tile.title), \(placement.span == 2 ? "full width" : "half width")"
                : placement.tile.title
        )
        .accessibilityHint(arranging ? "Arranging the page." : "")
        // VoiceOver cannot drag: every move the hand makes on a row, the
        // rotor makes as an action
        .accessibilityActions {
            if arranging {
                Button(placement.span == 2 ? "Make half width" : "Make full width") {
                    toggleSpan(placement.tile)
                }
                if index > 0 {
                    Button("Move up") { move(placement.tile, by: -1) }
                }
                if index < count - 1 {
                    Button("Move down") { move(placement.tile, by: 1) }
                }
                Button("Hide") { putAway(placement.tile) }
            }
        }
    }

    @ViewBuilder
    private func tileContent(_ placement: ChapelPlacement, acts: [ChapelAct]) -> some View {
        switch placement.tile {
        case .rule:
            ChapelRuleTile(
                acts: acts,
                span: placement.span,
                onAct: handleAct,
                onEditRule: { showRuleEditor = true }
            )
        case .consecration:
            ChapelConsecrationTile(span: placement.span)
        case .reading:
            ChapelReadingTile(span: placement.span)
        case .liturgy:
            ChapelLiturgyTile(
                span: placement.span,
                today: today
            )
        case .library:
            ChapelLibraryTile(span: placement.span)
        case .chant:
            ChapelChantTile(
                span: placement.span,
                player: chantPlayer,
                onOpenChant: { router.push(.chant(id: chantPlayer.current.id)) },
                onOpenLibrary: { router.push(.chantLibrary) }
            )
        case .reflections:
            ChapelReflectionsTile(span: placement.span)
        case .prayers:
            ChapelPrayerBookTile(span: placement.span)
        case .flame:
            ChapelFlameTile(
                span: placement.span,
                streak: flameStats.streak,
                hasPrayedToday: flameStats.prayedToday,
                weekStatus: flameStats.week,
                onOpen: { router.switchTo(.progress) }
            )
        }
    }

    // MARK: - Foot control

    /// The standing, visible door into arrange mode — the long press is
    /// a shortcut, never the only way.
    private var footControl: some View {
        VStack(spacing: 8) {
            // An outlined capsule, so the one door into arranging reads
            // as a control and not as a line of the colophon
            Button(action: enterArrange) {
                HStack(spacing: 9) {
                    arrangeGlyph(size: 5.5, gap: 2.5)

                    Text("ARRANGE THIS PAGE")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold)
                }
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .overlay(
                    Capsule()
                        .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                )
                .contentShape(Capsule())
            }
            // The card's settle: a bare glyph's dip to 0.9 reads as a
            // jolt across a control this wide
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityLabel("Arrange this page")

            Text("Or press and hold anywhere.")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)

            // The page's imprint — the version at the foot of the
            // user's own page, where a flyleaf carries its printing.
            VStack(spacing: 3) {
                Text("LUMEN VIAE V\(Bundle.main.appVersion)")
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))

                Text("For the greater glory of God")
                    .font(AppFonts.italicFont(11))
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.top, 22)
        }
        .padding(.horizontal, 40)
        .padding(.top, 4)
    }

    // MARK: - Arrange mode

    private func enterArrange() {
        router.beginChapelArranging(reduceMotion: reduceMotion)
    }

    private func endArrange() {
        withAnimation(modeChange) {
            router.chapelArranging = false
        }
        carrying = nil
        carryPoint = nil
        dropIndex = nil
        tilt = 0
        // Marked on the way out, not the way in. The long press fires
        // alongside any control held for half a second, so entering can
        // happen by accident — and spending the one-time coach on a
        // press the user never meant as one leaves them without the
        // explanation.
        settings.chapelCoached = true
    }

    /// Moves a section to the tray. Never a deletion — the tray always
    /// holds it, and what it shows keeps counting underneath.
    private func putAway(_ tile: ChapelTile) {
        // A counter can keep counting out of sight; a sound cannot. The
        // chant tile is the page's transport for its own audio, so putting
        // it away hands the player back rather than leave a chant singing
        // with nothing on the page able to stop it.
        if tile == .chant { chantPlayer.relinquish() }

        withAnimation(.easeOut(duration: 0.26)) {
            settings.setChapelLayout(
                settings.chapelLayout.map { placement in
                    var placement = placement
                    if placement.tile == tile { placement.on = false }
                    return placement
                }
            )
        }
    }

    /// Puts a tray section back at the end of the page.
    private func addToEnd(_ tile: ChapelTile) {
        var layout = settings.chapelLayout
        guard var moved = layout.first(where: { $0.tile == tile }) else { return }
        moved.on = true
        layout.removeAll { $0.tile == tile }
        withAnimation(.easeOut(duration: 0.26)) {
            settings.setChapelLayout(layout + [moved])
        }
    }

    /// A tap on a placed tile while arranging: switch it between its
    /// full and half drawing.
    private func toggleSpan(_ tile: ChapelTile) {
        withAnimation(.easeOut(duration: 0.26)) {
            settings.setChapelLayout(
                settings.chapelLayout.map { placement in
                    var placement = placement
                    if placement.tile == tile {
                        placement.span = placement.span == 2 ? 1 : 2
                    }
                    return placement
                }
            )
        }
    }

    /// A step up or down the page, for VoiceOver, which cannot drag: the
    /// section trades places with its neighbour among those on the page.
    private func move(_ tile: ChapelTile, by offset: Int) {
        let layout = settings.chapelLayout
        var placed = layout.filter(\.on)
        let stowed = layout.filter { !$0.on }
        guard let from = placed.firstIndex(where: { $0.tile == tile }) else { return }
        let to = from + offset
        guard placed.indices.contains(to) else { return }

        placed.swapAt(from, to)
        withAnimation(.easeOut(duration: 0.26)) {
            settings.setChapelLayout(placed + stowed)
        }
        AccessibilityNotification.Announcement(
            "\(tile.title), \(to + 1) of \(placed.count)"
        ).post()
    }

    // MARK: - The carry

    /// One carry pipeline for both the page and the tray — the only
    /// difference is where a barely-moved press puts the section back.
    private func carryDrag(_ placement: ChapelPlacement, fromTray: Bool) -> AnyGesture<DragGesture.Value> {
        AnyGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                // `@GestureState` resets itself when a gesture is
                // cancelled, which `onEnded` does not cover. The page
                // watches it to unwind a carry the ScrollView stole.
                .updating($dragActive) { _, state, _ in state = true }
                .onChanged { value in
                    if carrying == nil {
                        beginCarry(
                            placement.tile,
                            fromTray: fromTray,
                            span: placement.span,
                            at: value.location
                        )
                    } else if carrying?.tile == placement.tile {
                        moveCarry(to: value.location)
                    }
                }
                .onEnded { value in
                    // Only the tile actually being carried may end the
                    // carry. A second finger brushing another tile fires
                    // that tile's `onEnded` with a zero translation,
                    // which would read as a tap and resize the tile
                    // still under the first finger.
                    guard carrying?.tile == placement.tile else { return }
                    endCarry(with: value)
                }
        )
    }

    private func tileDrag(_ placement: ChapelPlacement) -> AnyGesture<DragGesture.Value> {
        carryDrag(placement, fromTray: false)
    }

    /// The whole row while arranging: a tap turns it full or half, and
    /// nothing else, so a swipe begun on it scrolls the list
    @ViewBuilder
    private func rowTouch(_ placement: ChapelPlacement) -> some View {
        if arranging {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { tapRow(placement) }
        }
    }

    /// The grip's own hit area, which carries at once
    @ViewBuilder
    private func gripTouch(_ placement: ChapelPlacement) -> some View {
        if arranging {
            Color.clear
                .frame(width: 44)
                .contentShape(Rectangle())
                .gesture(tileDrag(placement))
        }
    }

    private func tapRow(_ placement: ChapelPlacement) {
        guard carrying == nil else { return }
        toggleSpan(placement.tile)
    }

    private func trayDrag(_ placement: ChapelPlacement) -> AnyGesture<DragGesture.Value> {
        carryDrag(placement, fromTray: true)
    }

    /// Unwinds a carry that ended without `onEnded` — the enclosing
    /// ScrollView claimed the touch, a call arrived, the app went away.
    /// The layout is left exactly as it was; only the carry is dropped.
    private func cancelCarry() {
        guard carrying != nil else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            carrying = nil
            dropIndex = nil
        }
        carryPoint = nil
        tilt = 0
        lastDropBoundaryY = nil
    }

    private func beginCarry(_ tile: ChapelTile, fromTray: Bool, span: Int, at point: CGPoint) {
        tilt = 0
        carryPoint = point
        lastDropBoundaryY = point.y
        withAnimation(.easeOut(duration: 0.26)) {
            carrying = Carry(tile: tile, fromTray: fromTray, span: span)
            dropIndex = dropIndexAt(point, excluding: tile)
        }
    }

    private func moveCarry(to point: CGPoint) {
        guard let carrying else { return }

        // Lean into the direction of travel, easing back to level when
        // the finger stops.
        let dx = point.x - (carryPoint?.x ?? point.x)
        tilt = max(-9, min(9, tilt * 0.72 + dx * 0.5))
        carryPoint = point

        let index = dropIndexAt(point, excluding: carrying.tile)
        guard index != dropIndex else { return }

        // The slot that just opened pushed the tile below it out from
        // under the finger, so the very next reading can point back the
        // way it came. Require the finger itself to have travelled
        // before honouring a reversal.
        if let last = lastDropBoundaryY, abs(point.y - last) < 12 { return }

        lastDropBoundaryY = point.y
        withAnimation(.easeOut(duration: 0.26)) {
            dropIndex = index
        }
    }

    private func endCarry(with value: DragGesture.Value) {
        guard let carried = carrying else { return }
        let landing = dropIndex

        withAnimation(.easeOut(duration: 0.26)) {
            carrying = nil
            dropIndex = nil
        }
        carryPoint = nil
        tilt = 0
        lastDropBoundaryY = nil

        // A press that barely moved is a tap: on a placed tile it
        // switches the size; on a tray row it puts the section back.
        let moved = abs(value.translation.width) + abs(value.translation.height)
        if moved < 10 {
            if carried.fromTray {
                addToEnd(carried.tile)
            } else {
                toggleSpan(carried.tile)
            }
            return
        }

        commitDrop(of: carried, at: landing)
    }

    private func commitDrop(of carried: Carry, at index: Int?) {
        var layout = settings.chapelLayout
        layout.removeAll { $0.tile == carried.tile }

        var placed = layout.filter(\.on)
        let stowed = layout.filter { !$0.on }

        let at = min(max(index ?? placed.count, 0), placed.count)
        placed.insert(
            ChapelPlacement(tile: carried.tile, span: carried.span, on: true),
            at: at
        )

        withAnimation(.easeOut(duration: 0.26)) {
            settings.setChapelLayout(placed + stowed)
        }
    }

    /// Where among the placed tiles a point falls: before the first tile
    /// whose midline the finger is above — or, within a shared row,
    /// whose left half it is in — else after them all.
    private func dropIndexAt(_ point: CGPoint, excluding tile: ChapelTile) -> Int {
        let placed = settings.chapelLayout.filter { $0.on && $0.tile != tile }

        for (index, placement) in placed.enumerated() {
            guard let frame = tileFrames[placement.tile] else { continue }
            if point.y < frame.midY { return index }

            // The left-half rule belongs to half-width tiles, which sit
            // two to a row and so can only be told apart across. Applied
            // to a full-width tile it makes the whole left side of every
            // row an "insert before me" zone, and a tile dragged down
            // the left margin can never reach the end of the page.
            if placement.span == 1, point.y < frame.maxY, point.x < frame.midX {
                return index
            }
        }
        return placed.count
    }

    // MARK: - Tray

    private var trayOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            ChapelTray(
                hidden: settings.chapelLayout.filter { !$0.on },
                onAdd: addToEnd,
                chipGesture: trayDrag
            )
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                trayHeight = height
            }
        }
        .zIndex(30)
        // Risen from below, but only faded under Reduce Motion
        .transition(
            reduceMotion
                ? AnyTransition.opacity.animation(.easeOut(duration: 0.25))
                : .move(edge: .bottom).combined(with: .opacity)
        )
    }

    // MARK: - Ghost

    /// The card under the finger while something is carried.
    private var ghostOverlay: some View {
        GeometryReader { proxy in
            if let carrying, let carryPoint {
                // Level with the column, following the finger only up
                // and down. Centred on the finger, a row lifted by its
                // grip hung half off the glass to the left, and the
                // landing slot's words read beside it.
                ChapelGhost(tile: carrying.tile, tilt: tilt)
                    .position(x: proxy.size.width / 2, y: carryPoint.y)
            }
        }
        .allowsHitTesting(false)
        .zIndex(80)
    }
}

// MARK: - TodayInChurch, for the day strip

extension TodayInChurch {
    /// The feast alone — nil until the day is known, so the strip can
    /// hold to the weekday rather than a placeholder.
    var feastTitle: String? { proper?.info.title }
}

// MARK: - Preview

#Preview {
    MyChapelView()
        .environment(UserSettings.shared)
        .environment(AppRouter())
        .modelContainer(
            for: [PrayerSession.self, JournalEntry.self, ConsecrationProgress.self, BookReadingProgress.self],
            inMemory: true
        )
}
