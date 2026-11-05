//
//  APIService.swift
//  Lumen Viae
//
//  HTTP client for the Lumen Viae API (https://www.lumenviae.org/api):
//  - GET  /mysteries[?category=]  - List mysteries
//  - GET  /meditation-sets        - List meditation sets
//  - GET  /meditation-sets/:id    - Get full meditation set
//  - GET  /meditations/:id/audio  - Freshly signed narration URL + expiry
//                                   (?voice=slug for one voice)
//  - GET  /voices                 - The narration voices, default first
//  - GET  /rosary/audio           - The spoken Rosary's clips, signed
//                                   (?voice=slug, &include=kinds)
//  - POST /completions            - Record prayer completion
//

import Foundation

// MARK: - APIError

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)

    /// A non-2xx answer. `code` is the stable machine-readable code from
    /// the API's error envelope (`not_found`, `validation_failed`,
    /// `audio_unavailable`, …) when the body carried one; nil for a bare
    /// status from a proxy or a body in some other shape.
    case serverError(statusCode: Int, code: String? = nil)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid URL", comment: "Error message, rarely shown: the app built a bad web address for its server")
        case .networkError(let error):
            return String(
                localized: "Network error: \(error.localizedDescription)",
                comment: "Error message: the server could not be reached; the system's own description of the failure follows"
            )
        case .decodingError(let error):
            return String(
                localized: "Failed to decode response: \(error.localizedDescription)",
                comment: "Error message, rarely shown: the server's answer could not be read; the system's description follows"
            )
        case .serverError(let statusCode, let code):
            if let code {
                return String(
                    localized: "Server error \(statusCode) (\(code))",
                    comment: "Error message: the server answered with an error; an HTTP status number, then a technical code in English like not_found"
                )
            }
            return String(
                localized: "Server error with status code: \(statusCode)",
                comment: "Error message: the server answered with an error; an HTTP status number follows"
            )
        }
    }
}

// MARK: - APIService

final class APIService {

    static let shared = APIService()

    // MARK: - Configuration

    private let baseURL = APIService.baseURL

    /// The API's root, which the library's documents (`LibraryContentSync`)
    /// are asked of too
    nonisolated static let baseURL: String = {
        #if DEBUG
        // A debug build can be pointed at a server on this Mac, to try an
        // endpoint before it is deployed:
        // SIMCTL_CHILD_LUMEN_VIAE_API_BASE_URL=http://localhost:8080/api
        if let override = ProcessInfo.processInfo.environment["LUMEN_VIAE_API_BASE_URL"], !override.isEmpty {
            return override
        }
        #endif
        return "https://www.lumenviae.org/api"
    }()
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
    /// The default session fails fast (15s) instead of URLSession's 60s —
    /// the API sleeps on Fly.io, and a hung cold start should surface as a
    /// retryable error, not a minute-long spinner.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 45
            self.session = URLSession(configuration: config)
        }
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
    func fetchMeditationSets(
        category: MysteryCategory, lang: String? = MeditationTranslation.requestLanguage
    ) async throws -> [MeditationSetSummary] {
        // In Spanish the list asks for each set's Spanish name and line too
        let language = lang.map { "&lang=\($0)" } ?? ""
        let urlString = "\(baseURL)/meditation-sets?category=\(category.rawValue)\(language)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetsResponse.self).data
    }

    /// Fetches a complete meditation set with all meditations. A Spanish
    /// app asks with `lang=es`, which adds the meditations' Spanish
    /// (`translations`) and changes nothing else; an English app's request
    /// is the one it always sent.
    func fetchMeditationSet(id: Int, lang: String? = MeditationTranslation.requestLanguage) async throws -> MeditationSet {
        let language = lang.map { "?lang=\($0)" } ?? ""
        let urlString = "\(baseURL)/meditation-sets/\(id)\(language)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: MeditationSetDetailResponse.self).data
    }

    // MARK: - Meditation Audio

    /// Fetches a freshly signed narration URL for one meditation, with the
    /// moment it expires. The URLs on a set live about a day; a stored or
    /// long-held set asks here once they have passed instead of meeting
    /// the expiry as a 403 partway through a decade.
    ///
    /// `voice` names the narration voice; nil asks for the server's
    /// default, or whichever voice has recorded the meditation when the
    /// default has not.
    func fetchMeditationAudio(meditationId: Int, voice: String? = nil) async throws -> MeditationAudioResponse {
        var urlString = "\(baseURL)/meditations/\(meditationId)/audio"
        if let voice, !voice.isEmpty {
            urlString += "?voice=\(voice)"
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: APIResponse<MeditationAudioResponse>.self).data
    }

    // MARK: - Timed Narrations (v2)

    /// One meditation's narration from the v2 API, with the lines the
    /// recording says and where each falls in it (`lines`, nil when the
    /// recording has not been timed). Asked for only by the simple
    /// Rosary, to light the meditation's words; every other fetch stays
    /// on v1.
    struct TimedNarration: nonisolated Codable, Equatable {
        struct Audio: nonisolated Codable, Equatable {
            let url: String
        }
        let meditationId: Int
        let voice: String
        let audio: Audio
        let lines: [TimedLine]?

        enum CodingKeys: String, CodingKey {
            case voice, audio, lines
            case meditationId = "meditation_id"
        }
    }

    /// `POST /api/v2/meditations/audio`: freshly signed narrations for
    /// the meditations, each in `voice` where it has one, with its timed
    /// lines. An id with nothing to play is left out of the answer.
    func fetchTimedNarrations(meditationIds: [Int], voice: String?) async throws -> [TimedNarration] {
        guard let url = URL(string: "\(baseURL)/v2/meditations/audio") else { throw APIError.invalidURL }
        struct Body: Encodable {
            struct Data: Encodable {
                let meditation_ids: [Int]
                let voice: String?
            }
            let data: Data
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(Body(data: .init(meditation_ids: meditationIds, voice: voice)))
        return try await send(request, responseType: [TimedNarration].self)
    }

    // MARK: - Voices

    /// Fetches the narration voices, default first.
    func fetchVoices() async throws -> [NarrationVoice] {
        guard let url = URL(string: "\(baseURL)/voices") else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: VoicesResponse.self).data
    }

    // MARK: - Completions

    /// Records a prayer completion to the server when the user finishes all 5 mysteries.
    /// `prayedAloud` says whether the Rosary was said aloud by the spoken
    /// Rosary rather than read as text (a set with no recording).
    @discardableResult
    func recordCompletion(meditationSetId: Int, prayedAloud: Bool = false) async throws -> CompletionResponse {
        let urlString = "\(baseURL)/completions"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let request = CompletionRequest(meditationSetId: meditationSetId, prayedAloud: prayedAloud)
        return try await post(url: url, body: request, responseType: APIResponse<CompletionResponse>.self).data
    }

    // MARK: - The Spoken Rosary

    /// Fetches one voice's spoken-Rosary manifest: the fixed prayers, the
    /// mystery announcements and, unless left out, the Scriptural
    /// Rosary's verses — each with a signed link.
    ///
    /// `include` narrows the kinds ("prayers", "announcements",
    /// "verses"); a meditation Rosary has no use for 249 verse links.
    func fetchRosaryAudio(voice: String?, include: [String]? = nil) async throws -> RosaryAudioManifest {
        var components = URLComponents(string: "\(baseURL)/rosary/audio")
        var query: [URLQueryItem] = []
        if let voice, !voice.isEmpty {
            query.append(URLQueryItem(name: "voice", value: voice))
        }
        if let include, !include.isEmpty {
            query.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        components?.queryItems = query.isEmpty ? nil : query

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: RosaryAudioResponse.self).data
    }

    // MARK: - Private Helpers

    /// Performs a GET request with one retry for transient failures —
    /// the first request to a sleeping Fly.io machine often wakes it just
    /// in time for the second.
    ///
    /// Only connection-shaped errors retry: a 404, a decoding failure, or
    /// a cancelled task must fail immediately, once. The un-optional
    /// `Task.sleep` propagates cancellation so a dismissed screen never
    /// fires a second request.
    private func fetch<T: Codable>(url: URL, responseType: T.Type) async throws -> T {
        do {
            return try await fetchOnce(url: url, responseType: responseType)
        } catch let error as APIError {
            guard case .networkError(let underlying) = error,
                  let urlError = underlying as? URLError,
                  Self.retryableCodes.contains(urlError.code) else {
                throw error
            }
            try await Task.sleep(for: .seconds(1.5))
            return try await fetchOnce(url: url, responseType: responseType)
        }
    }

    /// Failures that plausibly mean "the server is still waking up".
    private static let retryableCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotConnectToHost,
        .cannotFindHost,
        .networkConnectionLost,
        .dnsLookupFailed
    ]

    /// Runs a request, validates the status code, and decodes the body.
    ///
    /// The single place status checking and error mapping live, so a GET and
    /// a POST can never disagree about what counts as a server error or how
    /// a decoding failure is reported.
    private func send<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            // The status code decides; the body is only read for its
            // error code. A 404 is a 404 whatever shape the envelope
            // takes, and an envelope that fails to decode must never turn
            // a server error into a decoding error.
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
                throw APIError.serverError(
                    statusCode: httpResponse.statusCode,
                    code: envelope?.error.code
                )
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

    /// Performs a single GET request and decodes the response.
    private func fetchOnce<T: Codable>(url: URL, responseType: T.Type) async throws -> T {
        try await send(URLRequest(url: url), responseType: responseType)
    }

    /// Performs a POST request with a JSON body.
    private func post<T: Codable, B: Encodable>(url: URL, body: B, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        return try await send(request, responseType: responseType)
    }
}
