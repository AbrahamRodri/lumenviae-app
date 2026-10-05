//
//  ReadingsAndRemindersTests.swift
//  Lumen Viae Tests
//
//  The short readings (the Marian Library, St. Carlo, How to Pray's
//  methods and questions, the Devotion in Summary) found by one lookup
//  and every door on them opening something the app holds; the feasts
//  they keep; the reminder copy drawn from the reader's reasons, and
//  never a word of shame in it; the day's quotation.
//

import Foundation
import Testing
@testable import app

@MainActor
struct LibraryReadingsTests {

    private var readings: [LibraryReading] { LibraryReadings.shelves.flatMap(\.entries) }

    @Test func everyReadingIsFoundOnItsOwnShelfAtItsOwnPlace() throws {
        for shelf in LibraryReadings.shelves {
            for (index, entry) in shelf.entries.enumerated() {
                let found = try #require(LibraryReadings.locate(id: entry.id))
                #expect(found.section.id == shelf.id, "\(entry.id) is found on another shelf")
                #expect(found.index == index)
            }
        }
        #expect(LibraryReadings.locate(id: "no-such-reading") == nil)
    }

    @Test func readingAndShelfIdsAreUnique() {
        let ids = readings.map(\.id)
        #expect(Set(ids).count == ids.count, "two readings share an id, so one can never be opened")
        let shelfIDs = LibraryReadings.shelves.map(\.id)
        #expect(Set(shelfIDs).count == shelfIDs.count)
    }

    @Test func everyShelfHoldsSomething() {
        for shelf in LibraryReadings.shelves {
            #expect(!shelf.entries.isEmpty, "\(shelf.id) is empty")
            #expect(!shelf.title.isEmpty)
        }
    }

    @Test func everyReadingHasWords() {
        for reading in readings {
            #expect(!reading.title.isEmpty, "\(reading.id)")
            let hasBody = !reading.paragraphs.isEmpty || !reading.parts.isEmpty || reading.quote != nil
            #expect(hasBody, "\(reading.id) has nothing to read")
        }
    }

    @Test func everyPrayerDoorOpensAPrayerTheAppHolds() {
        for reading in readings {
            for door in reading.doors {
                guard case .prayer(let id, _) = door else { continue }
                let found = PrayerBook.prayer(id) != nil || DevotionPrayers.find(id) != nil
                #expect(found, "\(reading.id) opens a prayer \(id) that is nowhere")
            }
        }
    }

    @Test func everyFeastIsARealDay() {
        let calendar = Calendar(identifier: .gregorian)
        for reading in readings {
            guard let feast = reading.feast else { continue }
            // Every day of the year exists in a leap year
            let date = calendar.date(from: DateComponents(year: 2028, month: feast.month, day: feast.day))
            #expect(date != nil && calendar.component(.day, from: date!) == feast.day,
                    "\(reading.id)'s feast is on \(feast.month)/\(feast.day)")
        }
    }

    @Test func onlyTheMarianLibraryAndCarloLeadHome() {
        for shelf in MarianLibraryData.sections {
            #expect(LibraryReadings.home(of: shelf) != nil)
        }
        for shelf in CarloAcutisData.shelves {
            #expect(LibraryReadings.home(of: shelf) != nil)
        }
        #expect(LibraryReadings.home(of: HowToPrayData.questions) == nil)
        #expect(LibraryReadings.home(of: TrueDevotionData.teaching) == nil)
    }

    @Test func aTableReadsItsRowsFromDashedLines() {
        let table = ReadingTable("Apparitions", "Lourdes — 1858\nFatima — 1917 — Portugal")
        #expect(table.rows.count == 2)
        #expect(table.rows[0].label == "Lourdes")
        #expect(table.rows[0].value == "1858")
        #expect(table.rows[1].value == "1917 — Portugal")
    }
}

@MainActor
struct KeptFeastTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func aFeastStillToComeThisYearIsThisYears() {
        let lourdes = KeptFeast(month: 2, day: 11, name: "Our Lady of Lourdes")
        #expect(lourdes.nextDate(from: date(2026, 1, 5), calendar: calendar) == date(2026, 2, 11, hour: 0))
    }

    @Test func aFeastAlreadyPastIsNextYears() {
        let lourdes = KeptFeast(month: 2, day: 11, name: "Our Lady of Lourdes")
        #expect(lourdes.nextDate(from: date(2026, 10, 3), calendar: calendar) == date(2027, 2, 11, hour: 0))
    }

    @Test func todayCountsAsTheNextTimeItIsKept() {
        let rosary = KeptFeast(month: 10, day: 7, name: "Our Lady of the Rosary")
        let evening = date(2026, 10, 7, hour: 21)
        #expect(rosary.nextDate(from: evening, calendar: calendar) == date(2026, 10, 7, hour: 0))
        #expect(rosary.isToday(evening, calendar: calendar))
        #expect(!rosary.isToday(date(2026, 10, 8), calendar: calendar))
    }

    @Test func aFeastOffTheMissalSaysWhyThereIsNoMass() {
        #expect(KeptFeast(month: 8, day: 14, name: "St. Maximilian Kolbe", inMissal: false).calendarNote != nil)
        #expect(KeptFeast(month: 8, day: 15, name: "The Assumption").calendarNote == nil)
    }
}

@MainActor
struct ReminderMessageTests {

    private let every: [ReminderMessage] =
        ReminderMessage.peace + ReminderMessage.habit + ReminderMessage.devotion
        + ReminderMessage.learning + ReminderMessage.standard

    @Test func noReasonChosenGivesTheNeutralPool() {
        #expect(ReminderMessage.pool(for: []) == ReminderMessage.standard)
    }

    @Test func oneReasonGivesItsOwnPool() {
        #expect(ReminderMessage.pool(for: [.peace]) == ReminderMessage.peace)
        #expect(ReminderMessage.pool(for: [.devotion]) == ReminderMessage.devotion)
    }

    @Test func learningOpensTheWholeCatalog() {
        let pool = ReminderMessage.pool(for: [.learning])
        #expect(Set(pool) == Set(every))
        #expect(pool.count == Set(pool).count, "no message twice")
    }

    @Test func twoReasonsAreInterleavedSoAWeekHearsFromBoth() {
        let pool = ReminderMessage.pool(for: [.peace, .habit])
        #expect(Set(pool) == Set(ReminderMessage.peace + ReminderMessage.habit))
        let firstTwo = Set(pool.prefix(2))
        #expect(firstTwo.contains(ReminderMessage.peace[0]))
        #expect(firstTwo.contains(ReminderMessage.habit[0]))
    }

    @Test func noReminderShamesTheReader() {
        let forbidden = ["missed", "don't break", "don’t break", "lose your", "falling behind", "streak"]
        for message in every {
            let words = (message.title + " " + message.body).lowercased()
            for word in forbidden {
                #expect(!words.contains(word), "\"\(message.title)\" says \(word)")
            }
            #expect(!message.title.isEmpty && !message.body.isEmpty)
        }
    }

    @Test func noReminderPromisesADuration() {
        // A notification is no place to promise "about 18 minutes"
        for message in every {
            #expect(!(message.title + message.body).lowercased().contains("about "), "\(message.title)")
        }
    }

    @Test func everyReasonHasWords() {
        for intention in PrayerIntention.allCases {
            #expect(!intention.displayName.isEmpty)
            #expect(!intention.detail.isEmpty)
            #expect(!ReminderMessage.pool(for: [intention]).isEmpty)
        }
    }
}

@MainActor
struct RosaryQuoteTests {

    @Test func theCatalogIsFullAndUnrepeated() {
        #expect(RosaryQuotes.all.count >= 2)
        #expect(Set(RosaryQuotes.all.map(\.text)).count == RosaryQuotes.all.count)
        for quote in RosaryQuotes.all {
            #expect(!quote.text.isEmpty && !quote.author.isEmpty)
        }
    }

    @Test func theCompletionScreenNeverRepeatsHomesLine() {
        #expect(RosaryQuotes.today != RosaryQuotes.afterPraying)
        #expect(RosaryQuotes.all.contains(RosaryQuotes.today))
    }
}
