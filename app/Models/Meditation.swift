//
//  Meditation.swift
//  Lumen Viae
//
//  Meditation content for a single mystery, nested in the MeditationSet
//  API response. Each mystery can have multiple meditation styles
//  (Traditional, St. Louis de Montfort, Scriptural, etc.).
//

import Foundation

/// Meditation text for a specific mystery, with optional guided audio.
struct Meditation: Codable, Identifiable, Hashable {

    // MARK: - Properties

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

    enum CodingKeys: String, CodingKey {
        case id, title, content, author, source, mystery
        case audioUrl = "audio_url"
    }

    // MARK: - Computed Properties

    /// Title for display, with fallback chain: title → mystery name → "Meditation"
    var displayTitle: String {
        title ?? mystery?.name ?? "Meditation"
    }

    /// Whether this meditation has a non-empty audio URL
    var hasAudio: Bool {
        guard let url = audioUrl else { return false }
        return !url.isEmpty
    }
}
