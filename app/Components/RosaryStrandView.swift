//
//  RosaryStrandView.swift
//  Lumen Viae
//
//  The whole Rosary as one string hanging at the right edge of the
//  screen, read from the bottom up: prayed beads run off below the
//  hand, the bead under the hand rests at the middle, and the beads
//  still to come descend toward it from above — so the next decade's
//  Our Father, larger and carrying its numeral, can be seen approaching
//  several beads before it arrives.
//
//  A readout, not a control. Nothing on it is tappable; it moves when
//  the hand does — the string follows the finger while a swipe is
//  under way (`dragOffset`), and on release slides the rest of the way
//  to the next bead and settles, the ring passing from the bead leaving
//  the hand to the one arriving. Let go short of a bead, it comes back.
//  When a decade turns, a ripple leaves the bead under the hand — the
//  one moment the strand itself does not move, since the Glory Be is
//  said on the same bead the next decade opens on.
//
//  The window is compact, about eleven beads tall, and dissolves a
//  little above and below so there is always a hint of string beyond
//  in either direction without it running the whole height of the
//  glass. Both players hang it in the same place (`rosaryStrand(_:)`),
//  so a hand that has learned where the beads are on one finds them
//  on the other.
//

import SwiftUI

struct RosaryStrandView: View {

    let strand: RosaryStrand

    /// The bead under the hand, as a position on the string
    let activeIndex: Int

    /// The window's height; the active bead is pinned at its middle
    let height: CGFloat

    /// How far the finger has drawn the string, in points, while a
    /// swipe is under way — positive downward. Zero at rest.
    var dragOffset: CGFloat = 0

    /// Bumped each time a decade turns; the ripple answers it
    var turnPulse: Int = 0

    /// The bead under the hand, named beside it: a line or two of small
    /// capitals in the margin at the window's middle, where the eye and
    /// the thumb already are, its count rolling as the beads pass. Nil
    /// where the screen names the bead elsewhere — the Scriptural
    /// Rosary's column does — and the row keeps its own numeral.
    var activeLabel: [String]? = nil

    /// Greyed and still: the meditation under the hand has not yet been
    /// heard, and the beads open after it. The name beside the bead gives
    /// way to when they open, and a small lock stands on the bead under
    /// the hand. Unlocking colours the string where it hangs.
    var locked: Bool = false

    /// What stands beside the bead under the hand while the strand is locked
    static let lockedLines = ["Opens after", "the meditation"]

    /// Room for the numerals beside the bead column
    static let width: CGFloat = 150

    /// Room past the bead column at the trailing edge, for what the
    /// beads throw beyond their own circle: the ring under the hand and
    /// its halo, and the ripple as a decade turns, which grows to more
    /// than twice the column's width. The window's edge once ran down
    /// the middle of the bead column, and cut the right half off both.
    static let trailingRoom: CGFloat = 24

    /// One bead's length of string
    static let rowHeight: CGFloat = 34

    /// Where the window begins, measured from the top of the glass. The
    /// Scriptural Rosary hangs the head of its reading level with it, so
    /// the two agree by construction.
    static func windowTop(fullHeight: CGFloat) -> CGFloat {
        fullHeight * 0.24
    }

    /// The column the beads are centred in, at the trailing edge
    static let beadColumn: CGFloat = 24

    /// Between a numeral's end and the bead column
    private static let labelGap: CGFloat = 14

    var body: some View {
        // The string is drawn top-down but read bottom-up: the last bead
        // of the Rosary is the first row, and the active bead's row is
        // counted from the top for the offset that pins it mid-window
        let rowFromTop = strand.count - 1 - activeIndex
        let restingOffset = height / 2 - Self.rowHeight / 2 - CGFloat(rowFromTop) * Self.rowHeight

        ZStack(alignment: .topTrailing) {
            // The chain, the full height of the window
            Rectangle()
                .fill(AppColors.gold.opacity(0.22))
                .frame(width: 1, height: height)
                .padding(.trailing, Self.beadColumn / 2 - 0.5 + Self.trailingRoom)
                .saturation(locked ? 0 : 1)
                .opacity(locked ? 0.85 : 1)

            VStack(spacing: 0) {
                ForEach((0..<strand.count).reversed(), id: \.self) { index in
                    row(at: index)
                }
            }
            .offset(y: restingOffset + dragOffset)
            .padding(.trailing, Self.trailingRoom)
            // Locked, every bead is drawn grey — the whole string plainly
            // there and plainly waiting. Grey alone, not dimmed far: at
            // under half strength the beads vanished into a bright painting
            // and the strand read as missing again
            .saturation(locked ? 0 : 1)
            .opacity(locked ? 0.8 : 1)
            // The slide to the next bead is always this spring, however
            // the move was made — a swipe, a tap on the bead row, the
            // Lock Screen — so the string has one way of moving
            .animation(Motion.beadSlide, value: activeIndex)

            // The ripple leaves the bead under the hand, which is always
            // at the window's middle, so it needs no row to belong to
            DecadeTurnRipple(trigger: turnPulse)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
                .offset(y: height / 2 - Self.rowHeight / 2)
                .padding(.trailing, Self.trailingRoom)

            // The bead's name stands still at the window's middle while
            // the rows slide beneath it — one view from bead to bead, so
            // its count rolls instead of the words being torn down with
            // the row that carried them
            if let lines = locked && activeLabel != nil ? Self.lockedLines : activeLabel {
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line.uppercased())
                            .font(AppFonts.labelFont(9))
                            .tracking(1.4)
                            .foregroundColor(locked ? AppColors.cream.opacity(0.8) : AppColors.goldLight.opacity(0.95))
                            .lineLimit(1)
                            .fixedSize()
                            .contentTransition(.numericText())
                    }
                }
                .shadow(color: .black.opacity(0.55), radius: 4, y: 1)
                .frame(height: Self.rowHeight)
                .offset(y: height / 2 - Self.rowHeight / 2)
                .padding(.trailing, Self.trailingRoom + Self.beadColumn + Self.labelGap)
                .animation(Motion.words, value: lines)
            }

            // The lock, on the bead under the hand, while the meditation
            // is still being heard
            if locked {
                StrandLockGlyph()
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .frame(width: Self.beadColumn, height: Self.rowHeight)
                    .offset(y: height / 2 - Self.rowHeight / 2)
                    .padding(.trailing, Self.trailingRoom)
                    .transition(.opacity)
            }
        }
        // Locking and unlocking ease in and out; the slide keeps its own
        // spring, closer to the rows it moves
        .animation(.easeOut(duration: 0.5), value: locked)
        .frame(width: Self.width + Self.trailingRoom, height: height, alignment: .topTrailing)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.34),
                    .init(color: .black, location: 0.66),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        // Let down from above when the screen opens, the way the beads
        // come: a short drift, after the painting has had its moment
        .devotionalEntrance(delay: 0.18, drift: -16)
        .allowsHitTesting(false)
        // The status row beside the controls names the bead in words;
        // this is the same fact drawn, and VoiceOver needs it once
        .accessibilityHidden(true)
    }

    private func row(at index: Int) -> some View {
        let bead = strand.bead(at: index)
        let state: RosaryBeadState = index < activeIndex ? .prayed : (index == activeIndex ? .active : .ahead)
        let isOurFather: Bool
        let size: CGFloat
        switch bead {
        case .hailMary:
            isOurFather = false
            size = 11
        case .ourFather, .amen:
            isOurFather = true
            size = 18
        }

        return HStack(spacing: 0) {
            Spacer(minLength: 0)

            // The active row's numeral yields to the name drawn over it
            if index != activeIndex || activeLabel == nil,
               let label = strand.strandLabel(at: index) {
                Text(label.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1.2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(1)
                    .fixedSize()

                Spacer()
                    .frame(width: Self.labelGap)
            }

            RosaryBead(state: state, size: size, isOurFather: isOurFather)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
        }
        .frame(width: Self.width, height: Self.rowHeight)
    }

    /// How far the string follows a finger that has moved `travel`
    /// points: freely at first, then with growing resistance, so a
    /// bead's length is about as far as it will go however far the
    /// finger does. At either end of the Rosary — nothing to move to
    /// in that direction — it gives only a little, and comes back.
    static func follow(_ travel: CGFloat, resisted: Bool) -> CGFloat {
        let reach = Self.rowHeight * tanh(travel / 90)
        return resisted ? reach * 0.35 : reach
    }
}

// MARK: - Lock

/// A small padlock, drawn rather than imaged — the icon set has no lock —
/// at the weight of the strand's own lines.
private struct StrandLockGlyph: View {
    var body: some View {
        VStack(spacing: -1) {
            LockShackle()
                .stroke(style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                .frame(width: 6, height: 5.5)

            RoundedRectangle(cornerRadius: 1.5)
                .frame(width: 9, height: 7)
        }
        .shadow(color: .black.opacity(0.6), radius: 2)
        .accessibilityHidden(true)
    }
}

/// The lock's shackle: two uprights joined by a half circle.
private struct LockShackle: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addRelativeArc(
            center: CGPoint(x: rect.midX, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            delta: .degrees(180)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

// MARK: - Decade Turn Ripple

/// One ring, leaving the bead under the hand as the decade turns:
/// bright for an instant, then wider and gone. Under Reduce Motion it
/// only brightens and fades, without growing.
private struct DecadeTurnRipple: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let trigger: Int

    private struct Ring {
        var scale: CGFloat = 1
        var opacity: Double = 0
    }

    var body: some View {
        // Read once, outside the animator's closure, which is Sendable
        // and may not touch main-actor state
        let still = reduceMotion

        return Circle()
            .strokeBorder(AppColors.goldLight, lineWidth: 1)
            .frame(width: 22, height: 22)
            .keyframeAnimator(initialValue: Ring(), trigger: trigger) { view, ring in
                view
                    .scaleEffect(still ? 1 : ring.scale)
                    .opacity(ring.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    MoveKeyframe(1)
                    CubicKeyframe(2.6, duration: 0.75)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.85, duration: 0.06)
                    CubicKeyframe(0, duration: 0.69)
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Travel

/// Which way the hand last moved along the string. The words for the
/// bead arrive from the side the string came from — down it for the
/// next bead, up it for the one before — so the screen reads as one
/// thing moving rather than a strand and a caption changing separately.
enum BeadTravel {
    case forward
    case back
}

extension View {

    /// Sets the words for a new bead down from a little above (or up
    /// from a little below, stepping back) as they crossfade in. A short
    /// keyframe rather than a transition, so both the words leaving and
    /// the words arriving move the same way whichever way the last move
    /// went. Under Reduce Motion (`still`) the words only crossfade.
    func beadWordsArrival<Trigger: Equatable>(
        trigger: Trigger,
        from travel: BeadTravel,
        still: Bool,
        distance: CGFloat = 10
    ) -> some View {
        keyframeAnimator(initialValue: CGFloat(0), trigger: trigger) { view, dy in
            view.offset(y: dy)
        } keyframes: { _ in
            MoveKeyframe(still ? 0 : (travel == .forward ? -distance : distance))
            CubicKeyframe(0, duration: 0.36)
        }
    }
}

// MARK: - Placement

extension View {

    /// Hangs the strand at the right edge, at the height both players
    /// agree on: a window from about a quarter of the glass down to
    /// two-thirds, its middle — where the active bead rests — a little
    /// above the screen's centre, clear of the controls at the foot.
    ///
    /// The bead column's centre stands 38 points in from the glass —
    /// the window's frame reaches past it by `trailingRoom`, so the
    /// padding is what remains.
    ///
    /// - Parameters:
    ///   - fullHeight: The glass, top to bottom, safe areas included.
    ///   - topInset: The safe area above this view, so the window can be
    ///     placed against the glass rather than against the inset frame.
    ///   - dragOffset: How far a swipe under way has drawn the string.
    ///   - turnPulse: Bumped when a decade turns, for the ripple.
    ///   - activeLabel: The bead under the hand, named beside it; see
    ///     `RosaryStrandView.activeLabel`.
    ///   - locked: Greyed and still until the meditation has been heard;
    ///     see `RosaryStrandView.locked`.
    ///   - onAmen: Finishes the Rosary. Present only on the final bead,
    ///     where AMEN — the one act that ends a Rosary — hangs under the
    ///     bead's name, at the hand that just prayed it. The strand is a
    ///     readout and takes no touches; the button is laid beside it,
    ///     not on it.
    func rosaryStrand(
        _ strand: RosaryStrand,
        activeIndex: Int,
        fullHeight: CGFloat,
        topInset: CGFloat,
        dragOffset: CGFloat = 0,
        turnPulse: Int = 0,
        activeLabel: [String]? = nil,
        locked: Bool = false,
        onAmen: (() -> Void)? = nil
    ) -> some View {
        let windowTop = max(RosaryStrandView.windowTop(fullHeight: fullHeight) - topInset, 0)
        let windowHeight = fullHeight * 0.435
        // The bead column's centre stands this far in from the glass
        let beadInset: CGFloat = 26

        return overlay(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                RosaryStrandView(
                    strand: strand,
                    activeIndex: activeIndex,
                    height: windowHeight,
                    dragOffset: dragOffset,
                    turnPulse: turnPulse,
                    activeLabel: activeLabel,
                    locked: locked
                )
                .padding(.top, windowTop)
                .padding(.trailing, beadInset - RosaryStrandView.trailingRoom)
                // A readout, never a control: the beads, the string and
                // the bead's name let every touch through to the painting
                // beneath, and only the AMEN laid beside them takes one
                .allowsHitTesting(false)

                if let onAmen {
                    GoldCTAButton(
                        title: "Amen",
                        prominence: .inline,
                        trailingIcon: "ph-check",
                        fullWidth: false,
                        action: onAmen
                    )
                    .accessibilityLabel("Amen — finish the Rosary")
                    // Under the active row, clear of the name above it
                    .padding(.top, windowTop + windowHeight / 2 + RosaryStrandView.rowHeight / 2 + 6)
                    .padding(.trailing, beadInset + RosaryStrandView.beadColumn / 2 + 14)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .animation(Motion.settle, value: onAmen != nil)
        }
    }
}

// MARK: - Preview

#Preview {
    let strand = RosaryStrand(decades: 5, hailMarys: 10)
    HStack(spacing: 30) {
        RosaryStrandView(strand: strand, activeIndex: strand.index(mystery: 0, bead: 0), height: 380)
        RosaryStrandView(strand: strand, activeIndex: strand.index(mystery: 0, bead: 4), height: 380)
        RosaryStrandView(strand: strand, activeIndex: strand.index(mystery: 4, bead: 11), height: 380)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}
