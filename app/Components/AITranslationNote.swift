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
        } else if LibraryContent.consecrationSpanish.prayerByID[prayerID] != nil {
            flagged = ConsecrationSpanish.prayerIsAITranslated(prayerID)
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

/// The same line under any Spanish text that is the team's own
/// translation: a consecration day's reading, its title and journal
/// question. Nothing when `shows` is false, or in English.
struct AINote: View {
    let shows: Bool

    var body: some View {
        if shows, SpanishContent.isActive {
            Text(AITranslationNote.line)
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }
}

/// The small lines under a meditation read in Spanish: the AI line when
/// its Spanish is the team's own translation, and, where it can be heard,
/// that the voice reads it in English (the recordings are English in every
/// language). Nothing under an English meditation.
struct MeditationLanguageNote: View {
    let meditation: Meditation?

    var body: some View {
        let lines = Self.lines(for: meditation)
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 6)
        }
    }

    /// What the meditation owes beneath it, in order
    static func lines(for meditation: Meditation?) -> [String] {
        guard let meditation, meditation.isSpanish else { return [] }
        var lines: [String] = []
        if meditation.aiTranslated { lines.append(AITranslationNote.line) }
        if meditation.hasAudio { lines.append(voiceLine) }
        return lines
    }

    static var voiceLine: String {
        String(
            localized: "The voice reads the meditation in English.",
            comment: "Shown only in Spanish, under a meditation shown in Spanish: its recording is in English"
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
