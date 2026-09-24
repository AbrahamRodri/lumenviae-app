//
//  GuidedRosary.swift
//  Lumen Viae
//
//  The Rosary as an object in the hand, and as a sequence of steps for
//  someone praying it for the first time.
//
//  `RosaryPart` names every bead of a real rosary — the crucifix, the
//  pendant (a large bead, three small, a large), the centrepiece, and
//  the loop of five decades with a large bead between each — and
//  `RosaryMap.traversal` is the order the fingers travel them.
//  `RosaryDiagram` draws the same parts.
//
//  `GuidedRosary.steps(for:)` is the whole Rosary a step at a time,
//  each step tied to the bead under the fingers, what to do there, and
//  the prayers said there, so a beginner never has to know anything in
//  advance. It is the traditional order: Sign of the Cross, Creed, Our
//  Father, three Hail Marys, Glory Be; five decades, each announced,
//  then Our Father, ten Hail Marys, Glory Be and the Fatima Prayer; the
//  Hail, Holy Queen and the closing prayer; the Sign of the Cross.
//  A Glory Be is said on reaching a large bead, before its Our Father —
//  the bead the drawing lights — and every word here says so.
//

import Foundation

// MARK: - RosaryPart

enum RosaryPart: Hashable {
    case crucifix

    /// The pendant's two large beads: 0 by the crucifix, 1 by the
    /// centrepiece
    case pendantLarge(Int)

    /// The pendant's three small beads, 0 nearest the crucifix
    case pendantSmall(Int)

    /// The centrepiece, where the pendant meets the loop
    case medal

    /// A Hail Mary bead of the loop: decade 0…4, bead 0…9
    case loopSmall(decade: Int, bead: Int)

    /// A large bead of the loop, between decades: 0…3, carrying the Our
    /// Father of decades two to five
    case loopLarge(Int)
}

// MARK: - RosaryMap

enum RosaryMap {

    /// The loop, from the centrepiece round: fifty small beads in five
    /// tens, a large bead between each ten
    static let loop: [RosaryPart] = (0..<5).flatMap { decade -> [RosaryPart] in
        let tens = (0..<10).map { RosaryPart.loopSmall(decade: decade, bead: $0) }
        return decade < 4 ? tens + [.loopLarge(decade)] : tens
    }

    /// The order the fingers travel: up the pendant, round the loop, and
    /// back to the centrepiece
    static let traversal: [RosaryPart] =
        [.crucifix, .pendantLarge(0), .pendantSmall(0), .pendantSmall(1), .pendantSmall(2), .pendantLarge(1)]
        + loop
        + [.medal]

    /// The bead a decade's Our Father is said on
    static func ourFatherBead(decade: Int) -> RosaryPart {
        decade == 0 ? .pendantLarge(1) : .loopLarge(decade - 1)
    }

    /// Where the fingers are in the traversal, for the diagram's
    /// prayed / ahead colouring
    static func position(of part: RosaryPart) -> Int {
        traversal.firstIndex(of: part) ?? 0
    }

    // MARK: The Parts, Explained

    /// The parts of a rosary as a beginner learns them, each with the
    /// beads it names and what is prayed there
    struct Anatomy: Identifiable {
        let id: String
        let name: String
        let prayed: String
        let parts: Set<RosaryPart>
    }

    static let anatomy: [Anatomy] = [
        Anatomy(
            id: "crucifix",
            name: "The crucifix",
            prayed: "Where the Rosary begins and ends. Hold it for the Sign of the Cross and the Apostles' Creed.",
            parts: [.crucifix]
        ),
        Anatomy(
            id: "first_large",
            name: "The first large bead",
            prayed: "An Our Father, the prayer Jesus taught.",
            parts: [.pendantLarge(0)]
        ),
        Anatomy(
            id: "three_small",
            name: "The three small beads",
            prayed: "Three Hail Marys, asking for an increase of faith, hope and charity.",
            parts: [.pendantSmall(0), .pendantSmall(1), .pendantSmall(2)]
        ),
        Anatomy(
            id: "second_large",
            name: "The next large bead",
            prayed: "The Glory Be first, on reaching it. Then the first mystery is announced, and its Our Father said on this bead.",
            parts: [.pendantLarge(1)]
        ),
        Anatomy(
            id: "medal",
            name: "The centrepiece",
            prayed: "Where the loop begins, and where the Rosary is closed with the Hail, Holy Queen.",
            parts: [.medal]
        ),
        Anatomy(
            id: "decade",
            name: "A decade",
            prayed: "Ten small beads: ten Hail Marys while you think about one mystery. There are five decades, one for each mystery.",
            parts: Set((0..<10).map { RosaryPart.loopSmall(decade: 0, bead: $0) })
        ),
        Anatomy(
            id: "between",
            name: "The large beads between",
            prayed: "On each, the Glory Be and the Fatima Prayer close one decade; then the next mystery is announced, and its Our Father said on the same bead.",
            parts: [.loopLarge(0), .loopLarge(1), .loopLarge(2), .loopLarge(3)]
        )
    ]
}

// MARK: - GuidedStep

struct GuidedStep: Identifiable {
    let id: Int

    /// The bead under the fingers
    let part: RosaryPart

    /// Where on the Rosary, in small capitals: "THE CRUCIFIX", "THE
    /// ANNUNCIATION · 3 OF 10"
    let place: String

    /// What to do here, in plain words
    let instruction: String

    /// The prayers said here, in order (`DevotionPrayers`)
    var prayerIDs: [String] = []

    /// The decade this step belongs to, when it belongs to one
    var decade: Int? = nil

    /// The step that names the mystery before its decade
    var isAnnouncement = false

    /// A step of the close, after the last decade: every bead is behind
    /// the fingers, so the drawing shows the whole rosary prayed
    var isClosing = false
}

// MARK: - GuidedRosary

enum GuidedRosary {

    /// How the Prayer Record names a Rosary prayed with the guide. It
    /// counts as the day's Rosary, like any other.
    static let devotionName = "A Guided Rosary"

    /// The mysteries the guide can walk: the four sets of the Rosary.
    /// The Seven Sorrows are a chaplet of seven, not a Rosary.
    static func isGuidable(_ category: MysteryCategory) -> Bool {
        category != .sevenSorrows
    }

    static func steps(for category: MysteryCategory) -> [GuidedStep] {
        let mysteries = MysteryData.mysteries(for: category)
        var steps: [GuidedStep] = []

        func add(
            _ part: RosaryPart,
            _ place: String,
            _ instruction: String,
            prayers: [String] = [],
            decade: Int? = nil,
            announcement: Bool = false,
            closing: Bool = false
        ) {
            steps.append(GuidedStep(
                id: steps.count,
                part: part,
                place: place,
                instruction: instruction,
                prayerIDs: prayers,
                decade: decade,
                isAnnouncement: announcement,
                isClosing: closing
            ))
        }

        // The opening, on the pendant
        add(.crucifix, "The crucifix",
            "Take the crucifix in your hand. Touch your forehead, your breast, your left shoulder and your right as you say:",
            prayers: ["sign_of_cross"])
        add(.crucifix, "The crucifix",
            "Still holding the crucifix, profess the faith of the Church. Everything the Rosary is about is in this prayer.",
            prayers: ["apostles_creed"])
        add(.pendantLarge(0), "The first large bead",
            "Move your fingers up to the first large bead, and pray the prayer Jesus taught His disciples.",
            prayers: ["our_father"])

        let virtues = ["faith", "hope", "charity"]
        for (index, virtue) in virtues.enumerated() {
            add(.pendantSmall(index), "Small bead · \(index + 1) of 3",
                index == 0
                    ? "On each of the next three small beads, a Hail Mary. This first one asks God for an increase of \(virtue)."
                    : "The next small bead: a Hail Mary for an increase of \(virtue).",
                prayers: ["hail_mary"])
        }

        // The Glory Be is said on reaching the large bead, before the
        // mystery and its Our Father — the bead the drawing lights, so
        // the words say so too
        add(.pendantLarge(1), "The next large bead",
            "Move up to the next large bead. Before anything else is said on it, give glory to the Holy Trinity.",
            prayers: ["glory_be"])

        // The five decades
        for (decade, mystery) in mysteries.prefix(5).enumerated() {
            let ordinal = mystery.ordinalName
            let bead = RosaryMap.ourFatherBead(decade: decade)

            add(bead, "The \(ordinal) \(category.displayName) Mystery",
                decade == 0
                    ? "Now the heart of the Rosary. Each decade is spent with one scene from the life of Jesus and Mary. Say its name, aloud or silently, and picture it."
                    : "Say the name of the next mystery, and picture the scene.",
                decade: decade,
                announcement: true)

            add(bead, "\(mystery.name) · the large bead",
                decade == 0
                    ? "On the large bead, the Our Father. Keep the scene before you as you pray."
                    : "On the large bead, the Our Father.",
                prayers: ["our_father"],
                decade: decade)

            for bead in 0..<10 {
                let instruction: String
                switch (decade, bead) {
                case (0, 0):
                    instruction = "Ten Hail Marys, one on each small bead. The words are the same each time; let them carry you while your mind stays with \(mystery.name.lowercasedArticle)."
                case (0, 1):
                    instruction = "The next bead. If your mind wanders, simply come back to the scene."
                case (_, 0):
                    instruction = "Ten Hail Marys on \(mystery.name.lowercasedArticle)."
                case (_, 9):
                    instruction = "The last of the ten."
                default:
                    instruction = "Stay with \(mystery.name.lowercasedArticle)."
                }

                add(.loopSmall(decade: decade, bead: bead),
                    "\(mystery.name) · \(bead + 1) of 10",
                    instruction,
                    prayers: ["hail_mary"],
                    decade: decade)
            }

            let closingBead: RosaryPart = decade < 4 ? .loopLarge(decade) : .medal
            add(closingBead, "The decade closes",
                decade == 0
                    ? "Move on to the next large bead. Before its Our Father, close the decade: the Glory Be, and the prayer Our Lady asked for at Fatima. You have prayed one decade."
                    : decade == 4
                        ? "Move on to the centrepiece, and close the last decade."
                        : "On the next large bead, before its Our Father, close the decade.",
                prayers: ["glory_be", "fatima_prayer"],
                decade: decade)
        }

        // The close, on the centrepiece and the crucifix
        add(.medal, "The centrepiece",
            "You have come round to the centrepiece. Hold it, and greet Our Lady as Queen and Mother.",
            prayers: ["hail_holy_queen"],
            closing: true)
        add(.medal, "The centrepiece",
            "The closing prayer asks that what the mysteries hold may become ours.",
            prayers: ["rosary_closing_prayer"],
            closing: true)
        add(.crucifix, "The crucifix",
            "End as you began, with the Sign of the Cross.",
            prayers: ["sign_of_cross"],
            closing: true)

        return steps
    }
}

private extension String {
    /// "The Annunciation" → "the Annunciation", for use mid-sentence
    var lowercasedArticle: String {
        hasPrefix("The ") ? "the " + dropFirst(4) : self
    }
}
