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

    @Binding var path: [ConsecrationRoute]

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

    /// The bilingual order the user chose for their profile, remembered
    /// so that stepping out to English and back to "Both" returns them
    /// to their own order rather than the app's default.
    @State private var profileBilingualOrder: PrayerLanguage = .latinUnderEnglish

    // No audio on this screen. The reading card carried a CHANT chip,
    // which played the phase's first *prayer* — narration for the
    // reading itself doesn't exist yet, so the control promised
    // something the card couldn't deliver. The chants are still one tap
    // away: every prayer that has one carries its own transport inside
    // the day flow. When reading audio does land, it belongs here.

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

    private var completedCount: Int {
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
            if settings.prayerLanguage.isBilingual {
                profileBilingualOrder = settings.prayerLanguage
            }
        }
    }

    // MARK: - Hero

    /// The cathedral-window arch that frames the phase's painting
    private var arch: GothicArchShape { GothicArchShape(riseRatio: 0.34) }

    private var heroSection: some View {
        arch
            .fill(AppColors.cardBackground)
            .frame(height: 368)
            .overlay(
                CachedAssetImage(phase?.heroImageName ?? MysteryCategory.luminous.cardImageName)
                    .aspectRatio(contentMode: .fill)
                    .overlay(phaseTint)
            )
            .clipShape(arch)
            .overlay(
                arch.strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1)
            )
            .overlay(
                arch.inset(by: 5)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
            )
            .overlay(alignment: .bottom) { heroContent }
            // The foot dissolves so the arch never closes on a rule drawn
            // straight across the screen. No halo underneath it: a glow
            // survives the mask and re-draws the very edge the mask
            // exists to remove, as a bright band under the arch's foot.
            .mask(
                VStack(spacing: 0) {
                    Rectangle().fill(.black)
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)
                }
            )
    }

    /// The phase's own hue laid over the painting, deepening downward
    private var phaseTint: some View {
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

    private var heroContent: some View {
        VStack(spacing: 13) {
            phaseBadge

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

            // One act, full width. The week bar and its "DAY 3 OF 12
            // THIS WEEK" used to sit here and said nothing the badge
            // above and the journey below don't already say.
            GoldCTAButton(title: heroActionTitle, showsCross: isToday && !isDayComplete) {
                path.append(.dayFlow(dayNumber: displayDayNumber, step: .reading))
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
        }
        .padding(.top, 70)
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
        // The featured card's scrim, stop for stop: out of the way through
        // the top third, gathering only where the words need ground.
        .background(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.background.opacity(0.5), location: 0.34),
                    .init(color: AppColors.background.opacity(0.86), location: 0.66),
                    .init(color: AppColors.background, location: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var isDayComplete: Bool {
        viewModel.isDayCompleted(displayDayNumber)
    }

    /// A day already prayed doesn't need to be told it was; the journey
    /// below counts it. The act just stops asking to be begun.
    private var heroActionTitle: String {
        if isDayComplete { return "Pray it again" }
        return isToday ? "Begin today's prayer" : "Open day \(displayDayNumber)"
    }

    private var phaseBadge: some View {
        Text(badgeText)
            .font(AppFonts.labelFont(9))
            .tracking(2.5)
            .foregroundColor(AppColors.goldLight)
            .padding(.horizontal, 15)
            .padding(.vertical, 7)
            .background(Capsule().fill(AppColors.background.opacity(0.55)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.45), lineWidth: 1))
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

    // MARK: - The Feast

    /// The feast the 33 days count toward, and its date. The countdown
    /// that used to head this — "31 DAYS TO GO" — said the same thing
    /// the badge above already says as "DAY 3 OF 33", one line apart.
    private var countdownSection: some View {
        VStack(spacing: 8) {
            DayPrayerLabel(
                label: feastName,
                size: 10,
                tracking: 2.5,
                horizontalPadding: 0
            )

            Text(feastDate)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            // No guilt about a feast that came and went — the days
            // already completed stand, and another feast is always coming.
            if daysUntilConsecration < 0 {
                Text("The days you completed still stand. Choose another feast whenever you're ready.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
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

    private static let feastDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    /// The feast the 33 days count toward. It isn't stored — the start
    /// date was counted back from it — so it is recovered by matching the
    /// completion date against the Marian calendar.
    private var feast: MarianFeastDay? {
        guard let progress = viewModel.progress else { return nil }
        let parts = Calendar.current.dateComponents(
            [.month, .day],
            from: progress.expectedCompletionDate
        )
        return MarianFeastDay.all.first {
            $0.month == parts.month && $0.day == parts.day
        }
    }

    /// The ruled line over the date. A feast that has already gone by
    /// says so here rather than as a countdown running backwards.
    private var feastName: String {
        if daysUntilConsecration < 0 { return "YOUR CONSECRATION DAY HAS PASSED" }
        return (feast?.name ?? "Your consecration day").uppercased()
    }

    private var feastDate: String {
        guard let progress = viewModel.progress else { return "" }
        return Self.feastDateFormatter.string(from: progress.expectedCompletionDate)
    }

    // MARK: - Today's Reading

    private var readingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeading(isToday ? "Today's reading" : "The reading", meta: readTimeLabel)

            Text(day?.meditationTitle ?? "")
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.cream)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            readingPreview

            if let source = day?.meditationSource {
                Text(source)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }

            QuietGoldButton(
                title: "Read in full",
                leadingIcon: "ph-book-open",
                trailingIcon: "ph-caret-right",
                size: 10,
                color: AppColors.gold,
                horizontalPadding: 0
            ) {
                openDay(at: .reading)
            }
        }
        .sacredCard()
    }

    private var firstParagraph: String {
        ReadingText.paragraphs(of: day?.meditationText ?? "").first ?? ""
    }

    /// The opening paragraph, clamped where it would run past the card
    private var readingPreview: some View {
        ReadingExcerpt(text: firstParagraph, size: 18, clampsAfter: 260, maxHeight: 132)
    }

    /// Reading time at the 200-words-a-minute the book reader uses
    private var readTimeLabel: String? {
        guard let text = day?.meditationText, !text.isEmpty else { return nil }
        let words = text.split(separator: " ").count
        return "\(max(1, Int((Double(words) / 200.0).rounded(.up)))) min"
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
    private var prayerRows: [(prayer: ConsecrationPrayer, english: String, latin: String?)] {
        guard let phase else { return [] }
        let bilingual = BilingualConsecrationPrayers.allPrayers()

        return ConsecrationData
            .prayers(for: phase, language: settings.prayerLanguage)
            .map { prayer in
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

    /// How a row reads under the chosen language. Latin means Latin —
    /// the title itself, not an English title with a Latin footnote —
    /// and the bilingual modes lead with whichever language the user's
    /// own order puts first.
    private func rowTitles(english: String, latin: String?) -> (primary: String, secondary: String?) {
        let distinctLatin = latin.flatMap {
            $0.caseInsensitiveCompare(english) == .orderedSame ? nil : $0
        }

        switch settings.prayerLanguage {
        case .english:
            return (english, nil)
        case .latin:
            return (distinctLatin ?? english, nil)
        case .both:
            // "Latin & English"
            return (distinctLatin ?? english, distinctLatin == nil ? nil : english)
        case .latinUnderEnglish:
            // "English & Latin"
            return (english, distinctLatin)
        }
    }

    private func prayerRow(english: String, latin: String?, at index: Int) -> some View {
        let titles = rowTitles(english: english, latin: latin)

        return Button {
            openDay(at: .prayer(index))
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppColors.goldGradient)
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(titles.primary)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)

                    if let secondary = titles.secondary {
                        Text(secondary)
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
    private var languageSelector: some View {
        HStack(spacing: 6) {
            languageCapsule("English", language: .english)
            languageCapsule("Latin", language: .latin)
            languageCapsule("Both", language: .both)
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
            selectLanguage(language)
        } label: {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                .foregroundColor(isSelected ? AppColors.goldLight : AppColors.textSecondary)
                // Three capsules sharing one row: at accessibility text
                // sizes "English" is the first to run out of room
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
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

    /// "Both" leads with English unless the user's own profile order is
    /// Latin over English — in which case tapping it here restores that
    /// order rather than silently overriding a choice made in Account.
    private func selectLanguage(_ language: PrayerLanguage) {
        guard language.isBilingual else {
            settings.prayerLanguagePreference = language.rawValue
            return
        }
        settings.prayerLanguagePreference = profileBilingualOrder.rawValue
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
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)

                QuietGoldButton(
                    title: "Write in your journal",
                    leadingIcon: "ph-note-pencil",
                    trailingIcon: "ph-caret-right",
                    size: 10,
                    color: AppColors.gold,
                    horizontalPadding: 0
                ) {
                                path.append(.journal(dayNumber: displayDayNumber))
                }
            }
            .sacredCard()
        }
    }

    // MARK: - Your Journey

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeading("Your journey", meta: "\(completedCount) of 33 complete")

            VStack(spacing: 0) {
                ForEach(ConsecrationPhase.allCases.filter { $0 != .consecrationDay }, id: \.self) { phase in
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
                        onSelectDay: openDay
                    )
                }
            }
        }
    }

    /// Opens another day of the 33 *in place of* the day being read
    /// rather than on top of it. Browsing four days used to leave four
    /// identical screens stacked, and reaching today from a past day
    /// gave a second copy of the tab root — same screen, but with a back
    /// chevron and no tab bar.
    private func openDay(_ number: Int) {
        guard number != displayDayNumber else { return }

        if number == viewModel.todaysDayNumber {
            // The root already is today; return to it.
            path.removeAll()
        } else if case .dayOverview = path.last {
            path[path.count - 1] = .dayOverview(dayNumber: number)
        } else {
            path.append(.dayOverview(dayNumber: number))
        }
    }

    // MARK: - Source Text

    private var sourceTextCard: some View {
        Button {
                path.append(.trueDevotionReader)
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
            Text("Your day progress will be erased so you can begin again. Journal reflections you have written stay in your Journal.")
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

    /// Opens the day at a given step. The reading and the prayers are one
    /// pushed screen, so there is no cover to dismiss first and no beat
    /// where the dashboard shows through between them.
    private func openDay(at step: ConsecrationDayStep) {
        path.append(.dayFlow(dayNumber: displayDayNumber, step: step))
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
    private var completedInPhase: Int { days.filter(isCompleted).count }
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

                        Text("\(completedInPhase)/\(days.count)")
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
                                        * (Double(completedInPhase) / Double(days.count))
                                )
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.vertical, 13)
                .frame(minHeight: 44)
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityLabel("\(phase.displayName), \(completedInPhase) of \(days.count) complete")
            .accessibilityHint(isExpanded ? "Collapses the days" : "Shows the days")

            if isExpanded {
                // 44pt cells around the 30pt circles: the gap between
                // them is the cell's own margin, so the row still reads
                // as a quiet grid of numbers rather than a row of chips.
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 0)],
                    alignment: .leading,
                    spacing: 0
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
        let isDone = isCompleted(number)
        let isToday = number == today
        let reachable = canAccess(number)

        return Button {
            onSelectDay(number)
        } label: {
            Text("\(number)")
                .font(AppFonts.bodyFont(12))
                .foregroundColor(numberColor(isDone: isDone, isToday: isToday, reachable: reachable))
                .frame(width: 30, height: 30)
                .background {
                    if isDone {
                        Circle().fill(AppColors.goldCTAGradient)
                    } else {
                        Circle().fill(AppColors.background.opacity(0.5))
                    }
                }
                .overlay {
                    if isToday {
                        Circle().strokeBorder(AppColors.goldLight, lineWidth: 1)
                    } else if !isDone {
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
                // The circle stays 30pt; the finger gets 44pt
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        // Days still ahead stay quiet rather than opening early
        .disabled(!reachable)
        .accessibilityLabel(
            "Day \(number)\(isDone ? ", complete" : "")\(isToday ? ", today" : "")\(reachable ? "" : ", not yet")"
        )
    }

    private func numberColor(isDone: Bool, isToday: Bool, reachable: Bool) -> Color {
        if isDone { return AppColors.background }
        if isToday { return AppColors.goldLight }
        return AppColors.cream.opacity(reachable ? 0.45 : 0.25)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsecrationDayOverviewView(path: .constant([]))
            .environment(ConsecrationViewModel())
            .environment(UserSettings.shared)
    }
    .modelContainer(for: [ConsecrationProgress.self, TrueDevotionReadingProgress.self], inMemory: true)
}
