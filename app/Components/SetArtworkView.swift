//
//  SetArtworkView.swift
//  Lumen Viae
//
//  The painting for a meditation set, wherever a set is drawn.
//
//  The fallback chain for a set drawn on its own: the set's painting from
//  the API, cropped around the focal point a curator chose → the
//  category's bundled painting around its own focal point. Per-meditation
//  artwork, when it arrives, slots in ahead of the set's; the view's
//  callers never learn which link answered. This view is reserved for the
//  meditation-set preview; the prayer flow always uses each mystery's own
//  bundled painting — see `PrayerPainting`.
//
//  While the set's painting is on its way the plate is the card fill, and
//  the painting fades in — never the category's painting first, which
//  would swap one picture for another under the reader's eye. If the
//  bytes never come, the category's painting takes the plate.
//

import SwiftUI
import UIKit

struct SetArtworkView: View {

    let setId: Int

    /// The set's painting, or nil for a set that has none
    let artwork: SetArtwork?

    /// What the chain ends on when the set's painting isn't there
    let fallback: Fallback

    /// Where the chain ends. A set on its own page ends on the devotion's
    /// painting, so the plate is never empty. A shelf of sets ends on
    /// nothing: the same category painting repeated down every tile that
    /// lacks its own would say nothing about any of them.
    enum Fallback {
        case categoryPainting(MysteryCategory?)
        case nothing
    }

    @State private var loaded: UIImage?
    /// The URL `loaded` belongs to. SwiftUI can preserve this view's state
    /// while a reused shelf cell receives a different set, so the image and
    /// its identity must move together.
    @State private var loadedURL: String?
    @State private var failed = false

    init(setId: Int, artwork: SetArtwork?, category: MysteryCategory?) {
        self.init(setId: setId, artwork: artwork, fallback: .categoryPainting(category))
    }

    init(setId: Int, artwork: SetArtwork?, fallback: Fallback) {
        self.setId = setId
        self.artwork = artwork
        self.fallback = fallback
        // A revisited page finds its plate already decoded and shows it on
        // the first frame rather than after a fade.
        let cached = artwork.flatMap { ArtworkCache.shared.cached($0.url) }
        _loaded = State(initialValue: cached)
        _loadedURL = State(initialValue: cached == nil ? nil : artwork?.url)
    }

    var body: some View {
        ZStack {
            if let artwork, !failed {
                AppColors.cardBackground

                if let loaded, loadedURL == artwork.url {
                    FocalFill(uiImage: loaded, focal: artwork.focalPoint)
                        .transition(.opacity)
                }
            } else {
                switch fallback {
                case .categoryPainting(let category):
                    categoryPainting(for: category)
                case .nothing:
                    Color.clear
                }
            }
        }
        .animation(.easeOut(duration: 0.35), value: loaded != nil)
        .task(id: artwork?.url) {
            guard let artwork else {
                loaded = nil
                loadedURL = nil
                failed = false
                return
            }

            if loadedURL == artwork.url, loaded != nil { return }

            // Do not leave the previous set's painting in a cell SwiftUI
            // has reused while the new painting is being resolved.
            loaded = ArtworkCache.shared.cached(artwork.url)
            loadedURL = loaded == nil ? nil : artwork.url
            failed = false
            if loaded != nil { return }

            let image = await ArtworkCache.shared.image(for: artwork, setId: setId)
            guard !Task.isCancelled else { return }
            if let image {
                loaded = image
                loadedURL = artwork.url
            } else {
                failed = true
            }
        }
        .accessibilityHidden(accessibilityText == nil)
        .accessibilityLabel(accessibilityText ?? "")
    }

    /// The bundled painting for the devotion — the end of the chain
    private func categoryPainting(for category: MysteryCategory?) -> some View {
        let fallback = category ?? .joyful
        return CachedAssetImage(fallback.cardImageName, focal: fallback.cardFocalPoint)
    }

    /// The curator's description of the set's painting, once it is the
    /// painting on screen. The bundled fallbacks are decorative and stay
    /// hidden from VoiceOver, as they always were.
    private var accessibilityText: String? {
        guard let artwork, !failed, loaded != nil, loadedURL == artwork.url else { return nil }
        guard let alt = artwork.alt, !alt.isEmpty else { return nil }
        return alt
    }
}

// MARK: - Focal Point

extension SetArtwork {

    /// The focal point as SwiftUI reads it. The model keeps plain doubles
    /// so offline reads decode off the main actor; the conversion is made
    /// here, on the view side, and the server's values are clamped to the
    /// canvas in case a hand-edited row ever strays outside it.
    var focalPoint: UnitPoint {
        UnitPoint(x: min(max(focalX, 0), 1), y: min(max(focalY, 0), 1))
    }
}

// MARK: - Previews

#Preview("No painting — category fallback") {
    SetArtworkView(setId: 27, artwork: nil, category: .sorrowful)
        .frame(width: 260, height: 317)
        .clipShape(GothicArchShape(riseRatio: 0.34))
        .padding()
        .background(AppColors.background)
}

#Preview("Unreachable painting — falls back") {
    SetArtworkView(
        setId: 27,
        artwork: SetArtwork(
            url: "https://example.invalid/sets/27/nope.jpg",
            focalX: 0.5, focalY: 0.24, width: 1600, height: 2400,
            alt: "Christ falls beneath the cross.", attribution: nil
        ),
        category: .sevenSorrows
    )
    .frame(width: 260, height: 317)
    .clipShape(GothicArchShape(riseRatio: 0.34))
    .padding()
    .background(AppColors.background)
}
