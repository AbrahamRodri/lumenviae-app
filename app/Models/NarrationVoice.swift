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

    /// The picker's wording: "Female voice".
    var displayName: String { "\(name) voice" }

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
        NarrationVoice(slug: "female", name: "Female", description: "A gentle, emotive narrator", isDefault: true),
        NarrationVoice(slug: "male", name: "Male", description: "A calm, measured narrator", isDefault: false)
    ]
}

/// Response from GET /api/voices
typealias VoicesResponse = APIResponse<[NarrationVoice]>
