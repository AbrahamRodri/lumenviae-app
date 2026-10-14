//
//  PrayAlongTransport.swift
//  Lumen Viae
//
//  What play and pause do on the pray-along screen, wherever the voice
//  stands: on a prayer, in the breath after one, or turning in the next
//  (the page turning and its recording loading). The disc, the Lock
//  Screen and the headphones all go through it, so a pause taken
//  between two prayers holds the next one back however it was asked
//  for: one taken while the next prayer loaded once reached a player
//  that held nothing yet, and the prayer began anyway, from the speaker
//  when the headphones had been pulled out.
//

import Foundation

struct PrayAlongTransport: Equatable {

    enum Stage: Equatable {
        /// On a prayer: the voice sounding or paused on it, or silent
        case onPrayer
        /// The breath after a prayer, the next to follow by itself
        case breath
        /// Paused in the breath: play goes on to the next prayer
        case heldInBreath
        /// The next prayer on its way in, to sound when it arrives
        case arriving
        /// Paused while it was on its way: it arrives held
        case heldArriving
    }

    /// What the screen does for a request
    enum Act: Equatable {
        case nothing
        /// Pause the voice where it is (and let go of the breath)
        case pause
        /// On to the next prayer, or Amen after the last
        case goToNext
        /// Play the prayer under the hand: resumed if loaded, else loaded
        case resume
    }

    private(set) var stage: Stage = .onPrayer

    /// Whether the voice counts as going on: sounding, in the breath, or
    /// with the next prayer on its way to begin by itself. The disc shows
    /// Pause through all three, and a tap pauses.
    func goesOn(voiceSounding: Bool) -> Bool {
        switch stage {
        case .breath, .arriving: true
        case .onPrayer: voiceSounding
        case .heldInBreath, .heldArriving: false
        }
    }

    /// Whether a prayer arriving now should begin: not once a pause was
    /// asked for while it was on its way
    var startsOnArrival: Bool { stage != .heldArriving }

    mutating func breathBegan() { stage = .breath }

    /// The next prayer set on its way. A pause already asked for while it
    /// was (the page still turning) holds
    mutating func turnBegan() {
        if stage != .heldArriving { stage = .arriving }
    }

    /// The prayer arrived (or could not): the voice is on it now
    mutating func arrived() {
        if stage == .arriving || stage == .heldArriving { stage = .onPrayer }
    }

    mutating func reset() { stage = .onPrayer }

    mutating func handle(_ request: AudioService.TransportRequest, voiceSounding: Bool) -> Act {
        switch request {
        case .toggle:
            return handle(goesOn(voiceSounding: voiceSounding) ? .pause : .play, voiceSounding: voiceSounding)
        case .pause:
            switch stage {
            case .breath:
                stage = .heldInBreath
                return .pause
            case .arriving:
                stage = .heldArriving
                return .pause
            case .onPrayer:
                return .pause
            case .heldInBreath, .heldArriving:
                return .nothing
            }
        case .play:
            switch stage {
            case .heldInBreath:
                stage = .onPrayer
                return .goToNext
            case .heldArriving:
                // Still on its way: it begins when it arrives
                stage = .arriving
                return .nothing
            case .onPrayer:
                return voiceSounding ? .nothing : .resume
            case .breath, .arriving:
                return .nothing
            }
        }
    }
}
