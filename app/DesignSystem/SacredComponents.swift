//
//  SacredComponents.swift
//  Lumen Viae
//
//  The shared Catholic visual vocabulary: gothic arches, rosary-bead
//  progress, ornamental dividers, illuminated drop caps, and corner
//  flourishes. Kept deliberately restrained — structure over clutter.
//

import SwiftUI

// MARK: - GothicArchShape

/// A pointed (lancet) arch: vertical sides that sweep into a peaked
/// apex. Used to clip featured imagery and frame sacred content.
///
/// `riseRatio` controls how much of the width the arch rise occupies;
/// the sides below the springline stay straight, so the shape works
/// on both tall cards and squat frames.
struct GothicArchShape: InsettableShape {

    /// Arch rise as a fraction of the shape's width
    var riseRatio: CGFloat = 0.30

    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> GothicArchShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let rise = min(rect.width * riseRatio, rect.height * 0.9)
        let springY = rect.minY + rise
        let apex = CGPoint(x: rect.midX, y: rect.minY)
        let shoulderY = rect.minY + rise * 0.38

        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: springY))
        p.addQuadCurve(
            to: apex,
            control: CGPoint(x: rect.minX + rect.width * 0.03, y: shoulderY)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: springY),
            control: CGPoint(x: rect.maxX - rect.width * 0.03, y: shoulderY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - RosaryBeadProgress

/// Progress rendered as a strand of rosary beads on a fine chain.
/// Completed beads glow gold, the active bead breathes, and the
/// beads ahead rest as faint outlines — never a scolding empty bar.
struct RosaryBeadProgress: View {

    /// Total number of beads in the strand
    let total: Int

    /// Number of beads fully completed
    let completed: Int

    /// Index of the bead currently being prayed (breathes gently)
    var activeIndex: Int? = nil

    var beadSize: CGFloat = 9

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<total, id: \.self) { index in
                bead(at: index)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(
            Rectangle()
                .fill(AppColors.gold.opacity(0.22))
                .frame(height: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(completed) of \(total)")
    }

    @ViewBuilder
    private func bead(at index: Int) -> some View {
        if index < completed {
            Circle()
                .fill(AppColors.goldGradient)
                .frame(width: beadSize, height: beadSize)
                .shadow(color: AppColors.gold.opacity(0.55), radius: 3)
        } else if index == activeIndex {
            ActiveBead(size: beadSize)
        } else {
            Circle()
                .strokeBorder(AppColors.textSecondary.opacity(0.4), lineWidth: 1)
                .background(Circle().fill(AppColors.background.opacity(0.9)))
                .frame(width: beadSize, height: beadSize)
        }
    }
}

/// The bead currently being prayed: ringed in bright gold and
/// breathing slowly (still, when Reduce Motion is on).
private struct ActiveBead: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let size: CGFloat

    var body: some View {
        let core = ZStack {
            Circle()
                .fill(AppColors.gold.opacity(0.35))
            Circle()
                .strokeBorder(AppColors.goldLight, lineWidth: 1.2)
        }
        .frame(width: size + 3, height: size + 3)
        .shadow(color: AppColors.gold.opacity(0.5), radius: 4)

        if reduceMotion {
            core
        } else {
            core.phaseAnimator([1.0, 1.18, 1.0]) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in
                .easeInOut(duration: 1.4)
            }
        }
    }
}

// MARK: - OrnamentDivider

/// A fine ornamental rule: fading gold lines flanking diamond studs
/// and (optionally) a small Latin cross at center.
struct OrnamentDivider: View {

    var showsCross: Bool = true
    var lineOpacity: Double = 0.55

    var body: some View {
        HStack(spacing: 10) {
            fadingLine(leading: true)

            diamond

            if showsCross {
                LatinCross()
                    .fill(AppColors.gold.opacity(0.85))
                    .frame(width: 9, height: 13)
            }

            diamond

            fadingLine(leading: false)
        }
        .accessibilityHidden(true)
    }

    private var diamond: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.8))
            .frame(width: 5, height: 5)
            .rotationEffect(.degrees(45))
    }

    private func fadingLine(leading: Bool) -> some View {
        LinearGradient(
            colors: leading
                ? [AppColors.gold.opacity(0), AppColors.gold.opacity(lineOpacity)]
                : [AppColors.gold.opacity(lineOpacity), AppColors.gold.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}

// MARK: - OrnateCornersOverlay

/// Four fine corner flourishes — a double hairline tick in each
/// corner, like the ruled corners of an illuminated page. Overlay
/// on cards that deserve a touch more ceremony.
struct OrnateCornersOverlay: View {

    var inset: CGFloat = 10
    var length: CGFloat = 16
    var opacity: Double = 0.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { p in
                for (x, y, dx, dy) in [
                    (inset, inset, 1.0, 1.0),
                    (w - inset, inset, -1.0, 1.0),
                    (inset, h - inset, 1.0, -1.0),
                    (w - inset, h - inset, -1.0, -1.0)
                ] {
                    p.move(to: CGPoint(x: x + CGFloat(dx) * length, y: y))
                    p.addLine(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x, y: y + CGFloat(dy) * length))
                }
            }
            .stroke(AppColors.gold.opacity(opacity), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - DropCapText

/// A paragraph whose first letter is set as an illuminated initial —
/// large Cinzel gold capital leading into EB Garamond body text.
struct DropCapText: View {

    let text: String
    var bodySize: CGFloat = 17
    var textColor: Color = AppColors.cream

    /// The initial shares the first line's text box, so its font metrics
    /// set that line's height: much past 1.6× the body and the line grows
    /// a visible hole beneath it, breaking the paragraph's rhythm. 1.6×
    /// keeps the cap standing proud of the line — a versal initial —
    /// while the leading stays even.
    private var capSize: CGFloat { (bodySize * 1.6).rounded() }

    private static let openingQuotes: Set<Character> = ["\u{201C}", "\u{2018}", "\"", "'"]

    var body: some View {
        // Line spacing tracks the body size so enlarged text keeps its air
        composed.lineSpacing(ReadingTypography.lineSpacing(for: bodySize))
    }

    /// A paragraph that opens with a quotation gets no illumination at
    /// all — an enlarged or gilded quote mark reads as a mistake, so
    /// those paragraphs are set as plain reading text.
    private var composed: Text {
        guard let first = text.first, !Self.openingQuotes.contains(first) else {
            return plain(text)
        }
        return versal(first) + plain(String(text.dropFirst()))
    }

    private func versal(_ letter: Character) -> Text {
        Text(String(letter))
            .font(AppFonts.titleFont(capSize))
            .foregroundColor(AppColors.gold)
    }

    private func plain(_ s: String) -> Text {
        Text(s).font(AppFonts.readingFont(bodySize)).foregroundColor(textColor)
    }
}

// MARK: - Gold CTA Background

extension View {

    /// The horizontal gold pill used for primary actions. Pairs with
    /// `GoldCTAButtonStyle` for press feedback.
    func goldCTABackground(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(AppColors.goldCTAGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Sacred Card

extension View {

    /// The app's card shell: a themed surface behind a fine gold
    /// hairline. One place for it so every card on every screen carries
    /// the same radius, fill, and rule weight.
    func sacredCard(
        vertical: CGFloat,
        horizontal: CGFloat,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
            )
    }

    func sacredCard(padding: CGFloat = 20, cornerRadius: CGFloat = 16) -> some View {
        sacredCard(vertical: padding, horizontal: padding, cornerRadius: cornerRadius)
    }
}

// MARK: - Previews

#Preview("Sacred components") {
    VStack(spacing: 28) {
        GothicArchShape()
            .strokeBorder(AppColors.gold.opacity(0.6), lineWidth: 1)
            .frame(width: 160, height: 130)

        RosaryBeadProgress(total: 10, completed: 4, activeIndex: 4)
            .padding(.horizontal, 30)

        OrnamentDivider()
            .padding(.horizontal, 40)

        DropCapText(text: "Behold, the handmaid of the Lord; be it done unto me according to thy word. And the Word was made flesh and dwelt among us.")
            .padding(.horizontal, 24)
    }
    .padding(.vertical, 40)
    .frame(maxWidth: .infinity)
    .background(AppColors.background)
}
