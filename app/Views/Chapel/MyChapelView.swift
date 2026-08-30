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
//     "Arrange this page"), then drag sections around, tap them to
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

    /// Sessions re-render the rule and the flame as prayers land.
    @Query(sort: \PrayerSession.completedAt, order: .reverse)
    private var sessions: [PrayerSession]

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    @State private var historyService: PrayerHistoryService?
    @State private var today = TodayInChurch()

    /// The chant's hold on the shared player outlives this view: a tab
    /// switch tears the page down, and a chant left singing with its
    /// transport deallocated could not be paused from anywhere.
    private let chantPlayer = ChapelChantPlayer.shared

    @State private var showChantSheet = false
    @State private var showRuleEditor = false

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

    private var arranging: Bool { router.chapelArranging }

    private static let space = "chapel"

    // MARK: Body

    var body: some View {
        // Resolved once per pass. Each `ChapelAct` costs a SwiftData
        // fetch, Easter/season math, and a date format; read as a
        // computed property it was evaluated about eleven times per body
        // — twice in the focus block and twice in each of the four
        // strings it draws.
        let acts = resolvedActs
        let next = acts.first { !$0.done }

        return ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            halo

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        dayStrip

                        focusBlock(acts: acts, next: next, scrollProxy: proxy)

                        OrnamentDivider()
                            .padding(.horizontal, 28)
                            .padding(.top, -4)

                        if !arranging && !settings.chapelCoached {
                            coachRibbon
                        }

                        grid(acts: acts)
                            .padding(.horizontal, 20)

                        if !arranging {
                            footControl
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 190)
                    // Press and hold the page itself. Behind the
                    // content, not over it: as a `simultaneousGesture`
                    // on the ScrollView this recognized *alongside*
                    // every control, so holding "Begin the Rosary" for
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
                // A tab root: no Back capsule to clear, so no inset — the
                // day strip keeps its place at the top. The dissolve is
                // only so a scrolled ledger row stops colliding with the
                // clock and the battery on its way off the page.
                .topChromeFade(height: 40, inset: 0)
            }

            if arranging {
                trayOverlay
            }

            ghostOverlay
        }
        .coordinateSpace(name: Self.space)
        .sensoryFeedback(.impact(weight: .medium), trigger: arranging)
        .onAppear {
            if historyService == nil {
                historyService = PrayerHistoryService(modelContext: modelContext)
            }
            refreshFlameStats()
        }
        .onChange(of: sessions.count) { _, _ in refreshFlameStats() }
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
        .sheet(isPresented: $showChantSheet) {
            ChapelChantSheet(player: chantPlayer)
        }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorSheet()
        }
    }

    private func refreshFlameStats() {
        guard let historyService else { return }
        flameStats = FlameStats(
            streak: historyService.currentStreak(),
            prayedToday: historyService.hasPrayedToday(),
            week: historyService.weeklyPrayerStatus()
        )
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

    /// The liturgical day, marked with the day's colour, and the door to
    /// Settings. Fixed — never arrangeable.
    private var dayStrip: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 9) {
                Rectangle()
                    .fill(today.vestment?.swatch ?? AppColors.gold.opacity(0.45))
                    .frame(width: 7, height: 7)
                    .rotationEffect(.degrees(45))
                    .accessibilityHidden(true)

                // Tracked Cinzel resists compression, and a long feast
                // ("Beheading of St. John the Baptist") widened the whole
                // page — the frame holds the line to the room it has.
                Text(dayLine.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            // The faders and the colophon used to ride here. They are
            // app-level chrome and now live in the home masthead, where
            // a first-time user actually looks for them; this strip is
            // left to read the liturgical day, which is its whole job.
            // The page's foot still names both in words.
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

    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    /// The user's rule as today sees it. Acts the app can watch finish
    /// (the Rosary, the chaplet, the consecration day) check themselves;
    /// the Mass and the Office are checked by hand.
    private var resolvedActs: [ChapelAct] {
        settings.ruleItems.map { item in
            ChapelAct(
                shortcut: item,
                subtitle: subtitle(for: item),
                done: isDone(item),
                manual: isManual(item)
            )
        }
    }

    private func isManual(_ item: PrayerShortcut) -> Bool {
        switch item {
        case .mass, .office, .chooseMeditation: return true
        case .todaysRosary, .sevenSorrows, .consecration: return false
        }
    }

    private func isDone(_ item: PrayerShortcut) -> Bool {
        switch item {
        case .todaysRosary:
            // Any set of mysteries counts; the chaplet has its own row.
            return historyService?.sessions(on: Date())
                .contains { $0.category != .sevenSorrows } ?? false

        case .sevenSorrows:
            return historyService?.sessions(on: Date())
                .contains { $0.category == .sevenSorrows } ?? false

        case .consecration:
            guard let progress = activeConsecration else { return false }
            return progress.isDayCompleted(progress.currentDayNumber)

        case .mass, .office, .chooseMeditation:
            return settings.isRuleChecked(item)
        }
    }

    private func subtitle(for item: PrayerShortcut) -> String {
        switch item {
        case .todaysRosary:
            return ScheduleService.categoryForToday().devotionTitle
        case .consecration:
            guard let progress = activeConsecration else { return "Not yet begun" }
            return "Day \(min(progress.currentDayNumber, 33)) of 33"
        default:
            return item.subtitle
        }
    }

    private func handleAct(_ act: ChapelAct) {
        if act.manual {
            settings.setRuleChecked(act.shortcut, !act.done)
        } else {
            router.run(act.shortcut)
        }
    }

    // MARK: - Focus block

    /// Everything the focus block says, derived from the first unoffered
    /// act — never stored.
    private func focusBlock(
        acts: [ChapelAct],
        next: ChapelAct?,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        let ruleEmpty = acts.isEmpty

        return VStack(spacing: 13) {
            Text(focusKicker(acts: acts, next: next).uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(
                    next == nil && !ruleEmpty
                        ? AppColors.gold
                        : AppColors.gold.opacity(0.7)
                )

            Text(focusTitle(acts: acts, next: next))
                .font(AppFonts.headlineFont(38))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(focusDetail(acts: acts, next: next))
                .font(AppFonts.readingItalicFont(15.5))
                .foregroundColor(AppColors.cream.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .frame(maxWidth: 272)
                .fixedSize(horizontal: false, vertical: true)

            GoldCTAButton(title: focusAction(acts: acts, next: next), fullWidth: false) {
                performFocusAction(acts: acts, next: next)
            }
            .padding(.top, 8)

            if !ruleEmpty, ruleTileOnPage {
                Button {
                    withAnimation(.easeOut(duration: 0.45)) {
                        scrollProxy.scrollTo(
                            "tile-\(ChapelTile.rule.rawValue)",
                            anchor: UnitPoint(x: 0.5, y: 0.08)
                        )
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("CHOOSE ANOTHER")
                            .font(AppFonts.labelFont(9.5))
                            .tracking(2)
                        AppIcon("ph-caret-down", size: 9)
                    }
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .padding(.top, 6)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose another. Shows the day's ledger.")
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, -18)
        // While arranging, the page is being rearranged, not read. The
        // tiles and the day strip already stand down; the focus block's
        // gold act is the largest target on the page and would otherwise
        // navigate away mid-arrange.
        .allowsHitTesting(!arranging)
    }

    private var ruleTileOnPage: Bool {
        settings.chapelLayout.contains { $0.tile == .rule && $0.on }
    }

    private func focusKicker(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty { return "Your rule" }
        return next != nil ? "Next" : "The day is offered"
    }

    private func focusTitle(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty { return "A rule of prayer" }
        return next?.focusTitle ?? "Rest now"
    }

    private func focusDetail(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty {
            return "Choose the devotions you mean to offer each day, and the Chapel will keep them here."
        }
        guard let next else {
            return "Everything on your rule has been offered today. The Chapel keeps until morning."
        }
        switch next.shortcut {
        case .todaysRosary:
            return "The \(ScheduleService.categoryForToday().devotionTitle), with meditations drawn from the saints."
        case .sevenSorrows:
            return "The chaplet of Our Lady's seven sorrows, prayed on her own beads."
        case .mass:
            return "The propers of the day, from the 1962 Missal, with the Ordinary in its place."
        case .office:
            return "The canonical hours of the 1962 Breviary, prayed hour by hour."
        case .consecration:
            let day = activeConsecration.map { min($0.currentDayNumber, 33) }
            return day.map { "Day \($0) of the 33-day preparation to Jesus through Mary." }
                ?? "The 33-day preparation to Jesus through Mary."
        case .chooseMeditation:
            return "Browse the day's meditation sets and choose one to pray."
        }
    }

    private func focusAction(acts: [ChapelAct], next: ChapelAct?) -> String {
        if acts.isEmpty { return "Choose your rule" }
        return next?.focusAction ?? "Open the Rosary"
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

                Text("Move sections, resize them, put some away")
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
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
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
        return ChapelGridLayout(columnGap: 16, rowGap: 30) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, placement in
                cell(placement, index: index, acts: acts)
                    .chapelSpan(placement.span)
                    .id("tile-\(placement.tile.rawValue)")
            }
        }
        .animation(.easeOut(duration: 0.26), value: entries)
    }

    @ViewBuilder
    private func cell(_ placement: ChapelPlacement, index: Int, acts: [ChapelAct]) -> some View {
        let isCarried = carrying?.tile == placement.tile

        ZStack {
            if isCarried {
                ChapelSlotView()
            } else {
                tileContent(placement, acts: acts)
                    .allowsHitTesting(!arranging)
            }
        }
        .modifier(ChapelSway(active: arranging && carrying == nil, index: index))
        .overlay {
            if arranging {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(tileDrag(placement))
            }
        }
        .overlay(alignment: .topLeading) {
            if arranging && !isCarried {
                ChapelRemoveBadge(tile: placement.tile) {
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
            arranging ? "\(placement.tile.title). Arranging." : placement.tile.title
        )
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
        case .library:
            ChapelLibraryTile(span: placement.span)
        case .chant:
            ChapelChantTile(
                span: placement.span,
                player: chantPlayer,
                onOpenSheet: { showChantSheet = true }
            )
        case .reflections:
            ChapelReflectionsTile(span: placement.span)
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
        VStack(spacing: 12) {
            OrnamentDivider()
                .frame(width: 120)

            Button(action: enterArrange) {
                HStack(spacing: 9) {
                    arrangeGlyph(size: 6, gap: 2.5)

                    Text("ARRANGE THIS PAGE")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.2)
                }
                .foregroundColor(AppColors.gold.opacity(0.85))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Arrange this page")

            Text("Or press and hold anywhere.")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, -8)

            // Settings and About are reached from the day strip's two
            // glyphs, which name themselves to VoiceOver and to nobody
            // else. These are the same two doors, in words, where a
            // colophon would carry them.
            HStack(spacing: 10) {
                footLink("Settings") { router.navigateToSettings() }

                Text("·")
                    .font(AppFonts.labelFont(10))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))

                footLink("About") { router.push(.about) }
            }
            .padding(.top, 10)

            // The page's imprint — the version at the foot of the
            // user's own page, where a flyleaf carries its printing.
            VStack(spacing: 3) {
                Text("LUMEN VIAE V\(Bundle.main.appVersion)")
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))

                Text("Ad Majorem Dei Gloriam")
                    .font(AppFonts.italicFont(11))
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 40)
        .padding(.top, -6)
    }

    /// One named door in the foot, set in the page's own small-caps.
    private func footLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Arrange mode

    private func enterArrange() {
        guard !arranging else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            router.chapelArranging = true
        }
    }

    private func endArrange() {
        withAnimation(.easeOut(duration: 0.25)) {
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
        // chant tile is the only transport for its own audio, so putting
        // it away has to hand the player back rather than leave a chant
        // singing with nothing in the app able to stop it.
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
                putAway: settings.chapelLayout.filter { !$0.on },
                onDone: endArrange,
                onAdd: addToEnd,
                rowGesture: trayDrag
            )
        }
        .zIndex(30)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Ghost

    /// The card under the finger while something is carried.
    private var ghostOverlay: some View {
        GeometryReader { _ in
            if let carrying, let carryPoint {
                ChapelGhost(tile: carrying.tile, tilt: tilt)
                    .position(carryPoint)
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
