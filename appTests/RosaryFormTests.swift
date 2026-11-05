//
//  RosaryFormTests.swift
//  Lumen Viae Tests
//
//  One Rosary in three forms: which rows each form's own page carries,
//  and the line a meditation set's page sets under its name.
//

import Testing
@testable import app

@MainActor
struct RosaryFormTests {

    // MARK: - The Forms

    @Test func theSpokenFormsAreTheirRosaryForms() {
        #expect(RosaryForm(SpokenForm.scriptural) == .scriptural)
        #expect(RosaryForm(SpokenForm.plain) == .holy)
    }

    // MARK: - The Rows Beneath

    @Test(arguments: [false, true])
    func eachFormCarriesItsRows(aloud: Bool) {
        #expect(RosaryInfoRow.rows(for: .meditation, aloud: aloud) == [.voice])
        #expect(RosaryInfoRow.rows(for: .holy, aloud: aloud) == [.audio, .mysteries, .voice])
    }

    /// Read in silence, nothing in the Scriptural Rosary is spoken, so it
    /// has no voice and no speed to choose
    @Test func theScripturalRosaryOffersAVoiceOnlyWhenItSpeaks() {
        #expect(RosaryInfoRow.rows(for: .scriptural, aloud: false) == [.mysteries])
        #expect(RosaryInfoRow.rows(for: .scriptural, aloud: true) == [.mysteries, .voice])
    }

    @Test func theRowsSayWhatIsSet() {
        #expect(RosaryInfoRow.mysteriesValue(.joyful, today: .joyful) == "Joyful · today")
        #expect(RosaryInfoRow.mysteriesValue(.sevenSorrows, today: .joyful) == "Seven Sorrows")
        #expect(RosaryInfoRow.voiceValue(voice: "Female", rate: "1×") == "Female · 1×")
        #expect(RosaryInfoRow.holyAudioValue == "Whole Rosary · pause anytime")
    }

    // MARK: - A Set's Subtitle

    @Test func aShortDescriptionIsTheSubtitleAndNothingMore() {
        let description = "Meditations on the Joyful Mysteries from Archbishop Fulton J. Sheen"
        let subtitle = MeditationSetDetailViewModel.subtitle(from: description)
        #expect(subtitle == description)
        #expect(MeditationSetDetailViewModel.about(description: description, subtitle: subtitle) == nil)
    }

    @Test func aShortFirstSentenceLeadsAndTheWholeStaysBelow() {
        let description = "St. Ignatius gives each mystery as a few numbered points. Take each point slowly: picture the persons, hear the words."
        let subtitle = MeditationSetDetailViewModel.subtitle(from: description)
        // "St." does not end the sentence
        #expect(subtitle == "St. Ignatius gives each mystery as a few numbered points.")
        #expect(MeditationSetDetailViewModel.about(description: description, subtitle: subtitle) == description)
    }

    @Test func initialsTitlesAndYearsAreReadRight() {
        #expect(MeditationSetDetailViewModel.firstSentence(of: "From Fulton J. Sheen. More.") == "From Fulton J. Sheen.")
        #expect(MeditationSetDetailViewModel.firstSentence(of: "Mullan, S.J. and others. More.") == "Mullan, S.J. and others.")
        #expect(MeditationSetDetailViewModel.firstSentence(of: "Drawn from Bethlehem (1860). More.") == "Drawn from Bethlehem (1860).")
        #expect(MeditationSetDetailViewModel.firstSentence(of: "One sentence only") == "One sentence only")
    }

    @Test func aLongFirstSentenceIsNoSubtitle() {
        let description = "Verbatim passages from the visions of Blessed Anne Catherine Emmerich on the Joyful Mysteries, drawn from The Life of Jesus Christ and Biblical Revelations (1914)."
        #expect(MeditationSetDetailViewModel.subtitle(from: description) == nil)
        #expect(MeditationSetDetailViewModel.about(description: description, subtitle: nil) == description)
    }

    @Test func noDescriptionIsNoSubtitle() {
        #expect(MeditationSetDetailViewModel.subtitle(from: nil) == nil)
        #expect(MeditationSetDetailViewModel.subtitle(from: "  ") == nil)
        #expect(MeditationSetDetailViewModel.about(description: nil, subtitle: nil) == nil)
    }
}
