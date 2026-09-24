//
//  RosaryDiagram.swift
//  Lumen Viae
//
//  A rosary drawn as it lies in the hand: the loop of five decades, the
//  centrepiece at its foot, and the pendant hanging to the crucifix. It
//  teaches the object before the prayer — How to Pray lights its parts
//  one at a time, and the guided Rosary lights the bead under the
//  fingers, the beads behind it gold and the beads ahead waiting.
//
//  Every part is a `RosaryPart`, the same vocabulary the guide's steps
//  use, so what is lit here is always what the words below are about.
//  A readout, never a control.
//

import SwiftUI

struct RosaryDiagram: View {

    /// The bead under the fingers; beads before it in the traversal are
    /// drawn prayed. Nil draws the whole rosary waiting.
    var current: RosaryPart? = nil

    /// Parts picked out for teaching — lit without implying progress
    var highlighted: Set<RosaryPart> = []

    /// The whole rosary behind the fingers: the close, where the hand has
    /// come back round to the centrepiece and down to the crucifix — the
    /// first part of the traversal — and every bead has been prayed
    var completed: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Height over width
    static let aspect: CGFloat = 1.28

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let layout = Layout(width: width)
            let currentPosition = current.map { RosaryMap.position(of: $0) }

            ZStack {
                // The chain: the loop, and the pendant down to the cross
                Circle()
                    .stroke(AppColors.gold.opacity(0.28), lineWidth: max(1, width * 0.004))
                    .frame(width: layout.radius * 2, height: layout.radius * 2)
                    .position(layout.center)

                Path { path in
                    path.move(to: layout.point(for: .medal))
                    path.addLine(to: layout.point(for: .crucifix))
                }
                .stroke(AppColors.gold.opacity(0.28), lineWidth: max(1, width * 0.004))

                ForEach(RosaryMap.traversal.dropLast(), id: \.self) { part in
                    bead(part, layout: layout, currentPosition: currentPosition)
                }

                medal(layout: layout, currentPosition: currentPosition)
            }
            // Under Reduce Motion the lit bead does not swell, and the
            // light passes as a crossfade rather than a settle
            .animation(reduceMotion ? Motion.crossfade : Motion.settle, value: current)
            .animation(Motion.crossfade, value: highlighted)
            .animation(Motion.crossfade, value: completed)
        }
        .aspectRatio(1 / Self.aspect, contentMode: .fit)
        .accessibilityHidden(true)
    }

    // MARK: - State

    private enum BeadState {
        case ahead, prayed, lit
    }

    private func state(of part: RosaryPart, currentPosition: Int?) -> BeadState {
        if part == current || highlighted.contains(part) { return .lit }
        if completed { return .prayed }
        if let currentPosition, RosaryMap.position(of: part) < currentPosition { return .prayed }
        return .ahead
    }

    // MARK: - Beads

    @ViewBuilder
    private func bead(_ part: RosaryPart, layout: Layout, currentPosition: Int?) -> some View {
        let state = state(of: part, currentPosition: currentPosition)
        let point = layout.point(for: part)

        if part == .crucifix {
            CrossShape()
                .fill(fill(for: state))
                .overlay(CrossShape().stroke(AppColors.gold.opacity(state == .ahead ? 0.7 : 1), lineWidth: 1))
                .frame(width: layout.width * 0.075, height: layout.width * 0.11)
                .shadow(color: AppColors.goldLight.opacity(state == .lit ? 0.8 : 0), radius: state == .lit ? 6 : 0)
                .position(x: point.x, y: point.y + layout.width * 0.045)
        } else {
            let size = layout.size(for: part) * (state == .lit ? litGrowth : 1)

            Circle()
                .fill(fill(for: state))
                .overlay(
                    Circle().strokeBorder(
                        state == .lit ? AppColors.goldLight : AppColors.gold.opacity(state == .ahead ? 0.55 : 0.9),
                        lineWidth: 1
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: AppColors.goldLight.opacity(state == .lit ? 0.85 : 0), radius: state == .lit ? 5 : 0)
                .position(point)
        }
    }

    private func medal(layout: Layout, currentPosition: Int?) -> some View {
        let state = state(of: .medal, currentPosition: currentPosition)
        let lit = state == .lit
        // The centrepiece swells a little less than a bead
        let size = layout.width * 0.07 * (lit ? 1 + (litGrowth - 1) * 0.6 : 1)

        return Diamond()
            .fill(fill(for: state))
            .overlay(Diamond().stroke(lit ? AppColors.goldLight : AppColors.gold.opacity(0.9), lineWidth: 1))
            .frame(width: size, height: size * 1.2)
            .shadow(color: AppColors.goldLight.opacity(lit ? 0.85 : 0), radius: lit ? 6 : 0)
            .position(layout.point(for: .medal))
    }

    /// How much a lit bead swells; not at all under Reduce Motion, where
    /// its light alone marks it
    private var litGrowth: CGFloat { reduceMotion ? 1 : 1.35 }

    private func fill(for state: BeadState) -> Color {
        switch state {
        case .ahead:  return AppColors.background
        case .prayed: return AppColors.gold.opacity(0.85)
        case .lit:    return AppColors.goldLight
        }
    }

    // MARK: - Layout

    /// Where each part hangs, in the view's own points
    private struct Layout {
        let width: CGFloat

        var center: CGPoint { CGPoint(x: width * 0.5, y: width * 0.4) }
        var radius: CGFloat { width * 0.36 }

        /// Spacing down the pendant
        var step: CGFloat { width * 0.062 }

        func size(for part: RosaryPart) -> CGFloat {
            switch part {
            case .pendantLarge, .loopLarge: return width * 0.052
            default:                        return width * 0.034
            }
        }

        func point(for part: RosaryPart) -> CGPoint {
            let medal = CGPoint(x: center.x, y: center.y + radius)

            switch part {
            case .medal:
                return medal

            case .pendantLarge(1):
                return CGPoint(x: medal.x, y: medal.y + step * 1.2)
            case .pendantSmall(let index):
                return CGPoint(x: medal.x, y: medal.y + step * (4.2 - Double(index)))
            case .pendantLarge:
                return CGPoint(x: medal.x, y: medal.y + step * 5.4)
            case .crucifix:
                return CGPoint(x: medal.x, y: medal.y + step * 6.4)

            case .loopSmall, .loopLarge:
                // Fifty-four beads and the centrepiece share the circle
                // evenly, the loop setting out up the left side
                let index = RosaryMap.loop.firstIndex(of: part) ?? 0
                let slots = Double(RosaryMap.loop.count + 1)
                let angle = (90 + Double(index + 1) * 360 / slots) * Double.pi / 180
                return CGPoint(
                    x: center.x + radius * CGFloat(Foundation.cos(angle)),
                    y: center.y + radius * CGFloat(Foundation.sin(angle))
                )
            }
        }
    }
}

// MARK: - Shapes

/// A Latin cross, its crossbar a third of the way down
private struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        let bar = rect.width * 0.3
        let arm = rect.height * 0.3
        var path = Path()
        path.addRect(CGRect(x: rect.midX - bar / 2, y: rect.minY, width: bar, height: rect.height))
        path.addRect(CGRect(x: rect.minX, y: rect.minY + arm - bar / 2, width: rect.width, height: bar))
        return path
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 30) {
        RosaryDiagram(current: .loopSmall(decade: 1, bead: 4))
            .frame(width: 220)
        RosaryDiagram(highlighted: [.pendantSmall(0), .pendantSmall(1), .pendantSmall(2)])
            .frame(width: 160)
        RosaryDiagram(current: .crucifix, completed: true)
            .frame(width: 160)
    }
    .padding()
    .background(AppColors.background)
}
