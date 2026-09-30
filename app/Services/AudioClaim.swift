//
//  AudioClaim.swift
//  Lumen Viae
//
//  Ownership of the shared player, as one object.
//
//  Several flows sound through `AudioService` — the Chant Library, a
//  consecration day, the Rosary, the reading shelf, the Prayer Book — and
//  each used to decide for itself whether the player was still its own,
//  from as many as three signals: the file it loaded, the load generation
//  it loaded under, and whether it still held the Lock Screen arrows. The
//  service never told a flow it had been displaced; flows found out when
//  they next looked. Two flows sounding the same recording (the library's
//  Veni Creator and a consecration day's) could both believe they held it,
//  and closing one silenced the other.
//
//  A claim is ownership. `AudioService.claim(_:rate:ifIdle:onRevoked:)`
//  gives one out and ends the claim before it, with notice. A flow loads,
//  plays and reads the player through its claim; once the claim has ended
//  every act is a no-op and every readout is at rest, so a surface never
//  narrates or drives someone else's audio. The speed a flow borrows is
//  part of its claim and comes back when the claim ends, however it ends.
//  End-of-track goes to the claim whose load put the item in the player.
//

import Foundation

// MARK: - AudioOwnerKind

/// Which flow holds a claim
enum AudioOwnerKind {
    case prayerFlow
    case spokenRosary
    case chant
    case library
    case prayerBook
    case consecration
}

// MARK: - AudioRatePolicy

/// The speed a claim plays at
enum AudioRatePolicy: Equatable {
    /// The app's narration speed, which the claim's speed changes set
    case app
    /// A speed of its own — a chant slowed to be learned, a book's reader —
    /// and the app's comes back when the claim ends
    case borrowed(Double)
}

// MARK: - AudioNavigation

/// The Lock Screen's and the headphones' next and previous, for a claim
struct AudioNavigation {
    var canGoNext: Bool
    var canGoPrevious: Bool
    var onNext: () -> Void
    var onPrevious: () -> Void
}

// MARK: - AudioClaim

final class AudioClaim {

    let kind: AudioOwnerKind

    /// Unique for the life of the service, so an item can name the claim
    /// that loaded it without holding on to it
    let serial: Int

    /// The name the older surface knows this claim by, as the owner of the
    /// Lock Screen arrows and the borrower of the speed
    let token: AnyHashable = UUID()

    /// The speed this claim plays at. Changed through `setRate`.
    var ratePolicy: AudioRatePolicy

    private weak var service: AudioService?

    /// Called once, when another flow's claim or load ends this one
    let onRevoked: () -> Void

    init(
        service: AudioService,
        serial: Int,
        kind: AudioOwnerKind,
        ratePolicy: AudioRatePolicy,
        onRevoked: @escaping () -> Void
    ) {
        self.service = service
        self.serial = serial
        self.kind = kind
        self.ratePolicy = ratePolicy
        self.onRevoked = onRevoked
    }

    // MARK: - Ownership

    /// Whether this claim holds the player — the one ownership test
    var isCurrent: Bool { service?.holder === self }

    /// Whether this claim holds the player and the item in it is the one
    /// it loaded
    var holdsItem: Bool { service?.holdsItem(self) ?? false }

    // MARK: - Readouts (at rest once the item is not this claim's)

    var isPlaying: Bool { holdsItem && (service?.isPlaying ?? false) }

    var currentTime: Double { holdsItem ? (service?.currentTime ?? 0) : 0 }

    var duration: Double { holdsItem ? (service?.duration ?? 0) : 0 }

    var errorMessage: String? { holdsItem ? service?.errorMessage : nil }

    // MARK: - Transport (no-ops once the item is not this claim's)

    /// Loads a recording into the player for this claim. False when it
    /// could not be had, or when the claim ended while it was arriving.
    @discardableResult
    func load(
        _ url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        artworkAssetName: String? = nil,
        album: String? = nil,
        queueIndex: Int? = nil,
        queueCount: Int? = nil,
        claimNowPlaying: Bool = false,
        startAt: Double = 0
    ) async -> Bool {
        guard let service else { return false }
        return await service.load(
            for: self,
            url: url,
            title: title,
            subtitle: subtitle,
            artworkAssetName: artworkAssetName,
            album: album,
            queueIndex: queueIndex,
            queueCount: queueCount,
            claimNowPlaying: claimNowPlaying,
            startAt: startAt
        )
    }

    func play() {
        guard holdsItem else { return }
        service?.play()
    }

    func pause() {
        guard holdsItem else { return }
        service?.pause()
    }

    func togglePlayback() {
        guard holdsItem else { return }
        service?.togglePlayback()
    }

    func seek(to time: Double) {
        guard holdsItem else { return }
        service?.seek(to: time)
    }

    /// Takes the item this claim loaded out of the player — between the
    /// steps of a flow, where the next load follows. The Lock Screen
    /// player is kept unless asked otherwise.
    func unload(preservingNowPlaying: Bool = true) {
        guard holdsItem else { return }
        service?.reset(preservingNowPlaying: preservingNowPlaying)
    }

    /// The claim's speed: a borrowed one at a new pace, or the app's own
    func setRate(_ rate: Double) {
        service?.setRate(rate, for: self)
    }

    // MARK: - Lock Screen and events

    /// Next and previous on the Lock Screen and the headphones, while the
    /// claim holds the player. Nil takes them off.
    var navigation: AudioNavigation? {
        didSet { service?.installNavigation(for: self) }
    }

    /// Play and pause from outside the screen, for a flow that keeps a
    /// transport of its own above the player's
    var onTransport: ((AudioService.TransportRequest) -> Void)? {
        didSet { service?.installNavigation(for: self) }
    }

    /// The item this claim loaded played to its end
    var onFinish: (() -> Void)?

    /// The item this claim loaded stopped part-way and cannot go on
    var onFail: (() -> Void)?

    // MARK: - Release

    /// Ends the claim at the flow's own hand: its item stopped and the
    /// audio session given back, its arrows off, the app's speed back.
    /// Safe to call twice, and after the claim was ended by another flow.
    func release() {
        service?.release(self)
    }
}
