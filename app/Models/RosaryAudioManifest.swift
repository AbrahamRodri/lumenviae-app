//
//  RosaryAudioManifest.swift
//  Lumen Viae
//
//  What GET /api/rosary/audio says about one voice's spoken Rosary: every
//  fixed prayer, every mystery's announcement, and the Scriptural
//  Rosary's verse for every Hail Mary, each with the name it is stored
//  under and a signed link that lives about a day.
//
//  The server keeps the catalogue (LumenViae.Rosary.PrayerAudio) and the
//  words are the app's own: the prayers are RosaryPrayers' text and the
//  verses are ScripturalRosaryData's, recorded by the server from an
//  export of the same generator.
//

import Foundation

/// Response from GET /api/rosary/audio
typealias RosaryAudioResponse = APIResponse<RosaryAudioManifest>

struct RosaryAudioManifest: Codable, Equatable {

    /// The voice slug the clips are recorded in
    let voice: String

    /// A fingerprint of the voice's whole catalogue. A copy on disk made
    /// under another version may be missing clips or hold old wording.
    let version: String

    /// When the signed links stop working (ISO 8601)
    let expiresAt: String?

    /// Keyed by the app's prayer ids: "hail_mary", "apostles_creed" …
    let prayers: [String: RosaryAudioClip]?

    /// Keyed "<category>_<order>", the key MysteryData's fruits use
    let announcements: [String: RosaryAudioClip]?

    /// The verses for each mystery, in bead order, under the same key
    let verses: [String: [RosaryAudioClip]]?

    enum CodingKeys: String, CodingKey {
        case voice, version, prayers, announcements, verses
        case expiresAt = "expires_at"
    }

    /// When the links die, or nil if the server did not say
    var expiry: Date? {
        expiresAt.flatMap { ISO8601DateFormatter().date(from: $0) }
    }
}

/// One recording. `file` changes whenever the recording would — new
/// words, or a voice moved to another model — so it is the name the
/// recording is saved under on the device too, and a stale copy is
/// simply a file the manifest no longer names.
struct RosaryAudioClip: Codable, Equatable {
    let file: String
    let audioUrl: String

    /// An announcement's words: "The First Joyful Mystery: The Annunciation"
    let text: String?

    /// A verse's citation: "Luke 1:28"
    let reference: String?

    enum CodingKeys: String, CodingKey {
        case file, text, reference
        case audioUrl = "audio_url"
    }
}
