//
//  BilingualPrayer.swift
//  Lumen Viae
//
//  Reusable model for prayers stored with both translations; display format
//  is generated from the user's language preference.
//

import Foundation
import SwiftUI

// MARK: - BilingualText

/// Represents text content available in multiple languages
struct BilingualText {
    let english: String
    let latin: String

    /// Get the text content for a specific language preference
    /// - Parameter language: The user's prayer language preference
    /// - Returns: Formatted text with ||| separator for bilingual modes, or single language text
    func formatted(for language: PrayerLanguage) -> String {
        switch language {
        case .english:
            return english
        case .latin:
            return latin
        case .both:
            // Latin & English: Latin first, then English
            return formatBilingual(primary: latin, secondary: english)
        case .latinUnderEnglish:
            // English & Latin: English first, then Latin
            return formatBilingual(primary: english, secondary: latin)
        }
    }

    /// Format text for bilingual display using ||| separator
    private func formatBilingual(primary: String, secondary: String) -> String {
        let primaryLines = primary.components(separatedBy: "\n")
        let secondaryLines = secondary.components(separatedBy: "\n")

        // Ensure both have the same number of lines
        guard primaryLines.count == secondaryLines.count else {
            // Fallback: if line counts don't match, show both languages in blocks
            // This is safer than just showing primary and losing the translation
            return primary + "\n\n" + secondary
        }

        // Combine line-by-line with ||| separator
        var result: [String] = []
        for (primaryLine, secondaryLine) in zip(primaryLines, secondaryLines) {
            let primaryTrimmed = primaryLine.trimmingCharacters(in: .whitespaces)
            let secondaryTrimmed = secondaryLine.trimmingCharacters(in: .whitespaces)

            if primaryTrimmed.isEmpty && secondaryTrimmed.isEmpty {
                // Both empty - add blank line for spacing
                result.append("")
            } else if primaryTrimmed.isEmpty {
                // Only primary is empty - skip this line pair
                continue
            } else if secondaryTrimmed.isEmpty
                        || primaryTrimmed.caseInsensitiveCompare(secondaryTrimmed) == .orderedSame {
                // Only secondary is empty, or the two are the same word —
                // "Amen." under "Amen." — so the line stands alone
                result.append(primaryTrimmed)
            } else {
                // Both have content - combine with separator
                result.append("\(primaryTrimmed)|||\(secondaryTrimmed)")
            }
        }

        return result.joined(separator: "\n")
    }
}

extension BilingualText {
    /// One language's text as a single paragraph, its lines joined — for a
    /// screen that sets a prayer as one block rather than line by line.
    /// Latin when Latin alone is chosen, English otherwise.
    func paragraph(in language: PrayerLanguage) -> String {
        let source = language == .latin ? latin : english
        return source
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - The Rosary's Prayers

/// The prayers of the beads that more than one screen sets out — How to
/// Pray's cards, and the Scriptural Rosary's closing bead — kept once so
/// the two never say them differently. The lines break where How to Pray
/// breaks them; a screen that sets a prayer as one block joins them
/// (`BilingualText.paragraph(in:)`).
enum RosaryPrayerText {

    static let gloryBe = BilingualText(
        english: """
Glory be to the Father, and to the Son, and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be,
world without end. Amen.
""",
        latin: """
Gloria Patri, et Filio, et Spiritui Sancto.
Sicut erat in principio, et nunc, et semper,
et in saecula saeculorum. Amen.
"""
    )

    /// Said after the Glory Be of every decade, as Our Lady asked at Fatima
    static let fatimaPrayer = BilingualText(
        english: """
O my Jesus, forgive us our sins,
save us from the fires of hell,
and lead all souls to heaven,
especially those in most need of Thy mercy. Amen.
""",
        latin: """
Domine Iesu, dimitte nobis debita nostra,
salva nos ab igne inferiori,
perduc in caelum omnes animas,
praesertim eas, quae misericordiae tuae maxime indigent. Amen.
"""
    )
}

// MARK: - BilingualPrayer

/// A prayer with bilingual content
struct BilingualPrayer: Identifiable {
    let id = UUID()
    let title: String
    let content: BilingualText

    /// Get formatted content for display based on language preference
    func formattedContent(for language: PrayerLanguage) -> String {
        content.formatted(for: language)
    }
}

// MARK: - BilingualSection

/// A section containing multiple bilingual prayers or items
struct BilingualSection: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let items: [BilingualPrayer]

    init(title: String, icon: String, items: [BilingualPrayer], id: UUID = UUID()) {
        self.id = id
        self.title = title
        self.icon = icon
        self.items = items
    }

    /// Convert to DevotionSection for display
    /// Note: Uses a stable ID derived from this section's ID to ensure consistent identity across renders
    func toDevotionSection(for language: PrayerLanguage) -> DevotionSection {
        DevotionSection(
            id: self.id, // Use the same ID so expanded state persists
            title: title,
            icon: icon,
            items: items.map { prayer in
                DevotionItem(
                    title: prayer.title,
                    content: prayer.formattedContent(for: language)
                )
            }
        )
    }
}
