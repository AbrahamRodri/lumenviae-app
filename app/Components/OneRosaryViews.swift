//
//  OneRosaryViews.swift
//  Lumen Viae
//
//  What the One Rosary beta (`UserSettings.oneRosaryBeta`) draws: the
//  whole Rosary at a glance on its own page (`RosaryOverviewSection`),
//  and the one player both players become: the rail of the whole Rosary
//  at the edge (`OneRosaryRailView`), the prayer's words in one column
//  that never moves (`OneRosaryColumn`), the Helps line in it
//  (`RosaryHelpLine`), and one footer of Back and Next
//  (`OneRosaryFooter`), the same from the first Sign of the Cross to
//  the AMEN.
//
//  Off, none of this is drawn.
//

import SwiftUI

// MARK: - RosaryOverviewSection

/// THE ORDER OF THE ROSARY: the rosary drawn beside the order of the
/// prayer as a ruled list, opening to close. A row tapped lights the
/// beads it is prayed on, so the list and the drawing say one thing; it
/// only shows, and never changes where the Rosary begins, which the line
/// under the heading says. Nothing is lit until a row is tapped. The
/// chaplet has no drawing: the rosary drawn is the Rosary's five decades.
struct RosaryOverviewSection: View {

    let category: MysteryCategory

    /// Whether the opening and closing prayers are prayed
    let includesPendant: Bool

    /// A meditation set's own titles, under the mysteries' names
    var meditationTitles: [String] = []

    /// Where the set sits in the week, under the list
    var contextLine: String? = nil

    @State private var chosen: String?

    private var overview: RosaryOverview {
        RosaryOverview(category: category, includesPendant: includesPendant, meditationTitles: meditationTitles)
    }

    /// The drawing's width, beside the list: short enough that the first
    /// rows of the list stand clear of PRAY on the first screen
    private static let drawingWidth: CGFloat = 118

    var body: some View {
        let overview = overview
        let chosenPart = overview.parts.first { $0.id == chosen }

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(
                    "THE ORDER OF THE ROSARY",
                    comment:
                        "One Rosary beta, a Rosary's own page: heading over the order of the whole Rosary, before PRAY"
                )
                .font(AppFonts.labelFont(10.5))
                .tracking(2.2)
                .foregroundColor(AppColors.goldLight)
                .lineLimit(1)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)

                LinearGradient(
                    colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: AppLine.hairline)
                .accessibilityHidden(true)
            }

            if category != .sevenSorrows {
                Text(
                    "Tap a part to see it on the beads. PRAY always begins at the start.",
                    comment: "One Rosary beta, a Rosary's own page: the line under the order of the Rosary, saying a row only shows its beads and does not change where the Rosary begins"
                )
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
            }

            // The drawing beside the list, so a row and its beads are
            // read together; the chaplet has no drawing
            HStack(alignment: .top, spacing: 8) {
                if category != .sevenSorrows {
                    RosaryDiagram(
                        highlighted: chosenPart?.beads ?? [],
                        bracket: chosenPart.map { part in
                            if case .mystery = part.kind { return part.beads }
                            return []
                        } ?? [],
                        numbersDecades: true,
                        litDecade: chosenPart.flatMap { part in
                            if case .mystery(let number) = part.kind { return number - 1 }
                            return nil
                        },
                        matchesPendant: true
                    )
                    .frame(width: Self.drawingWidth)
                    .padding(.top, 6)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(overview.parts) { part in
                        row(part, isChosen: part == chosenPart, isLast: part == overview.parts.last)
                    }

                    Text(overview.decadeNote)
                        .font(AppFonts.italicFont(13.5))
                        .foregroundColor(AppColors.cream.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                        .padding(.horizontal, 10)

                    if let contextLine {
                        Text(contextLine)
                            .font(AppFonts.italicFont(13.5))
                            .foregroundColor(AppColors.cream.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                            .padding(.horizontal, 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(Motion.crossfade, value: chosen)
    }

    private func row(_ part: RosaryOverview.Part, isChosen: Bool, isLast: Bool) -> some View {
        Button {
            // A second tap puts the light out again
            chosen = chosen == part.id ? nil : part.id
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Group {
                    // The numeral in the drawing's own face and size, so
                    // a row and its number on the ring read as one
                    if case .mystery(let number) = part.kind {
                        Text(verbatim: "\(number)")
                            .font(AppFonts.headlineFont(isChosen ? 17 : 14))
                            .foregroundColor(isChosen ? AppColors.goldLight : AppColors.gold.opacity(0.95))
                    } else {
                        AppIcon("lv-lozenge", size: 7)
                            .foregroundColor(isChosen ? AppColors.goldLight : AppColors.gold.opacity(0.6))
                    }
                }
                .frame(width: 14, alignment: .leading)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(part.title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(isChosen ? AppColors.goldLight : AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail = part.detail {
                        Text(detail)
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.gold.opacity(isChosen && category != .sevenSorrows ? 0.16 : 0))
            )
            // The chosen row's edge, in the light its beads take in the
            // drawing beside it
            .overlay(alignment: .leading) {
                if isChosen && category != .sevenSorrows {
                    Capsule()
                        .fill(AppColors.goldLight)
                        .frame(width: 3)
                        .padding(.vertical, 6)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(height: AppLine.hairline)
                    .padding(.horizontal, 10)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .accessibilityHint(category == .sevenSorrows ? Text(verbatim: "") : Text("Shows it on the rosary", comment: "One Rosary beta, the Rosary's overview: VoiceOver hint on a part of the Rosary, which lights its beads in the drawing"))
    }
}

// MARK: - RosaryHelpLine

/// With Helps on: what to do here, one plain line, quieter than the
/// prayer and set apart from it by a short gold rule, never naming what
/// the screen already names above it (`RosaryHelps.sceneFreeInstruction`)
struct RosaryHelpLine: View {
    let line: RosaryHelps.Line

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AppIcon("ph-question", size: 15)
                .foregroundColor(AppColors.goldLight.opacity(0.85))
                .padding(.top, 2)
                .accessibilityHidden(true)

            Text(line.instruction)
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.cream.opacity(0.86))
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.backgroundDeep.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.gold.opacity(0.22), lineWidth: AppLine.hairline)
                )
        )
        .padding(.leading, -12)
        .fixedSize(horizontal: false, vertical: true)
        .contentTransition(.opacity)
        .animation(Motion.words, value: line)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Help: \(line.instruction)", comment: "One Rosary beta, the player with Helps on: VoiceOver reading of the help line; the argument is what to do"))
    }
}

// MARK: - OneRosaryRailView

/// The whole Rosary as one rail at the right edge: the pendant's cross
/// and beads, the decades, and the pendant again at the close
/// (`OneRosaryRail`). Drawn as the strand is drawn, a bead's length to a
/// row, the place under the hand at the window's middle, on a quiet
/// ground of its own so it reads over any painting. A readout; the
/// beads near the hand take a tap (`oneRosaryRail(onTap:)`).
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

    static let rowHeight = RosaryStrandView.rowHeight
    static let beadColumn = RosaryStrandView.beadColumn
    static let trailingRoom = RosaryStrandView.trailingRoom

    /// Room for the decades' numerals beside the bead column
    static let width: CGFloat = 64

    /// Where the rail's window begins, from the top of the glass: lower
    /// than the strand's, so the painting shows above the words and the
    /// band over the footer is used
    static func windowTop(fullHeight: CGFloat) -> CGFloat {
        fullHeight * 0.33
    }

    /// The window's height: about the strand's, cut to an odd number of
    /// rows, so with the hand at the middle both edges fall on the gap
    /// between two beads and never through one
    static func windowHeight(fullHeight: CGFloat) -> CGFloat {
        var rows = Int((fullHeight * 0.435 / rowHeight).rounded(.down))
        if rows % 2 == 0 { rows -= 1 }
        return CGFloat(max(rows, 3)) * rowHeight
    }

    /// The window's fade at each end, as fractions of its height: clear
    /// over the outermost row, coming in across the gap after it, so no
    /// bead or numeral is ever drawn half
    static func fadeStops(height: CGFloat) -> (clear: CGFloat, solid: CGFloat) {
        let h = max(height, 1)
        return ((rowHeight - 2) / h, (rowHeight + 6) / h)
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
            // it reads as a shadow on the painting and never as a bar;
            // a bead to come carries its own dark fill and cream edge
            LinearGradient(
                stops: [
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 0),
                    .init(color: AppColors.backgroundDeep.opacity(0.62), location: 0.5),
                    .init(color: AppColors.backgroundDeep.opacity(0), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Self.beadColumn + 52, height: height)
            .padding(.trailing, Self.trailingRoom - 26)

            VStack(spacing: 0) {
                ForEach((0..<rail.count).reversed(), id: \.self) { index in
                    row(at: index)
                }
            }
            // The chain runs from the first bead to the last and no
            // further: past the cross there is no more rosary
            .background(alignment: .trailing) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.45))
                    .frame(width: 1)
                    .padding(.vertical, Self.rowHeight / 2)
                    .padding(.trailing, Self.beadColumn / 2 - 0.5)
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

    private func row(at index: Int) -> some View {
        let state: RosaryBeadState = complete
            ? .prayed
            : (index < activeIndex ? .prayed : (index == activeIndex ? .active : .ahead))

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
                    .padding(.trailing, 10)
            }

            bead(rail.kinds[index], state: state)
                .frame(width: Self.beadColumn, height: Self.rowHeight)
        }
        .frame(width: Self.width, height: Self.rowHeight)
    }

    @ViewBuilder
    private func bead(_ kind: OneRosaryRail.Kind, state: RosaryBeadState) -> some View {
        switch kind {
        case .cross:
            RailCross(state: state, glows: complete)
        case .medal:
            RailMedal(state: state)
        case .largeBead, .ourFather, .end:
            RailBead(state: state, size: 17)
        case .smallBead, .hailMary:
            RailBead(state: state, size: 12)
        }
    }
}

/// A bead of the rail, in three states that never look alike, over any
/// painting: a bead to come is a clear cream outline round a dark fill,
/// a prayed bead is solid gold with no edge of its own, and the bead
/// under the hand is the one bright bead inside the one ring
private struct RailBead: View {
    let state: RosaryBeadState
    let size: CGFloat

    var body: some View {
        ZStack {
            // The ring: the bead under the hand alone
            Circle()
                .strokeBorder(AppColors.goldLight, lineWidth: 2)
                .frame(width: size + 12, height: size + 12)
                .opacity(state == .active ? 1 : 0)
                .scaleEffect(state == .active ? 1 : 0.7)

            switch state {
            case .ahead:
                Circle()
                    .fill(AppColors.backgroundDeep.opacity(0.92))
                    .overlay(Circle().strokeBorder(AppColors.cream.opacity(0.88), lineWidth: 1.5))
                    .frame(width: size, height: size)
            case .prayed:
                Circle()
                    .fill(AppColors.gold)
                    .frame(width: size, height: size)
            case .active:
                Circle()
                    .fill(AppColors.goldLight)
                    .frame(width: size + 1, height: size + 1)
            }
        }
        .frame(width: size + 12, height: size + 12)
    }
}

/// A rail bead's press: a soft disc of light swelling where the finger
/// is, filled and edgeless, so it is never read as the ring that marks
/// the bead under the hand
private struct RailBeadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.goldLight.opacity(0.75), AppColors.goldLight.opacity(0)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 19
                    )
                )
                .frame(width: 38, height: 38)
                .opacity(configuration.isPressed ? 1 : 0)
                .scaleEffect(configuration.isPressed ? 1 : 0.5)
                .animation(Motion.settle, value: configuration.isPressed)
                .allowsHitTesting(false)
        }
    }
}

/// The cross at the rail's foot and head: the budded cross the pendant
/// drawing above the words hangs (`BuddedCross`), so the two are plainly
/// one object, in the rail's three states — quiet cream to come, gold
/// once prayed, and lit under the hand
private struct RailCross: View {
    let state: RosaryBeadState
    var glows: Bool = false

    var body: some View {
        let lit = state == .active || glows
        // The budded cross is slender, so it is told by its fill alone:
        // a quiet cream to come, gold prayed, lit under the hand
        BuddedCross()
            .fill(fill)
            .frame(width: lit ? 24 : 21, height: lit ? 33 : 29)
            .shadow(color: AppColors.goldLight.opacity(lit ? 0.8 : 0), radius: lit ? 6 : 0)
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

/// The centrepiece, oval as the pendant drawing draws it, in the rail's
/// three states
private struct RailMedal: View {
    let state: RosaryBeadState

    var body: some View {
        let active = state == .active
        ZStack {
            Ellipse()
                .strokeBorder(AppColors.goldLight, lineWidth: 2)
                .frame(width: 26, height: 31)
                .opacity(active ? 1 : 0)
            Ellipse()
                .fill(
                    state == .ahead
                        ? AppColors.backgroundDeep.opacity(0.92)
                        : (active ? AppColors.goldLight : AppColors.gold))
                .overlay(
                    Ellipse().strokeBorder(
                        AppColors.cream.opacity(state == .ahead ? 0.88 : 0), lineWidth: 1.5)
                )
                .frame(width: 14, height: 18)
        }
        .frame(width: 26, height: 31)
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
        onTap: @escaping (Int) -> Void
    ) -> some View {
        let windowTop = max(OneRosaryRailView.windowTop(fullHeight: fullHeight) - topInset, 0)
        let windowHeight = OneRosaryRailView.windowHeight(fullHeight: fullHeight)
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
                    hintPulse: hintPulse
                )
                .padding(.top, windowTop)
                .padding(.trailing, beadInset - RosaryStrandView.trailingRoom)

                ForEach(Array(tappable).sorted(), id: \.self) { index in
                    Button {
                        onTap(index)
                    } label: {
                        Color.clear
                            .frame(width: 44, height: RosaryStrandView.rowHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(RailBeadPressStyle())
                    .padding(.top, windowTop + windowHeight / 2 - RosaryStrandView.rowHeight / 2
                        + CGFloat(activeIndex - index) * RosaryStrandView.rowHeight)
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

/// The prayer under the hand, set in one column that never moves: its
/// head level with the top of the rail's window, clear of the rail. Two
/// levels before the words: one kicker naming the Rosary (the mysteries
/// and the set or form, JOYFUL MYSTERIES · THE GOSPEL), and the title in
/// the display face beside its number, as the order of the Rosary on its
/// own page sets it (1 The Annunciation, ◆ The Opening Prayers). Then the
/// bead in small capitals (HAIL MARY · 4 OF 10), the words — the bead's
/// prayer, or the Scriptural Rosary's verse — and, with Helps on, one
/// quiet line. The same on every step and on both players.
struct OneRosaryColumn<Words: View>: View {
    let kicker: String
    let title: String
    /// The mystery's number beside the title; nil on the opening and
    /// closing prayers, which wear the overview's lozenge
    var number: Int? = nil
    let bead: String?
    var help: RosaryHelps.Line? = nil

    /// Once: the line under the words saying the beads take a tap
    var tapHint: Bool = false

    /// Whether the words stand a third of the way down the room left to
    /// them rather than under the label (the opening and closing
    /// prayers); the column must then be given the room's height
    var balancesWords: Bool = false

    /// What the column's words are keyed by, so a new bead's words
    /// crossfade whole in their slot
    let wordsKey: String

    @ViewBuilder let words: () -> Words

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(kicker.uppercased())
                .font(AppFonts.labelFont(10.5))
                .tracking(1.4)
                .foregroundColor(AppColors.gold.opacity(0.95))
                // One line on every step, so the title never moves
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Group {
                    if let number {
                        Text(verbatim: "\(number)")
                            .font(AppFonts.headlineFont(20))
                            .foregroundColor(AppColors.goldLight)
                            .contentTransition(.opacity)
                    } else {
                        // Centred on the capitals beside it, as the
                        // order of the Rosary sets it beside a row
                        AppIcon("lv-lozenge", size: 11)
                            .foregroundColor(AppColors.goldLight)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 2 }
                    }
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            .padding(.top, 6)

            // The label's words stand on the column's edge, its ground
            // reaching out past them
            OneRosaryStepLabel(text: bead ?? " ")
                .opacity(bead == nil ? 0 : 1)
                .padding(.leading, -12)
                .padding(.top, 12)

            // On the opening and closing prayers, which stand on the dark
            // ground and are often short, the words are set a third of
            // the way down the room left above the foot, so a Sign of the
            // Cross leaves no dead band beneath it; a long prayer fills
            // the room as it did
            if balancesWords {
                Spacer(minLength: 6)
            }

            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    words()
                        .id(wordsKey)
                        .transition(.opacity)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, balancesWords ? 0 : 12)
                .animation(Motion.crossfade, value: wordsKey)

                if let help {
                    RosaryHelpLine(line: help)
                        .padding(.top, 14)
                        .transition(.opacity)
                }

                // Under the last line, where it can cover no word
                if tapHint {
                    OneRosaryTapHint()
                        .padding(.top, 14)
                        .transition(.opacity)
                }
            }

            if balancesWords {
                Spacer(minLength: 0)
                Spacer(minLength: 0)
            }
        }
        .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.words, value: kicker)
        .animation(Motion.words, value: title)
        .animation(Motion.words, value: bead)
        .animation(Motion.crossfade, value: help)
        .animation(Motion.crossfade, value: tapHint)
    }

    /// The one kicker over every step: the mysteries and what was chosen
    /// to pray them with, the meditation set or the form
    static func kicker(mysteries: String?, chosen: String) -> String {
        guard let mysteries, !mysteries.isEmpty else { return chosen }
        guard !chosen.isEmpty else { return mysteries }
        return "\(mysteries) · \(chosen)"
    }

    /// The label on the opening and closing prayers, as a decade's
    /// bead wears it: the prayer and its count, "The Apostles' Creed · 2
    /// of 7" (the prayer alone where no count is kept)
    static func pendantLabel(prayer: String, count: String?) -> String {
        guard let count else { return prayer }
        return "\(prayer) · \(count)"
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
/// APOSTLES' CREED · 2 OF 7"), in full cream at the size of a row's
/// name, on a solid ground of its own with a gold edge.
///
/// The ground keeps one width, the column's, whatever it says, and the
/// words change whole: one view identified by what it shows, crossfading
/// in its slot over the one leaving (CLAUDE.md, Motion). Rolled a glyph at
/// a time, a count caught mid-change read "? OF 7", and the capsule
/// re-wrapped from step to step.
struct OneRosaryStepLabel: View {
    let text: String

    var body: some View {
        ZStack(alignment: .leading) {
            Text(text.uppercased())
                .font(AppFonts.labelFont(13))
                .tracking(1.5)
                .monospacedDigit()
                .foregroundColor(AppColors.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .id(text)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(AppColors.backgroundDeep.opacity(0.94))
                .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.32), lineWidth: AppLine.hairline))
        )
        .animation(Motion.words, value: text)
    }
}

/// A painting's left side quietened behind the column, dissolving to
/// clear across the glass and at both ends, so the words read over any
/// painting without a slab under them
struct OneRosaryColumnScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.86), location: 0),
                .init(color: .black.opacity(0.68), location: 0.62),
                .init(color: .black.opacity(0), location: 0.95),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.18),
                    .init(color: .black, location: 0.31),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 0.92),
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
/// gold stroke and gold words; Back is quieter, grey, and on the first
/// step, with nowhere to go back to, is not drawn (its place kept). On
/// the last step AMEN, the one filled gold act, takes Next's place.
struct OneRosaryFooter: View {
    let canGoBack: Bool
    let canGoOn: Bool
    let isLast: Bool
    var amenBeckons: Bool = false
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
            .foregroundColor(isWayOn ? AppColors.goldLight : AppColors.cream.opacity(0.62))
            .padding(.horizontal, 18)
            .frame(minWidth: isWayOn ? 132 : 104, minHeight: 44)
            .background(Capsule().fill(AppColors.background.opacity(isWayOn ? 0.7 : 0.45)))
            .overlay(
                Capsule().strokeBorder(
                    isWayOn ? AppColors.goldLight.opacity(0.9) : AppColors.cream.opacity(0.22),
                    lineWidth: isWayOn ? 1.2 : AppLine.hairline)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
    }
}

// MARK: - OneRosaryReadLink

/// On a mystery's Our Father, where its meditation is heard: a quiet door
/// to the meditation as text, named with its title where it has one
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
            .foregroundColor(AppColors.goldLight.opacity(0.9))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
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
                .font(AppFonts.italicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            AppIcon("ph-caret-right", size: 10)
                .foregroundColor(AppColors.goldLight)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - OneRosaryHeader

/// The player's head, the same on both players: the way out alone. The
/// Rosary is named once, in the column's kicker (the mysteries and the
/// set or form), so no screen stacks a name over a name before the words.
struct OneRosaryHeader: View {
    let onClose: () -> Void

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
            }
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
            icon: "ph-faders",
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
