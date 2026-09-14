//
//  SacredComponents.swift
//  Lumen Viae
//
//  The shared Catholic visual vocabulary: gothic arches, rosary-bead
//  progress, ornamental dividers, illuminated drop caps, and corner
//  flourishes. Kept deliberately restrained — structure over clutter.
//

import SwiftUI

// MARK: - Smooth Ramps

extension Gradient {

    /// Smoothstep — 3t² − 2t³. Zero slope at both ends.
    private static func smoothstep(_ t: CGFloat) -> CGFloat {
        t * t * (3 - 2 * t)
    }

    /// Sample points for the ramps below. Dense enough that the straight
    /// segments between them are shorter than the eye resolves.
    private static let rampSamples: [CGFloat] = [
        0, 0.12, 0.24, 0.36, 0.47, 0.58, 0.68, 0.77, 0.85, 0.92, 1
    ]

    /// A fade to `color` across `from`…`end` of a gradient's span, eased
    /// so neither end is a line.
    ///
    /// Two things make an image's dissolve into the page visible, and
    /// this addresses both:
    ///
    /// A two-stop ramp is smooth in the middle and has a **corner** at
    /// each end. The eye reads a corner in a gradient as a line — a Mach
    /// band — which is the very edge such a fade exists to remove. These
    /// stops follow a smoothstep, so there is no corner to find.
    ///
    /// And `end` should land **before** the image's own edge, never on
    /// it. Alpha is linear but sight is not: the last few percent of a
    /// *dark* painting showing through is nothing, while the last few
    /// percent of a bright cloud or a pale robe is a visible band right
    /// where the image stops. Finishing the fade early and holding the
    /// flat color through the edge costs a sliver of painting and makes
    /// the seam unfindable at any brightness.
    static func smoothFade(to color: Color, from: CGFloat, end: CGFloat = 1) -> Gradient {
        Gradient(stops: rampSamples.map { t in
            Gradient.Stop(
                color: color.opacity(smoothstep(t)),
                location: from + (end - from) * t
            )
        })
    }

    /// An eased mask ramping clear→black across `from`…`to`, then held to
    /// the foot.
    ///
    /// Held, deliberately, rather than tapered back out. A frost that
    /// fades away at the very bottom lets the **sharp** image underneath
    /// re-emerge for the last couple of percent — and it only reads as a
    /// seam over bright paint, where a two-percent return of a cream
    /// cloud is a visible line and the same two percent of a dark robe is
    /// nothing. Whatever covers the image below must be fully opaque
    /// before this mask reaches the foot; then the mask's own hard edge
    /// there is under it and cannot be seen.
    static func smoothMask(from: CGFloat, to: CGFloat) -> Gradient {
        Gradient(stops: rampSamples.map { t in
            Gradient.Stop(
                color: .black.opacity(smoothstep(t)),
                location: from + (to - from) * t
            )
        })
    }

    /// The inverse of `smoothMask`: held black from the top, an eased
    /// ramp black→clear across `from`…`to`, then clear to the foot.
    ///
    /// For a plate that has to end in **nothing** rather than in a flat
    /// color — a painting sitting on a page whose color it cannot know.
    /// `to` should land before the foot, so the last stretch is pure
    /// page and there is no edge anywhere for the eye to find.
    static func smoothDissolve(from: CGFloat, to: CGFloat) -> Gradient {
        Gradient(
            stops: [Gradient.Stop(color: .black, location: 0)]
                + rampSamples.map { t in
                    Gradient.Stop(
                        color: .black.opacity(1 - smoothstep(t)),
                        location: from + (to - from) * t
                    )
                }
                + [Gradient.Stop(color: .clear, location: 1)]
        )
    }
}

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
/// double-struck in gold, dissolving into the page beneath the screen's
/// own words.
///
/// One place for it so the home screen's featured mystery and the
/// consecration's day overview stay the same object.
///
/// **Nothing opaque may reach the foot.** The hero sits on the app
/// gradient, which is a different color at every height and under every
/// scroll, and an earlier draft ended in a slab of flat `background`
/// under the words with a short fade at the very bottom. Wherever that
/// slab landed on a darker stretch of the gradient it read as a lighter
/// band with a soft edge — and it landed somewhere different every time
/// the card's content grew or the phone changed, which is why the line
/// kept coming back after being "fixed". So the painting, its tint and
/// its rim are one plate, and the plate is masked to **nothing** across
/// its lower part, finishing before the foot; the words stand on the
/// page itself and are never masked. There is no flat color to mismatch,
/// so there is no edge to find, at any height, in any theme.
struct ArchHero<Content: View>: View {

    /// Asset name of the painting the arch frames
    let imageName: String

    var height: CGFloat = 410

    /// Laid over the painting, inside the plate — so it dissolves with
    /// it. A dim that deepens downward on the home card, so the words
    /// have ground where the painting is still showing through; the
    /// phase's own hue on the consecration screen.
    var tint: AnyShapeStyle = AnyShapeStyle(
        LinearGradient(
            colors: [Color.black.opacity(0.18), Color.black.opacity(0.62)],
            startPoint: .top,
            endPoint: .bottom
        )
    )

    var spacing: CGFloat = 16

    var contentPadding = EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)

    /// Steady, not pulsing — the same presence the Pray medallion and the
    /// narration transport carry. On by default; the consecration hero
    /// keeps it off.
    var showsHalo: Bool = true

    @ViewBuilder let content: Content

    private var arch: GothicArchShape { GothicArchShape(riseRatio: 0.34) }

    var body: some View {
        ZStack(alignment: .bottom) {
            plate
                .mask(plateDissolve)
                // Steady, not pulsing — the same presence the Pray
                // medallion and the narration transport carry. On the
                // plate alone: applied over the words too, the words
                // would be the only opaque thing low on the card and
                // would grow a glow of their own.
                .modifier(OptionalHalo(active: showsHalo))

            // The words, on the page itself. No scrim: the plate's own
            // tint deepens where they stand, and by the button the
            // painting is all but gone.
            VStack(spacing: spacing) { content }
                .padding(contentPadding)
        }
        .frame(height: height)
    }

    /// The painting in its arch, its tint, and the two gold rims — one
    /// layer, so one mask dissolves all of it together. The image goes
    /// in .overlay so it never expands layout bounds.
    private var plate: some View {
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
                    .strokeBorder(AppColors.gold.opacity(0.15), lineWidth: AppLine.hairline)
            )
    }

    /// Whole through the arch's upper third, then an eased fade to
    /// nothing that finishes a tenth short of the foot. The plate is
    /// still three-quarters there behind the title and a fifth there
    /// behind the button; the last stretch is pure page. See the type's
    /// note for why it must be nothing and not a color.
    private var plateDissolve: some View {
        LinearGradient(
            gradient: .smoothDissolve(from: 0.32, to: 0.90),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// `haloGlow` behind a switch, so a hero can drop it without the call
/// site branching on two otherwise identical view trees.
///
/// The glow ends where its shape ends: a halo cast by a silhouette that
/// dissolves toward the foot still pools light below it, so the glow —
/// and only the glow — is trimmed there. The trim is opaque rather than
/// a second pass of the plate's own dissolve: masking the same fade
/// twice would multiply it by itself and steepen a hand-tuned ramp.
private struct OptionalHalo: ViewModifier {
    let active: Bool

    private static let radius: CGFloat = 16

    /// How far the glow may spread past the shape on the apex and sides.
    /// `haloGlow`'s outer shadow reaches `radius * 2.2`; this leaves it
    /// room and stays tied to the radius it belongs to.
    private static var bleed: CGFloat { radius * 5 }

    func body(content: Content) -> some View {
        if active {
            content
                .haloGlow(AppColors.gold, radius: Self.radius, intensity: 0.18)
                .mask(
                    Rectangle()
                        .fill(.black)
                        .padding(.top, -Self.bleed)
                        .padding(.horizontal, -Self.bleed)
                )
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

    /// Whether the active bead breathes. Off where another strand on the
    /// same screen already carries the living bead — two things
    /// breathing on one page is one too many.
    var breathes: Bool = true

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

    private func bead(at index: Int) -> some View {
        RosaryBead(
            state: index < completed ? .prayed : (index == activeIndex ? .active : .ahead),
            size: beadSize,
            breathes: breathes
        )
    }
}

// MARK: - RosaryBead

/// Where one bead stands: already prayed, under the hand, or still to
/// come.
enum RosaryBeadState {
    case prayed
    case active
    case ahead
}

/// One bead of a strand, drawn the same way wherever a strand is drawn —
/// the mysteries across the player's head, the whole Rosary at its
/// edge, the mysteries offered on the Scriptural Rosary's page.
///
/// One view whose parts light and dim, rather than three views swapped
/// by state: a bead leaving the hand fills gold as its ring fades onto
/// the next, under whatever animation the move was made with. Swapped
/// views would blink from one state to the other and the strand would
/// read as a counter rather than a string.
struct RosaryBead: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: RosaryBeadState
    var size: CGFloat = 9

    /// An Our Father bead on the long strand: larger than its Hail
    /// Marys, and ringed in gold rather than grey while still to come,
    /// so the next decade can be seen approaching up the string.
    var isOurFather: Bool = false

    /// Whether the active bead breathes (see `RosaryBeadProgress`)
    var breathes: Bool = true

    var body: some View {
        let active = state == .active
        let prayed = state == .prayed
        let ahead = state == .ahead
        let drawn = active ? size + 3 : size

        ZStack {
            // Still to come: an outline on a dark fill
            Circle()
                .fill(AppColors.background.opacity(0.9))
                .overlay(
                    Circle().strokeBorder(
                        isOurFather ? AppColors.gold.opacity(0.6) : AppColors.textSecondary.opacity(0.4),
                        lineWidth: isOurFather ? 1.2 : 1
                    )
                )
                .opacity(ahead ? 1 : 0)

            // Prayed: a gold disc
            Circle()
                .fill(AppColors.goldGradient)
                .opacity(prayed ? 1 : 0)

            // Under the hand: a bright ring on a lit fill
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.35))
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1.2)
            }
            .opacity(active ? 1 : 0)
        }
        .frame(width: drawn, height: drawn)
        .shadow(
            color: AppColors.gold.opacity(active ? 0.5 : (prayed ? 0.55 : 0)),
            radius: active ? (isOurFather ? 6 : 4) : (prayed ? (isOurFather ? 5 : 3) : 0)
        )
        // Breathing slowly while under the hand — still when Reduce
        // Motion is on, or where the screen has asked for a still bead.
        // Toggled by `repeating` rather than by wrapping the view, so the
        // bead keeps its identity and the fades above are never cut off
        // by the ring arriving.
        .keyframeAnimator(
            initialValue: 1.0,
            repeating: active && breathes && !reduceMotion
        ) { view, scale in
            view.scaleEffect(scale)
        } keyframes: { _ in
            CubicKeyframe(1.18, duration: 0.7)
            CubicKeyframe(1.0, duration: 0.7)
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

    /// Below this many characters the opening is set plain. Book IV of
    /// the Imitation prints "The Voice of the Disciple" above the prose,
    /// and eighteen of its chapters open on a rubric like it; a gilded
    /// versal on four words, with the real first sentence left plain
    /// below, reads as a misprint. A reader's own journal entry is the
    /// exception — three words of thanks still open on their letter —
    /// and passes 0.
    var minimumLength: Int = 80

    /// The versal against the body — standing proud of the first line
    /// by more than half its height, as a versal initial should. It is
    /// no longer part of that line's text box (see `illuminated`), so
    /// its size no longer costs the paragraph its rhythm.
    private var capSize: CGFloat { (bodySize * 1.6).rounded() }

    /// Air between the initial's ink and the first line's words — a
    /// hair, as a printed versal sits against its word. Measured from
    /// the ink, not the advance: the letter's own side bearing at 1.6×
    /// the body was already a visible gap before any gutter was added.
    private var gutter: CGFloat { (bodySize * 0.1).rounded() }

    var body: some View {
        if text.count >= minimumLength, let cut = VersalCut.of(text) {
            if cut.opensOnQuotation {
                gildedQuotation(cut)
            } else {
                illuminated(cut)
            }
        } else {
            plain(text)
        }
    }

    private func plain(_ string: String) -> some View {
        Text(string)
            .font(AppFonts.readingFont(bodySize))
            .foregroundColor(textColor)
            .lineSpacing(ReadingTypography.lineSpacing(for: bodySize))
    }

    /// The initial once shared the first line's text box, and its
    /// descent — twice the body's at this size — opened a hole beneath
    /// that one line that no other line had, in every reading that
    /// opened on a versal. Now the paragraph is set on its own, its
    /// first line indented by exactly the initial's width, and the
    /// initial is laid over the indent with its baseline on the first
    /// line's: a versal standing proud of the line, and the leading
    /// beneath it the same as everywhere else on the page.
    ///
    /// A paragraph that opens on a quotation is `gildedQuotation`. One
    /// that opens on an apostrophe — an elision, 'Tis — comes here: the
    /// mark stays at the body size, hung before the initial, and the
    /// letter it belongs to takes the gold.
    private func illuminated(_ cut: VersalCut) -> some View {
        let leadWidth = cut.lead.isEmpty
            ? 0
            : width(of: cut.lead, font: "EBGaramond-Regular", size: bodySize)
        let indent = inkExtent(of: cut.letter, font: "Cinzel-Regular", size: capSize) + gutter
        let space = width(of: " ", font: "EBGaramond-Regular", size: bodySize)

        return ZStack(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
            // A single space, kerned out to the indent: the one way a
            // SwiftUI Text indents its first line and no other
            (Text(cut.lead) + Text(" ").kerning(max(0, indent - space)) + Text(cut.rest))
                .font(AppFonts.readingFont(bodySize))
                .foregroundColor(textColor)
                .lineSpacing(ReadingTypography.lineSpacing(for: bodySize))

            Text(cut.letter)
                .font(AppFonts.titleFont(capSize))
                .foregroundColor(AppColors.gold)
                .padding(.leading, leadWidth)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    /// A paragraph that opens on a quotation: the opening mark itself
    /// is the illumination (`GildedQuotationMark`), and the words stand
    /// flush beside it as typed, closing mark and all. The mark used to be
    /// hung small before a gilded letter, and the gilding fell one
    /// character too late: a small “ and then a great gold B read as a
    /// misprint on every journal entry that began with a saying.
    private func gildedQuotation(_ cut: VersalCut) -> some View {
        Text(cut.wordsAfterLead)
            .font(AppFonts.readingFont(bodySize))
            .foregroundColor(textColor)
            .lineSpacing(ReadingTypography.lineSpacing(for: bodySize))
            .gildedQuotationMark(cut.lead, bodySize: bodySize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }

    /// The advance of a run — a quotation mark, a space — in the body face
    private func width(of string: String, font name: String, size: CGFloat) -> CGFloat {
        guard let font = UIFont(name: name, size: size) else { return size * 0.7 }
        return (string as NSString).size(withAttributes: [.font: font]).width
    }

    /// How far the letter's ink reaches from its origin: its left side
    /// bearing plus the width of the glyph itself, without the right
    /// side bearing an advance would add. Measured, because an I and an
    /// M are half an em apart and the indent has to fit the letter it
    /// holds — and fit it closely.
    private func inkExtent(of letter: String, font name: String, size: CGFloat) -> CGFloat {
        guard let font = UIFont(name: name, size: size) else { return size * 0.7 }
        let characters = Array(letter.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        guard CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count),
              let glyph = glyphs.first else {
            return width(of: letter, font: name, size: size)
        }
        var bounds = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(font, .horizontal, [glyph], &bounds, 1)
        return max(bounds.maxX, 0)
    }
}

// MARK: - VersalCut

/// How a paragraph opens, cut for illumination: the quotation marks it
/// may open on, the letter that takes the versal, and everything after.
/// One rule for every versal in the app — the readers', the journal's,
/// the Chapel's Reflections tile — so an entry that opens on a letter
/// is gilded everywhere it is shown, and one that opens on a digit or a
/// dash is gilded nowhere.
struct VersalCut {

    /// The marks the paragraph opens on, before its first letter. Usually
    /// empty. When they open a quotation (`opensOnQuotation`) the mark
    /// itself is gilded in place of a letter; an apostrophe is hung small
    /// before the letter instead.
    let lead: String

    /// The versal, capitalised — an initial is always a capital
    let letter: String

    /// The versal's letter as it was typed
    let typedLetter: String

    /// The paragraph after the versal
    let rest: String

    /// The paragraph after its opening marks, exactly as typed: the words
    /// that stand beside a gilded quotation mark, which is no versal and
    /// leaves the first letter its own case
    var wordsAfterLead: String { typedLetter + rest }

    private static let openingQuotes: Set<Character> = [
        "\u{201C}", "\u{2018}", "\"", "'", "«", "‹"
    ]

    /// Marks that open a quotation and nothing else
    private static let quotationOnly: Set<Character> = ["\u{201C}", "\"", "«", "‹"]

    /// Words an apostrophe opens by standing in for their first letters.
    /// A mark before one of these belongs to the word, never a quotation.
    private static let elisions: Set<String> = [
        "tis", "twas", "twere", "twill", "twould", "twixt",
        "em", "neath", "gainst", "mongst", "til", "cause"
    ]

    /// Whether the paragraph truly opens on a quotation, so the mark is
    /// the thing to gild. A double mark or a guillemet always does. A
    /// single mark does only when a closing one answers it — a ’ or '
    /// that ends a word rather than sitting inside one — because a lone
    /// apostrophe opens an elision ('Tis, ‘twas) and gilded large it
    /// read as a stray mark.
    ///
    /// The elision is recognised by its word first: a plural possessive
    /// later in the sentence ("'Tis the saints' feast") ends a word just
    /// as a closing mark does, and was taken for one.
    var opensOnQuotation: Bool {
        guard !lead.isEmpty else { return false }
        if lead.contains(where: { Self.quotationOnly.contains($0) }) { return true }
        let firstWord = wordsAfterLead.prefix { $0.isLetter }.lowercased()
        if Self.elisions.contains(firstWord) { return false }
        let characters = Array(rest)
        for (index, character) in characters.enumerated() where character == "\u{2019}" || character == "'" {
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            // Inside a word (don’t) the mark is followed by a letter
            if !(next?.isLetter ?? false) { return true }
        }
        return false
    }

    /// Nil when the paragraph does not open on a letter (after any
    /// quotation marks): such a paragraph is set plain.
    static func of(_ text: String) -> VersalCut? {
        let trimmed = text.drop { $0.isWhitespace }
        var lead = ""
        var index = trimmed.startIndex
        while index < trimmed.endIndex, openingQuotes.contains(trimmed[index]) {
            lead.append(trimmed[index])
            index = trimmed.index(after: index)
        }
        guard index < trimmed.endIndex, trimmed[index].isLetter else { return nil }
        return VersalCut(
            lead: lead,
            letter: String(trimmed[index]).uppercased(),
            typedLetter: String(trimmed[index]),
            rest: String(trimmed[trimmed.index(after: index)...])
        )
    }
}

// MARK: - GildedQuotationMark

/// The opening quotation mark gilded in place of a versal: large, in the
/// display face, hung in the margin beside the words the way a pull
/// quote's is. One drawing for `DropCapText` (a paragraph that opens on a
/// saying) and `QuotedPassageText` (a passage kept from a book), so the
/// two stand the same size on the same page.
///
/// Cinzel's quotation mark fills only the upper third of its em, so it is
/// set at twice a versal's proportion to stand as large as a versal does,
/// and lifted so its ink hangs level with the first line's.
struct GildedQuotationMark: View {
    var mark: String = "\u{201C}"
    let bodySize: CGFloat

    static func size(bodySize: CGFloat) -> CGFloat {
        (bodySize * 3.2).rounded()
    }

    /// The margin the mark hangs in; the words begin past it
    static func margin(bodySize: CGFloat) -> CGFloat {
        (size(bodySize: bodySize) * 0.42).rounded()
    }

    var body: some View {
        let size = Self.size(bodySize: bodySize)

        Text(mark)
            .font(AppFonts.titleFont(size))
            .foregroundColor(AppColors.gold)
            .offset(y: -(size * 0.14).rounded())
            .accessibilityHidden(true)
    }
}

extension View {
    /// Hangs a gilded opening mark in this block's leading margin
    func gildedQuotationMark(_ mark: String = "\u{201C}", bodySize: CGFloat) -> some View {
        padding(.leading, GildedQuotationMark.margin(bodySize: bodySize))
            .overlay(alignment: .topLeading) {
                GildedQuotationMark(mark: mark, bodySize: bodySize)
            }
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
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
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

// MARK: - Chrome fade

/// Dissolves the top of a scrolling page so content passes *behind* the
/// floating Back button and the status bar instead of colliding with them.
///
/// Pushed pages here draw a gold Back in the toolbar with no bar material
/// behind it, so without this a settings row slides up until its label sits
/// inside the word "Back" and its toggle sits under the battery. The set
/// detail page had solved this privately with its own mask; this is the
/// same idea, in one place, in the weight the home page already uses.
struct TopChromeFade: ViewModifier {

    /// Height of the dissolve — deep enough to cover the Back capsule the
    /// toolbar draws over the scroll.
    var height: CGFloat = 48

    /// How far to hold at-rest content clear of the band. Matches `height`
    /// on a pushed page, whose Back capsule overlays the scroll. A tab root
    /// has no such capsule and its content already begins below the status
    /// bar, so it passes 0 and takes the dissolve alone.
    var inset: CGFloat = 48

    func body(content: Content) -> some View {
        content
            // The band is for content *travelling* under the chrome, not
            // for content sitting at rest. Without this inset the first
            // thing on the page — which on several of these pages is the
            // title — begins inside the dissolve and renders as a ghost
            // before anyone has scrolled at all.
            .contentMargins(.top, inset, for: .scrollContent)
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black.opacity(0.06), location: 0.55),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height)

                    Rectangle().fill(.black)
                }
            )
    }
}

extension View {
    /// See `TopChromeFade`.
    func topChromeFade(height: CGFloat = 48, inset: CGFloat? = nil) -> some View {
        modifier(TopChromeFade(height: height, inset: inset ?? height))
    }
}
