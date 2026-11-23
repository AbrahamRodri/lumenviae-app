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
    /// painting, so the plate is never empty. A shelf of sets ends there
    /// too, and stands it under a painting still on its way, so a set
    /// with no picture, or one offline on a fresh install, is never a bare
    /// dark card and the real painting fades in over it (design's offline
    /// set card, Abraham's "Looks right", 23 Nov 2026). `nothing` is kept
    /// for a plate that must stay empty.
    enum Fallback {
        case categoryPainting(MysteryCategory?)
        case categoryPaintingWhileLoading(MysteryCategory?)
        case nothing
    }

    @State private var loaded: UIImage?
    /// The URL `loaded` belongs to. SwiftUI can preserve this view's state
    /// while a reused shelf cell receives a different set, so the image and
    /// its identity must move together.
    @State private var loadedURL: String?
    @State private var failed = false
    /// The plate's size in points, which decides the copy of the painting
    /// fetched (a smaller one where the API lists it). Zero until
    /// measured, when nothing is fetched yet.
    @State private var drawnSize: CGSize = .zero
    @Environment(\.displayScale) private var displayScale

    init(setId: Int, artwork: SetArtwork?, category: MysteryCategory?) {
        self.init(setId: setId, artwork: artwork, fallback: .categoryPainting(category))
    }

    init(setId: Int, artwork: SetArtwork?, fallback: Fallback) {
        self.setId = setId
        self.artwork = artwork
        self.fallback = fallback
        // A revisited page finds its plate already decoded and shows it on
        // the first frame rather than after a fade.
        // Any copy of it already decoded will do for the first frame.
        let hit = artwork?.urls.lazy.compactMap { url in ArtworkCache.shared.cached(url).map { (url, $0) } }.first
        _loaded = State(initialValue: hit?.1)
        _loadedURL = State(initialValue: hit?.0)
    }

    var body: some View {
        ZStack {
            if let artwork, !failed {
                if case .categoryPaintingWhileLoading(let category) = fallback {
                    categoryPainting(for: category)
                } else {
                    AppColors.cardBackground
                }

                if let loaded, let loadedURL, artwork.urls.contains(loadedURL) {
                    FocalFill(uiImage: loaded, focal: artwork.focalPoint)
                        .transition(.opacity)
                }
            } else {
                switch fallback {
                case .categoryPainting(let category), .categoryPaintingWhileLoading(let category):
                    categoryPainting(for: category)
                case .nothing:
                    Color.clear
                }
            }
        }
        .animation(.easeOut(duration: 0.35), value: loaded != nil)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { drawnSize = $0 }
        .task(id: wantedURL) {
            guard let artwork else {
                loaded = nil
                loadedURL = nil
                failed = false
                return
            }

            // Not measured yet: nothing to ask for
            guard let wanted = wantedURL else { return }
            if loadedURL == wanted, loaded != nil { return }

            // Do not leave the previous set's painting in a cell SwiftUI
            // has reused while the new painting is being resolved; another
            // copy of this one stays up until the wanted one arrives.
            if let loadedURL, !artwork.urls.contains(loadedURL) {
                loaded = nil
                self.loadedURL = nil
            }
            failed = false
            if let hit = ArtworkCache.shared.cached(wanted) {
                loaded = hit
                loadedURL = wanted
                return
            }

            let image = await ArtworkCache.shared.image(for: artwork, setId: setId, url: wanted)
            guard !Task.isCancelled else { return }
            if let image {
                loaded = image
                loadedURL = wanted
            } else if loaded == nil {
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
    /// The copy to fetch for the plate, once measured: as wide as the
    /// painting is drawn when it fills the plate (a wide painting in a tall
    /// plate is drawn wider than the plate), in pixels
    private var wantedURL: String? {
        guard let artwork, drawnSize.width > 0, drawnSize.height > 0 else { return nil }
        var points = drawnSize.width
        if let size = artwork.intrinsicSize {
            points = max(points, drawnSize.height * size.width / size.height)
        }
        return artwork.url(forPixelWidth: Double(points * displayScale))
    }

    private var accessibilityText: String? {
        guard let artwork, !failed, loaded != nil, let loadedURL, artwork.urls.contains(loadedURL) else { return nil }
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
