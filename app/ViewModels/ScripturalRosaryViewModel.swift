//
//  ScripturalRosaryViewModel.swift
//  Lumen Viae
//
//  State for the Scriptural Rosary: which mystery, which bead, and what
//  the bead under the hand says.
//
//  The devotion is bundled whole — the mysteries from MysteryData, the
//  verses from ScripturalRosaryData — so this model touches no service
//  and no network. There is no narration, no set, no audio session;
//  what it shares with the meditation's player is the shape of a
//  decade and the timing of a session.
//

import Foundation

@Observable
final class ScripturalRosaryViewModel {

    /// How the Prayer Record names this devotion. The Chapel's rule reads
    /// it back to know the Scriptural Rosary was prayed today, so it is
    /// one string, kept here.
    static let devotionName = "Scriptural Rosary"

    // MARK: - State

    let category: MysteryCategory

    /// The mysteries being prayed, in order — five, or the seven sorrows
    let mysteries: [Mystery]

    /// Current mystery index (0-based).
    ///
    /// The bead resets in `didSet` rather than in each caller, so a new
    /// decade always begins on its Our Father bead however it was
    /// reached.
    var currentMysteryIndex: Int = 0 {
        didSet { currentBeadIndex = 0 }
    }

    /// Which bead of the decade is under the hand: 0 is the Our Father
    /// bead, 1 through `hailMarys` that Hail Mary, and one past the last
    /// the decade prayed — the Glory Be.
    var currentBeadIndex: Int = 0

    /// When THIS segment of the session started. Resumed sessions get a
    /// fresh clock — the gap between segments is not prayer time.
    private let segmentStart = Date()

    /// Seconds prayed in earlier segments of a resumed session
    private let priorSeconds: Int

    // MARK: - Initialization

    init(category: MysteryCategory, startAtIndex: Int = 0, startAtBead: Int = 0, priorSeconds: Int = 0) {
        self.category = category
        self.mysteries = MysteryData.mysteries(for: category)
        self.priorSeconds = max(priorSeconds, 0)

        let upperBound = max(mysteries.count - 1, 0)
        self.currentMysteryIndex = min(max(startAtIndex, 0), upperBound)
        // After the mystery, whose `didSet` would put the hand back on
        // the Our Father; clamped to the decade
        self.currentBeadIndex = min(max(startAtBead, 0), strand.gloryBe)
    }

    // MARK: - The Mysteries

    var totalMysteries: Int { mysteries.count }

    var currentMystery: Mystery? {
        guard mysteries.indices.contains(currentMysteryIndex) else { return nil }
        return mysteries[currentMysteryIndex]
    }

    var isFirstMystery: Bool { currentMysteryIndex == 0 }

    var isLastMystery: Bool { currentMysteryIndex >= totalMysteries - 1 }

    /// "The Fourth Joyful Mystery" — where the Rosary stands
    var mysteryKicker: String {
        category.mysteryLabel(ordinal: currentMysteryIndex + 1)
    }

    /// Advances to the next mystery.
    ///
    /// - Returns: `true` if advanced, `false` on the last mystery — when
    ///   the caller should go to the completion screen.
    func nextMystery() -> Bool {
        guard !isLastMystery else { return false }
        currentMysteryIndex += 1
        return true
    }

    /// Returns to the previous mystery (no-op on the first)
    func previousMystery() {
        guard currentMysteryIndex > 0 else { return }
        currentMysteryIndex -= 1
    }

    // MARK: - The Beads

    /// One verse of Scripture per Hail Mary for the current mystery.
    ///
    /// The category is lowercased on the way in: MysteryData's strings
    /// are lowercase, but every other consumer normalizes, and a single
    /// capitalized key would make a mystery's verses vanish.
    var verses: [ScripturalVerse] {
        guard let mystery = currentMystery else { return [] }
        return ScripturalRosaryData.verses(
            category: mystery.category.lowercased(),
            order: mystery.order
        ) ?? []
    }

    /// Hail Marys in the decade: as many as there are verses — ten, or
    /// seven for a sorrow — and the chaplet's own count should a mystery
    /// ever arrive without a curated set.
    var hailMarys: Int {
        let count = verses.count
        guard count > 0 else { return category == .sevenSorrows ? 7 : 10 }
        return count
    }

    /// The whole Rosary as one string, for the strand at the screen's
    /// edge and for where on it the hand is.
    var strand: RosaryStrand {
        RosaryStrand(decades: totalMysteries, hailMarys: hailMarys)
    }

    /// Where the hand is on the string
    var strandIndex: Int {
        strand.index(mystery: currentMysteryIndex, bead: currentBeadIndex)
    }

    /// What the bead under the hand is called
    var beadLabel: String {
        strand.label(bead: currentBeadIndex)
    }

    /// True once every bead of the decade has been prayed.
    var isDecadePrayed: Bool {
        currentBeadIndex > hailMarys
    }

    /// The very first bead of the Rosary — nothing to step back to
    var isFirstBeadOfRosary: Bool {
        isFirstMystery && currentBeadIndex == 0
    }

    /// The last mystery's Glory Be — the final bead, where AMEN stands
    var isLastBeadOfRosary: Bool {
        isLastMystery && isDecadePrayed
    }

    /// Where the hand is, as one value. The screen's haptic keys on it
    /// so one move is one tick — whether the bead moved, the mystery
    /// moved, or both at once, as they do crossing a decade's end.
    var beadPosition: BeadPosition {
        BeadPosition(mystery: currentMysteryIndex, bead: currentBeadIndex)
    }

    /// Prays the strand forward as one continuous line: the next bead,
    /// or past the Glory Be the next mystery's Our Father. The whole
    /// Rosary is fifty-odd steps of this and nothing else.
    ///
    /// - Returns: `false` at the last mystery's Glory Be — the final
    ///   bead. The Rosary is finished only by the AMEN tap there, never
    ///   by the move that reaches it.
    func prayForward() -> Bool {
        if isDecadePrayed { return nextMystery() }
        currentBeadIndex += 1
        return true
    }

    /// Steps the strand back one: the previous bead, or from an Our
    /// Father the previous mystery's Glory Be. No-op on the first bead
    /// of the Rosary.
    func prayBack() {
        if currentBeadIndex > 0 {
            currentBeadIndex -= 1
            return
        }
        guard !isFirstMystery else { return }
        // The index's own `didSet` lands on the Our Father; the strand
        // is walked backwards, so the hand belongs on the Glory Be
        currentMysteryIndex -= 1
        currentBeadIndex = strand.gloryBe
    }

    /// What the bead under the hand says.
    ///
    /// The Our Father bead announces the mystery — its scene, its
    /// passage, and the fruit to ask for — the way a decade is announced
    /// aloud before the beads begin. Each Hail Mary carries its verse.
    /// The decade prayed, the doxology closes it.
    var reading: BeadReading {
        if currentBeadIndex <= 0 {
            guard let mystery = currentMystery else {
                return BeadReading(reference: nil, text: "", footnote: nil)
            }
            return BeadReading(
                reference: mystery.scriptureReference,
                text: mystery.description ?? "",
                footnote: MysteryData.fruit(for: mystery).map { "Fruit of the mystery · \($0)" }
            )
        }

        if isDecadePrayed {
            let language = UserSettings.shared.prayerLanguage
            return BeadReading(
                reference: nil,
                text: Self.gloryBe(in: language),
                footnote: nil,
                closingPrayer: Self.fatimaPrayer(in: language)
            )
        }

        let verses = verses
        guard verses.indices.contains(currentBeadIndex - 1) else {
            return BeadReading(reference: nil, text: "", footnote: nil)
        }
        let verse = verses[currentBeadIndex - 1]
        return BeadReading(reference: verse.reference, text: verse.text, footnote: nil)
    }

    /// The doxology, in the language the Rosary's prayers are set in —
    /// Latin when Latin alone is chosen, English otherwise. The band is
    /// one paragraph, not a bilingual pair, so the two-language modes
    /// read it in English.
    private static func gloryBe(in language: PrayerLanguage) -> String {
        RosaryPrayerText.gloryBe.paragraph(in: language)
    }

    /// The Fatima Prayer, said after the Glory Be of every decade as Our
    /// Lady asked at Fatima — the bundled text How to Pray teaches, in the
    /// language the doxology is set in.
    private static func fatimaPrayer(in language: PrayerLanguage) -> String {
        RosaryPrayerText.fatimaPrayer.paragraph(in: language)
    }

    // MARK: - Session

    /// Seconds actually spent praying: earlier segments plus this one.
    /// Interruption gaps between segments are never counted.
    var sessionDuration: Int {
        priorSeconds + Int(Date().timeIntervalSince(segmentStart))
    }
}

// MARK: - BeadReading

/// What one bead says: a citation in small caps, the passage, on the
/// Our Father bead the fruit to ask for beneath it, and on the closing
/// bead the Fatima Prayer after the doxology.
struct BeadReading: Hashable {
    /// "Luke 1:28"; the mystery's own passage on the Our Father bead;
    /// nothing on the Glory Be
    let reference: String?

    let text: String

    /// A line set like the citation, under the text
    let footnote: String?

    /// A second prayer said on the same bead, set as a paragraph of its
    /// own beneath the first — the Fatima Prayer after the Glory Be
    var closingPrayer: String? = nil
}
