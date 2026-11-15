//
//  RubricSpokenTests.swift
//  appTests
//
//  VoiceOver hears a versicle and its response as the website says
//  them, "Leader:" and "All:", never the symbols' names, and the
//  cross not at all.
//

import Testing

@testable import app

@MainActor
struct RubricSpokenTests {

    @Test func aVersicleAndResponseAreHeardAsLeaderAndAll() {
        #expect(Rubric.spoken("℣. Pray for us, O holy Mother of God.") == "Leader: Pray for us, O holy Mother of God.")
        #expect(Rubric.spoken("℟. Amen.") == "All: Amen.")
        #expect(Rubric.spoken("℟") == "All:")
    }

    @Test func aLitanyLineKeepsItsInvocationAndAnswer() {
        #expect(Rubric.spoken("Holy Mary, ℟. pray for us.") == "Holy Mary, All: pray for us.")
    }

    @Test func theCrossIsSilent() {
        #expect(Rubric.spoken("℣. O God, ✠ come to my assistance.") == "Leader: O God, come to my assistance.")
    }

    @Test func aLineWithNoMarksIsUnchanged() {
        #expect(Rubric.spoken("Hail Mary, full of grace,") == "Hail Mary, full of grace,")
    }

    @Test func aPlayersDirectionIsHeardOutOfItsBrackets() {
        #expect(Rubric.spokenParagraph(["[Let us pray.]", "℣. Lord, have mercy."]) == "Let us pray. Leader: Lord, have mercy.")
    }
}
