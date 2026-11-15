//
//  NovenaTwinTests.swift
//  appTests
//
//  A novena's twin cut into its days (NovenaTwin), as the pray-along
//  page shows it one day at a time: the days by their headings, the
//  closing page from what stands before the first day and after the last.
//

import Testing

@testable import app

@MainActor
struct NovenaTwinTests {

    private func twin(_ text: String, length: Int) -> (NovenaTwin?, [String]) {
        let stanzas = PrayAlongView.stanzas(text)
        return (NovenaTwin(stanzas: stanzas, length: length), stanzas)
    }

    private let threeDays = """
        [Each day: the Sign of the Cross, then the prayer of the day, then the closing prayer below.]

        [The First Day.]

        First day's prayer.

        [Here name your request.]

        [The Second Day.]

        Second day's prayer.

        [The Third Day.]

        Third day's prayer.

        [Our Father, Hail Mary, Glory Be.]

        [Closing prayer, each day.]

        The prayer said every day. Amen.
        """

    @Test func cutsTheDaysByTheirHeadings() throws {
        let (cut, stanzas) = twin(threeDays, length: 3)
        let twin = try #require(cut)
        #expect(twin.days.count == 3)
        #expect(
            twin.stanzas(day: 1).map { stanzas[$0] }.sorted()
                == [
                    "[Here name your request.]", "[The First Day.]", "First day's prayer.",
                ].sorted())
        #expect(twin.stanzas(day: 2).count == 2)
    }

    @Test func theLastDayKeepsItsSaidPrayersAndEndsAtTheNextNamedPart() throws {
        let (cut, stanzas) = twin(threeDays, length: 3)
        let twin = try #require(cut)
        let third = twin.stanzas(day: 3).map { stanzas[$0] }
        #expect(third.contains("[Our Father, Hail Mary, Glory Be.]"))
        #expect(!third.contains("[Closing prayer, each day.]"))
    }

    @Test func theClosingHoldsThePrefaceAndTheTail() throws {
        let (cut, stanzas) = twin(threeDays, length: 3)
        let twin = try #require(cut)
        let closing = twin.stanzas(day: nil).map { stanzas[$0] }
        #expect(closing.count == 3)
        #expect(closing.contains { $0.hasPrefix("[Each day:") })
        #expect(closing.contains("The prayer said every day. Amen."))
    }

    @Test func aTwinWhoseHeadingsDoNotNameEveryDayStaysWhole() {
        #expect(twin(threeDays, length: 9).0 == nil)
        #expect(twin("[Each day.]\n\nThe same prayer every day.", length: 9).0 == nil)
    }

    @Test func daysAreNamedInEnglishAndSpanish() {
        for words in [
            "The Fourth Day.", "The Eighth Day, December 6.", "Día cuarto.", "Cuarto día.", "Día 4.", "Primer día.",
        ] {
            #expect(NovenaTwin.namesADay(words), "\(words)")
        }
        for words in ["Each day: the Sign of the Cross", "Closing prayer, each day.", "The Day of Consecration"] {
            #expect(!NovenaTwin.namesADay(words), "\(words)")
        }
    }

    @Test func theBundledNovenasThatNameTheirDaysAreCut() throws {
        for novena in LibraryContent.prayerBook.novenas where novena.prayerID == "undoer_of_knots_novena" {
            let prayer = try #require(PrayerBook.prayer(novena.prayerID))
            let stanzas = PrayAlongView.stanzas(prayer.english)
            let twin = try #require(NovenaTwin(stanzas: stanzas, length: novena.length))
            #expect(twin.days.count == novena.length)
            #expect(!twin.closing.isEmpty)
        }
    }
}
