//
//  LibraryBookView.swift
//  Lumen Viae
//
//  One book of the Spiritual Reading shelf, set like a title page: the
//  binding's own cloth washing down from the head, the author in
//  engraved caps, the name in Cinzel, and one gold act — take it up, or
//  take it up again where you left it.
//
//  Below that the book keeps two ledgers, because a book can be held in
//  two hands. The contents is what you read; the LISTEN ledger is what
//  you hear. They are the same book, so they speak to each other: a
//  track names the chapter it reads, a chapter can be handed to the
//  voice, and the voice remembers where it stopped.
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

    @State private var book: LibraryBook?
    @State private var loadFailed = false

    /// Why the book didn't open — a connection is one reason, an edition
    /// the parser could no longer cut is another, and blaming the wrong
    /// one sends the reader to their settings for nothing.
    @State private var failure: LibraryError = .unreachable

    @State private var sections: [LibriVoxSection] = []

    /// Whether the recording *failed* to arrive, as opposed to this book
    /// simply not having one. Told apart because they look identical
    /// otherwise, and a reader who came for the audiobook deserves to
    /// know which it is.
    @State private var tracksFailed = false

    @State private var progress: BookReadingProgress?

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

    /// What the page has put over itself. One case today; carried as a
    /// value rather than a boolean so adding a second never repeats the
    /// empty-sheet trap the reader hit.
    @State private var sheet: BookSheet?

    private enum BookSheet: String, Identifiable {
        case player
        var id: String { rawValue }
    }

    private let session = LibraryListeningSession.shared
    private let downloads = LibraryAudioDownloads.shared

    private var info: LibraryBookInfo? { LibraryCatalog.book(id: bookID) }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            // The book's own cloth, washing down from the head of the
            // page — the cover's identity carried through to its
            // contents, one binding colour per book.
            if let info {
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: info.bindingColor.opacity(0.5), location: 0),
                            .init(color: info.bindingColor.opacity(0.18), location: 0.55),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 300)

                    Spacer(minLength: 0)
                }
                .ignoresSafeArea()

                content(info)
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
                        .padding(.bottom, 20)
                        .devotionalEntrance(delay: 0.05)

                    ledgerSection(book, info)
                        .padding(.horizontal, 20)
                        .devotionalEntrance(delay: 0.1)

                    if let failure = session.failure {
                        quietNote(failure)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                    }

                    if !sections.isEmpty {
                        offlineRow(info)
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

    /// The head of the page, set as a title page rather than a record
    /// card: the book itself standing in its own cloth — the cover the
    /// reader just tapped, carried through so the page is recognizably
    /// *that* book — and under it the imprint, ruled the way a printed
    /// title page rules it.
    ///
    /// The marker ribbon on the cover is the same one the shelf and
    /// Explore hang on a book with a reading under way, so the three
    /// surfaces agree.
    private func header(_ info: LibraryBookInfo) -> some View {
        VStack(spacing: 0) {
            BookCover(info: info, hasRibbon: hasReadingUnderWay)
                .frame(width: 122)
                .padding(.top, 22)
                .padding(.bottom, 22)
                .accessibilityHidden(true)

            gilt
                .padding(.horizontal, 56)
                .padding(.bottom, 14)

            Text(info.author.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.8)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)

            Text(info.title)
                .font(AppFonts.headlineFont(27))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            if let translator = info.translator {
                Text("translated by \(translator)")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 6)
            }

            gilt
                .padding(.horizontal, 56)
                .padding(.top, 16)

            // The line that told the books apart on the shelf keeps
            // telling this one's story here.
            Text(info.blurb)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
                .padding(.top, 16)

            OrnamentDivider()
                .padding(.horizontal, 40)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(info.title), \(info.author). \(info.blurb)")
    }

    /// The pair of gilt rules a bound book carries at head and tail,
    /// fading out at the ends so they read as tooling rather than as the
    /// page's own dividers.
    private var gilt: some View {
        VStack(spacing: 3) {
            rule
            rule
        }
        .accessibilityHidden(true)
    }

    private var rule: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.gold.opacity(0), location: 0),
                .init(color: AppColors.gold.opacity(0.5), location: 0.5),
                .init(color: AppColors.gold.opacity(0), location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }

    private var hasReadingUnderWay: Bool {
        guard let progress else { return false }
        return LibraryProgressStore.isCurrent(progress) || progress.hasResumableTrack
    }

    // MARK: - The one gold act

    /// The screen's primary act, and the only filled gold shape on it:
    /// open the book. Named for what it will actually do — a reader with
    /// a marker is not beginning, they are going back.
    @ViewBuilder
    private func primaryAct(_ book: LibraryBook) -> some View {
        let resume = resumeChapter(book)

        VStack(spacing: 9) {
            GoldCTAButton(title: actTitle(resume)) {
                guard let opening = resume ?? book.chapters.first else { return }
                openChapter(opening)
            }
            .accessibilityHint(
                resume.map { "Opens \($0.displayTitle)" } ?? "Opens the first chapter"
            )
            // The marker ribbon of a book left open, hanging over the
            // act that returns to it — the same ribbon the covers wear.
            .overlay(alignment: .topTrailing) {
                if resume != nil {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(AppColors.goldLight)
                        .frame(width: 8, height: 22)
                        .offset(x: -26, y: -9)
                        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                        .accessibilityHidden(true)
                }
            }

            // Where the act leads, named under it rather than crammed
            // into the pill: a chapter's own title is often a sentence.
            if let resume, resume.title != nil, resume.title != resume.heading {
                Text(resume.displayTitle)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .accessibilityHidden(true)
            }
        }
    }

    /// "Begin reading" on a book not yet opened; on one with a place
    /// kept, the place itself — the act says where it goes.
    private func actTitle(_ resume: LibraryChapter?) -> String {
        guard let resume else { return "Begin reading" }
        return "Continue · \(resume.heading)"
    }

    /// Where the reader left off, if the marker still belongs to this
    /// cutting of the edition and names a chapter it still has.
    private func resumeChapter(_ book: LibraryBook) -> LibraryChapter? {
        guard let progress, LibraryProgressStore.isCurrent(progress) else { return nil }
        return book.chapter(at: progress.lastChapterIndex)
    }

    // MARK: - Contents

    /// One ledger, not two.
    ///
    /// The contents and the recording used to stand as separate sections,
    /// which for a book whose reader gave every chapter its own file
    /// meant printing the same thirteen names twice on one page. They are
    /// the same book: the chapter is the thing, and the voice is one of
    /// the two ways to have it. So a chapter row carries the play control
    /// where a recording begins at that chapter, and the recording has no
    /// ledger of its own.
    @ViewBuilder
    private func ledgerSection(_ book: LibraryBook, _ info: LibraryBookInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("CONTENTS")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.75))

                if info.librivoxID != nil, !sections.isEmpty {
                    AppIcon("ph-speaker-high", size: 11)
                        .foregroundColor(AppColors.gold.opacity(0.5))
                        .accessibilityHidden(true)
                }

                Spacer()

                Button {
                    isSearching.toggle()
                    if !isSearching { query = "" }
                } label: {
                    AppIcon(isSearching ? "ph-x" : "ph-magnifying-glass", size: 13)
                        .foregroundColor(AppColors.gold.opacity(0.75))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSearching ? "Close the search" : "Search inside this book")
            }
            .padding(.bottom, 4)

            if isSearching {
                searchField
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
    /// starts. A reader partway into that span still hands the chapter to
    /// the voice from inside the reader, where "Hear this read" names the
    /// span it is joining.
    private func listening(for chapter: LibraryChapter) -> LibraryRowListening? {
        guard let track = session.alignment.track(forChapter: chapter.id),
              session.alignment.firstChapter(forTrack: track) == chapter.id,
              sections.indices.contains(track) else { return nil }

        let section = sections[track]
        return LibraryRowListening(
            isSounding: session.isSounding(track: track),
            isLoaded: session.isLoaded(track: track),
            isLoading: session.isLoaded(track: track) && session.isLoading,
            playtime: section.playtimeLabel,
            resting: session.isLoaded(track: track)
                ? nil : session.restingPosition(forTrack: section.id),
            save: downloads.state(bookID: bookID, sectionID: section.id),
            onToggle: { session.toggle(track: track) },
            onSave: { downloads.save(bookID: bookID, section: section) },
            onRemove: { downloads.remove(bookID: bookID, sectionID: section.id) }
        )
    }

    private var finishedChapters: Set<Int> {
        guard let progress, LibraryProgressStore.isCurrent(progress) else { return [] }
        return progress.finishedChapterIndexes
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
                .fill(AppColors.cardBackground.opacity(0.7))
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

    /// The missal's own honest offline row, in the shelf's words: how
    /// much of this recording is on the device, what it weighs, and the
    /// way to fetch the rest — with the size named before it is spent,
    /// never hidden behind one button.
    @ViewBuilder
    private func offlineRow(_ info: LibraryBookInfo) -> some View {
        let tally = downloads.tally(bookID: bookID, sections: sections)

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
        .padding(.top, 14)
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
        session.adopt(
            info: info,
            sections: sections,
            alignment: LibraryTrackMap.align(
                chapters: book.chapters,
                sections: sections,
                mapping: info.trackMapping
            ),
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryBookView(bookID: "imitation-of-christ")
            .environment(AppRouter())
    }
}
