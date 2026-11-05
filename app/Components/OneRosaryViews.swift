//
//  OneRosaryViews.swift
//  Lumen Viae
//
//  What the One Rosary beta (`UserSettings.oneRosaryBeta`), the simple
//  Rosary, draws: the one player every form prays on — the rail of the
//  whole Rosary at the edge (`OneRosaryRailView`), the pill at the top
//  that goes to any part of the Rosary (`RosaryStopsPill`), the speaker
//  that mutes the voice, the prayer's words in one column at one size,
//  lit line by line where the recording is timed (`SimpleRosaryWords`),
//  and one footer of Back, play and Next (`OneRosaryFooter`), the same
//  from the first Sign of the Cross to the AMEN.
//
//  Off, none of this is drawn.
//

import SwiftUI

// MARK: - RosaryHelpLine

/// On the beginner's path (`PrayerLaunch.showsHelps`): what to do here, one plain line in the italic, in the
/// light gold of the app's guidance, so it is seen at once and still
/// reads as quieter than the prayer's upright cream; never naming what
/// the screen already names above it (`RosaryHelps.sceneFreeInstruction`).
/// No glyph: the line is the same on every step, and a mark before each
/// one repeated itself fifty times.
struct RosaryHelpLine: View {
    let line: RosaryHelps.Line

    static let lineLimit = 3

    var body: some View {
        Text(line.instruction)
            .font(AppFonts.italicFont(16.5))
            .foregroundColor(AppColors.goldLight.opacity(0.92))
            .lineSpacing(1)
            .lineLimit(Self.lineLimit)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentTransition(.opacity)
        .animation(Motion.words, value: line)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Help: \(line.instruction)", comment: "One Rosary beta, the player with Helps on: VoiceOver reading of the help line; the argument is what to do"))
    }
}

// MARK: - OneRosaryRailView

/// The whole Rosary as one rail at the right edge, drawn as a rosary
/// unrolled into one string (`OneRosaryRail`): the cross at its foot, the
/// pendant, the medal, the decades, and the medal again at its head. Read
/// one way only: prayed beads below the hand, beads to come above, the
/// place under the hand at the window's middle in a plain halo, on a quiet
/// ground of its own so it reads over any painting. A readout; the beads
/// near the hand take a tap (`oneRosaryRail(onTap:)`).
struct OneRosaryRailView: View {

    let rail: OneRosaryRail
    let activeIndex: Int
    let height: CGFloat
    var dragOffset: CGFloat = 0
    var turnPulse: Int = 0

    /// Greyed and still until the meditation has been heard
    var locked: Bool = false

    /// Beads a tap may reach (their press draws a ring of light)
    var tappable: Set<Int> = []

    /// The last step: the whole Rosary prayed, every bead gold, the
    /// cross it ends on lit
    var complete: Bool = false

    /// The hand on the closing prayers: everything but the place under
    /// it prayed, so the cross the close comes back to stands lit among
    /// gold beads rather than ahead of them
    var closing: Bool = false

    /// A row to a bead, tall enough that every bead is a 44-point target
    /// of its own
    static let rowHeight: CGFloat = 44
    static let beadColumn = RosaryStrandView.beadColumn
    static let trailingRoom = RosaryStrandView.trailingRoom

    /// Room for the decades' numerals beside the bead column
    static let width: CGFloat = 64

    /// Where the rail's window begins, from the top of the glass: lower
    /// than the strand's, and lowered with the words (`OneRosaryColumn
    /// .wordsTop`), so the hand's bead stays level with them
    static func windowTop(fullHeight: CGFloat) -> CGFloat {
        fullHeight * 0.38
    }

    /// The window's height: about half the glass, and never past the top
    /// of Back and Next, cut to an odd number of rows, so with the hand at
    /// the middle both edges fall on the gap between two beads and never
    /// through one
    static func windowHeight(fullHeight: CGFloat) -> CGFloat {
        let room = min(fullHeight * 0.52, fullHeight * 0.8 + rowHeight - windowTop(fullHeight: fullHeight))
        var rows = Int((room / rowHeight).rounded(.down))
        if rows % 2 == 0 { rows -= 1 }
        return CGFloat(max(rows, 3)) * rowHeight
    }

    /// The window's fade at each end, as fractions of its height: clear
    /// over the outermost row, coming in across the gap after it, so no
    /// bead or numeral is ever drawn half
    static func fadeStops(height: CGFloat) -> (clear: CGFloat, solid: CGFloat) {
        let h = max(height, 1)
        return ((rowHeight - 2) / h, (rowHeight + 8) / h)
    }

    /// Once, with the hint that the beads take a tap: a ring sent out
    /// from the next bead
    var hintPulse: Int = 0

    var body: some View {
        let rowFromTop = rail.count - 1 - activeIndex
        let restingOffset = height / 2 - Self.rowHeight / 2 - CGFloat(rowFromTop) * Self.rowHeight

        ZStack(alignment: .topTrailing) {
            // The rail's own ground: a soft shade under the beads, clear
            // at its sides and, with the window's fade, at both ends, so
            // it reads as a shadow on the painting and never as a bar
            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.7), location: 0.5),
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Self.beadColumn + 56, height: height)
            .padding(.trailing, Self.trailingRoom - 28)

            VStack(spacing: 0) {
                ForEach((0..<rail.count).reversed(), id: \.self) { index in
                    row(at: index)
                }
            }
            // The chain runs from the cross to the last bead and no
            // further: one string, a firm gold line between the beads
            .background(alignment: .trailing) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.6))
                    .frame(width: 1.5)
                    .padding(.vertical, Self.rowHeight / 2)
                    .padding(.trailing, Self.beadColumn / 2 - 0.75)
            }
            .offset(y: restingOffset + dragOffset)
            .padding(.trailing, Self.trailingRoom)
            .saturation(locked ? 0 : 1)
            .opacity(locked ? 0.8 : 1)
            .animation(Motion.beadSlide, value: activeIndex)

            DecadeTurnRipple(trigger: turnPulse)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
                .offset(y: height / 2 - Self.rowHeight / 2)
                .padding(.trailing, Self.trailingRoom)

            // The next bead, one row above the hand, rings once with the
            // tap hint, so the hint's words have a bead to point at
            DecadeTurnRipple(trigger: hintPulse)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
                .offset(y: height / 2 - Self.rowHeight * 1.5)
                .padding(.trailing, Self.trailingRoom)

            if locked {
                StrandLockGlyph()
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .frame(width: Self.beadColumn, height: Self.rowHeight)
                    .offset(y: height / 2 - Self.rowHeight / 2)
                    .padding(.trailing, Self.trailingRoom)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.5), value: locked)
        .frame(width: Self.width + Self.trailingRoom, height: height, alignment: .topTrailing)
        .clipped()
        .mask {
            let fade = Self.fadeStops(height: height)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: fade.clear),
                    .init(color: .black, location: fade.solid),
                    .init(color: .black, location: 1 - fade.solid),
                    .init(color: .clear, location: 1 - fade.clear),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .devotionalEntrance(delay: 0.18, drift: -16)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A position's state: on the close every place but the hand's has
    /// been prayed, the cross the close comes back to included
    static func state(at index: Int, active: Int, complete: Bool, closing: Bool) -> RosaryBeadState {
        if complete { return .prayed }
        if index == active { return .active }
        if closing || index < active { return .prayed }
        return .ahead
    }

    private func row(at index: Int) -> some View {
        let kind = rail.kinds[index]
        let state = Self.state(at: index, active: activeIndex, complete: complete, closing: closing)

        return HStack(spacing: 0) {
            Spacer(minLength: 0)

            if let label = rail.label(at: index) {
                Text(label.uppercased())
                    .font(label.count > 1 ? AppFonts.labelFont(11) : AppFonts.headlineFont(19))
                    .tracking(1.2)
                    .foregroundColor(AppColors.goldLight)
                    .lineLimit(1)
                    .fixedSize()
                    .shadow(color: .black.opacity(0.8), radius: 3)
                    .padding(.trailing, 12)
            }

            bead(kind, state: state)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
        }
        .frame(width: Self.width, height: Self.rowHeight)
    }

    @ViewBuilder
    private func bead(_ kind: OneRosaryRail.Kind, state: RosaryBeadState) -> some View {
        switch kind {
        case .cross:
            RailCross(state: state, glows: complete || (closing && state == .active))
        case .medal, .centrepiece:
            RailMedal(state: state)
        case .largeBead, .ourFather, .end:
            RailBead(state: state, size: 22)
        case .smallBead, .hailMary:
            RailBead(state: state, size: 16)
        }
    }
}

/// A bead of the rail, in three states that never look alike, over any
/// painting: a bead to come is a clear cream outline round a dark fill,
/// a prayed bead is solid gold with no edge of its own, and the bead
/// under the hand is the one bright bead inside a halo of light and a
/// ring, plain at arm's length
private struct RailBead: View {
    let state: RosaryBeadState
    let size: CGFloat

    var body: some View {
        let active = state == .active
        ZStack {
            // The halo: the bead under the hand alone
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.goldLight.opacity(0.55), AppColors.goldLight.opacity(0)],
                        center: .center,
                        startRadius: size / 2,
                        endRadius: size / 2 + 16
                    )
                )
                .frame(width: size + 32, height: size + 32)
                .opacity(active ? 1 : 0)
            Circle()
                .strokeBorder(AppColors.goldLight, lineWidth: 2)
                .frame(width: size + 12, height: size + 12)
                .opacity(active ? 1 : 0)
                .scaleEffect(active ? 1 : 0.7)

            switch state {
            case .ahead:
                Circle()
                    .fill(AppColors.backgroundDeep.opacity(0.92))
                    .overlay(Circle().strokeBorder(AppColors.cream.opacity(0.88), lineWidth: 1.5))
                    .frame(width: size, height: size)
            case .prayed:
                // Solid, with a dark rim of its own, so a prayed bead
                // reads as done over the brightest gold in a painting
                Circle()
                    .fill(AppColors.gold)
                    .overlay(Circle().strokeBorder(AppColors.backgroundDeep.opacity(0.55), lineWidth: 1))
                    .frame(width: size, height: size)
            case .active:
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: size + 2, height: size + 2)
            }
        }
        .frame(width: size + 12, height: size + 12)
    }
}

/// A rail bead's press: the bead itself swells, solid and bright, and the
/// step it goes to is named for as long as the finger is down ("Hail Mary
/// · 6 of 10"), on one line to the left of the rail, level with the
/// finger: never over another bead, and never off the glass's edge
private struct RailBeadPressStyle: ButtonStyle {
    let lines: [String]

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .overlay {
                ZStack {
                    Circle()
                        .fill(AppColors.goldLight.opacity(0.35))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(AppColors.goldLight)
                        .frame(width: 28, height: 28)
                        .shadow(color: AppColors.goldLight.opacity(0.9), radius: 8)
                }
                .scaleEffect(pressed ? 1 : 0.55)
                .opacity(pressed ? 1 : 0)
                .allowsHitTesting(false)
            }
            // The step's name to the left of the bead, its trailing edge a
            // gap clear of the press's 44-point light
            .overlay(alignment: .trailing) {
                Text(lines.joined(separator: " · ").uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(1.3)
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColors.backgroundDeep.opacity(0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline))
                )
                .fixedSize()
                .alignmentGuide(HorizontalAlignment.trailing) { $0[.trailing] + 52 }
                .opacity(pressed ? 1 : 0)
                .allowsHitTesting(false)
            }
            .animation(Motion.settle, value: pressed)
    }
}

/// The cross at the rail's foot: the budded cross, in the rail's three
/// states — quiet cream to come, gold once prayed, and lit in a halo
/// under the hand, as it is at the first Sign of the Cross and again at
/// the last
private struct RailCross: View {
    let state: RosaryBeadState
    var glows: Bool = false

    var body: some View {
        let lit = state == .active || glows
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.goldLight.opacity(0.45), AppColors.goldLight.opacity(0)],
                        center: .center, startRadius: 6, endRadius: 30)
                )
                .frame(width: 60, height: 60)
                .opacity(lit ? 1 : 0)
            BuddedCross()
                .fill(fill)
                .frame(width: lit ? 28 : 25, height: lit ? 39 : 35)
                .shadow(color: AppColors.goldLight.opacity(lit ? 0.8 : 0), radius: lit ? 6 : 0)
        }
    }

    private var fill: Color {
        if glows { return AppColors.goldLight }
        switch state {
        case .ahead: return AppColors.cream.opacity(0.72)
        case .prayed: return AppColors.gold
        case .active: return AppColors.goldLight
        }
    }
}

/// The centrepiece, drawn as the medal it is and never as a bead: an
/// oval of metal hung from its ring, with an engraved rim and a small
/// cross struck on its face, as the page's drawing hangs it. Always
/// solid, so it is never read as a bead to come (a hollow oval beside a
/// hollow ring read as a second large bead); quiet cream before the hand
/// reaches it, gold once passed, lit in a halo under the hand. Its size
/// never changes with its state: only its light does.
private struct RailMedal: View {
    let state: RosaryBeadState

    var body: some View {
        let active = state == .active
        let metal: Color = {
            switch state {
            case .ahead: return AppColors.cream.opacity(0.78)
            case .prayed: return AppColors.gold
            case .active: return AppColors.goldLight
            }
        }()
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [AppColors.goldLight.opacity(0.5), AppColors.goldLight.opacity(0)],
                        center: .center, startRadius: 8, endRadius: 28)
                )
                .frame(width: 56, height: 60)
                .opacity(active ? 1 : 0)

            VStack(spacing: -1) {
                // The ring it hangs by
                Circle()
                    .strokeBorder(metal, lineWidth: 1.5)
                    .frame(width: 6, height: 6)
                ZStack {
                    Ellipse()
                        .fill(metal)
                    // The engraved rim
                    Ellipse()
                        .strokeBorder(AppColors.backgroundDeep.opacity(0.7), lineWidth: 1)
                        .padding(2.5)
                    // The cross struck on its face
                    MedalCross()
                        .fill(AppColors.backgroundDeep.opacity(0.75))
                        .frame(width: 8, height: 11)
                }
                .frame(width: 21, height: 28)
                .overlay(Ellipse().strokeBorder(AppColors.backgroundDeep.opacity(0.5), lineWidth: 0.75))
            }
            .shadow(color: AppColors.goldLight.opacity(active ? 0.8 : 0), radius: active ? 6 : 0)
        }
        .frame(width: 30, height: 40)
    }
}

/// The small Latin cross struck on the medal's face
private struct MedalCross: Shape {
    func path(in rect: CGRect) -> Path {
        let bar = rect.width * 0.3
        var path = Path()
        path.addRect(CGRect(x: rect.midX - bar / 2, y: rect.minY, width: bar, height: rect.height))
        path.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.28, width: rect.width, height: bar))
        return path
    }
}

extension View {

    /// Hangs the One Rosary rail at the strand's own place
    /// (`rosaryStrand(_:)`): the same window, the bead column the same
    /// distance in from the glass, so a hand that learned the strand
    /// finds the rail where the strand was.
    ///
    /// - Parameter onTap: A tap on a bead near the hand, by its rail
    ///   position; only the positions in `tappable` answer
    func oneRosaryRail(
        _ rail: OneRosaryRail,
        activeIndex: Int,
        fullHeight: CGFloat,
        topInset: CGFloat,
        dragOffset: CGFloat = 0,
        turnPulse: Int = 0,
        locked: Bool = false,
        tappable: Set<Int> = [],
        hintPulse: Int = 0,
        complete: Bool = false,
        closing: Bool = false,
        onTap: @escaping (Int) -> Void
    ) -> some View {
        let windowTop = max(OneRosaryRailView.windowTop(fullHeight: fullHeight) - topInset, 0)
        let windowHeight = OneRosaryRailView.windowHeight(fullHeight: fullHeight)
        let row = OneRosaryRailView.rowHeight
        let beadInset: CGFloat = 26

        return overlay(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                OneRosaryRailView(
                    rail: rail,
                    activeIndex: activeIndex,
                    height: windowHeight,
                    dragOffset: dragOffset,
                    turnPulse: turnPulse,
                    locked: locked,
                    tappable: tappable,
                    complete: complete,
                    closing: closing,
                    hintPulse: hintPulse
                )
                .padding(.top, windowTop)
                .padding(.trailing, beadInset - RosaryStrandView.trailingRoom)

                ForEach(Array(tappable).sorted(), id: \.self) { index in
                    let lines: [String] = {
                        if case .strand(let bead) = rail.target(at: index) { return rail.pressLines(strandIndex: bead) }
                        return []
                    }()
                    Button {
                        onTap(index)
                    } label: {
                        Color.clear
                            .frame(width: 44, height: row)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(RailBeadPressStyle(lines: lines))
                    .padding(.top, windowTop + windowHeight / 2 - row / 2
                        + CGFloat(activeIndex - index) * row)
                    // Centred on the bead column, which stands half its
                    // width further in than the inset
                    .padding(.trailing, beadInset + RosaryStrandView.beadColumn / 2 - 22)
                    .accessibilityHidden(true)
                }
            }
        }
    }
}

// MARK: - OneRosaryColumn

/// The prayer under the hand, set in one column that never moves: the
/// first line of the words stands at one height on every step, opening
/// to close, on both players (`wordsTop`), on the dark ground under the
/// painting. Over the words, two levels and no more: the title in the
/// display face (The Annunciation, The Opening Prayers) with where the
/// Rosary stands under it in a quiet italic ("Mystery 1 of 5", "Before
/// the first mystery"), and the step in plain small capitals, always
/// "NAME · N OF M" on one line (HAIL MARY · 4 OF 10, THE SIGN OF THE
/// CROSS · 3 OF 3). The Rosary is not named over every step: the page
/// before PRAY named it.
///
/// The words take the room left above the foot, so a long prayer scrolls
/// in it rather than shrink (`SimpleRosaryWords`).
struct OneRosaryColumn<Words: View>: View {
    let title: String
    /// Where the Rosary stands, under the title
    let place: String
    let bead: String?

    /// The beginner's path: what to pray here, over the words
    var help: RosaryHelps.Line? = nil

    /// Once: the line under the words saying the beads take a tap
    var tapHint: Bool = false

    /// What the column's words are keyed by, so a new bead's words
    /// crossfade whole in their slot
    let wordsKey: String

    @ViewBuilder let words: () -> Words

    /// The room over the words that the title, the place and the step
    /// stand in, set to its foot: the column's top is the words' height
    /// less this
    static var headHeight: CGFloat { 112 }

    /// Where the first line of the words stands, from the top of the
    /// glass: low enough that the words sit near Back and Next, with the
    /// painting's fold (`paintingFraction`) lowered with them, so the
    /// painting keeps its height and no dark band stands under a short
    /// prayer
    static func wordsTop(fullHeight: CGFloat) -> CGFloat {
        fullHeight * 0.55
    }

    /// The painting's share of the glass on the beta's players, so it
    /// has dissolved by the time the words begin
    static var paintingFraction: CGFloat { 0.65 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The head, set to its foot in a room of one height, so a
            // title on two lines grows up into the painting and the words
            // never move
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(AppFonts.headlineFont(21))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                Text(place)
                    .font(AppFonts.italicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.74))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .contentTransition(.opacity)
                    .padding(.top, 2)

                OneRosaryStepLabel(text: bead ?? " ")
                    .opacity(bead == nil ? 0 : 1)
                    .padding(.top, 12)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: Self.headHeight, alignment: .bottomLeading)

            VStack(alignment: .leading, spacing: 0) {
                if let help {
                    RosaryHelpLine(line: help)
                        .padding(.top, 12)
                        .transition(.opacity)
                }
                ZStack(alignment: .topLeading) {
                    words()
                        .id(wordsKey)
                        .transition(.opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 14)
                .animation(Motion.crossfade, value: wordsKey)

                // Under the last line, where it can cover no word
                if tapHint {
                    OneRosaryTapHint()
                        .padding(.top, 14)
                        .transition(.opacity)
                }
            }
        }
        .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.words, value: title)
        .animation(Motion.words, value: place)
        .animation(Motion.words, value: bead)
        .animation(Motion.crossfade, value: help)
        .animation(Motion.crossfade, value: tapHint)
    }

    /// Where the Rosary stands, in plain words, under the title: a
    /// mystery by its number of all of them ("Mystery 2 of 5", "Sorrow 3
    /// of 7"), and the opening and closing prayers by where they fall
    static func place(mystery: Int?, of total: Int, phase: SpokenSegment.Phase? = nil) -> String {
        let chaplet = total != 5
        if let mystery {
            return chaplet
                ? String(
                    localized: "Sorrow \(mystery + 1) of \(total)",
                    comment: "One Rosary beta, the player: under the title, which sorrow of the Seven Sorrows chaplet this is, like Sorrow 3 of 7")
                : String(
                    localized: "Mystery \(mystery + 1) of \(total)",
                    comment: "One Rosary beta, the player: under the title, which mystery of the Rosary this is, like Mystery 2 of 5")
        }
        if phase == .closing {
            return chaplet
                ? String(localized: "After the last sorrow", comment: "One Rosary beta, the player on the closing prayers of the Seven Sorrows chaplet: under the title, where they fall")
                : String(localized: "After the last mystery", comment: "One Rosary beta, the player on the closing prayers: under the title, where they fall")
        }
        return chaplet
            ? String(localized: "Before the first sorrow", comment: "One Rosary beta, the player on the opening prayers of the Seven Sorrows chaplet: under the title, where they fall")
            : String(localized: "Before the first mystery", comment: "One Rosary beta, the player on the opening prayers: under the title, where they fall")
    }

    /// The step line on the opening and closing prayers, as a decade's
    /// bead wears it: the prayer and its count, "The Apostles' Creed · 2
    /// of 7", "The Sign of the Cross · 3 of 3" (the prayer alone where no
    /// count is kept)
    static func pendantLabel(prayer: String, count: String?) -> String {
        guard let count else { return prayer }
        return "\(prayer) · \(count)"
    }

    /// The step line on a prayer of the pendant, on the opening and the
    /// close alike
    static func pendantLabel(_ pendant: SpokenPendant, count: String?) -> String {
        pendantLabel(prayer: pendant.title, count: count)
    }

    /// The prayer's words as the column sets them: quiet, so the painting
    /// still leads (`raisesShort`: a short prayer on the pendant a size
    /// up), and whole — a long prayer (the Creed) comes down a
    /// size rather than run under the foot
    static func prayerWords(_ lines: [String], size: CGFloat = 17, raisesShort: Bool = false) -> some View {
        let length = lines.joined().count
        // A short prayer of the opening or the close (the Sign of the
        // Cross, the Glory Be) is set larger, so it holds its room
        let fitted: CGFloat = length > 280 ? size - 1 : (raisesShort && length < 160 ? size + 5 : size + 1)
        let words = Rubric.paragraph(lines, size: fitted)
        return ViewThatFits(in: .vertical) {
            prayerText(words, size: fitted)
                .fixedSize(horizontal: false, vertical: true)
            prayerText(words, size: fitted)
                .minimumScaleFactor(0.5)
        }
    }

    private static func prayerText(_ words: AttributedString, size: CGFloat) -> some View {
        Text(words)
            .font(AppFonts.readingFont(size))
            .foregroundColor(AppColors.cream)
            .lineSpacing(size > 15 ? 5 : 2)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// The one label every step wears, opening, decades and close: what is
/// said here and its count, on one line ("HAIL MARY · 4 OF 10", "THE
/// APOSTLES' CREED · 2 OF 7"), in plain small capitals under the title,
/// with no ground or edge of its own, so it reads as a line of type and
/// never as a button or a field.
///
/// The words change whole: one view identified by what it shows,
/// crossfading in its slot over the one leaving (CLAUDE.md, Motion).
/// Rolled a glyph at a time, a count caught mid-change read "? OF 7".
struct OneRosaryStepLabel: View {
    let text: String

    var body: some View {
        ZStack(alignment: .leading) {
            Text(text.uppercased())
                .font(AppFonts.labelFont(12.5))
                .tracking(1.8)
                .monospacedDigit()
                .foregroundColor(AppColors.cream.opacity(0.9))
                // One line on every step: a long prayer's name comes down
                // a little rather than wrap
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .id(text)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.words, value: text)
    }
}

/// A painting's left side quietened behind the column, dissolving to
/// clear across the glass and at both ends, so the words read over any
/// painting without a slab under them; deepest where the words stand
struct OneRosaryColumnScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.9), location: 0),
                .init(color: .black.opacity(0.74), location: 0.62),
                .init(color: .black.opacity(0), location: 0.95),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.31),
                    .init(color: .black, location: 0.47),
                    .init(color: .black, location: 0.84),
                    .init(color: .clear, location: 0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - OneRosaryPendantVeil

/// On the opening and closing prayers, the mystery's painting stepped
/// back under a deeper veil, so these screens read as the Rosary's door
/// and its close rather than as the first decade; the pendant they are
/// said on is drawn once, at the rail's head
struct OneRosaryPendantVeil: View {
    var body: some View {
        AppColors.backgroundDeep.opacity(0.55)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// MARK: - OneRosaryFooter

/// Back and Next, the same two buttons on every step, opening, decades
/// and close, on both players, in the same places. Next is the way on, in
/// gold stroke and gold words; Back is quieter, in cream on a cream edge,
/// and on the first step, with nowhere to go back to, is not drawn (its
/// place kept). On the last step AMEN, the one filled gold act, takes
/// Next's place. While a voice speaks, its play and pause stands between
/// them (`play`), always in that one place.
struct OneRosaryFooter: View {
    let canGoBack: Bool
    let canGoOn: Bool
    let isLast: Bool
    var amenBeckons: Bool = false

    /// The voice's play and pause, while there is a voice to hear
    var play: OneRosaryPlayDisc? = nil

    let onBack: () -> Void
    let onNext: () -> Void
    let onAmen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            button(
                title: String(localized: "Back", comment: "One Rosary beta, the player's footer: the button back to the bead or prayer before"),
                leading: "ph-caret-left",
                trailing: nil,
                isWayOn: false,
                action: onBack
            )
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1 : 0)
            .accessibilityHidden(!canGoBack)
            .accessibilityLabel(Text("Back", comment: "One Rosary beta, the player's footer: VoiceOver name of the button back to the bead or prayer before"))

            Spacer(minLength: 8)

            if let play {
                // In a slot of the row's own height, so Back and Next stand
                // in one place whether or not a voice speaks
                play
                    .frame(width: OneRosaryPlayDisc.diameter, height: 44)
                    .transition(.opacity)
                Spacer(minLength: 8)
            }

            if isLast {
                GoldCTAButton(
                    title: String(localized: "Amen", comment: "Prayer screen, last closing prayer: the gold button that finishes the Rosary"),
                    fill: .solid,
                    prominence: .inline,
                    trailingIcon: "ph-check",
                    action: onAmen
                )
                // Next's width, at Next's place
                .frame(width: 132)
                .beckoning(amenBeckons)
                .accessibilityLabel("Amen — finish the Rosary")
                .transition(.opacity)
            } else {
                button(
                    title: String(localized: "Next", comment: "One Rosary beta, the player's footer: the button on to the next bead or prayer"),
                    leading: nil,
                    trailing: "ph-caret-right",
                    isWayOn: true,
                    action: onNext
                )
                .disabled(!canGoOn)
                .opacity(canGoOn ? 1 : 0.35)
                .transition(.opacity)
            }
        }
        .frame(minHeight: 44)
        .animation(Motion.settle, value: isLast)
        .animation(Motion.crossfade, value: play == nil)
    }

    private func button(
        title: String, leading: String?, trailing: String?, isWayOn: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leading { AppIcon(leading, size: 10) }
                Text(title.uppercased())
                    .font(AppFonts.labelFont(isWayOn ? 12 : 11))
                    .tracking(2)
                if let trailing { AppIcon(trailing, size: 10) }
            }
            // Back in cream on a cream edge, plainly there; Next in gold,
            // with the firmer edge, still the way on
            .foregroundColor(isWayOn ? AppColors.goldLight : AppColors.cream.opacity(0.88))
            .padding(.horizontal, 18)
            .frame(minWidth: isWayOn ? 132 : 104, minHeight: 44)
            .background(Capsule().fill(AppColors.background.opacity(isWayOn ? 0.7 : 0.55)))
            .overlay(
                Capsule().strokeBorder(
                    isWayOn ? AppColors.goldLight.opacity(0.9) : AppColors.cream.opacity(0.5),
                    lineWidth: isWayOn ? 1.2 : 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
    }
}

// MARK: - OneRosaryPlayDisc

/// The voice's play and pause, between Back and Next while a voice
/// speaks: on a mystery's Our Father the meditation's (heard to its end,
/// it offers to hear it again), and with the Whole Rosary the voice's.
/// Outlined in gold, so the step's one filled gold act stays AMEN's.
struct OneRosaryPlayDisc: View, Equatable {
    enum Glyph: Equatable { case play, pause, replay }

    let glyph: Glyph
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    static let diameter: CGFloat = 52

    static func == (a: Self, b: Self) -> Bool {
        a.glyph == b.glyph && a.isLoading == b.isLoading && a.isEnabled == b.isEnabled
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.background.opacity(0.7))
                    .overlay(Circle().strokeBorder(AppColors.goldLight.opacity(0.9), lineWidth: 1.2))
                if isLoading {
                    ProgressView().tint(AppColors.goldLight)
                } else {
                    AppIcon(icon, size: glyph == .replay ? 20 : 18)
                        .foregroundColor(AppColors.goldLight)
                        .contentTransition(.opacity)
                }
            }
            .frame(width: Self.diameter, height: Self.diameter)
            .contentShape(Circle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(Motion.crossfade, value: glyph)
        .accessibilityLabel(label)
    }

    private var icon: String {
        switch glyph {
        case .play: return "ph-play-fill"
        case .pause: return "ph-pause-fill"
        case .replay: return "ph-arrow-counter-clockwise"
        }
    }

    private var label: Text {
        if isLoading { return Text("Loading audio") }
        switch glyph {
        case .play: return Text("Play")
        case .pause: return Text("Pause")
        case .replay: return Text("Hear it again", comment: "One Rosary beta, the player: VoiceOver name of the button that plays the meditation again from its start, once it has been heard")
        }
    }
}

// MARK: - OneRosaryReadLink

/// On a mystery's Our Father, where its meditation is heard: the door to
/// the meditation as text, named with its title where it has one, in a
/// hairline capsule of its own so it reads as a button and not a caption
struct OneRosaryReadLink: View {
    var title: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                AppIcon("ph-book-open", size: 15)
                Text(
                    "READ THE MEDITATION",
                    comment: "One Rosary beta, the player on a mystery's Our Father: the quiet door to the meditation as text"
                )
                .font(AppFonts.labelFont(10))
                .tracking(1.6)
                if let title {
                    Text(verbatim: "·")
                    Text(title)
                        .font(AppFonts.italicFont(14))
                        .lineLimit(1)
                }
                AppIcon("ph-caret-right", size: 9)
            }
            .foregroundColor(AppColors.goldLight)
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .background(Capsule().fill(AppColors.background.opacity(0.55)))
            .overlay(Capsule().strokeBorder(AppColors.goldLight.opacity(0.5), lineWidth: 1))
            .frame(minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Read the meditation", comment: "Prayer screen: VoiceOver name of the button that opens the meditation as text"))
    }
}

// MARK: - OneRosaryTapHint

/// Once, the first time the beads can be tapped: that they can. Set in
/// the column under the prayer's last line, where it covers no word at any
/// step or text size, pointing across to the rail, whose next bead rings
/// as it comes; gone on its own after a few seconds.
struct OneRosaryTapHint: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Tap a bead on the rail to go to it.", comment: "One Rosary beta: a one-time hint under the prayer that the beads of the rail beside it can be tapped")
                .font(AppFonts.italicFont(14.5))
                .foregroundColor(AppColors.cream.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - OneRosaryHeader

/// The player's head, the same on both players: the way out alone. The
/// Rosary is named once, in the column's kicker (the mysteries and the
/// set or form), so no screen stacks a name over a name before the words.
struct OneRosaryHeader<Pill: View, Trailing: View>: View {
    let onClose: () -> Void
    /// The pill that goes to any part of the Rosary, centred
    @ViewBuilder var pill: () -> Pill
    /// The speaker, at the trailing edge
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            HStack {
                PrayerHeaderButton(
                    icon: "ph-x",
                    size: 18,
                    label: String(localized: "End prayer", comment: "Prayer screen: VoiceOver name of the close button that leaves the Rosary")
                ) {
                    onClose()
                }
                Spacer()
                trailing()
            }
            pill()
                .padding(.horizontal, 56)
        }
        .padding(.horizontal, 16)
        // The column's scrim, turned to the head: the painting quietened
        // behind the name and its line, dissolving to clear below them,
        // so the italic reads over the brightest sky
        .background(alignment: .top) {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.55), location: 0),
                    .init(color: .black.opacity(0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .padding(.top, -90)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - OneRosaryUtilityRow

/// One of the player's less used acts, under Back and Next
struct OneRosaryUtility: Identifiable {
    let id: String
    let icon: String
    /// The short name set under the glyph
    let title: String
    /// The name VoiceOver reads
    let label: String
    let action: () -> Void
}

/// The row under Back and Next, the same on both players and on every
/// step: each glyph with its name beneath (VOICE, TEXT, MORE), quieter
/// than the prayer above it. The meditation to read is a door of its own
/// on the step it belongs to (`OneRosaryReadLink`).
struct OneRosaryUtilityRow: View {
    let items: [OneRosaryUtility]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 4) {
                        AppIcon(item.icon, size: 20)
                        Text(item.title.uppercased())
                            .font(AppFonts.labelFont(9.5))
                            .tracking(1.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(AppColors.cream.opacity(0.72))
                    .frame(width: 80, height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(GoldCTAButtonStyle())
                .accessibilityLabel(item.label)
            }
        }
    }

    /// The voice, the speed and the Rosary's choices
    static func voice(_ action: @escaping () -> Void) -> OneRosaryUtility {
        OneRosaryUtility(
            id: "voice",
            // The reader, as Settings' Narration voice wears it: who reads
            // and how fast; the speaker is the Audio choice's
            icon: "lv-voice",
            title: String(localized: "Voice", comment: "Playback settings sheet: section label over the narration voices"),
            label: String(localized: "Playback settings", comment: "Prayer screen: VoiceOver name of the button that opens the voice, speed and Rosary choices"),
            action: action
        )
    }

    /// The text's size
    static func text(_ action: @escaping () -> Void) -> OneRosaryUtility {
        OneRosaryUtility(
            id: "text",
            icon: "ph-text-aa",
            title: String(localized: "Text", comment: "Meditation reader, text options sheet: its title"),
            label: String(localized: "Text options", comment: "Scriptural Rosary's prayer screen: VoiceOver name of the button that opens text size"),
            action: action
        )
    }

    /// Everything else
    static func more(_ action: @escaping () -> Void) -> OneRosaryUtility {
        OneRosaryUtility(
            id: "more",
            icon: "ph-dots-three",
            title: String(localized: "More", comment: "Prayer screen: VoiceOver name of the button that opens the menu of more actions"),
            label: String(localized: "More", comment: "Prayer screen: VoiceOver name of the button that opens the menu of more actions"),
            action: action
        )
    }
}

// MARK: - SimpleRosaryWords

/// A prayer's words as the simple Rosary sets them: every prayer at one
/// size, the Creed as the Glory Be, never shrunk to fit. A long prayer
/// scrolls in the room it has; where the recording is timed, the line
/// being said is lit and the words move to keep it in view. Untimed, no
/// line is lit and the words rest at the top: a pace is never guessed.
struct SimpleRosaryWords: View {
    let lines: [String]
    /// The line being said, from the recording's real timings; nil for
    /// none
    let highlighted: Int?
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(Rubric.paragraph([line], size: size))
                            .font(AppFonts.readingFont(size))
                            .foregroundColor(AppColors.cream)
                            .lineSpacing(5)
                            .opacity(highlighted == nil || highlighted == index ? 1 : 0.5)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(index)
                    }
                }
                .padding(.bottom, 24)
                .animation(reduceMotion ? nil : Motion.crossfade, value: highlighted)
            }
            // The foot of a long prayer dissolves under Back and Next
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.86),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onChange(of: highlighted) { _, line in
                guard let line else { return }
                if reduceMotion {
                    proxy.scrollTo(line, anchor: UnitPoint(x: 0, y: 0.3))
                } else {
                    withAnimation(Motion.crossfade) { proxy.scrollTo(line, anchor: UnitPoint(x: 0, y: 0.3)) }
                }
            }
        }
    }
}

// MARK: - RosaryStopsPill

/// The pill at the top of the player, as the Consecration's day pill is
/// drawn: where the Rosary stands in a struck capsule with a caret, over
/// a dash for each part — the opening, each mystery, the closing — the
/// one the hand is on drawn long. A tap opens every part to go to.
struct RosaryStopsPill: View {
    let stops: [RosaryStop]
    let current: RosaryStop
    let isChaplet: Bool
    let action: () -> Void

    var body: some View {
        let position = current.position(in: stops)
        Button(action: action) {
            VStack(spacing: 7) {
                HStack(spacing: 6) {
                    Text(RosaryStopsPill.label(current, of: stops, isChaplet: isChaplet).uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.cream.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    AppIcon("ph-caret-down", size: 9)
                        .foregroundColor(AppColors.gold)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppColors.background.opacity(0.55)))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 1))

                HStack(spacing: 5) {
                    ForEach(Array(stops.indices), id: \.self) { index in
                        Capsule()
                            .fill(index <= position ? AppColors.gold : AppColors.cardBackground)
                            .frame(width: index == position ? 18 : 7, height: 4)
                    }
                }
                .animation(Motion.settle, value: position)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(RosaryStopsPill.label(current, of: stops, isChaplet: isChaplet))
        .accessibilityHint(Text("Opens the parts of the Rosary, to go to any of them", comment: "Simple Rosary player: VoiceOver hint on the pill at the top"))
    }

    /// "Mystery 2 of 5", "Sorrow 3 of 7", "Opening Prayers", "Closing
    /// Prayers"
    static func label(_ stop: RosaryStop, of stops: [RosaryStop], isChaplet: Bool) -> String {
        let total = stops.filter { if case .mystery = $0 { return true } else { return false } }.count
        switch stop {
        case .opening:
            return String(localized: "Opening Prayers", comment: "Simple Rosary player: the pill at the top while the opening prayers are said")
        case .closing:
            return String(localized: "Closing Prayers", comment: "Simple Rosary player: the pill at the top while the closing prayers are said")
        case .mystery(let n):
            return isChaplet
                ? String(localized: "Sorrow \(n + 1) of \(total)", comment: "One Rosary beta, the player: under the title, which sorrow of the Seven Sorrows chaplet this is, like Sorrow 3 of 7")
                : String(localized: "Mystery \(n + 1) of \(total)", comment: "One Rosary beta, the player: under the title, which mystery of the Rosary this is, like Mystery 2 of 5")
        }
    }
}

// MARK: - RosaryStopsSheet

/// Every part of the Rosary, to go to any of them: the opening prayers,
/// each mystery by name (and its meditation's title where it says more),
/// the closing prayers. Set as the Consecration's day index is.
struct RosaryStopsSheet: View {
    let title: String
    let stops: [RosaryStop]
    let current: RosaryStop
    let mysteryNames: [String]
    var meditationTitles: [String] = []
    let isChaplet: Bool
    let onSelect: (RosaryStop) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    kicker: String(localized: "Go to", comment: "Simple Rosary: kicker over the sheet listing the parts of the Rosary to go to"),
                    title: title
                )
                ForEach(stops, id: \.self) { stop in
                    row(stop)
                }
                Spacer(minLength: 30)
            }
        }
        .sheetGround()
        .presentationDetents([.medium, .large])
    }

    private func row(_ stop: RosaryStop) -> some View {
        let isCurrent = stop == current
        let (name, detail, icon) = describe(stop)
        return Button {
            dismiss()
            onSelect(stop)
        } label: {
            SheetRow(
                name,
                detail: detail,
                icon: icon,
                accessory: isCurrent
                    ? .label(String(localized: "Here", comment: "Consecration day index sheet: small capitals at the end of the row the reader is on now"))
                    : .caret,
                isLit: isCurrent
            )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(name)
    }

    private func describe(_ stop: RosaryStop) -> (String, String?, String) {
        switch stop {
        case .opening:
            return (
                String(localized: "The Opening Prayers", comment: "Simple Rosary: the row going to the opening prayers"),
                isChaplet
                    ? String(localized: "The Sign of the Cross and the Act of Contrition", comment: "Simple Rosary: what the Seven Sorrows chaplet opens with")
                    : String(localized: "The Sign of the Cross, the Creed, an Our Father, three Hail Marys and a Glory Be", comment: "Simple Rosary: what the Rosary opens with"),
                "lv-rosary"
            )
        case .closing:
            return (
                String(localized: "The Closing Prayers", comment: "Simple Rosary: the row going to the closing prayers"),
                isChaplet
                    ? String(localized: "Three Hail Marys for her tears, the closing prayer and the Sign of the Cross", comment: "Simple Rosary: what the Seven Sorrows chaplet closes with")
                    : String(localized: "The Hail, Holy Queen, the closing prayer and the Sign of the Cross", comment: "Simple Rosary: what the Rosary closes with"),
                "lv-rosary"
            )
        case .mystery(let n):
            let name = mysteryNames.indices.contains(n) ? mysteryNames[n] : ""
            let title = meditationTitles.indices.contains(n) ? meditationTitles[n] : nil
            let differs = title.map { !$0.isEmpty && $0.caseInsensitiveCompare(name) != .orderedSame } ?? false
            let place = RosaryStopsPill.label(stop, of: stops, isChaplet: isChaplet)
            return (name, differs ? "\(place) · \(title ?? "")" : place, "ch-praying-hands")
        }
    }
}

// MARK: - SimpleRosaryMuteButton

/// The speaker at the top of the player: muted, the voice is silent and
/// the Rosary goes on at its own pace, the words lit where the recording
/// is timed
struct SimpleRosaryMuteButton: View {
    let isMuted: Bool
    let action: () -> Void

    var body: some View {
        PrayerHeaderButton(
            icon: isMuted ? "ph-speaker-slash" : "ph-speaker-high",
            size: 17,
            label: isMuted
                ? String(localized: "Unmute", comment: "Simple Rosary player: VoiceOver name of the speaker button while the voice is muted")
                : String(localized: "Mute", comment: "Simple Rosary player: VoiceOver name of the speaker button while the voice is heard"),
            tint: isMuted ? AppColors.goldLight : .white,
            action: action
        )
    }
}
