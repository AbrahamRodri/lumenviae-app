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
