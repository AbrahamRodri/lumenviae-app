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

// MARK: - ArchHero

/// The cathedral-window hero: a painting clipped into a lancet arch,
/// double-struck in gold, its foot dissolved so the page runs on
/// underneath, with the screen's own words standing on a weighted scrim.
///
/// One place for it so the home screen's featured mystery and the
/// consecration's day overview stay the same object. The scrim stops are
/// weighted rather than even — out of the way through the top third,
/// gathering only where the words need ground, so more of the painting
/// survives behind the title.
struct ArchHero<Content: View>: View {

    /// Asset name of the painting the arch frames
    let imageName: String

    var height: CGFloat = 410

    /// Laid over the painting, under the scrim — a flat dim on the home
    /// card, the phase's own hue on the consecration screen.
    var tint: AnyShapeStyle = AnyShapeStyle(Color.black.opacity(0.25))

    var spacing: CGFloat = 16

    var contentPadding = EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)

    /// A glow survives the foot mask and re-draws the very edge the mask
    /// exists to remove, as a bright band under the arch. Where the hero
    /// sits directly on the page gradient that band is visible, so the
    /// halo comes off.
    var showsHalo: Bool = true

    @ViewBuilder let content: Content

    private var arch: GothicArchShape { GothicArchShape(riseRatio: 0.34) }

    var body: some View {
        // Arch shape drives size; the image goes in .overlay so it never
        // expands layout bounds, then everything clips to the arch.
        arch
            .fill(AppColors.cardBackground)
            .frame(height: height)
            .overlay(
                CachedAssetImage(imageName)
                    .aspectRatio(contentMode: .fill)
                    .overlay(Rectangle().fill(tint))
            )
            .clipShape(arch)
            .overlay(arch.strokeBorder(AppColors.gold.opacity(0.4), lineWidth: 1))
            .overlay(
                arch.inset(by: 5)
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: 0.5)
            )
            .overlay(alignment: .bottom) {
                VStack(spacing: spacing) { content }
                    .padding(contentPadding)
                    .background(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: AppColors.background.opacity(0.5), location: 0.34),
                                .init(color: AppColors.background.opacity(0.86), location: 0.66),
                                .init(color: AppColors.background, location: 0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            // The hero runs edge to edge, so its foot would otherwise end
            // on a rule straight across the screen — the arch's stroke
            // closes its path along the bottom, and the scrim stops dead
            // against the page gradient. Dissolving the last few points
            // removes both at once. Masked before the halo so the glow
            // itself isn't clipped, and applied to the arch-clipped view
            // so it follows the silhouette rather than a box.
            .mask(
                VStack(spacing: 0) {
                    Rectangle().fill(.black)
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)
                }
            )
            // Steady, not pulsing — the same presence the Pray medallion
            // and the narration transport carry.
            .modifier(OptionalHalo(active: showsHalo))
    }
}

/// `haloGlow` behind a switch, so a hero can drop it without the call
/// site branching on two otherwise identical view trees.
private struct OptionalHalo: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.haloGlow(AppColors.gold, radius: 16, intensity: 0.18)
        } else {
            content
        }
    }
}

// MARK: - HeroBadge

/// The tracked gold kicker that rides above a hero's title — "JOYFUL
/// MYSTERIES", "WEEK TWO · DAY 20 OF 33".
struct HeroBadge: View {

    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppFonts.labelFont(9))
            .tracking(2.5)
            .foregroundColor(AppColors.goldLight)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(AppColors.background.opacity(0.55)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.45), lineWidth: 1))
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
    ///
    /// `filled: false` keeps the padding and the rule but drops the
    /// surface — an outline on the page for a section that should read
    /// as a place rather than a slab.
    func sacredCard(
        vertical: CGFloat,
        horizontal: CGFloat,
        cornerRadius: CGFloat = 16,
        filled: Bool = true
    ) -> some View {
        self
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(filled ? AppColors.cardBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: 0.5)
            )
    }

    func sacredCard(padding: CGFloat = 20, cornerRadius: CGFloat = 16, filled: Bool = true) -> some View {
        sacredCard(vertical: padding, horizontal: padding, cornerRadius: cornerRadius, filled: filled)
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
