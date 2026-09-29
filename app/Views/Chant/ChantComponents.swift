//
//  ChantComponents.swift
//  Lumen Viae
//
//  The pieces every chant surface shares: the score drawn on the dark
//  page, the play disc, the scrubber, and the credit the recordings carry.
//
//  The scores are Verbum Gloriae's engravings, redrawn by the app from
//  the operations Tools/Chants recorded — the notes in the page's cream
//  and the initials in the missal's rubric red, as the text of every
//  prayer is. Printed black on white they would be the one bright slab
//  on a dark app.
//

import SwiftUI

// MARK: - ChantScoreImage

/// One engraved part of a score, drawn on the page: the ink in cream, the
/// initials in rubric red, vector at any width (`ChantScoreDrawing`).
struct ChantScoreImage: View {
    let part: ChantScorePart

    @State private var drawing: ChantScoreDrawing?

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

            let ink = AppColors.cream.opacity(0.94)
            let red = Rubric.red
            for operation in drawing.operations {
                switch operation {
                case .fill(let path, let which):
                    context.fill(Path(path), with: .color(which == .ink ? ink : red))
                case .erase(let path):
                    // A white shape in the engraving: it clears what lies
                    // under it, so the page shows through
                    context.blendMode = .destinationOut
                    context.fill(Path(path), with: .color(.black))
                    context.blendMode = .normal
                case .stroke(let path, let which, let width):
                    context.stroke(Path(path), with: .color(which == .ink ? ink : red), lineWidth: width)
                }
            }
        }
        .aspectRatio(part.aspectRatio, contentMode: .fit)
        .opacity(drawing == nil ? 0 : 1)
        .animation(Motion.crossfade, value: drawing == nil)
        .task(id: part.file) {
            if drawing == nil {
                drawing = await ChantScoreStore.shared.load(part.file)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Score: \(part.caption)")
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - ChantScoreView

/// Every part of a chant's score in order, each named when there is
/// more than one (the hymn, then its versicle, then its collect).
struct ChantScoreView: View {
    let parts: [ChantScorePart]
    var spacing: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                VStack(alignment: .leading, spacing: 10) {
                    if parts.count > 1 {
                        Text(part.caption.uppercased())
                            .font(AppFonts.labelFont(8.5))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ChantScoreImage(part: part)
                }
            }
        }
    }
}

// MARK: - ChantPlayDisc

/// The round play control: a dark disc lit through a gold rim, the one
/// shape the app gives to a play control that is not a page's act.
struct ChantPlayDisc: View {
    let isPlaying: Bool
    let isLoading: Bool
    var size: CGFloat = 46
    var label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)

                // Play, pause and the spinner crossfade over one another
                // rather than swapping under the thumb
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.goldLight)
                            .scaleEffect(0.8)
                            .transition(.opacity)
                    } else {
                        AppIcon(isPlaying ? "ph-pause-fill" : "ph-play-fill", size: size * 0.32)
                            .foregroundColor(AppColors.goldLight)
                            .contentTransition(.opacity)
                    }
                }
                .animation(Motion.crossfade, value: isLoading)
                .animation(Motion.crossfade, value: isPlaying)
            }
            .frame(width: size, height: size)
            .shadow(color: AppColors.gold.opacity(0.3), radius: size * 0.2)
            // Drawn at its size, answering to 44 whatever that is
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(isPlaying ? "Pause \(label)" : "Play \(label)")
    }
}

// MARK: - ChantScrubber

/// A gold hairline the finger can drag along — the consecration
/// transport's scrubber, at the weight of a rule.
struct ChantScrubber: View {
    let progress: Double
    let isEnabled: Bool
    let onSeek: (Double) -> Void

    @State private var dragging: Double?

    private var shown: Double { dragging ?? progress }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.cream.opacity(0.14))
                    .frame(height: 3)
                Capsule()
                    .fill(AppColors.goldCTAGradient)
                    .frame(width: max(width * shown, 3), height: 3)
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: 11, height: 11)
                    .offset(x: (width - 11) * shown)
                    .opacity(isEnabled ? 1 : 0.4)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }
                        dragging = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { _ in
                        if let dragging { onSeek(dragging) }
                        dragging = nil
                    }
            )
        }
        .frame(height: 24)
        .accessibilityElement()
        .accessibilityLabel("Position in the chant")
        .accessibilityValue("\(Int((shown * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: onSeek(min(1, progress + 0.05))
            case .decrement: onSeek(max(0, progress - 0.05))
            @unknown default: break
            }
        }
    }
}

// MARK: - ChantCredit

/// Who sang it, on what terms. The licence asks no attribution; the app
/// gives it, and says the adapted files are shared on the same terms,
/// which the licence does ask.
struct ChantCredit: View {
    var compact = false

    var body: some View {
        VStack(alignment: compact ? .leading : .center, spacing: 8) {
            Text(ChantCatalog.credit)
                .font(AppFonts.readingItalicFont(compact ? 12.5 : 14))
                .foregroundColor(AppColors.cream.opacity(0.75))
                .multilineTextAlignment(compact ? .leading : .center)

            if !compact {
                Text(ChantCatalog.licenceNote)
                    .font(AppFonts.readingItalicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 18) {
                    Link(destination: ChantCatalog.sourceSite) {
                        Text("VERBUMGLORIAE.ES")
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.8))
                            .frame(minHeight: 44)
                    }
                    Link(destination: ChantCatalog.licenceURL) {
                        Text("THE LICENCE")
                            .font(AppFonts.labelFont(9))
                            .tracking(2)
                            .foregroundColor(AppColors.gold.opacity(0.8))
                            .frame(minHeight: 44)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
    }
}

// MARK: - ChantPracticeChip

/// A small tracked word that turns on and off: SLOW, REPEAT.
struct ChantPracticeChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(isOn ? AppColors.goldLight : AppColors.gold.opacity(0.65))
                .padding(.horizontal, 14)
                .frame(minHeight: 32)
                .background(Capsule().fill(isOn ? AppColors.gold.opacity(0.16) : Color.clear))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(isOn ? 0.5 : 0.25), lineWidth: AppLine.hairline))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: isOn)
    }
}
