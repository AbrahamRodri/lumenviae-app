//
//  APIService.swift
//  app
//
//  Network service for communicating with the Lumen Viae API.
//  Uses async/await for modern concurrency.
//

import Foundation

/// Errors that can occur during API operations
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)

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

/// Service for making API requests to the Lumen Viae backend
@Observable
final class APIService {
    static let shared = APIService()

    private let baseURL = "https://lumenviae.fly.dev/api"
    private let session: URLSession

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Mysteries

    /// Fetch all mysteries, optionally filtered by category
    /// - Parameter category: Optional category filter (joyful, sorrowful, glorious, luminous)
    /// - Returns: Array of Mystery objects
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

    /// Fetch meditation set summaries for a category
    /// - Parameter category: The mystery category to fetch sets for
    /// - Returns: Array of MeditationSetSummary objects
    func fetchMeditationSets(category: MysteryCategory) async throws -> [MeditationSetSummary] {
        let urlString = "\(baseURL)/meditation-sets?category=\(category.rawValue)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetsResponse.self).data
    }

    /// Fetch a complete meditation set with all meditations
    /// - Parameter id: The meditation set ID
    /// - Returns: Full MeditationSet with meditations array populated
    func fetchMeditationSet(id: Int) async throws -> MeditationSet {
        let urlString = "\(baseURL)/meditation-sets/\(id)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetDetailResponse.self).data
    }

    // MARK: - Completions

    /// Record a prayer completion
    /// - Parameter meditationSetId: The ID of the completed meditation set
    /// - Returns: Completion response with confirmation
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

    private func fetch<T: Codable>(url: URL, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)

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
