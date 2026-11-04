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

/// THE WHOLE ROSARY: the rosary drawn large, over the order of the
/// prayer as a ruled list, opening to close. A row chosen lights the
/// beads it is prayed on, so the list and the drawing say one thing; the
/// opening is chosen to begin with. The chaplet has no drawing: the
/// rosary drawn is the Rosary's five decades.
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

    /// With the beta, the Helps choice: set under the heading, over the
    /// drawing and the list, so it is seen before the list and near PRAY
    var helps: AnyView? = nil

    /// The drawing's width, beside the list: short enough that the first
    /// rows of the list stand clear of PRAY on the first screen
    private static let drawingWidth: CGFloat = 132

    var body: some View {
        let overview = overview
        let chosenPart = overview.parts.first { $0.id == chosen } ?? overview.parts.first

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(
                    "THE WHOLE ROSARY",
                    comment:
                        "One Rosary beta, a Rosary's own page: heading over the order of the whole Rosary, before PRAY"
                )
                .font(AppFonts.labelFont(10.5))
                .tracking(2.2)
                .foregroundColor(AppColors.goldLight)
                .accessibilityAddTraits(.isHeader)

                LinearGradient(
                    colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: AppLine.hairline)
                .accessibilityHidden(true)
            }

            if let helps {
                helps
                    .padding(.bottom, 4)
            }

            // The drawing beside the list, so a row and its beads are
            // read together; the chaplet has no drawing
            HStack(alignment: .top, spacing: 14) {
                if category != .sevenSorrows {
                    RosaryDiagram(
                        highlighted: chosenPart?.beads ?? [],
                        bracket: chosenPart?.beads ?? [],
                        bracketLabel: chosenPart.flatMap { part in
                            if case .mystery(let number) = part.kind { return "\(number)" }
                            return nil
                        }
                    )
                    .frame(width: Self.drawingWidth)
                    .padding(.top, 6)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(overview.parts) { part in
                        row(part, isChosen: part == chosenPart, isLast: part == overview.parts.last)
                    }

                    Text(overview.decadeNote)
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.cream.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .padding(.horizontal, 10)

                    if let contextLine {
                        Text(contextLine)
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.cream.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                            .padding(.horizontal, 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, 18)
        .animation(Motion.crossfade, value: chosen)
    }

    private func row(_ part: RosaryOverview.Part, isChosen: Bool, isLast: Bool) -> some View {
        Button {
            chosen = part.id
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Group {
                    if case .mystery(let number) = part.kind {
                        Text(verbatim: "\(number)")
                            .font(AppFonts.labelFont(isChosen ? 12 : 11))
                            .foregroundColor(isChosen ? AppColors.goldLight : AppColors.gold.opacity(0.85))
                    } else {
                        AppIcon("lv-lozenge", size: 7)
                            .foregroundColor(isChosen ? AppColors.goldLight : AppColors.gold.opacity(0.6))
                    }
                }
                .frame(width: 12, alignment: .leading)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(part.title)
                        .font(AppFonts.bodyFont(16))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail = part.detail {
                        Text(detail)
                            .font(AppFonts.italicFont(13.5))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.gold.opacity(isChosen && category != .sevenSorrows ? 0.08 : 0))
            )
            // The chosen row's edge, in the light its beads take in the
            // drawing beside it
            .overlay(alignment: .leading) {
                if isChosen && category != .sevenSorrows {
                    Capsule()
                        .fill(AppColors.goldLight)
                        .frame(width: 2)
                        .padding(.vertical, 8)
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
            Rectangle()
                .fill(AppColors.gold.opacity(0.6))
                .frame(width: 1.5)
                .padding(.vertical, 2)
                .accessibilityHidden(true)

            Text(line.instruction)
                .font(AppFonts.italicFont(15.5))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .shadow(color: .black.opacity(0.6), radius: 5, y: 1)
        .contentTransition(.opacity)
        .animation(Motion.words, value: line)
        .accessibilityElement(children: .combine)
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

    /// The window's height, as the strand's
    static func windowHeight(fullHeight: CGFloat) -> CGFloat {
        fullHeight * 0.435
    }

    /// Once, with the hint that the beads take a tap: a ring sent out
    /// from the next bead
    var hintPulse: Int = 0

    var body: some View {
        let rowFromTop = rail.count - 1 - activeIndex
        let restingOffset = height / 2 - Self.rowHeight / 2 - CGFloat(rowFromTop) * Self.rowHeight

        ZStack(alignment: .topTrailing) {
            // The rail's own ground: a column of the page's dark, deep
            // enough that no bead is read against a face, dissolving at
            // both ends with the window
            Capsule()
                .fill(AppColors.backgroundDeep.opacity(0.82))
                .frame(width: Self.beadColumn + 18, height: height)
                .padding(.trailing, Self.trailingRoom - 9)

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
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.3),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .devotionalEntrance(delay: 0.18, drift: -16)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func row(at index: Int) -> some View {
        let state: RosaryBeadState = index < activeIndex ? .prayed : (index == activeIndex ? .active : .ahead)

        return HStack(spacing: 0) {
            Spacer(minLength: 0)

            if let label = rail.label(at: index) {
                Text(label.uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(1.2)
                    .foregroundColor(AppColors.cream)
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
            RailCross(state: state)
        case .medal:
            RailMedal(state: state)
        case .largeBead, .ourFather, .end:
            RailBead(state: state, size: 17)
        case .smallBead, .hailMary:
            RailBead(state: state, size: 12)
        }
    }
}

/// A bead of the rail, drawn to read over anything: a bead to come has a
/// fill of its own and a clear edge, a prayed one is gold, and the bead
/// under the hand is gold inside one crisp ring, with no glow to blur it
private struct RailBead: View {
    let state: RosaryBeadState
    let size: CGFloat

    var body: some View {
        let active = state == .active

        ZStack {
            Circle()
                .strokeBorder(AppColors.goldLight, lineWidth: 1.5)
                .frame(width: size + 11, height: size + 11)
                .opacity(active ? 1 : 0)
                .scaleEffect(active ? 1 : 0.7)

            Circle()
                .fill(fill)
                .overlay(Circle().strokeBorder(edge, lineWidth: 1))
                .frame(width: size, height: size)
        }
        .frame(width: size + 11, height: size + 11)
    }

    private var fill: Color {
        switch state {
        case .ahead: return AppColors.cream.opacity(0.2)
        case .prayed: return AppColors.gold.opacity(0.9)
        case .active: return AppColors.goldLight
        }
    }

    private var edge: Color {
        switch state {
        case .ahead: return AppColors.goldLight.opacity(0.75)
        case .prayed: return AppColors.goldLight.opacity(0.9)
        case .active: return AppColors.goldLight
        }
    }
}

/// A rail bead's press: a ring of light where the finger is, so a bead
/// reads as something that can be pressed
private struct RailBeadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
            Circle()
                .fill(AppColors.goldLight.opacity(configuration.isPressed ? 0.25 : 0))
                .overlay(
                    Circle().strokeBorder(
                        AppColors.goldLight.opacity(configuration.isPressed ? 0.95 : 0),
                        lineWidth: 1.5
                    )
                )
                .frame(width: 30, height: 30)
                .scaleEffect(configuration.isPressed ? 1 : 0.75)
                .animation(Motion.settle, value: configuration.isPressed)
                .allowsHitTesting(false)
        }
    }
}

/// The cross at the rail's foot and head: drawn as the rosary drawing
/// draws it, gold once prayed, lit under the hand
private struct RailCross: View {
    let state: RosaryBeadState

    var body: some View {
        let active = state == .active
        ZStack {
            RailCrossShape()
                .fill(state == .ahead ? AppColors.cream.opacity(0.2) : AppColors.gold.opacity(active ? 0.45 : 0.9))
            RailCrossShape()
                .stroke(active ? AppColors.goldLight : AppColors.gold.opacity(0.8), lineWidth: 1)
        }
        .frame(width: active ? 15 : 12, height: active ? 22 : 18)
        .shadow(color: AppColors.gold.opacity(active ? 0.6 : 0), radius: 5)
    }
}

private struct RailMedal: View {
    let state: RosaryBeadState

    var body: some View {
        let active = state == .active
        ZStack {
            Ellipse()
                .fill(state == .ahead ? AppColors.cream.opacity(0.2) : AppColors.gold.opacity(active ? 0.35 : 0.9))
            Ellipse()
                .strokeBorder(active ? AppColors.goldLight : AppColors.gold.opacity(0.8), lineWidth: 1.2)
        }
        .frame(width: active ? 16 : 13, height: active ? 21 : 17)
        .shadow(color: AppColors.gold.opacity(active ? 0.6 : 0), radius: 5)
    }
}

private struct RailCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        let bar = rect.width * 0.3
        let arm = rect.height * 0.3
        var path = Path()
        path.addRect(CGRect(x: rect.midX - bar / 2, y: rect.minY, width: bar, height: rect.height))
        path.addRect(CGRect(x: rect.minX, y: rect.minY + arm - bar / 2, width: rect.width, height: bar))
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
/// head level with the top of the rail's window, clear of the rail. A
/// kicker for where on the Rosary (THE FIRST JOYFUL MYSTERY, THE OPENING
/// PRAYERS), the title in the display face (the mystery, or the prayer),
/// the bead in small capitals (HAIL MARY · 4 OF 10, 2 OF 7), then the
/// words — the bead's prayer, or the Scriptural Rosary's verse — and,
/// with Helps on, one quiet line. The same on every step and on both
/// players; only the words change.
struct OneRosaryColumn<Words: View>: View {
    let kicker: String
    let title: String
    let bead: String?
    var help: RosaryHelps.Line? = nil

    /// What the column's words are keyed by, so a new bead's words
    /// crossfade whole in their slot
    let wordsKey: String

    @ViewBuilder let words: () -> Words

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(kicker.uppercased())
                .font(AppFonts.labelFont(10.5))
                .tracking(2)
                .foregroundColor(AppColors.goldLight)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.opacity)

            Text(title)
                .font(AppFonts.headlineFont(22))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .contentTransition(.opacity)

            // The label's words stand on the column's edge, its ground
            // reaching out past them
            OneRosaryStepLabel(text: bead ?? " ")
                .opacity(bead == nil ? 0 : 1)
                .padding(.leading, -10)
                .padding(.top, 10)

            ZStack(alignment: .topLeading) {
                words()
                    .id(wordsKey)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.top, 12)
            .animation(Motion.crossfade, value: wordsKey)

            if let help {
                RosaryHelpLine(line: help)
                    .padding(.top, 14)
                    .transition(.opacity)
            }
        }
        .shadow(color: .black.opacity(0.55), radius: 6, y: 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.words, value: kicker)
        .animation(Motion.words, value: title)
        .animation(Motion.words, value: bead)
        .animation(Motion.crossfade, value: help)
    }

    /// The label on the opening and closing prayers, as a decade's
    /// bead wears it: the prayer and its count, "The Apostles' Creed · 2
    /// of 7" (the prayer alone where no count is kept)
    static func pendantLabel(prayer: String, count: String?) -> String {
        guard let count else { return prayer }
        return "\(prayer) · \(count)"
    }

    /// The prayer's words as the column sets them: quiet, so the painting
    /// still leads, and whole — a long prayer (the Creed) comes down a
    /// size rather than run under the foot
    static func prayerWords(_ lines: [String], size: CGFloat = 17) -> some View {
        let fitted: CGFloat = lines.joined().count > 280 ? size - 2 : size
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
            .foregroundColor(AppColors.cream.opacity(0.84))
            .lineSpacing(size > 15 ? 4 : 2)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// The one label every step wears, opening, decades and close: what is
/// said here and its count, on one line ("HAIL MARY · 4 OF 10", "THE
/// APOSTLES' CREED · 2 OF 7"), in cream on a solid ground of its own
struct OneRosaryStepLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.labelFont(11))
            .tracking(1.6)
            .foregroundColor(AppColors.cream)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(AppColors.backgroundDeep.opacity(0.88))
                    .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline))
            )
            .contentTransition(.numericText())
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

// MARK: - OneRosaryFooter

/// Back and Next, the same two quiet buttons on every step, opening,
/// decades and close, on both players: the same place, the same weight.
/// On the last step AMEN takes Next's place at Next's weight. A step
/// with nowhere to go back to keeps Back's place, faded.
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
                action: onBack
            )
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1 : 0.35)
            .accessibilityLabel(Text("Back", comment: "One Rosary beta, the player's footer: VoiceOver name of the button back to the bead or prayer before"))

            Spacer(minLength: 8)

            if isLast {
                button(
                    title: String(localized: "Amen", comment: "Prayer screen, last closing prayer: the gold button that finishes the Rosary"),
                    leading: nil,
                    trailing: "ph-check",
                    action: onAmen
                )
                .beckoning(amenBeckons)
                .accessibilityLabel("Amen — finish the Rosary")
                .transition(.opacity)
            } else {
                button(
                    title: String(localized: "Next", comment: "One Rosary beta, the player's footer: the button on to the next bead or prayer"),
                    leading: nil,
                    trailing: "ph-caret-right",
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

    private func button(title: String, leading: String?, trailing: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leading { AppIcon(leading, size: 10) }
                Text(title.uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2)
                if let trailing { AppIcon(trailing, size: 10) }
            }
            .foregroundColor(AppColors.goldLight)
            .padding(.horizontal, 18)
            .frame(minWidth: 112, minHeight: 44)
            .background(Capsule().fill(AppColors.background.opacity(0.55)))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.45), lineWidth: AppLine.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(GoldCTAButtonStyle())
    }
}

// MARK: - OneRosaryTapHint

/// Once, the first time the beads can be tapped: that they can. Floats
/// above the footer and goes on its own.
struct OneRosaryTapHint: View {
    var body: some View {
        HStack(spacing: 8) {
            AppIcon("lv-rosary", size: 13)
            Text("Tap a bead on the strand to go to it.", comment: "One Rosary beta: a one-time hint that the beads on the strand can be tapped")
                .font(AppFonts.italicFont(14))
        }
        .foregroundColor(AppColors.cream.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(AppColors.background.opacity(0.85)))
        .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - OneRosaryHeader

/// The player's head, the same on both players: the way out, and the
/// prayer's one name, THE ROSARY, with the form or the meditation set
/// small beneath it ("The Scriptural Rosary", "The Gospel")
struct OneRosaryHeader: View {
    let subtitle: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 3) {
                Text(String(localized: "The Rosary", comment: "Settings: a section heading").uppercased())
                    .font(AppFonts.labelFont(11))
                    .tracking(2.4)
                    .foregroundColor(AppColors.goldLight)
                Text(subtitle)
                    .font(AppFonts.italicFont(14))
                    .foregroundColor(AppColors.cream.opacity(0.82))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .shadow(color: .black.opacity(0.7), radius: 6, y: 1)
            .padding(.horizontal, 64)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

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

/// The row under Back and Next, the same on both players: each glyph with
/// its name beneath (VOICE, READ, TEXT, MORE), at a weight that reads
/// over the foot's dark ground. READ stands only where there is a
/// meditation to read.
struct OneRosaryUtilityRow: View {
    let items: [OneRosaryUtility]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 5) {
                        AppIcon(item.icon, size: 22)
                        Text(item.title.uppercased())
                            .font(AppFonts.labelFont(10))
                            .tracking(1.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(AppColors.cream.opacity(0.92))
                    .frame(width: 72, height: 54)
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

    /// The meditation as text
    static func read(_ action: @escaping () -> Void) -> OneRosaryUtility {
        OneRosaryUtility(
            id: "read",
            icon: "ph-book-open",
            title: String(localized: "Read", comment: "One Rosary beta, the player's row under Back and Next: the name under the book, which opens the meditation as text"),
            label: String(localized: "Read the meditation", comment: "Prayer screen: VoiceOver name of the button that opens the meditation as text"),
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
