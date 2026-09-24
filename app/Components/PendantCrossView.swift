//
//  PendantCrossView.swift
//  Lumen Viae
//
//  The Rosary's pendant, drawn: a budded cross in worked gold at the
//  foot, and above it on the chain the large bead, the three small beads
//  and the centrepiece where the loop begins. It stands in for a
//  mystery's painting while the opening and closing prayers are said —
//  they are prayed on the pendant, before and after the mysteries, and
//  borrowing the first mystery's picture for them said the Rosary had
//  begun when it had not.
//
//  The bead being prayed is lit, the beads below it are gold, and the
//  beads above it wait, so the climb from the cross to the centrepiece
//  is seen as it is heard. Drawn rather than bundled: it has to light
//  any bead, and it stays crisp at any size, the Lock Screen's included.
//
//  The gold is a fixed metal palette rather than the theme's accent: the
//  cross is an object, lit from the upper left, and has to read as gold
//  on every theme.
//

import SwiftUI

// MARK: - The Metal

private enum Metal {
    static let highlight = Color(red: 0.99, green: 0.93, blue: 0.72)
    static let light = Color(red: 0.93, green: 0.80, blue: 0.47)
    static let body = Color(red: 0.80, green: 0.63, blue: 0.28)
    static let shade = Color(red: 0.55, green: 0.40, blue: 0.14)
    static let deep = Color(red: 0.30, green: 0.21, blue: 0.07)

    /// The raised face: lit at the upper left, turning away to the lower
    /// right
    static let face = LinearGradient(
        colors: [highlight, light, body, shade],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// The chamfer between the face and the edge, lit the other way so
    /// the face reads as standing proud of it
    static let bevel = LinearGradient(
        colors: [shade, body, light, highlight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// The outer edge, the metal's thickness seen side-on
    static let edge = LinearGradient(
        colors: [body, shade, deep],
        startPoint: .top,
        endPoint: .bottom
    )

    /// A round of gold — a bead, the centre boss — lit from the upper
    /// left. `radius` is the round's own, in points: a gradient's radius
    /// is absolute, so it has to be told how large the sphere is.
    static func sphere(lit: Bool, radius: CGFloat) -> RadialGradient {
        RadialGradient(
            colors: lit ? [highlight, light, body, shade] : [light, body, shade, deep],
            center: UnitPoint(x: 0.34, y: 0.3),
            startRadius: 0,
            endRadius: radius * 1.55
        )
    }
}

// MARK: - BuddedCross

/// A Latin cross whose four arms end in trefoil buds — the cross
/// bottony, the form most rosary crucifixes take. `inset` draws the
/// same cross drawn in from its edge, so stacking insets builds the
/// bevel: edge, chamfer, face.
struct BuddedCross: Shape {

    var inset: CGFloat = 0

    /// Where the arms cross, as a fraction of the height from the top
    static let crossing: CGFloat = 0.3

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let beam = max(w * 0.15 - inset * 2, 1)
        let bud = max(w * 0.072 - inset, 0.5)
        let reach = w * 0.072 * 1.9

        let cx = rect.midX
        let cy = rect.minY + rect.height * Self.crossing

        let top = CGPoint(x: cx, y: rect.minY + reach)
        let bottom = CGPoint(x: cx, y: rect.maxY - reach)
        let left = CGPoint(x: rect.minX + reach, y: cy)
        let right = CGPoint(x: rect.maxX - reach, y: cy)

        var path = Path()
        path.addRect(CGRect(x: cx - beam / 2, y: top.y, width: beam, height: bottom.y - top.y))
        path.addRect(CGRect(x: left.x, y: cy - beam / 2, width: right.x - left.x, height: beam))

        // Each bud: a round lobe carrying the arm on, and two smaller
        // lobes set back from it on either side
        let arms: [(CGPoint, CGVector)] = [
            (top, CGVector(dx: 0, dy: -1)),
            (bottom, CGVector(dx: 0, dy: 1)),
            (left, CGVector(dx: -1, dy: 0)),
            (right, CGVector(dx: 1, dy: 0))
        ]
        let fullBud = w * 0.072
        for (end, out) in arms {
            let side = CGVector(dx: -out.dy, dy: out.dx)
            let lobes: [(CGPoint, CGFloat)] = [
                (CGPoint(x: end.x + out.dx * fullBud * 0.62, y: end.y + out.dy * fullBud * 0.62), bud),
                (CGPoint(x: end.x - out.dx * fullBud * 0.3 + side.dx * fullBud * 1.02,
                         y: end.y - out.dy * fullBud * 0.3 + side.dy * fullBud * 1.02), bud * 0.8),
                (CGPoint(x: end.x - out.dx * fullBud * 0.3 - side.dx * fullBud * 1.02,
                         y: end.y - out.dy * fullBud * 0.3 - side.dy * fullBud * 1.02), bud * 0.8)
            ]
            for (center, radius) in lobes {
                path.addEllipse(in: CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                ))
            }
        }
        return path
    }
}

// MARK: - The Cross, Worked

/// The cross in the round: its shadow, the edge, the chamfer, the face,
/// an engraved line down each arm, and a boss where the arms meet.
struct WorkedCross: View {

    /// Lit as the bead being prayed: a warmer glow behind it
    var isLit: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let chamfer = w * 0.016
            let face = w * 0.034

            ZStack {
                // The glow the cross stands in: a circle whose gradient
                // is spent before its edge, so it has no edge of its own
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Metal.light.opacity(isLit ? 0.32 : 0.12),
                                Metal.light.opacity(isLit ? 0.1 : 0.04),
                                Metal.light.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w
                        )
                    )
                    .frame(width: w * 2, height: w * 2)
                    .position(x: w / 2, y: h * 0.42)
                    .allowsHitTesting(false)

                // Cast on the ground behind it, down and to the right
                BuddedCross()
                    .fill(Color.black.opacity(0.55))
                    .offset(x: w * 0.02, y: w * 0.035)
                    .blur(radius: w * 0.03)

                BuddedCross()
                    .fill(Metal.edge)

                BuddedCross(inset: chamfer)
                    .fill(Metal.bevel)

                BuddedCross(inset: face)
                    .fill(Metal.face)

                engraving(width: w, height: h, face: face)

                boss(width: w, height: h)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// A fine line cut down the middle of each arm, dark with a lit lip
    /// below it, stopping short of the buds and of the boss
    private func engraving(width w: CGFloat, height h: CGFloat, face: CGFloat) -> some View {
        let cx = w / 2
        let cy = h * BuddedCross.crossing
        let reach = w * 0.072 * 1.9 + w * 0.05
        let clear = w * 0.11
        let line = max(w * 0.006, 0.75)

        let groove = Path { path in
            path.move(to: CGPoint(x: cx, y: reach))
            path.addLine(to: CGPoint(x: cx, y: cy - clear))
            path.move(to: CGPoint(x: cx, y: cy + clear))
            path.addLine(to: CGPoint(x: cx, y: h - reach))
            path.move(to: CGPoint(x: reach, y: cy))
            path.addLine(to: CGPoint(x: cx - clear, y: cy))
            path.move(to: CGPoint(x: cx + clear, y: cy))
            path.addLine(to: CGPoint(x: w - reach, y: cy))
        }

        return ZStack {
            groove
                .stroke(Metal.highlight.opacity(0.55), style: StrokeStyle(lineWidth: line, lineCap: .round))
                .offset(x: line * 0.8, y: line * 0.8)
            groove
                .stroke(Metal.deep.opacity(0.55), style: StrokeStyle(lineWidth: line, lineCap: .round))
        }
    }

    /// The round boss where the arms meet: a ring, and a domed centre
    private func boss(width w: CGFloat, height h: CGFloat) -> some View {
        let r = w * 0.09
        return ZStack {
            Circle()
                .fill(Metal.edge)
                .frame(width: r * 2, height: r * 2)
            Circle()
                .fill(Metal.bevel)
                .frame(width: r * 1.76, height: r * 1.76)
            Circle()
                .fill(Metal.sphere(lit: true, radius: r * 0.65))
                .frame(width: r * 1.3, height: r * 1.3)
            Circle()
                .stroke(Metal.deep.opacity(0.35), lineWidth: max(w * 0.004, 0.5))
                .frame(width: r * 1.3, height: r * 1.3)
            // The glint
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: r * 0.26, height: r * 0.26)
                .blur(radius: r * 0.05)
                .offset(x: -r * 0.22, y: -r * 0.24)
        }
        .position(x: w / 2, y: h * BuddedCross.crossing)
    }
}

// MARK: - The Pendant

struct PendantCrossView: View {

    /// The place being prayed; nil draws the pendant waiting
    var current: PendantPlace?

    /// The closing prayers: everything on the pendant has been prayed on
    /// the way up, so nothing waits
    var isClosing: Bool = false

    /// The Seven Sorrows chaplet, which has no large bead on its pendant
    var isChaplet: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    /// Width over height
    static let aspect: CGFloat = 0.42

    private enum BeadState {
        case prayed
        case current
        case waiting
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let layout = Layout(width: w, height: h, isChaplet: isChaplet)

            ZStack {
                chain(layout)

                medal(layout, state: state(for: .medal))

                chainKnot(layout, state: state(for: .chain))

                ForEach(0..<3, id: \.self) { index in
                    bead(
                        at: layout.small(index),
                        radius: layout.smallRadius,
                        state: state(for: .smallBead(index))
                    )
                }

                if !isChaplet {
                    bead(
                        at: layout.large,
                        radius: layout.largeRadius,
                        state: state(for: .largeBead)
                    )
                }

                // The bail the cross hangs from
                Circle()
                    .stroke(Metal.edge, lineWidth: max(w * 0.018, 1.2))
                    .frame(width: w * 0.07, height: w * 0.07)
                    .position(x: w / 2, y: layout.crossRect.minY - w * 0.01)

                WorkedCross(isLit: state(for: .cross) == .current)
                    .frame(width: layout.crossRect.width, height: layout.crossRect.height)
                    .position(x: layout.crossRect.midX, y: layout.crossRect.midY)
            }
            .animation(reduceMotion ? nil : Motion.settle, value: current)
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(current.map { "The pendant. \($0.name)" } ?? "The pendant")
    }

    // MARK: Where Everything Hangs

    private struct Layout {
        let width: CGFloat
        let height: CGFloat
        let isChaplet: Bool

        var cx: CGFloat { width / 2 }
        var smallRadius: CGFloat { width * 0.056 }
        var largeRadius: CGFloat { width * 0.084 }

        var medal: CGPoint { CGPoint(x: cx, y: height * 0.075) }
        var medalBottom: CGFloat { medal.y + width * 0.24 * 1.3 / 2 }
        var knot: CGPoint { CGPoint(x: cx, y: height * 0.215) }

        /// The three small beads, index 0 nearest the cross: they are
        /// prayed climbing
        func small(_ index: Int) -> CGPoint {
            let lowest = isChaplet ? large.y : height * 0.415
            return CGPoint(x: cx, y: lowest - CGFloat(index) * height * 0.056)
        }

        var large: CGPoint { CGPoint(x: cx, y: height * 0.485) }

        var crossRect: CGRect {
            let crossWidth = width * 0.8
            let crossHeight = crossWidth / 0.72
            return CGRect(
                x: cx - crossWidth / 2,
                y: height - crossHeight - height * 0.005,
                width: crossWidth,
                height: crossHeight
            )
        }
    }

    // MARK: Lit, Prayed, Waiting

    private func state(for place: PendantPlace) -> BeadState {
        guard let current else { return .waiting }
        if place == current { return .current }
        if isClosing { return .prayed }
        return place.rank < current.rank ? .prayed : .waiting
    }

    // MARK: The Chain

    /// Small oval links, alternately face-on and edge-on, from the
    /// centrepiece down to the cross
    private func chain(_ layout: Layout) -> some View {
        Canvas { context, _ in
            let top = layout.medalBottom
            let bottom = layout.crossRect.minY
            let link = max(layout.width * 0.032, 3)
            var y = top
            var faceOn = true
            while y < bottom {
                let rect = faceOn
                    ? CGRect(x: layout.cx - link * 0.34, y: y, width: link * 0.68, height: link)
                    : CGRect(x: layout.cx - link * 0.12, y: y, width: link * 0.24, height: link)
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Metal.body.opacity(0.7)),
                    lineWidth: max(layout.width * 0.008, 0.7)
                )
                y += link * 0.78
                faceOn.toggle()
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Beads

    private func bead(at point: CGPoint, radius: CGFloat, state: BeadState) -> some View {
        ZStack {
            if state == .current {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Metal.light.opacity(0.55), Metal.light.opacity(0)],
                            center: .center,
                            startRadius: radius * 0.6,
                            endRadius: radius * 3
                        )
                    )
                    .frame(width: radius * 6, height: radius * 6)
                    .scaleEffect(breathing ? 1.08 : 0.92)
                    .opacity(breathing ? 1 : 0.75)
            }

            switch state {
            case .prayed, .current:
                Circle()
                    .fill(Metal.sphere(lit: state == .current, radius: radius))
                    .frame(width: radius * 2, height: radius * 2)
                    .shadow(color: .black.opacity(0.45), radius: radius * 0.35, x: radius * 0.12, y: radius * 0.22)
                Circle()
                    .fill(Color.white.opacity(state == .current ? 0.9 : 0.6))
                    .frame(width: radius * 0.42, height: radius * 0.42)
                    .blur(radius: radius * 0.08)
                    .offset(x: -radius * 0.34, y: -radius * 0.36)

            case .waiting:
                Circle()
                    .fill(AppColors.background)
                    .frame(width: radius * 2, height: radius * 2)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.cream.opacity(0.16), AppColors.cream.opacity(0.03)],
                            center: UnitPoint(x: 0.34, y: 0.3),
                            startRadius: 0,
                            endRadius: radius * 1.4
                        )
                    )
                    .frame(width: radius * 2, height: radius * 2)
                Circle()
                    .stroke(Metal.body.opacity(0.5), lineWidth: max(radius * 0.08, 0.75))
                    .frame(width: radius * 2, height: radius * 2)
            }
        }
        .position(point)
    }

    /// Where the Glory Be is said: on the chain itself, marked by a small
    /// lozenge knot rather than a bead
    private func chainKnot(_ layout: Layout, state: BeadState) -> some View {
        let size = layout.width * 0.07
        return ZStack {
            if state == .current {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Metal.light.opacity(0.5), .clear],
                            center: .center, startRadius: 0, endRadius: size * 1.8
                        )
                    )
                    .frame(width: size * 3.6, height: size * 3.6)
                    .scaleEffect(breathing ? 1.08 : 0.92)
            }
            Rectangle()
                .fill(AppColors.background)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(state == .waiting ? AnyShapeStyle(AppColors.cream.opacity(0.12)) : AnyShapeStyle(Metal.face))
                .overlay(Rectangle().stroke(Metal.body.opacity(state == .waiting ? 0.5 : 0.9), lineWidth: 0.8))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
        }
        .position(layout.knot)
    }

    /// The centrepiece: an oval medal where the pendant meets the loop
    private func medal(_ layout: Layout, state: BeadState) -> some View {
        let width = layout.width * 0.24
        let height = width * 1.3
        return ZStack {
            if state == .current {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Metal.light.opacity(0.5), .clear],
                            center: .center, startRadius: 0, endRadius: height
                        )
                    )
                    .frame(width: width * 2.6, height: height * 2.2)
                    .scaleEffect(breathing ? 1.06 : 0.94)
            }
            Ellipse()
                .fill(AppColors.background)
                .frame(width: width, height: height)
            Ellipse()
                .fill(state == .waiting ? AnyShapeStyle(AppColors.cream.opacity(0.1)) : AnyShapeStyle(Metal.edge))
                .frame(width: width, height: height)
            Ellipse()
                .fill(state == .waiting ? AnyShapeStyle(AppColors.cream.opacity(0.06)) : AnyShapeStyle(Metal.bevel))
                .frame(width: width * 0.86, height: height * 0.86)
            Ellipse()
                .fill(state == .waiting ? AnyShapeStyle(AppColors.cream.opacity(0.1)) : AnyShapeStyle(Metal.face))
                .frame(width: width * 0.68, height: height * 0.68)
            Ellipse()
                .stroke(Metal.body.opacity(state == .waiting ? 0.5 : 0), lineWidth: 0.8)
                .frame(width: width, height: height)
        }
        .position(layout.medal)
    }
}

// MARK: - The Stage

/// The ground the opening and closing prayers are said on, in place of a
/// mystery's painting: the pendant standing in a low warm light, seated
/// where the painting would be so the controls keep their place.
struct PendantStage: View {

    let pendant: SpokenPendant

    let width: CGFloat
    let fullHeight: CGFloat

    /// How much of the glass the pendant may take
    var heightFraction: CGFloat = 0.6

    /// Where it hangs from, as a fraction of the glass from the top
    var topFraction: CGFloat = 0.1

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background

            RadialGradient(
                colors: [Metal.body.opacity(0.16), AppColors.background.opacity(0)],
                center: UnitPoint(x: 0.5, y: 0.36),
                startRadius: 0,
                endRadius: fullHeight * 0.55
            )

            PendantCrossView(
                current: pendant.place,
                isClosing: pendant.phase == .closing,
                isChaplet: pendant.isChaplet
            )
            .frame(height: fullHeight * heightFraction)
            .padding(.top, fullHeight * topFraction)
            .frame(maxWidth: .infinity)
        }
        .frame(width: width, height: fullHeight)
        .ignoresSafeArea()
    }
}

// MARK: - The Title

/// What stands where the mystery's title stands while the pendant is
/// prayed: "The Opening Prayers", the prayer being said, and on the way
/// in, the mystery it leads to — so the screen says the Rosary has not
/// reached its first decade yet, and where it is going.
struct PendantTitleBlock: View {

    let pendant: SpokenPendant

    /// "Then the First Glorious Mystery", while the opening is said
    var leadsInto: String? = nil

    /// "The First Glorious Mystery" read mid-sentence
    static func leadIn(to kicker: String) -> String {
        let phrase = kicker.hasPrefix("The ") ? "the " + kicker.dropFirst(4) : kicker
        return "Then \(phrase)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(pendant.heading.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(pendant.title)
                .font(AppFonts.headlineFont(24))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(Motion.words, value: pendant.title)

            if let leadsInto {
                Text(leadsInto)
                    .font(AppFonts.bodyFont(15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Lock Screen

enum PendantArtwork {

    /// The cross alone, rendered once for the Lock Screen while the
    /// opening and closing prayers are said
    @MainActor
    static let lockScreenImage: UIImage? = {
        let view = ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.12)
            WorkedCross(isLit: true)
                .frame(width: 560)
        }
        .frame(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }()
}

// MARK: - Preview

#Preview("Pendant") {
    HStack(spacing: 24) {
        PendantCrossView(current: .cross)
        PendantCrossView(current: .smallBead(1))
        PendantCrossView(current: .medal, isClosing: true)
    }
    .frame(height: 420)
    .padding(24)
    .background(AppColors.background)
}

#Preview("Cross") {
    WorkedCross(isLit: true)
        .frame(width: 300)
        .padding(40)
        .background(AppColors.background)
}
