//
//  RosaryForm.swift
//  Lumen Viae
//
//  One Rosary in three forms, and the rows its own page carries.
//
//  The app once looked as though it held four Rosaries — Pray with a
//  Meditation, the Scriptural Rosary, the Rosary Aloud, and an "Every
//  prayer aloud" switch that quietly made a fourth of the first. They
//  are one prayer: the same mysteries, prayed with a meditation read
//  between the decades, with a verse of Scripture on every bead, or with
//  nothing read between at all (No Meditation). The form is chosen on the
//  mysteries' page. Every form is said aloud and the beads always hang:
//  the Audio and Counting choices that once stood above PRAY went with
//  the switch (Abraham, Nov 2026: "Yes, only Rosary").
//
//  What is set — which mysteries, the voice and the prayers' speed — is a
//  row on the form's own page.
//

import Foundation

// MARK: - RosaryForm

/// Which form of the Rosary a page confirms
enum RosaryForm: Hashable {
    /// A meditation set: a meditation read before each decade
    case meditation
    /// A verse of Scripture for every bead
    case scriptural
    /// The Rosary Said Aloud (it was the Holy Rosary): every prayer
    /// said aloud, no readings between
    case holy

    init(_ spoken: SpokenForm) {
        switch spoken {
        case .scriptural: self = .scriptural
        case .plain: self = .holy
        }
    }
}

// MARK: - RosaryChoice

/// A choice set as a pill of two named options (Opening and Closing
/// Prayers, the Prayers tab's Audio). The Rosary's own two choices, Audio
/// and Counting, went with the switch (Abraham, Nov 2026: "Yes, only
/// Rosary"): every Rosary is said aloud and the beads always hang.
enum RosaryChoice {
    /// One of a choice's two options: the setting's value, and its name
    struct Option: Hashable {
        let value: Bool
        let name: String
    }
}

// MARK: - RosaryInfoRow

/// A ruled row beneath the choices: what is set, and a way to change it
enum RosaryInfoRow: Hashable {
    /// The Holy Rosary's audio, which is not a choice
    case audio
    /// Which mysteries, chosen already on the mysteries' page
    case mysteries
    /// Who reads, and how fast
    case voice

    /// The rows a form's page carries, in order, with `aloud` the Audio
    /// choice. A meditation set belongs to its mysteries, so its page has
    /// no Mysteries row. The Scriptural Rosary read in silence has no
    /// voice to choose, so no Voice & speed row either; a set's
    /// meditation is always read aloud, so its row stays.
    static func rows(for form: RosaryForm, aloud: Bool) -> [RosaryInfoRow] {
        switch form {
        case .meditation: return [.voice]
        case .scriptural: return aloud ? [.mysteries, .voice] : [.mysteries]
        case .holy: return [.audio, .mysteries, .voice]
        }
    }

    var title: String {
        switch self {
        case .audio: return String(localized: "Rosary Audio", comment: "A Rosary's own page: the name of the row saying the Audio Rosary is said aloud")
        case .mysteries:
            return String(localized: "Mysteries", comment: "A Rosary's own page: name of the row that opens the choice of mysteries")
        case .voice:
            return String(localized: "Voice & speed", comment: "A Rosary's own page: name of the row that opens the narration voice and speed")
        }
    }

    /// The Holy Rosary's audio, said as a fact rather than offered
    static let holyAudioValue = String(
        localized: "Every prayer aloud · pause anytime",
        comment: "The Audio Rosary's own page: the Audio row's value, a fact rather than a choice: every prayer is said aloud and can be paused"
    )

    /// "Joyful · today", or the mysteries' name alone on another day's
    static func mysteriesValue(_ category: MysteryCategory, today: MysteryCategory) -> String {
        category == today
            ? String(
                localized: "\(category.displayName) · today",
                comment: "A Rosary's own page: the Mysteries row's value when today's mysteries are chosen, like Joyful · today"
            )
            : category.displayName
    }

    /// "Female · 1×"
    static func voiceValue(voice: String, rate: String) -> String {
        "\(voice) · \(rate)"
    }
}
