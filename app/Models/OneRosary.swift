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
    }

    let parts: [Part]

    /// What each decade is: "Each: an Our Father, ten Hail Marys and a
    /// Glory Be"
    let decadeNote: String

    /// - Parameters:
    ///   - includesPendant: Whether the opening and closing prayers are
    ///     prayed: shown in Settings, or said by the voice
    init(category: MysteryCategory, includesPendant: Bool) {
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
            parts.append(Part(kind: .mystery(index + 1), title: mystery.name))
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
        return step.map { Line(place: $0.place, instruction: $0.instruction) }
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
