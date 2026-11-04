//
//  OneRosary.swift
//  Lumen Viae
//
//  The pure parts of the One Rosary beta (`UserSettings.oneRosaryBeta`):
//  the whole Rosary at a glance before PRAY (`RosaryOverview`), the
//  Guided Rosary's plain words on the Rosary itself (`RosaryHelps`), and
//  which beads of the strand a tap may go to (`RosaryStrand.canTap`).
//
//  Off, nothing here is read, and the app is as it was.
//

import Foundation

// MARK: - RosaryOverview

/// The order of one Rosary, opening to close, for the overview on its
/// own page: the opening prayers, each mystery by name, the closing
/// prayers. The chaplet of the Seven Sorrows opens and closes its own
/// way, and has seven.
struct RosaryOverview: Equatable {

    enum Kind: Equatable {
        case opening
        case mystery(Int)
        case closing
    }

    struct Part: Equatable, Identifiable {
        let kind: Kind
        let title: String
        var detail: String?

        var id: String {
            switch kind {
            case .opening: return "opening"
            case .mystery(let n): return "mystery.\(n)"
            case .closing: return "closing"
            }
        }

        /// The beads of the drawn rosary this part is prayed on, lit in
        /// the drawing while the part is chosen in the list. The first
        /// mystery's Our Father hangs on the pendant's second large bead
        /// (`RosaryMap.ourFatherBead`), so the opening ends below it.
        var beads: Set<RosaryPart> {
            switch kind {
            case .opening:
                return [.crucifix, .pendantLarge(0), .pendantSmall(0), .pendantSmall(1), .pendantSmall(2)]
            case .mystery(let n):
                let decade = n - 1
                guard decade < 5 else { return [] }
                return Set((0..<10).map { RosaryPart.loopSmall(decade: decade, bead: $0) })
                    .union([RosaryMap.ourFatherBead(decade: decade)])
            case .closing:
                return [.medal, .crucifix]
            }
        }
    }

    let parts: [Part]

    /// What each decade is: "Each: an Our Father, ten Hail Marys and a
    /// Glory Be"
    let decadeNote: String

    /// - Parameters:
    ///   - includesPendant: Whether the opening and closing prayers are
    ///     prayed: shown in Settings, or said by the voice
    ///   - meditationTitles: A meditation set's own titles for its
    ///     meditations, in order; each stands under its mystery's name
    ///     where it says something the name does not, so the set's list
    ///     of meditations and this order of the Rosary are one list
    init(category: MysteryCategory, includesPendant: Bool, meditationTitles: [String] = []) {
        let chaplet = category == .sevenSorrows
        var parts: [Part] = []
        if includesPendant {
            parts.append(
                Part(
                    kind: .opening,
                    title: String(
                        localized: "The Opening Prayers",
                        comment: "One Rosary beta, the Rosary's overview: the first part of the Rosary"),
                    detail: chaplet
                        ? String(
                            localized: "The Sign of the Cross and the Act of Contrition",
                            comment: "One Rosary beta, the Rosary's overview: what the Seven Sorrows chaplet opens with"
                        )
                        : String(
                            localized:
                                "The Sign of the Cross, the Creed, an Our Father, three Hail Marys and a Glory Be",
                            comment: "One Rosary beta, the Rosary's overview: what the Rosary opens with")
                ))
        }
        for (index, mystery) in MysteryData.mysteries(for: category).enumerated() {
            let title = meditationTitles.indices.contains(index) ? meditationTitles[index] : nil
            let differs = title.map { $0.caseInsensitiveCompare(mystery.name) != .orderedSame && !$0.isEmpty } ?? false
            parts.append(Part(kind: .mystery(index + 1), title: mystery.name, detail: differs ? title : nil))
        }
        if includesPendant {
            parts.append(
                Part(
                    kind: .closing,
                    title: String(
                        localized: "The Closing Prayers",
                        comment: "One Rosary beta, the Rosary's overview: the last part of the Rosary"),
                    detail: chaplet
                        ? String(
                            localized: "Three Hail Marys for her tears, the closing prayer and the Sign of the Cross",
                            comment:
                                "One Rosary beta, the Rosary's overview: what the Seven Sorrows chaplet closes with")
                        : String(
                            localized: "The Hail, Holy Queen, the closing prayer and the Sign of the Cross",
                            comment: "One Rosary beta, the Rosary's overview: what the Rosary closes with")
                ))
        }
        self.parts = parts
        decadeNote =
            chaplet
            ? String(
                localized: "Each sorrow: an Our Father, seven Hail Marys and a Glory Be",
                comment: "One Rosary beta, the Rosary's overview: what is prayed on each sorrow of the chaplet")
            : String(
                localized: "Each mystery: an Our Father, ten Hail Marys and a Glory Be",
                comment: "One Rosary beta, the Rosary's overview: what is prayed on each mystery")
    }

    /// The mysteries alone, for counting them
    var mysteries: [Part] {
        parts.filter { if case .mystery = $0.kind { return true } else { return false } }
    }
}

// MARK: - RosaryHelps

/// The Guided Rosary's words on the Rosary itself, with the One Rosary
/// beta's Helps on: for the step under the hand, where it is and what
/// to do, from `GuidedRosary.steps(for:)` through `RosaryPart`. The
/// chaplet of the Seven Sorrows has no guide, so no line.
enum RosaryHelps {

    struct Line: Equatable {
        /// Where on the Rosary: "The Annunciation · 3 of 10"
        let place: String
        /// What to do there, in plain words
        let instruction: String
    }

    /// The line for the hand's place on a player.
    ///
    /// - Parameters:
    ///   - pendantStep: The opening or closing prayer under the hand, or
    ///     nil on the decades
    ///   - mystery: The mystery under the hand, 0-based
    ///   - bead: The bead of its decade: 0 the Our Father, 1…10 the Hail
    ///     Marys, 11 the Glory Be
    static func line(
        for category: MysteryCategory,
        pendantStep: SilentPendant.Step?,
        mystery: Int,
        bead: Int
    ) -> Line? {
        guard GuidedRosary.isGuidable(category) else { return nil }
        let steps = steps(for: category)
        let step: GuidedStep?
        switch pendantStep {
        case .opening(let index):
            let opening = steps.filter { $0.decade == nil && !$0.isClosing }
            step = opening.indices.contains(index) ? opening[index] : nil
        case .closing(let index):
            let closing = steps.filter(\.isClosing)
            step = closing.indices.contains(index) ? closing[index] : nil
        case nil:
            // A decade's steps past its announcement: the Our Father, the
            // ten Hail Marys, and the close — one to each bead
            let decade = steps.filter { $0.decade == mystery && !$0.isAnnouncement }
            step = decade.indices.contains(bead) ? decade[bead] : nil
        }
        guard let step else { return nil }
        let instruction = pendantStep == nil
            ? (sceneFreeInstruction(mystery: mystery, bead: bead) ?? step.instruction)
            : step.instruction
        return Line(place: step.place, instruction: instruction)
    }

    /// The Hail Marys' words in the guide name the scene ("Stay with the
    /// Annunciation."), which the player already names over them, so on
    /// the Rosary itself the line says what to do and leaves the name
    /// to the title. Nil where the guide's own words already do that.
    static func sceneFreeInstruction(mystery: Int, bead: Int) -> String? {
        switch (mystery, bead) {
        case (0, 1):
            return String(
                localized: "Ten Hail Marys, one on each small bead. Let the words carry you while your mind stays with the scene.",
                comment: "One Rosary beta, Helps on the first Hail Mary of the first mystery: what to do, without naming the mystery, which the screen names above")
        case (0, 2), (_, 10):
            return nil
        case (_, 1):
            return String(
                localized: "Ten Hail Marys, one on each small bead.",
                comment: "One Rosary beta, Helps on the first Hail Mary of a later mystery: what to do")
        case (_, 2...9):
            return String(
                localized: "Keep the scene before you.",
                comment: "One Rosary beta, Helps on a Hail Mary in the middle of a mystery: what to do, without naming the mystery, which the screen names above")
        default:
            return nil
        }
    }

    /// The guide's steps, built once a category and a language
    private static var cache: [String: [GuidedStep]] = [:]

    private static func steps(for category: MysteryCategory) -> [GuidedStep] {
        let key = "\(category.rawValue)|\(Locale.current.identifier)"
        if let steps = cache[key] { return steps }
        let steps = GuidedRosary.steps(for: category)
        cache[key] = steps
        return steps
    }
}

// MARK: - Tapping the Strand

extension RosaryStrand {

    /// Whether a tap on the bead at `index` may take the hand there from
    /// `active`, with the One Rosary beta on: any bead behind it, and
    /// ahead only as far as the next Our Father, so a tap never passes
    /// over a mystery's meditation unheard. On a decade's Glory Be
    /// (`onGloryBe`) the hand already stands on the next Our Father's
    /// bead, so nothing ahead is reached by a tap: the next mystery's
    /// meditation comes first, by the swipe or Next.
    func canTap(_ index: Int, from active: Int, onGloryBe: Bool = false) -> Bool {
        guard index != active, index >= 0, index < count else { return false }
        if index < active { return true }
        if onGloryBe { return false }
        let nextOurFather = min((active / decadeLength + 1) * decadeLength, count - 1)
        return index <= nextOurFather
    }

    /// The mystery and bead a position on the string is prayed as: the
    /// final bead is the last decade's Glory Be
    func position(at index: Int) -> BeadPosition {
        if index >= decades * decadeLength {
            return BeadPosition(mystery: decades - 1, bead: gloryBe)
        }
        return BeadPosition(mystery: index / decadeLength, bead: index % decadeLength)
    }
}

// MARK: - OneRosaryRail

/// The whole Rosary as one rail, with the One Rosary beta on: the
/// pendant's cross and beads, the five decades (seven sorrows) and the
/// pendant again at the close, drawn as one string at the strand's own
/// place on every step. The opening prayers climb it from the cross,
/// the decades run up it, and the closing prayers come back to the medal
/// and the cross, so there is one layout from the first Sign of the
/// Cross to the last.
///
/// A position is a place on the rosary, not a prayer: the Sign of the
/// Cross and the Creed are both said on the cross, the Hail, Holy Queen
/// and the closing prayer on the medal, and a decade's Glory Be on the
/// next Our Father's bead, as the strand already draws it. Index 0 is
/// the first bead prayed; the rail is read bottom-up, like the strand.
struct OneRosaryRail: Equatable {

    enum Kind: Hashable {
        case cross
        case largeBead
        case smallBead
        case medal
        case ourFather(decade: Int)
        case hailMary
        /// The last bead of a Rosary with no closing prayers shown
        case end
    }

    /// What a tap on a position takes the hand to
    enum Target: Equatable {
        case strand(Int)
        case pendant(SilentPendant.Step)
    }

    private struct Group: Equatable {
        let place: PendantPlace?
        var steps: [Int]
        var railIndex: Int
    }

    let kinds: [Kind]
    let strand: RosaryStrand

    /// Rail positions before the strand's first bead
    let strandStart: Int

    private let opening: [Group]
    private let closing: [Group]

    /// - Parameters:
    ///   - showsPendant: Whether the opening and closing prayers are
    ///     prayed on this Rosary (shown in Settings, or said aloud);
    ///     without them the rail is the strand alone, as it was
    init(strand: RosaryStrand, pendant: SilentPendant, showsPendant: Bool) {
        self.strand = strand
        guard showsPendant else {
            kinds = (0..<strand.count).map { Self.kind(of: strand.bead(at: $0)) }
            strandStart = 0
            opening = []
            closing = []
            return
        }

        func groups(_ pendants: [SpokenPendant]) -> [Group] {
            var result: [Group] = []
            for (index, prayer) in pendants.enumerated() {
                if let last = result.last, prayer.place == nil || last.place == prayer.place {
                    result[result.count - 1].steps.append(index)
                } else {
                    result.append(Group(place: prayer.place, steps: [index], railIndex: 0))
                }
            }
            return result
        }

        var kinds: [Kind] = []
        var opening = groups(pendant.opening)
        for index in opening.indices {
            opening[index].railIndex = kinds.count
            kinds.append(Self.kind(of: opening[index].place))
        }
        strandStart = kinds.count

        var closing = groups(pendant.closing)
        let mergesIntoEnd = closing.first?.place == .medal
        for index in 0..<strand.count {
            let bead = strand.bead(at: index)
            if case .amen = bead, !closing.isEmpty {
                kinds.append(mergesIntoEnd ? .medal : .largeBead)
            } else {
                kinds.append(Self.kind(of: bead))
            }
        }
        for index in closing.indices {
            if index == 0, mergesIntoEnd {
                closing[index].railIndex = kinds.count - 1
            } else {
                closing[index].railIndex = kinds.count
                kinds.append(Self.kind(of: closing[index].place))
            }
        }

        self.kinds = kinds
        self.opening = opening
        self.closing = closing
    }

    var count: Int { kinds.count }

    /// The position of a bead of the strand
    func index(strandIndex: Int) -> Int {
        strandStart + min(max(strandIndex, 0), strand.count - 1)
    }

    /// The position of an opening or closing prayer
    func index(of step: SilentPendant.Step) -> Int {
        switch step {
        case .opening(let i):
            return opening.first { $0.steps.contains(i) }?.railIndex ?? strandStart
        case .closing(let i):
            return closing.first { $0.steps.contains(i) }?.railIndex ?? (count - 1)
        }
    }

    /// The position of a prayer the voice is saying on the pendant, by
    /// its place: the prayers after the Rosary, which the silent pendant
    /// leaves out, are said on the medal with the closing prayer
    func index(of pendant: SpokenPendant) -> Int {
        let groups = pendant.phase == .opening ? opening : closing
        if let place = pendant.place, let group = groups.first(where: { $0.place == place }) {
            return group.railIndex
        }
        return pendant.phase == .opening ? (groups.last?.railIndex ?? strandStart) : (groups.last?.railIndex ?? count - 1)
    }

    /// Where a tap on a position takes the hand: a bead of the strand,
    /// or the first prayer said on a place of the pendant
    func target(at index: Int) -> Target? {
        guard index >= 0, index < count else { return nil }
        // The medal the last Glory Be is said on is the strand's own last
        // bead: a tap there is that bead
        if index >= strandStart, index < strandStart + strand.count {
            return .strand(index - strandStart)
        }
        if let first = opening.first(where: { $0.railIndex == index })?.steps.first {
            return .pendant(.opening(first))
        }
        if let first = closing.first(where: { $0.railIndex == index })?.steps.first {
            return .pendant(.closing(first))
        }
        return nil
    }

    /// The numeral beside a decade's Our Father, or the end's name
    func label(at index: Int) -> String? {
        guard index >= 0, index < count else { return nil }
        switch kinds[index] {
        case .ourFather(let decade): return "\(decade + 1)"
        case .end: return String(localized: "Amen", comment: "Drawn strand: the label beside the last bead, where the Rosary ends")
        default: return nil
        }
    }

    private static func kind(of place: PendantPlace?) -> Kind {
        switch place {
        case .cross: return .cross
        case .largeBead: return .largeBead
        case .chain, .medal: return .medal
        case .smallBead, nil: return .smallBead
        }
    }

    private static func kind(of bead: RosaryStrand.Bead) -> Kind {
        switch bead {
        case .ourFather(let decade): return .ourFather(decade: decade)
        case .hailMary: return .hailMary
        case .amen: return .end
        }
    }
}
