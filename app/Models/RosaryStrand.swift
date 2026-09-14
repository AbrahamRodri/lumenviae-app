//
//  RosaryStrand.swift
//  Lumen Viae
//
//  The whole Rosary as one string of beads, and the arithmetic of
//  walking it. Both players — the meditation's and the Scriptural
//  Rosary's — pray bead by bead on the same strand, so where a bead
//  falls on the string and what it is called are worked out here once.
//
//  A decade is its Our Father bead followed by its Hail Marys (ten, or
//  seven for a sorrow of the chaplet). The Glory Be has no bead of its
//  own on a real rosary: it is said on the chain before the next Our
//  Father, so here it is drawn on the next decade's Our Father bead —
//  the same bead the hand lands on for the decade that follows — and,
//  after the last decade, on one final bead where the Rosary ends.
//

import Foundation

// MARK: - BeadPosition

/// Where the hand is, as one value: which mystery, and which bead of
/// its decade. The screens' haptics key on it so one move is one tick
/// whether the bead moved, the mystery moved, or both at once.
struct BeadPosition: Hashable {
    let mystery: Int
    let bead: Int
}

// MARK: - RosaryStrand

struct RosaryStrand: Hashable {

    /// Decades on the string — five, or the seven sorrows
    let decades: Int

    /// Hail Marys in each decade
    let hailMarys: Int

    /// One decade's beads: its Our Father and its Hail Marys
    var decadeLength: Int { hailMarys + 1 }

    /// Every bead on the string, the final bead included
    var count: Int { decades * decadeLength + 1 }

    /// The bead of the decade the decade is prayed on: one past its
    /// last Hail Mary, where the Glory Be is said
    var gloryBe: Int { hailMarys + 1 }

    // MARK: - Beads

    /// What one bead on the string is.
    enum Bead: Hashable {
        /// The bead a decade opens on; `decade` is 0-based
        case ourFather(decade: Int)
        /// One of the decade's Hail Marys; `number` counts from 1
        case hailMary(decade: Int, number: Int)
        /// The last bead of all, where the Rosary is finished
        case amen
    }

    /// The bead at one position on the string, counted from the first
    /// Our Father.
    func bead(at index: Int) -> Bead {
        guard index < decades * decadeLength else { return .amen }
        let decade = index / decadeLength
        let offset = index % decadeLength
        return offset == 0
            ? .ourFather(decade: decade)
            : .hailMary(decade: decade, number: offset)
    }

    /// Where a position in a decade falls on the string. The Glory Be
    /// position lands on the next decade's Our Father bead — or, after
    /// the last decade, on the final bead.
    func index(mystery: Int, bead: Int) -> Int {
        let clamped = min(max(bead, 0), decadeLength)
        return min(mystery * decadeLength + clamped, count - 1)
    }

    // MARK: - Names

    /// What the bead under the hand is called: the prayer said on it.
    /// A decade closes on the Glory Be and the Fatima Prayer together,
    /// as Our Lady asked at Fatima, so the closing bead is named for both.
    func label(bead: Int) -> String {
        if bead <= 0 { return "Our Father" }
        if bead > hailMarys { return "Glory Be & Fatima Prayer" }
        return "Hail Mary · \(bead) of \(hailMarys)"
    }

    /// The same name broken for the strand's margin, where a line is a
    /// dozen characters: the prayer, then its count or its companion.
    func labelLines(bead: Int) -> [String] {
        if bead <= 0 { return ["Our Father"] }
        if bead > hailMarys { return ["Glory Be &", "Fatima Prayer"] }
        return ["Hail Mary", "\(bead) of \(hailMarys)"]
    }

    /// The label beside a bead on the drawn strand, where one is drawn:
    /// the Our Father beads carry the numeral of the decade they open,
    /// the final bead the Rosary's end. A numeral alone — the bead's
    /// size and its gold ring already say it is an Our Father, and the
    /// words spelt out beside every one of them ran a hundred points
    /// into the reading, sliding under its last words as the string
    /// moved.
    func strandLabel(at index: Int) -> String? {
        switch bead(at: index) {
        case .ourFather(let decade): return Self.roman(decade + 1)
        case .hailMary: return nil
        case .amen: return "Amen"
        }
    }

    /// I through X, which is as far as any string here runs.
    static func roman(_ number: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        guard number >= 1, number <= numerals.count else { return "\(number)" }
        return numerals[number - 1]
    }
}
