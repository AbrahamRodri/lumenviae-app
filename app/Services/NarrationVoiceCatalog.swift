//
//  NarrationVoiceCatalog.swift
//  Lumen Viae
//
//  The voices a meditation can be heard in, and which one this person
//  has chosen.
//
//  The list comes from GET /api/voices and is kept in UserDefaults so the
//  picker is whole offline and on first launch; until the first fetch
//  lands it is the built-in pair the server ships with. The choice itself
//  lives in UserSettings as a slug; this resolves it against the list, so
//  a voice the server has since withdrawn falls back to the default
//  rather than to silence.
//

import Foundation

@Observable
final class NarrationVoiceCatalog {

    static let shared = NarrationVoiceCatalog()

    /// Every voice the server offers, default first.
    private(set) var voices: [NarrationVoice]

    private static let storageKey = "narrationVoiceCatalog.voices"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([NarrationVoice].self, from: data),
           !stored.isEmpty {
            voices = stored
        } else {
            voices = NarrationVoice.builtIn
        }
    }

    // MARK: - The Choice

    /// The server's default voice.
    var defaultVoice: NarrationVoice {
        voices.first { $0.isDefault } ?? voices[0]
    }

    /// The voice this person hears: their choice when the server still
    /// offers it, the default otherwise.
    var chosenVoice: NarrationVoice {
        guard let slug = UserSettings.shared.narrationVoiceSlug,
              let voice = voices.first(where: { $0.slug == slug }) else {
            return defaultVoice
        }
        return voice
    }

    /// The slug of `chosenVoice` - what is sent as `?voice=`, looked up on
    /// a meditation's narrations, and written into offline file names.
    var chosenSlug: String { chosenVoice.slug }

    /// Makes `voice` the one this person hears.
    func choose(_ voice: NarrationVoice) {
        UserSettings.shared.narrationVoiceSlug = voice.slug
    }

    // MARK: - Refresh

    /// Asks the server for the current list. Quiet on failure: whatever
    /// was stored is still the best list there is, and this is called
    /// from places that would not know what to do with an error anyway.
    func refresh() async {
        guard let fresh = try? await APIService.shared.fetchVoices(), !fresh.isEmpty else { return }
        voices = fresh
        if let data = try? JSONEncoder().encode(fresh) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
