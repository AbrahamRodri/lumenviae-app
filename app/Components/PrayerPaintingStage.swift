//
//  PrayerPaintingStage.swift
//  Lumen Viae
//
//  The ground every prayer player stands on: the mystery's painting
//  pulled low on the screen, its foot frosted into the controls, and a
//  scrim to keep the words legible over it. Tapping the painting clears
//  the chrome, and with the chrome gone the painting takes the whole
//  glass.
//
//  Lifted out of `MysteryPrayerView` so the Scriptural Rosary could pray
//  on the same ground without a second copy of it — the two screens
//  differ in what stands on the stage, not in the stage.
//
//  Sized by its host rather than measuring itself: the host's controls
//  sit inside the safe area, so the host's proxy reports the inset
//  height, and the artwork and scrim bleed past it in both directions.
//  They have to be sized against the glass, not against the room left
//  over for the chrome.
//

import SwiftUI

struct PrayerPaintingStage: View {

    /// How the painting is set on the glass.
    enum Style {
        /// Seated in the upper part of the screen with its foot frosted
        /// into the controls — the meditation's player, whose title and
        /// transport need ground of their own to stand on
        case seated
        /// Filling the glass, dimmed under a veil — the Scriptural
        /// Rosary, whose verse stands in the middle of the picture and
        /// needs the whole of it quiet behind the words
        case veiled
    }

    /// The painting on the stage, or nothing yet — a plain card ground
    /// stands in while a painting is on its way, or when there is none
    let painting: PrayerPainting?

    var style: Style = .seated

    /// Identity for the crossfade: a new mystery is a new picture
    let paintingID: Int

    /// True while a tap has cleared the chrome and the painting fills
    /// the screen
    let chromeHidden: Bool

    /// The glass, edge to edge — the host's width and its full height
    /// including both safe-area insets
    let width: CGFloat
    let fullHeight: CGFloat

    /// A tap on the painting. The host decides what it means (clearing
    /// the chrome, and retiring any hint that was showing).
    let onTap: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            switch style {
            case .seated:
                // Artwork with a frosted foot, tapped to clear the chrome
                artworkLayer

                // Scrim so the title and controls stay legible over art
                scrimOverlay

            case .veiled:
                veiledArtwork

                veil
            }
        }
    }

    // MARK: - Veiled

    /// The painting edge to edge, dimmed to just over half so the verse
    /// reads over any part of it; a tap lifts the dimming with the
    /// chrome and the picture is seen whole.
    private var veiledArtwork: some View {
        Group {
            if let painting {
                FocalFill(image: painting.image, intrinsicSize: painting.intrinsicSize, focal: painting.focal)
                    .frame(width: width, height: fullHeight)
                    .clipped()
            } else {
                Rectangle()
                    .fill(AppColors.cardBackground)
                    .frame(width: width, height: fullHeight)
            }
        }
        .opacity(chromeHidden ? 1 : 0.55)
        .animation(Motion.chrome, value: chromeHidden)
        .ignoresSafeArea()
        .compositingGroup()
        .id(paintingID)
        .transition(.opacity)
        .animation(Motion.decadeTurn, value: paintingID)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    /// Darker at the head, where the chrome is, and at the foot, where
    /// the controls are; lightest across the middle where the verse
    /// stands over the picture. Most of it goes with the chrome.
    private var veil: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.background.opacity(0.70), location: 0),
                .init(color: AppColors.background.opacity(0.35), location: 0.30),
                .init(color: AppColors.background.opacity(0.45), location: 0.55),
                .init(color: AppColors.background.opacity(0.95), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .opacity(chromeHidden ? 0.3 : 1)
    }

    /// The mystery's artwork, pulled low on the screen. Its lower band is
    /// the artwork itself blurred — a frosted transition into the controls
    /// instead of a hard dark gradient — so more of the painting survives.
    /// With the chrome tapped away the painting takes the whole screen.
    private var artworkLayer: some View {
        // The frost keeps the chrome-up height in both states. It is only
        // ever visible with the chrome up, and animating its geometry
        // would re-blur two full-screen copies on every frame of the tap.
        //
        // Seated higher than the painting would like: the player's title,
        // scrubber, transport and utility row are four bands of chrome,
        // and they need ground of their own to sit on.
        let seatedHeight = fullHeight * 0.75
        let artHeight = chromeHidden ? fullHeight : seatedHeight

        return VStack(spacing: 0) {
            Group {
                if let painting {
                    mysteryArtwork(
                        painting,
                        height: artHeight,
                        frostHeight: seatedHeight
                    )
                } else {
                    // Nothing to draw yet — the set's painting is on its
                    // way, or there is none and no bundled one either
                    Rectangle()
                        .fill(AppColors.cardBackground)
                        .frame(height: artHeight)
                }
            }
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
        // One layer for the crossfade. Without this the opacity transition
        // is applied leaf by leaf — the painting fades in on its own and
        // the frost and foot fade on top of it fade in on their own — so
        // halfway through the switch the sharp painting shows through its
        // own fade with a hard edge at the foot, then the fade "comes
        // back" as the transition finishes. Composited first, the
        // transition fades the finished picture as a whole.
        .compositingGroup()
        .id(paintingID)
        .transition(.opacity)
        .animation(Motion.decadeTurn, value: paintingID)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    /// The painting filling the frame, cropped around its focal point —
    /// the centre for a bundled painting, the curator's point for a set's.
    private func mysteryArtwork(
        _ painting: PrayerPainting,
        height: CGFloat,
        frostHeight: CGFloat
    ) -> some View {
        FocalFill(image: painting.image, intrinsicSize: painting.intrinsicSize, focal: painting.focal)
            .frame(width: width, height: height)
            .overlay(
                // Two staggered blur layers fake a progressive blur: the
                // soft pass eases the sharp painting into the frost, the
                // strong pass deepens below it — no visible seam where
                // the blurring begins. Clipped so blur can't bleed past
                // the artwork's edges.
                //
                // The frost is the painting itself and not a material:
                // a material blurs the backdrop through a gray system
                // tint, which drains the color the paintings carry —
                // the deep blues in particular come back gray.
                ZStack {
                    blurLayer(painting, height: frostHeight,
                              radius: 5, from: 0.74, to: 0.88)
                    blurLayer(painting, height: frostHeight,
                              radius: 13, from: 0.84, to: 0.95)
                }
                .frame(width: width, height: frostHeight)
                // The frost exists to seat the title and controls; with the
                // chrome tapped away it has nothing to seat, so it lifts and
                // the painting shows sharp edge to edge.
                .opacity(chromeHidden ? 0 : 1)
                .allowsHitTesting(false),
                alignment: .top
            )
            // Seats the art on the background so it never ends on a hard
            // line: one fade to the background color, laid over the sharp
            // painting *and* its frost together. Earlier the frost sat
            // above this fade and cut itself out with a short taper of its
            // own at the foot — a bright blurred band held at full strength
            // over an already-dark base, then dropped across ~50pt. Flat,
            // steep, flat is exactly what the eye reads as a line. One long
            // ramp over everything has no such step.
            //
            // It also finishes *before* the image's own edge and holds flat
            // background through it: a ramp that only reaches full color on
            // the last pixel still shows the last few percent of a bright
            // foot (the Annunciation's cream cloud) as a line exactly where
            // the image stops. Compact in contemplation — the art should
            // feel full-bleed, just not edge-cut.
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: chromeHidden ? 0.86 : 0.70),
                        .init(color: AppColors.background, location: 0.95),
                        .init(color: AppColors.background, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
            .clipped()
    }

    private func blurLayer(
        _ painting: PrayerPainting,
        height: CGFloat,
        radius: CGFloat,
        from: CGFloat,
        to: CGFloat
    ) -> some View {
        // The same crop as the sharp painting above it, so the frost is
        // that painting blurred and not a differently-framed copy
        FocalFill(image: painting.image, intrinsicSize: painting.intrinsicSize, focal: painting.focal)
            .frame(width: width, height: height)
            .blur(radius: radius)
            .mask(
                // Held to the foot, not tapered back out: the background
                // fade above covers the frost too, so the blurred copy
                // can't re-cut the image's edge, and a second taper here
                // would only add a step of its own.
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: from),
                        .init(color: .black, location: to),
                        .init(color: .black, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    /// Lighter than a hard fade — the frosted band underneath does half
    /// the legibility work, so more painting shows through.
    ///
    /// The head carries a shade of its own. The set's name in small gold
    /// capitals and the × stand over whatever the top of the painting
    /// happens to be — sky, gold cloud, a lit wall — and there the name
    /// could all but disappear. The shade is darkest under the status bar
    /// and the title and dissolves to nothing a fifth of the way down,
    /// before the scene begins; never a band with an edge.
    private var scrimOverlay: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.72), location: 0),
                    .init(color: AppColors.background.opacity(0.5), location: 0.45),
                    .init(color: AppColors.background.opacity(0.18), location: 0.75),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: fullHeight * 0.22)

            Spacer()
                .frame(height: fullHeight * 0.22)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.background.opacity(0.45), location: 0.40),
                    .init(color: AppColors.background.opacity(0.9), location: 0.68),
                    .init(color: AppColors.background, location: 0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .drawingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
        // Contemplation lifts the veil: most of the scrim goes with the
        // chrome, leaving only enough to keep the status bar readable
        .opacity(chromeHidden ? 0.3 : 1)
    }
}
