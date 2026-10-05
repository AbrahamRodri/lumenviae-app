//
//  APIClientTests.swift
//  Lumen Viae Tests
//
//  The app's three HTTP clients driven end to end against a stubbed
//  network: the requests they send (paths, the voice and include
//  queries, the Office's pinned rubrics, the completion's body — the
//  app's one write, and only what the Privacy Policy says), and what
//  they make of the answers — the data envelope unwrapped, a status
//  code deciding an error whatever the body says, the envelope's code
//  carried, a dropped connection tried once more.
//

import Foundation
import Testing
@testable import app

/// Answers every request from a handler the test sets, and keeps what was asked
final class StubProtocol: URLProtocol, @unchecked Sendable {

    struct Answer {
        var status: Int = 200
        var body: String = "{}"
        var error: URLError?
    }

    nonisolated(unsafe) static var handler: (URLRequest) -> Answer = { _ in Answer() }
    nonisolated(unsafe) static var requests: [URLRequest] = []
    nonisolated(unsafe) static var bodies: [Data] = []
    private static let lock = NSLock()

    static func reset(_ handler: @escaping (URLRequest) -> Answer) {
        lock.withLock {
            self.handler = handler
            requests = []
            bodies = []
        }
    }

    static var session: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = Self.readBody(of: request)
        let answer = Self.lock.withLock {
            Self.requests.append(request)
            Self.bodies.append(body)
            return Self.handler(request)
        }
        if let error = answer.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: answer.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(answer.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readBody(of request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

@MainActor
@Suite(.serialized)
struct APIClientTests {

    private var api: APIService { APIService(session: StubProtocol.session) }

    // MARK: Lumen Viae's own API

    @Test func aSetsListIsAskedForByCategoryAndUnwrapped() async throws {
        StubProtocol.reset { _ in .init(body: #"{"data": [{"id": 3, "name": "Sheen", "category": "sorrowful", "description": null, "labels": ["Saints"], "author": null}]}"#) }
        let sets = try await api.fetchMeditationSets(category: .sevenSorrows)
        #expect(sets.map(\.id) == [3])
        let url = try #require(StubProtocol.requests.first?.url)
        #expect(url.path.hasSuffix("/api/meditation-sets"))
        #expect(url.query == "category=seven_sorrows")
    }

    @Test func aFreshNarrationIsAskedForInTheChosenVoice() async throws {
        StubProtocol.reset { _ in .init(body: #"{"data": {}}"#, error: nil) }
        _ = try? await api.fetchMeditationAudio(meditationId: 101, voice: "female")
        let url = try #require(StubProtocol.requests.first?.url)
        #expect(url.path.hasSuffix("/meditations/101/audio"))
        #expect(url.query == "voice=female")

        StubProtocol.reset { _ in .init(body: #"{"data": {}}"#) }
        _ = try? await api.fetchMeditationAudio(meditationId: 101, voice: "")
        #expect(StubProtocol.requests.first?.url?.query == nil, "no voice, no query")
    }

    @Test func theRosarysRecordingsAskForTheBookOnlyWhenIncluded() async throws {
        StubProtocol.reset { _ in .init(status: 500) }
        _ = try? await api.fetchRosaryAudio(voice: "frederick", include: ["book"])
        let components = try #require(StubProtocol.requests.first?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        #expect(components.path.hasSuffix("/rosary/audio"))
        #expect(components.queryItems == [URLQueryItem(name: "voice", value: "frederick"), URLQueryItem(name: "include", value: "book")])

        StubProtocol.reset { _ in .init(status: 500) }
        _ = try? await api.fetchRosaryAudio(voice: nil)
        #expect(StubProtocol.requests.first?.url?.query == nil)
    }

    @Test func theCompletionSendsTheSetAndWhetherItWasSaidAloudAndNothingElse() async throws {
        StubProtocol.reset { _ in .init(status: 201, body: #"{"data": {"id": 9, "meditation_set_id": 12, "completed_at": "2026-10-04T12:00:00Z"}}"#) }
        let response = try await api.recordCompletion(meditationSetId: 12, prayedAloud: true)
        #expect(response.meditationSetId == 12)

        let request = try #require(StubProtocol.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path.hasSuffix("/api/completions") == true)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(JSONSerialization.jsonObject(with: StubProtocol.bodies[0]) as? [String: Any])
        #expect(Set(body.keys) == ["meditation_set_id", "prayed_aloud"], "no device, install or account identifier")
        #expect(body["meditation_set_id"] as? Int == 12)
        #expect(body["prayed_aloud"] as? Bool == true)
    }

    @Test func theStatusDecidesAndTheEnvelopesCodeIsCarried() async {
        StubProtocol.reset { _ in .init(status: 404, body: #"{"error": {"code": "not_found", "message": "No such set"}}"#) }
        do {
            _ = try await api.fetchMeditationSet(id: 999)
            Issue.record("a 404 was taken for a set")
        } catch APIError.serverError(let status, let code) {
            #expect(status == 404)
            #expect(code == "not_found")
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test func aServerErrorInAnyShapeIsNeverADecodingError() async {
        StubProtocol.reset { _ in .init(status: 502, body: "<html>Bad gateway</html>") }
        do {
            _ = try await api.fetchVoices()
            Issue.record("a 502 was decoded")
        } catch APIError.serverError(let status, let code) {
            #expect(status == 502)
            #expect(code == nil)
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test func aMalformedSuccessIsADecodingError() async {
        StubProtocol.reset { _ in .init(body: #"{"data": [{"slug": 7}]}"#) }
        do {
            _ = try await api.fetchVoices()
            Issue.record("garbage was decoded")
        } catch APIError.decodingError {
            // as it should be
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test func aDroppedConnectionIsTriedOnceMore() async throws {
        var calls = 0
        StubProtocol.reset { _ in
            calls += 1
            return calls == 1
                ? .init(error: URLError(.networkConnectionLost))
                : .init(body: #"{"data": [{"slug": "frederick", "name": "Male", "default": true}]}"#)
        }
        let voices = try await api.fetchVoices()
        #expect(voices.map(\.slug) == ["frederick"])
        #expect(StubProtocol.requests.count == 2)
    }

    @Test func beingOfflineIsNotRetried() async {
        StubProtocol.reset { _ in .init(error: URLError(.notConnectedToInternet)) }
        do {
            _ = try await api.fetchVoices()
            Issue.record("offline succeeded")
        } catch APIError.networkError {
            #expect(StubProtocol.requests.count == 1)
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    // MARK: The Office and the Missal, their own clients

    @Test func theOfficeAsksWithItsPinnedRubricsAndLanguage() async throws {
        StubProtocol.reset { _ in .init(status: 503, body: #"{"error": {"code": "office_unavailable"}}"#) }
        let office = OfficeAPIService(session: StubProtocol.session)
        do {
            _ = try await office.fetchHour(day: "2026-10-04", hour: .vespers)
            Issue.record("a 503 was taken for an hour")
        } catch {
            // the engine's outage is its own
        }
        let components = try #require(StubProtocol.requests.first?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        #expect(components.path.hasSuffix("/office/2026-10-04/\(CanonicalHour.vespers.rawValue)"))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(query["version"] == "rubrics-1960")
        #expect(query["language"] == "english")
    }

    @Test func theMissalAsksMissaleMeumNotUs() async throws {
        StubProtocol.reset { _ in .init(status: 500) }
        let missal = MissalAPIService(session: StubProtocol.session)
        _ = try? await missal.fetchPropers(day: "2026-10-04")
        let url = try #require(StubProtocol.requests.first?.url)
        #expect(url.host == "www.missalemeum.com")
        #expect(url.absoluteString.contains("2026-10-04"))
    }

    @Test func aDayIsWrittenAsBothBooksKeyIt() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 6, hour: 9))!
        #expect(MissalAPIService.dayString(for: date) == "2026-01-06")
        #expect(OfficeAPIService.dayString(for: date) == "2026-01-06")
    }
}
