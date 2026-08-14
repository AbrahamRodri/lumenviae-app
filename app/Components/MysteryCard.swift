//
//  MysteryCard.swift
//  app
//
//  Created by Abraham Rodriguez on 2/10/26.
//

import SwiftUI

struct MysteryCard: View {
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    var cardImageName: String? = nil

    /// Which part of the painting the card crop keeps. `.fill` centers by
    /// default, which is wrong for canvases whose subject sits high in
    /// the frame — see `MysteryCategory.cardImageAlignment`.
    var imageAlignment: Alignment = .center

    /// Fine vertical adjustment on top of `imageAlignment`, in points.
    /// Offset is a render-time shift, so the crop moves without the
    /// image's layout — and the scrim over it — moving with it.
    var imageOffset: CGFloat = 0

    var body: some View {
        // RoundedRectangle drives size; image goes in .overlay
        // so it never expands the card's layout bounds.
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom))
            .frame(height: 160)
            .overlay(
                Group {
                    if let cardImageName {
                        CachedAssetImage(cardImageName)
                            .aspectRatio(contentMode: .fill)
                            .offset(y: imageOffset)
                    }
                },
                alignment: imageAlignment
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            // Weighted like the featured card's scrim: the art stays clear
            // through the top half and the shading gathers only under the
            // title.
            //
            // Laid over the clipped card, not over the painting. On the
            // image these stops were measured against the overflowing
            // `.fill` bounds, so `location: 1` was the foot of the
            // artwork rather than the foot of the card and the title got
            // far less ground than the numbers suggest — and with the
            // crop anchored anywhere but center they would drift again.
            .overlay {
                if cardImageName != nil {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.05), location: 0),
                            .init(color: .black.opacity(0.18), location: 0.5),
                            .init(color: .black.opacity(0.68), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .allowsHitTesting(false)
                }
            }
            // Clipping is visual only — without this, the unclipped .fill
            // image still catches taps far outside the card and steals
            // touches from neighbors (e.g. VIEW ALL above the grid).
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.background.opacity(0.25))
                        .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 0.5))
                        .frame(width: 28, height: 28)
                    AppIcon("ph-arrow-right", size: 12)
                        .foregroundColor(AppColors.gold)
                }
                .padding(12)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.cream.opacity(0.75))
                }
                .padding(14)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 0.5)
            )
    }
}

#Preview {
    MysteryCard(
        title: "Joyful",
        subtitle: "The Incarnation",
        gradientColors: [Color(hex: "3d3522"), Color(hex: "2a2518")],
        cardImageName: "joyful_annunciation"
    )
    .padding()
    .background(AppColors.background)
}
