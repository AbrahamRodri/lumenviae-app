//
//  OfficeAPIService.swift
//  Lumen Viae
//
//  HTTP client for the Divine Office endpoints of the Lumen Viae API
//  (https://lumenviae.fly.dev/api/office/*). Our own API and envelope —
//  but its own client beside APIService, the way MissalAPIService is:
//  the office is assembled from the Divinum Officium engine upstream,
//  and an upstream outage (the API's `office_unavailable`) should never
//  be mistaken for the Rosary content failing.
//
//  The version is pinned to the 1960 rubrics — the 1962 books, matching
//  the Daily Missal — and the translation to English. Both travel as
//  explicit query parameters so a change of server default can never
//  silently turn the page. A version or language setting would thread
//  through here.
//

import Foundation

final class OfficeAPIService {

    static let shared = OfficeAPIService()

    // MARK: - Configuration

    /// The rubrical version every request asks for. One slug, everywhere:
    /// the fetches, the cache keys, and the reader all agree.
    static let version = "rubrics-1960"

    /// The translation set beside the Latin
    static let language = "english"

    private let baseURL = "https://lumenviae.fly.dev/api/office"
    private let session: URLSession
    private let decoder = JSONDecoder()

    /// The request date the server understands. The formatter's own
    /// current time zone decides when the page turns — the same "the
    /// user's midnight" rule ScheduleService applies to the mysteries.
    private static let requestDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// "2026-08-24" — the form the API and the disk cache both key by
    static func dayString(for date: Date) -> String {
        requestDateFormatter.string(from: date)
    }

    // MARK: - Initialization

    /// Same fail-fast timeouts as APIService: a hung request should
    /// surface as a retryable error, not a minute-long spinner.
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

    // MARK: - Day

    /// One day's place in the calendar — celebration, rank, season line —
    /// without fetching any hour.
    func fetchDay(day: String) async throws -> OfficeDay {
        try await fetch(
            url: url(path: day),
            responseType: APIResponse<OfficeDay>.self
        ).data
    }

    // MARK: - Hour

    /// The full text of one canonical hour on one date.
    func fetchHour(day: String, hour: CanonicalHour) async throws -> OfficeHour {
        try await fetch(
            url: url(path: "\(day)/\(hour.rawValue)"),
            responseType: APIResponse<OfficeHour>.self
        ).data
    }

    // MARK: - Calendar

    /// The liturgical calendar for one month under the pinned rubrics.
    func fetchCalendar(year: Int, month: Int) async throws -> OfficeCalendarMonth {
        try await fetch(
            url: url(path: "calendar/\(year)/\(month)"),
            responseType: APIResponse<OfficeCalendarMonth>.self
        ).data
    }

    // MARK: - Private Helpers

    private func url(path: String) throws -> URL {
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "version", value: Self.version),
            URLQueryItem(name: "language", value: Self.language)
        ]
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        return url
    }

    /// One retry for connection-shaped failures, mirroring APIService —
    /// the first request often wakes the sleeping Fly.io machine just in
    /// time for the second. A 404 or a decoding failure fails once.
    private func fetch<T: Codable>(url: @autoclosure () throws -> URL, responseType: T.Type) async throws -> T {
        let url = try url()
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

    private static let retryableCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotConnectToHost,
        .cannotFindHost,
        .networkConnectionLost,
        .dnsLookupFailed
    ]

    private func fetchOnce<T: Codable>(url: URL, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))

            // The Lumen Viae envelope: the status code decides, and the
            // body is read only for its stable error code
            // (`office_unavailable` — the upstream engine, retryable).
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
}
