//
//  ConsecrationDayOverviewView.swift
//  Lumen Viae
//
//  The Consecrate tab's home: today's day of the 33, framed by the
//  phase's own painting.
//
//  Built in the home screen's language — an arch-framed hero with real
//  artwork, a ruled countdown to the feast, gold-hairline cards for the
//  reading, the prayers and the reflection, and the journey as four
//  collapsible phase rows rather than a strand of numbered circles that
//  ran off the edge of the screen.
//

import SwiftUI
import SwiftData

// MARK: - ConsecrationDayOverviewView

struct ConsecrationDayOverviewView: View {

    // MARK: - Properties

    @Binding var path: NavigationPath

    @Environment(ConsecrationViewModel.self) private var viewModel
    @Environment(UserSettings.self) private var settings

    /// Read-only: the source-text card cites how far through the book the
    /// user has read. The reader itself owns every write.
    @Query private var readingProgress: [TrueDevotionReadingProgress]

    /// Optional specific day to view (for revisiting past days)
    var dayNumber: Int?

    // MARK: - State

    /// One phase open at a time in the journey; the current one on appear.
    @State private var openPhase: ConsecrationPhase?
    @State private var showRestartConfirm = false
    @State private var showReadingSheet = false

    /// The chant loaded into the shared player, so the chip knows whether
    /// the audio that is playing is its own.
    @State private var loadedChantId: String?

    /// This chip's own fetch, rather than the shared player's `isLoading`
    /// — the presign hop happens before any audio is handed over, so the
    /// player is still idle while the chip is waiting.
    @State private var isPreparingChant = false

    /// Which reading the card's carousel is showing, by `order`
    @State private var visibleReading: Int?

    private let audio = AudioService.shared

    // MARK: - Computed Properties

    private var displayDayNumber: Int {
        dayNumber ?? viewModel.todaysDayNumber
    }

    private var day: ConsecrationDay? {
        ConsecrationData.day(displayDayNumber)
    }

    private var phase: ConsecrationPhase? {
        day?.phase
    }

    private var isToday: Bool {
        displayDayNumber == viewModel.todaysDayNumber
    }

    private var keptCount: Int {
        (1...33).filter { viewModel.isDayCompleted($0) }.count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                        .devotionalEntrance()

                    if viewModel.progress != nil {
                        countdownSection
                            .padding(.top, 26)
                            .padding(.horizontal, 20)
                            .devotionalEntrance(delay: 0.08)
                    }

                    VStack(spacing: 16) {
                        readingCard
                        prayersCard
                        reflectionCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .devotionalEntrance(delay: 0.16)

                    VStack(spacing: 16) {
                        journeySection
                            .padding(.top, 10)
                        sourceTextCard
                        restartButton
                            .padding(.top, 4)

                        #if DEBUG
                        debugControls
                        #endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 130)
                    .devotionalEntrance(delay: 0.24)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let dayNumber {
                viewModel.loadDay(dayNumber)
            } else {
                viewModel.loadCurrentDay()
            }
            if openPhase == nil { openPhase = phase }
        }
        .onDisappear {
            // The chant belongs to this screen; anything pushed over it
            // (the prayer flow) loads its own audio.
            //
            // Presenting the reading also takes this view off screen and
            // fires onDisappear — but the reading is this screen's own
            // page, and a chant the user started should carry on behind
            // it rather than cutting out mid-verse.
            if loadedChantId != nil && !showReadingSheet {
                audio.reset()
                audio.deactivateSession()
                loadedChantId = nil
            }
        }
        .fullScreenCover(isPresented: $showReadingSheet) {
            ConsecrationReadingSheet(
                dayNumber: displayDayNumber,
                onContinue: continueToPrayers
            )
        }
    }

    // MARK: - Hero

    /// The same arch the home screen's featured mystery is set in — the
    /// phase's painting in place of the mystery's, and the phase's hue
    /// over it in place of a flat dim.
    private var heroSection: some View {
        ArchHero(
            imageName: phase?.heroImageName ?? MysteryCategory.luminous.cardImageName,
            height: 368,
            tint: AnyShapeStyle(phaseTint),
            spacing: 13,
            contentPadding: EdgeInsets(top: 70, leading: 16, bottom: 22, trailing: 16)
        ) {
            heroContent
        }
    }

    /// The phase's own hue laid over the painting, deepening downward
    private var phaseTint: LinearGradient {
        let colors = phase?.gradientColors ?? [AppColors.background, AppColors.background]
        return LinearGradient(
            colors: [
                colors[0].opacity(0.33),
                (colors.count > 1 ? colors[1] : colors[0]).opacity(0.80)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var heroContent: some View {
        HeroBadge(badgeText)

        Text(day?.title ?? phase?.subtitle ?? "")
            .font(AppFonts.headlineFont(26))
            .foregroundColor(AppColors.cream)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .minimumScaleFactor(0.8)

        Text(heroSubtitle)
            .font(AppFonts.italicFont(14))
            .foregroundColor(AppColors.accentSoft)
            .multilineTextAlignment(.center)

        if let phase, phase != .consecrationDay {
            weekBar(phase)
        }

        GoldCTAButton(
            title: heroActionTitle,
            showsCross: isToday
        ) {
            showReadingSheet = true
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    /// A day already kept opens for rereading, not for starting over —
    /// the same distinction the old "Review Day" title drew.
    private var heroActionTitle: String {
        if viewModel.isDayCompleted(displayDayNumber) {
            return isToday ? "Revisit today's prayer" : "Revisit day \(displayDayNumber)"
        }
        return isToday ? "Begin today's prayer" : "Open day \(displayDayNumber)"
    }

    /// The phase's focus under the day's theme — unless the day is the one
    /// that opens the week and carries the week's own name, in which case
    /// repeating it twice says nothing and the ordinal is the better line.
    private var heroSubtitle: String {
        let focus = phase?.subtitle ?? ""
        guard let day else { return focus }
        return day.title.caseInsensitiveCompare(focus) == .orderedSame
            ? day.ordinalLabel
            : focus
    }

    private var badgeText: String {
        guard let phase else { return "" }
        if phase == .consecrationDay {
            return "CONSECRATION DAY"
        }
        return "\(phase.displayName.uppercased()) · DAY \(displayDayNumber) OF 33"
    }

    /// One segment per day of the phase — kept, today, and the days ahead.
    /// It replaces the 33-bead strand that used to sit here: the strand
    /// only repeated the badge, and read as decoration.
    private func weekBar(_ phase: ConsecrationPhase) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(Array(phase.dayRange), id: \.self) { number in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.cream.opacity(0.16))
                        .overlay {
                            if viewModel.isDayCompleted(number) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppColors.goldCTAGradient)
                            } else if number == displayDayNumber {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppColors.gold.opacity(0.55))
                            }
                        }
                        .frame(height: 3)
                }
            }

            // "THIS WEEK" only where a week is what it is — the
            // preparatory period runs twelve days, not seven.
            Text("\(phase.spanLabel) · DAY \(day?.dayWithinPhase ?? 1) OF \(phase.dayCount)")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.cream.opacity(0.7))
        }
        .frame(width: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Day \(day?.dayWithinPhase ?? 1) of \(phase.dayCount) "
            + (phase == .preparatory ? "of the preparation" : "this week")
        )
    }

    // MARK: - Countdown

    private var countdownSection: some View {
        VStack(spacing: 8) {
            DayPrayerLabel(
                label: countdownLabel,
                size: 10,
                tracking: 2.5,
                horizontalPadding: 0
            )

            Text(feastLine)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    /// Days between today and the consecration itself (Day 34).
    private var daysUntilConsecration: Int {
        guard let progress = viewModel.progress else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: progress.expectedCompletionDate)
        ).day ?? 0
    }

    private var countdownLabel: String {
        switch daysUntilConsecration {
        case ...0: return "CONSECRATION TODAY"
        case 1:    return "CONSECRATION TOMORROW"
        case let days: return "\(days) DAYS TO GO"
        }
    }

    /// `dateStyle` rather than a hand-written format: the feast date is
    /// read, not parsed, so it has to follow the reader's region — a
    /// fixed "d MMMM yyyy" prints 8 December 2026 to someone whose whole
    /// phone says December 8, 2026.
    private static let feastDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    /// The feast the 33 days count toward. It isn't stored — the start
    /// date was counted back from it — so it is recovered by matching the
    /// completion date against the Marian calendar.
    private var feastLine: String {
        guard let progress = viewModel.progress else { return "" }
        let date = progress.expectedCompletionDate
        let formatted = Self.feastDateFormatter.string(from: date)
        let parts = Calendar.current.dateComponents([.month, .day], from: date)

        if let feast = MarianFeastDay.all.first(where: {
            $0.month == parts.month && $0.day == parts.day
        }) {
            return "\(feast.name) · \(formatted)"
        }
        return formatted
    }

    // MARK: - Today's Reading

    private var readingCard: some View {
        let readings = day?.readings ?? []

        return VStack(alignment: .leading, spacing: 12) {
            CardHeading(readingHeading, meta: readTimeLabel)

            if readings.count > 1 {
                readingCarousel(readings)
            } else if let only = readings.first {
                readingPage(only)
            }

            HStack(spacing: 12) {
                QuietGoldButton(
                    title: "Read in full",
                    leadingIcon: "ph-book-open",
                    trailingIcon: "ph-caret-right",
                    size: 10,
                    color: AppColors.gold,
                    horizontalPadding: 0
                ) {
                    showReadingSheet = true
                }

                Spacer()

                if chantPrayer != nil {
                    chantChip
                }
            }
        }
        .sacredCard()
    }

    /// Plural when the day asks for more than one reading — the heading is
    /// the first thing that tells the user there are two.
    private var readingHeading: String {
        let plural = day?.hasMultipleReadings == true
        if isToday {
            return plural ? "Today's readings" : "Today's reading"
        }
        return plural ? "The readings" : "The reading"
    }

    /// Total for the day, summed from the per-reading counts made when the
    /// readings were built rather than on every render of this card.
    private var readTimeLabel: String? {
        guard let minutes = day?.estimatedMinutes, minutes > 0 else { return nil }
        return "\(minutes) min"
    }

    // MARK: - Reading Carousel

    /// Montfort's plan gives most days a Gospel passage *and* a spiritual
    /// reading. They are separate texts, so they get separate pages rather
    /// than being run together into one blob the user has to untangle.
    private func readingCarousel(_ readings: [ConsecrationReading]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(readings) { reading in
                        readingPage(reading)
                            .containerRelativeFrame(.horizontal)
                            .id(reading.order)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $visibleReading, anchor: .center)

            readingPageControl(readings)
        }
    }

    /// The reading now open, and the way to the other one. Dots carry full
    /// tap targets — a day has two or three readings, never enough for
    /// 44pt each to crowd the card.
    private func readingPageControl(_ readings: [ConsecrationReading]) -> some View {
        let current = visibleReading ?? readings.first?.order ?? 1

        return HStack(spacing: 0) {
            ForEach(readings) { reading in
                let isCurrent = reading.order == current

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        visibleReading = reading.order
                    }
                } label: {
                    Capsule()
                        .fill(isCurrent ? AppColors.gold : AppColors.cream.opacity(0.22))
                        .frame(width: isCurrent ? 18 : 6, height: 4)
                        .frame(width: 34, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SacredCardButtonStyle())
                .accessibilityLabel("Reading \(reading.order) of \(readings.count), \(reading.title)")
                .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
            }

            Spacer(minLength: 8)

            Text("\(current) of \(readings.count)")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary)
                .accessibilityHidden(true)
        }
        .animation(.easeOut(duration: 0.2), value: current)
    }

    /// One reading's page. Every page reserves the same number of lines so
    /// the carousel doesn't change height as it moves — a card that grows
    /// and shrinks under the thumb reads as a glitch.
    private func readingPage(_ reading: ConsecrationReading) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reading.title)
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.cream)
                .lineSpacing(3)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(preview(of: reading))
                .font(AppFonts.readingFont(17))
                .foregroundColor(AppColors.cream.opacity(0.92))
                .lineSpacing(ReadingTypography.lineSpacing(for: 17))
                .lineLimit(5, reservesSpace: true)
                .multilineTextAlignment(.leading)
                // The last line dissolves instead of stopping on an
                // ellipsis. Late enough that a short reading is untouched.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.78),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(spacing: 6) {
                if let source = reading.source {
                    Text(source)
                    Text("·")
                }
                Text("\(reading.estimatedMinutes) min")
            }
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The reading's opening, enough of it to be worth reading. Some
    /// readings open on their own theme line — a few words — so the next
    /// paragraph comes along rather than leaving the page half empty.
    private func preview(of reading: ConsecrationReading) -> String {
        ReadingText.paragraphs(of: reading.text)
            .prefix(2)
            .joined(separator: " ")
    }

    // MARK: - Chant

    /// The phase's first prayer that has a chant recording. Not every
    /// phase has one, and the chip stays away when it doesn't.
    private var chantPrayer: ConsecrationPrayer? {
        prayers.first { $0.hasChantAudio }
    }

    private var isChanting: Bool {
        loadedChantId != nil && audio.isPlaying
    }

    private var chantChip: some View {
        Button(action: toggleChant) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppColors.goldCTAGradient)
                        .frame(width: 26, height: 26)

                    if isPreparingChant {
                        SwiftUI.ProgressView()
                            .controlSize(.mini)
                            .tint(AppColors.background)
                    } else {
                        AppIcon(isChanting ? "ph-pause-fill" : "ph-play-fill", size: 11)
                            .foregroundColor(AppColors.background)
                    }
                }

                Text("CHANT")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .frame(minHeight: 44)
            .background(Capsule().fill(AppColors.background.opacity(0.5)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5))
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(isChanting ? "Pause the chant" : "Play the chant")
    }

    private func toggleChant() {
        guard let prayer = chantPrayer, !isPreparingChant else { return }

        if loadedChantId == prayer.id {
            audio.togglePlayback()
            return
        }

        isPreparingChant = true

        Task {
            defer { isPreparingChant = false }

            // A downloaded chant plays offline and skips the presign hop
            if let local = OfflineContentService.shared.localPrayerAudioURL(prayerId: prayer.id) {
                await audio.loadAudio(
                    from: local.absoluteString,
                    title: prayer.title,
                    subtitle: "33-Day Consecration"
                )
            } else {
                do {
                    let url = try await APIService.shared.fetchPrayerAudioUrl(prayerId: prayer.id)
                    await audio.loadAudio(
                        from: url,
                        title: prayer.title,
                        subtitle: "33-Day Consecration"
                    )
                } catch {
                    // A tap that does nothing at all reads as a broken
                    // button; say why instead. The tab hosts the alert.
                    viewModel.errorMessage =
                        "The chant for \(prayer.title) couldn't be loaded. "
                        + "Check your connection, or download the consecration "
                        + "audio from Account to chant offline."
                    return
                }
            }
            loadedChantId = prayer.id
            audio.play()
        }
    }

    // MARK: - Prayers

    /// One row per prayer of the phase.
    ///
    /// Resolved through the same call the prayer flow makes, so the list
    /// and the flow agree: several prayers — Veni Creator, Ave Maris
    /// Stella, the Magnificat — live only in the bilingual set, and the
    /// plain lookup drops them silently. The row shows the English title
    /// with the Latin beneath it whatever the display language, so the
    /// list stays readable while the prayers themselves follow the
    /// preference.
    /// The day's prayers, resolved once. Both this list and the chant
    /// chip read it, and the prayer flow resolves the same call for the
    /// same phase — so a row's position here is its position there.
    private var prayers: [ConsecrationPrayer] {
        guard let phase else { return [] }
        return ConsecrationData.prayers(for: phase, language: settings.prayerLanguage)
    }

    private var prayerRows: [(prayer: ConsecrationPrayer, english: String, latin: String?)] {
        let bilingual = BilingualConsecrationPrayers.allPrayers

        return prayers.map { prayer in
            let record = bilingual[prayer.id]
            return (
                prayer: prayer,
                english: record?.englishTitle ?? prayer.title,
                latin: record?.latinTitle ?? prayer.latinTitle
            )
        }
    }

    private var prayersCard: some View {
        let rows = prayerRows

        return VStack(alignment: .leading, spacing: 14) {
            CardHeading(
                "Prayers for \(phase?.displayName ?? "")",
                meta: rows.count == 1 ? "1 prayer" : "\(rows.count) prayers"
            )

            languageSelector

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.prayer.id) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.15))
                            .frame(height: 0.5)
                    }
                    prayerRow(english: row.english, latin: row.latin, at: index)
                }
            }
        }
        .sacredCard()
    }

    private func prayerRow(english: String, latin: String?, at index: Int) -> some View {
        Button {
            viewModel.resetPrayers()
            path.append(
                ConsecrationRoute.prayerFlow(dayNumber: displayDayNumber, startIndex: index)
            )
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppColors.goldGradient)
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(english)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    if let latin,
                       settings.prayerLanguage != .english,
                       latin.caseInsensitiveCompare(english) != .orderedSame {
                        Text(latin)
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.accentSoft)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 9)
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.vertical, 11)
            .frame(minHeight: 44)
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    /// English / Latin / Both, bound to the app-wide prayer language.
    ///
    /// It writes the same preference the Account screen does, so the
    /// caption says so — a tap here to glance at the Latin shouldn't
    /// quietly re-language the user's Rosary as well.
    private var languageSelector: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                languageCapsule("English", language: .english)
                languageCapsule("Latin", language: .latin)
                languageCapsule("Both", language: .both)
            }

            Text("Sets the prayer language everywhere you pray")
                .font(AppFonts.italicFont(11))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func languageCapsule(_ title: String, language: PrayerLanguage) -> some View {
        // "Both" covers either bilingual order — a user who chose
        // "English & Latin" in Account shouldn't see it read as unselected.
        let isSelected = language.isBilingual
            ? settings.prayerLanguage.isBilingual
            : settings.prayerLanguage == language

        return Button {
            guard !isSelected else { return }
            settings.prayerLanguagePreference = language.rawValue
        } label: {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Capsule().fill(
                        isSelected ? AppColors.cardElevated : AppColors.background.opacity(0.5)
                    )
                )
                .overlay(
                    Capsule().strokeBorder(
                        AppColors.gold.opacity(isSelected ? 0.7 : 0.15),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Reflection

    @ViewBuilder
    private var reflectionCard: some View {
        if let prompt = day?.journalPrompt, !prompt.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                CardHeading(isToday ? "Today's reflection" : "The reflection")

                Text(prompt)
                    .font(AppFonts.readingItalicFont(17))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .lineSpacing(ReadingTypography.lineSpacing(for: 17))
                    .fixedSize(horizontal: false, vertical: true)

                QuietGoldButton(
                    title: "Write in your journal",
                    leadingIcon: "ph-note-pencil",
                    trailingIcon: "ph-caret-right",
                    size: 10,
                    color: AppColors.gold,
                    horizontalPadding: 0
                ) {
                    path.append(ConsecrationRoute.journal(dayNumber: displayDayNumber))
                }
            }
            .sacredCard()
        }
    }

    // MARK: - Your Journey

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeading("Your journey", meta: "\(keptCount) of 33 kept")

            // Every phase, the consecration itself included — Day 34 is
            // the one day of the thirty-four a user is most likely to
            // want to return to, and filtering it out left no route back.
            VStack(spacing: 0) {
                ForEach(ConsecrationPhase.allCases, id: \.self) { phase in
                    JourneyPhaseRow(
                        phase: phase,
                        today: viewModel.todaysDayNumber,
                        selected: displayDayNumber,
                        isExpanded: openPhase == phase,
                        isCompleted: viewModel.isDayCompleted,
                        canAccess: viewModel.canAccessDay,
                        onToggle: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                openPhase = openPhase == phase ? nil : phase
                            }
                        },
                        onSelectDay: { number in
                            guard number != displayDayNumber else { return }
                            path.append(ConsecrationRoute.dayOverview(dayNumber: number))
                        }
                    )
                }
            }
        }
    }

    // MARK: - Source Text

    private var sourceTextCard: some View {
        Button {
            path.append(ConsecrationRoute.trueDevotionReader)
        } label: {
            HStack(spacing: 14) {
                AppIcon("ch-bible", size: 26)
                    .foregroundColor(AppColors.gold)

                VStack(alignment: .leading, spacing: 3) {
                    Text("THE SOURCE TEXT")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)

                    Text("Read True Devotion in full")
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    Text(readingProgressLabel)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                AppIcon("ph-caret-right", size: 11)
                    .foregroundColor(AppColors.gold.opacity(0.6))
            }
            .sacredCard(padding: 16)
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    private var readingProgressLabel: String {
        guard let book = TrueDevotionLibrary.shared.book else {
            return "St. Louis de Montfort"
        }
        let total = book.chapters.count
        let completed = readingProgress.first?.completedChapterIDs ?? []
        let read = book.chapters.filter { completed.contains($0.id) }.count

        guard read > 0 else {
            return "\(total) chapters · St. Louis de Montfort"
        }
        let percent = Int((Double(read) / Double(total) * 100).rounded())
        return "Chapter \(min(read + 1, total)) of \(total) · \(percent)% read"
    }

    // MARK: - Restart

    private var restartButton: some View {
        QuietGoldButton(
            title: "Restart consecration",
            size: 10,
            color: AppColors.textSecondary
        ) {
            showRestartConfirm = true
        }
        .frame(maxWidth: .infinity)
        .confirmationDialog(
            "Restart your consecration?",
            isPresented: $showRestartConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase Progress and Start Over", role: .destructive) {
                viewModel.abandonConsecration()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your day progress will be erased so you can begin again. Journal reflections you have written are kept in your Journal.")
        }
    }

    // MARK: - Testing Controls

    /// Never in a shipped build — but walking the 33 days by hand is the
    /// only way to see a phase change, so the controls stay for DEBUG.
    #if DEBUG
    private var debugControls: some View {
        HStack(spacing: 10) {
            QuietGoldButton(
                title: "Next day",
                leadingIcon: "ph-skip-forward",
                leadingIconSize: 11,
                size: 9,
                color: AppColors.textSecondary.opacity(0.6),
                horizontalPadding: 0
            ) {
                viewModel.debugAdvanceDay()
            }

            Spacer()

            QuietGoldButton(
                title: "Reset",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 11,
                size: 9,
                color: AppColors.textSecondary.opacity(0.6),
                horizontalPadding: 0
            ) {
                viewModel.debugResetConsecration()
            }
        }
        .padding(.top, 8)
    }
    #endif

    // MARK: - Navigation

    /// The reading sheet hands off to the prayers. The push waits a beat
    /// so the cover finishes dismissing over the stack it is pushing onto.
    private func continueToPrayers() {
        showReadingSheet = false
        let target = displayDayNumber
        DispatchQueue.main.async {
            viewModel.resetPrayers()
            path.append(ConsecrationRoute.prayerFlow(dayNumber: target, startIndex: 0))
        }
    }
}

// MARK: - CardHeading

/// A card's engraved kicker, with an optional italic meta on the right.
struct CardHeading: View {

    let title: String
    var meta: String?

    init(_ title: String, meta: String? = nil) {
        self.title = title
        self.meta = meta
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if let meta {
                Text(meta)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize()
            }
        }
    }
}

// MARK: - JourneyPhaseRow

/// One phase of the 33 days: a quiet line with a hairline progress bar
/// that opens into its own days. This replaces both the 33-bead strand
/// and the row of numbered circles, which clipped at the screen edge and
/// never said which week a day belonged to.
private struct JourneyPhaseRow: View {

    let phase: ConsecrationPhase
    let today: Int
    let selected: Int
    let isExpanded: Bool
    let isCompleted: (Int) -> Bool
    let canAccess: (Int) -> Bool
    let onToggle: () -> Void
    let onSelectDay: (Int) -> Void

    private var days: [Int] { Array(phase.dayRange) }
    private var keptInPhase: Int { days.filter(isCompleted).count }
    private var isCurrent: Bool { phase.dayRange.contains(today) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.15))
                .frame(height: 0.5)

            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(phase.displayName.uppercased())
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(isCurrent ? AppColors.gold : AppColors.textSecondary)
                            .fixedSize()

                        Text(phase.subtitle)
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(isCurrent ? AppColors.cream : AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 4)

                        Text("\(keptInPhase)/\(days.count)")
                            .font(AppFonts.bodyFont(11))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppColors.cream.opacity(0.1))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppColors.goldCTAGradient)
                                .frame(
                                    width: geometry.size.width
                                        * (Double(keptInPhase) / Double(days.count))
                                )
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.vertical, 13)
                .frame(minHeight: 44)
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityLabel("\(phase.displayName), \(keptInPhase) of \(days.count) kept")
            .accessibilityHint(isExpanded ? "Collapses the days" : "Shows the days")

            if isExpanded {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 2)],
                    alignment: .leading,
                    spacing: 2
                ) {
                    ForEach(days, id: \.self) { number in
                        dayCircle(number)
                    }
                }
                .padding(.bottom, 13)
            }
        }
    }

    private func dayCircle(_ number: Int) -> some View {
        let kept = isCompleted(number)
        let isToday = number == today
        let reachable = canAccess(number)

        return Button {
            onSelectDay(number)
        } label: {
            Text("\(number)")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(numberColor(kept: kept, isToday: isToday, reachable: reachable))
                .frame(width: 32, height: 32)
                .background {
                    if kept {
                        Circle().fill(AppColors.goldCTAGradient)
                    } else {
                        Circle().fill(AppColors.background.opacity(0.5))
                    }
                }
                .overlay {
                    if isToday {
                        Circle().strokeBorder(AppColors.goldLight, lineWidth: 1)
                    } else if !kept {
                        Circle().strokeBorder(AppColors.gold.opacity(0.25), lineWidth: 0.5)
                    }
                }
                // The day being read carries a ring outside its own edge
                .overlay {
                    if number == selected {
                        Circle()
                            .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 2)
                            .padding(-3)
                    }
                }
                // The mark stays small and quiet; the target around it is
                // full size. Thirty-four of these sit side by side, and
                // this is the route back to a day someone missed.
                .frame(width: 44, height: 44)
        }
        .buttonStyle(SacredCardButtonStyle())
        // Days still ahead stay quiet rather than opening early
        .disabled(!reachable)
        .accessibilityLabel(
            "Day \(number)\(kept ? ", kept" : "")\(isToday ? ", today" : "")\(reachable ? "" : ", not yet")"
        )
    }

    private func numberColor(kept: Bool, isToday: Bool, reachable: Bool) -> Color {
        if kept { return AppColors.background }
        if isToday { return AppColors.goldLight }
        return AppColors.cream.opacity(reachable ? 0.45 : 0.25)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationDayOverviewView(path: .constant(NavigationPath()))
            .environment(ConsecrationViewModel())
            .environment(UserSettings.shared)
    }
    .modelContainer(for: [ConsecrationProgress.self, TrueDevotionReadingProgress.self], inMemory: true)
}
