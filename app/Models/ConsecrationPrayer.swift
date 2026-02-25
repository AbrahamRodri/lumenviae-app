//
//  ConsecrationPrayer.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION PRAYER - REPRESENTS A PRAYER IN THE 33-DAY CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Each phase of the consecration has its own set of prayers that are recited
//  daily. This model represents a single prayer such as:
//  - Veni Creator
//  - Ave Maris Stella
//  - Magnificat
//  - Litany of the Holy Ghost
//  - Litany of Loreto
//  - Etc.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - ConsecrationPrayer

/// A single prayer used in the 33-Day Consecration.
///
/// Each prayer includes:
/// - Title (English and optional Latin)
/// - Full prayer text
/// - Optional audio URL for guided prayer
///
struct ConsecrationPrayer: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the prayer (e.g., "veni_creator", "magnificat")
    let id: String

    /// English title of the prayer (e.g., "Come, Creator Spirit")
    let title: String

    /// Latin title if applicable (e.g., "Veni Creator Spiritus")
    let latinTitle: String?

    /// Full text of the prayer
    /// Note: Placeholder content for now - will be populated with actual prayers
    let content: String

    /// URL for audio recording of the prayer (optional)
    let audioUrl: String?

    /// Whether this prayer has a chant audio recording available via the API
    let hasChantAudio: Bool

    // MARK: - Initializer

    init(
        id: String,
        title: String,
        latinTitle: String? = nil,
        content: String,
        audioUrl: String? = nil,
        hasChantAudio: Bool = false
    ) {
        self.id = id
        self.title = title
        self.latinTitle = latinTitle
        self.content = content
        self.audioUrl = audioUrl
        self.hasChantAudio = hasChantAudio
    }

    // MARK: - Computed Properties

    /// Display title - uses Latin title if available, otherwise English
    var displayTitle: String {
        latinTitle ?? title
    }

    /// Whether this prayer has audio available
    var hasAudio: Bool {
        audioUrl != nil || hasChantAudio
    }
}
