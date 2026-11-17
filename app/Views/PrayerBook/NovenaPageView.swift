//
//  NovenaPageView.swift
//  Lumen Viae
//
//  A novena's own page, the way in (design plan, "The finished design",
//  sections 2, 3, 4, 7 and 9; frames reports/design/novenas/rounds/f-r2-*,
//  f-r3-*, f-r4-page*): the painting, what the novena is, BEGIN TODAY or
//  Begin tomorrow, the intention kept on the phone, a reminder, the nine
//  days, and once under way the day to pray, a day left open, Welcome back
//  after three or more, Begin again and End this novena. A day itself is
//  prayed in the Rosary player (the continuous day).
//

import SwiftUI
import UserNotifications

struct NovenaPageView: View {
    let novenaID: String

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    @State private var now = PrayerDay.now
    @State private var sheet: NovenaSheet?
    @State private var confirming: Confirmation?
    @State private var footHeight: CGFloat = 0
    /// Whether the painting has scrolled up behind the clock and the
    /// Back, so the dark ground under them is needed
    @State private var paintingGone = false

    private var store: NovenaStore { NovenaStore.shared }
    private var novena: PrayerBookDocument.Novena? { NovenaDayContext.novena(novenaID) }
    private var progress: NovenaProgress? { store.progress[novenaID] }

    enum Confirmation: Identifiable {
        case beginAgain, end
        var id: Self { self }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appGradient.ignoresSafeArea()

            if let novena {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        NovenaHero(novena: novena)
                            .onGeometryChange(for: Bool.self) { hero in
                                hero.frame(in: .global).maxY < 200
                            } action: { gone in
                                paintingGone = gone
                            }
                        head(novena)
                            .padding(.horizontal, 22)
                            .padding(.top, -64)
                        VStack(alignment: .leading, spacing: 30) {
                            standingCard(novena)
                            if progress != nil { intentionBlock(novena) }
                            if progress != nil { reminderRow(novena) }
                            daysList(novena)
                            if let progress { endLinks(progress, novena) }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 26)
                        Color.clear.frame(height: max(150, footHeight + 24))
                    }
                }
                .ignoresSafeArea(edges: .top)

                chromeGround

                foot(novena)
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        footHeight = $0
                    }
            } else {
                Text(
                    String(
                        localized: "This novena could not be found.",
                        comment: "Novena page: shown when the novena is missing")
                )
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { GoldBackButton(grounded: true) }
        }
        .onAppear { now = PrayerDay.now }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = PrayerDay.now }
        }
        .sheet(item: $sheet) { which in
            if let novena {
                sheetContent(which, novena: novena)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
            }
        }
    }

    /// The dark ground under the clock and the Back once the painting has
    /// gone, so the page dissolves beneath them (the topic page's)
    private var chromeGround: some View {
        VStack(spacing: 0) {
            // From the top of the glass to just under the Back
            AppColors.backgroundDeep.frame(height: 52)
                .background(AppColors.backgroundDeep.ignoresSafeArea(edges: .top))
            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep, location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.85), location: 0.35),
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 44)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(paintingGone ? 1 : 0)
        .animation(Motion.crossfade, value: paintingGone)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Questions

    /// Begin again's and End this novena's questions, each anchored to the
    /// control that asks it: on iOS 26 a question is drawn as a popover
    /// pointing at the view it hangs from
    private func asks(_ which: Confirmation, _ novena: PrayerBookDocument.Novena) -> some ViewModifier {
        NovenaQuestion(which: which, confirming: $confirming) {
            switch which {
            case .end: store.end(novena.id)
            case .beginAgain: store.beginAgain(novena, now: now)
            }
        }
    }

    // MARK: - Head

    private func head(_ novena: PrayerBookDocument.Novena) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if progress == nil {
                Text(Self.kicker(length: novena.length))
                    .font(AppFonts.labelFont(10))
                    .tracking(2.6)
                    .foregroundColor(AppColors.gold)
            }
            Text(novena.title)
                .font(AppFonts.titleFont(30))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let progress {
                Text(headLine(progress, length: novena.length))
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                NovenaDashes(
                    days: NovenaDays.of(progress, length: novena.length, here: hereDay(progress, novena), on: now)
                )
                .padding(.top, 6)
            } else {
                Text(novena.detail)
                    .font(AppFonts.readingFont(18))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                Text(
                    String(
                        localized: "With the Rosary. Begin any day.",
                        comment:
                            "Novena page, not begun: how it is prayed and when it may begin; never a length of time")
                )
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                if let origin = novena.origin {
                    NovenaCreditLine(
                        origin: origin, url: novena.sourceURL(spanish: SpanishContent.isActive), size: 14,
                        color: AppColors.textSecondary.opacity(0.85))
                }
            }
        }
    }

    /// "Your intention": the sheet's title, and in capitals the page's heading
    static var intentionTitle: String {
        String(
            localized: "novena.intention.title", defaultValue: "Your intention",
            comment: "Novena: the reader's intention, as a sheet title and (in capitals) the page's heading")
    }

    /// An instant inside tomorrow's prayer day: its noon. Tomorrow's
    /// midnight is before the day turns at four, so it named today.
    static func tomorrowsStart(after now: Date) -> Date {
        PrayerDay.adding(days: 1, to: PrayerDay.day(of: now)).addingTimeInterval(12 * 3600)
    }

    static func kicker(length: Int) -> String {
        length == 9
            ? String(
                localized: "NOVENA · NINE DAYS",
                comment: "Novena page and card: the kicker over a nine-day novena's name")
            : String(
                localized: "NOVENA · \(length) DAYS",
                comment: "Novena page and card: the kicker over a novena of another length")
    }

    /// "Began 11 November · Day 4 today", "Begins tomorrow, 16 November"
    private func headLine(_ progress: NovenaProgress, length: Int) -> String {
        let day = progress.dayNumber(on: now)
        let began = (progress.date(ofDay: progress.anchorDay) ?? progress.anchorDate)
            .formatted(.dateTime.day().month(.wide))
        if day < 1 {
            return String(
                localized: "Begins tomorrow, \(began)",
                comment: "Novena page, head: a novena set to begin tomorrow, with its date")
        }
        let picked = progress.anchorDay > 1
        // Welcome back names no day today: the card says where she was
        if case .welcomeBack = progress.standing(on: now) {
            return String(localized: "Began \(began)", comment: "Novena page, head: the date it began, past its last day")
        }
        if (1...length).contains(day) {
            return picked
                ? String(
                    localized: "Picked up on \(began) · Day \(day) today",
                    comment: "Novena page, head: a novena picked up again, the date and today's day")
                : String(
                    localized: "Began \(began) · Day \(day) today",
                    comment: "Novena page, head: the date it began and today's day")
        }
        return String(localized: "Began \(began)", comment: "Novena page, head: the date it began, past its last day")
    }

    private func hereDay(_ progress: NovenaProgress, _ novena: PrayerBookDocument.Novena) -> Int {
        Self.hereDay(progress, length: novena.length, on: now)
    }

    /// Today's dash; none in Welcome back, where a marker on today read as
    /// the day she is on while the card names another, nor before Day 1
    static func hereDay(_ progress: NovenaProgress, length: Int, on now: Date) -> Int {
        if case .welcomeBack = progress.standing(on: now) { return 0 }
        let day = progress.dayNumber(on: now)
        // Set to begin tomorrow: no day is today's yet
        if day < 1 { return 0 }
        return min(day, length)
    }

    // MARK: - Where it stands

    @ViewBuilder
    private func standingCard(_ novena: PrayerBookDocument.Novena) -> some View {
        if let progress {
            switch progress.standing(on: now) {
            case .welcomeBack(let first):
                NovenaCardFrame {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(
                            String(
                                localized: "Welcome back",
                                comment: "Novena page: the card after three or more days left open")
                        )
                        .font(AppFonts.headlineFont(20))
                        .foregroundColor(AppColors.cream)
                        .accessibilityAddTraits(.isHeader)
                        Text(
                            String(
                                localized: "You were on Day \(first) of \(novena.length).",
                                comment: "Novena page, Welcome back: the day she had reached")
                        )
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        QuietGoldButton(
                            title: String(
                                localized: "Begin Again", comment: "Novena page, Welcome back: begin from Day 1"),
                            horizontalPadding: 0
                        ) {
                            confirming = .beginAgain
                        }
                        .modifier(asks(.beginAgain, novena))
                        .padding(.top, 4)
                    }
                }
            case .underWay(let today, let open) where !open.isEmpty:
                NovenaCardFrame {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Self.openSentence(open, next: today))
                            .font(AppFonts.readingFont(17))
                            .foregroundColor(AppColors.cream.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(open, id: \.self) { day in
                            QuietGoldButton(
                                title: String(
                                    localized: "Pray Day \(day)", comment: "Novena page: pray a day left open"),
                                horizontalPadding: 0
                            ) {
                                pray(day, of: novena)
                            }
                        }
                    }
                }
            default:
                EmptyView()
            }
        }
    }

    /// "Day 3 is still open. You can pray it now, or go on with Day 4."
    static func openSentence(_ open: [Int], next: Int?) -> String {
        if open.count == 1 {
            let day = open[0]
            guard let next else {
                return String(
                    localized: "Day \(day) is still open. You can pray it now.",
                    comment: "Novena page: one past day not yet prayed, nothing else today")
            }
            return String(
                localized: "Day \(day) is still open. You can pray it now, or go on with Day \(next).",
                comment: "Novena page: one past day not yet prayed, and today's day")
        }
        let list = open.map(String.init).formatted(.list(type: .and))
        guard let next else {
            return String(
                localized: "Days \(list) are still open. You can pray them now.",
                comment: "Novena page: two past days not yet prayed, nothing else today")
        }
        return String(
            localized: "Days \(list) are still open. You can pray them now, or go on with Day \(next).",
            comment: "Novena page: two past days not yet prayed, and today's day")
    }

    // MARK: - Intention and reminder

    private func intentionBlock(_ novena: PrayerBookDocument.Novena) -> some View {
        Button {
            sheet = .intention(.editing)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                NovenaLabel(
                    NovenaPageView.intentionTitle.uppercased()
                )
                HStack(alignment: .firstTextBaseline) {
                    if let intention = progress?.intention {
                        Text(intention)
                            .font(AppFonts.readingItalicFont(19))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(
                            String(
                                localized: "Add an intention",
                                comment: "Novena page: the intention row when none is kept")
                        )
                        .font(AppFonts.readingItalicFont(18))
                        .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer(minLength: 8)
                    AppIcon("ph-pencil-simple", size: 16)
                        .foregroundColor(AppColors.gold)
                        .accessibilityLabel(
                            String(
                                localized: "Edit your intention",
                                comment: "VoiceOver: the pencil beside the novena's intention"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    private func reminderRow(_ novena: PrayerBookDocument.Novena) -> some View {
        Button {
            sheet = .reminder(.editing)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    NovenaLabel(
                        String(
                            localized: "DAILY REMINDER", comment: "Novena page: the heading over the reminder's time"))
                    Text(
                        Self.reminderTime(progress?.reminder)
                            ?? String(
                                localized: "Off", comment: "Novena page: the reminder row when no reminder is set")
                    )
                    .font(AppFonts.readingFont(18))
                    .foregroundColor(AppColors.cream)
                }
                Spacer()
                AppIcon("ph-caret-right", size: 12).foregroundColor(AppColors.gold.opacity(0.7))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityHint(String(localized: "Choose the time.", comment: "VoiceOver hint: the novena's reminder row"))
    }

    static func reminderTime(_ components: DateComponents?) -> String? {
        guard let components, let date = Calendar.current.date(from: components) else { return nil }
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - The days

    private func daysList(_ novena: PrayerBookDocument.Novena) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NovenaLabel(
                novena.length == 9
                    ? String(localized: "THE NINE DAYS", comment: "Novena page: the heading over its days")
                    : String(
                        localized: "THE DAYS",
                        comment: "Novena page: the heading over the days of a novena not nine days long")
            )
            .padding(.bottom, 6)
            if progress == nil, let finished = store.lastFinished(novena.id) {
                finishedDays(finished, length: novena.length)
            } else if progress == nil {
                // Not begun: nine bare DAY rows read as unfinished, so the
                // days are their dashes, as on the begun page and the
                // Prayers card, and one line says what the rows become
                VStack(alignment: .leading, spacing: 12) {
                    NovenaDashes(days: NovenaDays.of(nil, length: novena.length, here: 0))
                        .accessibilityHidden(true)
                    Text(Self.notBegunDaysLine(length: novena.length))
                        .font(AppFonts.readingItalicFont(16))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            } else {
                ForEach(1...max(novena.length, 1), id: \.self) { day in
                    dayRow(day, novena: novena)
                    if day < novena.length {
                        Rectangle().fill(AppColors.gold.opacity(0.14)).frame(height: AppLine.hairline)
                    }
                }
            }
        }
    }

    /// A novena finished and not begun again (design's FINISHED.md): its
    /// days all gold, when they were prayed, and the intention kept, in
    /// place of the line a novena never begun carries
    private func finishedDays(_ finished: FinishedNovena, length: Int) -> some View {
        let range = NovenaSpan.range(from: finished.firstDate(length: length), to: finished.lastDate())
        return VStack(alignment: .leading, spacing: 12) {
            NovenaDashes(days: NovenaDays(length: length, prayed: Set(1...max(length, 1)), here: 0, open: []))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(NovenaSpan.spoken(length: length, range: range))
            Text(NovenaSpan.prayedLine(range))
                .font(AppFonts.readingItalicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let intention = finished.intention {
                Text(intention)
                    .font(AppFonts.readingItalicFont(19))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
        }
        .padding(.top, 6)
    }

    /// The line under the days of a novena not yet begun
    static func notBegunDaysLine(length: Int) -> String {
        length == 9
            ? String(
                localized: "Nine days in a row. Once you begin, each day shows its date here.",
                comment: "Novena page, not begun: under THE NINE DAYS and their nine dashes")
            : String(
                localized: "Once you begin, each day shows its date here.",
                comment: "Novena page, not begun: under THE DAYS of a novena not nine days long")
    }

    private func dayRow(_ day: Int, novena: PrayerBookDocument.Novena) -> some View {
        let state = Self.dayState(day, progress: progress, now: now)
        let canPray = progress?.canPray(day, on: now) == true
        let date = progress?.date(ofDay: day)
        return Button {
            if canPray { pray(day, of: novena) }
        } label: {
            HStack(spacing: 16) {
                Text(
                    String(localized: "DAY \(day)", comment: "Novena page: a day's row, its number; shown in capitals")
                )
                .font(AppFonts.labelFont(12))
                .tracking(1.8)
                .foregroundColor(AppColors.gold.opacity(state == .ahead ? 0.5 : 1))
                .frame(minWidth: 64, alignment: .leading)
                if let date {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream.opacity(state == .ahead ? 0.45 : 0.85))
                }
                Spacer(minLength: 8)
                switch state {
                case .prayed:
                    AppIcon("ph-check", size: 15).foregroundColor(AppColors.gold)
                case .today:
                    NovenaLabel(
                        String(localized: "TODAY", comment: "Novena page: the day to pray today, at its row's end"))
                case .open:
                    NovenaLabel(
                        Self.spokenState(.open).uppercased(),
                        dim: true)
                case .ahead, .none:
                    EmptyView()
                }
                if canPray {
                    AppIcon("ph-caret-right", size: 11).foregroundColor(AppColors.gold.opacity(0.6))
                }
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .disabled(!canPray)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Self.spokenState(state))
    }

    enum DayState { case none, prayed, today, open, ahead }

    static func dayState(_ day: Int, progress: NovenaProgress?, now: Date) -> DayState {
        guard let progress else { return .none }
        if progress.prayed.contains(day) { return .prayed }
        let today = progress.dayNumber(on: now)
        if day == today { return .today }
        if day < today, day >= 1 { return .open }
        return .ahead
    }

    static func spokenState(_ state: DayState) -> String {
        switch state {
        case .prayed: return String(localized: "prayed", comment: "VoiceOver: a novena day's state")
        case .today: return String(localized: "today", comment: "VoiceOver: a novena day's state")
        case .open:
            return String(localized: "open", comment: "VoiceOver: a novena day's state, a past day not yet prayed")
        case .ahead:
            return String(localized: "not yet", comment: "VoiceOver: a novena day's state, a day still to come")
        case .none: return ""
        }
    }

    private func endLinks(_ progress: NovenaProgress, _ novena: PrayerBookDocument.Novena) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Welcome back's card carries its own Begin Again
            if !Self.isWelcomeBack(progress, on: now) {
                Button(String(localized: "Begin again", comment: "Novena page foot: begin the novena again from Day 1")) {
                    confirming = .beginAgain
                }
                .modifier(asks(.beginAgain, novena))
            }
            Button(String(localized: "End this novena", comment: "Novena page foot: end the novena under way")) {
                confirming = .end
            }
            .modifier(asks(.end, novena))
        }
        .font(AppFonts.readingFont(17))
        .foregroundColor(AppColors.textSecondary)
        .buttonStyle(QuietGlyphButtonStyle())
    }

    static func isWelcomeBack(_ progress: NovenaProgress, on now: Date) -> Bool {
        if case .welcomeBack = progress.standing(on: now) { return true }
        return false
    }

    // MARK: - Foot

    @ViewBuilder
    private func foot(_ novena: PrayerBookDocument.Novena) -> some View {
        VStack(spacing: 10) {
            footActs(novena)
        }
        .padding(.horizontal, 22)
        .padding(.top, 48)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0), location: 0),
                    .init(color: AppColors.background.opacity(0.96), location: 0.35),
                    .init(color: AppColors.background, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func footActs(_ novena: PrayerBookDocument.Novena) -> some View {
        if let progress {
            switch progress.standing(on: now) {
            case .welcomeBack(let first):
                GoldCTAButton(
                    title: String(
                        localized: "Pick Up at Day \(first)",
                        comment: "Novena page, Welcome back: the gold act; the rest run from today"),
                    glyph: .play
                ) {
                    store.pickUp(novena, now: now)
                    pray(first, of: novena)
                }
            case .underWay(let today, _):
                if let today {
                    GoldCTAButton(
                        title: String(
                            localized: "Pray Day \(today)", comment: "Novena page: the gold act praying today's day"),
                        glyph: .play
                    ) {
                        pray(today, of: novena)
                    }
                } else if progress.dayNumber(on: now) < 1 {
                    QuietGoldButton(
                        title: String(
                            localized: "Pray Day 1 today instead",
                            comment: "Novena page, set to begin tomorrow: begin today instead")
                    ) {
                        store.beginAgain(novena, now: now)
                        pray(1, of: novena)
                    }
                } else {
                    let day = min(progress.dayNumber(on: now), novena.length)
                    Text(
                        String(
                            localized: "Day \(day) prayed",
                            comment: "Novena, after a day is prayed in the Rosary: the title"
                        ).uppercased()
                    )
                    .font(AppFonts.labelFont(11))
                    .tracking(2.4)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(minHeight: 44)
                }
            case .finished:
                EmptyView()
            }
        } else {
            let prayedBefore = store.history.contains { $0.novenaID == novena.id }
            GoldCTAButton(
                title: prayedBefore
                    ? String(localized: "Pray It Again", comment: "Novena page: begin a novena prayed before")
                    : String(localized: "Begin Today", comment: "Novena page: the gold act beginning the novena today"),
                glyph: .play
            ) {
                sheet = .intention(.beginning(tomorrow: false))
            }
            QuietGoldButton(
                title: String(localized: "Begin tomorrow", comment: "Novena page: begin the novena tomorrow instead")
            ) {
                sheet = .intention(.beginning(tomorrow: true))
            }
        }
    }

    // MARK: - Acts

    private func pray(_ day: Int, of novena: PrayerBookDocument.Novena) {
        router.push(
            .scripturalRosaryPrayer(
                ScripturalRosaryLaunch(
                    category: NovenaProgress.mysteriesToday(), form: .plain, novenaID: novena.id, novenaDay: day)))
    }

    @ViewBuilder
    private func sheetContent(_ which: NovenaSheet, novena: PrayerBookDocument.Novena) -> some View {
        switch which {
        case .intention(let mode):
            NovenaIntentionSheet(
                novena: novena,
                isBeginning: mode != .editing,
                initial: progress?.intention ?? ""
            ) { intention in
                switch mode {
                case .editing:
                    store.setIntention(intention, for: novena)
                    sheet = nil
                case .beginning(let tomorrow):
                    // The reminder comes next; the novena begins there
                    sheet = .reminder(.beginning(tomorrow: tomorrow, intention: intention))
                }
            } onCancel: {
                sheet = nil
            }
        case .reminder(let mode):
            NovenaReminderSheet(
                initial: progress?.reminder,
                isBeginning: mode != .editing,
                showsIntentionChoice: mode == .editing && progress?.intention != nil,
                showingIntention: progress?.remindsWithIntention ?? false
            ) { reminder, showingIntention in
                switch mode {
                case .editing:
                    store.setReminder(reminder, showingIntention: showingIntention, for: novena, now: now)
                case .beginning(let tomorrow, let intention):
                    let start = tomorrow ? Self.tomorrowsStart(after: now) : now
                    store.begin(novena, on: start, intention: intention, reminder: reminder, now: now)
                    if !tomorrow { pray(1, of: novena) }
                }
                sheet = nil
            } onCancel: {
                sheet = nil
            }
        }
    }
}

// MARK: - Questions

/// One of the page's two questions, hung from the control that asks it
struct NovenaQuestion: ViewModifier {
    let which: NovenaPageView.Confirmation
    @Binding var confirming: NovenaPageView.Confirmation?
    let answer: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            which == .end
                ? String(
                    localized: "End this novena? Its reminders will stop. You can begin it again any day.",
                    comment: "Novena page: the question before ending a novena")
                : String(
                    localized: "Begin again from Day 1? The days you have prayed will be cleared.",
                    comment: "Novena page: the question before beginning a novena again"),
            isPresented: Binding(get: { confirming == which }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            switch which {
            case .end:
                Button(
                    String(
                        localized: "End Novena", comment: "Novena page: the act that ends a novena, in its question"
                    ), role: .destructive, action: answer)
            case .beginAgain:
                Button(
                    String(
                        localized: "Begin Again",
                        comment: "Novena page: the act that begins a novena again from Day 1, in its question"),
                    role: .destructive, action: answer)
            }
            Button(String(localized: "Cancel", comment: "A question's way to leave it unanswered"), role: .cancel) {}
        }
    }
}

// MARK: - Sheets

enum NovenaSheet: Identifiable, Equatable {
    enum IntentionMode: Equatable {
        case beginning(tomorrow: Bool)
        case editing
    }
    enum ReminderMode: Equatable {
        case beginning(tomorrow: Bool, intention: String?)
        case editing
    }
    case intention(IntentionMode)
    case reminder(ReminderMode)

    var id: String {
        switch self {
        case .intention: return "intention"
        case .reminder: return "reminder"
        }
    }
}

/// What she prays for, optional, kept on the phone only
struct NovenaIntentionSheet: View {
    let novena: PrayerBookDocument.Novena
    let isBeginning: Bool
    let initial: String
    let onDone: (String?) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(
                    kicker: isBeginning
                        ? String(
                            localized: "BEGIN A NOVENA", comment: "Intention sheet: kicker when beginning a novena")
                        : nil,
                    title: isBeginning
                        ? novena.title
                        : NovenaPageView.intentionTitle
                ) {
                    if !isBeginning {
                        SheetHeaderAction(
                            title: String(localized: "Cancel", comment: "A sheet's way to leave without saving"),
                            action: onCancel)
                    }
                }

                Text(
                    String(
                        localized: "What are you praying for?", comment: "Intention sheet: the question over the field")
                )
                .font(AppFonts.readingFont(19))
                .foregroundColor(AppColors.cream)

                TextField("", text: $text, axis: .vertical)
                    .font(AppFonts.readingFont(18))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2...5)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
                    )
                    .focused($focused)
                    .tint(AppColors.gold)
                    .accessibilityLabel(
                        String(localized: "Your intention, optional", comment: "VoiceOver: the novena intention field"))

                Text(
                    String(
                        localized: "Optional. Only you see it, and it stays on this phone.",
                        comment: "Intention sheet: the line under the field")
                )
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    GoldCTAButton(
                        title: isBeginning
                            ? String(localized: "Continue", comment: "Intention sheet: go on to the reminder")
                            : String(localized: "Save", comment: "Intention sheet: keep the edited intention")
                    ) {
                        // The keyboard lets go first, so a word still
                        // marked by its suggestions is kept whole
                        focused = false
                        DispatchQueue.main.async { onDone(text) }
                    }
                    if isBeginning {
                        QuietGoldButton(
                            title: String(localized: "Skip", comment: "Intention sheet: begin without an intention")
                        ) {
                            onDone(nil)
                        }
                    }
                }
                .padding(.top, 6)
            }
            .padding(22)
            .sheetContentMeasure()
        }
        // As tall as it holds, not the whole glass over an empty half
        .fittedScrollingSheet()
        .sheetGround()
        .onAppear {
            text = initial
            focused = true
        }
    }
}

/// A reminder each day, at the time she chooses; never through the daily
/// reminder's own request, which turns that reminder off when refused
struct NovenaReminderSheet: View {
    let initial: DateComponents?
    let isBeginning: Bool
    let showsIntentionChoice: Bool
    let showingIntention: Bool
    let onDone: (DateComponents?, Bool) -> Void
    var onCancel: () -> Void = {}

    @Environment(\.openURL) private var openURL
    @State private var time = Date()
    @State private var withIntention = false
    @State private var denied = false

    private var timeWords: String { time.formatted(date: .omitted, time: .shortened) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(
                    title: String(localized: "A reminder each day", comment: "Reminder sheet: title"),
                    lead: String(
                        localized: "For each of the nine days, at the time you choose.",
                        comment: "Reminder sheet: the line under the title")
                ) {
                    if !isBeginning {
                        SheetHeaderAction(
                            title: String(localized: "Cancel", comment: "A sheet's way to leave without saving"),
                            action: onCancel)
                    }
                }

                if denied {
                    Text(
                        String(
                            localized:
                                "Notifications are turned off for Lumen Viae, so there can be no reminder. Your novena will be here each day all the same.",
                            comment: "Reminder sheet: notifications are off")
                    )
                    .font(AppFonts.readingFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 10) {
                        GoldCTAButton(
                            title: String(
                                localized: "Open Settings",
                                comment: "Reminder sheet: open the phone's settings for notifications")
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        QuietGoldButton(
                            title: isBeginning
                                ? String(
                                    localized: "Begin without a reminder",
                                    comment: "Reminder sheet, notifications off: begin anyway")
                                : String(
                                    localized: "Turn off the reminder",
                                    comment: "Reminder sheet, opened later: no reminder")
                        ) {
                            onDone(nil, false)
                        }
                    }
                } else {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)

                    if showsIntentionChoice {
                        Toggle(isOn: $withIntention) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(
                                    String(
                                        localized: "Show my intention in the reminder",
                                        comment: "Reminder sheet: switch")
                                )
                                .font(AppFonts.readingFont(17))
                                .foregroundColor(AppColors.cream)
                                Text(
                                    String(
                                        localized: "It will show on your lock screen.",
                                        comment: "Reminder sheet: the line under the intention switch")
                                )
                                .font(AppFonts.readingItalicFont(14))
                                .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .tint(AppColors.gold)
                    }

                    VStack(spacing: 10) {
                        GoldCTAButton(
                            title: isBeginning
                                ? String(
                                    localized: "Remind Me at \(timeWords)",
                                    comment: "Reminder sheet: the gold act, with the chosen time")
                                : String(localized: "Save", comment: "Reminder sheet: keep the chosen time")
                        ) {
                            Task { await choose() }
                        }
                        if isBeginning || initial != nil {
                            QuietGoldButton(
                                title: isBeginning
                                    ? String(
                                        localized: "No reminder", comment: "Reminder sheet: begin without a reminder")
                                    : String(
                                        localized: "Turn off the reminder",
                                        comment: "Reminder sheet, opened later: no reminder")
                            ) {
                                onDone(nil, false)
                            }
                        }
                    }
                }
            }
            .padding(22)
            .sheetContentMeasure()
        }
        // As tall as it holds, not the whole glass over an empty half
        .fittedScrollingSheet()
        .sheetGround()
        .interactiveDismissDisabled(isBeginning)
        .onAppear {
            let parts = initial ?? DateComponents(hour: 20, minute: 0)
            time =
                Calendar.current.date(bySettingHour: parts.hour ?? 20, minute: parts.minute ?? 0, second: 0, of: Date())
                ?? Date()
            withIntention = showingIntention
        }
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            denied = status == .denied
        }
    }

    private func choose() async {
        let center = UNUserNotificationCenter.current()
        var status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            denied = true
            return
        }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        onDone(parts, withIntention)
    }
}

// MARK: - Pieces

/// The novena's painting, run up under the bar and dissolving into the page
struct NovenaHero: View {
    let novena: PrayerBookDocument.Novena

    var body: some View {
        let painting =
            novena.painting.map { PrayerBookPainting.chosen($0, caption: novena.title) }
            ?? PrayerBookPainting.prayer(novena.prayerID)
        CachedAssetImage(painting.resolvedAsset, focal: painting.focal)
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.55),
                        .init(color: .black.opacity(0.3), location: 0.85),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom)
            )
            .accessibilityHidden(true)
    }
}

/// A small gold heading in tracked capitals
struct NovenaLabel: View {
    let words: String
    var dim = false

    init(_ words: String, dim: Bool = false) {
        self.words = words
        self.dim = dim
    }

    var body: some View {
        Text(words)
            .font(AppFonts.labelFont(10))
            .tracking(2.4)
            .foregroundColor(dim ? AppColors.textSecondary : AppColors.gold)
    }
}

/// A hairline card on the bare page, for the missed-day choices
struct NovenaCardFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
            )
    }
}

// MARK: - The Prayers tab's novenas

/// NOVENAS under Now on the Prayers tab (design plan, section 1; frames
/// f-r4-tab-*): the first novena's door before any is begun, then each
/// novena under way as a card naming its day. Each card opens the
/// novena's page.
struct PrayersNovenaShelf: View {
    /// The novena offered before any is begun: launch is one novena
    static let featuredID = "undoer_of_knots"

    @Environment(AppRouter.self) private var router
    let now: Date

    var body: some View {
        let under = NovenaStore.shared.progress.keys.sorted()
            .compactMap { id in NovenaDayContext.novena(id).map { ($0, NovenaStore.shared.progress[id]!) } }
        let shown: [(PrayerBookDocument.Novena, NovenaProgress?)] =
            under.isEmpty
            ? NovenaDayContext.novena(Self.featuredID).map { [($0, nil)] } ?? []
            : under.map { ($0.0, Optional($0.1)) }

        if !shown.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                PrayersShelfHeading(
                    title: under.isEmpty
                        ? String(localized: "Novenas", comment: "Prayers tab: the heading over the novena door, none begun")
                        : under.count == 1
                            ? String(localized: "Your Novena", comment: "Prayers tab: the heading over the novena under way")
                            : String(localized: "Your Novenas", comment: "Prayers tab: the heading over the novenas under way")
                )
                ForEach(shown, id: \.0.id) { novena, progress in
                    NovenaShelfCard(novena: novena, progress: progress, now: now) {
                        router.push(.novena(id: novena.id))
                    }
                }
            }
        }
    }
}

struct NovenaShelfCard: View {
    let novena: PrayerBookDocument.Novena
    let progress: NovenaProgress?
    let now: Date
    let open: () -> Void

    private static let paintingWidth: CGFloat = 112

    var body: some View {
        let painting = novena.painting.map { PrayerBookPainting.chosen($0, caption: novena.title) }
            ?? PrayerBookPainting.prayer(novena.prayerID)
        Button(action: open) {
            HStack(spacing: 0) {
                GeometryReader { proxy in
                    PrayersPaintingThumb(painting: painting, width: Self.paintingWidth, height: max(proxy.size.height, 140))
                }
                .frame(width: Self.paintingWidth)

                VStack(alignment: .leading, spacing: 6) {
                    Text(kicker)
                        .font(AppFonts.labelFont(9.5))
                        .tracking(2.2)
                        .foregroundColor(AppColors.gold)
                    Text(novena.title)
                        .font(AppFonts.titleFont(19))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let progress {
                        NovenaDashes(
                            days: NovenaDays.of(
                                progress, length: novena.length,
                                here: NovenaPageView.hereDay(progress, length: novena.length, on: now), on: now)
                        )
                        .padding(.vertical, 4)
                    }
                    Text(line)
                        .font(progress == nil ? AppFonts.readingItalicFont(15) : AppFonts.labelFont(10))
                        .tracking(progress == nil ? 0 : 2)
                        .foregroundColor(progress == nil ? AppColors.textSecondary : AppColors.gold)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
            )
        }
        .buttonStyle(SacredCardButtonStyle(scales: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(novena.title). \(kicker). \(line)"))
        .accessibilityAddTraits(.isButton)
    }

    private var kicker: String {
        guard let progress else { return NovenaPageView.kicker(length: novena.length) }
        switch progress.standing(on: now) {
        case .welcomeBack:
            return String(localized: "Welcome back", comment: "Novena page: the card after three or more days left open").uppercased()
        default:
            let day = progress.dayNumber(on: now)
            if day < 1 { return String(localized: "BEGINS TOMORROW", comment: "Prayers tab, novena card: set to begin tomorrow") }
            return String(localized: "Day \(min(day, novena.length)) of \(novena.length)", comment: "Novena: which day of how many, like Day 4 of 9").uppercased()
        }
    }

    private var line: String {
        guard let progress else {
            if let finished = NovenaStore.shared.lastFinished(novena.id) {
                return NovenaSpan.lastPrayed(finished.lastDate())
            }
            return String(localized: "Begin any day", comment: "Prayers tab, novena card: a novena not begun")
        }
        switch progress.standing(on: now) {
        case .welcomeBack(let first):
            return String(localized: "Pick Up at Day \(first)", comment: "Novena page, Welcome back: the gold act; the rest run from today").uppercased()
        case .underWay(let today, _):
            if let today { return String(localized: "Pray Day \(today)", comment: "Novena page: the gold act praying today's day").uppercased() }
            if progress.dayNumber(on: now) < 1 {
                return String(localized: "PRAY DAY 1 TODAY", comment: "Prayers tab, novena card: set to begin tomorrow, may begin today")
            }
            return String(localized: "PRAYED TODAY", comment: "Prayers tab, novena card: today's day is prayed")
        case .finished:
            return ""
        }
    }
}
