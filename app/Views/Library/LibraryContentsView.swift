//
//  LibraryContentsView.swift
//  Lumen Viae
//
//  The book's contents, as a ruled ledger — used both on the book page,
//  where it is the page itself, and inside the reader, where it is the
//  ☰ sheet that keeps a hundred-and-fourteen-chapter book from being a
//  corridor with no doors.
//
//  Both taps on a row land in the reader; the only difference is
//  whether the voice starts. The row itself opens the chapter silent,
//  and its listen chip — the recording's own length, worn as a pill —
//  opens it with the voice reading.
//
//  Marks, and what they mean, deliberately: a gold dot is where you are,
//  a chapter you have read to the end is set dimmed on the book page and
//  under a faint gold rule in the ☰ sheet's margin, and a small ribbon
//  with a count is the marks you laid in it.
//  None is a score. Knowing which doors you have been through is
//  navigation; knowing you have been through forty-one per cent of them
//  is a scoreboard, and this shelf does not keep one.
//

import SwiftUI

// MARK: - PartRun

/// One run of chapters under one part heading — or the whole book, when
/// its edition names no parts.
struct LibraryPartRun: Identifiable {
    let id: String
    let title: String?
    var chapters: [LibraryChapter]

    /// Appends in place rather than rebuilding from a concatenation: the
    /// old form copied the whole accumulating array once per chapter,
    /// which is a hundred and fourteen copies for the Imitation.
    static func runs(of book: LibraryBook) -> [LibraryPartRun] {
        var built: [LibraryPartRun] = []
        for chapter in book.chapters {
            if let last = built.indices.last, built[last].title == chapter.part {
                built[last].chapters.append(chapter)
            } else {
                built.append(LibraryPartRun(
                    id: chapter.part ?? "part-\(built.count)",
                    title: chapter.part,
                    chapters: [chapter]
                ))
            }
        }
        return built
    }
}

// MARK: - Contents ledger

// MARK: - Place

/// How the book page names a place in the book and where its list
/// begins. Pure, so the rules can be tested without a view.
enum LibraryBookPlace {

    /// How many chapters before the one being read the page's list
    /// shows, dimmed, so the reader sees where they came from.
    static let leadIn = 2

    /// The numeral a heading ends on — "V" of "Chapter V", "12" of
    /// "Chapter 12" — or nil for a heading with none ("Prologue"), read
    /// as strictly as the recordings' ledger reads them
    /// (`LibraryNumerals`), so an all-caps word is never a numeral.
    static func numeral(ofHeading heading: String) -> String? {
        guard let last = heading.split(separator: " ").last, last.count < heading.count else {
            return nil
        }
        let word = String(last)
        return Int(word) != nil || LibraryNumerals.roman(word) != nil ? word : nil
    }

    /// The parts a book prints by name. An edition's front matter — the
    /// Glories of Mary's Introduction, the Practice's Preface — stands as
    /// a run of its own before the first part, with no title, and is no
    /// part: it is never numbered, pinned or indexed.
    static func titledParts(_ runs: [LibraryPartRun]) -> [LibraryPartRun] {
        runs.filter { $0.title != nil }
    }

    /// Whether the book is printed in parts, so the page pins and indexes
    /// them
    static func hasParts(_ runs: [LibraryPartRun]) -> Bool {
        titledParts(runs).count > 1
    }

    /// A part's number as the book counts its parts, 1 for the first named
    /// one; nil for front matter
    static func partNumber(of runID: String, in runs: [LibraryPartRun]) -> Int? {
        titledParts(runs).firstIndex { $0.id == runID }.map { $0 + 1 }
    }

    /// The place on the Continue button: "III.V" in a book of parts —
    /// the part's numeral and the chapter's — and the heading itself
    /// ("Chapter V", "Prologue") in a book without them, in front matter,
    /// or where the heading carries no numeral. A chapter whose heading is
    /// its part's own name (the exhortation opening the Imitation's Fourth
    /// Book) is named by the part's numeral alone.
    static func shortName(of chapter: LibraryChapter, in runs: [LibraryPartRun]) -> String {
        guard hasParts(runs),
              let run = runs.first(where: { $0.chapters.contains { $0.id == chapter.id } }),
              let part = partNumber(of: run.id, in: runs) else {
            return chapter.heading
        }
        if let tail = numeral(ofHeading: chapter.heading) {
            return "\(LibraryNumerals.numeral(for: part)).\(tail)"
        }
        return chapter.heading == run.title ? LibraryNumerals.numeral(for: part) : chapter.heading
    }

    /// The chapter the page's list begins at: `leadIn` before the one
    /// being read. Nil when the list begins at the book's start, so
    /// nothing stands folded above it.
    static func firstShown(in runs: [LibraryPartRun], currentIndex: Int?) -> Int? {
        guard let currentIndex else { return nil }
        let ids = runs.flatMap { $0.chapters.map(\.id) }
        guard let position = ids.firstIndex(of: currentIndex) else { return nil }
        let start = position - leadIn
        return start > 0 ? ids[start] : nil
    }

    /// The runs as the page draws them from `first` on: earlier runs
    /// left out, the run holding `first` cut to begin there.
    static func runs(_ runs: [LibraryPartRun], from first: Int?) -> [LibraryPartRun] {
        guard let first else { return runs }
        var shown: [LibraryPartRun] = []
        var started = false
        for run in runs {
            if started {
                shown.append(run)
            } else if let cut = run.chapters.firstIndex(where: { $0.id == first }) {
                started = true
                var tail = run
                tail.chapters = Array(run.chapters[cut...])
                shown.append(tail)
            }
        }
        return shown
    }
}

/// Where a chapter row is drawn. The book page keeps its own ruled list;
/// the reader's ☰ sheet sets the same chapters as the app's sheet rows
/// (`SheetChrome`), so its index reads like every other sheet's.
enum LibraryContentsStyle {
    case page
    case sheet
}

/// The reader's ☰ sheet's ledger, its parts folding. The book page draws
/// its own list, with the parts pinned rather than folded.
struct LibraryContentsLedger: View {

    let runs: [LibraryPartRun]

    /// Where the reader is now — a gold dot
    var currentIndex: Int?

    /// Chapters read to the end — a faint gold rule in the margin
    var finished: Set<Int> = []

    /// How many ribbons lie in each chapter
    var markCounts: [Int: Int] = [:]

    /// Which parts stand open. Bound so the two callers keep their own.
    @Binding var expandedParts: Set<String>

    let onSelect: (LibraryChapter) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if runs.count == 1 {
                chapterRows(runs[0].chapters)
            } else {
                ForEach(runs) { run in
                    partHeader(run)

                    if expandedParts.contains(run.id) {
                        chapterRows(run.chapters)
                            .padding(.bottom, 6)
                    }
                }
            }
        }
    }

    // MARK: Part header

    private func partHeader(_ run: LibraryPartRun) -> some View {
        let isOpen = expandedParts.contains(run.id)
        let holdsCurrent = currentIndex.map { index in
            run.chapters.contains { $0.id == index }
        } ?? false

        return Button {
            // The caret animates; the rows do not. The Imitation's Third
            // Book is fifty-nine chapters, and animating all of them into
            // existence in one transaction inside a lazy stack is a
            // visible stutter for no gain.
            if isOpen {
                expandedParts.remove(run.id)
            } else {
                expandedParts.insert(run.id)
            }
        } label: {
            sheetPartLabel(run, isOpen: isOpen, holdsCurrent: holdsCurrent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(run.title ?? "Part"), \(run.chapters.count) chapters")
        .accessibilityHint(isOpen ? "Closes this part's chapters" : "Opens this part's chapters")
    }

    /// The sheet's part heading: a `SheetSectionLabel` that still folds,
    /// with the part's size and its caret at the trailing edge
    private func sheetPartLabel(_ run: LibraryPartRun, isOpen: Bool, holdsCurrent: Bool) -> some View {
        HStack(spacing: 10) {
            Text((run.title ?? "").uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(isOpen ? 0.95 : 0.75))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if holdsCurrent, !isOpen {
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: 5, height: 5)
            }

            Spacer(minLength: 8)

            Text("\(run.chapters.count)")
                .font(AppFonts.labelFont(9))
                .tracking(1)
                .foregroundColor(AppColors.textSecondary.opacity(0.8))

            AppIcon(isOpen ? "ph-caret-up" : "ph-caret-down", size: 10)
                .foregroundColor(AppColors.gold.opacity(0.6))
                .animation(.easeOut(duration: 0.2), value: isOpen)
        }
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: Chapter rows

    @ViewBuilder
    private func chapterRows(_ chapters: [LibraryChapter]) -> some View {
        ForEach(chapters) { chapter in
            LibraryChapterRow(
                chapter: chapter,
                style: .sheet,
                isCurrent: chapter.id == currentIndex,
                isFinished: finished.contains(chapter.id),
                isLast: chapter.id == chapters.last?.id,
                markCount: markCounts[chapter.id] ?? 0,
                onSelect: onSelect
            )
            .id(chapter.id)
        }
    }
}

// MARK: - What a row knows about the voice

/// Everything a chapter row needs in order to also be the way into the
/// recording that reads it.
///
/// Carried rather than looked up, because the same row is drawn in two
/// places: the book page, where a chapter can be read *or* heard, and the
/// reader's ☰ index, where it is only a door to another chapter and this
/// is nil.
struct LibraryRowListening {
    var isSounding: Bool = false
    var isLoaded: Bool = false
    var isLoading: Bool = false

    /// The recording's own length in seconds, as LibriVox states it — a
    /// fact about the file, never an estimate of the reader
    var playtimeSeconds: Double? = nil

    /// Seconds in, where the voice was left mid-reading
    var resting: Double? = nil

    /// Whether the reading is on the device
    var save: LibraryAudioDownloads.State = .absent

    /// Toggles the reading — the chip's own act
    var onToggle: () -> Void = {}
    var onSave: () -> Void = {}
    var onRemove: () -> Void = {}
}

// MARK: - One row

struct LibraryChapterRow: View {

    let chapter: LibraryChapter

    /// The page's row by default; the ☰ sheet draws a `SheetRow`
    var style: LibraryContentsStyle = .page

    var isCurrent: Bool = false
    var isFinished: Bool = false
    var isLast: Bool = false

    /// How many ribbons lie in this chapter
    var markCount: Int = 0

    /// A line of the chapter to show beneath the title — a search match
    var excerpt: AttributedString? = nil

    /// Present where a recording begins at this chapter.
    var listening: LibraryRowListening? = nil

    /// Whether the page row keeps a column for the numeral even where
    /// this chapter has none, so a Prologue's title stands in line with
    /// Chapter I's beneath it. Off for a book that numbers nothing.
    var reservesNumeral: Bool = false

    let onSelect: (LibraryChapter) -> Void

    /// An edition that prints no chapter titles used to draw its heading
    /// twice. Where the two would say the same thing, the heading owns
    /// the row.
    private var hasDistinctTitle: Bool {
        guard let title = chapter.title else { return false }
        return title != chapter.heading
    }

    var body: some View {
        switch style {
        case .page: pageRow
        case .sheet: sheetRow
        }
    }

    // MARK: Page row

    /// The numeral the row leads with — "V" of "Chapter V" — or nil for
    /// a heading with none ("Prologue"), which the title then carries.
    private var numeral: String? {
        LibraryBookPlace.numeral(ofHeading: chapter.heading)
    }

    /// The row's one line of title: the chapter's own where its heading
    /// is only a number, "Prologue · The Parentage…" where it is a word —
    /// but not where the heading is the part's own name (the exhortation
    /// that opens the Imitation's Fourth Book), which is pinned above it.
    private var rowTitle: String {
        guard hasDistinctTitle, numeral == nil, chapter.heading != chapter.part else {
            return chapter.displayTitle
        }
        return "\(chapter.heading) · \(chapter.displayTitle)"
    }

    private var titleColor: Color {
        if isCurrent { return AppColors.goldLight }
        if isFinished { return AppColors.cream.opacity(0.5) }
        return AppColors.cream
    }

    /// One tight row: the numeral in a column of its own, the title, and
    /// at the trailing edge only what is there — ribbons laid, and the
    /// recording's time where one begins here. Read chapters are dimmed,
    /// the one being read is lit with a dot by its numeral.
    private var pageRow: some View {
        VStack(spacing: 0) {
            Button {
                onSelect(chapter)
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if numeral != nil || reservesNumeral {
                            HStack(spacing: 4) {
                                Text(numeral ?? "")
                                    .font(AppFonts.labelFont(11))
                                    .foregroundColor(
                                        isCurrent ? AppColors.goldLight : AppColors.gold.opacity(0.8)
                                    )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                if isCurrent {
                                    Circle()
                                        .fill(AppColors.goldLight)
                                        .frame(width: 4, height: 4)
                                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 2 }
                                }
                            }
                            .frame(width: 40, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(rowTitle)
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(titleColor)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            if let excerpt {
                                Text(excerpt)
                                    .font(AppFonts.italicFont(13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }

                            // Only where the voice was left part-way: the
                            // exact place it rests, in the player's own hand.
                            if let resting = listening?.resting {
                                Text("\(LibraryListeningSession.time(resting)) in")
                                    .font(AppFonts.italicFont(12))
                                    .foregroundColor(AppColors.goldLight.opacity(0.85))
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    if markCount > 0 {
                        HStack(spacing: 4) {
                            MarkerRibbonShape()
                                .fill(AppColors.goldLight)
                                .frame(width: 6, height: 13)

                            Text("\(markCount)")
                                .font(AppFonts.labelFont(9))
                                .foregroundColor(AppColors.goldLight.opacity(0.9))
                        }
                        .accessibilityHidden(true)
                    }

                    if let listening {
                        listenChip(listening)
                        saveMark(listening)
                    }
                }
                .padding(.vertical, 9)
                .frame(minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenLabel)
            .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
            // Only where a recording actually begins at this chapter.
            // Registered unconditionally, VoiceOver offered "Hear this
            // read" on every row of the ☰ index and on the nine rows in
            // ten of a gathered track that draw no chip on purpose — an
            // action that silently did nothing.
            .accessibilityActions {
                if let listening {
                    Button("Hear this read") { listening.onToggle() }
                    if case .saved = listening.save {
                        Button("Remove from the device") { listening.onRemove() }
                    } else if case .absent = listening.save {
                        Button("Save this reading to the device") { listening.onSave() }
                    }
                }
            }

            if !isLast {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.08))
                    .frame(height: AppLine.hairline)
            }
        }
    }

    // MARK: Sheet row

    /// The ☰ sheet's row: the chapter's name, its heading beneath where
    /// the edition prints a distinct one, the ribbons laid in it, and HERE
    /// lit where the reader is. No listen chip — in the index a row is
    /// only a door.
    private var sheetRow: some View {
        Button {
            onSelect(chapter)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                SheetRow(
                    chapter.displayTitle,
                    detail: hasDistinctTitle ? chapter.heading : nil,
                    isLit: isCurrent,
                    showsDivider: excerpt == nil
                ) {
                    HStack(spacing: 10) {
                        if markCount > 0 {
                            sheetMarkRibbon
                        }

                        SheetRowAccessoryView(accessory: isCurrent ? .label("Here") : .caret)
                    }
                }

                // A search match's line, under the row in its own hand:
                // `SheetRow` takes plain strings, and the gold on the
                // matched words is how the eye finds the line. Pulled up
                // into the row's foot; its wash is laid after the pull so
                // it meets the row's rather than doubling over it.
                if let excerpt {
                    Text(excerpt)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SheetMetrics.gutter)
                        .padding(.bottom, 12)
                        .padding(.top, -7)
                        .background(isCurrent ? AppColors.gold.opacity(0.07) : Color.clear)
                        .overlay(alignment: .bottom) { SheetRule() }
                }
            }
            // The read-mark, in the gutter: a thin rule, the way a
            // well-used book falls open. Never a checkbox.
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(isFinished ? AppColors.gold.opacity(0.45) : Color.clear)
                    .frame(width: 2)
                    .padding(.vertical, 10)
                    .padding(.leading, 12)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
    }

    /// The ribbons laid in this chapter, beside the row's caret
    private var sheetMarkRibbon: some View {
        HStack(spacing: 4) {
            MarkerRibbonShape()
                .fill(AppColors.goldLight)
                .frame(width: 7, height: 15)

            Text("\(markCount)")
                .font(AppFonts.labelFont(9))
                .foregroundColor(AppColors.goldLight.opacity(0.9))
        }
        .accessibilityHidden(true)
    }

    /// A small arrow that fills to a solid mark once the reading is on
    /// the device, and turns as it arrives. Press and hold a saved one to
    /// give it back to the network.
    ///
    /// The one-chapter-at-a-time way in: the honest offline line beneath
    /// the ledger offers the whole book, which for the Dolorous Passion
    /// is about 188 MB. A reader who wants tonight's chapter before a
    /// flight asks here.
    @ViewBuilder
    private func saveMark(_ listening: LibraryRowListening) -> some View {
        switch listening.save {
        case .absent:
            Button(action: listening.onSave) {
                AppIcon("ph-download-simple", size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

        case .saving(let fraction):
            SwiftUI.ProgressView(value: fraction ?? 0)
                .progressViewStyle(.circular)
                .controlSize(.mini)
                .tint(AppColors.gold)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

        case .saved:
            // Not a Button: a tap on one would have done nothing at all,
            // with press feedback promising otherwise. A mark that says
            // "this is here", and a press-and-hold that gives it back.
            AppIcon("ph-check-circle-fill", size: 13)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onLongPressGesture { listening.onRemove() }
                .accessibilityHidden(true)
        }
    }

    /// The recording's length, worn as the row's second act: tap the
    /// time to have the chapter read aloud. While it sounds, the chip
    /// fills and offers the pause.
    @ViewBuilder
    private func listenChip(_ listening: LibraryRowListening) -> some View {
        let sounding = listening.isSounding

        Button(action: listening.onToggle) {
            HStack(spacing: 6) {
                if listening.isLoading {
                    SwiftUI.ProgressView()
                        .controlSize(.mini)
                        .tint(AppColors.gold)
                } else {
                    AppIcon(sounding ? "ph-pause-fill" : "ph-play-fill", size: 10)
                }

                if let seconds = listening.playtimeSeconds {
                    Text(ReadingSpans.chipMinutes(seconds))
                        .font(AppFonts.labelFont(9))
                        .tracking(1.2)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundColor(sounding ? AppColors.goldLight : AppColors.gold)
            .padding(.vertical, 8)
            .padding(.horizontal, 11)
            .background(
                Capsule().fill(sounding ? AppColors.gold.opacity(0.14) : Color.clear)
            )
            .overlay(
                Capsule().strokeBorder(
                    AppColors.gold.opacity(sounding ? 0.7 : 0.4),
                    lineWidth: AppLine.hairline
                )
            )
            // A 44-point target without a 44-point row: the chip's hit
            // area reaches past its drawn pill.
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .padding(.vertical, -8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            sounding
                ? "Pause the reading of \(chapter.displayTitle)"
                : "Hear \(chapter.displayTitle) read"
        )
    }

    private var spokenLabel: String {
        var parts: [String] = []
        if hasDistinctTitle { parts.append(chapter.heading) }
        parts.append(chapter.displayTitle)
        if isCurrent { parts.append("where you are") }
        else if isFinished { parts.append("read") }
        if markCount > 0 { parts.append("\(markCount) bookmarks") }
        if let seconds = listening?.playtimeSeconds {
            parts.append(ReadingSpans.chipMinutes(seconds).lowercased())
        }
        if let resting = listening?.resting {
            parts.append("\(LibraryListeningSession.elapsedLabel(resting)) in")
        }
        return parts.joined(separator: ". ")
    }
}

// MARK: - A mark, in a sheet

/// One ribbon in a contents sheet's YOUR MARKS: where it lies, the words
/// it marks, and a door straight back to its paragraph. Shared by the
/// shelf's ☰ sheet and True Devotion's, which keep their marks the same
/// way and differ only in how a chapter is named.
struct LibraryMarkSheetRow: View {

    /// The chapter the ribbon lies in
    let place: String

    /// The paragraph's opening words, where the paragraph still exists
    let words: String?

    let spokenLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SheetRow(place, detail: words, detailLineLimit: 2) {
                HStack(spacing: 10) {
                    MarkerRibbonShape()
                        .fill(AppColors.goldLight)
                        .frame(width: 7, height: 15)
                        .accessibilityHidden(true)

                    SheetRowAccessoryView(accessory: .caret)
                }
            }
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(spokenLabel)
    }
}

// MARK: - Contents sheet

/// The ☰ sheet: the whole book from inside a chapter, the pages that
/// stood out, and a search that finds the half-remembered line.
struct LibraryContentsSheet: View {

    let info: LibraryBookInfo
    let book: LibraryBook
    let currentIndex: Int
    var finished: Set<Int> = []

    /// The ribbons laid in this book, for the YOUR MARKS section
    var marks: [BookPassageMark] = []

    let onSelect: (Int) -> Void

    /// Returns to a marked paragraph — chapter, then paragraph
    var onSelectMark: ((Int, Int) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var expandedParts: Set<String> = []
    @State private var query = ""

    /// Partitioned once when the sheet opens. Derived in the body it was
    /// re-cut on every keystroke of the search field and every disclosure
    /// — a hundred and fourteen chapters at a time.
    @State private var runs: [LibraryPartRun] = []

    private var markCounts: [Int: Int] {
        marks.reduce(into: [:]) { counts, mark in
            counts[mark.chapter, default: 0] += 1
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    SheetHeader(kicker: info.title, title: "Contents") {
                        place
                    }

                    // Deliberately not auto-focused: the page is a place
                    // first and a search second, the same restraint
                    // Explore keeps.
                    searchField
                        .padding(.horizontal, SheetMetrics.gutter)
                        .padding(.bottom, 12)

                    if query.isEmpty {
                        if !marks.isEmpty {
                            marksSection

                            // A book with no parts has no heading of its
                            // own to end the marks on
                            if runs.count == 1 {
                                SheetSectionLabel("Chapters")
                            }
                        }

                        LibraryContentsLedger(
                            runs: runs,
                            currentIndex: currentIndex,
                            finished: finished,
                            markCounts: markCounts,
                            expandedParts: $expandedParts,
                            onSelect: { chapter in
                                onSelect(chapter.id)
                                dismiss()
                            }
                        )
                    } else {
                        results
                    }

                    Spacer(minLength: 40)
                }
            }
            .onAppear {
                if runs.isEmpty { runs = LibraryPartRun.runs(of: book) }
                seedExpansion()
                // Open on the chapter being read, not at the head of
                // a book the reader is sixty chapters into.
                DispatchQueue.main.async {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
        .sheetGround()
    }

    // MARK: Header

    /// Where the reader stands in the book, level with the kicker
    private var place: some View {
        Text("\(currentIndex + 1) of \(book.chapters.count)".uppercased())
            .font(AppFonts.labelFont(9))
            .tracking(1.5)
            .foregroundColor(AppColors.textSecondary)
            .fixedSize()
            .accessibilityLabel("Chapter \(currentIndex + 1) of \(book.chapters.count)")
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

            if !query.isEmpty {
                Button { query = "" } label: {
                    AppIcon("ph-x", size: 12)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.cardBackground.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: AppLine.hairline)
        )
    }

    // MARK: Your marks

    /// The pages that stood out: every ribbon in the book, each one a
    /// door straight back to its paragraph.
    private var marksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetSectionLabel("Your bookmarks · \(marks.count)")

            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                markRow(mark)
            }
        }
    }

    @ViewBuilder
    private func markRow(_ mark: BookPassageMark) -> some View {
        if let chapter = book.chapter(at: mark.chapter) {
            LibraryMarkSheetRow(
                place: chapter.heading,
                words: chapter.paragraphs.indices.contains(mark.paragraph)
                    ? openingWords(of: chapter.paragraphs[mark.paragraph])
                    : nil,
                spokenLabel: "Bookmark in \(chapter.displayTitle). Returns to that passage."
            ) {
                onSelectMark?(mark.chapter, mark.paragraph)
                dismiss()
            }
        }
    }

    private func openingWords(of paragraph: String) -> String {
        let words = info.parsing.quotable(paragraph)
        return words.count > 90 ? String(words.prefix(90)) + "\u{2026}" : words
    }

    // MARK: Search

    @ViewBuilder
    private var results: some View {
        let found = LibraryBookSearch.matches(in: book, query: query)

        if found.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nothing found")
                    .font(AppFonts.headlineFont(16))
                    .foregroundColor(AppColors.cream)

                Text("No line in this book has those words.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.top, 16)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(found, id: \.chapter.id) { match in
                    LibraryChapterRow(
                        chapter: match.chapter,
                        style: .sheet,
                        isCurrent: match.chapter.id == currentIndex,
                        isFinished: finished.contains(match.chapter.id),
                        isLast: match.chapter.id == found.last?.chapter.id,
                        excerpt: match.line,
                        onSelect: { chapter in
                            onSelect(chapter.id)
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    /// The part being read stands open; without one, the first.
    private func seedExpansion() {
        guard expandedParts.isEmpty, runs.count > 1 else { return }
        if let holding = runs.first(where: { run in
            run.chapters.contains { $0.id == currentIndex }
        }) {
            expandedParts = [holding.id]
        } else if let first = runs.first {
            expandedParts = [first.id]
        }
    }
}


// MARK: - Search

/// Finding the half-remembered line — the way people actually return to
/// a book of spiritual reading, far more often than they read one front
/// to back.
///
/// A scan, not an index. The whole parsed book is already resident (one
/// at a time, by design), so a hundred and fourteen chapters of Kempis —
/// or the Confessions' hundred and twelve thousand words — finish well
/// inside a frame, and there is nothing to build or keep in step.
enum LibraryBookSearch {

    struct Match: Identifiable {
        let chapter: LibraryChapter
        let line: AttributedString
        var id: Int { chapter.id }
    }

    /// The first matching line of each chapter that carries the words.
    static func matches(in book: LibraryBook, query: String, limit: Int = 60) -> [Match] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard needle.count >= 2 else { return [] }

        var found: [Match] = []
        for chapter in book.chapters {
            guard let paragraph = chapter.paragraphs.first(where: {
                $0.localizedStandardContains(needle)
            }) else { continue }
            found.append(Match(chapter: chapter, line: excerpt(of: paragraph, around: needle)))
            if found.count >= limit { break }
        }
        return found
    }

    /// The words either side of the match, with the match itself in gold.
    static func excerpt(of paragraph: String, around needle: String) -> AttributedString {
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        guard let range = paragraph.range(of: needle, options: options) else {
            return AttributedString(String(paragraph.prefix(140)))
        }

        let lead = paragraph.index(range.lowerBound, offsetBy: -60, limitedBy: paragraph.startIndex)
            ?? paragraph.startIndex
        let tail = paragraph.index(range.upperBound, offsetBy: 80, limitedBy: paragraph.endIndex)
            ?? paragraph.endIndex

        var text = AttributedString(
            (lead == paragraph.startIndex ? "" : "…") + paragraph[lead..<tail] +
            (tail == paragraph.endIndex ? "" : "…")
        )
        if let highlighted = text.range(of: needle, options: options) {
            text[highlighted].foregroundColor = AppColors.goldLight
        }
        return text
    }
}
