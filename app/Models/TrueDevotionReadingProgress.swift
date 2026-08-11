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
}
