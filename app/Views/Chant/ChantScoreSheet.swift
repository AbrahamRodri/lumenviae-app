//
//  ChantScoreSheet.swift
//  Lumen Viae
//
//  A chant's score, large: the whole of it at the width of the glass, a
//  pinch (or a double tap) to bring a phrase closer, and the transport
//  kept at the foot so the score can be followed while the chant sounds.
//  A sheet, not a page: it is the score of the page it opens from, with
//  nowhere else to go.
//

import SwiftUI

struct ChantScoreSheet: View {

    let chant: Chant

    /// Off where the page beneath has its own transport sounding the chant
    /// (a consecration day), so the sheet never takes the player from it
    var showsTransport = true

    @Environment(\.dismiss) private var dismiss

    private var player = ChantPlayer.shared

    /// How much closer than the width of the glass: 1 to 3
    @State private var zoom: CGFloat = 1

    /// A zoom under way — a pinch, or a double tap's — drawn as the score
    /// scaled about the point it began on. The score is laid out afresh at
    /// its new width only when the zoom settles, so the engraving is drawn
    /// sharp again at the size it is read.
    @State private var pinch: CGFloat = 1
    @State private var pinchAnchor: UnitPoint = .topLeading
    @State private var pinchStart: CGRect?

    /// The score's frame in the glass, and each part's engraving in the
    /// score's own coordinates
    @State private var scoreFrame: CGRect = .zero
    @State private var partFrames: [Int: CGRect] = [:]
    @State private var glassSize: CGSize = .zero

    /// The phrase a zoom keeps under the fingers, and where in the glass
    /// it is scrolled to once the score stands at its new width
    @State private var mark: ChantScoreMark?
    @State private var pendingScroll: UnitPoint?

    private static let glass = "ChantScoreSheet.glass"

    init(chant: Chant, showsTransport: Bool = true) {
        self.chant = chant
        self.showsTransport = showsTransport
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(kicker: "The score", title: chant.fullTitle) {
                SheetHeaderAction(title: "Done") { dismiss() }
            }

            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView([.vertical, .horizontal], showsIndicators: false) {
                        ChantScoreView(
                            parts: chant.score,
                            spacing: 30,
                            onPartFrame: { index, frame in partFrames[index] = frame },
                            mark: mark,
                            onMarkPlaced: {
                                // Laid out at its new width, the mark stands
                                // on the same phrase: scroll it back under
                                // the point it was read at
                                guard let anchor = pendingScroll else { return }
                                pendingScroll = nil
                                proxy.scrollTo(ChantScoreView.markID, anchor: anchor)
                            }
                        )
                        .frame(width: (geo.size.width - 32) * zoom)
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named(Self.glass))
                        } action: { frame in
                            scoreFrame = frame
                        }
                        .scaleEffect(pinch, anchor: pinchAnchor)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    if pinchStart == nil {
                                        pinchStart = scoreFrame
                                        pinchAnchor = value.startAnchor
                                    }
                                    pinch = Self.clamped(zoom * value.magnification) / zoom
                                }
                                .onEnded { value in
                                    let start = pinchStart ?? scoreFrame
                                    pinchStart = nil
                                    settle(
                                        at: Self.clamped(zoom * value.magnification),
                                        keeping: value.startLocation,
                                        from: start.origin
                                    )
                                }
                        )
                        .simultaneousGesture(
                            SpatialTapGesture(count: 2)
                                .onEnded { tap in
                                    zoomByTap(at: tap.location)
                                }
                        )
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                    .coordinateSpace(.named(Self.glass))
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { glassSize = $0 }
                }
                .accessibilityHint("Pinch or double tap to bring the score closer")
            }

            if showsTransport {
                footTransport
            }
        }
        .sheetGround()
        .presentationDetents([.large])
    }

    // MARK: - Zoom

    /// Where a zoom leaves the score: the mark on the phrase kept, the
    /// point of the glass it is scrolled to, and the score's origin in the
    /// glass — where that would put it, and where it rests once the scroll
    /// view has held it within its bounds
    private struct Landing {
        let mark: ChantScoreMark
        let anchor: UnitPoint
        let free: CGPoint
        let origin: CGPoint
    }

    private func landing(at newZoom: CGFloat, keeping point: CGPoint, from origin: CGPoint) -> Landing? {
        let glass = glassSize
        let parts = partFrames.sorted { $0.key < $1.key }
        // The part under the point, and the point as a fraction of its
        // engraving (clamped to it when the point is on a caption)
        guard glass.width > 0, glass.height > 0,
              let (index, frame) = parts.first(where: { point.y <= $0.value.maxY }) ?? parts.last,
              frame.width > 0, frame.height > 0
        else { return nil }
        let unit = UnitPoint(
            x: min(max((point.x - frame.minX) / frame.width, 0), 1),
            y: min(max((point.y - frame.minY) / frame.height, 0), 1)
        )
        let inGlass = CGPoint(
            x: origin.x + frame.minX + unit.x * frame.width,
            y: origin.y + frame.minY + unit.y * frame.height
        )

        // At the new zoom the engravings scale and the captions and gaps
        // between them do not
        let scale = newZoom / zoom
        let above = parts.filter { $0.key < index }.reduce(0) { $0 + $1.value.height }
        let engraved = parts.reduce(0) { $0 + $1.value.height }
        let markInScore = CGPoint(
            x: (frame.minX + unit.x * frame.width) * scale,
            y: frame.minY + above * (scale - 1) + unit.y * frame.height * scale
        )
        let width = (glass.width - 32) * newZoom
        let height = scoreFrame.height + engraved * (scale - 1)
        // The scroll view keeps 16 points of margin about the score, and 40
        // beneath it
        let free = CGPoint(x: inGlass.x - markInScore.x, y: inGlass.y - markInScore.y)
        let left = min(max(free.x, min(glass.width - 16 - width, 16)), 16)
        let top = min(max(free.y, min(glass.height - 40 - height, 16)), 16)

        return Landing(
            mark: ChantScoreMark(part: index, unit: unit),
            anchor: UnitPoint(
                x: min(max(inGlass.x / glass.width, 0), 1),
                y: min(max(inGlass.y / glass.height, 0), 1)
            ),
            free: free,
            origin: CGPoint(x: left, y: top)
        )
    }

    /// A double tap brings the score to twice the width of the glass, or
    /// back to its width, about the tapped phrase: drawn first as the score
    /// scaling about that point, as a pinch is, then laid out and settled.
    /// Where the scroll view's edge holds the score back — always across,
    /// coming back to the width of the glass — the scaling is drawn about
    /// the point that brings the score to where it will rest instead.
    private func zoomByTap(at point: CGPoint) {
        let target: CGFloat = zoom > 1.2 ? 1 : 2
        let size = scoreFrame.size
        let origin = scoreFrame.origin
        guard size.width > 0, size.height > 0,
              let landing = landing(at: target, keeping: point, from: origin)
        else { return }
        let scale = target / zoom
        func anchor(_ free: CGFloat, _ rest: CGFloat, _ start: CGFloat, _ tapped: CGFloat) -> CGFloat {
            abs(rest - free) < 0.5 ? tapped : (rest - start) / (1 - scale)
        }
        let anchorX = anchor(landing.free.x, landing.origin.x, origin.x, point.x)
        let anchorY = anchor(landing.free.y, landing.origin.y, origin.y, point.y)
        pinchAnchor = UnitPoint(x: anchorX / size.width, y: anchorY / size.height)
        withAnimation(Motion.settle, completionCriteria: .logicallyComplete) {
            pinch = scale
        } completion: {
            settle(at: target, keeping: point, from: origin)
        }
    }

    /// Lays the score out at `newZoom` and keeps `point` — a point on the
    /// score as it stood, in its own coordinates — where it was in the
    /// glass. Laid out afresh at the new width, the score would otherwise
    /// grow from its top-left corner and carry the phrase being read off
    /// the glass.
    private func settle(at newZoom: CGFloat, keeping point: CGPoint, from origin: CGPoint) {
        guard newZoom != zoom else {
            withAnimation(Motion.settle) { pinch = 1 }
            return
        }
        if let landing = landing(at: newZoom, keeping: point, from: origin) {
            mark = landing.mark
            pendingScroll = landing.anchor
        }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            zoom = newZoom
            pinch = 1
        }
    }

    private static func clamped(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, 1), 3)
    }

    /// Play, pause and the time, under a hairline — the score stays the
    /// sheet's subject
    private var footTransport: some View {
        let holds = player.holds(chant)
        return VStack(spacing: 10) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)

            HStack(spacing: 14) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying(chant),
                    isLoading: player.current.id == chant.id && player.isLoading,
                    size: 40,
                    label: chant.latinTitle
                ) {
                    player.toggle(chant)
                }

                ChantScrubber(
                    progress: holds ? player.progress : 0,
                    duration: holds ? player.duration : chant.duration,
                    isEnabled: holds
                ) { fraction in
                    player.seek(toFraction: fraction)
                }

                Text(holds ? ChantPlayer.clock(player.currentTime) : chant.durationLabel)
                    .font(AppFonts.labelFont(9))
                    .tracking(1.5)
                    .foregroundColor(AppColors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 36, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}
