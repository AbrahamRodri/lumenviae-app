//
//  TrueDevotionChapterReaderView.swift
//  Lumen Viae
//
//  One chapter of True Devotion, read the way the Spiritual Reading
//  shelf reads: the reader's own chrome (Back, and SIZE · MARK ·
//  CONTENTS by name) withdrawing into the prose, a place rule that
//  never leaves, a tap on a paragraph raising NOTE · MARK · SHARE, and
//  the foot stepping chapter to chapter in place — a book of thirteen
//  chapters must not stack thirteen screens.
//
//  Reading state belongs to TrueDevotionReaderViewModel, handed down
//  from the book page so a whole session shares one. Reaching the end
//  of a chapter is what marks it read — no button press required.
//

import SwiftUI
import SwiftData

struct TrueDevotionChapterReaderView: View {

    // MARK: - Properties

    let chapterID: String
    let viewModel: TrueDevotionReaderViewModel
    let library: TrueDevotionLibrary

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSettings.self) private var settings

    /// The chapter on screen — starts where the push said, then steps
    /// in place through the foot and the contents sheet.
    @State private var currentChapterID: String

    /// Paragraph id currently at the top of the screen (scroll tracking)
    @State private var topParagraphID: Int?

    /// True once the reader has actually been touched. SwiftUI builds the
    /// destination of a link on the contents screen before it is pushed,
    /// and that off-screen copy still reports scroll positions — without
    /// this gate it would silently record progress for a chapter the user
    /// never opened.
    @State private var hasInteracted = false

    /// True once the end of the chapter has been on screen. A chapter short
    /// enough to fit in one screenful is finished without any scrolling, so
    /// leaving via the chrome still has to count as having read it.
    @State private var hasReachedEnd = false

    /// The paragraph the reader selected — NOTE · MARK · SHARE stands
    /// while one is.
    @State private var selectedParagraph: Int?

    @State private var toast: String?

    // Chrome withdrawal — the shelf reader's own measure, on the whole
    // content column in global coordinates.
    @State private var chromeHidden = false
    @State private var lastScrollOffset: CGFloat?
    @State private var contentTopAnchor: CGFloat?
    @State private var scrollDownRun: CGFloat = 0
    @State private var scrollUpRun: CGFloat = 0

    @State private var sheet: ReaderSheet?
    @State private var journalDraft = ""

    private enum ReaderSheet: Identifiable {
        case contents
        case textOptions
        case keep(passage: String)
        case share(passage: String)

        var id: String {
            switch self {
            case .contents: return "contents"
            case .textOptions: return "text"
            case .keep: return "keep"
            case .share: return "share"
            }
        }
    }

    /// Sentinel id for the end-of-chapter block in the scroll layout
    private static let endBlockID = Int.max

    private let meter = ReadingDayMeter.shared

    init(
        chapterID: String,
        viewModel: TrueDevotionReaderViewModel,
        library: TrueDevotionLibrary
    ) {
        self.chapterID = chapterID
        self.viewModel = viewModel
        self.library = library
        self._currentChapterID = State(initialValue: chapterID)
    }

    private var chapter: TrueDevotionChapter? { library.book?.chapter(id: currentChapterID) }

    /// The shelf's own reading size — one Aa for every book.
    private var size: CGFloat { settings.readingFontSize }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let chapter {
                reader(chapter)
            } else {
                // The Back capsule lives in `chrome`, inside
                // `reader(chapter)`, and this page hides the system bar
                // and its back-swipe — so this branch has to carry its
                // own way out or it is a screen only a force-quit
                // leaves.
                VStack(spacing: 20) {
                    Text("Chapter unavailable.")
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.textSecondary)

                    ReaderBackCapsule { dismiss() }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let selected = selectedParagraph, let chapter,
               let paragraph = chapter.paragraphs.first(where: { $0.id == selected }) {
                PassageActionBar(
                    isMarked: viewModel.isMarked(chapterID: currentChapterID, paragraph: selected),
                    onNote: {
                        journalDraft = ""
                        sheet = .keep(passage: paragraph.text)
                    },
                    onMark: { toggleMark(at: selected) },
                    onShare: { sheet = .share(passage: paragraph.text) }
                )
                .padding(.bottom, 76)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: selectedParagraph)
        .readerToast($toast)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            meter.enterReader()
            topParagraphID = viewModel.resumeParagraph(for: currentChapterID)
        }
        .onDisappear {
            meter.leaveReader()
            viewModel.save()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else {
                // Back in front of the reader: the day's clock was
                // stopped on the way out, so it has to be re-armed.
                meter.resume()
                return
            }
            viewModel.save()
            // Stops the clock as well as committing it — a phone in a
            // pocket with a chapter open is not reading.
            meter.pause()
        }
        .onChange(of: topParagraphID) { _, newValue in
            guard hasInteracted, let newValue,
                  newValue != Self.endBlockID, newValue >= 0 else { return }
            viewModel.recordPosition(chapterID: currentChapterID, paragraphIndex: newValue)
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .contents:
                TrueDevotionContentsSheet(
                    library: library,
                    viewModel: viewModel,
                    currentChapterID: currentChapterID,
                    onSelect: { go(to: $0) },
                    onSelectMark: { chapterID, paragraph in
                        returnToMark(chapterID: chapterID, paragraph: paragraph)
                    }
                )

            case .textOptions:
                LibraryTextOptionsSheet()
                    .presentationDetents([.height(360)])
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

    private func reader(_ chapter: TrueDevotionChapter) -> some View {
        VStack(spacing: 0) {
            placeRule

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        chapterHeader(chapter)
                            .padding(.bottom, 24)
                            .id(-1)

                        ForEach(chapter.paragraphs) { paragraph in
                            paragraphView(
                                paragraph,
                                isFirst: paragraph.id == chapter.firstTextParagraphID
                            )
                            .id(paragraph.id)
                        }

                        endBlock(chapter)
                            .id(Self.endBlockID)
                            // Reading to the end is what marks the chapter
                            // read — no button press required.
                            .onAppear {
                                hasReachedEnd = true
                                if hasInteracted { complete(currentChapterID) }
                            }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .padding(.bottom, 40)
                    .scrollTargetLayout()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).minY
                    } action: { offset in
                        handleScroll(offset)
                    }
                }
                .scrollPosition(id: $topParagraphID, anchor: .top)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { _ in hasInteracted = true }
                )

                chrome
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .offset(y: chromeHidden ? -58 : 0)
                    .opacity(chromeHidden ? 0 : 1)
                    .allowsHitTesting(!chromeHidden)
            }
        }
        .onChange(of: currentChapterID) { _, newID in
            hasReachedEnd = false
            selectedParagraph = nil
            // The reader has not touched the new chapter yet. Without
            // this the flag stays true across the step, and the end
            // block — which materializes while the scroll offset is
            // still deep in the chapter just left — completes the new
            // chapter on the frame it lays out, permanently.
            hasInteracted = false
            topParagraphID = viewModel.resumeParagraph(for: newID) ?? -1
            setChrome(hidden: false)
        }
    }

    /// Where you are in the book — the shelf's hairline, always present.
    @ViewBuilder
    private var placeRule: some View {
        if let book = library.book, book.chapters.count > 1,
           let index = book.chapterIndex(id: currentChapterID) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.1))

                    Rectangle()
                        .fill(AppColors.gold.opacity(0.55))
                        .frame(
                            width: geometry.size.width
                                * (Double(index + 1) / Double(book.chapters.count))
                        )
                }
            }
            .frame(height: 1)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Chrome

    private var chrome: some View {
        HStack(alignment: .top) {
            ReaderBackCapsule {
                if hasReachedEnd { complete(currentChapterID) }
                dismiss()
            }

            Spacer()

            ReaderChromeCapsule(buttons: [
                ReaderCapsuleButton(id: "size", icon: "ph-text-aa", label: "SIZE") {
                    sheet = .textOptions
                },
                ReaderCapsuleButton(id: "mark", icon: nil, label: markButtonLabel) {
                    markCurrentParagraph()
                },
                ReaderCapsuleButton(id: "contents", icon: "ph-list", label: "CONTENTS") {
                    sheet = .contents
                }
            ])
        }
    }

    private var markButtonLabel: String {
        let count = viewModel.markCount(forChapter: currentChapterID)
        return count > 0 ? "MARK · \(count)" : "MARK"
    }

    private func setChrome(hidden: Bool) {
        guard chromeHidden != hidden else { return }
        withAnimation(.easeOut(duration: 0.32)) {
            chromeHidden = hidden
        }
        scrollDownRun = 0
        scrollUpRun = 0
    }

    private func handleScroll(_ offset: CGFloat) {
        guard let last = lastScrollOffset else {
            lastScrollOffset = offset
            contentTopAnchor = offset
            return
        }
        let delta = offset - last
        lastScrollOffset = offset

        if let anchor = contentTopAnchor {
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

    // MARK: - Header

    private func chapterHeader(_ chapter: TrueDevotionChapter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(kicker(for: chapter).uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                if let book = library.book,
                   let index = book.chapterIndex(id: chapter.id) {
                    Text("\(index + 1) OF \(book.chapters.count)")
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Text(chapter.title)
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)

            OrnamentDivider(showsCross: false)
                .frame(width: 140)
                .padding(.top, 8)
        }
        .padding(.top, 12)
    }

    private func kicker(for chapter: TrueDevotionChapter) -> String {
        if let part = library.book?.parts.first(where: { $0.number == chapter.part }) {
            return part.title.components(separatedBy: " — ").first ?? part.title
        }
        return library.book?.title ?? "True Devotion"
    }

    // MARK: - Paragraphs

    @ViewBuilder
    private func paragraphView(_ paragraph: TrueDevotionParagraph, isFirst: Bool) -> some View {
        switch paragraph.kind {
        case .subheading:
            Text(paragraph.text)
                .font(AppFonts.headlineFont(17))
                .foregroundColor(AppColors.gold.opacity(0.9))
                .padding(.top, 10)
                .padding(.bottom, ReadingTypography.paragraphSpacing(for: size))

        case .text:
            ReaderProseParagraph(
                text: paragraph.text,
                isFirst: isFirst,
                size: size,
                isSelected: selectedParagraph == paragraph.id,
                isMarked: viewModel.isMarked(
                    chapterID: currentChapterID, paragraph: paragraph.id
                ),
                onTap: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedParagraph =
                            selectedParagraph == paragraph.id ? nil : paragraph.id
                    }
                }
            )
            .padding(.bottom, ReadingTypography.paragraphSpacing(for: size))
        }
    }

    // MARK: - Marks

    /// The chrome's MARK: the paragraph the reader selected, or failing
    /// that the one being read — walked forward off a subheading, which
    /// has no margin for a ribbon.
    private func markCurrentParagraph() {
        guard let chapter else { return }

        if let selected = selectedParagraph {
            toggleMark(at: selected)
            return
        }

        let top = (topParagraphID ?? -1) >= 0 ? (topParagraphID ?? 0) : 0
        let candidate = chapter.paragraphs.first {
            $0.id >= top && $0.kind == .text
        } ?? chapter.paragraphs.last { $0.kind == .text }

        guard let candidate else { return }
        toggleMark(at: candidate.id)
    }

    private func toggleMark(at paragraph: Int) {
        let nowMarked = viewModel.toggleMark(
            chapterID: currentChapterID, paragraph: paragraph
        )
        toast = nowMarked ? "Marked" : "Mark removed"
        if selectedParagraph == paragraph {
            withAnimation(.easeOut(duration: 0.2)) { selectedParagraph = nil }
        }
    }

    private func returnToMark(chapterID target: String, paragraph: Int) {
        if target == currentChapterID {
            withAnimation(.easeInOut(duration: 0.5)) { topParagraphID = paragraph }
            return
        }
        go(to: target)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            topParagraphID = paragraph
        }
    }

    // MARK: - Stepping

    private func go(to target: String) {
        guard target != currentChapterID,
              library.book?.chapter(id: target) != nil else { return }
        currentChapterID = target
    }

    /// Marks a chapter read, counting it toward the day's measure only
    /// the first time.
    private func complete(_ id: String) {
        let wasCompleted = viewModel.isCompleted(id)
        viewModel.completeChapter(id)
        if !wasCompleted { meter.noteChapterFinished() }
    }

    // MARK: - Foot

    private func endBlock(_ chapter: TrueDevotionChapter) -> some View {
        VStack(spacing: 0) {
            if let book = library.book {
                HStack {
                    if let index = book.chapterIndex(id: chapter.id), index > 0 {
                        let previous = book.chapters[index - 1]
                        footButton(label: previous.title, icon: "ph-caret-left", iconLeads: true) {
                            go(to: previous.id)
                        }
                    }

                    Spacer()

                    if let next = book.chapter(after: chapter.id) {
                        footButton(label: next.title, icon: "ph-caret-right", iconLeads: false) {
                            // Stepping on is how a reader says they
                            // finished this one.
                            complete(chapter.id)
                            go(to: next.id)
                        }
                    }
                }
                .padding(.top, 28)

                if book.chapter(after: chapter.id) == nil {
                    finis
                        .padding(.top, 24)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var finis: some View {
        VStack(spacing: 12) {
            OrnamentDivider()
                .padding(.horizontal, 30)

            Text("Finis")
                .font(AppFonts.italicFont(18))
                .foregroundColor(AppColors.gold)

            Text("You have read the whole of True Devotion. Totus tuus.")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            QuietGoldButton(
                title: "Back to contents",
                size: 10,
                color: AppColors.gold
            ) {
                complete(currentChapterID)
                dismiss()
            }
        }
        .frame(maxWidth: .infinity)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !iconLeads { AppIcon(icon, size: 11) }
            }
            .foregroundColor(AppColors.gold)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .frame(maxWidth: 160, alignment: iconLeads ? .leading : .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Keeping a passage

    private var citation: String {
        guard let book = library.book, let chapter else { return "" }
        var line = "— \(book.author), \(book.title), \(chapter.title)"
        if let translator = translatorShort {
            line += " (trans. \(translator))"
        }
        return line + ". Public domain."
    }

    /// "Fr. Frederick William Faber" out of the source page's fuller line.
    private var translatorShort: String? {
        guard let translator = library.book?.translator else { return nil }
        let stripped = translator.replacingOccurrences(of: "Translated by ", with: "")
        return stripped.components(separatedBy: ",").first
    }

    private var shareCiteLine: String {
        guard let book = library.book, let chapter else { return "" }
        return "\(book.author) · \(chapter.title)"
    }

    /// A kept passage becomes a Reflection — the journal is the app's
    /// one store for what a reader keeps.
    private func keepAsReflection(_ passage: String) {
        guard let book = library.book else { return }
        let body = journalDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        var text = "\u{201C}\(passage)\u{201D}\n\n\(citation)"
        if !body.isEmpty { text += "\n\n\(body)" }

        let entry = JournalEntry(
            text: text,
            mysteryTitle: chapter?.title ?? book.title,
            bookID: TrueDevotionBook.noteBookID
        )
        modelContext.insert(entry)
        try? modelContext.save()

        journalDraft = ""
    }
}

// MARK: - Contents sheet

/// The ☰ sheet: the whole book from inside a chapter, with the pages
/// that stood out at its head.
struct TrueDevotionContentsSheet: View {

    let library: TrueDevotionLibrary
    let viewModel: TrueDevotionReaderViewModel
    let currentChapterID: String
    let onSelect: (String) -> Void
    var onSelectMark: ((String, Int) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        if !viewModel.marks.isEmpty {
                            marksSection
                        }

                        if let book = library.book {
                            ledger(book)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 22)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(currentChapterID, anchor: .center)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("CONTENTS")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Spacer()

                if let book = library.book,
                   let index = book.chapterIndex(id: currentChapterID) {
                    Text("\(index + 1) of \(book.chapters.count)")
                        .font(AppFonts.labelFont(10))
                        .tracking(1.5)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, 22)

            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(height: 0.5)
        }
        .padding(.bottom, 4)
    }

    private var marksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("YOUR MARKS · \(viewModel.marks.count)")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.2)
                    .foregroundColor(AppColors.gold.opacity(0.85))

                Text("the pages that stood out")
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 4)

            ForEach(Array(viewModel.marks.enumerated()), id: \.offset) { _, mark in
                markRow(mark.chapterID, paragraph: mark.paragraph)
            }

            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(height: 0.5)
                .padding(.top, 10)
        }
    }

    @ViewBuilder
    private func markRow(_ chapterID: String, paragraph: Int) -> some View {
        if let book = library.book, let chapter = book.chapter(id: chapterID) {
            Button {
                onSelectMark?(chapterID, paragraph)
                dismiss()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    MarkerRibbonShape()
                        .fill(AppColors.goldLight)
                        .frame(width: 7, height: 15)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(chapter.title.uppercased())
                            .font(AppFonts.labelFont(9))
                            .tracking(1.2)
                            .foregroundColor(AppColors.gold.opacity(0.75))
                            .lineLimit(1)

                        if let text = chapter.paragraphs.first(where: { $0.id == paragraph })?.text {
                            Text(text.count > 90 ? String(text.prefix(90)) + "\u{2026}" : text)
                                .font(AppFonts.italicFont(13))
                                .foregroundColor(AppColors.cream.opacity(0.85))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 8)

                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                }
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark in \(chapter.title). Returns to that passage.")
        }
    }

    private func ledger(_ book: TrueDevotionBook) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                if let partTitle = partHeaderTitle(before: chapter, in: book) {
                    Text(partTitle.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, index == 0 ? 10 : 18)
                        .padding(.bottom, 4)
                }

                chapterRow(chapter, isLast: index == book.chapters.count - 1)
                    .id(chapter.id)
            }
        }
    }

    private func partHeaderTitle(before chapter: TrueDevotionChapter, in book: TrueDevotionBook) -> String? {
        guard let index = book.chapterIndex(id: chapter.id) else { return nil }
        let isFirstOfPart = index == 0 || book.chapters[index - 1].part != chapter.part
        guard isFirstOfPart, chapter.part > 0 else { return nil }
        return book.parts.first { $0.number == chapter.part }?.title
    }

    private func chapterRow(_ chapter: TrueDevotionChapter, isLast: Bool) -> some View {
        let isCompleted = viewModel.isCompleted(chapter.id)
        let isCurrent = chapter.id == currentChapterID

        return VStack(spacing: 0) {
            Button {
                onSelect(chapter.id)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Text(chapter.title)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    if isCurrent {
                        Circle()
                            .fill(AppColors.goldLight)
                            .frame(width: 6, height: 6)
                    } else {
                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                    }
                }
                .padding(.vertical, 12)
                .padding(.leading, 14)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(isCompleted ? AppColors.gold.opacity(0.45) : Color.clear)
                        .frame(width: 2)
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "\(chapter.title)\(isCurrent ? ", where you are" : isCompleted ? ", read" : "")"
            )
            .accessibilityAddTraits(isCurrent ? [.isSelected] : [])

            if !isLast {
                Divider()
                    .background(AppColors.gold.opacity(0.15))
            }
        }
    }
}

// MARK: - Preview

// A view model with no model context simply records nothing, so the reader
// previews without a store — it no longer touches SwiftData itself.
#Preview {
    NavigationStack {
        TrueDevotionChapterReaderView(
            chapterID: "introduction",
            viewModel: TrueDevotionReaderViewModel(),
            library: .shared
        )
    }
    .environment(UserSettings.shared)
}
