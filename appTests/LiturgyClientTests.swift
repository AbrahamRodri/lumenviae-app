//
//  LiturgyClientTests.swift
//  Lumen Viae Tests
//
//  The Missal's and the Office's clients reading answers shaped as their
//  servers send them, through the stubbed network (no live request, no
//  disk): a day's propers in [english, latin] pairs, Christmas's three
//  Masses, the Ordo unwrapped from its container, the year's calendar
//  named in plain words; and the Office's day, hour and month in its
//  data envelope, its engine's outage carried as its own code.
//

import Foundation
import Testing
@testable import app

extension APIClientTests {

    private var missal: MissalAPIService { MissalAPIService(session: StubProtocol.session) }
    private var office: OfficeAPIService { OfficeAPIService(session: StubProtocol.session) }

    // MARK: The Missal

    @Test func aDaysProperComesInEnglishAndLatinPairs() async throws {
        StubProtocol.reset { _ in .init(body: """
        [{"info": {"id": "10-07", "title": "Most Holy Rosary of the Blessed Virgin Mary", "rank": 2, "colors": ["w"], "tempora": null, "description": null, "date": "2026-10-07", "tags": [], "commemorations": [{"title": "St. Mark, Pope"}]},
          "sections": [{"id": "Introitus", "label": "Introit", "body": [["Let us all rejoice in the Lord", "Gaudeamus omnes in Domino"]]}]}]
        """) }
        let propers = try await missal.fetchPropers(day: "2026-10-07")
        let proper = try #require(propers.first)
        #expect(proper.info.rankLabel == "Feast")
        #expect(proper.info.commemorations?.first?.title == "St. Mark, Pope")
        #expect(proper.sections.first?.body.first == ["Let us all rejoice in the Lord", "Gaudeamus omnes in Domino"])
        #expect(StubProtocol.requests.first?.url?.path.hasSuffix("/proper/2026-10-07") == true)
    }

    @Test func christmasCarriesItsThreeMasses() async throws {
        let mass = { (title: String) in #"{"info": {"title": "\#(title)", "rank": 1, "colors": ["w"]}, "sections": []}"# }
        StubProtocol.reset { _ in .init(body: "[\(mass("Midnight")), \(mass("Dawn")), \(mass("Day"))]") }
        let propers = try await missal.fetchPropers(day: "2026-12-25")
        #expect(propers.map(\.info.title) == ["Midnight", "Dawn", "Day"])
        #expect(Set(propers.map(\.id)).count == 3, "each Mass is its own page")
    }

    @Test func theOrdoIsTheFirstContainersSections() async throws {
        StubProtocol.reset { _ in .init(body: #"[{"info": {"title": "Ordo Missae"}, "sections": [{"id": null, "label": "Sanctus", "body": [["Holy, Holy, Holy", "Sanctus, Sanctus, Sanctus"]]}]}]"#) }
        let ordo = try await missal.fetchOrdo()
        #expect(ordo.map(\.label) == ["Sanctus"])

        StubProtocol.reset { _ in .init(body: "[]") }
        #expect(try await missal.fetchOrdo().isEmpty)
    }

    @Test func theYearsCalendarNamesEachDayPlainly() async throws {
        StubProtocol.reset { _ in .init(body: """
        [{"id": "2026-02-18", "title": "Ash Wednesday", "rank": 1, "colors": ["v"], "commemorations": null},
         {"id": "2026-10-04", "title": "Nineteenth Sunday after Pentecost", "rank": 2, "colors": ["g"], "commemorations": []}]
        """) }
        let days = try await missal.fetchCalendar(year: 2026)
        #expect(days.map(\.rankLabel) == ["Lenten Weekday", "Feast"])
        #expect(StubProtocol.requests.first?.url?.path.hasSuffix("/calendar/2026") == true)
    }

    @Test func aMissalOutageIsNotADecodingError() async {
        StubProtocol.reset { _ in .init(status: 500, body: "Internal Server Error") }
        do {
            _ = try await missal.fetchPropers(day: "2026-10-04")
            Issue.record("an outage was taken for a proper")
        } catch let error as APIError {
            if case .decodingError = error { Issue.record("an outage read as a decoding error") }
        } catch {
            // any other failure is the client's own; the page offers Try again
        }
    }

    // MARK: The Office

    @Test func anHourDecodesWithItsSectionsAndSource() async throws {
        StubProtocol.reset { _ in .init(body: """
        {"data": {"date": "2026-10-04", "hour": "vespers", "version": "rubrics-1960", "language": "english",
          "celebration": {"title": "Dominica XIX Post Pentecosten", "rank": "II. classis"}, "tempora": null,
          "sections": [{"latin": {"title": "Incipit", "note": null, "lines": ["℣. Deus, in adjutórium meum inténde."]},
                        "vernacular": {"title": "Incipit", "note": null, "lines": ["℣. O God, come to my assistance."]}}],
          "source": {"name": "Divinum Officium", "url": "https://www.divinumofficium.com"}}}
        """) }
        let hour = try await office.fetchHour(day: "2026-10-04", hour: .vespers)
        #expect(hour.sections.count == 1)
        #expect(hour.sections[0].latin?.lines.count == hour.sections[0].vernacular?.lines.count, "the two pair line for line")
        #expect(OfficeRank(hour.celebration?.rank) == .second)
        #expect(hour.source.name == "Divinum Officium", "every hour names its source")
    }

    @Test func aDayAndAMonthDecodeFromTheEnvelope() async throws {
        StubProtocol.reset { request in
            if request.url?.path.contains("/calendar/") == true {
                return .init(body: #"{"data": {"year": 2026, "month": 10, "version": "rubrics-1960", "days": [{"date": "2026-10-04", "celebration": null, "detail": null, "note": null, "letter": "d"}]}}"#)
            }
            return .init(body: #"{"data": {"date": "2026-10-04", "celebration": {"title": "Dominica XIX", "rank": "II. classis"}, "detail": {"label": "Tempora", "text": "Hebdomada XIX post Octavam Pentecostes"}, "note": null, "letter": null}}"#)
        }
        let day = try await office.fetchDay(day: "2026-10-04")
        #expect(day.id == "2026-10-04")
        #expect(day.celebration?.title == "Dominica XIX")
        let month = try await office.fetchCalendar(year: 2026, month: 10)
        #expect(month.days.count == 1)
        #expect(StubProtocol.requests.last?.url?.path.hasSuffix("/office/calendar/2026/10") == true)
    }

    @Test func theEnginesOutageIsItsOwn() async {
        StubProtocol.reset { _ in .init(status: 503, body: #"{"error": {"code": "office_unavailable", "message": "The engine is resting"}}"#) }
        do {
            _ = try await office.fetchDay(day: "2026-10-04")
            Issue.record("an outage was taken for a day")
        } catch APIError.serverError(let status, let code) {
            #expect(status == 503)
            #expect(code == "office_unavailable", "never mistaken for the Rosary's content failing")
        } catch {
            Issue.record("unexpected \(error)")
        }
    }
}
