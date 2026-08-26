//
//  LibraryBookView.swift
//  Lumen Viae
//
//  One book of the Spiritual Reading shelf, set like a title page: the
//  binding floating over its own halo of cloth-coloured light, one gold
//  act — take it up, or take it up again where you left it — the day's
//  measure, and one ledger of chapters that can be read or heard.
//
//  The title and author are said once, on the cloth. The typographic
//  imprint that used to repeat them under the cover is gone, and so is
//  the full-width wash that sat every dark element on another dark
//  element: the halo lights the cover only.
//
//  The recording itself belongs to `LibraryListeningSession`, which
//  outlives this page — walking into a chapter must not silence the
//  reading, and neither must a half-finished back-swipe.
//

import SwiftUI
import SwiftData

struct LibraryBookView: View {

    let bookID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(UserSettings.self) private var settings

    @State private var book: LibraryBook?
    @State private var loadFailed = false

    /// Why the book didn't open — a connection is one reason, an edition
    /// the parser could no longer cut is another, and blaming the wrong
    /// one sends the reader to their settings for nothing.
    @State private var failure: LibraryError = .unreachable

    @State private var sections: [LibriVoxSection] = []

    /// How this book's tracks line up with its chapters — held here as
    /// well as in the session, because the act's honest minutes are
    /// computed from it.
    @State private var alignment: LibraryTrackAlignment = .empty

    /// Whether the recording *failed* to arrive, as opposed to this book
    /// simply not having one. Told apart because they look identical
    /// otherwise, and a reader who came for the audiobook deserves to
    /// know which it is.
    @State private var tracksFailed = false

    @State private var progress: BookReadingProgress?

    /// The reader's notes on this book, fetched when the page appears —
    /// the notes row's count and the pull-up's rows.
    @State private var notes: [JournalEntry] = []

    /// Which parts stand open. Seeded once when the book arrives: the
    /// part being read, or the first.
    @State private var expandedParts: Set<String> = []
    @State private var didSeedExpansion = false

    /// The contents, partitioned once when the book arrives. Held rather
    /// than derived: partitioning a hundred and fourteen chapters on
    /// every pass of the body is work done for nothing.
    @State private var runs: [LibraryPartRun] = []

    /// Set as this page pushes a chapter, so a double tap cannot stack
    /// two readers on top of each other.
    @State private var isOpeningChapter = false

    @State private var query = ""
    @State private var isSearching = false

    /// What the page has put over itself. One at a time, carried as a
    /// value rather than booleans so a sheet can never be asked to draw
    /// before its state has landed.
    @State private var sheet: BookSheet?

    private enum BookSheet: String, Identifiable {
        case player, goal, notes
        var id: String { rawValue }
    }

    private let session = LibraryListeningSession.shared
    private let downloads = LibraryAudioDownloads.shared
    private let meter = ReadingDayMeter.shared

    private var info: LibraryBookInfo? { LibraryCatalog.book(id: bookID) }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let info {
                content(info)
            } else if loadFailed {
                // `load()` sets `.unreadable` precisely when the catalog
                // has no entry for this bookID — which is also when
                // `info` is nil, so nested under `content(info)` this
                // message could never be drawn and the reader got a
                // blank gold page with no way to understand it.
                unavailable
            }

            // The reading, kept at the foot of the page while it sounds,
            // so starting a chapter far down the ledger never shoves the
            // ledger out from under the reader's thumb.
            if session.isActive, let index = session.trackIndex,
               sections.indices.contains(index) {
                VStack {
                    Spacer()
                    LibraryMiniPlayer(
                        session: session,
                        title: sections[index].title ?? "The reading",
                        onExpand: { sheet = .player }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeOut(duration: 0.25), value: session.trackIndex)
            }
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .player:
                LibraryPlayerSheet(session: session)
                    .presentationDetents([.height(430)])
                    .presentationDragIndicator(.visible)

            case .goal:
                ReadingGoalSheet()
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)

            case .notes:
                BookNotesSheet(notes: notes)
                    .presentationDetents([.height(520), .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
        // `loadProgress` here as well as in `onAppear`: the two hooks run
        // in an order SwiftUI does not promise, and `load()` returns
        // without ever suspending when the book is already resident —
        // exactly the case on a return visit. Seeding the open part off a
        // marker that had not been read yet is what used to open the
        // Imitation on the First Book for a reader in the Fourth.
        .task {
            loadProgress()
            await load()
        }
        .onAppear {
            session.enterScreen()
            loadProgress()
            loadNotes()
            isOpeningChapter = false
        }
        .onDisappear {
            session.leaveScreen()
        }
        .onChange(of: scenePhase) { _, phase in
            // A place marker is worth a write when the app goes away; a
            // hard force-quit then costs at most a few seconds.
            if phase != .active { session.persist(force: true) }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ info: LibraryBookInfo) -> some View {
        ScrollView(showsIndicators: false) {
            // One lazy stack for the whole page, footer included. A lazy
            // stack nested inside an eager one reports a height that
            // grows as its rows materialize, and everything below it
            // drifts while the reader scrolls.
            LazyVStack(alignment: .leading, spacing: 0) {
                header(info)
                    .devotionalEntrance()

                if let book {
                    primaryAct(book)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                        .devotionalEntrance(delay: 0.05)

                    goalSection(book)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .devotionalEntrance(delay: 0.1)

                    ledgerSection(book, info)
                        .padding(.horizontal, 20)
                        .devotionalEntrance(delay: 0.15)

                    if let failure = session.failure {
                        quietNote(failure)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                    }

                    if !notes.isEmpty {
                        BookNotesRow(count: notes.count) { sheet = .notes }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    }

                    if !sections.isEmpty {
                        offlineSection(info)
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                    } else if tracksFailed {
                        recordingUnreachable(info)
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                    }

                    credit(info)
                        .padding(.horizontal, 32)
                        .padding(.top, 26)
                        .padding(.bottom, session.isActive ? 110 : 48)
                } else if loadFailed {
                    unavailable
                        .padding(.top, 40)
                } else {
                    loading
                }
            }
        }
    }

    /// The head of the page: the book itself, floating over its halo.
    /// Title and author are said once, on the cloth — nothing repeats
    /// them beneath it.
    private func header(_ info: LibraryBookInfo) -> some View {
        VStack(spacing: 0) {
            BookCover(info: info, hasRibbon: hasReadingUnderWay)
                .frame(width: 136)
                .shadow(color: .black.opacity(0.55), radius: 15, y: 7)
                // As a background the halo takes none of its 540 points
                // in layout, and it scrolls away with the cover instead
                // of clinging to the viewport.
                .background {
                    BookHalo(bindingColor: info.bindingColor)
                }
                .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.title), \(info.author). \(info.blurb)")
    }

    private var hasReadingUnderWay: Bool {
        guard let progress else { return false }
        return LibraryProgressStore.isCurrent(progress) || progress.hasResumableTrack
    }

    // MARK: - The one gold act

    /// The screen's primary act, and the only filled gold shape on it:
    /// open the book, at the exact chapter the marker holds — with how
    /// far into it the reader already is, said against the recording's
    /// own length where one exists.
    @ViewBuilder
    private func primaryAct(_ book: LibraryBook) -> some View {
        let resume = resumeChapter(book)
        let opening = resume ?? book.chapters.first

        if let opening {
            ContinueReadingAct(
                kicker: resume == nil ? "BEGIN READING" : "CONTINUE READING",
                destination: destination(for: opening),
                fraction: resume == nil ? 0 : chapterFraction(opening),
                meta: actMeta(for: opening, isResume: resume != nil),
                action: { openChapter(opening) }
            )
            .accessibilityHint(
                resume.map { "Opens \($0.displayTitle)" } ?? "Opens the first chapter"
            )
        }
    }

    /// "Chapter I · Earliest Memories" — or the heading alone where the
    /// edition prints no title.
    private func destination(for chapter: LibraryChapter) -> String {
        if let title = chapter.title, title != chapter.heading {
            return "\(chapter.heading) · \(title)"
        }
        return chapter.displayTitle
    }

    /// How far into a chapter the marker stands, by paragraph — the same
    /// proportional honesty follow-the-voice uses.
    private func chapterFraction(_ chapter: LibraryChapter) -> Double {
        guard let progress, LibraryProgressStore.isCurrent(progress),
              progress.lastChapterIndex == chapter.id,
              !chapter.paragraphs.isEmpty else { return 0 }
        return min(max(Double(progress.lastParagraphIndex) / Double(chapter.paragraphs.count), 0), 1)
    }

    /// "6 MIN IN · 18 MIN LEFT" — minutes taken from the recording's own
    /// length, the one honest clock this shelf has. Where no recording
    /// times this chapter, the meta stays quiet rather than guessing.
    private func actMeta(for chapter: LibraryChapter, isResume: Bool) -> String? {
        guard let seconds = chapterSeconds(chapter.id) else {
            return isResume ? nil : "NOT YET OPENED"
        }
        let minutes = max(Int((seconds / 60).rounded()), 1)
        guard isResume else { return "\(minutes) MIN · NOT YET OPENED" }

        let fraction = chapterFraction(chapter)
        let minutesIn = Int((fraction * Double(minutes)).rounded())
        guard minutesIn > 0 else { return "\(minutes) MIN" }
        return "\(minutesIn) MIN IN · \(max(minutes - minutesIn, 1)) MIN LEFT"
    }

    /// The recording's length for one chapter: its own tracks summed, or
    /// its share of a track that gathers several chapters into one file.
    private func chapterSeconds(_ chapter: Int) -> Double? {
        guard !alignment.isEmpty else { return nil }
        var total: Double = 0
        var found = false

        for (index, section) in sections.enumerated() {
            guard let range = alignment.chapters(forTrack: index),
                  range.contains(chapter),
                  let seconds = section.playtimeSeconds else { continue }
            total += seconds / Double(range.count)
            found = true
        }
        return found ? total : nil
    }

    /// Where the reader left off, if the marker still belongs to this
    /// cutting of the edition and names a chapter it still has.
    private func resumeChapter(_ book: LibraryBook) -> LibraryChapter? {
        guard let progress, LibraryProgressStore.isCurrent(progress) else { return nil }
        return book.chapter(at: progress.lastChapterIndex)
    }

    // MARK: - Today's goal

    /// The day's measure, and under it what the whole book still holds —
    /// both said against the recording's length, a fact about the files.
    @ViewBuilder
    private func goalSection(_ book: LibraryBook) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TodaysGoalBand(
                line: meter.goalLine(for: settings.readingGoal),
                fraction: meter.fraction(toward: settings.readingGoal),
                action: { sheet = .goal }
            )

            if let line = timeLeftLine(book) {
                Text(line)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    /// "2 h 5 m read · 7 h 26 m left in the book", from the recording's
    /// total length and the chapters read to their end. Absent where the
    /// book has no recording to time it by.
    private func timeLeftLine(_ book: LibraryBook) -> String? {
        // Only the tracks the alignment actually maps to a chapter —
        // the same tracks `chapterSeconds` can reach, so a finished book
        // really does reach zero.
        //
        // A recording usually carries more than the text does. Thérèse's
        // reading runs on through the Counsels, the Letters, the Prayers
        // and the Poems that the catalog's `stopPattern` cuts away, and
        // the Dolorous Passion's two appendices sit past its last
        // chapter. Summed into the total, those left four hours and
        // twenty minutes on the Story of a Soul that no amount of
        // reading could take off the line.
        let total = sections.enumerated().reduce(into: 0.0) { sum, pair in
            guard alignment.chapters(forTrack: pair.offset) != nil,
                  let seconds = pair.element.playtimeSeconds else { return }
            sum += seconds
        }
        guard total > 60 else { return nil }

        var done: Double = 0
        if let progress, LibraryProgressStore.isCurrent(progress) {
            for index in progress.finishedChapterIndexes {
                done += chapterSeconds(index) ?? 0
            }
            if let current = book.chapter(at: progress.lastChapterIndex),
               !progress.finishedChapterIndexes.contains(current.id),
               let seconds = chapterSeconds(current.id) {
                done += seconds * chapterFraction(current)
            }
        }

        guard done > 60 else {
            return "\(ReadingSpans.spell(total)) of reading in this book"
        }
        return "\(ReadingSpans.spell(done)) read · \(ReadingSpans.spell(max(total - done, 0))) left in the book"
    }

    // MARK: - Contents

    /// One ledger, not two: the chapter is the thing, and the voice is
    /// one of the two ways to have it. The header states the rule the
    /// rows follow.
    @ViewBuilder
    private func ledgerSection(_ book: LibraryBook, _ info: LibraryBookInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("CONTENTS · \(book.chapters.count) CHAPTERS")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Spacer()

                Button {
                    isSearching.toggle()
                    if !isSearching { query = "" }
                } label: {
                    HStack(spacing: 6) {
                        Text(isSearching ? "CLOSE" : "SEARCH")
                            .font(AppFonts.labelFont(9))
                            .tracking(1.8)
                        AppIcon(isSearching ? "ph-x" : "ph-magnifying-glass", size: 13)
                    }
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSearching ? "Close the search" : "Search inside this book")
            }
            .padding(.bottom, 4)

            if isSearching {
                searchField
                    .padding(.bottom, 6)
            } else if !sections.isEmpty {
                Text("Tap a chapter to read it. Tap its time to have it read aloud.")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.bottom, 6)
            }

            if isSearching, !query.trimmingCharacters(in: .whitespaces).isEmpty {
                searchResults(book)
            } else {
                LibraryContentsLedger(
                    runs: runs,
                    currentIndex: progress.flatMap {
                        LibraryProgressStore.isCurrent($0) ? $0.lastChapterIndex : nil
                    },
                    finished: finishedChapters,
                    markCounts: markCounts,
                    listening: listening(for:),
                    expandedParts: $expandedParts,
                    onSelect: openChapter
                )
            }
        }
    }

    /// The recording that *begins* at this chapter, if one does.
    ///
    /// Only where a track opens — not merely where one covers. Kempis's
    /// reader gathered ten chapters into a file, and putting the same
    /// control on all ten rows would claim a precision the recording does
    /// not have; putting it on the first says exactly where the voice
    /// starts.
    private func listening(for chapter: LibraryChapter) -> LibraryRowListening? {
        guard let track = alignment.track(forChapter: chapter.id),
              alignment.firstChapter(forTrack: track) == chapter.id,
              sections.indices.contains(track) else { return nil }

        let section = sections[track]
        return LibraryRowListening(
            isSounding: session.isSounding(track: track),
            isLoaded: session.isLoaded(track: track),
            isLoading: session.isLoaded(track: track) && session.isLoading,
            playtimeSeconds: section.playtimeSeconds,
            resting: session.isLoaded(track: track)
                ? nil : session.restingPosition(forTrack: section.id),
            save: downloads.state(bookID: bookID, sectionID: section.id),
            onToggle: { hearChapter(chapter, track: track) },
            onSave: { downloads.save(bookID: bookID, section: section) },
            onRemove: { downloads.remove(bookID: bookID, sectionID: section.id) }
        )
    }

    /// The chip's act: the reader opens at that chapter and the voice
    /// starts. Tapping the chip of the chapter already sounding pauses
    /// it where it stands.
    private func hearChapter(_ chapter: LibraryChapter, track: Int) {
        if session.isSounding(track: track) {
            session.pause()
            return
        }
        session.toggle(track: track)
        openChapter(chapter)
    }

    private var finishedChapters: Set<Int> {
        guard let progress, LibraryProgressStore.isCurrent(progress) else { return [] }
        return progress.finishedChapterIndexes
    }

    private var markCounts: [Int: Int] {
        guard let progress, LibraryProgressStore.isCurrent(progress) else { return [:] }
        return progress.marks.reduce(into: [:]) { counts, mark in
            counts[mark.chapter, default: 0] += 1
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            AppIcon("ph-magnifying-glass", size: 13)
                .foregroundColor(AppColors.gold.opacity(0.7))

            TextField("Find a line", text: $query)
                .font(AppFonts.bodyFont(15))
                .foregroundColor(AppColors.cream)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.gold.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func searchResults(_ book: LibraryBook) -> some View {
        let found = LibraryBookSearch.matches(in: book, query: query)

        if found.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nothing found")
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)

                Text("No line in this book carries those words.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, 22)
        } else {
            ForEach(found) { match in
                LibraryChapterRow(
                    chapter: match.chapter,
                    isFinished: finishedChapters.contains(match.chapter.id),
                    isLast: match.id == found.last?.id,
                    excerpt: match.line,
                    onSelect: openChapter
                )
            }
        }
    }

    // MARK: - Keeping it on the device

    /// The missal's honest offline line, under its own heading at the
    /// foot: how much of this recording is on the device, what it
    /// weighs, and the way to fetch the rest — the size named before it
    /// is spent, never hidden behind one button.
    @ViewBuilder
    private func offlineSection(_ info: LibraryBookInfo) -> some View {
        let tally = downloads.tally(bookID: bookID, sections: sections)

        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.15))
                .frame(height: 0.5)

            Text("KEEP IT ON THIS DEVICE")
                .font(AppFonts.labelFont(10))
                .tracking(2.2)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .padding(.top, 16)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(offlineLine(tally, total: sections.count))
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if tally.isSaving {
                    QuietGoldButton(
                        title: "Stop",
                        size: 10,
                        color: AppColors.gold.opacity(0.8),
                        horizontalPadding: 0
                    ) {
                        downloads.cancelAll(bookID: bookID, sections: sections)
                    }
                    .padding(.vertical, -10)
                } else if !tally.missing.isEmpty {
                    QuietGoldButton(
                        title: tally.savedCount == 0 ? "Save for offline" : "Save the rest",
                        leadingIcon: "ph-download-simple",
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 0
                    ) {
                        downloads.saveAll(bookID: bookID, sections: sections)
                    }
                    .padding(.vertical, -10)
                } else {
                    QuietGoldButton(
                        title: "Remove",
                        size: 10,
                        color: AppColors.textSecondary,
                        horizontalPadding: 0
                    ) {
                        downloads.removeAll(bookID: bookID, sections: sections)
                    }
                    .padding(.vertical, -10)
                }
            }
            .padding(.top, 8)
        }
    }

    private func offlineLine(_ tally: LibraryAudioDownloads.Tally, total: Int) -> String {
        if tally.savedCount == 0 {
            return "Nothing saved yet · about \(LibraryAudioDownloads.size(LibraryAudioDownloads.estimate(sections)))"
        }
        var line = "\(tally.savedCount) of \(total) readings saved · \(LibraryAudioDownloads.size(tally.savedBytes))"
        if !tally.missing.isEmpty {
            line += " · about \(LibraryAudioDownloads.size(LibraryAudioDownloads.estimate(tally.missing))) more"
        }
        return line
    }

    /// A recording the catalog promises but the network could not fetch
    /// — said out loud, because silence here is indistinguishable from a
    /// book that simply has no reading.
    private func recordingUnreachable(_ info: LibraryBookInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The recording couldn't be reached.")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)

            QuietGoldButton(
                title: "Try again",
                size: 11,
                color: AppColors.gold,
                horizontalPadding: 0
            ) {
                tracksFailed = false
                Task { await loadTracks(info) }
            }
        }
        .padding(.vertical, 6)
    }

    /// A recording that failed to load, said once and quietly under the
    /// ledger rather than left as a row that does nothing.
    private func quietNote(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - States

    /// A cold open is a real download over a throttled archive — say so,
    /// and say that it happens once.
    private var loading: some View {
        VStack(spacing: 12) {
            SwiftUI.ProgressView()
                .tint(AppColors.gold)

            Text("Fetching the text from Project Gutenberg.\nThis happens once.")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.bottom, 90)
    }

    private var unavailable: some View {
        VStack(spacing: 14) {
            Text(failure.title)
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.cream)

            Text(failure.detail)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Only offered where trying again can change the answer. A
            // text the parser couldn't cut will fail identically every
            // time, and each attempt re-downloads the whole book.
            if failure.isRetryable {
                QuietGoldButton(
                    title: "Try again",
                    size: 11,
                    color: AppColors.gold
                ) {
                    loadFailed = false
                    Task { await load() }
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 80)
    }

    private func credit(_ info: LibraryBookInfo) -> some View {
        VStack(spacing: 6) {
            Text(creditText(info))
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)

            // A book once opened reads without a signal. Said once,
            // quietly, rather than offered as a button for something
            // that is already true.
            Text("Once opened, this book reads offline.")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }

    private func creditText(_ info: LibraryBookInfo) -> String {
        var line = "Text: Project Gutenberg eBook #\(info.gutenbergID)."
        if info.librivoxID != nil {
            line += " Recording: LibriVox volunteers."
        }
        return line + " Public domain."
    }

    // MARK: - Loading

    private func load() async {
        guard let info else {
            // A route carrying an id the catalog no longer holds: say so
            // rather than spinning forever on a book that cannot arrive.
            // Not `.unreachable` — no connection will ever produce it,
            // and offering a retry would send the reader to their
            // settings for nothing.
            failure = .unreadable
            loadFailed = true
            return
        }

        if book == nil {
            do {
                let loaded = try await LibraryService.shared.book(for: info)
                book = loaded
                runs = LibraryPartRun.runs(of: loaded)
                loadFailed = false
                seedExpansion()
            } catch let error as LibraryError {
                failure = error
                loadFailed = true
                return
            } catch {
                failure = .unreachable
                loadFailed = true
                return
            }
        }

        // The recording rides behind the text and fails on its own — a
        // missing Listen ledger is an absence, not a failure of the book.
        if sections.isEmpty {
            await loadTracks(info)
        } else {
            adoptSession(info)
        }
    }

    private func loadTracks(_ info: LibraryBookInfo) async {
        guard info.librivoxID != nil else { return }
        do {
            sections = try await LibraryService.shared.trackList(for: info)
            tracksFailed = sections.isEmpty
            adoptSession(info)
        } catch {
            tracksFailed = true
        }
    }

    /// Hands the book, its tracks, and their alignment to the session
    /// that owns the player.
    private func adoptSession(_ info: LibraryBookInfo) {
        guard let book else { return }
        downloads.register(bookID: info.id, sections: sections)
        alignment = LibraryTrackMap.align(
            chapters: book.chapters,
            sections: sections,
            mapping: info.trackMapping
        )
        session.adopt(
            info: info,
            sections: sections,
            alignment: alignment,
            context: modelContext
        )
        offerCoverToLockScreen(info)
    }

    /// Draws the book's own cover once and hands it to the player, so a
    /// Thérèse recording on the Lock Screen shows her binding rather
    /// than an empty square. Cheap, and disproportionately felt.
    private func offerCoverToLockScreen(_ info: LibraryBookInfo) {
        let renderer = ImageRenderer(
            content: BookCover(info: info)
                .frame(width: 300, height: 429)
        )
        renderer.scale = 2
        guard let image = renderer.uiImage else { return }
        session.offerArtwork(image, for: info.id)
    }

    /// The part being read stands open on arrival; without a bookmark,
    /// the first. Seeded once — the reader's own opening and closing is
    /// never overridden afterward.
    private func seedExpansion() {
        guard !didSeedExpansion else { return }
        didSeedExpansion = true

        guard runs.count > 1 else { return }

        if let index = progress?.lastChapterIndex,
           let holding = runs.first(where: { $0.chapters.contains { $0.id == index } }) {
            expandedParts = [holding.id]
        } else if let first = runs.first {
            expandedParts = [first.id]
        }
    }

    /// Opens a chapter. Latched: `router.push` appends unconditionally
    /// and a NavigationPath permits duplicates, so two taps used to stack
    /// two readers and Back landed on the same chapter again.
    private func openChapter(_ chapter: LibraryChapter) {
        guard !isOpeningChapter else { return }
        isOpeningChapter = true
        router.push(.libraryChapter(bookID: bookID, chapterIndex: chapter.id))
    }

    /// The place marker, fetched directly — one small row at most.
    private func loadProgress() {
        progress = LibraryProgressStore.row(for: bookID, in: modelContext)
    }

    /// The reader's notes on this book — kept in the journal, gathered
    /// here for the notes row and its pull-up.
    private func loadNotes() {
        let id = bookID
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.bookID == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        notes = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryBookView(bookID: "imitation-of-christ")
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}
