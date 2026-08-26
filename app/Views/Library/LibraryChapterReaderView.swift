//
//  LibraryChapterReaderView.swift
//  Lumen Viae
//
//  One chapter of a Spiritual Reading book, set the way the app sets all
//  its long-form text: ReadingText's rhythm with a versal initial, at
//  the size the reader chose for this shelf.
//
//  The chrome is the reader's own — a Back capsule and a three-part
//  capsule whose buttons are named (SIZE · MARK · CONTENTS) — and it
//  withdraws when the reader scrolls into the prose, returning on the
//  first upward pull. The place rule at the head never leaves. Like the
//  missal, this is a page whose own chrome replaces the system bar.
//
//  A tap on a paragraph selects it and raises NOTE · MARK · SHARE. The
//  words are kept strictly apart: a MARK is a ribbon on a page, nothing
//  written, several per chapter; a NOTE is the passage plus the
//  reader's own words, kept in the journal — the app's one store for
//  what a reader keeps.
//
//  The editor's footnotes are set as an apparatus at the foot, and each
//  marker in the prose is a small gold superscript a tap can raise —
//  the note comes to the thumb without losing the line.
//

import SwiftUI
import SwiftData

struct LibraryChapterReaderView: View {

    let bookID: String
    let chapterIndex: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(UserSettings.self) private var settings

    @State private var book: LibraryBook?
    @State private var loadFailed = false

    /// Why the chapter didn't open — see LibraryError: only one of the
    /// two reasons is worth offering a second attempt.
    @State private var failure: LibraryError = .unreachable

    /// The chapter on screen — starts at the pushed index, then steps in
    /// place through the foot and the contents sheet.
    @State private var currentIndex: Int

    /// The row at the top of the screen. Negative ids are the chapter's
    /// furniture — `-1` the header (so a chapter opened fresh sits at its
    /// own title), `-2` the notes, `-3` the foot.
    @State private var topParagraph: Int?

    /// The last *paragraph* the reader was actually at. Kept apart from
    /// `topParagraph` because that also reports the furniture: a reader
    /// who reaches the notes at the chapter's end would otherwise have
    /// their place recorded as paragraph zero and resume at the top.
    @State private var lastParagraphSeen = 0

    /// Whether the reader has actually touched the page. Guards the
    /// place marker against SwiftUI's eager construction of destinations
    /// that are never pushed, and against the restore scroll writing
    /// itself back as a fresh position.
    @State private var hasSettled = false
    @State private var didRestore = false

    /// The paragraph the reader has selected — the NOTE · MARK · SHARE
    /// capsule stands while one is.
    @State private var selectedParagraph: Int?

    /// The ribbons laid in this book, refreshed on every toggle.
    @State private var marks: [BookPassageMark] = []

    /// This edition's footnote marker, compiled once when the book
    /// arrives — never per paragraph per pass.
    @State private var noteRegex: NSRegularExpression?

    /// The small engraved confirmation above the foot.
    @State private var toast: String?

    // Chrome withdrawal. The offset is measured on the whole content
    // column in global coordinates — the missal learned that a marker
    // inside the LazyVStack gets released mid-scroll and goes stale.
    @State private var chromeHidden = false
    @State private var lastScrollOffset: CGFloat?
    @State private var contentTopAnchor: CGFloat?
    @State private var scrollDownRun: CGFloat = 0
    @State private var scrollUpRun: CGFloat = 0

    /// What the reader has put over the page. One at a time, and carried
    /// as a value rather than booleans: a `.sheet(isPresented:)` whose
    /// content is built from *separate* state can be asked to draw
    /// before that state has landed, and hands back an empty white sheet.
    @State private var sheet: ReaderSheet?
    @State private var journalDraft = ""

    /// What the reader may put over the page, and what it needs to draw.
    private enum ReaderSheet: Identifiable {
        /// Carries the book, so the case cannot be set before there is
        /// something to draw — the button used to be live while the text
        /// was still fetching and opened an empty sheet.
        case contents(book: LibraryBook, info: LibraryBookInfo)
        case textOptions
        /// The paragraph selected, carried with the case so it can
        /// never be missing when the sheet is built
        case keep(passage: String)
        /// The recording's own transport, the same one the book page
        /// raises — one player, reached from wherever the reader is
        case player
        /// One of the editor's notes, raised from its marker
        case footnote(number: Int, text: String)
        /// The passage as a small setting, on its way out of the app
        case share(passage: String)

        var id: String {
            switch self {
            case .contents: return "contents"
            case .textOptions: return "text"
            case .keep: return "keep"
            case .player: return "player"
            case .footnote: return "footnote"
            case .share: return "share"
            }
        }
    }

    @State private var sections: [LibriVoxSection] = []
    @State private var alignment: LibraryTrackAlignment = .empty

    /// Keeps the page in step with the voice, and stands aside for a few
    /// seconds whenever the reader's own hand moves it. Shared with the
    /// prayer flow's reader, which solved this first.
    @State private var follow = ReaderScrollModel()

    /// The paragraph follow-along last moved the page to, so its own
    /// movement is never mistaken for the reader's hand.
    @State private var followTarget: Int?

    private let session = LibraryListeningSession.shared
    private let meter = ReadingDayMeter.shared

    init(bookID: String, chapterIndex: Int) {
        self.bookID = bookID
        self.chapterIndex = chapterIndex
        self._currentIndex = State(initialValue: chapterIndex)
    }

    private var info: LibraryBookInfo? { LibraryCatalog.book(id: bookID) }
    private var chapter: LibraryChapter? { book?.chapter(at: currentIndex) }
    private var size: CGFloat { settings.readingFontSize }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let chapter {
                reader(chapter)
            } else if loadFailed {
                unavailable
            } else {
                SwiftUI.ProgressView()
                    .tint(AppColors.gold)

                // The reader's Back lives in `chrome`, inside
                // `reader(chapter)`. While the text is still being
                // fetched there is no chrome, and this page hides the
                // system bar and its back-swipe with it — so without
                // this a stalled Gutenberg fetch is a screen the reader
                // cannot leave until the request times out.
                VStack {
                    HStack {
                        ReaderBackCapsule { dismiss() }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }

            // The recording, from inside the text. Only while this book's
            // voice is the one sounding.
            if session.isActive, let index = session.trackIndex,
               sections.indices.contains(index), info?.id == session.info?.id {
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
        // The floating capsule over a selected paragraph — 76 points
        // above the foot, standing clear of the mini player when the
        // voice is sounding.
        .overlay(alignment: .bottom) {
            if let selected = selectedParagraph, let chapter,
               chapter.paragraphs.indices.contains(selected) {
                PassageActionBar(
                    isMarked: isMarked(selected),
                    onNote: {
                        journalDraft = ""
                        sheet = .keep(passage: chapter.paragraphs[selected])
                    },
                    onMark: { toggleMark(at: selected) },
                    onShare: { sheet = .share(passage: chapter.paragraphs[selected]) }
                )
                .padding(.bottom, session.isActive ? 142 : 76)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: selectedParagraph)
        .readerToast($toast)
        // The reader's chrome is its own — like the missal, this page
        // hides the system bar deliberately.
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await load()
            restorePlace()
            refreshFinished()
            refreshMarks()
        }
        .onAppear {
            session.enterScreen()
            meter.enterReader()
        }
        .onDisappear {
            session.leaveScreen()
            meter.leaveReader()
            recordPlace(force: true)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else {
                // Back in front of the reader: the day's clock was
                // stopped on the way out, so it has to be re-armed.
                meter.resume()
                return
            }
            recordPlace(force: true)
            session.persist(force: true)
            // Stops the clock as well as committing it — a phone in a
            // pocket with a chapter open is not reading.
            meter.pause()
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .contents(let book, let info):
                LibraryContentsSheet(
                    info: info,
                    book: book,
                    currentIndex: currentIndex,
                    finished: finishedChapters,
                    marks: marks,
                    onSelect: { go(to: $0) },
                    onSelectMark: { chapter, paragraph in
                        returnToMark(chapter: chapter, paragraph: paragraph)
                    }
                )

            case .textOptions:
                LibraryTextOptionsSheet()
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)

            case .player:
                LibraryPlayerSheet(session: session)
                    .presentationDetents([.height(430)])
                    .presentationDragIndicator(.visible)

            case .keep(let passage):
                LibraryKeepSheet(
                    passage: passage,
                    citation: citation,
                    draft: $journalDraft,
                    onCopied: { toast = "Copied" },
                    onKeep: {
                        keepAsReflection(passage)
                        toast = "Saved to your journal"
                        selectedParagraph = nil
                    }
                )
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)

            case .footnote(let number, let text):
                LibraryFootnoteSheet(number: number, text: text)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)

            case .share(let passage):
                PassageShareSheet(
                    passage: passage,
                    citeLine: shareCiteLine,
                    citation: citation,
                    onCopied: { toast = "Copied" }
                )
                .presentationDetents([.height(560), .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Reader

    private func reader(_ chapter: LibraryChapter) -> some View {
        VStack(spacing: 0) {
            placeRule

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    // One flat lazy stack, foot included. A lazy stack
                    // nested in an eager one reports a height that grows
                    // as its rows materialize, and everything below it
                    // drifts as the reader scrolls.
                    LazyVStack(alignment: .leading, spacing: 0) {
                        chapterHeader(chapter)
                            .padding(.bottom, 24)
                            .id(-1)

                        paragraphs(of: chapter)

                        if !chapter.notes.isEmpty {
                            apparatus(chapter)
                                .id(-2)
                        }

                        footNavigation
                            .padding(.top, 36)
                            .padding(.bottom, session.isActive ? 96 : 48)
                            .id(-3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .scrollTargetLayout()
                    // The whole content column, in global coordinates —
                    // its travel is the scroll, and it cannot go stale
                    // the way a marker released by the lazy stack does.
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).minY
                    } action: { offset in
                        handleScroll(offset)
                    }
                }
                .scrollPosition(id: $topParagraph, anchor: .top)
                // Outside the lazy content on purpose. As the last child
                // of the LazyVStack this zero-size watcher was only
                // realized once the reader had scrolled to the foot of
                // the chapter — so follow-the-voice never started, and
                // the one step it did take scrolled it back out of the
                // viewport and derealized it. The prayer reader mounts
                // its equivalent in an overlay for the same reason.
                .overlay(alignment: .top) {
                    LibraryFollowWatcher(
                        session: session,
                        follow: follow,
                        chapterIndex: currentIndex,
                        paragraphCount: chapter.paragraphs.count,
                        isEnabled: settings.readerAutoScroll,
                        move: { target in
                            followTarget = target
                            topParagraph = target
                        }
                    )
                }
                .environment(\.openURL, OpenURLAction { url in
                    guard url.scheme == "lumen-note" else { return .systemAction }
                    if let host = url.host(), let number = Int(host) {
                        openFootnote(number)
                    }
                    return .handled
                })

                chrome
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .offset(y: chromeHidden ? -58 : 0)
                    .opacity(chromeHidden ? 0 : 1)
                    .allowsHitTesting(!chromeHidden)
            }
        }
        .onChange(of: topParagraph) { _, paragraph in
            // The first reports come from the restore, not the reader's
            // hand. Only once the page has settled does a scroll mean
            // "this is my place now".
            guard hasSettled else { return }

            if let paragraph {
                if paragraph >= 0 {
                    lastParagraphSeen = paragraph
                } else if paragraph == -1 {
                    lastParagraphSeen = 0
                }
                // -2 and -3 are the foot: the reader is past the last
                // paragraph, so the last one seen is still their place.
            }
            // A move the reader made themselves quiets follow-along for a
            // few seconds — otherwise reading ahead of the voice is
            // undone a second later.
            if paragraph != followTarget { follow.noteManualMove() }
            recordPlace()
        }
        .onChange(of: currentIndex) { _, _ in
            hasSettled = false
            follow.reset()
            followTarget = nil
            selectedParagraph = nil
            lastParagraphSeen = 0
            topParagraph = -1
            setChrome(hidden: false)
            recordPlace(force: true)
            // A chapter stepped into in place is a chapter arrived at.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { hasSettled = true }
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack(alignment: .top) {
            ReaderBackCapsule { dismiss() }

            Spacer()

            ReaderChromeCapsule(buttons: [
                ReaderCapsuleButton(id: "size", icon: "ph-text-aa", label: "SIZE") {
                    sheet = .textOptions
                },
                ReaderCapsuleButton(id: "mark", icon: nil, label: markButtonLabel) {
                    markCurrentParagraph()
                },
                ReaderCapsuleButton(id: "contents", icon: "ph-list", label: "CONTENTS") {
                    guard let book, let info else { return }
                    sheet = .contents(book: book, info: info)
                }
            ])
        }
    }

    /// "MARK · 2" once this chapter holds ribbons, "MARK" before.
    private var markButtonLabel: String {
        let count = marks.filter { $0.chapter == currentIndex }.count
        return count > 0 ? "MARK · \(count)" : "MARK"
    }

    /// Withdraws or returns the chrome. The place rule stays either way.
    private func setChrome(hidden: Bool) {
        guard chromeHidden != hidden else { return }
        withAnimation(.easeOut(duration: 0.32)) {
            chromeHidden = hidden
        }
        scrollDownRun = 0
        scrollUpRun = 0
    }

    /// Reads the content column's travel: a sustained run downward
    /// withdraws the chrome, the first real pull upward returns it, and
    /// near the head of the chapter it always stands.
    private func handleScroll(_ offset: CGFloat) {
        guard let last = lastScrollOffset else {
            lastScrollOffset = offset
            contentTopAnchor = offset
            return
        }
        let delta = offset - last
        lastScrollOffset = offset

        if let anchor = contentTopAnchor {
            // A chapter step resets the scroll to its head; adopt the
            // higher anchor so the rule below still means "near the top".
            if offset > anchor { contentTopAnchor = offset }
            if offset > anchor - 60 {
                setChrome(hidden: false)
                return
            }
        }

        if delta < -2 {
            scrollDownRun += -delta
            scrollUpRun = 0
            if scrollDownRun > 48 { setChrome(hidden: true) }
        } else if delta > 2 {
            scrollUpRun += delta
            scrollDownRun = 0
            if scrollUpRun > 16 { setChrome(hidden: false) }
        }
    }

    /// Where you are in the book, as position rather than arithmetic —
    /// the missal's own hairline. No percentage: a rule says where, a
    /// number says what you still owe.
    @ViewBuilder
    private var placeRule: some View {
        if let book, book.chapters.count > 1 {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.1))

                    Rectangle()
                        .fill(AppColors.gold.opacity(0.55))
                        .frame(
                            width: geometry.size.width
                                * (Double(currentIndex + 1) / Double(book.chapters.count))
                        )
                }
            }
            .frame(height: 1)
            .accessibilityHidden(true)
        }
    }

    private func chapterHeader(_ chapter: LibraryChapter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(kicker(for: chapter).uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)

                Spacer(minLength: 8)

                if let book, book.chapters.count > 1 {
                    Text("\(currentIndex + 1) OF \(book.chapters.count)")
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Text(chapter.displayTitle)
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)

            OrnamentDivider(showsCross: false)
                .frame(width: 140)
                .padding(.top, 8)

            hearThisRead
        }
        .padding(.top, 12)
    }

    /// "Chapter II" under a part, or the book's own name where the
    /// heading already owns the title line.
    private func kicker(for chapter: LibraryChapter) -> String {
        if let part = chapter.part {
            return "\(part) · \(chapter.heading)"
        }
        if chapter.title != nil, chapter.title != chapter.heading {
            return chapter.heading
        }
        return info?.title ?? chapter.heading
    }

    // MARK: - Hear this read

    /// The seam from the text to the voice, with what the recording
    /// still holds said at the right. Present only where a recording
    /// actually reads this chapter, and honest about what it can do:
    /// where one track holds ten chapters, it says so rather than
    /// dropping the reader eight chapters early without a word.
    @ViewBuilder
    private var hearThisRead: some View {
        if let info, let track = alignment.track(forChapter: currentIndex),
           sections.indices.contains(track) {
            let whole = alignment.readsWholeChapter(track: track)
            let opening = alignment.firstChapter(forTrack: track)
            let sounding = session.isSounding(track: track) && session.info?.id == info.id

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button {
                    if sounding {
                        session.pause()
                    } else {
                        prepareSession(info)
                        session.toggle(track: track)
                    }
                } label: {
                    HStack(spacing: 7) {
                        AppIcon(sounding ? "ph-pause-fill" : "ph-speaker-high", size: 13)

                        Text(sounding ? "PAUSE THE READING" : "HEAR THIS READ")
                            .font(AppFonts.labelFont(10))
                            .tracking(1.5)

                        if !whole, !sounding, let opening, let from = book?.chapter(at: opening) {
                            Text("· from \(from.heading)")
                                .font(AppFonts.italicFont(11))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .foregroundColor(AppColors.gold)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    sounding ? "Pause the reading"
                             : (whole ? "Hear this chapter read"
                                      : "Hear this read, from the start of this recording")
                )

                Spacer(minLength: 8)

                if let label = minutesLeftLabel(track: track) {
                    Text(label)
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, 4)
        }
    }

    /// "18 MIN LEFT" — what the file still holds while it sounds, or its
    /// whole length before it starts. A fact about the recording, never
    /// a prediction about the reader.
    private func minutesLeftLabel(track: Int) -> String? {
        if session.isLoaded(track: track), session.duration > 0 {
            let left = max(session.duration - session.currentTime, 0)
            return "\(ReadingSpans.chipMinutes(left)) LEFT"
        }
        guard let seconds = sections[track].playtimeSeconds else { return nil }
        return ReadingSpans.chipMinutes(seconds)
    }

    // MARK: - Body

    /// Paragraphs straight from the parser: a chapter of the Confessions
    /// runs past eighty thousand characters, and joining it into one
    /// string only for ReadingText to split it again would redo that work
    /// on every pass.
    @ViewBuilder
    private func paragraphs(of chapter: LibraryChapter) -> some View {
        ForEach(Array(chapter.paragraphs.enumerated()), id: \.offset) { index, paragraph in
            ReaderProseParagraph(
                text: paragraph,
                isFirst: index == 0,
                size: size,
                noteRegex: noteRegex,
                isSelected: selectedParagraph == index,
                isMarked: isMarked(index),
                isFollowed: followTarget == index && selectedParagraph != index
                    && session.canFollowText(chapterIndex: currentIndex),
                onTap: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedParagraph = selectedParagraph == index ? nil : index
                    }
                }
            )
            .padding(.bottom, ReadingTypography.paragraphSpacing(for: size))
            .id(index)
        }
    }

    /// The editor's notes, set small and apart under an ornament — the
    /// apparatus of a printed book, in the missal's citation voice.
    private func apparatus(_ chapter: LibraryChapter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OrnamentDivider(showsCross: false)
                .frame(width: 120)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Text("NOTES")
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.6))
                .padding(.bottom, 4)

            ForEach(Array(chapter.notes.enumerated()), id: \.offset) { _, note in
                Text(note)
                    .font(AppFonts.bodyFont(max(size - 4, 12)))
                    .foregroundColor(AppColors.gold.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Foot

    /// The way on: previous and next chapter, stepped in place.
    @ViewBuilder
    private var footNavigation: some View {
        if let book {
            HStack {
                if currentIndex > 0, let previous = book.chapter(at: currentIndex - 1) {
                    footButton(label: previous.heading, icon: "ph-caret-left", iconLeads: true) {
                        go(to: currentIndex - 1)
                    }
                }

                Spacer()

                if let next = book.chapter(at: currentIndex + 1) {
                    footButton(label: next.heading, icon: "ph-caret-right", iconLeads: false) {
                        // Stepping on is how a reader says they finished
                        // this one. Additive; nothing is ever un-finished.
                        complete(currentIndex)
                        go(to: currentIndex + 1)
                    }
                }
            }
            // Reaching the foot is the other way a chapter is finished,
            // and the only one the last chapter of a book has — there is
            // no next to step on to. Guarded by `hasSettled` so a
            // chapter stepped into does not complete itself on the frame
            // it lays out, while the scroll is still deep in the old one.
            .onAppear {
                guard hasSettled else { return }
                complete(currentIndex)
            }
        }
    }

    /// Marks a chapter read, counting it toward the day's measure only
    /// the first time. `markFinished` is itself idempotent, but the
    /// day's chapter count is not, so the guard has to sit here.
    private func complete(_ index: Int) {
        guard !finishedChapters.contains(index) else { return }
        LibraryProgressStore.markFinished(
            bookID: bookID, chapterIndex: index, in: modelContext
        )
        meter.noteChapterFinished()
        refreshFinished()
    }

    private func footButton(
        label: String,
        icon: String,
        iconLeads: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if iconLeads { AppIcon(icon, size: 11) }
                Text(label.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(1.5)
                if !iconLeads { AppIcon(icon, size: 11) }
            }
            .foregroundColor(AppColors.gold)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - States

    private var unavailable: some View {
        VStack(spacing: 12) {
            Text(failure.title)
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.cream)

            Text(failure.detail)
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if failure.isRetryable {
                QuietGoldButton(title: "Try again", size: 11, color: AppColors.gold) {
                    loadFailed = false
                    Task {
                        await load()
                        restorePlace()
                    }
                }
                .padding(.top, 4)
            }

            ReaderBackCapsule { dismiss() }
                .padding(.top, 12)
        }
    }

    // MARK: - Loading

    private func load() async {
        guard let info else {
            // A route carrying an id the catalog no longer holds: say so
            // rather than spinning on a book that cannot arrive.
            failure = .unreadable
            loadFailed = true
            return
        }

        if noteRegex == nil, let pattern = info.parsing.notePattern {
            noteRegex = try? NSRegularExpression(pattern: pattern)
        }

        guard book == nil else { return }
        do {
            let loaded = try await LibraryService.shared.book(for: info)
            // A stale place marker, or a route restored after a reparse
            // cut the book differently, can name a chapter this edition
            // no longer has. Clamp into range rather than leave the page
            // with no chapter, no error, and a spinner that never ends.
            if loaded.chapter(at: currentIndex) == nil, !loaded.chapters.isEmpty {
                currentIndex = min(max(currentIndex, 0), loaded.chapters.count - 1)
            }
            book = loaded
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

        // The recording rides behind the text and fails silently here —
        // the reader came for the words.
        if info.librivoxID != nil, sections.isEmpty {
            sections = (try? await LibraryService.shared.trackList(for: info)) ?? []
            if let book {
                alignment = LibraryTrackMap.align(
                    chapters: book.chapters,
                    sections: sections,
                    mapping: info.trackMapping
                )
            }
        }
    }

    private func prepareSession(_ info: LibraryBookInfo) {
        session.adopt(
            info: info,
            sections: sections,
            alignment: alignment,
            context: modelContext
        )
    }

    // MARK: - Marks

    private func isMarked(_ paragraph: Int) -> Bool {
        marks.contains(BookPassageMark(chapter: currentIndex, paragraph: paragraph))
    }

    private func refreshMarks() {
        marks = LibraryProgressStore.marks(for: bookID, in: modelContext)
    }

    /// The chrome's MARK: the paragraph the reader selected, or failing
    /// that the one being read — tracked from the scroll position.
    private func markCurrentParagraph() {
        guard let chapter else { return }
        let paragraph = selectedParagraph
            ?? ((topParagraph ?? -1) >= 0 ? topParagraph! : lastParagraphSeen)
        guard chapter.paragraphs.indices.contains(paragraph) else { return }
        toggleMark(at: paragraph)
    }

    private func toggleMark(at paragraph: Int) {
        let nowMarked = LibraryProgressStore.toggleMark(
            bookID: bookID,
            chapter: currentIndex,
            paragraph: paragraph,
            in: modelContext
        )
        refreshMarks()
        toast = nowMarked ? "Marked" : "Mark removed"
        if selectedParagraph == paragraph {
            withAnimation(.easeOut(duration: 0.2)) { selectedParagraph = nil }
        }
    }

    /// Back to a marked paragraph, from the contents sheet — stepping
    /// the chapter first where the ribbon lies in another one.
    private func returnToMark(chapter chapterTarget: Int, paragraph: Int) {
        if chapterTarget == currentIndex {
            withAnimation(.easeInOut(duration: 0.5)) { topParagraph = paragraph }
            lastParagraphSeen = paragraph
            return
        }
        go(to: chapterTarget)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            topParagraph = paragraph
            lastParagraphSeen = paragraph
        }
    }

    // MARK: - Footnotes

    /// The marker's own note: the one that opens with the same number,
    /// or its position in the apparatus where the numbering restarts.
    private func openFootnote(_ number: Int) {
        guard let chapter, !chapter.notes.isEmpty else { return }

        let found = chapter.notes.first { note in
            let trimmed = note.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("[\(number)]") || trimmed.hasPrefix("(\(number))")
        } ?? (chapter.notes.indices.contains(number - 1) ? chapter.notes[number - 1] : nil)

        guard let found else { return }
        sheet = .footnote(number: number, text: found)
    }

    // MARK: - The place

    /// Held rather than fetched: read from the sheet's content builder,
    /// the computed form ran a SwiftData round trip on the render path.
    @State private var finishedChapters: Set<Int> = []

    private func refreshFinished() {
        guard let row = LibraryProgressStore.row(for: bookID, in: modelContext),
              LibraryProgressStore.isCurrent(row) else {
            finishedChapters = []
            return
        }
        finishedChapters = row.finishedChapterIndexes
    }

    /// Puts the page back at the paragraph the eye left, once. A chapter
    /// of the Confessions is eighty-six thousand characters; without
    /// this, "continue reading" means "scroll for a minute".
    private func restorePlace() {
        guard book != nil, !didRestore else { return }
        didRestore = true

        var paragraph = 0
        if let row = LibraryProgressStore.row(for: bookID, in: modelContext),
           LibraryProgressStore.isCurrent(row),
           row.lastChapterIndex == currentIndex {
            paragraph = row.lastParagraphIndex
        }

        lastParagraphSeen = paragraph
        topParagraph = paragraph > 0 ? paragraph : -1

        // Arriving *is* reading; the paragraph only becomes the reader's
        // own once the restore scroll has landed and settled.
        recordPlace(force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { hasSettled = true }
    }

    /// Records where the eye is. Never from view construction — SwiftUI
    /// builds destinations eagerly for routes that are never pushed.
    private func recordPlace(force: Bool = false) {
        guard book != nil else { return }
        guard force || hasSettled else { return }

        LibraryProgressStore.recordReading(
            bookID: bookID,
            chapterIndex: currentIndex,
            chapterTitle: chapter?.heading ?? "",
            paragraphIndex: lastParagraphSeen,
            in: modelContext
        )
    }

    private func go(to index: Int) {
        guard let book, book.chapter(at: index) != nil, index != currentIndex else { return }
        currentIndex = index
    }

    // MARK: - Keeping a passage

    /// The citation a kept or copied passage carries. Public domain
    /// still deserves attribution, and the translator is a voice.
    private var citation: String {
        guard let info, let chapter else { return "" }
        var line = "— \(info.author), \(info.title)"
        if let part = chapter.part {
            line += ", \(part), \(chapter.heading)"
        } else {
            line += ", \(chapter.heading)"
        }
        if let translator = info.translator {
            line += " (trans. \(translator))"
        }
        return line + ". Project Gutenberg."
    }

    /// "St. Thérèse of Lisieux · Chapter I" — the share card's short cite.
    private var shareCiteLine: String {
        guard let info, let chapter else { return "" }
        return "\(info.author) · \(chapter.heading)"
    }

    /// A kept passage becomes a Reflection — the app already has one
    /// store for what a reader keeps, and it is the journal. No second
    /// highlights library, no colours, no review queue.
    private func keepAsReflection(_ passage: String) {
        guard let info else { return }

        let entry = JournalEntry.note(
            passage: passage,
            citation: citation,
            comment: journalDraft,
            subject: chapter?.displayTitle ?? info.title,
            bookID: bookID
        )
        modelContext.insert(entry)
        try? modelContext.save()

        journalDraft = ""
    }
}

// MARK: - Text options

/// How the page reads. One control, on purpose: `ReadingTypography`
/// derives its spacing from the size, EB Garamond is the app's reading
/// voice, and three sliders is a settings panel where a book wants a
/// single Aa.
struct LibraryTextOptionsSheet: View {

    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        LibraryTraySheet(
            title: "Reading size",
            note: "Applies to the books on this shelf."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Text("A")
                        .font(AppFonts.readingFont(14))
                        .foregroundColor(AppColors.textSecondary)

                    Slider(value: $settings.readingTextScale, in: 0...1)
                        .tint(AppColors.gold)

                    Text("A")
                        .font(AppFonts.readingFont(24))
                        .foregroundColor(AppColors.cream)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Reading size")

                Text("Whosoever followeth Me shall not walk in darkness.")
                    .font(AppFonts.readingFont(settings.readingFontSize))
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .lineSpacing(ReadingTypography.lineSpacing(for: settings.readingFontSize))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)

                Divider()
                    .background(AppColors.gold.opacity(0.15))

                Toggle(isOn: $settings.readerAutoScroll) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Follow the voice")
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.cream)

                        Text("The page keeps pace while a recording reads.")
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.gold)
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Note on a passage

/// A passage on its way into the journal: the words as they stand, their
/// citation, and room for the reader's own line underneath — which is
/// where spiritual reading is supposed to end up.
struct LibraryKeepSheet: View {

    let passage: String
    let citation: String
    @Binding var draft: String
    var onCopied: (() -> Void)? = nil
    let onKeep: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWriting: Bool

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("NOTE ON THIS PASSAGE")
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .padding(.top, 22)

                    Text("\u{201C}\(passage)\u{201D}")
                        .font(AppFonts.readingItalicFont(16))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .lineSpacing(ReadingTypography.lineSpacing(for: 16))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(citation)
                        .font(AppFonts.labelFont(10))
                        .tracking(1.2)
                        .foregroundColor(AppColors.gold.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)

                    OrnamentDivider(showsCross: false)
                        .frame(width: 120)
                        .padding(.vertical, 4)

                    TextField("And what it said to you…", text: $draft, axis: .vertical)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(3...10)
                        .textFieldStyle(.plain)
                        .focused($isWriting)

                    HStack(spacing: 14) {
                        QuietGoldButton(
                            title: "Copy",
                            leadingIcon: "ph-export",
                            size: 10,
                            color: AppColors.gold.opacity(0.8),
                            horizontalPadding: 0
                        ) {
                            UIPasteboard.general.string = "\u{201C}\(passage)\u{201D}\n\n\(citation)"
                            onCopied?()
                            dismiss()
                        }

                        Spacer()

                        QuietGoldButton(
                            title: "Save to the journal",
                            trailingIcon: "ph-check",
                            size: 10,
                            color: AppColors.goldLight,
                            horizontalPadding: 0
                        ) {
                            onKeep()
                            dismiss()
                        }
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryChapterReaderView(bookID: "imitation-of-christ", chapterIndex: 0)
            .environment(UserSettings.shared)
    }
}


// MARK: - Following the voice

/// Carries the page along with the recording, paragraph by paragraph.
///
/// Reads `currentTime` in its own body on purpose: observed from the
/// reader, the twice-a-second tick would make the whole chapter a
/// dependency of the clock. Here it invalidates a zero-size view and
/// writes outward only when the paragraph actually changes.
///
/// Only where the sounding track reads this whole chapter and nothing
/// else. Without per-word timings the mapping is proportional —
/// paragraph N of M at N/M of the recording — which tracks a reader's
/// pace closely enough over one chapter and would be nonsense over a
/// track holding ten of them. `LibraryTrackAlignment` is what knows the
/// difference, and it refuses the cases it cannot do honestly.
struct LibraryFollowWatcher: View {

    let session: LibraryListeningSession
    let follow: ReaderScrollModel
    let chapterIndex: Int
    let paragraphCount: Int
    let isEnabled: Bool
    let move: (Int) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: session.currentTime) { _, time in
                guard isEnabled, paragraphCount > 0,
                      session.canFollowText(chapterIndex: chapterIndex),
                      session.duration > 0 else { return }

                let fraction = min(max(time / session.duration, 0), 1)
                guard let target = follow.paragraphToFollow(
                    fraction: fraction,
                    paragraphCount: paragraphCount
                ) else { return }

                withAnimation(.easeInOut(duration: 1.0)) {
                    move(target)
                }
            }
    }
}
