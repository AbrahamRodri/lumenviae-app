//
//  APIResponse.swift
//  Lumen Viae
//
//  All backend responses are wrapped as `{ "data": <content> }`.
//  These types handle that wrapping.
//

import Foundation

// MARK: - Generic API Response Wrapper

struct APIResponse<T: Codable>: Codable {
    let data: T
}

// MARK: - Type Aliases

/// Response from GET /api/mysteries
typealias MysteriesResponse = APIResponse<[Mystery]>

/// Response from GET /api/meditation-sets (list)
typealias MeditationSetsResponse = APIResponse<[MeditationSetSummary]>

/// Response from GET /api/meditation-sets/:id (detail)
typealias MeditationSetDetailResponse = APIResponse<MeditationSet>

// MARK: - Prayer Audio Types

/// Response from GET /api/prayers/:id/audio
struct PrayerAudioResponse: Codable {
    let id: String
    let audioUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case audioUrl = "audio_url"
    }
}

// MARK: - Meditation Audio Types

/// Response from GET /api/meditations/:id/audio — a freshly signed
/// narration URL and the moment it stops working (ISO 8601).
struct MeditationAudioResponse: Codable {
    let id: Int
    let audioUrl: String
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case audioUrl = "audio_url"
        case expiresAt = "expires_at"
    }

    /// `expiresAt` as a date, when it parses
    var expiry: Date? {
        expiresAt.flatMap { try? Date($0, strategy: .iso8601) }
    }
}

// MARK: - Error Envelope

/// The one shape every API error now takes:
/// `{ "error": { "code": "not_found", "message": "Not found", "details": {…} } }`.
/// `code` is stable and safe to branch on; `message` is for humans and may
/// change; `details` is present only when there is per-field information.
struct APIErrorEnvelope: Decodable {
    struct Body: Decodable {
        let code: String
        let message: String?
    }
    let error: Body
}

// MARK: - Completion Types

/// Request body for POST /api/completions, sent when the user
/// completes a Rosary prayer session.
struct CompletionRequest: Encodable {
    let meditationSetId: Int

    enum CodingKeys: String, CodingKey {
        case meditationSetId = "meditation_set_id"
    }
}

/// Response from POST /api/completions
struct CompletionResponse: Codable {
    let id: Int
    let meditationSetId: Int

    /// ISO 8601 timestamp of when completion was recorded
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case meditationSetId = "meditation_set_id"
        case completedAt = "completed_at"
    }
}
