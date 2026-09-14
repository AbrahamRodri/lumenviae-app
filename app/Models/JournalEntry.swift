//
//  JournalEntry.swift
//  Lumen Viae
//
//  SwiftData model for prayer reflections. Rosary entries are tied to a
//  mystery category/mystery; consecration entries to a day (1-34) and phase.
//

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

    // MARK: - Reading Properties

    /// The library book a kept passage came from ("story-of-a-soul",
    /// "true-devotion"), so a book page can gather its own notes.
    /// Nil for every entry that is not a note on a passage.
    var bookID: String?

    /// The passage as the book set it, and the citation it carries.
    ///
    /// Held as fields rather than read back out of `text`. The three
    /// parts are composed into `text` so the entry reads as one
    /// reflection in the journal — but `text` is also what
    /// `JournalEntryEditorView` hands the reader to edit, and an entry
    /// re-parsed by splitting on blank lines lost its shape the moment
    /// anyone touched it: the citation would render as the reader's own
    /// comment, or a passage carrying a blank line would shift every
    /// part along by one.
    var bookPassage: String?
    var bookCitation: String?

    // MARK: - Consecration Properties

    /// The consecration day number (1-34), nil for rosary entries
    var consecrationDay: Int?

    /// The consecration phase raw value, nil for rosary entries
    var consecrationPhaseRaw: String?

    /// Which consecration this reflection belongs to.
    ///
    /// Without it, a day number alone identified an entry — so a second
    /// consecration opened Day 5 onto the *first* one's reflection and
    /// overwrote it on save. Optional because entries written before this
    /// existed carry no id; `ConsecrationViewModel` backfills them once,
    /// matching each to the consecration whose 34-day window it falls in.
    var consecrationId: UUID?

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

    /// Icon name for the entry type. Categories defer to
    /// `MysteryCategory.iconName` so the journal never shows a different
    /// icon for a category than the rest of the app; the Marian monogram
    /// is the consecration symbol app-wide (tab, home, milestones).
    var categoryIcon: String {
        if isConsecrationEntry {
            return "ch-consecration-fill"
        }
        return category?.iconName ?? "ph-book"
    }

    // MARK: - Init (Rosary)

    init(
        text: String = "",
        category: MysteryCategory? = nil,
        mysteryTitle: String? = nil,
        mysteryIndex: Int? = nil,
        isMidPrayer: Bool = false,
        bookID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.entryTypeRaw = JournalEntryType.rosary.rawValue
        self.categoryRaw = category?.rawValue
        self.mysteryTitle = mysteryTitle
        self.mysteryIndex = mysteryIndex
        self.isMidPrayer = isMidPrayer
        self.bookID = bookID
        self.createdAt = createdAt
        self.consecrationDay = nil
        self.consecrationPhaseRaw = nil
    }

    // MARK: - Init (A page kept from a book)

    /// A passage kept from the shelf or from True Devotion.
    ///
    /// The parts are held as fields *and* composed into `text`: `text`
    /// is what the journal shows and what the editor lets the reader
    /// rewrite, while the fields are what a book page reads back, so
    /// editing the reflection can never scramble the passage or hand
    /// the citation to the wrong slot.
    static func note(
        passage: String,
        citation: String,
        comment: String = "",
        subject: String,
        bookID: String
    ) -> JournalEntry {
        var text = "\u{201C}\(passage)\u{201D}"
        if !citation.isEmpty { text += "\n\n\(citation)" }
        let body = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty { text += "\n\n\(body)" }

        let entry = JournalEntry(
            text: text,
            mysteryTitle: subject,
            bookID: bookID
        )
        entry.bookPassage = passage
        entry.bookCitation = citation.isEmpty ? nil : citation
        return entry
    }

    // MARK: - Init (Consecration)

    init(
        text: String,
        consecrationDay: Int,
        consecrationPhase: ConsecrationPhase,
        consecrationId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.entryTypeRaw = JournalEntryType.consecration.rawValue
        self.consecrationDay = consecrationDay
        self.consecrationPhaseRaw = consecrationPhase.rawValue
        self.consecrationId = consecrationId
        self.createdAt = createdAt
        // Rosary fields
        self.categoryRaw = nil
        self.mysteryTitle = nil
        self.mysteryIndex = nil
        self.isMidPrayer = false
    }
}


// MARK: - A page kept from a book, taken apart again

/// A kept passage as the page sets it: the passage, its citation, and
/// whatever the reader added — three parts, drawn three ways.
struct KeptPassage {
    let passage: String

    /// "St. Louis de Montfort, True Devotion…, Chapter I" — the stored
    /// citation without its leading dash and its rights note, which
    /// belong on a share card and not on a journal page
    let citation: String?

    /// The reader's own words, possibly none
    let comment: String
}

extension JournalEntry {

    /// The entry as a kept passage, or nil for an entry that is not one
    /// — or one whose passage the reader has since rewritten in the
    /// editor, which is then shown as they left it. The passage and
    /// citation come from their own fields; the comment is what remains
    /// of `text` once the composed parts are lifted out of it.
    var keptPassage: KeptPassage? {
        guard let stored = bookPassage else { return nil }
        let passage = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !passage.isEmpty else { return nil }

        // `note` composed the text from the passage exactly as it was
        // kept, whitespace and all, so that is tried before the trimmed
        // form — trimmed alone, a passage kept with a trailing newline
        // never matched and lost its quotation
        var rest = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let openings = [stored, passage].flatMap { ["\u{201C}\($0)\u{201D}", $0] }
        guard let opening = openings.first(where: { rest.hasPrefix($0) }) else { return nil }
        rest.removeFirst(opening.count)

        // The citation is set apart only while it still stands in the
        // text as it was kept. One the reader has since edited stays in
        // their words as they left it, rather than being printed twice
        var citation: String?
        if let storedCitation = bookCitation?.trimmingCharacters(in: .whitespacesAndNewlines),
           !storedCitation.isEmpty,
           let range = rest.range(of: storedCitation) {
            rest.removeSubrange(range)
            citation = Self.pageCitation(storedCitation)
        }

        return KeptPassage(
            passage: passage,
            citation: citation,
            comment: rest.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// The citation as the page prints it. The reader's keep composes
    /// "— Author, Title, Chapter (trans. X). Public domain." for the
    /// share card; on the page the dash is drawn by the block and the
    /// rights note is nobody's reflection.
    private static func pageCitation(_ stored: String) -> String? {
        var line = Substring(stored)
        while let first = line.first, "—–- ".contains(first) {
            line = line.dropFirst()
        }
        if let range = line.range(of: "Public domain.", options: [.backwards, .caseInsensitive]) {
            line = line[..<range.lowerBound]
        }
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
