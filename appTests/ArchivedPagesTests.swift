//
//  ArchivedPagesTests.swift
//  Lumen Viae Tests
//
//  An archived page has no door anywhere: the page itself, the passages
//  of In Scripture, the readings on its shelves, and the doors other
//  readings hang on it all stand down, while the pages around them —
//  the True Devotion book, Your First Rosary, and How to Pray's
//  readings (the beginners' questions, Montfort's methods) — stay open.
//

import Foundation
import SwiftUI
import Testing

@testable import app

@MainActor
struct ArchivedPagesTests {

    @Test func theFivePagesAreArchived() {
        #expect(ArchivedPages.hides(.trueDevotion))
        #expect(ArchivedPages.hides(.scripture))
        #expect(ArchivedPages.hides(.marianLibrary))
        #expect(ArchivedPages.hides(.carloAcutis))
        #expect(ArchivedPages.hides(.howToPray))
    }

    @Test func howToPraysLessonsGoWithIt() {
        for lesson in 0..<3 {
            #expect(ArchivedPages.hides(.rosaryLesson(lesson)))
        }
    }

    @Test func theBookAndTheFirstRosaryStayOpen() {
        #expect(!ArchivedPages.hides(.trueDevotionBook))
        #expect(!ArchivedPages.hides(.guidedRosary(.joyful)))
        #expect(!ArchivedPages.hides(.spiritualReading))
        #expect(!ArchivedPages.hides(nil))
    }

    @Test func aPassageOfInScriptureGoesWithIt() {
        #expect(ArchivedPages.hides(.mysteryInScripture(category: .joyful, order: 1)))
    }

    @Test func readingsGoWithTheirPage() {
        for shelf in MarianLibraryData.sections + CarloAcutisData.shelves + [TrueDevotionData.teaching] {
            #expect(ArchivedPages.hides(shelf: shelf), "\(shelf.id)")
            for entry in shelf.entries {
                #expect(ArchivedPages.hides(.libraryReading(id: entry.id)), "\(entry.id)")
            }
        }
        for shelf in [HowToPrayData.methods, HowToPrayData.questions] {
            #expect(!ArchivedPages.hides(shelf: shelf), "\(shelf.id)")
            for entry in shelf.entries {
                #expect(!ArchivedPages.hides(.libraryReading(id: entry.id)), "\(entry.id)")
            }
        }
    }

    @Test func theRouterPushesNoArchivedPage() {
        let router = AppRouter()
        router.push(.marianLibrary)
        router.push(.libraryReading(id: "lourdes"))
        #expect(router.path.isEmpty)
        router.push(.howToPray)
        router.push(.rosaryLesson(0))
        #expect(router.path.isEmpty)
        router.push(.spiritualReading)
        #expect(router.path.count == 1)
    }
}
