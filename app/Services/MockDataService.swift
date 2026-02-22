//
//  MockDataService.swift
//  app
//
//  Provides mock data for previews, testing, and offline fallback.
//  Data mirrors the structure returned by the API.
//

import Foundation
import SwiftUI

/// Service providing mock data for previews and offline use
struct MockDataService {
    // MARK: - Mysteries

    /// Get mock mysteries for a category
    static func mysteries(for category: MysteryCategory) -> [Mystery] {
        switch category {
        case .joyful:
            return joyfulMysteries
        case .sorrowful:
            return sorrowfulMysteries
        case .glorious:
            return gloriousMysteries
        case .luminous:
            return luminousMysteries
        case .sevenSorrows:
            return sevenSorrowsMysteries
        }
    }

    /// All mock mysteries across all categories
    static var allMysteries: [Mystery] {
        joyfulMysteries + sorrowfulMysteries + gloriousMysteries + luminousMysteries + sevenSorrowsMysteries
    }

    // MARK: - Meditation Sets

    /// Get mock meditation sets for a category
    static func meditationSets(for category: MysteryCategory) -> [MeditationSetSummary] {
        [
            MeditationSetSummary(
                id: 0,
                name: "Traditional Meditations",
                category: category.rawValue,
                description: "Classic meditations drawn from the rich tradition of the Church, focusing on the central themes of each mystery."
            ),
            MeditationSetSummary(
                id: 0,
                name: "St. Louis de Montfort",
                category: category.rawValue,
                description: "Meditations from the great Marian saint, emphasizing total consecration to Jesus through Mary."
            ),
            MeditationSetSummary(
                id: 0,
                name: "Scriptural Rosary",
                category: category.rawValue,
                description: "Each bead accompanied by a verse of Scripture, immersing you in the Word of God."
            )
        ]
    }

    /// Get a mock full meditation set with meditations
    static func meditationSet(for category: MysteryCategory, includeAudio: Bool = false) -> MeditationSet {
        let mysteries = self.mysteries(for: category)
        let meditations = mysteries.map { mystery in
            Meditation(
                id: 0,
                title: mystery.name,
                content: "Consider the mystery of \(mystery.name). \(mystery.description ?? "")",
                author: "Traditional",
                source: nil,
                audioUrl: includeAudio ? "https://example.com/audio.mp3" : nil,
                mystery: mystery
            )
        }

        return MeditationSet(
            id: 0,
            name: "Traditional Meditations",
            category: category.rawValue,
            description: "Classic meditations from the tradition of the Church.",
            meditations: meditations
        )
    }

    // MARK: - Quotes

    /// Daily inspirational quotes (rotates by day of year)
    static let quotes: [(text: String, author: String)] = [
        ("The Rosary is the most beautiful and the most rich in graces of all prayers; it is the prayer that touches most the Heart of the Mother of God.", "St. Pius X"),
        ("Give me an army saying the Rosary and I will conquer the world.", "Bl. Pope Pius IX"),
        ("The Rosary is a powerful weapon to put the demons to flight.", "St. Padre Pio"),
        ("Never will anyone who says his Rosary every day be led astray.", "Bl. Alan de la Roche"),
        ("The Rosary is the scourge of the devil.", "Pope Adrian VI"),
        ("Say the Rosary every day to obtain peace for the world.", "Our Lady of Fatima"),
        ("The holy Rosary is the storehouse of countless blessings.", "Bl. Alan de la Roche")
    ]

    /// Get today's quote based on day of year
    static var todaysQuote: (text: String, author: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }

    // MARK: - Private Mystery Data

    private static let joyfulMysteries: [Mystery] = [
        Mystery(
            id: 0,
            name: "The Annunciation",
            category: "joyful",
            order: 1,
            daysPrayed: "Monday, Saturday",
            description: "The Angel Gabriel announces to Mary that she is to be the Mother of God.",
            scriptureReference: "Luke 1:26-38"
        ),
        Mystery(
            id: 0,
            name: "The Visitation",
            category: "joyful",
            order: 2,
            daysPrayed: "Monday, Saturday",
            description: "Mary visits her cousin Elizabeth, who is pregnant with John the Baptist.",
            scriptureReference: "Luke 1:39-56"
        ),
        Mystery(
            id: 0,
            name: "The Nativity",
            category: "joyful",
            order: 3,
            daysPrayed: "Monday, Saturday",
            description: "Jesus is born in Bethlehem.",
            scriptureReference: "Luke 2:1-20"
        ),
        Mystery(
            id: 0,
            name: "The Presentation",
            category: "joyful",
            order: 4,
            daysPrayed: "Monday, Saturday",
            description: "Mary and Joseph present the infant Jesus in the Temple.",
            scriptureReference: "Luke 2:22-38"
        ),
        Mystery(
            id: 0,
            name: "Finding Jesus in the Temple",
            category: "joyful",
            order: 5,
            daysPrayed: "Monday, Saturday",
            description: "After three days of searching, Mary and Joseph find Jesus teaching in the Temple.",
            scriptureReference: "Luke 2:41-52"
        )
    ]

    private static let sorrowfulMysteries: [Mystery] = [
        Mystery(
            id: 0,
            name: "The Agony in the Garden",
            category: "sorrowful",
            order: 1,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus prays in the Garden of Gethsemane before His arrest.",
            scriptureReference: "Luke 22:39-46"
        ),
        Mystery(
            id: 0,
            name: "The Scourging at the Pillar",
            category: "sorrowful",
            order: 2,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus is brutally scourged by Roman soldiers.",
            scriptureReference: "John 19:1"
        ),
        Mystery(
            id: 0,
            name: "The Crowning with Thorns",
            category: "sorrowful",
            order: 3,
            daysPrayed: "Tuesday, Friday",
            description: "Soldiers place a crown of thorns on Jesus' head and mock Him.",
            scriptureReference: "Matthew 27:27-31"
        ),
        Mystery(
            id: 0,
            name: "The Carrying of the Cross",
            category: "sorrowful",
            order: 4,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus carries His cross to Calvary.",
            scriptureReference: "John 19:17"
        ),
        Mystery(
            id: 0,
            name: "The Crucifixion",
            category: "sorrowful",
            order: 5,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus dies on the cross for our salvation.",
            scriptureReference: "Luke 23:33-46"
        )
    ]

    private static let gloriousMysteries: [Mystery] = [
        Mystery(
            id: 0,
            name: "The Resurrection",
            category: "glorious",
            order: 1,
            daysPrayed: "Wednesday, Sunday",
            description: "Jesus rises from the dead on the third day.",
            scriptureReference: "Matthew 28:1-10"
        ),
        Mystery(
            id: 0,
            name: "The Ascension",
            category: "glorious",
            order: 2,
            daysPrayed: "Wednesday, Sunday",
            description: "Jesus ascends into Heaven forty days after the Resurrection.",
            scriptureReference: "Acts 1:9-11"
        ),
        Mystery(
            id: 0,
            name: "The Descent of the Holy Spirit",
            category: "glorious",
            order: 3,
            daysPrayed: "Wednesday, Sunday",
            description: "The Holy Spirit descends upon the Apostles at Pentecost.",
            scriptureReference: "Acts 2:1-4"
        ),
        Mystery(
            id: 0,
            name: "The Assumption of Mary",
            category: "glorious",
            order: 4,
            daysPrayed: "Wednesday, Sunday",
            description: "Mary is assumed body and soul into Heaven.",
            scriptureReference: "Revelation 12:1"
        ),
        Mystery(
            id: 0,
            name: "The Coronation of Mary",
            category: "glorious",
            order: 5,
            daysPrayed: "Wednesday, Sunday",
            description: "Mary is crowned Queen of Heaven and Earth.",
            scriptureReference: "Revelation 12:1"
        )
    ]

    private static let luminousMysteries: [Mystery] = [
        Mystery(
            id: 0,
            name: "The Baptism in the Jordan",
            category: "luminous",
            order: 1,
            daysPrayed: "Thursday",
            description: "Jesus is baptized by John in the Jordan River.",
            scriptureReference: "Matthew 3:13-17"
        ),
        Mystery(
            id: 0,
            name: "The Wedding at Cana",
            category: "luminous",
            order: 2,
            daysPrayed: "Thursday",
            description: "Jesus performs His first miracle, turning water into wine.",
            scriptureReference: "John 2:1-11"
        ),
        Mystery(
            id: 0,
            name: "The Proclamation of the Kingdom",
            category: "luminous",
            order: 3,
            daysPrayed: "Thursday",
            description: "Jesus proclaims the Kingdom of God and calls all to conversion.",
            scriptureReference: "Mark 1:14-15"
        ),
        Mystery(
            id: 0,
            name: "The Transfiguration",
            category: "luminous",
            order: 4,
            daysPrayed: "Thursday",
            description: "Jesus is transfigured on Mount Tabor before Peter, James, and John.",
            scriptureReference: "Matthew 17:1-8"
        ),
        Mystery(
            id: 0,
            name: "The Institution of the Eucharist",
            category: "luminous",
            order: 5,
            daysPrayed: "Thursday",
            description: "Jesus institutes the Eucharist at the Last Supper.",
            scriptureReference: "Luke 22:14-20"
        )
    ]

    private static let sevenSorrowsMysteries: [Mystery] = [
        Mystery(
            id: 0,
            name: "The Prophecy of Simeon",
            category: "seven_sorrows",
            order: 1,
            daysPrayed: "Fridays, September 15",
            description: "Simeon prophesies that a sword will pierce Mary's soul.",
            scriptureReference: "Luke 2:34-35"
        ),
        Mystery(
            id: 0,
            name: "The Flight into Egypt",
            category: "seven_sorrows",
            order: 2,
            daysPrayed: "Fridays, September 15",
            description: "The Holy Family flees to Egypt to escape King Herod's massacre.",
            scriptureReference: "Matthew 2:13-15"
        ),
        Mystery(
            id: 0,
            name: "The Loss of Jesus in the Temple",
            category: "seven_sorrows",
            order: 3,
            daysPrayed: "Fridays, September 15",
            description: "Mary and Joseph search for the child Jesus for three days.",
            scriptureReference: "Luke 2:41-50"
        ),
        Mystery(
            id: 0,
            name: "Mary Meets Jesus Carrying the Cross",
            category: "seven_sorrows",
            order: 4,
            daysPrayed: "Fridays, September 15",
            description: "Mary encounters her Son on the way to Calvary.",
            scriptureReference: "Luke 23:27-31"
        ),
        Mystery(
            id: 0,
            name: "The Crucifixion",
            category: "seven_sorrows",
            order: 5,
            daysPrayed: "Fridays, September 15",
            description: "Mary stands at the foot of the cross as Jesus dies.",
            scriptureReference: "John 19:25-27"
        ),
        Mystery(
            id: 0,
            name: "Jesus Taken Down from the Cross",
            category: "seven_sorrows",
            order: 6,
            daysPrayed: "Fridays, September 15",
            description: "Mary receives the body of her Son in her arms.",
            scriptureReference: "Matthew 27:57-59"
        ),
        Mystery(
            id: 0,
            name: "The Burial of Jesus",
            category: "seven_sorrows",
            order: 7,
            daysPrayed: "Fridays, September 15",
            description: "Mary watches as Jesus is laid in the tomb.",
            scriptureReference: "John 19:40-42"
        )
    ]
}
