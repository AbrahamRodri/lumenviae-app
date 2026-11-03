//
//  ReviewPromptTests.swift
//  appTests
//
//  When the app asks for a rating after a finished Rosary (W4).
//

import Foundation
import Testing

@testable import app

struct ReviewPromptTests {

    private func prompt() -> ReviewPrompt {
        ReviewPrompt(defaults: UserDefaults(suiteName: "ReviewPromptTests.\(UUID().uuidString)")!)
    }

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    @Test func neverBeforeThreeDaysOfPrayer() {
        let prompt = prompt()
        #expect(!prompt.shouldAsk(daysPrayed: 0, version: "4.1", now: now))
        #expect(!prompt.shouldAsk(daysPrayed: 1, version: "4.1", now: now))
        #expect(!prompt.shouldAsk(daysPrayed: 2, version: "4.1", now: now))
        #expect(prompt.shouldAsk(daysPrayed: 3, version: "4.1", now: now))
    }

    @Test func neverWhileAVoiceIsSpeaking() {
        #expect(!prompt().shouldAsk(daysPrayed: 10, version: "4.1", now: now, audioPlaying: true))
    }

    @Test func notTwiceForOneVersion() {
        let prompt = prompt()
        prompt.noteAsked(version: "4.1", now: now)
        #expect(!prompt.shouldAsk(daysPrayed: 10, version: "4.1", now: now.addingTimeInterval(400 * day)))
        #expect(prompt.shouldAsk(daysPrayed: 10, version: "4.2", now: now.addingTimeInterval(400 * day)))
    }

    @Test func notAgainWithin120Days() {
        let prompt = prompt()
        prompt.noteAsked(version: "4.1", now: now)
        #expect(!prompt.shouldAsk(daysPrayed: 10, version: "4.2", now: now.addingTimeInterval(119 * day)))
        #expect(prompt.shouldAsk(daysPrayed: 10, version: "4.2", now: now.addingTimeInterval(120 * day)))
    }

    @Test func askingIsRemembered() {
        let prompt = prompt()
        #expect(prompt.defaults.object(forKey: ReviewPrompt.lastAskedKey) == nil)
        prompt.noteAsked(version: "4.1", now: now)
        #expect(prompt.defaults.object(forKey: ReviewPrompt.lastAskedKey) as? Date == now)
        #expect(prompt.defaults.string(forKey: ReviewPrompt.lastVersionKey) == "4.1")
    }

    @Test func prayerDaysCountDaysNotRosaries() {
        let calendar = Calendar(identifier: .gregorian)
        let evening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 20))!
        let three = [evening, evening.addingTimeInterval(600), evening.addingTimeInterval(1200)]
        #expect(PrayerHistoryService.prayerDays(of: three, calendar: calendar).count == 1)
    }
}
