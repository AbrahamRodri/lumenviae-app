//
//  ChantScore.swift
//  Lumen Viae
//
//  The score drawn on the dark page. The scores are Verbum Gloriae's
//  engravings, redrawn by the app from the operations Tools/Chants
//  recorded — the notes in the page's cream and the initials in the
//  missal's rubric red, as the text of every prayer is. Printed black on
//  white they would be the one bright slab on a dark app.
//

import SwiftUI

// MARK: - ChantScoreImage

/// One engraved part of a score, drawn on the page: the ink in cream, the
/// initials in rubric red, vector at any width (`ChantScoreDrawing`).
struct ChantScoreImage: View {
    let part: ChantScorePart

    @State private var drawing: ChantScoreDrawing?

    /// The page is not on the phone and could not be fetched (offline)
    @State private var unavailable = false

    /// Tries made since: each coming back to the app, or the phone coming
    /// back online, tries a page that could not be had again
    @State private var attempt = 0
    @Environment(\.scenePhase) private var scenePhase

    init(part: ChantScorePart) {
        self.part = part
        // A score already read is drawn at once, never faded in again
        _drawing = State(initialValue: ChantScoreStore.shared.cached(part.file))
    }

    var body: some View {
        Canvas { context, size in
            guard let drawing else { return }
            let scale = size.width / drawing.bounds.width
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -drawing.bounds.minX, y: -drawing.bounds.minY)

            let ink = GraphicsContext.Shading.color(AppColors.cream.opacity(0.94))
            let red = GraphicsContext.Shading.color(Rubric.red)
            for operation in drawing.operations {
                switch operation {
                case .fill(let path, let which):
                    context.fill(path, with: which == .ink ? ink : red)
                case .erase(let path):
                    // A white shape in the engraving: it clears what lies
                    // under it, so the page shows through
                    context.blendMode = .destinationOut
                    context.fill(path, with: .color(.black))
                    context.blendMode = .normal
                case .stroke(let path, let which, let width):
                    context.stroke(path, with: which == .ink ? ink : red, lineWidth: width)
                }
            }
        }
        .aspectRatio(part.aspectRatio, contentMode: .fit)
        .opacity(drawing == nil ? 0 : 1)
        .overlay {
            if drawing == nil && unavailable {
                Text("The sheet music comes with a connection")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .transition(.opacity)
            }
        }
        .animation(Motion.crossfade, value: drawing == nil)
        .animation(Motion.crossfade, value: unavailable)
        .task(id: LoadKey(file: part.file, attempt: attempt, online: ChantAssetStore.shared.reconnections)) {
            if drawing == nil {
                drawing = await ChantScoreStore.shared.load(part)
                unavailable = drawing == nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, unavailable { attempt += 1 }
        }
        .accessibilityElement()
        .accessibilityLabel("Sheet music: \(part.caption)")
        .accessibilityAddTraits(.isImage)
    }
}

/// What a score's load is keyed by: a change of any part loads again
private struct LoadKey: Hashable {
    let file: String
    let attempt: Int
    let online: Int
}

// MARK: - ChantScoreView

/// A place on a score that survives its being laid out at another width:
/// a part, and a point on that part's engraving as a fraction of it. The
/// captions between the parts keep their height at any zoom, so a point
/// on the whole score does not scale with it; a point on one engraving
/// does.
struct ChantScoreMark: Equatable {
    let part: Int
    let unit: UnitPoint
}

/// Every part of a chant's score in order, each named when there is
/// more than one (the hymn, then its versicle, then its collect).
struct ChantScoreView: View {
    let parts: [ChantScorePart]
    var spacing: CGFloat = 26

    /// For the enlarged score: where each part's engraving stands, in the
    /// score's own coordinates (`space`); a mark to scroll to; and word
    /// that the mark stands where the score is now laid out
    var onPartFrame: ((Int, CGRect) -> Void)?
    var mark: ChantScoreMark?
    var onMarkPlaced: (() -> Void)?

    static let space = "ChantScoreView.space"
    static let markID = "ChantScoreView.mark"

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                VStack(alignment: .leading, spacing: 10) {
                    if parts.count > 1 {
                        Text(part.caption.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ChantScoreImage(part: part)
                        .overlay {
                            if let mark, mark.part == index {
                                GeometryReader { geometry in
                                    Color.clear
                                        .frame(width: 1, height: 1)
                                        .id(Self.markID)
                                        .onGeometryChange(for: CGRect.self) { geometry in
                                            geometry.frame(in: .named(Self.space))
                                        } action: { _ in
                                            onMarkPlaced?()
                                        }
                                        .position(
                                            x: mark.unit.x * geometry.size.width,
                                            y: mark.unit.y * geometry.size.height
                                        )
                                }
                                .accessibilityHidden(true)
                            }
                        }
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named(Self.space))
                        } action: { frame in
                            onPartFrame?(index, frame)
                        }
                }
            }
        }
        .coordinateSpace(.named(Self.space))
    }
}
