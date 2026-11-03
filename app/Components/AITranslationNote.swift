//
//  AITranslationNote.swift
//  app
//
//  The small line under a Spanish prayer whose Spanish is partly the
//  team's own (AI) translation rather than a published text (the api's
//  `ai_translated`, today the Seven Sorrows closing prayer). Spanish only:
//  English never draws it.
//

import SwiftUI

struct AITranslationNote: View {
    let prayerID: String

    var body: some View {
        if let note = Self.note(for: prayerID) {
            Text(note)
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }

    /// The line, when the prayer owes it in this language
    static func note(for prayerID: String, spanish: Bool = SpanishContent.isActive) -> String? {
        guard spanish else { return nil }
        let flagged: Bool
        if let book = LibraryContent.prayerBookSpanish[prayerID] {
            flagged = book.aiTranslated == true
        } else {
            flagged = SpanishContent.prayers[prayerID]?.aiTranslated == true
        }
        guard flagged else { return nil }
        return line
    }

    /// The words of the line, which a saint's quotation translated with
    /// AI wears too (`RosaryQuote.aiTranslated`)
    static var line: String {
        String(
            localized: "Translation made with artificial intelligence.",
            comment: "Shown only in Spanish, under a prayer whose Spanish was partly translated with AI (the Seven Sorrows closing prayer)"
        )
    }
}

/// The line under a saint's quotation whose Spanish is the team's own
/// translation: the same words and face as under a prayer
struct AIQuoteNote: View {
    let shows: Bool

    var body: some View {
        if shows {
            Text(AITranslationNote.line)
                .font(AppFonts.italicFont(11))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
