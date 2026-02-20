//
//  JournalEntry.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  JOURNAL ENTRY - SWIFTDATA MODEL FOR PRAYER REFLECTIONS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Stores personal reflections written during or after prayer sessions.
//  Supports both Rosary and 33-Day Consecration entries.
//
//  Entry Types:
//  - Rosary: Tied to mystery category and specific mystery
//  - Consecration: Tied to consecration day (1-34) and phase
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftData

// MARK: - JournalEntryType

/// The type of journal entry
enum JournalEntryType: String, Codable {
    case rosary
    case consecration
}

@Model
final class JournalEntry {

    // MARK: - Properties

    var id: UUID

    /// The written reflection
    var text: String

    /// When this entry was created
    var createdAt: Date

    /// The type of entry (rosary or consecration)
    var entryTypeRaw: String

    // MARK: - Rosary Properties

    /// The mystery category (e.g., "joyful", "sorrowful")
    var categoryRaw: String?

    /// The mystery title this entry relates to (e.g., "The Annunciation")
    /// nil means this is a general post-session reflection
    var mysteryTitle: String?

    /// The mystery index within its set (0-4), nil for general reflections
    var mysteryIndex: Int?

    /// Whether this was written mid-prayer (true) or post-prayer (false)
    var isMidPrayer: Bool

    // MARK: - Consecration Properties

    /// The consecration day number (1-34), nil for rosary entries
    var consecrationDay: Int?

    /// The consecration phase raw value, nil for rosary entries
    var consecrationPhaseRaw: String?

    // MARK: - Computed Properties

    /// The entry type
    var entryType: JournalEntryType {
        JournalEntryType(rawValue: entryTypeRaw) ?? .rosary
    }

    /// Whether this is a consecration entry
    var isConsecrationEntry: Bool {
        entryType == .consecration
    }

    var category: MysteryCategory? {
        guard let raw = categoryRaw else { return nil }
        return MysteryCategory(rawValue: raw)
    }

    /// The consecration phase for consecration entries
    var consecrationPhase: ConsecrationPhase? {
        guard let raw = consecrationPhaseRaw else { return nil }
        return ConsecrationPhase(rawValue: raw)
    }

    /// Display label — specific mystery title, consecration day, or category name
    var subjectLabel: String {
        if isConsecrationEntry {
            if let day = consecrationDay {
                if day == 34 {
                    return "Consecration Day"
                }
                return "Day \(day)"
            }
            return "Consecration"
        }
        if let title = mysteryTitle, !title.isEmpty {
            return title
        }
        return category?.displayName ?? "General Reflection"
    }

    /// Secondary label for additional context
    var secondaryLabel: String? {
        if isConsecrationEntry {
            return consecrationPhase?.displayName
        }
        return nil
    }

    /// Icon name for the entry type
    var categoryIcon: String {
        if isConsecrationEntry {
            return "flame.fill"
        }
        switch category {
        case .joyful:      return "sun.max.fill"
        case .sorrowful:   return "cloud.rain.fill"
        case .glorious:    return "sparkles"
        case .luminous:    return "rays"
        case .none:        return "book.fill"
        }
    }

    // MARK: - Init (Rosary)

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
        self.entryTypeRaw = JournalEntryType.rosary.rawValue
        self.categoryRaw = category?.rawValue
        self.mysteryTitle = mysteryTitle
        self.mysteryIndex = mysteryIndex
        self.isMidPrayer = isMidPrayer
        self.createdAt = createdAt
        self.consecrationDay = nil
        self.consecrationPhaseRaw = nil
    }

    // MARK: - Init (Consecration)

    init(
        text: String,
        consecrationDay: Int,
        consecrationPhase: ConsecrationPhase,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.entryTypeRaw = JournalEntryType.consecration.rawValue
        self.consecrationDay = consecrationDay
        self.consecrationPhaseRaw = consecrationPhase.rawValue
        self.createdAt = createdAt
        // Rosary fields
        self.categoryRaw = nil
        self.mysteryTitle = nil
        self.mysteryIndex = nil
        self.isMidPrayer = false
    }
}
