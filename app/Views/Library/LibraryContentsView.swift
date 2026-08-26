//
//  LibraryContentsView.swift
//  Lumen Viae
//
//  The book's contents, as a ruled ledger — used both on the book page,
//  where it is the page itself, and inside the reader, where it is the
//  ☰ sheet that keeps a hundred-and-fourteen-chapter book from being a
//  corridor with no doors.
//
//  Marks, and what they mean, deliberately: a gold dot is where you are,
//  a faint gold rule in the left margin is a chapter you have read to
//  the end. Neither is a count. Knowing which doors you have been
//  through is navigation; knowing you have been through forty-one per
//  cent of them is a scoreboard, and this shelf does not keep one.
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

/// The ruled ledger itself, without any chrome around it.
struct LibraryContentsLedger: View {

    let runs: [LibraryPartRun]

    /// Where the reader is now — a gold dot
    var currentIndex: Int?

    /// Chapters read to the end — a faint gold rule in the margin
    var finished: Set<Int> = []

    /// What each chapter's recording is doing, where one begins there.
    /// Absent for a book with no recording, and in the reader's index,
    /// where a row is only a door.
    var listening: (LibraryChapter) -> LibraryRowListening? = { _ in nil }

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
            HStack(spacing: 12) {
                Text((run.title ?? "").uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(isOpen ? 0.95 : 0.75))
                    .fixedSize()

                if holdsCurrent, !isOpen {
                    Circle()
                        .fill(AppColors.goldLight)
                        .frame(width: 5, height: 5)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold.opacity(0.3), AppColors.gold.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text("\(run.chapters.count)")
                    .font(AppFonts.labelFont(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))

                AppIcon(isOpen ? "ph-caret-up" : "ph-caret-down", size: 10)
                    .foregroundColor(AppColors.gold.opacity(0.6))
                    .animation(.easeOut(duration: 0.2), value: isOpen)
            }
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(run.title ?? "Part"), \(run.chapters.count) chapters")
        .accessibilityHint(isOpen ? "Closes this part's chapters" : "Opens this part's chapters")
    }

    // MARK: Chapter rows

    @ViewBuilder
    private func chapterRows(_ chapters: [LibraryChapter]) -> some View {
        ForEach(chapters) { chapter in
            LibraryChapterRow(
                chapter: chapter,
                isCurrent: chapter.id == currentIndex,
                isFinished: finished.contains(chapter.id),
                isLast: chapter.id == chapters.last?.id,
                listening: listening(chapter),
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

    /// The recording's own length, as LibriVox states it — a fact about
    /// the file, not an estimate of the reader
    var playtime: String? = nil

    /// Seconds in, where the voice was left mid-reading
    var resting: Double? = nil

    /// Whether the reading is on the device
    var save: LibraryAudioDownloads.State = .absent

    var onToggle: () -> Void = {}
    var onSave: () -> Void = {}
    var onRemove: () -> Void = {}
}

// MARK: - One row

struct LibraryChapterRow: View {

    let chapter: LibraryChapter
    var isCurrent: Bool = false
    var isFinished: Bool = false
    var isLast: Bool = false

    /// A line of the chapter to show beneath the title — a search match
    var excerpt: AttributedString? = nil

    /// Present where a recording begins at this chapter. The ledger is
    /// one ledger: the chapter is the thing, and the voice is one of two
    /// ways to have it.
    var listening: LibraryRowListening? = nil

    let onSelect: (LibraryChapter) -> Void

    /// An edition that prints no chapter titles used to draw its heading
    /// twice, once in the margin and once as the row's own text. Where
    /// the two would say the same thing, the heading owns the row.
    private var hasDistinctTitle: Bool {
        guard let title = chapter.title else { return false }
        return title != chapter.heading
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onSelect(chapter)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: listening == nil ? 12 : 6) {
                    if let listening {
                        // Two acts on one row, each with its own target:
                        // the row opens the chapter, this plays it.
                        Button(action: listening.onToggle) {
                            Group {
                                if listening.isLoading {
                                    SwiftUI.ProgressView()
                                        .controlSize(.small)
                                        .tint(AppColors.gold)
                                } else {
                                    AppIcon(
                                        listening.isSounding ? "ph-pause-fill"
                                            : (listening.isLoaded ? "ph-play-fill" : "ph-play"),
                                        size: 13
                                    )
                                    .foregroundColor(AppColors.gold)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            listening.isSounding
                                ? "Pause the reading of \(chapter.displayTitle)"
                                : "Hear \(chapter.displayTitle) read"
                        )
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 12 }
                    }

                    if hasDistinctTitle {
                        Text(chapter.heading.uppercased())
                            // Fits "CHAPTER VIII" on one line. Wrapped, it
                            // pushed the row taller than the divider knew
                            // about and the two collided.
                            .font(AppFonts.labelFont(10))
                            .tracking(1.2)
                            .foregroundColor(AppColors.gold.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(width: listening == nil ? 92 : 78, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.displayTitle)
                            .font(AppFonts.bodyFont(15))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if let excerpt {
                            Text(excerpt)
                                .font(AppFonts.italicFont(13))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        if let line = recordingLine {
                            Text(line)
                                .font(AppFonts.italicFont(12))
                                .foregroundColor(
                                    listening?.resting == nil
                                        ? AppColors.textSecondary
                                        : AppColors.goldLight.opacity(0.85)
                                )
                        }
                    }

                    Spacer(minLength: 8)

                    if let listening {
                        saveMark(listening)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 12 }
                    }

                    if isCurrent {
                        Circle()
                            .fill(AppColors.goldLight)
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)
                    } else {
                        AppIcon("ph-caret-right", size: 11)
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                    }
                }
                .padding(.vertical, 12)
                .padding(.leading, listening == nil ? 14 : 6)
                .frame(minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                // The read-mark: a thin rule in the margin, the way a
                // well-used book falls open. Never a checkbox — and drawn
                // as an overlay rather than a sibling, because a
                // baseline-aligned row has no baseline to give a bare
                // rectangle, and it took the row's height with it.
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(isFinished ? AppColors.gold.opacity(0.45) : Color.clear)
                        .frame(width: 2)
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenLabel)
            .accessibilityAddTraits(isCurrent ? [.isSelected] : [])

            if !isLast {
                Divider()
                    .background(AppColors.gold.opacity(0.15))
            }
        }
    }

    /// "40 min", or "40 min · 31 min in" where the voice was left
    /// part-way. A length is a fact about the file; nothing here
    /// predicts how long the reader will take.
    private var recordingLine: String? {
        guard let listening else { return nil }
        var parts: [String] = []
        if let playtime = listening.playtime { parts.append(playtime) }
        if let resting = listening.resting {
            parts.append("\(LibraryListeningSession.elapsedLabel(resting)) in")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// A small arrow that fills to a solid mark once the reading is on
    /// the device, and turns as it arrives. Press and hold a saved one to
    /// give it back to the network.
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
            .accessibilityLabel("Save this reading to the device")

        case .saving(let fraction):
            SwiftUI.ProgressView(value: fraction ?? 0)
                .progressViewStyle(.circular)
                .controlSize(.mini)
                .tint(AppColors.gold)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Saving this reading")

        case .saved:
            // Not a Button: a tap on one would have done nothing at all,
            // with press feedback promising otherwise. A mark that says
            // "this is here", and a press-and-hold that gives it back.
            AppIcon("ph-check-circle-fill", size: 13)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onLongPressGesture { listening.onRemove() }
                .accessibilityElement()
                .accessibilityLabel("Saved to the device")
                .accessibilityAddTraits(.isStaticText)
                .accessibilityAction(named: "Remove from the device") { listening.onRemove() }
        }
    }

    private var spokenLabel: String {
        var parts: [String] = []
        if hasDistinctTitle { parts.append(chapter.heading) }
        parts.append(chapter.displayTitle)
        if isCurrent { parts.append("where you are") }
        else if isFinished { parts.append("read") }
        if let line = recordingLine { parts.append(line) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Contents sheet

/// The ☰ sheet: the whole book from inside a chapter, with a search
/// that finds the half-remembered line.
struct LibraryContentsSheet: View {

    let info: LibraryBookInfo
    let book: LibraryBook
    let currentIndex: Int
    var finished: Set<Int> = []
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var expandedParts: Set<String> = []
    @State private var query = ""

    /// Partitioned once when the sheet opens. Derived in the body it was
    /// re-cut on every keystroke of the search field and every disclosure
    /// — a hundred and fourteen chapters at a time.
    @State private var runs: [LibraryPartRun] = []

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        if query.isEmpty {
                            LibraryContentsLedger(
                                runs: runs,
                                currentIndex: currentIndex,
                                finished: finished,
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
                    .padding(.horizontal, 22)
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
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("CONTENTS")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Spacer()

                Text("\(currentIndex + 1) of \(book.chapters.count)")
                    .font(AppFonts.labelFont(10))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 22)

            // Deliberately not auto-focused: the page is a place first
            // and a search second, the same restraint Explore keeps.
            searchField

            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(height: 0.5)
                .padding(.top, 4)
        }
        .padding(.bottom, 4)
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
                .strokeBorder(AppColors.gold.opacity(0.18), lineWidth: 0.5)
        )
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

                Text("No line in \(info.title) carries those words.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 28)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(found, id: \.chapter.id) { match in
                    LibraryChapterRow(
                        chapter: match.chapter,
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
