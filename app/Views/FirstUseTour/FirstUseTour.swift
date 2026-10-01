//
//  FirstUseTour.swift
//  Lumen Viae
//
//  A new reader's first look at the home page, once, after the
//  introduction: five coach marks over the real controls, one at a time
//  — today's Rosary, the Pray button (a tap and a hold), Prayers (the
//  Prayer Book's tab), the Chapel, and Explore.
//
//  Why this and not a deck of cards before the app: tutorials read
//  before the app is seen do not help people use it (NN/g, "Mobile
//  Tutorials: Wasted Effort or Efficiency Boost?", 2020), and help is
//  best given on the control it is about, one control at a time (NN/g,
//  "Instructional Overlays and Coach Marks for Mobile Apps"; Apple HIG,
//  "Offering help"). So each mark stands over the thing itself, says
//  what it is in a sentence, and waits. A stray tap cannot end it;
//  "Leave the tour" ends it on purpose, and it is never offered again.
//
//  It waits for the home page: the introduction's first step may open a
//  prayer, and the tour never stands over one. Someone updating from an
//  earlier version does not see it — they know the home page, and
//  What's New tells them what is new.
//
//  Each control reports where it stands through `firstUseTourStop(_:)`,
//  a single modifier on the control, in the screen's own coordinates.
//

import SwiftUI

// MARK: - FirstUseTourStop

/// The places the tour stops, in order.
enum FirstUseTourStop: Int, CaseIterable {
    case today, pray, prayers, chapel, explore

    /// The place's name, as the mark's kicker
    var name: String {
        switch self {
        case .today:   return "Today's Mysteries"
        case .pray:    return "The Pray Button"
        case .prayers: return "Prayers"
        case .chapel:  return "Your Chapel"
        case .explore: return "Explore"
        }
    }

    /// What the place is, then what it does, in a sentence or two
    var words: String {
        switch self {
        case .today:
            return "Each day has its own mysteries: scenes from the lives of Jesus and Mary to reflect on as you pray. Start today's Rosary here."
        case .pray:
            return "Tap it to begin today's Rosary at once. Press and hold to choose another prayer."
        case .prayers:
            return "Catholic prayers for every need, opening on the ones for this time of day. Find any prayer by name, or by where you are: at Mass, at Confession, at home."
        case .chapel:
            return "Your own page: your daily prayers, the days you have prayed, and the prayers for this time of day. Arrange it as you like."
        case .explore:
            return "Everything in the app in one place, from prayers and chant to books, with a search across it all."
        }
    }

    /// Round controls are lit in a circle, the rest in a rounded frame
    var isRound: Bool { self == .pray || self == .explore }
}

// MARK: - FirstUseTour

@Observable
final class FirstUseTour {

    static let shared = FirstUseTour()

    private static let dueKey = "firstUseTour.due"

    /// Owed to this install: set once, when the introduction is first
    /// finished, and cleared when the tour ends or is left
    private(set) var isDue: Bool

    /// The stop being shown, while the tour runs
    private(set) var stop: FirstUseTourStop?

    /// Where each stop's control stands, in the screen's coordinates
    var frames: [FirstUseTourStop: CGRect] = [:]

    var isRunning: Bool { stop != nil }

    private init() {
        isDue = UserDefaults.standard.bool(forKey: Self.dueKey)
    }

    /// Called when the introduction is finished for the first time
    func markDue() {
        isDue = true
        UserDefaults.standard.set(true, forKey: Self.dueKey)
    }

    /// Begins at the first stop, once every stop has said where it is
    func begin() {
        guard isDue, !isRunning,
              FirstUseTourStop.allCases.allSatisfy({ frames[$0] != nil }) else { return }
        stop = .today
    }

    /// On to the next stop, or the end after the last
    func advance() {
        guard let stop else { return }
        if let next = FirstUseTourStop(rawValue: stop.rawValue + 1) {
            self.stop = next
        } else {
            end()
        }
    }

    /// Stands the tour aside without ending it, when something opens over
    /// the home page while it runs (a notification's prayer, a shortcut, a
    /// Rosary still loading when it began). Still owed, it begins again
    /// from its first stop the next time the home page is in view.
    func pause() {
        stop = nil
    }

    /// Ends the tour, at its last stop or on purpose, for good
    func end() {
        stop = nil
        isDue = false
        UserDefaults.standard.set(false, forKey: Self.dueKey)
    }
}

// MARK: - Reporting a Stop

extension View {
    /// Tells the first-use tour where this control stands. One modifier,
    /// changing nothing about the control itself; nil (one of a row of
    /// controls that is not a stop) reports nothing.
    func firstUseTourStop(_ stop: FirstUseTourStop?) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            // Nothing is written once the tour is over: the home page
            // scrolls, and every frame of it would be a write
            guard let stop, FirstUseTour.shared.isDue else { return }
            FirstUseTour.shared.frames[stop] = frame
        }
    }
}
