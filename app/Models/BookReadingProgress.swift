//
//  BookReadingProgress.swift
//  Lumen Viae
//
//  Where the reader stands in a Spiritual Reading book — one row per
//  book, created on the first chapter actually opened (never on
//  browsing), following TrueDevotionReadingProgress's shape. A place
//  marker, not a scoreboard: it powers the Continue card and nothing
//  else.
//

import Foundation
import SwiftData

@Model
final class BookReadingProgress {

    /// The catalog id of the book this row marks
    var bookID: String

    /// Index of the chapter most recently opened
    var lastChapterIndex: Int

    var updatedAt: Date

    init(bookID: String, lastChapterIndex: Int, updatedAt: Date = Date()) {
        self.bookID = bookID
        self.lastChapterIndex = lastChapterIndex
        self.updatedAt = updatedAt
    }
}
