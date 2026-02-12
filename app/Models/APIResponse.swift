//
//  APIResponse.swift
//  app
//
//  Generic wrapper for API responses and completion types.
//

import Foundation

/// Generic wrapper for API responses: { "data": T }
struct APIResponse<T: Codable>: Codable {
    let data: T
}

/// Type aliases for common API responses
typealias MysteriesResponse = APIResponse<[Mystery]>
typealias MeditationSetsResponse = APIResponse<[MeditationSetSummary]>
typealias MeditationSetDetailResponse = APIResponse<MeditationSet>

// MARK: - Completion Types

/// Request body for POST /api/completions
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
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case meditationSetId = "meditation_set_id"
        case completedAt = "completed_at"
    }
}
