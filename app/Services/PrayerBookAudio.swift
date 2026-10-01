//
//  PrayerBookAudio.swift
//  Lumen Viae
//
//  The Prayer Book said aloud: each prayer recorded by the server in
//  every narration voice (LumenViae.Rosary.PrayerAudio's `book` kind,
//  recorded with ElevenLabs), fetched and kept on the device by the same
//  pack as the spoken Rosary. A prayer the Rosary also says — the Our
//  Father, the Memorare — is the Rosary's recording, made once.
//
//  `PrayAlongVoice` is one pray-along screen's hold on the shared
//  player: it asks the pack for the recordings a run of prayers needs,
//  plays one prayer at a time, and hears when each ends, so the screen
//  can turn to the next. It owns the Lock Screen's arrows while it
//  plays, and gives them back when the screen goes.
//

import Foundation
import AVFoundation

@MainActor
@Observable
final class PrayAlongVoice {

    enum State: Equatable {
        /// Nothing asked for yet
        case idle
        /// Fetching the recordings: done of total
        case preparing(Int, Int)
        /// At least one prayer can be said aloud
        case ready
        /// None can: offline and never downloaded, or not recorded yet
        case unavailable(String)
    }

    private(set) var state: State = .idle

    /// Prayer id → the recording on disk
    private(set) var files: [String: URL] = [:]

    /// Whether the voice is sounding right now
    var isPlaying: Bool { AudioService.shared.isPlaying && ownsPlayer }

    /// The prayer whose recording is loaded
    private(set) var currentPrayerID: String?

    /// Heard when the loaded prayer's recording plays to its end
    var onFinish: (() -> Void)?
    /// The Lock Screen's and headphones' arrows
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?

    private let owner = UUID()
    private var loadedGeneration: Int?

    /// The Rosary's prayers are served as `prayers`, recorded once for
    /// the Rosary and the book alike
    private static let rosaryPrayerIDs = Set(RosaryPrayers.all.map(\.id))

    static func clipID(for prayerID: String) -> RosaryAudioPack.ClipID {
        rosaryPrayerIDs.contains(prayerID) ? .prayer(prayerID) : .book(prayerID)
    }

    // MARK: - Preparing

    /// Fetches (or finds on disk) the recordings of `prayers` in the
    /// chosen narration voice.
    func prepare(_ prayers: [BookPrayer]) async {
        guard !prayers.isEmpty else { return }
        state = .preparing(0, 0)
        let clips = Set(prayers.map { Self.clipID(for: $0.id) })
        do {
            let result = try await RosaryAudioPack.shared.prepare(
                voice: NarrationVoiceCatalog.shared.chosenSlug,
                clips: clips
            ) { [weak self] done, total in
                Task { @MainActor in
                    guard let self, case .preparing = self.state else { return }
                    self.state = .preparing(done, total)
                }
            }
            var found: [String: URL] = [:]
            for prayer in prayers {
                if let url = result.files[Self.clipID(for: prayer.id)] { found[prayer.id] = url }
            }

            // A prayer not yet recorded in the chosen voice is said in the
            // default voice, as a meditation is, rather than in silence
            let missing = prayers.filter { found[$0.id] == nil }
            let fallback = NarrationVoiceCatalog.shared.defaultVoice.slug
            if !missing.isEmpty, result.voice != fallback,
               let second = try? await RosaryAudioPack.shared.prepare(
                   voice: fallback,
                   clips: Set(missing.map { Self.clipID(for: $0.id) })
               ) {
                for prayer in missing {
                    if let url = second.files[Self.clipID(for: prayer.id)] { found[prayer.id] = url }
                }
            }

            files = found
            if found.isEmpty {
                state = .unavailable(result.offline
                    ? SpokenRosaryPlayer.Failure.offline.message
                    : "These prayers aren't recorded in this voice yet.")
            } else {
                state = .ready
            }
        } catch {
            files = [:]
            state = .unavailable(SpokenRosaryPlayer.Failure.offline.message)
        }
    }

    func hasRecording(_ prayerID: String) -> Bool {
        files[prayerID] != nil
    }

    // MARK: - Playing

    /// Loads and plays one prayer's recording. False when it has none or
    /// it would not load — the screen then stays on the page, silent.
    @discardableResult
    func play(
        _ prayer: BookPrayer,
        in title: String,
        index: Int,
        of count: Int
    ) async -> Bool {
        guard let url = files[prayer.id] else { return false }
        let audio = AudioService.shared

        audio.setTrackNavigation(
            owner: owner,
            canGoNext: index < count - 1,
            canGoPrevious: index > 0,
            onNext: { [weak self] in self?.onNext?() },
            onPrevious: { [weak self] in self?.onPrevious?() },
            onFinish: { [weak self] in self?.onFinish?() }
        )

        currentPrayerID = prayer.id
        let ready = await audio.loadAudio(
            from: url.absoluteString,
            title: prayer.title,
            subtitle: title,
            album: "Prayers",
            queueIndex: index,
            queueCount: count,
            claimNowPlaying: true
        )
        guard ready, currentPrayerID == prayer.id else { return false }
        loadedGeneration = audio.loadGeneration
        audio.play()
        return true
    }

    /// Whether the shared player still holds this screen's recording —
    /// a Rosary or a chant that claims it silences the readouts here
    var ownsPlayer: Bool {
        guard let loadedGeneration else { return false }
        return AudioService.shared.loadGeneration == loadedGeneration
            && AudioService.shared.isTrackNavigationOwner(owner)
    }

    /// How far through the loaded prayer the voice is, 0…1
    var progress: Double {
        guard ownsPlayer else { return 0 }
        let audio = AudioService.shared
        guard audio.duration > 0 else { return 0 }
        return min(max(audio.currentTime / audio.duration, 0), 1)
    }

    func pause() {
        guard ownsPlayer else { return }
        AudioService.shared.pause()
    }

    func resume() {
        guard ownsPlayer else { return }
        AudioService.shared.play()
    }

    /// Lets the player go: paused, and the arrows handed back
    func stop() {
        if ownsPlayer { AudioService.shared.pause() }
        AudioService.shared.clearTrackNavigation(owner: owner)
        loadedGeneration = nil
        currentPrayerID = nil
    }
}

// MARK: - The Angelus Bell

/// The church bell, struck when the Angelus is prayed: once as it
/// begins, the way a parish bell calls the Angelus, and again at its
/// end. A short sound laid over whatever else is playing, never taking
/// the player.
@MainActor
final class AngelusBellSound {

    static let shared = AngelusBellSound()

    private var player: AVAudioPlayer?

    func ring() {
        guard let url = Bundle.main.url(forResource: "church_bell", withExtension: "caf") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.55
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            self.player = nil
        }
    }

    func silence() {
        player?.setVolume(0, fadeDuration: 0.6)
    }
}
