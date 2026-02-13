//
//  JournalEntry.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  JOURNAL ENTRY - SWIFTDATA MODEL FOR PRAYER REFLECTIONS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Stores personal reflections written during or after a Rosary session.
//  Entries can be tied to a specific mystery (mid-prayer note) or to
//  the overall session (post-prayer reflection).
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftData

@Model
final class JournalEntry {

    // MARK: - Properties

    var id: UUID

    /// The written reflection
    var text: String

    /// When this entry was created
    var createdAt: Date

    /// The mystery category (e.g., "joyful", "sorrowful")
    var categoryRaw: String?

    /// The mystery title this entry relates to (e.g., "The Annunciation")
    /// nil means this is a general post-session reflection
    var mysteryTitle: String?

    /// The mystery index within its set (0-4), nil for general reflections
    var mysteryIndex: Int?

    /// Whether this was written mid-prayer (true) or post-prayer (false)
    var isMidPrayer: Bool

    // MARK: - Computed Properties

    var category: MysteryCategory? {
        guard let raw = categoryRaw else { return nil }
        return MysteryCategory(rawValue: raw)
    }

    /// Display label — specific mystery title or category name
    var subjectLabel: String {
        if let title = mysteryTitle, !title.isEmpty {
            return title
        }
        return category?.displayName ?? "General Reflection"
    }

    /// Icon name for the mystery category
    var categoryIcon: String {
        switch category {
        case .joyful:      return "sun.max.fill"
        case .sorrowful:   return "cloud.rain.fill"
        case .glorious:    return "sparkles"
        case .luminous:    return "rays"
        case .none:        return "book.fill"
        }
    }

    // MARK: - Init

    init(
        text: String = "",
        category: MysteryCategory? = nil,
        mysteryTitle: String? = nil,
        mysteryIndex: Int? = nil,
        isMidPrayer: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.categoryRaw = category?.rawValue
        self.mysteryTitle = mysteryTitle
        self.mysteryIndex = mysteryIndex
        self.isMidPrayer = isMidPrayer
        self.createdAt = createdAt
    }
}
