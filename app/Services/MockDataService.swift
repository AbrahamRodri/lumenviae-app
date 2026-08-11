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
    ///
    /// Meditation IDs are distinct negatives: id 0 for every row would
    /// break `Identifiable` (ForEach drops duplicates) and alias every
    /// mystery to the same downloaded audio file (`meditation_0.mp3`).
    static func meditationSet(for category: MysteryCategory, includeAudio: Bool = false) -> MeditationSet {
        let meditations = MysteryData.mysteries(for: category).enumerated().map { index, mystery in
            Meditation(
                id: -(1000 + index),
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

}
