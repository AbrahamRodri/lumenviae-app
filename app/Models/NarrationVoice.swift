//
//  NarrationVoice.swift
//  Lumen Viae
//
//  A voice a meditation can be heard in, as GET /api/voices describes it.
//  The slug is the identifier everything else uses: it names the voice in
//  each meditation's `narrations`, is sent back as `?voice=`, and keys the
//  offline files. The name and description are for the picker.
//

import Foundation

struct NarrationVoice: nonisolated Codable, Identifiable, Hashable {
    let slug: String
    let name: String
    let description: String?
    let isDefault: Bool

    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case slug, name, description
        case isDefault = "default"
    }

    init(slug: String, name: String, description: String? = nil, isDefault: Bool = false) {
        self.slug = slug
        self.name = name
        self.description = description
        self.isDefault = isDefault
    }

    /// The picker's wording is the server's own: "Male", "Female", with
    /// the description beneath it. The two names the server sends today
    /// are translated here for display; any other name is shown as sent.
    var displayName: String {
        switch name {
        case "Male":
            return String(localized: "Male", comment: "Name of a narration voice, in Settings and the player's voice choice: the man's voice")
        case "Female":
            return String(localized: "Female", comment: "Name of a narration voice, in Settings and the player's voice choice: the woman's voice")
        default:
            return name
        }
    }

    /// The name set mid-sentence ("Read to you in the male voice", "Leída
    /// para ti con la voz masculina"): the displayed name, lowered, never
    /// the server's English name
    var nameInSentence: String { displayName.lowercased() }

    /// The server's line on the voice, said plainly: "emotive" is not a
    /// word for a newcomer
    var plainDescription: String? {
        switch description {
        case "A gentle, emotive narrator":
            return String(localized: "A gentle, warm voice", comment: "Settings, narration voice: the line under the woman's voice describing it")
        case "A warm, reverent narrator":
            return String(localized: "A warm, reverent voice", comment: "Settings, narration voice: the line under the man's voice describing it")
        default:                           return description
        }
    }

    /// The voice every recording was made in before there were voices.
    /// A stored set from that time carries only `audioUrl`, and a
    /// downloaded `meditation_<id>.mp3` with no voice in its name is one
    /// of these.
    static let legacyVoice = "male"

    /// What the app offers before it has ever reached `/api/voices`, and
    /// whenever it cannot: the same two voices the server ships with, in
    /// the same order. A picker that could show nothing offline would be
    /// a picker that sometimes vanished.
    static let builtIn: [NarrationVoice] = [
        NarrationVoice(slug: "frederick", name: "Male", description: "A warm, reverent narrator", isDefault: true),
        NarrationVoice(slug: "female", name: "Female", description: "A gentle, emotive narrator", isDefault: false)
    ]

    /// Voices the server has retired, each with the voice that took its
    /// place. Someone who chose the original male narrator chose a male
    /// voice, so the choice moves to his successor rather than to
    /// whatever the default happens to be. The retired voice's saved
    /// files keep their names and still play when nothing else is saved.
    static let successors: [String: String] = ["male": "frederick"]
}

/// Response from GET /api/voices
typealias VoicesResponse = APIResponse<[NarrationVoice]>
