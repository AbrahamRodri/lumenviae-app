//
//  PrayerPainting.swift
//  Lumen Viae
//
//  One painting as the prayer flow draws it: the image, and the point in
//  it the crop keeps. The same value serves the player's full-bleed
//  artwork, the reader's mini-player thumbnail and the Lock Screen, so the
//  three can never show different pictures for one mystery.
//
//  Which painting: the set's own when the set has one — the painting its
//  curator chose for the whole set — and otherwise the bundled painting
//  for this mystery. `MysteryPrayerView` makes that choice once.
//

import SwiftUI
import UIKit

struct PrayerPainting: Equatable {

    let uiImage: UIImage

    /// Where the subject sits, normalized to the canvas — see `FocalFill`
    let focal: UnitPoint

    var image: Image { Image(uiImage: uiImage) }

    var intrinsicSize: CGSize { uiImage.size }

    /// A bundled painting, centred: the per-mystery paintings were
    /// composed for the frame already, so the centre is their focal point.
    static func bundled(_ assetName: String) -> PrayerPainting? {
        ImageCacheService.shared.image(named: assetName).map {
            PrayerPainting(uiImage: $0, focal: .center)
        }
    }

    /// A set's painting once its bytes are in hand, cropped around the
    /// point its curator chose.
    static func set(_ artwork: SetArtwork, image: UIImage) -> PrayerPainting {
        PrayerPainting(uiImage: image, focal: artwork.focalPoint)
    }
}
