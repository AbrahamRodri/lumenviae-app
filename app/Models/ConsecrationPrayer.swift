//
//  ConsecrationPrayer.swift
//  Lumen Viae
//
//  A single prayer recited daily within a consecration phase,
//  e.g. Veni Creator, Ave Maris Stella, Magnificat, the litanies.
//

import Foundation

struct ConsecrationPrayer: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the prayer (e.g., "veni_creator", "magnificat")
    let id: String

    /// English title of the prayer (e.g., "Come, Creator Spirit")
    let title: String

    /// Latin title if applicable (e.g., "Veni Creator Spiritus")
    let latinTitle: String?

    /// Full text of the prayer
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

// MARK: - ChantRecordings

/// Whether the chant recordings are connected. They are not, for now:
/// the three files the app sang — the Veni Creator, the Ave Maris
/// Stella and the Magnificat — came with no licence behind them, so
/// nothing fetches, downloads or plays a chant. Every place a chant
/// would sound still stands (the Chapel's tile and sheet, the
/// consecration's transport) and says it is coming soon. Connecting
/// licensed recordings is this switch, and the server's keys behind
/// `/prayers/:id/audio`.
enum ChantRecordings {
    static let areConnected = false
}
