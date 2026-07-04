//
//  MockDataService.swift
//  Lumen Viae
//
//  Mock meditation content for previews and offline fallback.
//  Mystery data itself comes from MysteryData.
//

import Foundation

struct MockDataService {

    // MARK: - Meditation Sets

    /// A full meditation set built from local mystery data, used as an
    /// offline fallback and in previews.
    static func meditationSet(for category: MysteryCategory, includeAudio: Bool = false) -> MeditationSet {
        let meditations = MysteryData.mysteries(for: category).map { mystery in
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
            labels: nil,
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

    /// Today's quote based on day of year
    static var todaysQuote: (text: String, author: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return quotes[dayOfYear % quotes.count]
    }
}
