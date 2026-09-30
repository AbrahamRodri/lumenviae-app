//
//  RosaryFormTests.swift
//  Lumen Viae Tests
//
//  One Rosary in three forms: which choices each form's page offers and
//  when, what every option is called, that Whole Rosary always counts on
//  the screen, which rows stand beneath the choices, and the line a
//  meditation set's page sets under its name.
//

import Testing
@testable import app

@MainActor
struct RosaryFormTests {

    // MARK: - The Choices Offered

    @Test(arguments: [RosaryForm.meditation, .scriptural])
    func bothChoicesStandWhileTheVoiceReadsTheMeditationAlone(form: RosaryForm) {
        #expect(RosaryChoice.offered(for: form, aloud: false) == [.audio, .counting])
    }

    @Test(arguments: [RosaryForm.meditation, .scriptural])
    func countingFallsAwayWhenEveryPrayerIsSaidAloud(form: RosaryForm) {
        #expect(RosaryChoice.offered(for: form, aloud: true) == [.audio])
    }

    @Test(arguments: [false, true])
    func theHolyRosaryOffersNoChoice(aloud: Bool) {
        #expect(RosaryChoice.offered(for: .holy, aloud: aloud).isEmpty)
    }

    // MARK: - What Each Option Is Called

    @Test func theOptionsAreNamedAsTheDesignNamesThem() {
        #expect(RosaryChoice.audio.options(for: .meditation).map(\.name) == ["Meditation Only", "Whole Rosary"])
        #expect(RosaryChoice.audio.options(for: .scriptural).map(\.name) == ["Read in Silence", "Whole Rosary"])
        #expect(RosaryChoice.counting.options(for: .meditation).map(\.name) == ["On My Rosary", "On the Screen"])
        #expect(RosaryChoice.counting.options(for: .scriptural).map(\.name) == ["On My Rosary", "On the Screen"])
    }

    @Test func theQuieterWayComesFirstAsTheSettingsFalse() {
        for choice in RosaryChoice.allCases {
            #expect(choice.options(for: .meditation).map(\.value) == [false, true])
        }
    }

    @Test func everyNoteIsItsOwn() {
        let notes = [
            RosaryChoice.audio.note(for: false), RosaryChoice.audio.note(for: true),
            RosaryChoice.audio.note(for: false, form: .scriptural), RosaryChoice.audio.note(for: true, form: .scriptural),
            RosaryChoice.counting.note(for: false), RosaryChoice.counting.note(for: true),
        ]
        #expect(Set(notes).count == notes.count)
        #expect(RosaryChoice.counting.note(for: false, form: .scriptural) == RosaryChoice.counting.note(for: false))
    }

    @Test func settingsSharedWordingIsTheChoicesWording() {
        #expect(UserSettings.prayAloudTitle == "Audio")
        #expect(UserSettings.beadCounterTitle == "Counting")
        #expect(UserSettings.prayAloudDetail(isOn: true) == RosaryChoice.audio.note(for: true))
        #expect(UserSettings.beadCounterDetail(isOn: false) == RosaryChoice.counting.note(for: false))
    }

    // MARK: - Where the Beads Are Counted

    @Test func wholeRosaryAlwaysCountsOnTheScreen() {
        for form in [RosaryForm.meditation, .scriptural, .holy] {
            #expect(form.countsOnScreen(aloud: true, onBeads: false))
            #expect(form.countsOnScreen(aloud: true, onBeads: true))
        }
    }

    @Test func readingTheMeditationAloneCountsWhereChosen() {
        #expect(!RosaryForm.meditation.countsOnScreen(aloud: false, onBeads: false))
        #expect(RosaryForm.meditation.countsOnScreen(aloud: false, onBeads: true))
        #expect(!RosaryForm.scriptural.countsOnScreen(aloud: false, onBeads: false))
        #expect(RosaryForm.scriptural.countsOnScreen(aloud: false, onBeads: true))
        // The Holy Rosary is said aloud whatever the setting
        #expect(RosaryForm.holy.countsOnScreen(aloud: false, onBeads: false))
        #expect(RosaryForm.holy.praysAloud(setting: false))
    }

    @Test func theSpokenFormsAreTheirRosaryForms() {
        #expect(RosaryForm(SpokenForm.scriptural) == .scriptural)
        #expect(RosaryForm(SpokenForm.plain) == .holy)
    }

    // MARK: - The Rows Beneath

    @Test func eachFormCarriesItsRows() {
        #expect(RosaryInfoRow.rows(for: .meditation) == [.voice])
        #expect(RosaryInfoRow.rows(for: .scriptural) == [.mysteries, .voice])
        #expect(RosaryInfoRow.rows(for: .holy) == [.audio, .mysteries, .voice])
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
