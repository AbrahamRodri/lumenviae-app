//
//  ChantCatalogTests.swift
//  Lumen Viae Tests
//
//  The Chant Library: every chant ships its recording and every part of
//  its score, every score reads, every prayer a chant is tied to is one
//  the Prayer Book carries, and the path reader draws what SVG means —
//  relative moves from each path's own origin, arcs that land where the
//  data says, flags written with no separator.
//

import CoreGraphics
import Foundation
import Testing
@testable import app

@MainActor
struct ChantCatalogTests {

    @Test func everyChantShipsItsRecordingAndScore() {
        #expect(!ChantCatalog.all.isEmpty)
        for chant in ChantCatalog.all {
            #expect(chant.audioURL != nil, "\(chant.id) has no recording in the bundle")
            #expect(!chant.score.isEmpty, "\(chant.id) has no score")
            for part in chant.score {
                let drawing = ChantScoreDrawing.load(file: part.file)
                #expect(drawing != nil, "\(chant.id): \(part.file) does not read")
                #expect(drawing?.operations.isEmpty == false, "\(chant.id): \(part.file) draws nothing")
            }
        }
    }

    @Test func idsAreUniqueAndGroupsKnown() {
        let ids = ChantCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        let groups = Set(ChantCatalog.groups.map(\.id))
        for chant in ChantCatalog.all {
            #expect(groups.contains(chant.groupID), "\(chant.id) is on an unknown shelf")
        }
    }

    @Test func everyTiedPrayerIsInThePrayerBook() {
        for chant in ChantCatalog.all {
            for id in chant.prayerIDs {
                #expect(PrayerBook.prayer(id) != nil, "\(chant.id) names \(id)")
            }
        }
    }

    @Test func theConsecrationsChantsAreThere() {
        for id in ["veni_creator", "ave_maris_stella", "magnificat"] {
            #expect(!ChantCatalog.chants(forPrayer: id).isEmpty, "no chant for \(id)")
        }
    }

    @Test func everyAntiphonOfTheSeasonHasAChant() {
        let calendar = Calendar(identifier: .gregorian)
        for (month, day) in [(12, 10), (2, 20), (4, 20), (9, 24)] {
            let date = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 20))!
            #expect(ChantCatalog.antiphonOfTheSeason(on: date) != nil, "no antiphon on \(month)/\(day)")
        }
    }

    @Test func searchIgnoresAccentsAndLigatures() {
        #expect(ChantCatalog.search("regina caeli").contains { $0.id.hasPrefix("regina_caeli") })
        #expect(ChantCatalog.search("HAIL, HOLY").contains { $0.id.hasPrefix("salve_regina") })
    }

    // MARK: - Path data

    private func bounds(_ data: String) -> CGRect {
        let path = CGMutablePath()
        SVGPathData.append(data, to: path)
        return path.boundingBoxOfPath
    }

    @Test func relativeMovesStartFromThePathsOwnOrigin() {
        let box = bounds("m10,10h5v5h-5z")
        #expect(box == CGRect(x: 10, y: 10, width: 5, height: 5))
    }

    @Test func pairsAfterAMoveAreLines() {
        let box = bounds("M0 0 10 0 10 10")
        #expect(box == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func numbersRunTogetherAsTheGrammarAllows() {
        // "1.5.5" is 1.5 and .5; "-1-1" is -1 and -1
        let box = bounds("M1.5.5l-1-1")
        #expect(abs(box.minX - 0.5) < 0.0001 && abs(box.minY + 0.5) < 0.0001)
    }

    @Test func aHalfCircleArcLandsWhereTheDataSays() {
        let path = CGMutablePath()
        SVGPathData.append("M0,0a5,5 0 0,1 10,0", to: path)
        #expect(abs(path.currentPoint.x - 10) < 0.0001 && abs(path.currentPoint.y) < 0.0001)
        // Sweep 1 from left to right on a y-down page bulges upward
        #expect(path.boundingBoxOfPath.minY < -4.9)
    }

    @Test func arcFlagsNeedNoSeparator() {
        let path = CGMutablePath()
        SVGPathData.append("M0 0a5 5 0 0110 0", to: path)
        #expect(abs(path.currentPoint.x - 10) < 0.0001)
    }

    @Test func aScoreFileReadsItsOperationsInOrder() {
        let text = "LVSCORE 1\n0 0 100 50\nI M0,0h10v10h-10z\nW M2,2h2v2h-2z\nR M20,0h5v5h-5z\nS0.8 M0,40L100,40\n"
        let drawing = ChantScoreDrawing.parse(text)
        #expect(drawing?.bounds == CGRect(x: 0, y: 0, width: 100, height: 50))
        #expect(drawing?.operations.count == 4)
    }
}
