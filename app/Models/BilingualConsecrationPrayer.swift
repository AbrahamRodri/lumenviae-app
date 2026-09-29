//
//  BilingualConsecrationPrayer.swift
//  Lumen Viae
//
//  A consecration prayer stored once with both English and Latin versions.
//

import Foundation
import SwiftUI

// MARK: - BilingualConsecrationPrayer

/// A consecration prayer with bilingual content
struct BilingualConsecrationPrayer: Identifiable {

    // MARK: - Properties

    /// Unique identifier (e.g., "veni_creator", "magnificat")
    let id: String

    /// English title
    let englishTitle: String

    /// Latin title
    let latinTitle: String

    /// Bilingual prayer content
    let content: BilingualText

    // MARK: - Initializer

    init(
        id: String,
        englishTitle: String,
        latinTitle: String,
        englishContent: String,
        latinContent: String
    ) {
        self.id = id
        self.englishTitle = englishTitle
        self.latinTitle = latinTitle
        self.content = BilingualText(
            english: englishContent,
            latin: latinContent
        )
    }

    // MARK: - Computed Properties

    /// Get display title based on language preference
    func displayTitle(for language: PrayerLanguage) -> String {
        switch language {
        case .english, .latinUnderEnglish:
            return englishTitle
        case .latin, .both:
            return latinTitle
        }
    }

    /// Get formatted content based on language preference
    func formattedContent(for language: PrayerLanguage) -> String {
        content.formatted(for: language)
    }

    /// Convert to legacy ConsecrationPrayer for backward compatibility
    func toConsecrationPrayer(for language: PrayerLanguage) -> ConsecrationPrayer {
        ConsecrationPrayer(
            id: id,
            title: displayTitle(for: language),
            latinTitle: latinTitle,
            content: formattedContent(for: language)
        )
    }
}
