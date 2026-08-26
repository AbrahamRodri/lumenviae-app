//
//  TrueDevotionReadingProgress.swift
//  Lumen Viae
//
//  SwiftData model tracking the user's place in the full text of
//  True Devotion: which chapters are finished and the exact paragraph
//  they last had at the top of the screen, so reading resumes mid-chapter.
//

import Foundation
import SwiftData

@Model
final class TrueDevotionReadingProgress {

    // MARK: - Properties

    var id: UUID

    /// Chapter ids the user has finished, comma-separated (same storage
    /// pattern as ConsecrationProgress.completedDaysRaw)
    var completedChapterIDsRaw: String

    /// The chapter the user last had open
    var lastChapterID: String?

    /// Index of the paragraph last at the top of the screen in that chapter
    var lastParagraphIndex: Int

    /// The reader's marks — a ribbon laid on a paragraph, several per
    /// chapter. Stored as "chapterID:paragraph" pairs, comma-separated,
    /// the same flat storage the completed set uses. The chapter ids are
    /// stable slugs, so unlike the shelf's parsed indices these never
    /// need retiring.
    var marksRaw: String = ""

    var updatedAt: Date

    // MARK: - Computed Properties

    var completedChapterIDs: Set<String> {
        get {
            guard !completedChapterIDsRaw.isEmpty else { return [] }
            return Set(completedChapterIDsRaw.split(separator: ",").map(String.init))
        }
        set {
            completedChapterIDsRaw = newValue.sorted().joined(separator: ",")
        }
    }

    var hasStartedReading: Bool {
        lastChapterID != nil || !completedChapterIDsRaw.isEmpty
    }

    // MARK: - Initialization

    init() {
        self.id = UUID()
        self.completedChapterIDsRaw = ""
        self.lastChapterID = nil
        self.lastParagraphIndex = 0
        self.updatedAt = Date()
    }

    // MARK: - Methods

    func isChapterCompleted(_ chapterID: String) -> Bool {
        completedChapterIDs.contains(chapterID)
    }

    func markChapterCompleted(_ chapterID: String) {
        var ids = completedChapterIDs
        ids.insert(chapterID)
        completedChapterIDs = ids
        updatedAt = Date()
    }

    func savePosition(chapterID: String, paragraphIndex: Int) {
        lastChapterID = chapterID
        lastParagraphIndex = paragraphIndex
        updatedAt = Date()
    }

    // MARK: - Marks

    /// The marked paragraphs, in the order they were laid.
    var marks: [(chapterID: String, paragraph: Int)] {
        guard !marksRaw.isEmpty else { return [] }
        return marksRaw.split(separator: ",").compactMap { pair in
            guard let colon = pair.lastIndex(of: ":"),
                  let paragraph = Int(pair[pair.index(after: colon)...]) else { return nil }
            return (String(pair[..<colon]), paragraph)
        }
    }

    func isMarked(chapterID: String, paragraph: Int) -> Bool {
        marks.contains { $0.chapterID == chapterID && $0.paragraph == paragraph }
    }

    /// Lays a ribbon, or lifts the one already there. Returns whether
    /// the paragraph is marked afterwards.
    @discardableResult
    func toggleMark(chapterID: String, paragraph: Int) -> Bool {
        var all = marks
        let nowMarked: Bool
        if let index = all.firstIndex(where: {
            $0.chapterID == chapterID && $0.paragraph == paragraph
        }) {
            all.remove(at: index)
            nowMarked = false
        } else {
            all.append((chapterID, paragraph))
            nowMarked = true
        }
        marksRaw = all.map { "\($0.chapterID):\($0.paragraph)" }.joined(separator: ",")
        updatedAt = Date()
        return nowMarked
    }
}
