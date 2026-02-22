//
//  MysteryData.swift
//  Lumen Viae
//
//  Static mystery data - these never change, so no API call needed.
//

import Foundation

/// Local data source for all Rosary mysteries including the Seven Sorrows.
///
/// The mystery names, scripture references, and descriptions are unchanging
/// Catholic tradition. Storing them locally provides instant access without
/// network latency.
enum MysteryData {

    // MARK: - All Mysteries

    /// All mysteries organized by category
    static let all: [MysteryCategory: [Mystery]] = [
        .joyful: joyful,
        .sorrowful: sorrowful,
        .glorious: glorious,
        .luminous: luminous,
        .sevenSorrows: sevenSorrows
    ]

    /// Get mysteries for a specific category
    static func mysteries(for category: MysteryCategory) -> [Mystery] {
        all[category] ?? []
    }

    // MARK: - Joyful Mysteries

    static let joyful: [Mystery] = [
        Mystery(
            id: 1,
            name: "The Annunciation",
            category: "joyful",
            order: 1,
            daysPrayed: "Monday, Saturday",
            description: "The Angel Gabriel announces to Mary that she will conceive and bear the Son of God.",
            scriptureReference: "Luke 1:26-38"
        ),
        Mystery(
            id: 2,
            name: "The Visitation",
            category: "joyful",
            order: 2,
            daysPrayed: "Monday, Saturday",
            description: "Mary visits her cousin Elizabeth, who is pregnant with John the Baptist.",
            scriptureReference: "Luke 1:39-56"
        ),
        Mystery(
            id: 3,
            name: "The Nativity",
            category: "joyful",
            order: 3,
            daysPrayed: "Monday, Saturday",
            description: "Jesus is born in Bethlehem and laid in a manger.",
            scriptureReference: "Luke 2:1-20"
        ),
        Mystery(
            id: 4,
            name: "The Presentation",
            category: "joyful",
            order: 4,
            daysPrayed: "Monday, Saturday",
            description: "Mary and Joseph present the infant Jesus in the Temple.",
            scriptureReference: "Luke 2:22-38"
        ),
        Mystery(
            id: 5,
            name: "The Finding in the Temple",
            category: "joyful",
            order: 5,
            daysPrayed: "Monday, Saturday",
            description: "The child Jesus is found teaching in the Temple after three days.",
            scriptureReference: "Luke 2:41-52"
        )
    ]

    // MARK: - Sorrowful Mysteries

    static let sorrowful: [Mystery] = [
        Mystery(
            id: 6,
            name: "The Agony in the Garden",
            category: "sorrowful",
            order: 1,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus prays in the Garden of Gethsemane, sweating blood in anguish.",
            scriptureReference: "Matthew 26:36-46"
        ),
        Mystery(
            id: 7,
            name: "The Scourging at the Pillar",
            category: "sorrowful",
            order: 2,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus is bound to a pillar and scourged by Roman soldiers.",
            scriptureReference: "John 19:1"
        ),
        Mystery(
            id: 8,
            name: "The Crowning with Thorns",
            category: "sorrowful",
            order: 3,
            daysPrayed: "Tuesday, Friday",
            description: "Soldiers place a crown of thorns on Jesus' head and mock Him.",
            scriptureReference: "Matthew 27:27-31"
        ),
        Mystery(
            id: 9,
            name: "The Carrying of the Cross",
            category: "sorrowful",
            order: 4,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus carries His cross to Calvary, falling three times.",
            scriptureReference: "John 19:17"
        ),
        Mystery(
            id: 10,
            name: "The Crucifixion",
            category: "sorrowful",
            order: 5,
            daysPrayed: "Tuesday, Friday",
            description: "Jesus is nailed to the cross and dies for the salvation of mankind.",
            scriptureReference: "John 19:18-30"
        )
    ]

    // MARK: - Glorious Mysteries

    static let glorious: [Mystery] = [
        Mystery(
            id: 11,
            name: "The Resurrection",
            category: "glorious",
            order: 1,
            daysPrayed: "Wednesday, Sunday",
            description: "Jesus rises from the dead on the third day.",
            scriptureReference: "Mark 16:1-8"
        ),
        Mystery(
            id: 12,
            name: "The Ascension",
            category: "glorious",
            order: 2,
            daysPrayed: "Wednesday, Sunday",
            description: "Jesus ascends into Heaven forty days after His Resurrection.",
            scriptureReference: "Acts 1:9-11"
        ),
        Mystery(
            id: 13,
            name: "The Descent of the Holy Spirit",
            category: "glorious",
            order: 3,
            daysPrayed: "Wednesday, Sunday",
            description: "The Holy Spirit descends upon the Apostles at Pentecost.",
            scriptureReference: "Acts 2:1-4"
        ),
        Mystery(
            id: 14,
            name: "The Assumption",
            category: "glorious",
            order: 4,
            daysPrayed: "Wednesday, Sunday",
            description: "Mary is assumed body and soul into Heaven.",
            scriptureReference: "Revelation 12:1"
        ),
        Mystery(
            id: 15,
            name: "The Coronation",
            category: "glorious",
            order: 5,
            daysPrayed: "Wednesday, Sunday",
            description: "Mary is crowned Queen of Heaven and Earth.",
            scriptureReference: "Revelation 12:1"
        )
    ]

    // MARK: - Luminous Mysteries

    static let luminous: [Mystery] = [
        Mystery(
            id: 16,
            name: "The Baptism in the Jordan",
            category: "luminous",
            order: 1,
            daysPrayed: "Thursday",
            description: "Jesus is baptized by John in the Jordan River.",
            scriptureReference: "Matthew 3:13-17"
        ),
        Mystery(
            id: 17,
            name: "The Wedding at Cana",
            category: "luminous",
            order: 2,
            daysPrayed: "Thursday",
            description: "Jesus performs His first miracle, turning water into wine.",
            scriptureReference: "John 2:1-11"
        ),
        Mystery(
            id: 18,
            name: "The Proclamation of the Kingdom",
            category: "luminous",
            order: 3,
            daysPrayed: "Thursday",
            description: "Jesus proclaims the Kingdom of God and calls all to conversion.",
            scriptureReference: "Mark 1:14-15"
        ),
        Mystery(
            id: 19,
            name: "The Transfiguration",
            category: "luminous",
            order: 4,
            daysPrayed: "Thursday",
            description: "Jesus is transfigured on Mount Tabor, revealing His divine glory.",
            scriptureReference: "Matthew 17:1-8"
        ),
        Mystery(
            id: 20,
            name: "The Institution of the Eucharist",
            category: "luminous",
            order: 5,
            daysPrayed: "Thursday",
            description: "Jesus institutes the Eucharist at the Last Supper.",
            scriptureReference: "Matthew 26:26-28"
        )
    ]

    // MARK: - Seven Sorrows of Mary

    static let sevenSorrows: [Mystery] = [
        Mystery(
            id: 21,
            name: "The Prophecy of Simeon",
            category: "seven_sorrows",
            order: 1,
            daysPrayed: "Fridays, September 15",
            description: "Simeon prophesies that a sword will pierce Mary's soul.",
            scriptureReference: "Luke 2:34-35"
        ),
        Mystery(
            id: 22,
            name: "The Flight into Egypt",
            category: "seven_sorrows",
            order: 2,
            daysPrayed: "Fridays, September 15",
            description: "The Holy Family flees to Egypt to escape King Herod's massacre.",
            scriptureReference: "Matthew 2:13-15"
        ),
        Mystery(
            id: 23,
            name: "The Loss of Jesus in the Temple",
            category: "seven_sorrows",
            order: 3,
            daysPrayed: "Fridays, September 15",
            description: "Mary and Joseph search for the child Jesus for three days.",
            scriptureReference: "Luke 2:41-50"
        ),
        Mystery(
            id: 24,
            name: "Mary Meets Jesus Carrying the Cross",
            category: "seven_sorrows",
            order: 4,
            daysPrayed: "Fridays, September 15",
            description: "Mary encounters her Son on the way to Calvary.",
            scriptureReference: "Luke 23:27-31"
        ),
        Mystery(
            id: 25,
            name: "The Crucifixion",
            category: "seven_sorrows",
            order: 5,
            daysPrayed: "Fridays, September 15",
            description: "Mary stands at the foot of the cross as Jesus dies.",
            scriptureReference: "John 19:25-27"
        ),
        Mystery(
            id: 26,
            name: "Jesus Taken Down from the Cross",
            category: "seven_sorrows",
            order: 6,
            daysPrayed: "Fridays, September 15",
            description: "Mary receives the body of her Son in her arms.",
            scriptureReference: "Matthew 27:57-59"
        ),
        Mystery(
            id: 27,
            name: "The Burial of Jesus",
            category: "seven_sorrows",
            order: 7,
            daysPrayed: "Fridays, September 15",
            description: "Mary watches as Jesus is laid in the tomb.",
            scriptureReference: "John 19:40-42"
        )
    ]
}
