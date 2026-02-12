//
//  APIService.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  API SERVICE - NETWORK COMMUNICATION WITH THE BACKEND
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Handles all HTTP requests to the Lumen Viae API.
//  Uses modern Swift concurrency (async/await).
//
//  ## API Base URL
//  https://lumenviae.fly.dev/api
//
//  ## Available Endpoints
//  - GET  /mysteries              - List all mysteries
//  - GET  /mysteries?category=    - Filter by category
//  - GET  /meditation-sets        - List meditation sets
//  - GET  /meditation-sets/:id    - Get full meditation set
//  - POST /completions            - Record prayer completion
//
//  ## Error Handling
//  All methods can throw `APIError` for various failure cases.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - APIError

/// Errors that can occur during API operations.
///
/// ## LocalizedError
/// Conforming to `LocalizedError` allows us to provide user-friendly
/// error messages via the `errorDescription` property.
///
enum APIError: Error, LocalizedError {
    /// The URL string was invalid
    case invalidURL

    /// Network request failed (no internet, timeout, etc.)
    case networkError(Error)

    /// JSON decoding failed (API returned unexpected format)
    case decodingError(Error)

    /// Server returned an error status code (4xx, 5xx)
    case serverError(statusCode: Int)

    /// Human-readable error description
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        }
    }
}

// MARK: - APIService

/// Service for making HTTP requests to the Lumen Viae API.
///
/// ## Singleton Pattern
/// Uses `static let shared` for app-wide access. This ensures all
/// requests use the same URLSession and configuration.
///
/// ## Why @Observable?
/// Not strictly necessary since this service doesn't have UI-bound state,
/// but keeps it consistent with other services and allows future state.
///
@Observable
final class APIService {

    // MARK: - Singleton

    /// Shared instance for app-wide use
    static let shared = APIService()

    // MARK: - Configuration

    /// Base URL for all API requests
    private let baseURL = "https://lumenviae.fly.dev/api"

    /// URLSession for making network requests
    private let session: URLSession

    /// JSON decoder configured for ISO 8601 dates
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// JSON encoder configured for ISO 8601 dates
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Initialization

    /// Creates an APIService with the given URLSession.
    ///
    /// - Parameter session: URLSession to use (defaults to .shared)
    ///
    /// Using a parameter allows injecting a mock session for testing.
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Mysteries

    /// Fetches mysteries, optionally filtered by category.
    ///
    /// - Parameter category: Optional category filter
    /// - Returns: Array of Mystery objects
    /// - Throws: `APIError` if the request fails
    ///
    /// ## Example
    /// ```swift
    /// let joyfulMysteries = try await apiService.fetchMysteries(category: .joyful)
    /// ```
    func fetchMysteries(category: MysteryCategory? = nil) async throws -> [Mystery] {
        var urlString = "\(baseURL)/mysteries"
        if let category {
            urlString += "?category=\(category.rawValue)"
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MysteriesResponse.self).data
    }

    // MARK: - Meditation Sets

    /// Fetches meditation set summaries for a category.
    ///
    /// Returns summaries (without full meditations array) for the
    /// meditation selection screen.
    ///
    /// - Parameter category: The category to fetch sets for
    /// - Returns: Array of MeditationSetSummary objects
    func fetchMeditationSets(category: MysteryCategory) async throws -> [MeditationSetSummary] {
        let urlString = "\(baseURL)/meditation-sets?category=\(category.rawValue)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetsResponse.self).data
    }

    /// Fetches a complete meditation set with all meditations.
    ///
    /// Called when user selects a specific meditation style.
    ///
    /// - Parameter id: The meditation set ID
    /// - Returns: Full MeditationSet with meditations array
    func fetchMeditationSet(id: Int) async throws -> MeditationSet {
        let urlString = "\(baseURL)/meditation-sets/\(id)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetDetailResponse.self).data
    }

    // MARK: - Completions

    /// Records a prayer completion to the server.
    ///
    /// Called when the user finishes all 5 mysteries.
    ///
    /// - Parameter meditationSetId: The ID of the completed set
    /// - Returns: Confirmation response
    ///
    /// ## @discardableResult
    /// Allows calling this method without using the return value
    /// (callers often don't need the response for completions).
    @discardableResult
    func recordCompletion(meditationSetId: Int) async throws -> CompletionResponse {
        let urlString = "\(baseURL)/completions"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let request = CompletionRequest(meditationSetId: meditationSetId)
        return try await post(url: url, body: request, responseType: APIResponse<CompletionResponse>.self).data
    }

    // MARK: - Private Helpers

    /// Performs a GET request and decodes the response.
    ///
    /// - Parameters:
    ///   - url: The URL to fetch
    ///   - responseType: The expected response type
    /// - Returns: Decoded response object
    private func fetch<T: Codable>(url: URL, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)

            // Check for HTTP error status codes
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }

            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Performs a POST request with a JSON body.
    ///
    /// - Parameters:
    ///   - url: The URL to post to
    ///   - body: The request body (will be JSON-encoded)
    ///   - responseType: The expected response type
    /// - Returns: Decoded response object
    private func post<T: Codable, B: Encodable>(url: URL, body: B, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }

            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
