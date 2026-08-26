//
//  MissalAPIService.swift
//  Lumen Viae
//
//  HTTP client for the Missale Meum API (https://www.missalemeum.com),
//  which serves the 1962 Missal — the daily propers and the Order of
//  Mass — as bilingual JSON. Its Latin texts come from Divinum Officium;
//  the English passages are Missale Meum's reviewed translations.
//
//  A third party, so it lives beside APIService rather than inside it:
//  its own base URL, no APIResponse envelope (bodies are bare arrays),
//  and its own instance so a Missale Meum outage can never be mistaken
//  for a Lumen Viae API failure.
//

import Foundation

final class MissalAPIService {

    static let shared = MissalAPIService()

    // MARK: - Configuration

    private let baseURL = "https://www.missalemeum.com/en/api/v5"
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

    // MARK: - Propers

    /// The propers for every Mass celebrated on a date — usually one
    /// element, three on Christmas.
    func fetchPropers(for date: Date) async throws -> [MissalProper] {
        try await fetchPropers(day: Self.dayString(for: date))
    }

    func fetchPropers(day: String) async throws -> [MissalProper] {
        guard let url = URL(string: "\(baseURL)/proper/\(day)") else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: [MissalProper].self)
    }

    // MARK: - Calendar

    /// The whole 1962 calendar for a year — title, class, and color for
    /// every day. Small enough to fetch whole and cache.
    func fetchCalendar(year: Int) async throws -> [MissalCalendarDay] {
        guard let url = URL(string: "\(baseURL)/calendar/\(year)") else {
            throw APIError.invalidURL
        }

        return try await fetch(url: url, responseType: [MissalCalendarDay].self)
    }

    // MARK: - Ordo Missae

    /// The fixed parts of the Mass, Asperges through Last Gospel.
    func fetchOrdo() async throws -> [MissalSection] {
        guard let url = URL(string: "\(baseURL)/ordo") else {
            throw APIError.invalidURL
        }

        let containers = try await fetch(url: url, responseType: [MissalProper].self)
        return containers.first?.sections ?? []
    }

    // MARK: - Private Helpers

    /// One retry for connection-shaped failures, mirroring APIService —
    /// a 404 (a date outside the served calendar) fails immediately, once.
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

            // No error envelope here — Missale Meum's failures are plain
            // FastAPI bodies, so the status code is the whole story.
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
