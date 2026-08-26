//
//  TrueDevotionReaderViewModel.swift
//  Lumen Viae
//
//  Owns the user's place in True Devotion: which chapters are finished and
//  the paragraph they last had at the top of the screen.
//
//  All SwiftData access for the reader lives here. The views used to fetch
//  and save inline, which meant scroll callbacks raced the query that told
//  them whether a progress record already existed — on a fast flick they
//  could each insert one. Holding the record once removes that class of bug,
//  and keeps the parsed completed-chapter set in memory so drawing the
//  contents list doesn't re-split a stored string for every row.
//

import Foundation
import SwiftData

@Observable
final class TrueDevotionReaderViewModel {

    // MARK: - Published State

    /// Chapters the user has finished, parsed once and kept in memory
    private(set) var completedChapterIDs: Set<String> = []

    /// The chapter the user last had open
    private(set) var lastChapterID: String?

    /// Paragraph index last at the top of that chapter
    private(set) var lastParagraphIndex: Int = 0

    /// The ribbons laid in this book — a mark is a place, nothing
    /// written. Parsed once and kept in memory like the completed set.
    private(set) var marks: [(chapterID: String, paragraph: Int)] = []

    /// Surfaced to the reader rather than dropped — losing someone's place in
    /// a book they are praying through should never fail quietly.
    var errorMessage: String?

    // MARK: - Private Properties

    private var modelContext: ModelContext?

    /// The single progress record, fetched once and held for the session
    private var progress: TrueDevotionReadingProgress?

    // MARK: - Initialization

    init() {}

    // MARK: - Model Context

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Loading

    func loadProgress() {
        guard let modelContext else { return }

        var descriptor = FetchDescriptor<TrueDevotionReadingProgress>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            progress = try modelContext.fetch(descriptor).first
            refreshPublishedState()
        } catch {
            errorMessage = "Could not load your reading progress: \(error.localizedDescription)"
        }
    }

    private func refreshPublishedState() {
        completedChapterIDs = progress?.completedChapterIDs ?? []
        lastChapterID = progress?.lastChapterID
        lastParagraphIndex = progress?.lastParagraphIndex ?? 0
        marks = progress?.marks ?? []
    }

    /// The record, created on first write. Never called from a read path, so
    /// merely opening the book doesn't leave a row behind.
    private func ensureProgress() -> TrueDevotionReadingProgress? {
        if let progress { return progress }
        guard let modelContext else { return nil }
        let record = TrueDevotionReadingProgress()
        modelContext.insert(record)
        progress = record
        return record
    }

    // MARK: - Reading State

    var hasStartedReading: Bool {
        lastChapterID != nil || !completedChapterIDs.isEmpty
    }

    func isCompleted(_ chapterID: String) -> Bool {
        completedChapterIDs.contains(chapterID)
    }

    /// Genuinely part-way through — a chapter merely opened at the top has
    /// nothing to resume and reads as unstarted.
    func isInProgress(_ chapterID: String) -> Bool {
        !isCompleted(chapterID) && lastChapterID == chapterID && lastParagraphIndex > 0
    }

    func completedCount(of book: TrueDevotionBook) -> Int {
        book.chapters.reduce(0) { $0 + (completedChapterIDs.contains($1.id) ? 1 : 0) }
    }

    func progressPercentage(of book: TrueDevotionBook) -> Double {
        guard !book.chapters.isEmpty else { return 0 }
        return Double(completedCount(of: book)) / Double(book.chapters.count)
    }

    /// The chapter the continue card resumes: the one last opened if it is
    /// unfinished, otherwise the first unfinished chapter.
    func continueChapter(in book: TrueDevotionBook) -> TrueDevotionChapter? {
        guard hasStartedReading else { return nil }
        if let lastChapterID,
           !isCompleted(lastChapterID),
           let chapter = book.chapter(id: lastChapterID) {
            return chapter
        }
        return book.chapters.first { !isCompleted($0.id) }
    }

    /// Where to open a chapter, or nil to start at the beginning.
    func resumeParagraph(for chapterID: String) -> Int? {
        guard lastChapterID == chapterID,
              lastParagraphIndex > 0,
              !isCompleted(chapterID) else { return nil }
        return lastParagraphIndex
    }

    // MARK: - Recording

    /// Remembers the paragraph at the top of the screen. Index 0 is the top of
    /// the chapter, which is a real position: someone who scrolls back to the
    /// beginning should find it there next time, not where they had been.
    func recordPosition(chapterID: String, paragraphIndex: Int) {
        guard !isCompleted(chapterID) else { return }
        guard let record = ensureProgress() else { return }
        record.savePosition(chapterID: chapterID, paragraphIndex: max(paragraphIndex, 0))
        refreshPublishedState()
    }

    // MARK: - Marks

    func isMarked(chapterID: String, paragraph: Int) -> Bool {
        marks.contains { $0.chapterID == chapterID && $0.paragraph == paragraph }
    }

    func markCount(forChapter chapterID: String) -> Int {
        marks.filter { $0.chapterID == chapterID }.count
    }

    /// Lays a ribbon, or lifts the one already there. Returns whether
    /// the paragraph is marked afterwards.
    @discardableResult
    func toggleMark(chapterID: String, paragraph: Int) -> Bool {
        guard let record = ensureProgress() else { return false }
        let nowMarked = record.toggleMark(chapterID: chapterID, paragraph: paragraph)
        refreshPublishedState()
        save()
        return nowMarked
    }

    func completeChapter(_ chapterID: String) {
        guard let record = ensureProgress() else { return }
        record.markChapterCompleted(chapterID)
        record.savePosition(chapterID: chapterID, paragraphIndex: 0)
        refreshPublishedState()
        save()
    }

    /// Persists pending position changes; called when a chapter is left.
    func save() {
        guard let modelContext, modelContext.hasChanges else { return }
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Your place in the book could not be saved: \(error.localizedDescription)"
        }
    }
}
