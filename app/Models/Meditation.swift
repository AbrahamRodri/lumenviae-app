//
//  Meditation.swift
//  Lumen Viae
//
//  Meditation content for a single mystery, nested in the MeditationSet
//  API response. Each mystery can have multiple meditation styles
//  (Traditional, St. Louis de Montfort, Scriptural, etc.), and each
//  meditation can be heard in more than one narration voice.
//

import Foundation

// MARK: - Narration

/// One voice's recording of a meditation: the voice's slug (see
/// `NarrationVoice`) and a presigned URL for it. The server lists them
/// default voice first.
struct Narration: nonisolated Codable, Hashable {
    let voice: String
    let audioUrl: String

    enum CodingKeys: String, CodingKey {
        case voice
        case audioUrl = "audio_url"
    }
}

// MARK: - Meditation

/// Meditation text for a specific mystery, with optional guided audio.
struct Meditation: nonisolated Codable, Identifiable, Hashable {

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

    /// URL for the audio version of this meditation in the server's
    /// default voice. Kept beside `narrations` because builds that
    /// predate voices decode only this, and stored sets written by them
    /// carry only this.
    let audioUrl: String?

    /// Every voice this meditation can be heard in, default voice first.
    /// Nil for a set stored before voices existed; `audioUrl` still plays.
    let narrations: [Narration]?

    /// The mystery this meditation belongs to (includes name, scripture, etc.)
    let mystery: Mystery?

    enum CodingKeys: String, CodingKey {
        case id, title, content, author, source, mystery, narrations
        case audioUrl = "audio_url"
    }

    init(
        id: Int,
        title: String?,
        content: String,
        author: String?,
        source: String?,
        audioUrl: String?,
        narrations: [Narration]? = nil,
        mystery: Mystery?
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.author = author
        self.source = source
        self.audioUrl = audioUrl
        self.narrations = narrations
        self.mystery = mystery
    }

    // MARK: - Computed Properties

    /// Title for display, with fallback chain: title → mystery name → "Meditation"
    var displayTitle: String {
        title ?? mystery?.name ?? "Meditation"
    }

    /// Whether this meditation has any narration at all
    var hasAudio: Bool {
        guard let url = audioUrl else { return false }
        return !url.isEmpty
    }

    /// The voices this meditation has been recorded in, default first.
    /// Empty when the server said nothing about voices.
    var availableVoices: [String] {
        narrations?.map(\.voice) ?? []
    }

    /// Whether this meditation can be heard in `voice`. A stored set that
    /// predates voices claims nothing, so the caller falls back to
    /// `audioUrl`.
    func hasNarration(voice: String) -> Bool {
        narrations?.contains { $0.voice == voice } ?? false
    }

    /// The URL of this meditation in `voice`, or nil when it has not been
    /// recorded in that voice.
    func audioUrl(voice: String) -> String? {
        narrations?.first { $0.voice == voice }?.audioUrl
    }

    /// The narration to play for someone who prefers `voice`: that voice
    /// when the meditation has it, else the default. The voice actually
    /// chosen comes back with the URL, so a download is saved under the
    /// voice it really is. Nil when there is nothing to play.
    ///
    /// The default's voice is read off `narrations` when the server sent
    /// them; a stored set from before voices carries only `audioUrl`, and
    /// those recordings were all made in the original (male) voice.
    func playableNarration(preferring voice: String?) -> Narration? {
        if let voice, let url = audioUrl(voice: voice), !url.isEmpty {
            return Narration(voice: voice, audioUrl: url)
        }
        if let first = narrations?.first, !first.audioUrl.isEmpty {
            return first
        }
        guard let audioUrl, !audioUrl.isEmpty else { return nil }
        return Narration(voice: NarrationVoice.legacyVoice, audioUrl: audioUrl)
    }
}
