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

    /// Room for the Our Father labels beside the bead column
    static let width: CGFloat = 150

    /// One bead's length of string
    static let rowHeight: CGFloat = 34

    /// The column the beads are centred in, at the trailing edge
    static let beadColumn: CGFloat = 24

    /// Between a label's end and the bead column
    private static let labelGap: CGFloat = 30

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
                .padding(.trailing, Self.beadColumn / 2 - 0.5)

            VStack(spacing: 0) {
                ForEach((0..<strand.count).reversed(), id: \.self) { index in
                    row(at: index)
                }
            }
            .offset(y: restingOffset + dragOffset)
            // The slide to the next bead is always this spring, however
            // the move was made — a swipe, a tap on the bead row, the
            // Lock Screen — so the string has one way of moving
            .animation(Motion.beadSlide, value: activeIndex)

            // The ripple leaves the bead under the hand, which is always
            // at the window's middle, so it needs no row to belong to
            DecadeTurnRipple(trigger: turnPulse)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
                .offset(y: height / 2 - Self.rowHeight / 2)
        }
        .frame(width: Self.width, height: height, alignment: .topTrailing)
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

            if let label = strand.strandLabel(at: index) {
                Text(label.uppercased())
                    .font(AppFonts.labelFont(7.5))
                    .tracking(1.5)
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
        Circle()
            .strokeBorder(AppColors.goldLight, lineWidth: 1)
            .frame(width: 22, height: 22)
            .keyframeAnimator(initialValue: Ring(), trigger: trigger) { view, ring in
                view
                    .scaleEffect(reduceMotion ? 1 : ring.scale)
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
    /// - Parameters:
    ///   - fullHeight: The glass, top to bottom, safe areas included.
    ///   - topInset: The safe area above this view, so the window can be
    ///     placed against the glass rather than against the inset frame.
    ///   - dragOffset: How far a swipe under way has drawn the string.
    ///   - turnPulse: Bumped when a decade turns, for the ripple.
    func rosaryStrand(
        _ strand: RosaryStrand,
        activeIndex: Int,
        fullHeight: CGFloat,
        topInset: CGFloat,
        dragOffset: CGFloat = 0,
        turnPulse: Int = 0
    ) -> some View {
        let windowTop = fullHeight * 0.24
        let windowHeight = fullHeight * 0.435

        return overlay(alignment: .topTrailing) {
            RosaryStrandView(
                strand: strand,
                activeIndex: activeIndex,
                height: windowHeight,
                dragOffset: dragOffset,
                turnPulse: turnPulse
            )
            .padding(.top, max(windowTop - topInset, 0))
            .padding(.trailing, 26)
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
