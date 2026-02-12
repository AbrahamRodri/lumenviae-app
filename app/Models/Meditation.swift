//
//  Meditation.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  MEDITATION MODEL - CONTENT FOR A SINGLE MYSTERY
//  ═══════════════════════════════════════════════════════════════════════════
//
//  A Meditation contains the actual text content that users read/listen to
//  while praying a specific mystery. Each mystery can have multiple
//  meditation styles (Traditional, St. Louis de Montfort, Scriptural, etc.).
//
//  ## Relationship to Other Models
//  ```
//  MeditationSet (e.g., "Traditional Meditations for Joyful")
//      └── meditations: [Meditation]
//              └── mystery: Mystery (e.g., "The Annunciation")
//  ```
//
//  ## Example API Response (nested in MeditationSet)
//  ```json
//  {
//    "id": 1,
//    "title": "The Annunciation",
//    "content": "Consider the humility of Mary...",
//    "author": "Traditional",
//    "source": null,
//    "audio_url": "https://example.com/annunciation.mp3",
//    "mystery": { ... }
//  }
//  ```
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - Meditation

/// Individual meditation content for a specific mystery.
///
/// Contains the text content users read during prayer, plus optional
/// audio URL for guided meditation playback.
struct Meditation: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: Int

    /// Optional title (falls back to mystery name if nil)
    let title: String?

    /// The meditation text content
    let content: String

    /// Author or source attribution (e.g., "St. Louis de Montfort")
    let author: String?

    /// Source reference if applicable
    let source: String?

    /// URL for audio version of this meditation
    let audioUrl: String?

    /// The mystery this meditation belongs to (includes name, scripture, etc.)
    let mystery: Mystery?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id, title, content, author, source, mystery
        case audioUrl = "audio_url"
    }

    // MARK: - Computed Properties

    /// Title for display, with fallback chain: title → mystery name → "Meditation"
    var displayTitle: String {
        title ?? mystery?.name ?? "Meditation"
    }

    /// Whether this meditation has an audio version available.
    ///
    /// Checks both that audioUrl exists AND is not empty string.
    var hasAudio: Bool {
        guard let url = audioUrl else { return false }
        return !url.isEmpty
    }
}
