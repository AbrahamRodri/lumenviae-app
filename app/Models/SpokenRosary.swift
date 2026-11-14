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
        case .cross:
            return String(localized: "The crucifix", comment: "VoiceOver: the part of the rosary's pendant the voice is on, the crucifix")
        case .largeBead:
            return String(localized: "The large bead", comment: "VoiceOver: the part of the rosary's pendant the voice is on, the large bead above the cross")
        case .smallBead(let index):
            return String(
                localized: "Small bead \(index + 1) of 3",
                comment: "VoiceOver: the part of the rosary's pendant the voice is on, one of the three small beads, like Small bead 2 of 3"
            )
        case .chain:
            return String(localized: "The chain", comment: "VoiceOver: the part of the rosary's pendant the voice is on, the chain")
        case .medal:
            return String(
                localized: "The medal",
                comment: "VoiceOver: the part of the rosary's pendant the voice is on, the centrepiece medal where the decades join"
            )
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
        phase == .closing
            ? String(localized: "The Closing Prayers", comment: "Prayer screen: heading over the prayers said after the last decade")
            : String(localized: "The Opening Prayers", comment: "Prayer screen: heading over the prayers said on the cross and first beads")
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
        /// Words with no recording (a novena's meditation, its closing
        /// prayer), by their id: shown and held for their reading time
        /// (`HeldWords`), then the voice goes on by itself
        case words(String)

        /// A stable name for what is heard, the same in every language,
        /// kept with a resume step so it can be matched again
        var key: String {
            switch self {
            case .prayer(let id): return "prayer:\(id)"
            case .announcement: return "announcement"
            case .meditation: return "meditation"
            case .verse(let number): return "verse:\(number)"
            case .words(let id): return "words:\(id)"
            }
        }
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

    /// The words a `.words` segment shows and holds for
    var held: HeldWords? = nil

    /// Silence after the segment before the next begins. A pause after a
    /// meditation lets it settle before the Our Father; a Hail Mary runs
    /// on to the next as a Rosary said aloud does.
    var pauseAfter: Double {
        switch kind {
        case .meditation: return 2.0
        case .announcement: return 1.2
        case .verse: return 0.8
        case .prayer: return 0.9
        case .words: return 0.6
        }
    }
}

// MARK: - HeldWords

/// Words said in the Rosary's course that have no recording: a novena
/// day's meditation, its invocation, its closing prayer. The voice holds
/// on them for the time they take to read, then goes on by itself; a
/// pause holds the time, and Next goes on at once.
struct HeldWords: Hashable {
    var id: String
    var title: String?
    var text: String
    var source: String?
    /// A short invocation said after the words, on the same step ("Mary,
    /// Undoer of Knots, pray for me.")
    var invocation: String? = nil

    /// Words at 150 a minute and five seconds more, never under twenty
    var readingSeconds: Double {
        let words = (text + " " + (invocation ?? "")).split { $0.isWhitespace }.count
        return max(20, Double(words) / 150 * 60 + 5)
    }
}

// MARK: - SpokenNovenaDay

/// What a novena day adds to the Rosary it is prayed in (design plan, "The
/// continuous day"): parts after the Sign of the Cross, parts between two
/// decades, and parts after the Rosary's closing prayer, before the last
/// Sign of the Cross. Each is a recorded prayer or held words.
struct SpokenNovenaDay: Hashable {
    enum Insert: Hashable {
        case prayer(id: String, caption: String)
        case words(caption: String, HeldWords)
    }

    var opening: [Insert] = []
    /// By the 0-based decade they follow
    var afterDecade: [Int: [Insert]] = [:]
    var closing: [Insert] = []

    /// The prayers the Rosary's voice has recordings of: a novena part
    /// naming one is said, any other prayer is shown and held
    static let recordedPrayers: Set<String> = [
        "sign_of_cross", "apostles_creed", "our_father", "hail_mary", "glory_be", "fatima_prayer",
        "hail_holy_queen", "rosary_closing_prayer", "act_of_contrition", "sorrows_closing_prayer", "memorare",
        "st_michael_prayer",
    ]

    /// A day of a novena laid out for the Rosary: `book` finds a prayer's
    /// title and English by id. Parts before the first `rosary` part open,
    /// parts between two follow the last decade of the one before, and
    /// parts after the last close. A day with no `rosary` part gives nil.
    static func make(
        from day: PrayerBookDocument.Day, book: (String) -> (title: String, text: String)?
    ) -> SpokenNovenaDay? {
        guard day.parts.contains(where: \.isRosary) else { return nil }
        var result = SpokenNovenaDay()
        var lastDecade: Int?
        for part in day.parts {
            if part.isRosary {
                lastDecade = (part.decades ?? []).max().map { $0 - 1 } ?? lastDecade
                continue
            }
            var inserts: [Insert] = []
            // An invocation stands under the words before it, on their step
            if part.kind == "invocation", part.prayerID == nil, let text = part.text {
                func attach(_ list: inout [Insert]) -> Bool {
                    guard case .words(let caption, var words)? = list.last, words.invocation == nil else { return false }
                    words.invocation = text
                    list[list.count - 1] = .words(caption: caption, words)
                    return true
                }
                let attached: Bool
                if let decade = lastDecade, decade >= 4 {
                    attached = attach(&result.closing)
                } else if let decade = lastDecade {
                    attached = attach(&result.afterDecade[decade, default: []])
                } else {
                    attached = attach(&result.opening)
                }
                if attached { continue }
            }
            if let id = part.prayerID {
                let found = book(id)
                let caption = part.title ?? found?.title ?? id
                for _ in 0..<max(part.times ?? 1, 1) {
                    if recordedPrayers.contains(id) {
                        inserts.append(.prayer(id: id, caption: caption))
                    } else if let found {
                        inserts.append(
                            .words(caption: caption, HeldWords(id: id, title: found.title, text: found.text, source: nil)))
                    }
                }
            } else if let text = part.text, !text.isEmpty {
                let id = part.id ?? "\(day.number).\(part.kind)"
                inserts.append(
                    .words(
                        caption: part.title ?? caption(forKind: part.kind),
                        HeldWords(id: id, title: part.title, text: text, source: part.source)))
            }
            if let decade = lastDecade {
                if decade >= 4 {
                    result.closing += inserts
                } else {
                    result.afterDecade[decade, default: []] += inserts
                }
            } else {
                result.opening += inserts
            }
        }
        return result
    }

    static func caption(forKind kind: String) -> String {
        switch kind {
        case "meditation":
            return String(localized: "Today's Meditation", comment: "Prayer screen, novena day: caption over the day's meditation")
        case "closing":
            return String(localized: "The Closing Prayer", comment: "Prayer screen: caption while the closing prayer after the Rosary or the chaplet is said")
        default:
            return String(localized: "The Novena", comment: "Prayer screen, novena day: caption over a part of the novena with no title of its own")
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
        case .holyFather: return String(localized: "For the Pope's intentions", comment: "Settings, After the Rosary: name of a prayer said after the Rosary")
        case .memorare: return String(localized: "Memorare", comment: "Settings, After the Rosary: name of a prayer said after the Rosary")
        case .stMichael: return String(localized: "Saint Michael Prayer", comment: "Settings, After the Rosary: name of a prayer said after the Rosary")
        }
    }

    /// The name where three share a row: the set's page
    var shortTitle: String {
        switch self {
        case .holyFather: return String(localized: "The Pope", comment: "Short name of a prayer said after the Rosary, for a summary line")
        case .memorare: return String(localized: "Memorare", comment: "Short name of a prayer said after the Rosary, for a summary line")
        case .stMichael: return String(localized: "St. Michael", comment: "Short name of a prayer said after the Rosary, for a summary line")
        }
    }

    /// What the setting adds, said as what is prayed
    var detail: String {
        switch self {
        case .holyFather: return String(localized: "An Our Father, Hail Mary and Glory Be after the Rosary, for what the Pope asks the Church to pray for.", comment: "Settings, After the Rosary: the line under a prayer said after the Rosary")
        case .memorare: return String(localized: "The prayer “Remember, O most gracious Virgin Mary” after the Rosary.", comment: "Settings, After the Rosary: the line under a prayer said after the Rosary")
        case .stMichael: return String(localized: "The Prayer to Saint Michael after the Rosary.", comment: "Settings, After the Rosary: the line under a prayer said after the Rosary")
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
            return [("memorare", String(localized: "The Memorare", comment: "Prayer screen: caption while the Memorare is said after the Rosary"))]
        case .stMichael:
            return [
                (
                    "st_michael_prayer",
                    String(localized: "Prayer to Saint Michael", comment: "Prayer screen: caption while the Prayer to Saint Michael is said after the Rosary")
                )
            ]
        }
    }

    static let holyFatherCaption = String(
        localized: "For the Pope's intentions",
        comment: "Prayer screen: caption while the Our Father, Hail Mary and Glory Be for the Pope's intentions are said after the Rosary"
    )

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
        extras: [RosaryClosingExtra] = [],
        novena: SpokenNovenaDay? = nil
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
        let signOfTheCross = String(
            localized: "The Sign of the Cross",
            comment: "Prayer screen: caption while the Sign of the Cross is said, opening and closing the Rosary"
        )
        let ourFather = String(localized: "The Our Father", comment: "Prayer screen: caption while the Our Father is said")
        let gloryBeCaption = String(localized: "The Glory Be", comment: "Prayer screen: caption while the Glory Be is said")
        let closingPrayer = String(
            localized: "The Closing Prayer",
            comment: "Prayer screen: caption while the closing prayer after the Rosary or the chaplet is said"
        )
        func insert(_ inserts: [SpokenNovenaDay.Insert], phase: SpokenSegment.Phase, mystery: Int, bead: Int, key: String) {
            for item in inserts {
                switch item {
                case .prayer(let id, let caption):
                    script.append(SpokenSegment(
                        kind: .prayer(id), phase: phase, mystery: mystery, bead: bead, mysteryKey: key,
                        caption: caption, place: phase == .decade ? nil : .cross))
                case .words(let caption, let words):
                    script.append(SpokenSegment(
                        kind: .words(words.id), phase: phase, mystery: mystery, bead: bead, mysteryKey: key,
                        caption: caption, held: words))
                }
            }
        }

        opening("sign_of_cross", signOfTheCross, .cross)
        insert(novena?.opening ?? [], phase: .opening, mystery: 0, bead: 0, key: firstKey)
        if isChaplet {
            opening(
                "act_of_contrition",
                String(localized: "The Act of Contrition", comment: "Prayer screen: caption while the Act of Contrition opens the Seven Sorrows chaplet"),
                .cross
            )
        } else {
            opening(
                "apostles_creed",
                String(localized: "The Apostles' Creed", comment: "Prayer screen: caption while the Apostles' Creed is said on the cross"),
                .cross
            )
            opening("our_father", ourFather, .largeBead)
            let virtues = [
                String(localized: "A Hail Mary for faith", comment: "Prayer screen: caption for the first of the three opening Hail Marys, said for faith"),
                String(localized: "A Hail Mary for hope", comment: "Prayer screen: caption for the second of the three opening Hail Marys, said for hope"),
                String(
                    localized: "A Hail Mary for charity",
                    comment: "Prayer screen: caption for the third of the three opening Hail Marys, said for charity"
                ),
            ]
            for (index, caption) in virtues.enumerated() {
                opening("hail_mary", caption, .smallBead(index))
            }
            opening("glory_be", gloryBeCaption, .chain)
        }

        for (decade, key) in mysteryKeys.enumerated() {
            func add(_ kind: SpokenSegment.Kind, bead: Int, _ caption: String) {
                script.append(SpokenSegment(
                    kind: kind, phase: .decade, mystery: decade, bead: bead,
                    mysteryKey: key, caption: caption
                ))
            }

            add(
                .announcement,
                bead: 0,
                isChaplet
                    ? String(localized: "The sorrow", comment: "Prayer screen: caption while a sorrow of the chaplet is announced")
                    : String(localized: "The mystery", comment: "Prayer screen: caption while a mystery of the Rosary is announced")
            )
            if style == .meditation {
                add(.meditation, bead: 0, String(localized: "The meditation", comment: "Prayer screen: caption while the mystery's meditation is read aloud"))
            }
            add(.prayer("our_father"), bead: 0, ourFather)

            for number in 1...max(hailMarys, 1) {
                if style == .scriptural {
                    add(
                        .verse(number),
                        bead: number,
                        String(
                            localized: "Scripture · \(number) of \(hailMarys)",
                            comment: "Prayer screen: caption while the verse before a Hail Mary is read, like Scripture · 4 of 10"
                        )
                    )
                }
                add(
                    .prayer("hail_mary"),
                    bead: number,
                    String(
                        localized: "Hail Mary · \(number) of \(hailMarys)",
                        comment: "Prayer screen: name of a Hail Mary bead and which of the decade's Hail Marys it is, like Hail Mary · 4 of 10"
                    )
                )
            }

            add(.prayer("glory_be"), bead: gloryBe, gloryBeCaption)
            if !isChaplet {
                add(.prayer("fatima_prayer"), bead: gloryBe, String(localized: "The Fatima Prayer", comment: "Prayer screen: caption while the Fatima Prayer is said"))
            }
            // A novena day's parts between this decade and the next, on
            // the Glory Be's bead
            if decade < lastDecade {
                insert(novena?.afterDecade[decade] ?? [], phase: .decade, mystery: decade, bead: gloryBe, key: key)
            }
        }

        if isChaplet {
            // The chaplet closes with three Hail Marys in honor of the
            // tears Our Lady shed in her sorrows, and its own prayer
            for number in 1...3 {
                closing(
                    "hail_mary",
                    String(
                        localized: "In honor of her tears · \(number) of 3",
                        comment: "Prayer screen, end of the Seven Sorrows chaplet: caption for one of three Hail Marys said in honor of Mary's tears"
                    ),
                    .smallBead(number - 1)
                )
            }
            closing("sorrows_closing_prayer", closingPrayer, .medal)
        } else {
            closing(
                "hail_holy_queen",
                String(localized: "Hail, Holy Queen", comment: "Prayer screen: caption while the Hail, Holy Queen is said after the last decade"),
                .medal
            )
            closing("rosary_closing_prayer", closingPrayer, .medal)
            for extra in RosaryClosingExtra.ordered(extras) {
                for prayer in extra.prayers {
                    closing(prayer.id, prayer.caption, .medal)
                }
            }
        }
        insert(novena?.closing ?? [], phase: .closing, mystery: lastDecade, bead: gloryBe, key: lastKey)
        closing("sign_of_cross", signOfTheCross, .cross)

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
        guard segment.mystery == step.mystery, segment.bead == step.bead else { return nil }
        // Matched on what is heard. A step saved before the kind was kept
        // falls back to its caption, which is in the language it was saved in
        if let kind = step.kind {
            guard segment.kind.key == kind else { return nil }
        } else {
            guard segment.caption == step.caption else { return nil }
        }
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
    /// `SpokenSegment.Kind.key`; nil in a step saved before it was kept
    var kind: String? = nil
}
