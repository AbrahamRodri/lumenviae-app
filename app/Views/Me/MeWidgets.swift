//
//  MeWidgets.swift
//  Lumen Viae
//
//  The sections a user can place on their Me page. Same silhouette,
//  different characters: the rule is a ruled checklist, the library a
//  quiet grid of doors, consecration carries a votive wash, reflections
//  read as quoted lines from the journal.
//
//  None of these own their data — they read the same services and
//  SwiftData models the rest of the app writes, so removing a card from
//  the page removes a view of the practice, never the practice itself.
//

import SwiftUI
import SwiftData

// MARK: - Rule of Prayer

/// The user's daily rule: the devotions they mean to offer each day,
/// gathered as a checklist. Acts the app can see finish (the Rosary,
/// the consecration day) check themselves; acts it cannot (the Mass,
/// the Office) are checked by hand.
///
/// Missed days are never carried forward or called out — the rule
/// starts each morning unmarked, in keeping with the streak's own
/// no-guilt rules.
struct RuleOfPrayerCard: View {

    let historyService: PrayerHistoryService?
    let onArrange: () -> Void

    @Environment(UserSettings.self) private var settings
    @Environment(AppRouter.self) private var router

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    /// Sessions drive re-evaluation of the self-checking rows
    @Query private var sessions: [PrayerSession]

    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    var body: some View {
        MeSection(title: "Rule of Prayer", icon: "ch-rosary") {
            if settings.ruleItems.isEmpty {
                emptyRule
            } else {
                VStack(spacing: 0) {
                    ForEach(settings.ruleItems) { item in
                        RuleRow(
                            item: item,
                            subtitle: subtitle(for: item),
                            state: state(for: item),
                            onOpen: { router.run(item) },
                            onToggle: { done in settings.setRuleChecked(item, done) }
                        )

                        if item != settings.ruleItems.last {
                            Divider()
                                .background(AppColors.gold.opacity(0.2))
                                .padding(.horizontal, 16)
                        }
                    }

                    Divider()
                        .background(AppColors.gold.opacity(0.2))
                        .padding(.horizontal, 16)

                    Text(summaryLine)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        } accessory: {
            QuietGoldButton(
                title: "Edit",
                size: 9,
                color: AppColors.gold.opacity(0.8),
                horizontalPadding: 0,
                action: onArrange
            )
            .padding(.vertical, -10)
        }
    }

    private var emptyRule: some View {
        VStack(spacing: 10) {
            Text("No devotions yet.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)

            QuietGoldButton(
                title: "Choose your rule",
                size: 10,
                color: AppColors.gold,
                horizontalPadding: 0,
                action: onArrange
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    // MARK: State

    /// How a rule row shows and settles its completion.
    enum RuleState {
        /// The app saw this finish today
        case doneAutomatically
        /// The app will see it finish; it hasn't yet
        case awaitingAutomatic
        /// Checked or uncheckable only by hand
        case manual(done: Bool)
    }

    private func state(for item: PrayerShortcut) -> RuleState {
        switch item {
        case .todaysRosary:
            // Any set of mysteries counts — praying the Luminous on a
            // Monday is still today's Rosary. The chaplet does not: it
            // has its own row here, and crediting a Rosary nobody prayed
            // would tell the user "All offered today" over an unprayed
            // line they cannot uncheck.
            let prayedRosary = historyService?.sessions(on: Date())
                .contains { $0.category != .sevenSorrows } ?? false
            return prayedRosary ? .doneAutomatically : .awaitingAutomatic

        case .sevenSorrows:
            let prayed = historyService?.sessions(on: Date())
                .contains { $0.category == .sevenSorrows } ?? false
            return prayed ? .doneAutomatically : .awaitingAutomatic

        case .consecration:
            guard let progress = activeConsecration else {
                return .awaitingAutomatic
            }
            return progress.isDayCompleted(progress.currentDayNumber)
                ? .doneAutomatically : .awaitingAutomatic

        case .mass, .office, .chooseMeditation:
            return .manual(done: settings.isRuleChecked(item))
        }
    }

    private func subtitle(for item: PrayerShortcut) -> String {
        switch item {
        case .todaysRosary:
            return ScheduleService.categoryForToday().devotionTitle
        case .consecration:
            guard let progress = activeConsecration else {
                return "Not yet begun"
            }
            return "Day \(min(progress.currentDayNumber, 33)) of 33"
        default:
            return item.subtitle
        }
    }

    private var summaryLine: String {
        let states = settings.ruleItems.map(state(for:))
        let done = states.filter {
            switch $0 {
            case .doneAutomatically, .manual(done: true): return true
            default: return false
            }
        }.count

        if done == states.count {
            return "All offered today."
        }
        if done == 0 {
            return "Nothing yet today."
        }
        return "\(done) of \(states.count) offered today."
    }
}

// MARK: - RuleRow

private struct RuleRow: View {
    let item: PrayerShortcut
    let subtitle: String
    let state: RuleOfPrayerCard.RuleState
    let onOpen: () -> Void
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 16) {
            // The row body opens the act
            Button(action: onOpen) {
                HStack(spacing: 16) {
                    AppIcon(item.icon, size: 18)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(AppFonts.bodyFont(16))
                            .foregroundColor(AppColors.cream)

                        Text(subtitle)
                            .font(AppFonts.bodyFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            checkMark
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var checkMark: some View {
        switch state {
        case .doneAutomatically:
            AppIcon("ph-seal-check-fill", size: 22)
                .foregroundColor(AppColors.gold)
                .frame(width: 44, height: 44)
                .accessibilityLabel("\(item.title), offered today")

        case .awaitingAutomatic:
            // Not tappable: the act itself completes it
            Circle()
                .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 1.2)
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

        case .manual(let done):
            Button(action: { onToggle(!done) }) {
                ZStack {
                    if done {
                        AppIcon("ph-check-circle-fill", size: 22)
                            .foregroundColor(AppColors.gold)
                    } else {
                        Circle()
                            .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 1.2)
                            .frame(width: 22, height: 22)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: done)
            .accessibilityLabel(done ? "\(item.title), marked offered" : "Mark \(item.title) offered")
        }
    }
}

// MARK: - Reading

/// The book left face-down on the table.
///
/// An oratory is a room arranged by the one who prays in it, and a room
/// like that has a book open on the prie-dieu. One book — the most
/// recent — never a "Currently Reading (3)" list: that is library
/// management, and this is a chapel.
///
/// It names both places, because a book can be held in two hands: the
/// chapter the eye left, and — when there is one — the reading the voice
/// left mid-way. "Take it up" resumes whichever was more recent.
struct ReadingCard: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BookReadingProgress.updatedAt, order: .reverse)
    private var progress: [BookReadingProgress]

    /// The most recently touched book that the catalog still carries.
    private var current: (row: BookReadingProgress, info: LibraryBookInfo)? {
        for row in progress {
            if let info = LibraryCatalog.book(id: row.bookID) { return (row, info) }
        }
        return nil
    }

    var body: some View {
        MeSection(title: "Reading", icon: "ph-book-open-fill") {
            Group {
                if let current {
                    open(current.row, current.info)
                } else {
                    invitation
                }
            }
            .padding(16)
        }
    }

    // MARK: A book under way

    private func open(_ row: BookReadingProgress, _ info: LibraryBookInfo) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // The book's own cloth, small — you know which book it is
            // before you have read a word of the card.
            BookCover(info: info, isLettered: false)
                .frame(width: 54)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(info.author.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .lineLimit(1)

                Text(info.title)
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let place = chapterLine(row) {
                    Text(place)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                if row.hasResumableTrack {
                    HStack(spacing: 5) {
                        AppIcon("ph-speaker-high", size: 11)
                        Text("\(LibraryListeningSession.elapsedLabel(row.lastTrackSeconds)) into the reading")
                            .font(AppFonts.italicFont(12))
                    }
                    .foregroundColor(AppColors.goldLight.opacity(0.85))
                }

                QuietGoldButton(
                    title: "Take it up",
                    trailingIcon: "ph-caret-right",
                    size: 10,
                    color: AppColors.gold,
                    horizontalPadding: 0
                ) {
                    takeUp(row, info)
                }
                .padding(.vertical, -10)
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// "Chapter IX" — the chapter's own label, recorded with the place
    /// so the card never has to fetch and parse a whole book to name it,
    /// and never has to count. Absent for a place from a superseded
    /// cutting of the edition, or from before labels were stored.
    private func chapterLine(_ row: BookReadingProgress) -> String? {
        guard LibraryProgressStore.isCurrent(row), !row.lastChapterTitle.isEmpty
        else { return nil }
        return row.lastChapterTitle
    }

    /// Resumes whichever hand the book was last held in.
    private func takeUp(_ row: BookReadingProgress, _ info: LibraryBookInfo) {
        let listened = row.lastListenedAt ?? .distantPast
        let read = row.lastReadAt ?? .distantPast

        if row.hasResumableTrack, listened > read {
            // The recording lives on the book page, where its ledger and
            // its transport are.
            router.push(.libraryBook(id: info.id))
        } else if LibraryProgressStore.isCurrent(row) {
            router.push(.libraryChapter(bookID: info.id, chapterIndex: row.lastChapterIndex))
        } else {
            router.push(.libraryBook(id: info.id))
        }
    }

    // MARK: Nothing open yet

    /// A real empty state, not a blank frame: the shelf itself, and the
    /// three words written on it.
    private var invitation: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(LibraryCatalog.books.prefix(4)) { book in
                    BookCover(info: book, isLettered: false)
                        .frame(width: 40)
                }
            }
            .accessibilityHidden(true)

            Text("Tolle, lege — take up and read")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.85))

            QuietGoldButton(
                title: "The shelf",
                trailingIcon: "ph-caret-right",
                size: 10,
                color: AppColors.gold,
                horizontalPadding: 0
            ) {
                router.push(.spiritualReading)
            }
            .padding(.vertical, -10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nothing open yet. Take up and read.")
    }
}

// MARK: - Library

/// The doors the home screen's old menu button used to open, plus the
/// Sacred Record. Not nine identical tiles: the two liturgical books
/// stand together as a diptych across the card's head — the same
/// pairing the home shelf and Explore make — and the reading doors
/// follow as a ruled index, a table of contents rather than a wall of
/// boxes.
struct LibraryCard: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        MeSection(title: "Library", icon: "ph-book-open") {
            VStack(spacing: 0) {
                // Every door is a pushed page — content slides in from
                // the right; sheets are kept for tasks, not places.
                HStack(spacing: 0) {
                    diptychLeaf("ch-altar", "Daily Missal", "The Mass") {
                        router.push(.missal)
                    }

                    Rectangle()
                        .fill(AppColors.gold.opacity(0.22))
                        .frame(width: 0.5)
                        .padding(.vertical, 12)

                    diptychLeaf("ch-candle", "Divine Office", "The Hours") {
                        router.push(.office)
                    }
                }

                Rectangle()
                    .fill(AppColors.gold.opacity(0.18))
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)],
                    spacing: 0
                ) {
                    indexRow("ph-crown", "True Devotion") { router.push(.trueDevotion) }
                    indexRow("ph-book-open", "Spiritual Reading") { router.push(.spiritualReading) }
                    indexRow("ch-rosary", "How to Pray") { router.push(.howToPray) }
                    indexRow("ch-bible", "In Scripture") { router.push(.scripture) }
                    indexRow("ph-heart", "Marian Library") { router.push(.marianLibrary) }
                    indexRow("ch-monstrance", "Carlo Acutis") { router.push(.carloAcutis) }
                    // `switchTo`, not a bare `selectedTab`: the card is
                    // reachable from a Me page that has pushed Settings,
                    // and a tab set under a pushed screen only shows up
                    // later, when the reader taps Back for something else.
                    indexRow("ph-flame", "Sacred Record") { router.switchTo(.progress) }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
    }

    private func diptychLeaf(
        _ icon: String,
        _ title: String,
        _ subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AppIcon(icon, size: 20)
                    .foregroundColor(AppColors.gold)

                Text(title)
                    .font(AppFonts.headlineFont(14))
                    .foregroundColor(AppColors.cream)

                Text(subtitle.uppercased())
                    .font(AppFonts.labelFont(8))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private func indexRow(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                AppIcon(icon, size: 14)
                    .foregroundColor(AppColors.gold.opacity(0.85))
                    .frame(width: 17)

                Text(title)
                    .font(AppFonts.bodyFont(13))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Consecration

/// The user's place on the 33-day path — or the standing invitation to
/// begin it. Both lead to the Consecrate tab. Carries the page's one
/// votive wash, so the card glows a shade warmer than its neighbors.
struct ConsecrationCard: View {

    @Environment(AppRouter.self) private var router

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    private var active: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    private var completed: ConsecrationProgress? {
        consecrations.first { $0.isCompleted }
    }

    var body: some View {
        MeSection(title: "Consecration", icon: "ph-crown", washed: true) {
            VStack(alignment: .leading, spacing: 12) {
                if let active {
                    activeContent(active)
                } else if let completed {
                    completedContent(completed)
                } else {
                    invitation
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func activeContent(_ progress: ConsecrationProgress) -> some View {
        if let phase = progress.currentPhase {
            Text(phase.displayName.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.gold)
        }

        Text("Day \(min(progress.currentDayNumber, 33)) of 33")
            .font(AppFonts.headlineFont(18))
            .foregroundColor(AppColors.cream)

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.background.opacity(0.6))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold, AppColors.goldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geo.size.width * progress.progressPercentage))
            }
        }
        .frame(height: 5)

        QuietGoldButton(
            title: "Continue",
            trailingIcon: "ph-caret-right",
            size: 10,
            color: AppColors.gold,
            horizontalPadding: 0
        ) {
            router.selectedTab = .consecration
        }
        .padding(.vertical, -10)
    }

    @ViewBuilder
    private func completedContent(_ progress: ConsecrationProgress) -> some View {
        HStack(spacing: 10) {
            AppIcon("ph-seal-check-fill", size: 18)
                .foregroundColor(AppColors.gold)

            Text("Consecrated")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.cream)
        }

        if let date = progress.completedAt {
            Text(date.formatted(date: .long, time: .omitted))
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
        }

        QuietGoldButton(
            title: "Revisit",
            trailingIcon: "ph-caret-right",
            size: 10,
            color: AppColors.gold,
            horizontalPadding: 0
        ) {
            router.selectedTab = .consecration
        }
        .padding(.vertical, -10)
    }

    @ViewBuilder
    private var invitation: some View {
        Text("Total Consecration")
            .font(AppFonts.headlineFont(18))
            .foregroundColor(AppColors.cream)

        Text("A 33-day preparation to give yourself to Jesus through Mary.")
            .font(AppFonts.italicFont(13))
            .foregroundColor(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

        QuietGoldButton(
            title: "Begin",
            trailingIcon: "ph-caret-right",
            size: 10,
            color: AppColors.gold,
            horizontalPadding: 0
        ) {
            router.selectedTab = .consecration
        }
        .padding(.vertical, -10)
    }
}

// MARK: - Reflections

/// The two most recent journal entries, set as quoted lines — a thin
/// rule in the margin instead of ledger dividers, so the card reads
/// like writing, not a list.
struct JournalCard: View {

    @Environment(AppRouter.self) private var router

    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var entries: [JournalEntry]

    var body: some View {
        MeSection(title: "Reflections", icon: "ph-note-pencil") {
            VStack(alignment: .leading, spacing: 0) {
                if entries.isEmpty {
                    Text("Your reflections will gather here after prayer.")
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(entries.prefix(2)) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Rectangle()
                                    .fill(AppColors.gold.opacity(0.35))
                                    .frame(width: 2)
                                    .padding(.vertical, 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted).uppercased())
                                        .font(AppFonts.labelFont(9))
                                        .tracking(1.5)
                                        .foregroundColor(AppColors.gold.opacity(0.7))

                                    Text(entry.text)
                                        .font(AppFonts.italicFont(14))
                                        .foregroundColor(AppColors.cream.opacity(0.9))
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    QuietGoldButton(
                        title: "Open journal",
                        trailingIcon: "ph-caret-right",
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 16
                    ) {
                        router.selectedTab = .journal
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            }
        }
    }
}
