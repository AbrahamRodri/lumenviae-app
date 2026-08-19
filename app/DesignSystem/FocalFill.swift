//
//  FocalFill.swift
//  Lumen Viae
//
//  A painting filling a frame, cropped around the point that matters.
//
//  `.aspectRatio(.fill)` keeps the middle of the canvas, and `.overlay(
//  alignment:)` + `.offset(y:)` could only ever nudge that for one frame
//  size — an offset tuned for a 160pt card is half the overflow of a
//  thumbnail. A focal point is normalized to the canvas instead: the
//  subject 24% down the painting lands 24% down the frame whatever the
//  frame's size, which is the same rule the curator's preview draws with
//  CSS `object-position`, so what they see is what the phone shows.
//
//  Given frame F, intrinsic size I and focal point f:
//
//      scale  = max(F.w / I.w, F.h / I.h)
//      drawn  = I * scale
//      offset = ((0.5 - f.x) * (drawn.w - F.w), (0.5 - f.y) * (drawn.h - F.h))
//
//  f = (0.5, 0.5) is exactly the old centred `.fill`; f.y = 0 is `.top`.
//

import SwiftUI
import UIKit

struct FocalFill: View {

    let image: Image

    /// The painting's own size, in any unit — only its ratio matters.
    /// Known up front for API artwork (`image_width`/`image_height`) so the
    /// crop is settled before the bytes arrive.
    let intrinsicSize: CGSize

    /// Where in the canvas the subject sits, 0…1 on each axis
    let focal: UnitPoint

    init(image: Image, intrinsicSize: CGSize, focal: UnitPoint = .center) {
        self.image = image
        self.intrinsicSize = intrinsicSize
        self.focal = focal
    }

    init(uiImage: UIImage, focal: UnitPoint = .center) {
        self.init(image: Image(uiImage: uiImage), intrinsicSize: uiImage.size, focal: focal)
    }

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.size
            let drawn = Self.drawnSize(filling: frame, intrinsic: intrinsicSize)
            let offset = Self.offset(drawn: drawn, frame: frame, focal: focal)

            image
                .resizable()
                .frame(width: drawn.width, height: drawn.height)
                .position(
                    x: frame.width / 2 + offset.width,
                    y: frame.height / 2 + offset.height
                )
        }
        .clipped()
        // Clipping is visual only — without this the overflow would still
        // catch taps outside the frame and steal them from neighbours.
        .contentShape(Rectangle())
    }

    // MARK: - The Formula

    /// The size the painting is drawn at to cover the frame
    static func drawnSize(filling frame: CGSize, intrinsic: CGSize) -> CGSize {
        guard intrinsic.width > 0, intrinsic.height > 0 else { return frame }
        let scale = max(frame.width / intrinsic.width, frame.height / intrinsic.height)
        return CGSize(width: intrinsic.width * scale, height: intrinsic.height * scale)
    }

    /// How far the drawn painting's centre sits from the frame's centre so
    /// that fraction `f` of the canvas lands at fraction `f` of the frame
    static func offset(drawn: CGSize, frame: CGSize, focal: UnitPoint) -> CGSize {
        CGSize(
            width: (0.5 - focal.x) * (drawn.width - frame.width),
            height: (0.5 - focal.y) * (drawn.height - frame.height)
        )
    }
}

// MARK: - Previews

#Preview("Focal points") {
    let pieta = "seven_sorrows_pieta"
    return VStack(spacing: 16) {
        HStack(spacing: 16) {
            ForEach([0.0, 0.3, 0.5, 1.0], id: \.self) { y in
                VStack(spacing: 6) {
                    if let uiImage = UIImage(named: pieta) {
                        FocalFill(uiImage: uiImage, focal: UnitPoint(x: 0.5, y: y))
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Text("y \(y, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        if let uiImage = UIImage(named: pieta) {
            FocalFill(uiImage: uiImage, focal: MysteryCategory.sevenSorrows.cardFocalPoint)
                .frame(width: 170, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    .padding()
    .background(AppColors.background)
}
