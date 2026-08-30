//
//  ChapelGrid.swift
//  Lumen Viae
//
//  The Chapel page's furniture for arranging: the two-column grid that
//  seats full- and half-width tiles, the sway they take up while
//  arranging, the ✕ badge that puts a section away, the dashed slot
//  that opens where a carried tile will land, the ghost under the
//  finger, and the tray the tab bar yields to.
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
/// span-1 tiles share one, top-aligned. Rows never pack densely — the
/// order the user set is the order the eye reads.
nonisolated struct ChapelGridLayout: Layout {

    var columnGap: CGFloat = 16
    var rowGap: CGFloat = 30

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
        var column = 0

        func closeRow() {
            rowTop += rowHeight + rowGap
            rowHeight = 0
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

        return frames
    }
}

// MARK: - ChapelSway

/// The gentle rock every placed tile takes up while arranging —
/// ±0.5° at 0.24s, staggered by position. It stops entirely while
/// something is carried, so the only moving thing is the one in hand,
/// and it never runs under Reduce Motion.
struct ChapelSway: ViewModifier {

    let active: Bool
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onChange(of: active && !reduceMotion, initial: true) { _, swaying in
                if swaying {
                    angle = -0.5
                    withAnimation(
                        .easeInOut(duration: 0.24)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.05)
                    ) {
                        angle = 0.5
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        angle = 0
                    }
                }
            }
    }
}

// MARK: - ChapelRemoveBadge

/// The ✕ that puts a section away. Carded tiles hang it at the corner;
/// frameless tiles have no corner, so theirs sits in the row gap above,
/// clear of the kicker glyph.
struct ChapelRemoveBadge: View {

    let tile: ChapelTile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.backgroundDeep)
                Circle()
                    .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 0.5)
                AppIcon("ph-x", size: 10)
                    .foregroundColor(AppColors.gold.opacity(0.8))
            }
            .frame(width: 22, height: 22)
            // The badge reads as 22pt but answers to 44. It is the only
            // control that puts a section away, and it sits inside a
            // cell that is simultaneously running a drag gesture — a
            // miss here does not do nothing, it starts carrying the tile.
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(
            x: (tile.isFrameless ? -2 : -7) - 11,
            y: (tile.isFrameless ? -24 : -7) - 11
        )
        .accessibilityLabel("Put \(tile.title) away")
    }
}

// MARK: - ChapelSlotView

/// The dashed opening between two tiles where the carried one will land.
struct ChapelSlotView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.gold.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        AppColors.gold.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                    )
            )
            .shadow(color: AppColors.gold.opacity(0.1), radius: 11)
            .frame(minHeight: 74)
            .scaleEffect(arrived || reduceMotion ? 1 : 0.94)
            .opacity(arrived || reduceMotion ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.22)) { arrived = true }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - ChapelGhost

/// The card that lifts out under the finger: the section's icon and
/// name, leaning up to ±9° into the direction of travel.
struct ChapelGhost: View {

    let tile: ChapelTile
    let tilt: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false

    var body: some View {
        HStack(spacing: 12) {
            AppIcon(tile.icon, size: 17)
                .foregroundColor(AppColors.gold)

            Text(tile.title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(1.8)
                .lineSpacing(3)
                .foregroundColor(AppColors.cream.opacity(0.9))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(width: 168)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundDeep)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 17, y: 9)
        .shadow(color: AppColors.gold.opacity(0.16), radius: 13)
        .rotationEffect(.degrees(reduceMotion ? 0 : tilt))
        .scaleEffect(lifted || reduceMotion ? 1.04 : 0.9)
        .opacity(lifted || reduceMotion ? 1 : 0.5)
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { lifted = true }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - ChapelTray

/// What the tab bar yields to while arranging: the put-away sections,
/// each ready to be dragged back up onto the page — or tapped, which
/// returns it to the page's end.
struct ChapelTray: View {

    /// Sections currently off the page, in layout order.
    let putAway: [ChapelPlacement]

    let onDone: () -> Void
    let onAdd: (ChapelTile) -> Void

    /// Builds the drag gesture for one tray row; the page owns the
    /// carry pipeline, the tray only offers the handle.
    let rowGesture: (ChapelPlacement) -> AnyGesture<DragGesture.Value>

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                // Names the two gestures the page never announced: a tap
                // switches a section between its wide and narrow drawing,
                // and ✕ puts it in this tray rather than deleting it —
                // which is what a ✕ badge otherwise promises.
                Text(putAway.isEmpty
                     ? "Drag to reorder · tap to resize · ✕ puts a section here"
                     : "Drag onto your page · tap to resize · nothing is deleted")
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                Button(action: onDone) {
                    Text("DONE")
                        .font(AppFonts.labelFont(11))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .padding(.leading, 12)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Done arranging")
            }
            .padding(.bottom, 4)

            tray
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: AppColors.background.opacity(0.85), location: 0.22),
                    .init(color: AppColors.backgroundDeep, location: 0.42),
                    .init(color: AppColors.backgroundDeep, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private var tray: some View {
        Group {
            if putAway.isEmpty {
                Text("Everything is on your page. What you put away waits here.")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(putAway) { placement in
                            row(placement)
                        }
                    }
                }
                .frame(maxHeight: 168)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func row(_ placement: ChapelPlacement) -> some View {
        HStack(spacing: 14) {
            AppIcon(placement.tile.icon, size: 17)
                .foregroundColor(AppColors.gold.opacity(0.6))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(placement.tile.title)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.85))

                Text(placement.tile.detail)
                    .font(AppFonts.bodyFont(11))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            grabHandle
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .gesture(rowGesture(placement))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(placement.tile.title). \(placement.tile.detail)")
        .accessibilityHint("Double-tap to put it back on your page.")
        .accessibilityAction { onAdd(placement.tile) }
    }

    private var grabHandle: some View {
        VStack(spacing: 3) {
            ForEach(0..<3) { _ in
                HStack(spacing: 3) {
                    ForEach(0..<2) { _ in
                        Circle()
                            .fill(AppColors.gold.opacity(0.45))
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
        .padding(.trailing, 2)
        .accessibilityHidden(true)
    }
}
