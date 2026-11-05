//
//  OneRosary.swift
//  Lumen Viae
//
//  The pure parts of the Rosary player's rail: which beads of the strand a tap may go to
//  (`RosaryStrand.canTap`), and the whole Rosary as one rail
//  (`OneRosaryRail`). The simple Rosary's rules are `SimpleRosary`.
//

import Foundation

// MARK: - RosaryHelps

/// The Guided Rosary's words on the Rosary itself, shown only on the
/// simple Rosary's beginner's path (never a toggle): for the step under the hand, where it is and what
/// to do, from `GuidedRosary.steps(for:)` through `RosaryPart`. The
/// chaplet of the Seven Sorrows has no guide, so no line.
enum RosaryHelps {

    struct Line: Equatable {
        /// Where on the Rosary: "The Annunciation · 3 of 10"
        let place: String
        /// What to do there, in plain words
        let instruction: String
        /// Whether the line says what to do before the words are said
        /// ("...as you say:"), and so stands above them; a comment on the
        /// words while they are said ("Keep the scene before you.")
        /// stands after them
        var leadsWords: Bool = false
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
            : (pendantInstruction(pendantStep) ?? step.instruction)
        // On the pendant, on a mystery's Our Father, its first Hail Mary
        // and its close the guide says what to do next; on the Hail
        // Marys between, it keeps the mind on the scene while they are
        // said
        let leads = pendantStep != nil || bead <= 1 || bead > 10
        return Line(place: step.place, instruction: instruction, leadsWords: leads)
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
                localized: "Small bead \(bead) of 10. Keep the scene before you.",
                comment: "One Rosary beta, Helps on a Hail Mary in the middle of a mystery: which bead you are on and what to do, without naming the mystery, which the screen names above")
        default:
            return nil
        }
    }

    /// The guide's words on the first Sign of the Cross end "as you say:",
    /// leading into the prayer printed under them; on the Rosary itself
    /// the help line stands in its own slot over the words, so it says
    /// what to do and stops. Nil where the guide's own words serve.
    static func pendantInstruction(_ step: SilentPendant.Step?) -> String? {
        guard case .opening(0) = step else { return nil }
        return String(
            localized: "Take the crucifix in your hand. Touch your forehead, your breast, your left shoulder and your right.",
            comment: "One Rosary beta, Helps on the first Sign of the Cross: what to do, a sentence of its own over the prayer's words")
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
    /// `active`: any bead behind it, and
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

/// The whole Rosary as one rail: drawn as a
/// rosary unrolled into one string, read one way only, from the cross at
/// its foot to the medal at its head. The opening prayers climb the
/// pendant from the cross; the centrepiece (the medal) stands between the
/// pendant and the first decade's Hail Marys, so the pendant reads as the
/// pendant; the decades run up the string; and at the close the hand comes
/// back to the medal at the string's head, then to the cross it set out
/// from. The rail never turns over: the cross is always at the foot,
/// prayed beads below the hand, beads to come above.
///
/// A position is a place on the rosary, not a prayer: the Sign of the
/// Cross and the Creed are both said on the cross, the Hail, Holy Queen
/// and the closing prayer on the medal, and a decade's Glory Be on the
/// next Our Father's bead, as the strand already draws it. Index 0 is
/// the cross; the rail is read bottom-up, like the strand. The medal
/// between the pendant and the decades is passed, never stood on.
struct OneRosaryRail: Equatable {

    enum Kind: Hashable {
        case cross
        case largeBead
        case smallBead
        case medal
        /// The centrepiece between the pendant and the first decade's
        /// Hail Marys: drawn, passed over, never a place to stand
        case centrepiece
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

    /// Each bead of the strand's position on the rail
    private let strandRail: [Int]

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
            strandRail = Array(0..<strand.count)
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

        let isChaplet = strand.hailMarys != 10
        var kinds: [Kind] = []
        var opening = groups(pendant.opening)
        // The opening's Glory Be is said where the hand comes to the first
        // mystery's Our Father bead (the pendant's second large bead), not
        // on a bead of its own: drawn apart, it stood as an unnumbered
        // large ring under the "1" and read as a decade bead
        let mergesIntoStart = opening.count > 1 && (opening.last?.place == .chain || opening.last?.place == .medal)
        for index in opening.indices {
            if index == opening.count - 1, mergesIntoStart { continue }
            opening[index].railIndex = kinds.count
            kinds.append(Self.kind(of: opening[index].place))
        }
        // The chaplet's pendant is its cross alone, and its medal comes
        // straight after it
        if isChaplet { kinds.append(.centrepiece) }
        let strandStart = kinds.count
        if mergesIntoStart { opening[opening.count - 1].railIndex = strandStart }

        var closing = groups(pendant.closing)
        let mergesIntoEnd = closing.first?.place == .medal
        var strandRail: [Int] = []
        for index in 0..<strand.count {
            let bead = strand.bead(at: index)
            strandRail.append(kinds.count)
            if case .amen = bead, !closing.isEmpty {
                kinds.append(mergesIntoEnd ? .medal : .largeBead)
            } else {
                kinds.append(Self.kind(of: bead))
            }
            // The Rosary's first Our Father is said on the pendant's
            // second large bead, below the medal: the medal stands
            // between it and the first Hail Mary
            if index == 0, !isChaplet { kinds.append(.centrepiece) }
        }
        let returnsToCross = opening.first?.place == .cross
        for index in closing.indices {
            if index == 0, mergesIntoEnd {
                closing[index].railIndex = kinds.count - 1
            } else if closing[index].place == .cross, returnsToCross {
                // The close comes back to the cross the Rosary set out
                // from: the one cross, at the foot, never a second one
                // at the head
                closing[index].railIndex = 0
            } else {
                closing[index].railIndex = kinds.count
                kinds.append(Self.kind(of: closing[index].place))
            }
        }

        self.kinds = kinds
        self.strandStart = strandStart
        self.strandRail = strandRail
        self.opening = opening
        self.closing = closing
    }

    var count: Int { kinds.count }

    /// The position of a bead of the strand
    func index(strandIndex: Int) -> Int {
        strandRail[min(max(strandIndex, 0), strand.count - 1)]
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
    /// or the first prayer said on a place of the pendant. The medal
    /// between the pendant and the decades takes the hand nowhere.
    func target(at index: Int) -> Target? {
        guard index >= 0, index < count else { return nil }
        // The medal the last Glory Be is said on is the strand's own last
        // bead: a tap there is that bead
        if let bead = strandRail.firstIndex(of: index) {
            return .strand(bead)
        }
        if let first = opening.first(where: { $0.railIndex == index })?.steps.first {
            return .pendant(.opening(first))
        }
        if let first = closing.first(where: { $0.railIndex == index })?.steps.first {
            return .pendant(.closing(first))
        }
        return nil
    }

    /// The numeral beside a decade's Our Father: the only label the rail
    /// carries, so a number always means a mystery
    func label(at index: Int) -> String? {
        guard index >= 0, index < count else { return nil }
        if case .ourFather(let decade) = kinds[index] { return "\(decade + 1)" }
        return nil
    }

    /// What a press on a bead of the strand goes to, in the rail's
    /// margin while the finger is down: "Hail Mary" over "6 of 10", "Our
    /// Father" over the mystery's number
    func pressLines(strandIndex: Int) -> [String] {
        let position = strand.position(at: strandIndex)
        if position.bead == 0 {
            return [
                strand.labelLines(bead: 0).first ?? "",
                String(
                    localized: "Mystery \(position.mystery + 1)",
                    comment: "One Rosary beta, a bead of the rail pressed: the second short line under Our Father, naming which mystery the bead opens, like Mystery 2"),
            ]
        }
        return strand.labelLines(bead: position.bead)
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
