//
//  SilentPendant.swift
//  Lumen Viae
//
//  The Rosary's opening and closing prayers on a player prayed in
//  silence. Said aloud, the voice says them on the pendant
//  (`SpokenRosaryScript`); prayed in silence the players once began on
//  the first mystery's Our Father and ended on the last Glory Be, and a
//  newcomer was never shown the Sign of the Cross, the Creed, the three
//  Hail Marys or the Hail, Holy Queen, nor the words of any of them.
//  Now the Rosary begins on the cross and ends there, a prayer a step,
//  each with its words, as the Rosary Said Aloud sets them.
//
//  Pure: the steps are the spoken script's own opening and closing
//  segments, so the two ways of praying open and close the same way.
//

import Foundation

// MARK: - SilentPendant

/// The opening and closing prayers of one Rosary, as steps
struct SilentPendant: Equatable {

    /// Where on the pendant the hand is: a step of the opening, before
    /// the first mystery, or of the close, after the last
    enum Step: Hashable {
        case opening(Int)
        case closing(Int)
    }

    let opening: [SpokenPendant]
    let closing: [SpokenPendant]

    /// The steps for a Rosary of `category`, read off the spoken script
    /// so the order, the captions and the places on the pendant are the
    /// voice's. The prayers after the Rosary (`RosaryClosingExtra`) are
    /// said only aloud, as Settings says, and are left out.
    init(category: MysteryCategory) {
        let mysteries = MysteryData.mysteries(for: category)
        let keys = mysteries.map { "\($0.category.lowercased())_\($0.order)" }
        let isChaplet = category == .sevenSorrows
        let script = SpokenRosaryScript.build(
            category: category,
            mysteryKeys: keys,
            hailMarys: isChaplet ? 7 : 10,
            style: .plain
        )
        func pendant(_ segment: SpokenSegment) -> SpokenPendant? {
            guard case .prayer(let id) = segment.kind else { return nil }
            return SpokenPendant(
                phase: segment.phase,
                prayerID: id,
                title: segment.caption,
                place: segment.place,
                isChaplet: isChaplet
            )
        }
        opening = script.filter { $0.phase == .opening }.compactMap(pendant)
        closing = script.filter { $0.phase == .closing }.compactMap(pendant)
    }

    /// The prayer at a step
    func pendant(at step: Step) -> SpokenPendant? {
        switch step {
        case .opening(let index): return opening.indices.contains(index) ? opening[index] : nil
        case .closing(let index): return closing.indices.contains(index) ? closing[index] : nil
        }
    }

    var firstOpening: Step? { opening.isEmpty ? nil : .opening(0) }
    var lastOpening: Step? { opening.isEmpty ? nil : .opening(opening.count - 1) }
    var firstClosing: Step? { closing.isEmpty ? nil : .closing(0) }
    var lastClosing: Step? { closing.isEmpty ? nil : .closing(closing.count - 1) }

    /// The step after this one on its own side of the decades, or nil
    /// where the opening gives way to the first mystery and where the
    /// close ends at the AMEN
    func step(after step: Step) -> Step? {
        switch step {
        case .opening(let index): return index + 1 < opening.count ? .opening(index + 1) : nil
        case .closing(let index): return index + 1 < closing.count ? .closing(index + 1) : nil
        }
    }

    /// The step before this one, or nil where the opening begins and
    /// where the close gives way back to the last Glory Be
    func step(before step: Step) -> Step? {
        switch step {
        case .opening(let index): return index > 0 ? .opening(index - 1) : nil
        case .closing(let index): return index > 0 ? .closing(index - 1) : nil
        }
    }

    /// "1 of 7", counted on its own side of the decades
    func count(of step: Step) -> String {
        switch step {
        case .opening(let index): return "\(index + 1) of \(opening.count)"
        case .closing(let index): return "\(index + 1) of \(closing.count)"
        }
    }

    /// What comes after the last opening prayer, said on the first one
    /// so the whole opening is known before it is begun: "the Apostles'
    /// Creed, an Our Father, three Hail Marys and a Glory Be"
    static func openingSummary(isChaplet: Bool) -> String {
        isChaplet
            ? "Then the Act of Contrition, and the first sorrow."
            : "Then the Apostles' Creed, an Our Father, three Hail Marys and a Glory Be."
    }

    // MARK: - The Words

    /// A prayer's words line by line, in the language the Rosary's
    /// prayers are set in (Latin when Latin alone is chosen) — the words
    /// the voice says. A screen joins them with `Rubric.paragraph`, which
    /// sets a rubric line ("[Let us pray.]") as a rubric.
    static func lines(of prayerID: String, in language: PrayerLanguage) -> [String] {
        guard let content = DevotionPrayers.find(prayerID)?.content else { return [] }
        let source = language == .latin ? content.latin : content.english
        return source
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// The words of a decade's bead, by `RosaryStrand`'s arithmetic: the
    /// Our Father, a Hail Mary, or the Glory Be with the Fatima Prayer
    /// after it (not in the chaplet)
    static func lines(ofBead bead: Int, strand: RosaryStrand, in language: PrayerLanguage) -> [String] {
        if bead <= 0 { return lines(of: "our_father", in: language) }
        if bead < strand.gloryBe { return lines(of: "hail_mary", in: language) }
        let gloryBe = lines(of: "glory_be", in: language)
        guard strand.saysFatimaPrayer else { return gloryBe }
        return gloryBe + lines(of: "fatima_prayer", in: language)
    }
}

// MARK: - OpeningPrayersChoice

/// The third of the Rosary's settings: whether a Rosary prayed in silence
/// shows its opening and closing prayers. Kept apart from `RosaryChoice`,
/// whose two choices stand on every Rosary's own page; this one lives in
/// Settings alone.
enum OpeningPrayersChoice {
    static let title = "Opening and Closing Prayers"
    static let icon = "lv-procession-cross"

    static let options = [
        RosaryChoice.Option(value: false, name: "Skip"),
        RosaryChoice.Option(value: true, name: "Show"),
    ]

    static func note(for value: Bool) -> String {
        value
            ? "The Rosary begins with the Sign of the Cross and the Creed and ends with the Hail, Holy Queen, each with its words."
            : "The Rosary begins at the first mystery and ends at the last Glory Be."
    }

    /// Said aloud, the voice says them whatever is chosen
    static let unavailableNote = "With the Whole Rosary, the voice says them."
}
