//
//  RosaryWordsTests.swift
//  Lumen Viae
//
//  The small words the Rosary player and the Prayer Record say: the
//  pill, the place line, the pendant, the pauses between segments, the
//  prayers after the Rosary and a milestone as VoiceOver reads it.
//

import Foundation
import SwiftUI
import Testing

@testable import app

@MainActor
struct RosaryWordsTests {

    // MARK: - The pill

    @Test func thePillCountsTheMysteriesAlone() {
        let rosary = RosaryStop.all(decades: 5, includesPendant: true)
        #expect(RosaryStopsPill.label(.mystery(1), of: rosary, isChaplet: false) == "Mystery 2 of 5")
        #expect(RosaryStopsPill.label(.opening, of: rosary, isChaplet: false) == "Opening Prayers")
        #expect(RosaryStopsPill.label(.closing, of: rosary, isChaplet: false) == "Closing Prayers")

        let chaplet = RosaryStop.all(decades: 7, includesPendant: true)
        #expect(RosaryStopsPill.label(.mystery(2), of: chaplet, isChaplet: true) == "Sorrow 3 of 7")
    }

    @Test func aStopNotInTheListStandsFirst() {
        let decades = RosaryStop.all(decades: 5, includesPendant: false)
        #expect(RosaryStop.closing.position(in: decades) == 0)
        #expect(RosaryStop.mystery(3).position(in: decades) == 3)
    }

    // MARK: - The place line

    @Test func theChapletsOpeningIsBeforeTheFirstSorrow() {
        #expect(OneRosaryColumn<EmptyView>.place(mystery: nil, of: 7, phase: .opening) == "Before the first sorrow")
        #expect(OneRosaryColumn<EmptyView>.place(mystery: nil, of: 7) == "Before the first sorrow")
        #expect(OneRosaryColumn<EmptyView>.place(mystery: nil, of: 7, phase: .closing) == "After the last sorrow")
        #expect(OneRosaryColumn<EmptyView>.place(mystery: nil, of: 5) == "Before the first mystery")
    }

    // MARK: - The pendant

    @Test func thePendantsBeadsAreNamedAndRiseFromTheCross() {
        #expect(PendantPlace.cross.name == "The crucifix")
        #expect(PendantPlace.smallBead(1).name == "Small bead 2 of 3")
        let climb: [PendantPlace] = [.cross, .largeBead, .smallBead(0), .smallBead(1), .smallBead(2), .chain, .medal]
        #expect(climb.map(\.rank) == [0, 1, 2, 3, 4, 5, 6])
    }

    @Test func theHeadingNamesOpeningOrClosing() {
        let closing = SpokenPendant(phase: .closing, prayerID: "salve", title: "", place: nil, isChaplet: false)
        let opening = SpokenPendant(phase: .opening, prayerID: "creed", title: "", place: .cross, isChaplet: false)
        #expect(closing.heading == "The Closing Prayers")
        #expect(opening.heading == "The Opening Prayers")
    }

    // MARK: - Segments

    @Test func aMeditationSettlesLongestAndAVerseRunsOn() {
        func segment(_ kind: SpokenSegment.Kind) -> SpokenSegment {
            SpokenSegment(kind: kind, phase: .decade, mystery: 0, bead: 0, mysteryKey: "joyful_1", caption: "")
        }
        #expect(segment(.meditation).pauseAfter == 2.0)
        #expect(segment(.announcement).pauseAfter == 1.2)
        #expect(segment(.prayer("hail_mary")).pauseAfter == 0.9)
        #expect(segment(.verse(3)).pauseAfter == 0.8)
    }

    @Test func aSegmentsKeyIsTheSameInEveryLanguage() {
        #expect(SpokenSegment.Kind.verse(3).key == "verse:3")
        #expect(SpokenSegment.Kind.prayer("glory_be").key == "prayer:glory_be")
        #expect(SpokenSegment.Kind.announcement.key == "announcement")
        #expect(SpokenSegment.Kind.meditation.key == "meditation")
    }

    // MARK: - After the Rosary

    @Test func thePrayersAfterTheRosaryKeepTheirOrder() {
        #expect(RosaryClosingExtra.ordered([.stMichael, .holyFather]) == [.holyFather, .stMichael])
        #expect(RosaryClosingExtra.ordered([.memorare, .memorare]) == [.memorare])
        #expect(RosaryClosingExtra.holyFather.prayers.map(\.id) == ["our_father", "hail_mary", "glory_be"])
        #expect(RosaryClosingExtra.stMichael.prayers.map(\.id) == ["st_michael_prayer"])
    }

    // MARK: - Milestones

    @Test func aMilestoneIsReadWithAPauseNotADot() throws {
        let week = try #require(StreakMilestone.milestone(reachedAt: 7))
        #expect(week.spokenTitle == "7 days, a faithful week")
        let triduum = try #require(StreakMilestone.milestone(reachedAt: 3))
        #expect(triduum.spokenTitle == triduum.name)
        #expect(StreakMilestone.all.allSatisfy { !$0.spokenTitle.contains("·") })
    }
}
