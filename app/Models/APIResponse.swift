//
//  APIResponse.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  API RESPONSE WRAPPERS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  All API responses from the Lumen Viae backend are wrapped in a standard
//  format: `{ "data": <actual content> }`. These types handle that wrapping.
//
//  ## Why a Generic Wrapper?
//  Instead of creating separate response types for each endpoint, we use
//  a generic `APIResponse<T>` that works with any data type. This reduces
//  code duplication and keeps the codebase DRY (Don't Repeat Yourself).
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - Generic API Response Wrapper

/// Generic wrapper for all API responses.
///
/// The backend wraps all responses in `{ "data": <content> }` format.
/// This struct decodes that wrapper and extracts the inner data.
///
/// ## Usage
/// ```swift
/// // Instead of creating separate response types...
/// let response = try decoder.decode(APIResponse<[Mystery]>.self, from: data)
/// let mysteries = response.data // [Mystery]
/// ```
///
/// ## Swift Generics
/// `<T: Codable>` means "T can be any type that conforms to Codable".
/// This lets us reuse this one struct for all response types.
struct APIResponse<T: Codable>: Codable {
    /// The actual response data, extracted from the "data" key
    let data: T
}

// MARK: - Type Aliases

/// Type aliases provide readable names for common response types.
/// They're just shorthand - these are the same as writing out the full type.

/// Response from GET /api/mysteries
typealias MysteriesResponse = APIResponse<[Mystery]>

/// Response from GET /api/meditation-sets (list)
typealias MeditationSetsResponse = APIResponse<[MeditationSetSummary]>

/// Response from GET /api/meditation-sets/:id (detail)
typealias MeditationSetDetailResponse = APIResponse<MeditationSet>

// MARK: - Completion Types

/// Request body for POST /api/completions.
///
/// Sent when the user completes a Rosary prayer session.
/// Records which meditation set they finished.
///
/// Note: Uses `Encodable` (not `Codable`) because we only ever
/// SEND this data to the server, never receive it.
struct CompletionRequest: Encodable {
    /// The ID of the meditation set that was completed
    let meditationSetId: Int

    enum CodingKeys: String, CodingKey {
        case meditationSetId = "meditation_set_id"
    }
}

/// Response from POST /api/completions.
///
/// Confirms the completion was recorded successfully.
struct CompletionResponse: Codable {
    /// Server-assigned completion ID
    let id: Int

    /// The meditation set that was completed
    let meditationSetId: Int

    /// ISO 8601 timestamp of when completion was recorded
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case meditationSetId = "meditation_set_id"
        case completedAt = "completed_at"
    }
}
