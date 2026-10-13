//
//  ChantPaintings.swift
//  Lumen Viae
//
//  The paintings the library hangs: a page's head dissolving into the
//  page, and a row's thumbnail.
//

import SwiftUI

// MARK: - ChantPainting

/// A painting hung at the head of a card or a board, dissolving to clear
/// at its foot so the words beneath stand on the page, never on a slab.
struct ChantPainting: View {
    let name: String
    var height: CGFloat = 220
    /// How far down the painting the dissolve begins
    var dissolveFrom: CGFloat = 0.45

    var body: some View {
        CachedAssetImage(name, focal: .center)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: dissolveFrom),
                        .init(color: .black.opacity(0.35), location: (dissolveFrom + 1) / 2),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityHidden(true)
    }
}

// MARK: - ChantThumbnail

/// A painting as a small square, for a row or the mini player
struct ChantThumbnail: View {
    let name: String
    var size: CGFloat = 40
    var radius: CGFloat = 10
    /// Where the painting is cut; the curation's point for it
    /// (`ChantLibraryData.focalPoints`), else its middle
    var focal: UnitPoint? = nil

    var body: some View {
        CachedAssetImage(name, focal: focal ?? Self.focalPoint(for: name))
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
            )
            .accessibilityHidden(true)
    }

    static func focalPoint(for name: String) -> UnitPoint {
        guard let point = ChantLibraryData.focalPoints[name] else { return .center }
        return UnitPoint(x: point.x, y: point.y)
    }
}
