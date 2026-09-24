//
//  ScripturalRosaryViewModel.swift
//  Lumen Viae
//
//  State for the Scriptural Rosary: which mystery, which bead, and what
//  the bead under the hand says.
//
//  The devotion is bundled whole — the mysteries from MysteryData, the
//  verses from ScripturalRosaryData — so it prays with no network. What
//  it shares with the meditation's player is the shape of a decade, the
//  timing of a session, and — when the Rosary is said aloud
//  (`UserSettings.prayAloud`) — the spoken Rosary, which reads each
//  bead's verse before its Hail Mary from recordings kept on the device.
//
//  The same model prays the Rosary Aloud (`SpokenForm.plain`): no verses,
//  every prayer said by the voice whatever the setting, and each bead
//  set with the prayer being said on it, so a Rosary whose recordings
//  cannot be had is still a Rosary, prayed in silence from the page.
//

import Foundation

@Observable
final class ScripturalRosaryViewModel {

    /// How the Prayer Record names this devotion. The Chapel's rule reads
    /// it back to know the Scriptural Rosary was prayed today, so it is
    /// one string, kept here.
    static let devotionName = "Scriptural Rosary"

    /// The Rosary Aloud's name in the Prayer Record, kept apart from the
    /// Scriptural Rosary's so the Chapel's rule can tell the two apart.
    /// Both count as the day's Rosary, which is read from the mysteries.
    static let aloudDevotionName = "The Rosary Aloud"

    // MARK: - State

    let category: MysteryCategory

    /// A verse to a bead, or the Rosary Aloud
    let form: SpokenForm

    var isPlain: Bool { form == .plain }

    /// How the Prayer Record names what is being prayed
    var devotionName: String {
        isPlain ? Self.aloudDevotionName : Self.devotionName
    }

    /// The devotion's name as the screens set it: the header, the Lock
    /// Screen, a share
    var displayName: String {
        isPlain ? "The Rosary Aloud" : "The Scriptural Rosary"
    }

    /// Which snapshot an interrupted one is kept as, so it comes back
    /// as itself
    var resumeKind: InProgressPrayer.Kind {
        isPlain ? .rosaryAloud : .scripturalRosary
    }

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

    init(
        category: MysteryCategory,
        form: SpokenForm = .scriptural,
        startAtIndex: Int = 0,
        startAtBead: Int = 0,
        priorSeconds: Int = 0
    ) {
        self.category = category
        self.form = form
        self.mysteries = MysteryData.mysteries(for: category)
        self.priorSeconds = max(priorSeconds, 0)

        let upperBound = max(mysteries.count - 1, 0)
        self.currentMysteryIndex = min(max(startAtIndex, 0), upperBound)
        // After the mystery, whose `didSet` would put the hand back on
        // the Our Father; clamped to the decade
        self.currentBeadIndex = min(max(startAtBead, 0), strand.gloryBe)

        // A Rosary resumed while it was said aloud picks up the prayer
        // it stopped on — the verse, not just the bead
        if startAtIndex > 0 || startAtBead > 0 {
            resumeStep = PrayerResumeService.shared.spokenStep(
                kind: resumeKind,
                setId: 0,
                category: category.rawValue,
                mysteryIndex: currentMysteryIndex,
                beadIndex: currentBeadIndex
            )
        }
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
        spokenFollowHand()
        return true
    }

    /// Returns to the previous mystery (no-op on the first)
    func previousMystery() {
        guard currentMysteryIndex > 0 else { return }
        currentMysteryIndex -= 1
        spokenFollowHand()
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
        // The Rosary Aloud carries no verses: the decade is the Church's
        // count, ten, or seven for a sorrow
        if isPlain { return category == .sevenSorrows ? 7 : 10 }
        let count = verses.count
        guard count > 0 else { return category == .sevenSorrows ? 7 : 10 }
        return count
    }

    /// The whole Rosary as one string, for the strand at the screen's
    /// edge and for where on it the hand is.
    var strand: RosaryStrand {
        RosaryStrand(decades: totalMysteries, hailMarys: hailMarys, saysFatimaPrayer: !isChaplet)
    }

    /// The Seven Sorrows, prayed as their chaplet: no Fatima Prayer after
    /// the Glory Be
    var isChaplet: Bool { category == .sevenSorrows }

    /// Where the hand is on the string
    var strandIndex: Int {
        strand.index(mystery: currentMysteryIndex, bead: currentBeadIndex)
    }

    /// What the bead under the hand is called
    var beadLabel: String {
        spokenDecadeOpeningLines?.joined(separator: " ") ?? strand.label(bead: currentBeadIndex)
    }

    /// The bead's name broken for the strand's margin
    var beadLabelLines: [String] {
        spokenDecadeOpeningLines ?? strand.labelLines(bead: currentBeadIndex)
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
        spokenFollowHand()
        return true
    }

    /// Steps the strand back one: the previous bead, or from an Our
    /// Father the previous mystery's Glory Be. No-op on the first bead
    /// of the Rosary.
    func prayBack() {
        if currentBeadIndex > 0 {
            currentBeadIndex -= 1
            spokenFollowHand()
            return
        }
        guard !isFirstMystery else { return }
        // The index's own `didSet` lands on the Our Father; the strand
        // is walked backwards, so the hand belongs on the Glory Be
        currentMysteryIndex -= 1
        currentBeadIndex = strand.gloryBe
        spokenFollowHand()
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
            // The Rosary Aloud sets the prayer being said. The voice has
            // already announced the mystery, and its name heads the
            // column; the fruit stays beneath the Our Father, but the
            // scene's description and its passage give way to it — all
            // of them would not fit above the foot
            if isPlain {
                return BeadReading(
                    reference: nil,
                    text: Self.prayer("our_father", in: UserSettings.shared.prayerLanguage),
                    footnote: MysteryData.fruit(for: mystery).map { "Fruit of the mystery · \($0)" }
                )
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
                closingPrayer: isChaplet ? nil : Self.fatimaPrayer(in: language)
            )
        }

        if isPlain {
            return BeadReading(
                reference: nil,
                text: Self.prayer("hail_mary", in: UserSettings.shared.prayerLanguage),
                footnote: nil
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

    /// One of the Rosary's bundled prayers as a paragraph, by the id the
    /// spoken script names it by — the same words the voice says
    private static func prayer(_ id: String, in language: PrayerLanguage) -> String {
        DevotionPrayers.find(id)?.content.paragraph(in: language) ?? ""
    }

    // MARK: - The Rosary Said Aloud

    /// Whether the Rosary is said aloud: always for the Rosary Aloud,
    /// otherwise as the setting says
    func praysAloud(setting: Bool) -> Bool {
        isPlain || setting
    }

    /// The whole Rosary said aloud, while `UserSettings.prayAloud` is on
    private(set) var spoken: SpokenRosaryPlayer?

    /// The step of the spoken script an interrupted Rosary stopped on,
    /// taken from the resume snapshot and used once, by the first start
    fileprivate var resumeStep: SpokenStep?

    /// Fires when the voice moves the mystery, so the resume snapshot
    /// follows it with the phone locked
    var onMysteryChanged: ((Int) -> Void)?

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

// MARK: - The Rosary Said Aloud

extension ScripturalRosaryViewModel: SpokenRosaryHost {

    /// Turns the spoken Rosary on or off: the prayers said aloud, each
    /// Hail Mary preceded by its verse — or, in the Rosary Aloud, by
    /// nothing.
    @MainActor
    func setPrayAloud(_ on: Bool, autoplay: Bool = true) async {
        if on, spoken == nil {
            let keys = mysteries.map { "\($0.category.lowercased())_\($0.order)" }
            let script = SpokenRosaryScript.build(
                category: category,
                mysteryKeys: keys,
                hailMarys: hailMarys,
                style: isPlain ? .plain : .scriptural,
                extras: UserSettings.shared.closingExtras
            )
            let player = SpokenRosaryPlayer(script: script, host: self)
            spoken = player
            let step = resumeStep
            resumeStep = nil
            await player.start(
                mystery: currentMysteryIndex,
                bead: currentBeadIndex,
                autoplay: autoplay,
                resumingAt: step
            )
        } else if !on, let spoken {
            spoken.stop()
            self.spoken = nil
            // The hand keeps the place from here
            PrayerResumeService.shared.endSpokenSteps(forgettingStep: true)
        }
    }

    /// Stops the voice and hands the audio session back; call when
    /// leaving the Rosary
    @MainActor
    func stopSpeaking() {
        onMysteryChanged = nil
        guard let spoken else { return }
        spoken.stop()
        self.spoken = nil
        // The step it reached stays on the snapshot to resume at
        PrayerResumeService.shared.endSpokenSteps(forgettingStep: false)
        AudioService.shared.deactivateSession()
    }

    /// The recordings being fetched before the spoken Rosary begins
    var spokenStatus: String? {
        guard case .preparing(let done, let total) = spoken?.phase else { return nil }
        // A share, not a count of files: "12 of 63" counts recordings,
        // which is nothing the person praying knows about
        guard total > 0 else { return "Getting the prayers ready…" }
        return "Getting the prayers ready · \(done * 100 / total)%"
    }

    /// Why the spoken Rosary could not begin, while it could not
    var spokenFailure: SpokenRosaryPlayer.Failure? {
        if case .failed(let failure) = spoken?.phase { return failure }
        return nil
    }

    /// The last Amen has been said aloud; AMEN is waiting to be tapped
    var isSpokenFinished: Bool { spoken?.isFinished ?? false }

    /// Begins the spoken Rosary again: after it could not begin, or in a
    /// newly chosen voice. It carries on playing only if it was — a
    /// Rosary paused before the change stays paused after it.
    @MainActor
    func restartSpoken() async {
        guard let spoken else { return }
        let keepGoing = spoken.isPlayingOrAboutTo || spokenFailure != nil
        spoken.stop()
        self.spoken = nil
        await setPrayAloud(true, autoplay: keepGoing)
    }

    /// What is being said right now: "Scripture · 3 of 10"
    var spokenCaption: String? {
        guard let spoken, spoken.phase == .running || spoken.phase == .finished,
              let segment = spoken.currentSegment else { return nil }
        switch segment.phase {
        case .opening: return "Opening prayers · \(segment.caption)"
        case .closing: return "Closing prayers · \(segment.caption)"
        case .decade: return segment.caption
        }
    }

    var isPrayingAloud: Bool { spoken != nil }

    /// While the Rosary is said aloud and the voice is on the words that
    /// open a decade — its announcement, or the meditation — the hand
    /// rests on the Our Father bead, but the Our Father has not begun.
    /// The bead is named for what is being said instead. Nil otherwise.
    var spokenDecadeOpeningLines: [String]? {
        guard let spoken, spoken.phase == .running,
              let segment = spoken.currentSegment, segment.phase == .decade else { return nil }
        switch segment.kind {
        case .announcement:
            return [segment.mysteryKey.hasPrefix("seven_sorrows") ? "The Sorrow" : "The Mystery"]
        case .meditation:
            return ["Meditation"]
        default:
            return nil
        }
    }

    /// The opening or closing prayer being said, while it is: the screen
    /// draws the pendant and names the prayer in place of the mystery
    var spokenPendant: SpokenPendant? { spoken?.pendant }

    var isSpeaking: Bool { spoken?.isPlaying ?? false }

    @MainActor
    func toggleSpeaking() {
        spoken?.togglePlayback()
    }

    @MainActor
    fileprivate func spokenFollowHand() {
        spoken?.move(toMystery: currentMysteryIndex, bead: currentBeadIndex)
    }

    // MARK: SpokenRosaryHost

    func spokenRosaryMoved(mystery: Int, bead: Int) {
        if currentMysteryIndex != mystery {
            currentMysteryIndex = mystery
            onMysteryChanged?(mystery)
        }
        if currentBeadIndex != bead {
            currentBeadIndex = bead
        }
    }

    func spokenMeditationURL(decade: Int) async -> String? { nil }

    var spokenRosaryTitle: String { displayName }

    func spokenMysteryName(decade: Int) -> String? {
        mysteries.indices.contains(decade) ? mysteries[decade].name : nil
    }

    func spokenArtwork(decade: Int) -> String? {
        Constants.mysteryImageURL(category: category.rawValue, index: decade)
    }

    func spokenRosaryReached(_ step: SpokenStep) {
        PrayerResumeService.shared.updateSpokenStep(
            step,
            kind: resumeKind,
            setId: 0,
            category: category.rawValue
        )
    }
}
