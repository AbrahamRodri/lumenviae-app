//
//  ChapelChant.swift
//  Lumen Viae
//
//  Sung prayer, kept close to hand on the Chapel page.
//
//  The pieces are the app's own chant recordings — the three chanted
//  prayers of the consecration (Veni Creator, Ave Maris Stella, the
//  Magnificat) — reached through the same presigned-URL endpoint and
//  offline store the consecration flow uses. Nothing here is a second
//  catalog: adding a recording to the consecration adds it to the
//  Chapel's tile.
//
//  The player is the shared AudioService. The tile never owns it: a
//  Rosary that claims the player simply silences this tile's readouts,
//  which go by whether the loaded URL is still the one this tile loaded.
//

import SwiftUI

// MARK: - ChapelChantPiece

/// One chant the tile can hold: a bilingual prayer with a recording,
/// plus the one line the tile says about it.
struct ChapelChantPiece: Identifiable, Equatable {
    let prayer: BilingualConsecrationPrayer
    let detail: String

    var id: String { prayer.id }
    var latinTitle: String { prayer.latinTitle }

    /// The chant's opening words, for the sheet's epigraph.
    var firstLine: String {
        prayer.content.latin
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? prayer.englishTitle
    }

    static func == (lhs: ChapelChantPiece, rhs: ChapelChantPiece) -> Bool {
        lhs.id == rhs.id
    }

    /// Every prayer with a chant recording. The details are display
    /// copy; the recordings and texts live with the consecration.
    static let catalog: [ChapelChantPiece] = [
        ChapelChantPiece(
            prayer: BilingualConsecrationPrayers.veniCreator,
            detail: "The hymn of Pentecost"
        ),
        ChapelChantPiece(
            prayer: BilingualConsecrationPrayers.aveMaris,
            detail: "The Vespers hymn of Our Lady"
        ),
        ChapelChantPiece(
            prayer: BilingualConsecrationPrayers.magnificat,
            detail: "The Canticle of Mary"
        )
    ]

    static func piece(id: String) -> ChapelChantPiece? {
        catalog.first { $0.id == id }
    }
}

// MARK: - ChapelChantPlayer

/// The chant tile's hold on the shared player.
///
/// It remembers which URL it loaded and the load generation it loaded
/// under; everything it claims about playback is conditioned on both
/// still being the player's — so when another flow (a Rosary, a book, a
/// consecration day singing the very same recording) takes the player,
/// the tile's progress line and pause glyph quietly return to rest
/// instead of narrating someone else's audio.
///
/// It lives **above the views**, like `LibraryListeningSession`: the
/// Chapel is a tab, and `ContentView`'s tab `switch` destroys a view's
/// `@State` the moment the user looks at the Journal. A chant that kept
/// its hold in view state would go on singing with nothing in the app
/// able to pause it.
@Observable
@MainActor
final class ChapelChantPlayer {

    static let shared = ChapelChantPlayer()

    /// The piece the tile holds, remembered across launches.
    var current: ChapelChantPiece

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var loadedURL: URL?

    /// The player's load generation at the moment this chant took it.
    /// Any other flow's `loadAudio` resets the player and bumps this,
    /// which is what lets go of the claim.
    private var loadedGeneration: Int?

    private var loadCount = 0
    private var loadTask: Task<Void, Never>?

    /// Whether this player set a rate that is not the app's own, so it
    /// knows there is something to hand back — and never "restores" a
    /// rate it did not borrow.
    private var borrowedRate = false

    private let audio = AudioService.shared

    private init() {
        let storedID = UserSettings.shared.chapelChantID
        current = ChapelChantPiece.piece(id: storedID) ?? ChapelChantPiece.catalog[0]
    }

    /// Whether the player's loaded audio is still this tile's chant.
    ///
    /// The URL alone will not do: the consecration flow loads these same
    /// three files, so a tile that went by URL would claim a chant a
    /// consecration day started. The generation is what makes it an
    /// answer about ownership rather than about the file.
    var ownsPlayback: Bool {
        guard let loadedURL, let loadedGeneration else { return false }
        return audio.currentURL == loadedURL && audio.loadGeneration == loadedGeneration
    }

    var isPlaying: Bool { ownsPlayback && audio.isPlaying }

    /// 0…1 through the recording, or 0 when the player is elsewhere.
    var progress: Double {
        guard ownsPlayback, audio.duration > 0 else { return 0 }
        return min(1, audio.currentTime / audio.duration)
    }

    /// "0:55 of 4:12", once the recording is loaded and ours.
    var timeLabel: String? {
        guard ownsPlayback, audio.duration > 0 else { return nil }
        return "\(Self.clock(audio.currentTime)) of \(Self.clock(audio.duration))"
    }

    static func clock(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.down)))
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }

    func togglePlayback() {
        if ownsPlayback {
            audio.togglePlayback()
        } else {
            play(current)
        }
    }

    /// Loads and sings a piece — from the sheet's list or the tile's
    /// play button. Also makes it the tile's remembered chant.
    func play(_ piece: ChapelChantPiece) {
        current = piece
        UserSettings.shared.chapelChantID = piece.id

        loadCount += 1
        let token = loadCount
        errorMessage = nil
        isLoading = true

        // The transport as it stood when the user asked. Taking it over
        // from whatever holds it now is what they asked for; taking it
        // from something that claimed it *while they waited* is not.
        let generationAtRequest = audio.loadGeneration

        // A load already in flight is superseded, not left to finish:
        // its continuation would otherwise reach `audio.play()` after
        // the user asked for something else entirely.
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { if token == self.loadCount { self.isLoading = false } }

            // A downloaded chant plays offline and skips the presign hop
            let urlString: String
            if let local = OfflineContentService.shared.localPrayerAudioURL(prayerId: piece.id) {
                urlString = local.absoluteString
            } else {
                do {
                    urlString = try await APIService.shared.fetchPrayerAudioUrl(prayerId: piece.id)
                } catch {
                    guard token == self.loadCount, !Task.isCancelled else { return }
                    self.errorMessage = "The chant couldn't be reached."
                    return
                }
            }

            // The presign can take seconds, and the world moves while it
            // does. If the user pressed Pray in the meantime, a Rosary
            // now holds the player and is narrating; loading here would
            // tear its player down mid-sentence and sing over it. A
            // changed load generation is precisely that event.
            guard token == self.loadCount, !Task.isCancelled else { return }
            guard self.audio.loadGeneration == generationAtRequest else { return }
            guard let url = URL(string: urlString) else {
                self.errorMessage = "The chant couldn't be loaded."
                return
            }

            // Take the transport at chant's own pace. A Rosary read at
            // 2× has not thereby chosen a speed for sung Latin, so the
            // rate is borrowed rather than remembered, and handed back
            // in `relinquish()`.
            if !self.borrowedRate {
                self.audio.setPlaybackRate(1.0, remember: false)
                self.borrowedRate = true
            }

            let ready = await self.audio.loadAudio(
                from: urlString,
                title: piece.latinTitle,
                subtitle: "Chant",
                claimNowPlaying: true
            )

            guard token == self.loadCount, !Task.isCancelled else { return }

            // `loadAudio` answers false for a track already loaded whose
            // duration is still resolving — a second press on the same
            // chant, not a failure. The player having the URL is the
            // honest test of whether the load landed.
            guard ready || self.audio.currentURL == url else {
                self.errorMessage = "The chant couldn't be loaded."
                self.releaseRate()
                return
            }

            self.loadedURL = url
            self.loadedGeneration = self.audio.loadGeneration
            self.audio.play()
        }
    }

    /// Gives the player and the app's narration speed back: the chant is
    /// put away, or the page is done with it. Silent if the player has
    /// already moved on to someone else's audio.
    func relinquish() {
        loadCount += 1
        loadTask?.cancel()
        loadTask = nil
        isLoading = false

        if ownsPlayback {
            audio.reset()
            audio.deactivateSession()
        }
        loadedURL = nil
        loadedGeneration = nil
        releaseRate()
    }

    /// Hands the app-wide narration speed back, once, whether or not
    /// this player still holds the transport.
    private func releaseRate() {
        guard borrowedRate else { return }
        borrowedRate = false
        audio.restoreRememberedRate()
    }
}

// MARK: - ChapelChantSheet

/// The chant sheet: the piece by name, its opening words, a transport,
/// and the short list of every recording. One of the two surfaces on
/// the Chapel page allowed a card fill.
struct ChapelChantSheet: View {

    let player: ChapelChantPlayer

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                EditorHeader(
                    title: "Chant",
                    subtitle: "Sung prayer, kept close to hand.",
                    onDone: { dismiss() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text(player.current.latinTitle)
                            .font(AppFonts.headlineFont(21))
                            .foregroundColor(AppColors.cream)
                            .multilineTextAlignment(.center)
                            .padding(.top, 18)

                        Text(player.current.firstLine)
                            .font(AppFonts.readingItalicFont(16))
                            .foregroundColor(AppColors.cream.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        transport

                        if let error = player.errorMessage {
                            Text(error)
                                .font(AppFonts.italicFont(12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        OrnamentDivider()
                            .frame(width: 140)

                        list
                    }
                    .padding(.horizontal, 26)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: Transport

    private var transport: some View {
        VStack(spacing: 12) {
            Button(action: { player.togglePlayback() }) {
                ZStack {
                    Circle()
                        .fill(AppColors.cardBackground)
                    Circle()
                        .strokeBorder(AppColors.goldLight, lineWidth: 1)

                    if player.isLoading {
                        ProgressView()
                            .tint(AppColors.goldLight)
                    } else {
                        AppIcon(player.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: 16)
                            .foregroundColor(AppColors.goldLight)
                    }
                }
                .frame(width: 52, height: 52)
                .haloGlow(AppColors.gold, radius: 10, intensity: 0.3)
            }
            .buttonStyle(GoldCTAButtonStyle())
            .accessibilityLabel(player.isPlaying ? "Pause the chant" : "Sing the chant")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.15))
                    Rectangle()
                        .fill(AppColors.gold)
                        .frame(width: geo.size.width * player.progress)
                }
            }
            .frame(height: 1)
            .accessibilityHidden(true)

            if let time = player.timeLabel {
                Text(time)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.top, 4)
    }

    // MARK: The recordings

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(ChapelChantPiece.catalog) { piece in
                Button(action: { player.play(piece) }) {
                    HStack(spacing: 13) {
                        AppIcon("ph-music-note", size: 14)
                            .foregroundColor(
                                piece == player.current
                                    ? AppColors.goldLight
                                    : AppColors.gold.opacity(0.7)
                            )
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(piece.latinTitle)
                                .font(AppFonts.bodyFont(15))
                                .foregroundColor(AppColors.cream)

                            Text(piece.detail)
                                .font(AppFonts.bodyFont(11.5))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        if piece == player.current, player.isPlaying {
                            AppIcon("ph-speaker-high", size: 13)
                                .foregroundColor(AppColors.goldLight)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sing \(piece.latinTitle). \(piece.detail)")
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
        )
    }
}
