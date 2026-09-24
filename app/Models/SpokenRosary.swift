//
//  SpokenRosary.swift
//  Lumen Viae
//
//  The whole Rosary as a script to be heard: every prayer said aloud, in
//  order, from the Sign of the Cross to the last Amen, with each decade
//  opened by its announcement and — in a meditation Rosary — its
//  narrated meditation, or — in the Scriptural Rosary — a verse before
//  every Hail Mary. The Rosary Aloud is the plain one: the prayers and
//  the announcements, and nothing between them.
//
//  Building the script is pure: no audio, no network, no views. The
//  player (SpokenRosaryPlayer) walks it; each segment says which bead of
//  the strand it is prayed on, so the beads on screen move with the
//  voice and a bead moved by hand is a place in the script to go to.
//

import Foundation

// MARK: - PendantPlace

/// Where on the pendant a prayer of the opening or the close is said,
/// climbing from the crucifix to the centrepiece: the Sign of the Cross
/// and the Creed on the cross, the Our Father on the large bead, the three
/// Hail Marys on the small beads, the Glory Be on the chain, and the Hail,
/// Holy Queen at the centrepiece where the loop begins.
enum PendantPlace: Hashable {
    case cross
    case largeBead
    case smallBead(Int)
    case chain
    case medal

    /// Height up the pendant, counted from the cross
    var rank: Int {
        switch self {
        case .cross: return 0
        case .largeBead: return 1
        case .smallBead(let index): return 2 + index
        case .chain: return 5
        case .medal: return 6
        }
    }

    /// What the bead is called, for VoiceOver
    var name: String {
        switch self {
        case .cross: return "The crucifix"
        case .largeBead: return "The large bead"
        case .smallBead(let index): return "Small bead \(index + 1) of 3"
        case .chain: return "The chain"
        case .medal: return "The centrepiece"
        }
    }
}

// MARK: - SpokenPendant

/// The opening or closing prayer being said, as the screen shows it: the
/// pendant drawn in place of a mystery's painting, the bead lit, and the
/// prayer named.
struct SpokenPendant: Equatable {
    let phase: SpokenSegment.Phase
    let prayerID: String
    let title: String
    let place: PendantPlace?

    /// The Seven Sorrows chaplet, whose pendant has no large bead
    let isChaplet: Bool

    var heading: String {
        phase == .closing ? "The Closing Prayers" : "The Opening Prayers"
    }
}

// MARK: - SpokenSegment

struct SpokenSegment: Hashable {

    /// What is heard
    enum Kind: Hashable {
        /// A fixed prayer, by the app's prayer id (`RosaryPrayers`)
        case prayer(String)
        /// "The First Joyful Mystery: The Annunciation"
        case announcement
        /// The meditation set's narration for this decade
        case meditation
        /// The Scriptural Rosary's verse for one Hail Mary, counted from 1
        case verse(Int)
    }

    /// Where in the Rosary a segment falls. The opening and closing
    /// prayers are said on the pendant, off the decades' strand, so the
    /// screen names them rather than moving a bead.
    enum Phase: Hashable {
        case opening
        case decade
        case closing
    }

    let kind: Kind
    let phase: Phase

    /// The decade, 0-based; the first for the opening, the last for the
    /// closing
    let mystery: Int

    /// The bead on the strand: 0 the Our Father, 1 through the Hail Marys
    /// that Hail Mary, one past the last the Glory Be — `RosaryStrand`'s
    /// arithmetic
    let bead: Int

    /// "<category>_<order>" of this decade's mystery
    let mysteryKey: String

    /// What the screen calls the prayer being said
    let caption: String

    /// Where on the pendant an opening or closing prayer is said
    var place: PendantPlace? = nil

    /// Silence after the segment before the next begins. A pause after a
    /// meditation lets it settle before the Our Father; a Hail Mary runs
    /// on to the next as a Rosary said aloud does.
    var pauseAfter: Double {
        switch kind {
        case .meditation: return 2.0
        case .announcement: return 1.2
        case .verse: return 0.8
        case .prayer: return 0.9
        }
    }
}

// MARK: - RosaryClosingExtra

/// The prayers some add after the Rosary's closing prayer and before the
/// last Sign of the Cross, each chosen in Settings and off until chosen.
/// Declared in the order they are said. Never added to the chaplet of
/// the Seven Sorrows, which closes in its own way.
enum RosaryClosingExtra: String, CaseIterable, Hashable {
    /// An Our Father, a Hail Mary and a Glory Be for the Pope's
    /// intentions, said with the recordings the Rosary already has
    case holyFather
    case memorare
    case stMichael

    /// What the setting is called
    var title: String {
        switch self {
        case .holyFather: return "For the Holy Father's intentions"
        case .memorare: return "Memorare"
        case .stMichael: return "Saint Michael Prayer"
        }
    }

    /// The name where three share a row: the set's page
    var shortTitle: String {
        switch self {
        case .holyFather: return "Holy Father"
        case .memorare: return "Memorare"
        case .stMichael: return "St. Michael"
        }
    }

    /// What the setting adds, said as what is prayed
    var detail: String {
        switch self {
        case .holyFather: return "An Our Father, Hail Mary and Glory Be after the Rosary."
        case .memorare: return "The Memorare after the Rosary."
        case .stMichael: return "The Prayer to Saint Michael after the Rosary."
        }
    }

    var icon: String {
        switch self {
        case .holyFather: return "ch-church"
        case .memorare: return "ch-lily"
        case .stMichael: return "ph-shield"
        }
    }

    /// The prayers said, by the app's prayer ids (`RosaryPrayers`), each
    /// with what the screen calls it while it is said
    var prayers: [(id: String, caption: String)] {
        switch self {
        case .holyFather:
            return ["our_father", "hail_mary", "glory_be"].map { ($0, Self.holyFatherCaption) }
        case .memorare:
            return [("memorare", "The Memorare")]
        case .stMichael:
            return [("st_michael_prayer", "Prayer to Saint Michael")]
        }
    }

    static let holyFatherCaption = "For the intentions of the Holy Father"

    /// The chosen ones, in the order they are said, whatever order they
    /// were chosen in
    static func ordered(_ chosen: some Sequence<RosaryClosingExtra>) -> [RosaryClosingExtra] {
        let set = Set(chosen)
        return allCases.filter { set.contains($0) }
    }
}

// MARK: - SpokenRosaryScript

enum SpokenRosaryScript {

    /// How a decade is prayed between its announcement and its Glory Be.
    /// `everyClip()` walks every style, so a new one is downloaded for
    /// offline use without being named there.
    enum Style: Hashable, CaseIterable {
        /// The set's narrated meditation, then the decade
        case meditation
        /// A verse of Scripture before every Hail Mary
        case scriptural
        /// Nothing between the announcement and the Our Father, and
        /// nothing before a Hail Mary: the Rosary Aloud, the prayers
        /// alone. Every recording it plays is one the other two play too.
        case plain
    }

    /// The script for a whole Rosary.
    ///
    /// The four sets of the Rosary open on the pendant with the Sign of
    /// the Cross, the Creed, an Our Father, three Hail Marys and a Glory
    /// Be; each decade is announced, (meditated,) and prayed as an Our
    /// Father, ten Hail Marys, a Glory Be and the Fatima Prayer; the
    /// close is the Hail, Holy Queen, the closing prayer, any chosen
    /// `extras`, and the Sign of the Cross.
    ///
    /// The chaplet of the Seven Sorrows, in its traditional Servite form,
    /// opens with the Sign of the Cross and the Act of Contrition; each
    /// sorrow is announced, (meditated,) and prayed as an Our Father,
    /// seven Hail Marys and a Glory Be, with no Fatima Prayer; it closes
    /// with three Hail Marys in honor of Our Lady's tears, its own
    /// closing prayer, and the Sign of the Cross. `extras` are not added.
    ///
    /// - Parameters:
    ///   - category: the mysteries being prayed; the Seven Sorrows are the
    ///     chaplet, opened and closed in its own way
    ///   - mysteryKeys: "<category>_<order>" for each decade, in order
    ///   - hailMarys: per decade — ten, or seven for a sorrow
    ///   - extras: the optional prayers after the Rosary's closing prayer
    static func build(
        category: MysteryCategory,
        mysteryKeys: [String],
        hailMarys: Int,
        style: Style,
        extras: [RosaryClosingExtra] = []
    ) -> [SpokenSegment] {
        guard let firstKey = mysteryKeys.first, let lastKey = mysteryKeys.last else { return [] }
        let isChaplet = category == .sevenSorrows
        let lastDecade = mysteryKeys.count - 1
        let gloryBe = hailMarys + 1
        var script: [SpokenSegment] = []

        func opening(_ id: String, _ caption: String, _ place: PendantPlace) {
            script.append(SpokenSegment(
                kind: .prayer(id), phase: .opening, mystery: 0, bead: 0,
                mysteryKey: firstKey, caption: caption, place: place
            ))
        }

        func closing(_ id: String, _ caption: String, _ place: PendantPlace) {
            script.append(SpokenSegment(
                kind: .prayer(id), phase: .closing, mystery: lastDecade, bead: gloryBe,
                mysteryKey: lastKey, caption: caption, place: place
            ))
        }

        // The pendant: the Rosary opens with the Creed, the Our Father and
        // three Hail Marys for faith, hope and charity. The chaplet of the
        // Seven Sorrows opens with the Act of Contrition.
        opening("sign_of_cross", "The Sign of the Cross", .cross)
        if isChaplet {
            opening("act_of_contrition", "The Act of Contrition", .cross)
        } else {
            opening("apostles_creed", "The Apostles' Creed", .cross)
            opening("our_father", "The Our Father", .largeBead)
            for (index, virtue) in ["faith", "hope", "charity"].enumerated() {
                opening("hail_mary", "A Hail Mary for \(virtue)", .smallBead(index))
            }
            opening("glory_be", "The Glory Be", .chain)
        }

        for (decade, key) in mysteryKeys.enumerated() {
            func add(_ kind: SpokenSegment.Kind, bead: Int, _ caption: String) {
                script.append(SpokenSegment(
                    kind: kind, phase: .decade, mystery: decade, bead: bead,
                    mysteryKey: key, caption: caption
                ))
            }

            add(.announcement, bead: 0, isChaplet ? "The sorrow" : "The mystery")
            if style == .meditation {
                add(.meditation, bead: 0, "The meditation")
            }
            add(.prayer("our_father"), bead: 0, "The Our Father")

            for number in 1...max(hailMarys, 1) {
                if style == .scriptural {
                    add(.verse(number), bead: number, "Scripture · \(number) of \(hailMarys)")
                }
                add(.prayer("hail_mary"), bead: number, "Hail Mary · \(number) of \(hailMarys)")
            }

            add(.prayer("glory_be"), bead: gloryBe, "The Glory Be")
            if !isChaplet {
                add(.prayer("fatima_prayer"), bead: gloryBe, "The Fatima Prayer")
            }
        }

        if isChaplet {
            // The chaplet closes with three Hail Marys in honor of the
            // tears Our Lady shed in her sorrows, and its own prayer
            for number in 1...3 {
                closing("hail_mary", "In honor of her tears · \(number) of 3", .smallBead(number - 1))
            }
            closing("sorrows_closing_prayer", "The Closing Prayer", .medal)
        } else {
            closing("hail_holy_queen", "Hail, Holy Queen", .medal)
            closing("rosary_closing_prayer", "The Closing Prayer", .medal)
            for extra in RosaryClosingExtra.ordered(extras) {
                for prayer in extra.prayers {
                    closing(prayer.id, prayer.caption, .medal)
                }
            }
        }
        closing("sign_of_cross", "The Sign of the Cross", .cross)

        return script
    }

    /// Where to begin for a hand resting on `bead` of `mystery`. The very
    /// first bead of the Rosary begins with the opening prayers; any other
    /// Our Father begins with its decade's announcement, and a Hail Mary
    /// with its verse, if it has one.
    static func startIndex(in script: [SpokenSegment], mystery: Int, bead: Int, includingOpening: Bool) -> Int {
        if includingOpening, mystery == 0, bead == 0 { return 0 }
        return script.firstIndex { $0.phase == .decade && $0.mystery == mystery && $0.bead >= bead }
            ?? script.firstIndex { $0.phase == .closing }
            ?? 0
    }

    /// Where to begin a Rosary resumed after an interruption: the step it
    /// stopped on, if the script still has that step where it was — the
    /// closing prayers chosen in Settings may have changed since, and a
    /// step that no longer lines up is not guessed at. Nil sends the
    /// caller back to `startIndex`, the start of the bead.
    static func resumeIndex(in script: [SpokenSegment], step: SpokenStep?) -> Int? {
        guard let step, script.indices.contains(step.index) else { return nil }
        let segment = script[step.index]
        guard segment.mystery == step.mystery, segment.bead == step.bead,
              segment.caption == step.caption else { return nil }
        return step.index
    }

    /// Every recording any spoken Rosary can play — every set of
    /// mysteries and the chaplet, in every style, with every closing
    /// prayer — for the offline library, so the first Rosary said aloud
    /// needs no connection. Verses are named for as many as each mystery
    /// has; a recording the server does not have is passed over.
    static func everyClip() -> Set<RosaryAudioPack.ClipID> {
        var every = Set<RosaryAudioPack.ClipID>()
        for category in MysteryCategory.allCases {
            let mysteries = MysteryData.mysteries(for: category)
            let keys = mysteries.map { "\($0.category.lowercased())_\($0.order)" }
            let hailMarys = category == .sevenSorrows ? 7 : 10
            for style in Style.allCases {
                every.formUnion(clips(in: build(
                    category: category,
                    mysteryKeys: keys,
                    hailMarys: hailMarys,
                    style: style,
                    extras: RosaryClosingExtra.allCases
                )))
            }
            for (mystery, key) in zip(mysteries, keys) {
                let count = ScripturalRosaryData.verses(
                    category: mystery.category.lowercased(),
                    order: mystery.order
                )?.count ?? 0
                for number in stride(from: 1, through: count, by: 1) {
                    every.insert(.verse(key, number))
                }
            }
        }
        return every
    }

    /// Every recording a script plays, for fetching before the first word
    /// is said. Meditations are the set's own narration and are left out.
    static func clips(in script: [SpokenSegment]) -> Set<RosaryAudioPack.ClipID> {
        Set(script.compactMap { RosaryAudioPack.ClipID(segment: $0) })
    }
}

// MARK: - SpokenStep

/// One place in a spoken Rosary's script, kept with the resume snapshot
/// (`PrayerResumeService`) so a Rosary said aloud and interrupted comes
/// back on the prayer it stopped at — the third Hail Mary's verse, the
/// Memorare — rather than only at its bead. The mystery, bead and caption
/// are the segment's own, so a script built differently next time can be
/// told from the one the step was taken in.
struct SpokenStep: Codable, Equatable {
    let index: Int
    let mystery: Int
    let bead: Int
    let caption: String
}
