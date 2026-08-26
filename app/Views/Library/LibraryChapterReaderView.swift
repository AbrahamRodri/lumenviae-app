//
//  LibraryChapterReaderView.swift
//  Lumen Viae
//
//  One chapter of a Spiritual Reading book, set the way the app sets all
//  its long-form text: ReadingText with a versal initial, at the size
//  the reader chose for this shelf.
//
//  Three things a page of a book needs that a page of a meditation does
//  not, and all three are here: a way to know where you are (a hairline
//  rule at the head, and "9 of 13" beside the chapter's name), a way to
//  get somewhere else (the ☰ contents, and the foot's steppers, both in
//  place — walking a hundred-and-fourteen-chapter book must not stack a
//  hundred and fourteen screens), and a way to come back to the exact
//  paragraph you stopped at, which for a book of the Confessions is the
//  difference between resuming and starting again.
//
//  The editor's footnotes are set as an apparatus at the foot, not as
//  the author's prose. A chapter of the Story of a Soul carries
//  thirty-four citations, and they used to read as though the saint had
//  written them.
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

    /// What the reader has put over the page. One at a time, and carried
    /// as a value rather than three booleans: a `.sheet(isPresented:)`
    /// whose content is built from *separate* state can be asked to draw
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
        /// The paragraph long-pressed, carried with the case so it can
        /// never be missing when the sheet is built
        case keep(passage: String)
        /// The recording's own transport, the same one the book page
        /// raises — one player, reached from wherever the reader is
        case player

        var id: String {
            switch self {
            case .contents: return "contents"
            case .textOptions: return "text"
            case .keep: return "keep"
            case .player: return "player"
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
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbar }
        .task {
            await load()
            restorePlace()
            refreshFinished()
        }
        .onAppear { session.enterScreen() }
        .onDisappear {
            session.leaveScreen()
            recordPlace(force: true)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else { return }
            recordPlace(force: true)
            session.persist(force: true)
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .contents(let book, let info):
                LibraryContentsSheet(
                    info: info,
                    book: book,
                    currentIndex: currentIndex,
                    finished: finishedChapters,
                    onSelect: { go(to: $0) }
                )

            case .textOptions:
                LibraryTextOptionsSheet()
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)

            case .player:
                LibraryPlayerSheet(session: session)
                    .presentationDetents([.height(420)])
                    .presentationDragIndicator(.visible)

            case .keep(let passage):
                LibraryKeepSheet(
                    passage: passage,
                    citation: citation,
                    draft: $journalDraft,
                    onKeep: { keepAsReflection(passage) }
                )
            }
        }
    }

    // MARK: - Toolbar

    /// Back, and the two controls a book needs at hand: the contents,
    /// and how big the type is.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 2) {
                Button(action: { sheet = .textOptions }) {
                    AppIcon("ph-text-aa", size: 17)
                        .foregroundColor(AppColors.gold)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Reading size")

                Button {
                    guard let book, let info else { return }
                    sheet = .contents(book: book, info: info)
                } label: {
                    AppIcon("ph-list", size: 16)
                        .foregroundColor(AppColors.gold.opacity(book == nil ? 0.35 : 1))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(book == nil)
                .accessibilityLabel("Contents")
            }
        }
    }

    // MARK: - Reader

    private func reader(_ chapter: LibraryChapter) -> some View {
        VStack(spacing: 0) {
            placeRule

            ScrollView(showsIndicators: false) {
                // One flat lazy stack, foot included. A lazy stack nested
                // in an eager one reports a height that grows as its rows
                // materialize, and everything below it drifts as the
                // reader scrolls.
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
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .scrollTargetLayout()
            }
            .scrollPosition(id: $topParagraph, anchor: .top)
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
            lastParagraphSeen = 0
            topParagraph = -1
            recordPlace(force: true)
            // A chapter stepped into in place is a chapter arrived at.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { hasSettled = true }
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
                    Text("\(currentIndex + 1) of \(book.chapters.count)")
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

    /// The seam from the text to the voice. Present only where a
    /// recording actually reads this chapter, and honest about what it
    /// can do: where one track holds ten chapters, it says so rather
    /// than dropping the reader eight chapters early without a word.
    @ViewBuilder
    private var hearThisRead: some View {
        if let info, let track = alignment.track(forChapter: currentIndex),
           sections.indices.contains(track) {
            let whole = alignment.readsWholeChapter(track: track)
            let opening = alignment.firstChapter(forTrack: track)
            let sounding = session.isSounding(track: track) && session.info?.id == info.id

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
            .padding(.top, 4)
        }
    }

    // MARK: - Body

    /// Paragraphs straight from the parser: a chapter of the Confessions
    /// runs past eighty thousand characters, and joining it into one
    /// string only for ReadingText to split it again would redo that work
    /// on every pass.
    @ViewBuilder
    private func paragraphs(of chapter: LibraryChapter) -> some View {
        ForEach(Array(chapter.paragraphs.enumerated()), id: \.offset) { index, paragraph in
            Group {
                if index == 0 {
                    DropCapText(text: paragraph, bodySize: size)
                } else {
                    Text(paragraph)
                        .font(AppFonts.readingFont(size))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .lineSpacing(ReadingTypography.lineSpacing(for: size))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, ReadingTypography.paragraphSpacing(for: size))
            .id(index)
            .contentShape(Rectangle())
            // Paragraph-granular on purpose: the parser already made
            // paragraphs first-class, and a paragraph of Kempis is the
            // unit of thought. Drag handles over a custom text stack buy
            // nothing a reader of this book wants.
            .onLongPressGesture(minimumDuration: 0.4) {
                journalDraft = ""
                sheet = .keep(passage: paragraph)
            }
            // VoiceOver does not synthesize a long press on a paragraph
            // of text, so without this the whole keep-and-copy path is
            // closed to anyone using it.
            .accessibilityAction(named: "Keep this passage") {
                journalDraft = ""
                sheet = .keep(passage: paragraph)
            }
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
                        LibraryProgressStore.markFinished(
                            bookID: bookID, chapterIndex: currentIndex, in: modelContext
                        )
                        refreshFinished()
                        go(to: currentIndex + 1)
                    }
                }
            }
        }
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

    /// A kept passage becomes a Reflection — the app already has one
    /// store for what a reader keeps, and it is the journal. No second
    /// highlights library, no colours, no review queue.
    private func keepAsReflection(_ passage: String) {
        guard let info else { return }
        let body = journalDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        var text = "\u{201C}\(passage)\u{201D}\n\n\(citation)"
        if !body.isEmpty { text += "\n\n\(body)" }

        let entry = JournalEntry(
            text: text,
            mysteryTitle: chapter?.displayTitle ?? info.title
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

// MARK: - Keep a passage

/// A passage on its way into the journal: the words as they stand, their
/// citation, and room for the reader's own line underneath — which is
/// where spiritual reading is supposed to end up.
struct LibraryKeepSheet: View {

    let passage: String
    let citation: String
    @Binding var draft: String
    let onKeep: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWriting: Bool

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("KEEP THIS")
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
                            dismiss()
                        }

                        Spacer()

                        QuietGoldButton(
                            title: "Keep as a reflection",
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
private struct LibraryFollowWatcher: View {

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
