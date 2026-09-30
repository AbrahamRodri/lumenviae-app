//
//  RosaryForm.swift
//  Lumen Viae
//
//  One Rosary in three forms, and the two choices that change how it is
//  prayed.
//
//  The app once looked as though it held four Rosaries — Pray with a
//  Meditation, the Scriptural Rosary, the Rosary Aloud, and an "Every
//  prayer aloud" switch that quietly made a fourth of the first. They
//  are one prayer: the same mysteries, prayed with a meditation read
//  between the decades, with a verse of Scripture on every bead, or with
//  nothing read between at all. The form is chosen on the mysteries'
//  page; what changes the prayer beyond that is two choices, confirmed
//  on the form's own page just above PRAY:
//
//  Audio — whether the voice reads only the meditation (Meditation Only;
//  in the Scriptural Rosary, Read in Silence) or says every prayer
//  (Whole Rosary). The setting is `UserSettings.prayAloud`.
//
//  Counting — whether the beads are on the screen (On the Screen) or in
//  the hand (On My Rosary). The setting is `UserSettings.prayOnBeads`.
//  Offered only while the voice reads the meditation alone: when it says
//  every prayer, it moves the beads on the screen itself.
//
//  Everything else — the voice, its speed, which mysteries — is a row
//  beneath the choices. The words for every choice live here, once, so
//  the pages, the player's sheet, Settings and onboarding say the same
//  thing.
//

import Foundation

// MARK: - RosaryForm

/// Which form of the Rosary a page confirms
enum RosaryForm: Hashable {
    /// A meditation set: a meditation read before each decade
    case meditation
    /// A verse of Scripture for every bead
    case scriptural
    /// The Holy Rosary: every prayer said aloud, nothing read between
    case holy

    init(_ spoken: SpokenForm) {
        switch spoken {
        case .scriptural: self = .scriptural
        case .plain: self = .holy
        }
    }

    /// Whether every prayer is said aloud: always in the Holy Rosary,
    /// otherwise as the Audio choice says
    func praysAloud(setting: Bool) -> Bool {
        self == .holy || setting
    }

    /// Whether the beads are counted on the screen. When the voice says
    /// every prayer it moves them there itself, so the Counting choice
    /// only holds while it reads the meditation alone.
    func countsOnScreen(aloud: Bool, onBeads: Bool) -> Bool {
        praysAloud(setting: aloud) || onBeads
    }
}

// MARK: - RosaryChoice

/// One of the two choices that change how the Rosary is prayed
enum RosaryChoice: Hashable, CaseIterable {
    /// `UserSettings.prayAloud`: the meditation alone, or every prayer
    case audio
    /// `UserSettings.prayOnBeads`: on your own rosary, or on the screen
    case counting

    /// One of a choice's two options: the setting's value, and its name
    struct Option: Hashable {
        let value: Bool
        let name: String
    }

    var title: String {
        switch self {
        case .audio: return "Audio"
        case .counting: return "Counting"
        }
    }

    var icon: String {
        switch self {
        case .audio: return "ph-speaker-high"
        case .counting: return "lv-rosary"
        }
    }

    /// The two options in the order they are set side by side — the
    /// quieter way first, as the setting's `false`
    func options(for form: RosaryForm) -> [Option] {
        [Option(value: false, name: name(of: false, for: form)),
         Option(value: true, name: name(of: true, for: form))]
    }

    /// What an option is called. In the Scriptural Rosary there is no
    /// meditation, so the quieter way is named for what is left: the
    /// verses read in silence.
    func name(of value: Bool, for form: RosaryForm = .meditation) -> String {
        switch self {
        case .audio:
            if value { return "Whole Rosary" }
            return form == .scriptural ? "Read in Silence" : "Meditation Only"
        case .counting:
            return value ? "On the Screen" : "On My Rosary"
        }
    }

    /// What the chosen option does, said as what is heard or seen
    func note(for value: Bool, form: RosaryForm = .meditation) -> String {
        switch (self, form == .scriptural) {
        case (.audio, false):
            return value
                ? "Every prayer is said aloud. Answer along."
                : "The meditation is read aloud. You say the prayers."
        case (.audio, true):
            return value
                ? "Every verse and prayer is said aloud."
                : "The verses stand on the beads; you read and pray in silence."
        case (.counting, _):
            return value
                ? "The beads are on the screen. Swipe for each Hail Mary."
                : "Count on your own rosary. The screen moves a mystery at a time."
        }
    }

    /// The choices a page offers for a form. The Holy Rosary is always
    /// said aloud and its beads always move with the voice, so it offers
    /// neither; with Whole Rosary chosen, Counting falls away for the
    /// same reason.
    static func offered(for form: RosaryForm, aloud: Bool) -> [RosaryChoice] {
        switch form {
        case .holy:
            return []
        case .meditation, .scriptural:
            return aloud ? [.audio] : [.audio, .counting]
        }
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
        case .audio: return RosaryChoice.audio.title
        case .mysteries: return "Mysteries"
        case .voice: return "Voice & speed"
        }
    }

    /// The Holy Rosary's audio, said as a fact rather than offered
    static let holyAudioValue = "Whole Rosary · pause anytime"

    /// "Joyful · today", or the mysteries' name alone on another day's
    static func mysteriesValue(_ category: MysteryCategory, today: MysteryCategory) -> String {
        category == today ? "\(category.displayName) · today" : category.displayName
    }

    /// "Female · 1×"
    static func voiceValue(voice: String, rate: String) -> String {
        "\(voice) · \(rate)"
    }
}
