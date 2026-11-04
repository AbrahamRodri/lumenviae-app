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
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.8))
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
                RosaryDiagram(highlighted: chosenPart?.beads ?? [])
                    .frame(width: 176)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(overview.parts) { part in
                    row(part, isChosen: part == chosenPart, isLast: part == overview.parts.last)
                }

                Text(overview.decadeNote)
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                if let contextLine {
                    Text(contextLine)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
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
                            .font(AppFonts.labelFont(10))
                            .foregroundColor(isChosen ? AppColors.goldLight : AppColors.gold.opacity(0.75))
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
                    .fill(AppColors.gold.opacity(isChosen && category != .sevenSorrows ? 0.06 : 0))
            )
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
                .fill(AppColors.gold.opacity(0.45))
                .frame(width: 1.5)
                .padding(.vertical, 2)
                .accessibilityHidden(true)

            Text(line.instruction)
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.62))
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

    /// Beads a tap may reach, ringed faintly so they read as touchable
    var tappable: Set<Int> = []

    static let rowHeight = RosaryStrandView.rowHeight
    static let beadColumn = RosaryStrandView.beadColumn
    static let trailingRoom = RosaryStrandView.trailingRoom

    /// Room for the decades' numerals beside the bead column
    static let width: CGFloat = 64

    var body: some View {
        let rowFromTop = rail.count - 1 - activeIndex
        let restingOffset = height / 2 - Self.rowHeight / 2 - CGFloat(rowFromTop) * Self.rowHeight

        ZStack(alignment: .topTrailing) {
            // The rail's own quiet ground: a soft column of the page's
            // dark, dissolving at both ends with the window
            Capsule()
                .fill(AppColors.background.opacity(0.55))
                .frame(width: Self.beadColumn + 18, height: height)
                .blur(radius: 6)
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
                    .fill(AppColors.gold.opacity(0.3))
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
                    .font(AppFonts.labelFont(9))
                    .tracking(1.2)
                    .foregroundColor(AppColors.goldLight.opacity(0.9))
                    .lineLimit(1)
                    .fixedSize()
                    .shadow(color: .black.opacity(0.8), radius: 3)
                    .padding(.trailing, 10)
            }

            bead(rail.kinds[index], state: state)
                .overlay {
                    if tappable.contains(index) {
                        Circle()
                            .strokeBorder(AppColors.goldLight.opacity(0.28), lineWidth: 1)
                            .frame(width: 24, height: 24)
                    }
                }
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
            RosaryBead(state: state, size: 18, isOurFather: true)
        case .smallBead, .hailMary:
            RosaryBead(state: state, size: 11)
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
                .fill(state == .ahead ? AppColors.background.opacity(0.9) : AppColors.gold.opacity(active ? 0.45 : 0.9))
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
                .fill(state == .ahead ? AppColors.background.opacity(0.9) : AppColors.gold.opacity(active ? 0.35 : 0.9))
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
        onTap: @escaping (Int) -> Void
    ) -> some View {
        let windowTop = max(RosaryStrandView.windowTop(fullHeight: fullHeight) - topInset, 0)
        let windowHeight = fullHeight * 0.435
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
                    tappable: tappable
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
                    .buttonStyle(.plain)
                    .padding(.top, windowTop + windowHeight / 2 - RosaryStrandView.rowHeight / 2
                        + CGFloat(activeIndex - index) * RosaryStrandView.rowHeight)
                    .padding(.trailing, beadInset - 22)
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
                .font(AppFonts.labelFont(9.5))
                .tracking(2.2)
                .foregroundColor(AppColors.gold.opacity(0.9))
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

            Text((bead ?? " ").uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(1.8)
                .foregroundColor(AppColors.goldLight.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(AppColors.background.opacity(0.72)))
                .opacity(bead == nil ? 0 : 1)
                .padding(.leading, -8)
                .padding(.top, 8)
                .contentTransition(.numericText())

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

/// A painting's left side quietened behind the column, dissolving to
/// clear across the glass and at both ends, so the words read over any
/// painting without a slab under them
struct OneRosaryColumnScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.62), location: 0),
                .init(color: .black.opacity(0.4), location: 0.55),
                .init(color: .black.opacity(0), location: 0.9),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.08),
                    .init(color: .black, location: 0.22),
                    .init(color: .black, location: 0.72),
                    .init(color: .clear, location: 0.88),
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
