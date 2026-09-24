//
//  SpokenRosaryScriptTests.swift
//  Lumen Viae Tests
//
//  The spoken Rosary's script, checked against the order the server
//  records and serves (LumenViae.Rosary.PrayerAudio.script/3): the four
//  sets of the Rosary, the Seven Sorrows chaplet in its Servite form, the
//  optional closing prayers, the Scriptural Rosary's verses, and that
//  every recording a script asks for is one the server's manifest names.
//
//  NOTE: the project has no unit test target yet. This folder sits
//  outside the `app` synchronized group so it is not compiled into the
//  app. To run it, add a Unit Testing Bundle target named `appTests`
//  hosted in `app` (File > New > Target), pointing its synchronized
//  folder at `appTests/`.
//

import Testing
@testable import app

@MainActor
struct SpokenRosaryScriptTests {

    // MARK: - Helpers

    /// A segment as one word: the prayer id, "announcement", "meditation"
    /// or "verse:<n>"
    private func name(_ segment: SpokenSegment) -> String {
        switch segment.kind {
        case .prayer(let id): return id
        case .announcement: return "announcement"
        case .meditation: return "meditation"
        case .verse(let number): return "verse:\(number)"
        }
    }

    private func keys(_ category: MysteryCategory) -> [String] {
        MysteryData.mysteries(for: category).map { "\($0.category.lowercased())_\($0.order)" }
    }

    private func script(
        _ category: MysteryCategory,
        style: SpokenRosaryScript.Style = .meditation,
        extras: [RosaryClosingExtra] = []
    ) -> [SpokenSegment] {
        SpokenRosaryScript.build(
            category: category,
            mysteryKeys: keys(category),
            hailMarys: category == .sevenSorrows ? 7 : 10,
            style: style,
            extras: extras
        )
    }

    private func phase(_ script: [SpokenSegment], _ phase: SpokenSegment.Phase) -> [SpokenSegment] {
        script.filter { $0.phase == phase }
    }

    // MARK: - The Four Sets of the Rosary

    @Test(arguments: [MysteryCategory.joyful, .sorrowful, .glorious, .luminous])
    func rosaryOpensOnThePendant(category: MysteryCategory) {
        let opening = phase(script(category), .opening)
        #expect(opening.map(name) == [
            "sign_of_cross", "apostles_creed", "our_father",
            "hail_mary", "hail_mary", "hail_mary", "glory_be"
        ])
        #expect(opening.map(\.place) == [
            .cross, .cross, .largeBead, .smallBead(0), .smallBead(1), .smallBead(2), .chain
        ])
    }

    @Test(arguments: [MysteryCategory.joyful, .sorrowful, .glorious, .luminous])
    func rosaryDecadesAreAnnouncedMeditatedAndPrayed(category: MysteryCategory) {
        let decades = phase(script(category), .decade)
        #expect(decades.count == 5 * 15)

        let expected = ["announcement", "meditation", "our_father"]
            + Array(repeating: "hail_mary", count: 10)
            + ["glory_be", "fatima_prayer"]
        for decade in 0..<5 {
            let segments = decades.filter { $0.mystery == decade }
            #expect(segments.map(name) == expected)
            #expect(segments.allSatisfy { $0.mysteryKey == keys(category)[decade] })
            #expect(segments.filter { name($0) == "hail_mary" }.map(\.bead) == Array(1...10))
            #expect(segments.suffix(2).allSatisfy { $0.bead == 11 })
        }
    }

    @Test(arguments: [MysteryCategory.joyful, .sorrowful, .glorious, .luminous])
    func rosaryClosesWithTheSalveAndTheCollect(category: MysteryCategory) {
        let whole = script(category)
        let closing = phase(whole, .closing)
        #expect(closing.map(name) == ["hail_holy_queen", "rosary_closing_prayer", "sign_of_cross"])
        #expect(closing.allSatisfy { $0.mystery == 4 && $0.bead == 11 })
        #expect(whole.count == 7 + 75 + 3)
    }

    @Test func rosaryCountsEveryPrayer() {
        let names = script(.joyful).map(name)
        #expect(names.filter { $0 == "hail_mary" }.count == 53)
        #expect(names.filter { $0 == "our_father" }.count == 6)
        #expect(names.filter { $0 == "glory_be" }.count == 6)
        #expect(names.filter { $0 == "fatima_prayer" }.count == 5)
        #expect(names.filter { $0 == "announcement" }.count == 5)
        #expect(names.filter { $0 == "sign_of_cross" }.count == 2)
        #expect(!names.contains("act_of_contrition"))
        #expect(!names.contains("sorrows_closing_prayer"))
    }

    // MARK: - The Seven Sorrows Chaplet

    @Test func chapletOpensWithTheActOfContrition() {
        let opening = phase(script(.sevenSorrows), .opening)
        #expect(opening.map(name) == ["sign_of_cross", "act_of_contrition"])
        #expect(opening.allSatisfy { $0.mystery == 0 && $0.bead == 0 })
    }

    @Test func chapletSorrowsHaveSevenHailMarysAndNoFatimaPrayer() {
        let decades = phase(script(.sevenSorrows), .decade)
        #expect(decades.count == 7 * 11)

        let expected = ["announcement", "meditation", "our_father"]
            + Array(repeating: "hail_mary", count: 7)
            + ["glory_be"]
        for sorrow in 0..<7 {
            let segments = decades.filter { $0.mystery == sorrow }
            #expect(segments.map(name) == expected)
            #expect(segments.last?.bead == 8)
        }
        #expect(!decades.map(name).contains("fatima_prayer"))
    }

    @Test func chapletClosesWithHerTearsAndItsOwnPrayer() {
        let closing = phase(script(.sevenSorrows), .closing)
        #expect(closing.map(name) == [
            "hail_mary", "hail_mary", "hail_mary", "sorrows_closing_prayer", "sign_of_cross"
        ])
        #expect(closing.prefix(3).allSatisfy { $0.caption.hasPrefix("In honor of her tears") })
        #expect(closing.allSatisfy { $0.mystery == 6 && $0.bead == 8 })
    }

    @Test func chapletIgnoresTheRosarysClosingPrayers() {
        let plain = script(.sevenSorrows).map(name)
        let chosen = script(.sevenSorrows, extras: RosaryClosingExtra.allCases).map(name)
        #expect(plain == chosen)
        #expect(!chosen.contains("hail_holy_queen"))
        #expect(!chosen.contains("memorare"))
        #expect(!chosen.contains("st_michael_prayer"))
        #expect(plain.count == 2 + 77 + 5)
    }

    // MARK: - The Optional Closing Prayers

    @Test func closingPrayersFollowTheCollectInTheirOwnOrder() {
        let closing = phase(script(.glorious, extras: [.stMichael, .holyFather, .memorare]), .closing)
        #expect(closing.map(name) == [
            "hail_holy_queen", "rosary_closing_prayer",
            "our_father", "hail_mary", "glory_be",
            "memorare", "st_michael_prayer",
            "sign_of_cross"
        ])
        #expect(closing[2...4].allSatisfy { $0.caption == "For the intentions of the Holy Father" })
    }

    @Test func eachClosingPrayerStandsAlone() {
        #expect(phase(script(.joyful, extras: [.memorare]), .closing).map(name)
            == ["hail_holy_queen", "rosary_closing_prayer", "memorare", "sign_of_cross"])
        #expect(phase(script(.joyful, extras: [.stMichael]), .closing).map(name)
            == ["hail_holy_queen", "rosary_closing_prayer", "st_michael_prayer", "sign_of_cross"])
        #expect(phase(script(.joyful, extras: [.holyFather]), .closing).map(name)
            == ["hail_holy_queen", "rosary_closing_prayer", "our_father", "hail_mary", "glory_be", "sign_of_cross"])
    }

    @Test func closingPrayersDoNotTouchTheDecades() {
        let plain = script(.luminous).filter { $0.phase != .closing }
        let chosen = script(.luminous, extras: RosaryClosingExtra.allCases).filter { $0.phase != .closing }
        #expect(plain == chosen)
    }

    // MARK: - The Scriptural Rosary

    @Test(arguments: [MysteryCategory.joyful, .sevenSorrows])
    func scripturalVerseComesBeforeEachHailMary(category: MysteryCategory) {
        let whole = script(category, style: .scriptural)
        let hailMarys = category == .sevenSorrows ? 7 : 10
        #expect(!whole.map(name).contains("meditation"))
        #expect(whole.filter { $0.phase != .decade }.allSatisfy {
            if case .verse = $0.kind { return false }
            return true
        })

        for decade in 0..<keys(category).count {
            let segments = whole.filter { $0.phase == .decade && $0.mystery == decade }
            var expected = ["announcement", "our_father"]
            for number in 1...hailMarys {
                expected += ["verse:\(number)", "hail_mary"]
            }
            expected += category == .sevenSorrows ? ["glory_be"] : ["glory_be", "fatima_prayer"]
            #expect(segments.map(name) == expected)

            for (index, segment) in segments.enumerated() {
                guard case .verse(let number) = segment.kind else { continue }
                #expect(segment.bead == number)
                #expect(segments[index + 1].bead == number)
            }
        }
    }

    // MARK: - Recordings the Server Has

    /// What a full GET /api/rosary/audio names, per the server's catalogue
    /// (LumenViae.Rosary.PrayerAudio): the twelve prayers, an
    /// announcement for every mystery, and the Scriptural Rosary's verses
    /// from the same export as ScripturalRosaryData.
    private static let serverPrayerIDs: Set<String> = [
        "sign_of_cross", "apostles_creed", "our_father", "hail_mary", "glory_be",
        "fatima_prayer", "hail_holy_queen", "rosary_closing_prayer",
        "act_of_contrition", "sorrows_closing_prayer", "memorare", "st_michael_prayer"
    ]

    private func serverHas(_ clip: RosaryAudioPack.ClipID) -> Bool {
        switch clip {
        case .prayer(let id):
            return Self.serverPrayerIDs.contains(id)
        case .announcement(let key):
            return MysteryCategory.allCases.contains { keys($0).contains(key) }
        case .verse(let key, let number):
            guard let separator = key.lastIndex(of: "_"),
                  let order = Int(key[key.index(after: separator)...]) else { return false }
            let category = String(key[..<separator])
            let count = ScripturalRosaryData.verses(category: category, order: order)?.count ?? 0
            return (1...max(count, 1)).contains(number) && count > 0
        }
    }

    @Test func everyScriptNamesOnlyRecordingsTheServerHas() {
        for category in MysteryCategory.allCases {
            for style in SpokenRosaryScript.Style.allCases {
                let clips = SpokenRosaryScript.clips(in: script(category, style: style, extras: RosaryClosingExtra.allCases))
                #expect(!clips.isEmpty)
                for clip in clips {
                    #expect(serverHas(clip), "\(category) \(style) asks for \(clip)")
                }
            }
        }
    }

    @Test func theAppsPrayerTextCoversEveryRecordedPrayer() {
        for id in Self.serverPrayerIDs {
            #expect(DevotionPrayers.find(id) != nil, "no text for \(id)")
        }
    }

    @Test func meditationsAreNotPackClips() {
        let clips = SpokenRosaryScript.clips(in: script(.joyful))
        let meditations = script(.joyful).filter { $0.kind == .meditation }
        #expect(meditations.count == 5)
        #expect(meditations.allSatisfy { RosaryAudioPack.ClipID(segment: $0) == nil })
        #expect(clips.contains(.announcement("joyful_1")))
    }

    @Test func offlineLibraryFetchesEveryClipAnyScriptNeeds() {
        let every = SpokenRosaryScript.everyClip()
        for clip in every {
            #expect(serverHas(clip), "offline download asks for \(clip)")
        }
        for category in MysteryCategory.allCases {
            for style in SpokenRosaryScript.Style.allCases {
                let needed = SpokenRosaryScript.clips(in: script(category, style: style, extras: RosaryClosingExtra.allCases))
                #expect(needed.isSubset(of: every))
            }
        }
    }

    // MARK: - Resuming

    @Test func resumeIndexOnlyTrustsAStepThatStillLinesUp() {
        let whole = script(.joyful, extras: [.memorare])
        let index = whole.firstIndex { $0.kind == .prayer("memorare") }!
        let segment = whole[index]
        let step = SpokenStep(index: index, mystery: segment.mystery, bead: segment.bead, caption: segment.caption)
        #expect(SpokenRosaryScript.resumeIndex(in: whole, step: step) == index)

        // The same place in a script without the Memorare is the Sign of
        // the Cross: same bead, another prayer
        let shorter = script(.joyful)
        #expect(SpokenRosaryScript.resumeIndex(in: shorter, step: step) == nil)

        // A step whose bead no longer matches is not guessed at
        let drifted = SpokenStep(index: 20, mystery: 0, bead: 9, caption: "The Glory Be")
        #expect(SpokenRosaryScript.resumeIndex(in: whole, step: drifted) == nil)
        #expect(SpokenRosaryScript.resumeIndex(in: whole, step: nil) == nil)
    }

    // MARK: - The Rosary Aloud

    @Test(arguments: [MysteryCategory.joyful, .sorrowful, .glorious, .luminous])
    func plainRosaryIsThePrayersAlone(category: MysteryCategory) {
        let whole = script(category, style: .plain)
        let decades = phase(whole, .decade)
        let expected = ["announcement", "our_father"]
            + Array(repeating: "hail_mary", count: 10)
            + ["glory_be", "fatima_prayer"]
        for decade in 0..<5 {
            #expect(decades.filter { $0.mystery == decade }.map(name) == expected)
        }
        // The same pendant and the same close as every other style
        #expect(phase(whole, .opening).map(name) == phase(script(category), .opening).map(name))
        #expect(phase(whole, .closing).map(name) == ["hail_holy_queen", "rosary_closing_prayer", "sign_of_cross"])
        #expect(whole.count == 7 + 5 * 14 + 3)
    }

    @Test func plainChapletIsItsPrayersAlone() {
        let whole = script(.sevenSorrows, style: .plain, extras: RosaryClosingExtra.allCases)
        let expected = ["announcement", "our_father"]
            + Array(repeating: "hail_mary", count: 7)
            + ["glory_be"]
        for sorrow in 0..<7 {
            #expect(phase(whole, .decade).filter { $0.mystery == sorrow }.map(name) == expected)
        }
        #expect(phase(whole, .opening).map(name) == ["sign_of_cross", "act_of_contrition"])
        #expect(phase(whole, .closing).map(name) == [
            "hail_mary", "hail_mary", "hail_mary", "sorrows_closing_prayer", "sign_of_cross"
        ])
    }

    @Test func plainRosaryNeedsNoRecordingTheOthersDoNot() {
        let plain = SpokenRosaryScript.clips(in: script(.joyful, style: .plain))
        let meditation = SpokenRosaryScript.clips(in: script(.joyful, style: .meditation))
        #expect(plain.isSubset(of: meditation))
    }

    // MARK: - The Strand's Words

    @Test func chapletGloryBeBeadHasNoFatimaPrayer() {
        let rosary = RosaryStrand(decades: 5, hailMarys: 10)
        let chaplet = RosaryStrand(decades: 7, hailMarys: 7, saysFatimaPrayer: false)
        #expect(rosary.label(bead: 11) == "Glory Be & Fatima Prayer")
        #expect(chaplet.label(bead: 8) == "Glory Be")
        #expect(chaplet.labelLines(bead: 8) == ["Glory Be"])
    }
}
