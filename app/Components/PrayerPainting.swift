//
//  PrayerPainting.swift
//  Lumen Viae
//
//  One painting as the prayer flow draws it: the image, and the point in
//  it the crop keeps. The same value serves the player's full-bleed
//  artwork, the reader's mini-player thumbnail and the Lock Screen, so the
//  three can never show different pictures for one mystery.
//
//  The painting is always the current mystery's own bundled image. A
//  meditation set's artwork belongs to its preview page and never replaces
//  these personal mystery images in the prayer flow.
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
}
