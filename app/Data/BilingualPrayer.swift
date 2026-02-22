//
//  BilingualPrayer.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  BILINGUAL PRAYER MODEL
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A reusable model for storing prayers in multiple languages efficiently.
//  Each prayer is stored once with both translations, and the display format
//  is generated dynamically based on user language preference.
//
//  ═══════════════════════════════════════════════════════════════════════════

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
            } else if secondaryTrimmed.isEmpty {
                // Only secondary is empty - use primary only
                result.append(primaryTrimmed)
            } else {
                // Both have content - combine with separator
                result.append("\(primaryTrimmed)|||\(secondaryTrimmed)")
            }
        }

        return result.joined(separator: "\n")
    }
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
