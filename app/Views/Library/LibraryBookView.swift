//
//  LibraryBookView.swift
//  Lumen Viae
//
//  One book of the Spiritual Reading shelf (the "Ring and index" design,
//  Oct 2026): the cloth with the title, author and one gold act beside
//  it — take it up, or take it up again where you left it — the daily
//  reading goal as a ring, and one list of chapters that can be read or
//  heard, opening at the reader's place, each part's name pinned over
//  its chapters and the parts' numerals down the edge to jump between
//  them. No line describes the book: the cloth and the title say it.
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

    /// Whether the chapters before the list's first are shown. The list
    /// opens at the reader's place; asked for, or jumped to from the
    /// index, the earlier ones open where they stand.
    @State private var showsEarlier = false

    /// Where the list's first and last rows stand on the page, so the
    /// part index on the edge rides beside the list and nowhere else.
    @State private var listTop: CGFloat = 10_000
    @State private var listEnd: CGFloat = .greatestFiniteMagnitude

    /// The contents, partitioned once when the book arrives. Held rather
    /// than derived: partitioning a hundred and fourteen chapters on
    /// every pass of the body is work done for nothing.
    @State private var runs: [LibraryPartRun] = []

    /// Whether any chapter's heading carries a numeral, so the rows keep
    /// one column for them. Found once, with the runs.
    @State private var numbersChapters = false

    /// Set as this page pushes a chapter, so a double tap cannot stack
    /// two readers on top of each other.
    @State private var isOpeningChapter = false

    @State private var query = ""
    @FocusState private var searchFocused: Bool
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
                    .presentationDetents([.height(460)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .goal:
                ReadingGoalSheet()
                    .presentationDetents([.height(450)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)

            case .notes:
                BookNotesSheet(notes: notes)
                    .presentationDetents([.height(520), .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(AppColors.background)
                    .dynamicTypeSize(...DynamicTypeSize.appMaximum)
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
        // exactly the case on a return visit. Opening the list off a marker
        // that had not been read yet is what used to open the Imitation on
        // the First Book for a reader in the Fourth.
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

    /// Whether the book prints parts — the Imitation's four Books — and so
    /// pins their names over the list and stands their index on the edge.
    private var hasParts: Bool { runs.count > 1 }

    @ViewBuilder
    private func content(_ info: LibraryBookInfo) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // One lazy stack for the whole page, footer included. A lazy
                // stack nested inside an eager one reports a height that
                // grows as its rows materialize, and everything below it
                // drifts while the reader scrolls.
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    header(info)
                        .devotionalEntrance()

                    if let book {
                        DailyReadingGoalCard(
                            line: meter.progressLine(for: settings.readingGoal),
                            figure: meter.ringFigure(for: settings.readingGoal),
                            fraction: meter.fraction(toward: settings.readingGoal),
                            action: { sheet = .goal }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 22)
                        .devotionalEntrance(delay: 0.05)

                        contents(book)
                            .devotionalEntrance(delay: 0.1)

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
            .coordinateSpace(name: Self.pageSpace)
            // Held under the bar: a part's name pins at the scroll's top
            // edge, and the chapters it pushed up would otherwise go on
            // showing above it, behind the Back capsule.
            .clipped()
            .overlay(alignment: .topTrailing) {
                if hasParts, !isSearching, book != nil {
                    partIndex(proxy)
                        // Level with the list's first row, under its part's
                        // name, then held under the name pinned at the top
                        // of the glass while the list passes
                        .offset(y: max(listTop, 0) + Self.partHeaderHeight)
                        // Only beside the list: above it the goal card's
                        // ADJUST stands at the edge, below it the offline
                        // row's act.
                        .opacity(listEnd > 260 ? 1 : 0)
                        .animation(.easeOut(duration: 0.2), value: listEnd > 260)
                }
            }
        }
    }

    private static let pageSpace = "libraryBookPage"

    /// About the height of a pinned part name, which the index starts
    /// beneath so the two never cross
    private static let partHeaderHeight: CGFloat = 44

    /// The head of the page: the book's cloth, and beside it the title,
    /// the author and the one gold act. Nothing describes the book here;
    /// the cloth and the title already say what it is.
    private func header(_ info: LibraryBookInfo) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            // The shelf's own cloth, drawn at the size its lettering is set
            // for and then shrunk whole: laid out at 78 points, the title
            // could only shrink to "THE I…".
            BookCover(info: info, hasRibbon: hasReadingUnderWay)
                .frame(width: 136, height: 136 / 0.7)
                .scaleEffect(Self.coverWidth / 136)
                .frame(width: Self.coverWidth, height: Self.coverWidth / 0.7)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(info.title)
                        .font(AppFonts.titleFont(20))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text(info.author)
                        .font(AppFonts.italicFont(15))
                        .foregroundColor(AppColors.textSecondary)
                }

                if let book {
                    primaryAct(book)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 22)
    }

    private static let coverWidth: CGFloat = 78

    private var hasReadingUnderWay: Bool {
        guard let progress else { return false }
        return LibraryProgressStore.isCurrent(progress) || progress.hasResumableTrack
    }

    // MARK: - The one gold act

    /// The screen's primary act, and the only filled gold shape on it:
    /// open the book at the exact chapter the marker holds, named short —
    /// "Continue · III.V" — since the list below lights the same chapter
    /// in full.
    @ViewBuilder
    private func primaryAct(_ book: LibraryBook) -> some View {
        let resume = resumeChapter(book)

        if let opening = resume ?? book.chapters.first {
            GoldCTAButton(
                title: resume == nil
                    ? "Begin reading"
                    : "Continue · \(LibraryBookPlace.shortName(of: opening, in: runs))",
                prominence: .inline,
                trailingIcon: "ph-caret-right",
                fullWidth: false,
                action: { openChapter(opening) }
            )
            .accessibilityHint("Opens \(destination(for: opening))")
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

    /// Where the reader left off, if the marker still belongs to this
    /// cutting of the edition and names a chapter it still has.
    private func resumeChapter(_ book: LibraryBook) -> LibraryChapter? {
        guard let progress, LibraryProgressStore.isCurrent(progress) else { return nil }
        return book.chapter(at: progress.lastChapterIndex)
    }

    // MARK: - Contents

    private var currentIndex: Int? {
        progress.flatMap { LibraryProgressStore.isCurrent($0) ? $0.lastChapterIndex : nil }
    }

    /// The chapter the list begins at, a little before the one being
    /// read, unless the reader has asked for the chapters before it.
    private var firstShown: Int? {
        showsEarlier ? nil : LibraryBookPlace.firstShown(in: runs, currentIndex: currentIndex)
    }

    /// One list for the whole book: each part's name pinned over its
    /// chapters while they pass, and the list opening at the reader's
    /// place with the chapters before it folded into one line.
    @ViewBuilder
    private func contents(_ book: LibraryBook) -> some View {
        // The head and the search field as one view: loose in the lazy
        // stack, the field was laid out afresh as the keyboard rose and
        // let go of its focus, so nothing could be typed into it.
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("CONTENTS · \(book.chapters.count) CHAPTERS")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Spacer()

                Button {
                    isSearching.toggle()
                    if isSearching {
                        // On the next pass, once the field exists
                        DispatchQueue.main.async { searchFocused = true }
                    } else {
                        query = ""
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(isSearching ? "CLOSE" : "SEARCH")
                            .font(AppFonts.labelFont(9))
                            .tracking(1.8)
                        AppIcon(isSearching ? "ph-x" : "ph-magnifying-glass", size: 13)
                    }
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSearching ? "Close the search" : "Search inside this book")
            }
            .padding(.horizontal, 20)

            if isSearching {
                searchField
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
            }
        }

        if isSearching {
            if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                searchResults(book)
                    .padding(.horizontal, 20)
            }
        } else {
            let first = firstShown
            let shown = LibraryBookPlace.runs(runs, from: first)

            if let first, let hidden = book.chapters.firstIndex(where: { $0.id == first }) {
                earlierRow(count: hidden)
            }

            // Where the list begins and ends, for the index on the edge.
            // Markers rather than the list's own frame: a modifier on the
            // ForEach would land on every section. A marker the lazy
            // stack lets go keeps its last reading, which is past the
            // glass's edge in the direction it went.
            pageMarker { listTop = $0 }

            ForEach(shown) { run in
                Section {
                    ForEach(run.chapters) { chapter in
                        LibraryChapterRow(
                            chapter: chapter,
                            isCurrent: chapter.id == currentIndex,
                            isFinished: finishedChapters.contains(chapter.id),
                            isLast: chapter.id == run.chapters.last?.id,
                            markCount: markCounts[chapter.id] ?? 0,
                            listening: listening(for: chapter),
                            reservesNumeral: numbersChapters,
                            onSelect: openChapter
                        )
                        .padding(.leading, 20)
                        // Clear of the index on the edge, where there is one
                        .padding(.trailing, hasParts ? 34 : 20)
                        .id(chapter.id)
                    }
                } header: {
                    if hasParts {
                        partHeader(run)
                    }
                }
            }

            pageMarker { listEnd = $0 }
        }
    }

    /// A line of no height that reports where it stands on the page
    private func pageMarker(_ report: @escaping (CGFloat) -> Void) -> some View {
        Color.clear
            .frame(height: 0)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.frame(in: .named(Self.pageSpace)).minY
            } action: { y in
                report(y)
            }
    }

    /// The chapters before the list's first, folded into one line —
    /// "39 earlier chapters" — that opens them where they stand.
    private func earlierRow(count: Int) -> some View {
        Button {
            showsEarlier = true
        } label: {
            HStack(spacing: 8) {
                AppIcon("ph-caret-up", size: 11)
                Text(count == 1 ? "1 earlier chapter" : "\(count) earlier chapters")
                    .font(AppFonts.italicFont(14))
                Spacer()
                Text("SHOW")
                    .font(AppFonts.labelFont(9))
                    .tracking(1.8)
            }
            .foregroundColor(AppColors.gold.opacity(0.75))
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show the \(count) earlier chapters")
    }

    /// A part's name, pinned over its chapters while they pass under it
    private func partHeader(_ run: LibraryPartRun) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text((run.title ?? "").uppercased())
                .font(AppFonts.labelFont(10.5))
                .tracking(2.2)
                .foregroundColor(AppColors.gold)

            Text(totalChapters(of: run) == 1 ? "1 chapter" : "\(totalChapters(of: run)) chapters")
                .font(AppFonts.bodyFont(13))
                .foregroundColor(AppColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle().fill(AppColors.gold.opacity(0.14)).frame(height: AppLine.hairline)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.gold.opacity(0.14)).frame(height: AppLine.hairline)
        }
        .id(Self.partAnchor(run.id))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// A part's whole count, though the list may show it cut short
    private func totalChapters(of run: LibraryPartRun) -> Int {
        runs.first { $0.id == run.id }?.chapters.count ?? run.chapters.count
    }

    private static func partAnchor(_ id: String) -> String { "part:\(id)" }

    /// The parts' numerals down the trailing edge, as Contacts stands its
    /// letters: a tap goes straight to that part. The part being read is
    /// lit.
    private func partIndex(_ proxy: ScrollViewProxy) -> some View {
        let reading = currentIndex.flatMap { index in
            runs.firstIndex { $0.chapters.contains { $0.id == index } }
        }

        return VStack(spacing: 0) {
            ForEach(Array(runs.enumerated()), id: \.element.id) { position, run in
                Button {
                    jump(to: run, proxy: proxy)
                } label: {
                    Text(LibraryBookPlace.roman(position + 1))
                        .font(AppFonts.labelFont(11))
                        .foregroundColor(position == reading ? AppColors.background : AppColors.gold.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(position == reading ? AppColors.gold : Color.clear))
                        .frame(width: 34, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel(run.title ?? "Part \(position + 1)")
                .accessibilityHint(position == reading ? "Where you are reading. Goes to this part." : "Goes to this part")
            }
        }
        .padding(.trailing, 2)
    }

    /// Goes to a part's heading, opening the folded chapters first when
    /// the part stands among them.
    private func jump(to run: LibraryPartRun, proxy: ScrollViewProxy) {
        let anchor = Self.partAnchor(run.id)
        let shown = LibraryBookPlace.runs(runs, from: firstShown)
        if !shown.contains(where: { $0.id == run.id }) {
            showsEarlier = true
            // The opened rows are laid out on the next pass; scrolling in
            // this one would aim at a heading that does not exist yet.
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(anchor, anchor: .top) }
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(anchor, anchor: .top) }
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
                .focused($searchFocused)
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
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: AppLine.hairline)
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

                Text("No line in this book has those words.")
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
                .frame(height: AppLine.hairline)

            Text("SAVE FOR OFFLINE")
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
                numbersChapters = loaded.chapters.contains {
                    LibraryBookPlace.numeral(ofHeading: $0.heading) != nil
                }
                loadFailed = false
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

    /// Opens a chapter. Latched: `router.push` appends unconditionally
    /// and a NavigationPath permits duplicates, so two taps used to stack
    /// two readers and Back landed on the same chapter again.
    private func openChapter(_ chapter: LibraryChapter) {
        guard !isOpeningChapter else { return }
        isOpeningChapter = true
        router.push(.libraryChapter(bookID: bookID, chapterIndex: chapter.id))

        // Released on a timer, not by `onAppear`. The latch is only here
        // to swallow a double-tap inside one frame, but tying its
        // release to the return trip meant that any push which did not
        // actually happen — or any return where `onAppear` did not fire,
        // which this codebase knows it cannot promise — left the act
        // dead for the rest of the page's life, with no way to revive it
        // but leaving the book entirely.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isOpeningChapter = false
        }
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
