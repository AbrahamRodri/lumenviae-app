//
//  ReviewPrompt.swift
//  app
//
//  When the app may ask for a rating (App Store item W4): after the Amen of
//  a finished Rosary, once the person has come back to pray on a few
//  different days, never twice for one version and never within 120 days
//  of the last ask. The system decides whether the sheet actually appears
//  (it allows three a year); this only decides whether the app asks.
//

import Foundation
import OSLog

struct ReviewPrompt {

    /// Where the ask is noted, so a simulator run can show it was made even
    /// when the system keeps its sheet back
    static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "ReviewPrompt")

    /// Rosaries finished on this many different prayer days first: a person
    /// who has come back three times has found something here. Counted in
    /// days, not Rosaries, so three said in one evening are not enough.
    static let daysPrayedBeforeAsking = 3

    /// The least time between two asks, the app's own spacing under the
    /// system's three a year
    static let spacing: TimeInterval = 120 * 24 * 60 * 60

    /// How long the completion screen stands before the ask, so the seal,
    /// the streak and the acts arrive first and the prayer is felt as done
    static let delay: Duration = .seconds(3)

    static let lastAskedKey = "reviewPrompt.lastAsked"
    static let lastVersionKey = "reviewPrompt.lastVersion"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether to ask now, after a finished Rosary
    func shouldAsk(daysPrayed: Int, version: String, now: Date = Date(), audioPlaying: Bool = false) -> Bool {
        guard !audioPlaying, daysPrayed >= Self.daysPrayedBeforeAsking else { return false }
        if defaults.string(forKey: Self.lastVersionKey) == version { return false }
        if let last = defaults.object(forKey: Self.lastAskedKey) as? Date,
            now.timeIntervalSince(last) < Self.spacing
        {
            return false
        }
        return true
    }

    /// Remembered at the ask, whether or not the system shows its sheet:
    /// the app cannot know, and asking again soon would be nagging
    func noteAsked(version: String, now: Date = Date()) {
        defaults.set(now, forKey: Self.lastAskedKey)
        defaults.set(version, forKey: Self.lastVersionKey)
    }

    /// The version a person is running, as the App Store names it
    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
}
