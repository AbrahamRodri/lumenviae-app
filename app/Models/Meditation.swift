//
//  Meditation.swift
//  app
//
//  Represents meditation content within a meditation set.
//  Nested in MeditationSet detail response.
//

import Foundation

/// Individual meditation content for a mystery
struct Meditation: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?  // API can return null
    let content: String
    let author: String?
    let source: String?
    let audioUrl: String?
    let mystery: Mystery?

    enum CodingKeys: String, CodingKey {
        case id, title, content, author, source, mystery
        case audioUrl = "audio_url"
    }

    /// Display title (falls back to mystery name if title is nil)
    var displayTitle: String {
        title ?? mystery?.name ?? "Meditation"
    }

    /// Whether this meditation has audio available
    var hasAudio: Bool {
        audioUrl != nil && !audioUrl!.isEmpty
    }
}
