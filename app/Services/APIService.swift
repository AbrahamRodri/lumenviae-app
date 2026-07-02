//
//  APIService.swift
//  Lumen Viae
//
//  HTTP client for the Lumen Viae API (https://lumenviae.fly.dev/api):
//  - GET  /mysteries[?category=]  - List mysteries
//  - GET  /meditation-sets        - List meditation sets
//  - GET  /meditation-sets/:id    - Get full meditation set
//  - GET  /prayers/:id/audio      - Presigned audio URL
//  - POST /completions            - Record prayer completion
//

import Foundation

// MARK: - APIError

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

// MARK: - APIService

final class APIService {

    static let shared = APIService()

    // MARK: - Configuration

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

    // MARK: - Initialization

    /// The session parameter allows injecting a mock session for testing.
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Mysteries

    /// Fetches mysteries, optionally filtered by category.
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

    /// Fetches meditation set summaries (without meditations) for a category.
    func fetchMeditationSets(category: MysteryCategory) async throws -> [MeditationSetSummary] {
        let urlString = "\(baseURL)/meditation-sets?category=\(category.rawValue)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetsResponse.self).data
    }

    /// Fetches a complete meditation set with all meditations.
    func fetchMeditationSet(id: Int) async throws -> MeditationSet {
        let urlString = "\(baseURL)/meditation-sets/\(id)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetDetailResponse.self).data
    }

    // MARK: - Completions

    /// Records a prayer completion to the server when the user finishes all 5 mysteries.
    @discardableResult
    func recordCompletion(meditationSetId: Int) async throws -> CompletionResponse {
        let urlString = "\(baseURL)/completions"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let request = CompletionRequest(meditationSetId: meditationSetId)
        return try await post(url: url, body: request, responseType: APIResponse<CompletionResponse>.self).data
    }

    // MARK: - Prayer Audio

    /// Fetches a presigned S3 URL for a consecration prayer's chant audio
    /// (e.g., prayerId "veni_creator").
    func fetchPrayerAudioUrl(prayerId: String) async throws -> String {
        let urlString = "\(baseURL)/prayers/\(prayerId)/audio"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: APIResponse<PrayerAudioResponse>.self).data.audioUrl
    }

    // MARK: - Private Helpers

    /// Performs a GET request and decodes the response.
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

    /// Performs a POST request with a JSON body.
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
