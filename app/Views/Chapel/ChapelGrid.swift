//
//  ChapelGrid.swift
//  Lumen Viae
//
//  The Chapel page's furniture for arranging: the two-column grid that
//  seats full- and half-width tiles; the compact row each section folds
//  to while the page is arranged, with its grip, its width and the ✕
//  that hides it; the dashed slot that opens where a carried section
//  will land; the row lifted under the finger; and the tray of hidden
//  sections the tab bar yields to.
//
//  The page itself (state, gestures, persistence) lives in MyChapelView;
//  everything here is drawing.
//

import SwiftUI

// MARK: - ChapelGridLayout

/// Span carried per subview: 2 = full row, 1 = half. Nonisolated: the
/// layout engine reads it off the main actor (see the Concurrency notes
/// in CLAUDE.md).
nonisolated struct ChapelSpanKey: LayoutValueKey {
    static let defaultValue: Int = 2
}

extension View {
    func chapelSpan(_ span: Int) -> some View {
        layoutValue(key: ChapelSpanKey.self, value: span)
    }
}

/// A two-column flow: a span-2 tile takes the whole row; consecutive
/// span-1 tiles share one, and are stretched to it, so two halves side
/// by side always end on the same line. Rows never pack densely — the
/// order the user set is the order the eye reads.
nonisolated struct ChapelGridLayout: Layout {

    var columnGap: CGFloat = 16
    var rowGap: CGFloat = 28

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // An unspecified proposal is a question about ideal size, not an
        // offer of zero width. Measured at zero every tile wraps to one
        // character per line and reports an enormous height, which the
        // grid then claims as its own.
        let width = proposal.width ?? idealWidth(of: subviews)
        let frames = frames(for: subviews, in: width)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    private func idealWidth(of subviews: Subviews) -> CGFloat {
        let widest = subviews
            .map { subview in
                let ideal = subview.sizeThatFits(.unspecified).width
                // A half-width tile's ideal is half a row, so the row it
                // implies is twice as wide plus the gap between columns.
                return subview[ChapelSpanKey.self] == 2 ? ideal : ideal * 2 + columnGap
            }
            .max() ?? 0
        return max(0, widest)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = frames(for: subviews, in: bounds.width)
        for (index, subview) in subviews.enumerated() {
            let frame = frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func frames(for subviews: Subviews, in width: CGFloat) -> [CGRect] {
        let halfWidth = max(0, (width - columnGap) / 2)

        var frames: [CGRect] = []
        var rowTop: CGFloat = 0
        var rowHeight: CGFloat = 0
        var rowStart = 0
        var column = 0

        // Every tile in a row is given the row's height: each tile's
        // shell fills what it is offered and pins its foot to the floor,
        // so a short half beside a tall one ends where the tall one does
        // rather than leaving a ragged bottom.
        func closeRow() {
            for index in rowStart..<frames.count {
                frames[index].size.height = rowHeight
            }
            rowTop += rowHeight + rowGap
            rowHeight = 0
            rowStart = frames.count
            column = 0
        }

        for subview in subviews {
            let span = subview[ChapelSpanKey.self]
            let tileWidth = span == 2 ? width : halfWidth

            if span == 2, column == 1 {
                closeRow()
            }

            let height = subview.sizeThatFits(
                ProposedViewSize(width: tileWidth, height: nil)
            ).height

            let x = column == 1 ? halfWidth + columnGap : 0
            frames.append(CGRect(x: x, y: rowTop, width: tileWidth, height: height))
            rowHeight = max(rowHeight, height)

            if span == 2 || column == 1 {
                closeRow()
            } else {
                column = 1
            }
        }

        // A half left alone on the last row keeps its own height
        if rowStart < frames.count { closeRow() }

        return frames
    }
}

// MARK: - ChapelArrangeRow

/// A section as it stands while the page is arranged: folded to one
/// 58pt row so the whole page fits the glass and a section can be
/// carried past the others without scrolling. The grip says it moves;
/// the row says how wide it stands — WIDE in a capsule at full width,
/// HALF under the name at half — and a tap anywhere on it switches the
/// two. The ✕ that hides it is laid over its trailing edge by the page
/// (`ChapelHideButton`), above the carry gesture, so the row keeps room
/// for it here.
struct ChapelArrangeRow: View {

    let placement: ChapelPlacement

    var body: some View {
        HStack(spacing: placement.span == 2 ? 12 : 10) {
            ChapelGrip(color: AppColors.textSecondary)

            if placement.span == 2 {
                Text(placement.tile.title)
                    .font(AppFonts.bodyFont(18))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text("WIDE")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.gold.opacity(0.45), lineWidth: AppLine.hairline)
                    )
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(placement.tile.shortTitle)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("HALF")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                }

                Spacer(minLength: 0)
            }

            // The hide button's place
            Color.clear
                .frame(width: ChapelHideButton.width, height: 1)
        }
        .padding(.leading, placement.span == 2 ? 14 : 12)
        .padding(.trailing, placement.span == 2 ? 4 : 0)
        .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
                .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
        )
    }
}

/// The six dots of a grip — the mark of a thing that moves.
struct ChapelGrip: View {
    var color: Color

    var body: some View {
        VStack(spacing: 2.8) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 2.8) {
                    ForEach(0..<2, id: \.self) { _ in
                        Circle()
                            .fill(color)
                            .frame(width: 3.2, height: 3.2)
                    }
                }
            }
        }
        .frame(width: 12, height: 18)
        .accessibilityHidden(true)
    }
}

// MARK: - ChapelHideButton

/// The ✕ that hides a section — into the tray, never a deletion. Laid
/// over the arrange row's trailing edge, above the carry gesture: it is
/// the only control that hides a section, and it sits inside a cell
/// that is running a drag — a miss here does not do nothing, it starts
/// carrying the section.
struct ChapelHideButton: View {

    let tile: ChapelTile
    let span: Int
    let action: () -> Void

    /// 44 at either width: the half's row is narrow, and the target is
    /// not
    static let width: CGFloat = 44

    var body: some View {
        Button(action: action) {
            AppIcon("ph-x", size: 16)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: Self.width, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .padding(.trailing, span == 2 ? 4 : 0)
        .accessibilityLabel("Hide \(tile.title)")
    }
}

// MARK: - ChapelSlotView

/// The dashed opening between two rows where the carried section will
/// land, saying so.
struct ChapelSlotView: View {

    let span: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
            .fill(AppColors.gold.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
                    .strokeBorder(
                        AppColors.gold,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                    )
            )
            .overlay(
                Text(span == 2 ? "LET GO TO PLACE IT HERE" : "PLACE IT HERE")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
            )
            .frame(height: 58)
            .scaleEffect(arrived || reduceMotion ? 1 : 0.96)
            .opacity(arrived || reduceMotion ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.22)) { arrived = true }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - ChapelGhost

/// The row lifted under the finger, leaning up to ±9° into the
/// direction of travel.
struct ChapelGhost: View {

    let tile: ChapelTile
    let tilt: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false

    var body: some View {
        HStack(spacing: 12) {
            ChapelGrip(color: AppColors.gold)

            Text(tile.title)
                .font(AppFonts.bodyFont(18))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text("MOVING")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold)
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .frame(width: 300, height: 58)
        .background(
            RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
                .fill(AppColors.cardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
                .strokeBorder(AppColors.gold, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
        .shadow(color: AppColors.gold.opacity(0.13), radius: 16)
        .rotationEffect(.degrees(reduceMotion ? 0 : tilt))
        .scaleEffect(lifted || reduceMotion ? 1.02 : 0.94)
        .opacity(lifted || reduceMotion ? 1 : 0.5)
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { lifted = true }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - ChapelTray

/// What the tab bar yields to while arranging: the hidden sections, each
/// a chip ready to be tapped back onto the page's end or dragged up to
/// a place of its own. Nothing is deleted, and the tray says so.
struct ChapelTray: View {

    /// Sections currently off the page, in layout order.
    let hidden: [ChapelPlacement]

    let onAdd: (ChapelTile) -> Void

    /// Builds the drag gesture for one chip; the page owns the carry
    /// pipeline, the tray only offers the handle.
    let chipGesture: (ChapelPlacement) -> AnyGesture<DragGesture.Value>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("HIDDEN SECTIONS")
                    .font(AppFonts.headlineFont(13))
                    .tracking(2)
                    .foregroundColor(AppColors.cream)
                    .accessibilityAddTraits(.isHeader)

                Text(hidden.isEmpty
                     ? "Nothing is hidden. The ✕ on a section puts it here."
                     : "Nothing is deleted. Tap one to put it back.")
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(Motion.crossfade, value: hidden.isEmpty)
            }

            if !hidden.isEmpty {
                ChapelChipFlow(spacing: 10) {
                    ForEach(hidden) { placement in
                        chip(placement)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(AppColors.cardBackground)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                        .stroke(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline)
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func chip(_ placement: ChapelPlacement) -> some View {
        HStack(spacing: 8) {
            // Phosphor's ✕ turned a quarter: the plus at the same weight
            AppIcon("ph-x", size: 13)
                .rotationEffect(.degrees(45))
                .foregroundColor(AppColors.gold)

            Text(placement.tile.title)
                .font(AppFonts.bodyFont(16))
                .foregroundColor(AppColors.cream)
                .lineLimit(1)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .frame(height: 44)
        .background(Capsule().fill(AppColors.background))
        .overlay(
            Capsule()
                .strokeBorder(AppColors.gold.opacity(0.45), lineWidth: AppLine.hairline)
        )
        .contentShape(Capsule())
        .gesture(chipGesture(placement))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(placement.tile.title), hidden. \(placement.tile.detail)")
        .accessibilityHint("Double-tap to put it back on your page.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onAdd(placement.tile) }
    }
}

// MARK: - ChapelChipFlow

/// Chips laid in rows, wrapping to the next when a row is full.
/// Nonisolated: the layout engine reads it off the main actor (see the
/// Concurrency notes in CLAUDE.md).
nonisolated struct ChapelChipFlow: Layout {

    var spacing: CGFloat = 10

    /// Fills the proposed width when there is one, so `placeSubviews`
    /// arranges against exactly the width `sizeThatFits` did — a tight
    /// content width fed back as bounds can differ by a floating-point
    /// ulp and wrap the last chip of the widest row on placement only
    /// (the meditation shelf's `ChipFlowLayout` learned it first).
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let placed = positions(of: subviews, in: proposal.width ?? .infinity)
        if let width = proposal.width, width.isFinite {
            return CGSize(width: width, height: placed.size.height)
        }
        return placed.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placed = positions(of: subviews, in: proposal.width ?? bounds.width)
        for (subview, point) in zip(subviews, placed.points) {
            subview.place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func positions(of subviews: Subviews, in width: CGFloat) -> (points: [CGPoint], size: CGSize) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }

        return (points, CGSize(width: widest, height: y + rowHeight))
    }
}
