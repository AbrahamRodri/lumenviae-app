//
//  LibraryBookView.swift
//  Lumen Viae
//
//  One book of the Spiritual Reading shelf: its contents as a ruled
//  ledger (part headers interleaved), a Continue card once a chapter
//  has been opened, and — when LibriVox holds a complete recording —
//  a Listen ledger that streams through the app's own player.
//
//  The text is fetched and cut on first open, then cached; the page
//  states are loading → error (with retry) → the book itself.
//

import SwiftUI
import SwiftData

struct LibraryBookView: View {

    let bookID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var book: LibraryBook?
    @State private var loadFailed = false

    /// Why the book didn't open — a connection is one reason, an edition
    /// the parser could no longer cut is another, and blaming the wrong
    /// one sends the reader to their settings for nothing.
    @State private var failure: LibraryError = .unreachable
    @State private var sections: [LibriVoxSection] = []
    @State private var progress: BookReadingProgress?

    /// The Listen row last handed to the player, for its sounding mark
    @State private var soundingSectionID: String?

    /// Which parts of the contents stand open. Seeded once when the
    /// book arrives: the part being read, or the first.
    @State private var expandedParts: Set<String> = []
    @State private var didSeedExpansion = false

    /// The contents, partitioned once when the book arrives. Held
    /// rather than derived: the ledger is read on every pass of the
    /// body — which the observed player re-runs on every playback tick
    /// — and partitioning 114 chapters there did that work for nothing.
    @State private var runs: [PartRun] = []

    /// Set as this page pushes a chapter, so leaving *into* the book
    /// does not stop the recording. NavigationStack calls `onDisappear`
    /// for a push as well as for a pop, and a reader following the
    /// voice through the text must not silence it by opening the page.
    @State private var isOpeningChapter = false

    /// Observed so the Listen rows can mark what is sounding
    private let audio = AudioService.shared

    /// Token for this page's claim on the shared player's track
    /// navigation. The service is a singleton and the Rosary drives it
    /// too, so a recording started here must name itself before wiring
    /// the Lock Screen arrows, and must only disarm its own claim.
    private var navigationOwner: AnyHashable { "library-\(bookID)" }

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
            }

            if let info {
                content(info)
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
        .task { await load() }
        .onAppear {
            loadProgress()
            isOpeningChapter = false
        }
        .onDisappear {
            guard !isOpeningChapter else { return }
            stopListening()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ info: LibraryBookInfo) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header(info)
                    .devotionalEntrance()

                if let book {
                    if let progress, let chapter = book.chapter(at: progress.lastChapterIndex) {
                        continueCard(chapter)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .devotionalEntrance(delay: 0.06)
                    }

                    contentsLedger
                        .padding(.horizontal, 20)
                        .devotionalEntrance(delay: 0.1)

                    if !sections.isEmpty {
                        listenLedger(info)
                            .padding(.horizontal, 20)
                            .padding(.top, 28)
                            .devotionalEntrance(delay: 0.14)
                    }

                    credit(info)
                        .padding(.horizontal, 32)
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                } else if loadFailed {
                    unavailable
                        .padding(.top, 40)
                } else {
                    ProgressView()
                        .tint(AppColors.gold)
                        .padding(.top, 60)
                        .padding(.bottom, 80)
                }
            }
        }
    }

    private func header(_ info: LibraryBookInfo) -> some View {
        VStack(spacing: 10) {
            Text(info.author.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)
                .padding(.top, 24)

            Text(info.title)
                .font(AppFonts.headlineFont(26))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let translator = info.translator {
                Text("translated by \(translator)")
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.textSecondary)
            }

            // The line that told the books apart on the shelf keeps
            // telling this one's story here.
            Text(info.blurb)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
                .padding(.top, 2)

            OrnamentDivider()
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Continue

    private func continueCard(_ chapter: LibraryChapter) -> some View {
        Button {
            openChapter(chapter)
        } label: {
            HStack(spacing: 14) {
                AppIcon("ph-book-open-fill", size: 20)
                    .foregroundColor(AppColors.gold)

                VStack(alignment: .leading, spacing: 3) {
                    Text("CONTINUE READING")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))

                    Text(chapter.displayTitle)
                        .font(AppFonts.headlineFont(15))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                AppIcon("ph-caret-right", size: 13)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sacredCard(padding: 14)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(SacredCardButtonStyle())
    }

    // MARK: - Contents

    /// One run of chapters under one part heading — or the whole book,
    /// when its edition names no parts.
    private struct PartRun: Identifiable {
        let id: String
        let title: String?
        var chapters: [LibraryChapter]
    }

    /// Appends into the run in place rather than rebuilding it from a
    /// concatenation: the old form copied the whole accumulating array
    /// once per chapter, which is 114 copies for the Imitation.
    private static func partRuns(_ book: LibraryBook) -> [PartRun] {
        var built: [PartRun] = []
        for chapter in book.chapters {
            if let last = built.indices.last, built[last].title == chapter.part {
                built[last].chapters.append(chapter)
            } else {
                built.append(PartRun(
                    id: chapter.part ?? "part-\(built.count)",
                    title: chapter.part,
                    chapters: [chapter]
                ))
            }
        }
        return built
    }

    /// A book cut into parts folds each part behind its heading — the
    /// Imitation's 114 chapters become four doors, and only the part
    /// being read stands open on arrival. A book without parts stays a
    /// single ruled ledger. Lazy either way: an eager stack would build
    /// and measure every row before the page could draw.
    @ViewBuilder
    private var contentsLedger: some View {
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

    private func partHeader(_ run: PartRun) -> some View {
        let isOpen = expandedParts.contains(run.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isOpen {
                    expandedParts.remove(run.id)
                } else {
                    expandedParts.insert(run.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text((run.title ?? "").uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(isOpen ? 0.95 : 0.75))
                    .fixedSize()

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
            }
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(run.title ?? "Part"), \(run.chapters.count) chapters")
        .accessibilityHint(isOpen ? "Closes this part's chapters" : "Opens this part's chapters")
    }

    @ViewBuilder
    private func chapterRows(_ chapters: [LibraryChapter]) -> some View {
        ForEach(chapters) { chapter in
            chapterRow(chapter, isLast: chapter.id == chapters.last?.id)
        }
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

    private func chapterRow(_ chapter: LibraryChapter, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Button {
                openChapter(chapter)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(chapter.heading.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                        .frame(width: 82, alignment: .leading)

                    Text(chapter.title ?? chapter.heading)
                        .font(AppFonts.bodyFont(15))
                        .foregroundColor(AppColors.cream)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    AppIcon("ph-caret-right", size: 11)
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                }
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(chapter.heading). \(chapter.title ?? "")")

            if !isLast {
                Divider()
                    .background(AppColors.gold.opacity(0.15))
            }
        }
    }

    // MARK: - Listen

    private func listenLedger(_ info: LibraryBookInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Read and Listen are different acts, so the recording rows
            // stand apart in their own outlined case rather than running
            // on as more contents.
            HStack(spacing: 8) {
                AppIcon("ph-speaker-high", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.75))

                Text("LISTEN")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.75))
            }
            .padding(.bottom, 10)

            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                VStack(spacing: 0) {
                    Button {
                        toggle(section, info: info, index: index)
                    } label: {
                        HStack(spacing: 12) {
                            AppIcon(listenGlyph(section), size: 13)
                                .foregroundColor(AppColors.gold)
                                .frame(width: 20)

                            Text(section.title ?? "Track \(index + 1)")
                                .font(AppFonts.bodyFont(14))
                                .foregroundColor(AppColors.cream)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 8)

                            if let playtime = section.playtimeLabel {
                                Text(playtime)
                                    .font(AppFonts.bodyFont(11))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.vertical, 11)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(listenLabel(section, index: index))
                    .accessibilityHint(isSounding(section) ? "Pauses this track" : "Plays this track")

                    if index < sections.count - 1 {
                        Divider()
                            .background(AppColors.gold.opacity(0.15))
                    }
                }
            }
        }
    }

    /// Whether this row's track is the one in the player right now.
    /// The player keeps its URL to itself, so the page remembers which
    /// row it last handed over and pairs that with the live playing
    /// state.
    private func isSounding(_ section: LibriVoxSection) -> Bool {
        audio.isPlaying && soundingSectionID == section.id
    }

    /// Loaded and paused counts as "this row's track" too — otherwise
    /// the row that is paused looks identical to one never started, and
    /// tapping it reads as a fresh play rather than a resume.
    private func isLoaded(_ section: LibriVoxSection) -> Bool {
        soundingSectionID == section.id
    }

    private func listenGlyph(_ section: LibriVoxSection) -> String {
        if isSounding(section) { return "ph-pause-fill" }
        return isLoaded(section) ? "ph-play-fill" : "ph-play"
    }

    private func listenLabel(_ section: LibriVoxSection, index: Int) -> String {
        var label = section.title ?? "Track \(index + 1)"
        if let playtime = section.playtimeLabel { label += ", \(playtime)" }
        if isSounding(section) { label += ", now playing" }
        else if isLoaded(section) { label += ", paused" }
        return label
    }

    /// One row, one control: tap the sounding track to pause it, tap it
    /// again to resume, tap another to move there. Without the pause a
    /// recording started here could only be stopped from the Lock Screen.
    private func toggle(_ section: LibriVoxSection, info: LibraryBookInfo, index: Int) {
        if isSounding(section) {
            audio.pause()
            return
        }
        if isLoaded(section), !audio.isPlaying, audio.duration > 0 {
            audio.play()
            return
        }
        play(section, info: info, index: index)
    }

    private func play(_ section: LibriVoxSection, info: LibraryBookInfo, index: Int) {
        guard let url = section.listenURL else { return }
        soundingSectionID = section.id
        // Claim the Lock Screen arrows for this book before the load, so
        // the queue the player is about to publish is one the ⏭ actually
        // steps through. A recording is a reading, not a devotion — it
        // runs on to the next track by itself.
        armTrackNavigation(at: index, info: info)
        Task {
            await audio.loadAudio(
                from: url,
                title: section.title ?? info.title,
                subtitle: info.author,
                album: info.title,
                queueIndex: index,
                queueCount: sections.count,
                claimNowPlaying: true
            )
            audio.play()
        }
    }

    private func armTrackNavigation(at index: Int, info: LibraryBookInfo) {
        audio.setTrackNavigation(
            owner: navigationOwner,
            canGoNext: index + 1 < sections.count,
            canGoPrevious: index > 0,
            onNext: { step(from: index, by: 1, info: info) },
            onPrevious: { step(from: index, by: -1, info: info) }
        )
        audio.onTrackFinished = {
            step(from: index, by: 1, info: info)
        }
    }

    private func step(from index: Int, by offset: Int, info: LibraryBookInfo) {
        let target = index + offset
        guard sections.indices.contains(target) else { return }
        play(sections[target], info: info, index: target)
    }

    /// Leaving the page ends the reading: the recording stops, the Lock
    /// Screen player is cleared, and the audio session is handed back so
    /// other apps stop being ducked. Only if this page still owns it —
    /// a Rosary begun since must not be silenced.
    private func stopListening() {
        guard audio.isTrackNavigationOwner(navigationOwner) else { return }
        audio.onTrackFinished = nil
        audio.clearTrackNavigation(owner: navigationOwner)
        audio.reset()
        audio.deactivateSession()
        soundingSectionID = nil
    }

    // MARK: - States

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
        .padding(.bottom, 80)
    }

    private func credit(_ info: LibraryBookInfo) -> some View {
        Text(creditText(info))
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary.opacity(0.8))
            .multilineTextAlignment(.center)
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
                runs = Self.partRuns(loaded)
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

        // The recording list rides behind the text and fails silently —
        // a missing Listen section is an absence, not an error. Guarded
        // separately from the text: the two fetches fail independently,
        // and a cancelled track list must not be locked out by a text
        // load that already succeeded.
        if sections.isEmpty {
            sections = (try? await LibraryService.shared.trackList(for: info)) ?? []
        }
    }

    /// Opens a chapter, marking the departure as a push into the book
    /// so `onDisappear` leaves any recording playing.
    private func openChapter(_ chapter: LibraryChapter) {
        isOpeningChapter = true
        router.push(.libraryChapter(bookID: bookID, chapterIndex: chapter.id))
    }

    /// The place marker, fetched directly — one small row at most.
    private func loadProgress() {
        let id = bookID
        let descriptor = FetchDescriptor<BookReadingProgress>(
            predicate: #Predicate { $0.bookID == id }
        )
        progress = try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryBookView(bookID: "imitation-of-christ")
            .environment(AppRouter())
    }
}
