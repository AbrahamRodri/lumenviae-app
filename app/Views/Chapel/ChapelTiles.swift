//
//  ChapelTiles.swift
//  Lumen Viae
//
//  The sections of the Chapel page. Each tile is drawn twice — a
//  full-width layout and a compact half-width one, authored separately
//  so the half is never the full squeezed — and none of them own their
//  data: they read the same services and SwiftData models the rest of
//  the app writes.
//
//  Each section is its own object (the "Chapel Redesign" handoff). A
//  tile is a card cut from its own ground — the rule lit on a raised
//  card, the flame burning in the dark, the consecration's painting run
//  to the card's edges, the Prayer Book a leaf darkening down the page,
//  the reading shelf and the chant on cloth, the journal on the quote
//  ground, the liturgy on the deep ground, the library bound with a
//  second rule inside its first — and names itself on its own first
//  line, in Cinzel, with an italic note beside it. What it shows is
//  drawn for what it is: a string of beads, an ember, a road, a page of
//  hours, a shelf, a staff, a versal, a calendar leaf, an index.
//
//  The page before this drew every section in one shell: a kicker on the
//  page above a hairline outline with no fill, and a foot pinned to its
//  floor. Any tile sat well beside any other, and none of them could be
//  told apart at a glance. What the tiles still share is the frame's
//  measure — a 16pt corner, a hairline at the tile's own strength, the
//  title line, a foot ruled off when there is one — so two halves side
//  by side still share their first line and end on the same one.
//

import SwiftUI
import SwiftData

// MARK: - ChapelAct

/// One act of the user's rule, resolved for today: what it is, its live
/// context line, and whether it has been offered. Every act on the rule
/// is one the app watches finish.
struct ChapelAct: Identifiable {
    let shortcut: PrayerShortcut
    let subtitle: String
    let done: Bool

    /// A Rosary of this act's form left off today, which the act takes
    /// up where it stopped (`InProgressPrayer.isContinued(by:)`)
    var resume: InProgressPrayer? = nil

    var id: String { shortcut.rawValue }

    /// The act's name as the ledger and the focus block set it.
    var focusTitle: String { shortcut.actName }

    /// The gold act under the focus title.
    var focusAction: String {
        if resume != nil {
            switch shortcut {
            case .todaysRosary:     return "Continue the Rosary"
            case .sevenSorrows:     return "Continue the Chaplet"
            case .scripturalRosary: return "Continue the Scriptural Rosary"
            case .rosaryAloud:      return "Continue the Holy Rosary"
            default:                break
            }
        }
        switch shortcut {
        case .todaysRosary:     return "Pray with a Meditation"
        case .chooseMeditation: return "Open Today's Mysteries"
        case .sevenSorrows:     return "Begin the Chaplet"
        case .scripturalRosary: return "Begin the Scriptural Rosary"
        case .rosaryAloud:      return "Begin the Holy Rosary"
        case .mass:             return "Begin the Mass"
        case .office:           return "Begin the Office"
        case .consecration:     return "Continue the Preparation"
        case .morningPrayers:   return "Pray Morning Prayers"
        case .angelus:          return PrayerBook.isEastertide(Date()) ? "Pray the Regina Cæli" : "Pray the Angelus"
        case .nightPrayers:     return "Pray Night Prayers"
        }
    }

    /// The gold word on the ledger row's trailing act — CONTINUE for a
    /// preparation already under way or a Rosary left off today, BEGIN
    /// for everything else.
    var rowAction: String {
        shortcut == .consecration || resume != nil ? "Continue" : "Begin"
    }
}

// MARK: - The frame every tile shares

/// The measures every tile is built to, in one place.
enum ChapelTileMetrics {
    static let cornerRadius: CGFloat = 16

    /// The card's own padding. A tile's foot sits closer to its floor
    /// than its title does to its top, because the foot's act answers
    /// to 44 points and carries its own air.
    static func padding(_ span: Int) -> EdgeInsets {
        span == 2
            ? EdgeInsets(top: 18, leading: 18, bottom: 6, trailing: 18)
            : EdgeInsets(top: 16, leading: 14, bottom: 4, trailing: 14)
    }
}

/// What a tile's card is cut from. Each section has its own, so the page
/// reads as a room of different things rather than a stack of one.
enum ChapelSurface {
    /// The rule: a raised card, lit from its upper corner, with a halo
    case lit
    /// The flame: the deep ground, warm where the flame stands
    case ember
    /// The consecration: the preparation's painting, edge to edge
    case painting(String)
    /// The Prayer Book: a leaf darkening from the raised card down
    case leaf
    /// The shelf and the chant: the card's own cloth
    case cloth
    /// The journal: the quote ground
    case quote
    /// The liturgy: the deep ground
    case deep
    /// The library: cloth bound with a second rule inside the first
    case bound

    /// How strongly the card's hairline is drawn — the lit card most,
    /// the deep ground least, so each card's edge is as strong as its
    /// ground needs
    var borderOpacity: Double {
        switch self {
        case .lit:      return 0.42
        case .ember:    return 0.26
        case .painting: return 0.32
        case .leaf:     return 0.22
        case .cloth:    return 0.26
        case .quote:    return 0.2
        case .deep:     return 0.18
        case .bound:    return 0.3
        }
    }

    var isPainting: Bool {
        if case .painting = self { return true }
        return false
    }

    var isLit: Bool {
        if case .lit = self { return true }
        return false
    }
}

/// The ground a card is cut from, drawn behind its contents.
private struct ChapelCardGround: View {
    let surface: ChapelSurface
    let span: Int

    var body: some View {
        switch surface {
        case .lit:
            AppColors.cardElevated
                .overlay {
                    RadialGradient(
                        stops: [
                            .init(color: AppColors.gold.opacity(0.16), location: 0),
                            .init(color: AppColors.gold.opacity(0.05), location: 0.45),
                            .init(color: .clear, location: 0.72)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: span == 2 ? 340 : 220
                    )
                }

        case .ember:
            GeometryReader { geo in
                // The warmth stands behind the flame: beside the figure at
                // full width, above it at half
                let center = span == 2
                    ? CGPoint(x: 66, y: geo.size.height * 0.5)
                    : CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.34)
                AppColors.backgroundDeep
                    .overlay {
                        RadialGradient(
                            stops: [
                                .init(color: AppColors.gold.opacity(0.22), location: 0),
                                .init(color: AppColors.gold.opacity(0.06), location: 0.5),
                                .init(color: .clear, location: 0.72)
                            ],
                            center: UnitPoint(
                                x: geo.size.width > 0 ? center.x / geo.size.width : 0.5,
                                y: geo.size.height > 0 ? center.y / geo.size.height : 0.5
                            ),
                            startRadius: 0,
                            endRadius: span == 2 ? 150 : 120
                        )
                    }
            }

        case .painting(let name):
            ZStack {
                AppColors.backgroundDeep
                CachedAssetImage(name, focal: UnitPoint(x: 0.5, y: span == 2 ? 0.28 : 0.26))
                // Clear at the head, so the painting is seen, and dark at
                // the foot, where the day is read over it
                LinearGradient(
                    stops: [
                        .init(color: AppColors.backgroundDeep.opacity(0.10), location: 0),
                        .init(color: AppColors.backgroundDeep.opacity(0.18), location: 0.34),
                        .init(color: AppColors.background.opacity(0.78), location: 0.68),
                        .init(color: AppColors.background.opacity(0.96), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .accessibilityHidden(true)

        case .leaf:
            LinearGradient(
                stops: [
                    .init(color: AppColors.cardElevated, location: 0),
                    .init(color: AppColors.cardBackground, location: 0.46),
                    .init(color: AppColors.backgroundDeep, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .cloth:
            AppColors.cardBackground

        case .quote:
            AppColors.quoteBackground

        case .deep:
            AppColors.backgroundDeep

        case .bound:
            AppColors.cardBackground
                .overlay(
                    RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius - 6)
                        .strokeBorder(AppColors.gold.opacity(0.14), lineWidth: AppLine.hairline)
                        .padding(6)
                )
        }
    }
}

/// The lit card's halo — the rule's alone, since it is the page's
/// working list and the one card the eye should find first.
private struct ChapelCardHalo: ViewModifier {
    let active: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            content
                .shadow(color: AppColors.gold.opacity(0.10), radius: 16)
                .shadow(color: AppColors.gold.opacity(0.05), radius: 35)
        } else {
            content
        }
    }
}

/// A tile's first line: its name in Cinzel, and at the right either an
/// italic note — "Not yet today", "Two more open" — or the list's EDIT.
struct ChapelTileHeader: View {
    let title: String
    let span: Int
    var note: String? = nil

    /// Edits the tile's own list (the Today tile's rule) from its title
    /// line, where a list's edit control is looked for. As EDIT RULE in
    /// the foot it stood at the right under the rows, lined up with their
    /// BEGIN and CONTINUE, and read as one more of them.
    var onEdit: (() -> Void)? = nil

    /// Set over a painting, where the name takes a shadow to be read
    var overPainting: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(AppFonts.titleFont(span == 2 ? 17 : 15))
                .tracking(0.5)
                .foregroundColor(AppColors.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(overPainting ? 0.6 : 0), radius: 4, y: 1)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: note == nil && onEdit == nil ? 0 : 8)

            if let note {
                ChapelHeaderNote(note)
                    .layoutPriority(1)
            }

            if let onEdit {
                Button(action: onEdit) {
                    Text("EDIT")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                        .padding(.leading, 12)
                        // Drawn to the title line's height, answering to
                        // 44: a taller title line would break the line a
                        // pair of halves shares
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .padding(.vertical, -11)
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Edit your rule")
                .layoutPriority(1)
            }
        }
        .frame(minHeight: 22, alignment: .leading)
    }
}

/// The italic note on a title line's right — "Not yet today", "1962".
struct ChapelHeaderNote: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(13.5))
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(1)
            // A count or a clock rolls its digits; a word crossfades
            .contentTransition(
                text.contains(where: \.isNumber) ? ContentTransition.numericText() : .opacity
            )
            .animation(Motion.crossfade, value: text)
    }
}

/// The italic line at a foot — a fact, never a judgement.
struct ChapelFootNote: View {
    let text: String
    var size: CGFloat = 13

    init(_ text: String, size: CGFloat = 13) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(size))
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

/// The gold text act a foot closes on — "CONTINUE ›".
struct ChapelFootAct: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
            AppIcon("ph-caret-right", size: 9)
        }
        .foregroundColor(AppColors.gold)
        .lineLimit(1)
    }
}

/// A tile's foot, on the card's floor: at full width the note on the
/// left and the act on the right; at half the act alone, left-aligned,
/// or the note where a tile has no act. Ruled off from the body above
/// it unless the body ends on a line of its own (the reading shelf).
///
/// The act is a button of its own only when the tile's body has doors
/// of its own; otherwise the whole tile is the door and the act is a
/// label inside it.
struct ChapelTileFoot: View {
    let span: Int
    var note: String? = nil
    var act: String? = nil
    var ruled: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if span == 2 {
                if let note {
                    ChapelFootNote(note)
                }
                Spacer(minLength: 0)
                if let act {
                    actView(act)
                }
            } else {
                if let act {
                    actView(act)
                } else if let note {
                    ChapelFootNote(note)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(minHeight: 44)
        .padding(.top, 2)
        .overlay(alignment: .top) {
            if ruled {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.16))
                    .frame(height: AppLine.hairline)
            }
        }
    }

    @ViewBuilder
    private func actView(_ title: String) -> some View {
        if let action {
            Button(action: action) {
                ChapelFootAct(title: title)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(GoldCTAButtonStyle())
            .accessibilityLabel(title)
        } else {
            ChapelFootAct(title: title)
                .frame(minHeight: 44)
        }
    }
}

/// A hold on the quiet parts of a tile — its title, its card between
/// the doors — arranges the page, as a hold on the page between tiles
/// does. Only where no control is: a door keeps its own touch.
private struct ChapelHoldToArrange: ViewModifier {
    let active: Bool

    @Environment(AppRouter.self) private var router

    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            content.onLongPressGesture(minimumDuration: 0.45, maximumDistance: 8) {
                router.beginChapelArranging()
            }
        } else {
            content
        }
    }
}

/// The whole tile, assembled: its card, its title line, its body, what
/// stands on its floor, and its foot. A tile hands it a body and, where
/// the design pins something to the card's floor (the week under the
/// flame, the hours under the Prayer Book's order), a floor; everything
/// else is the frame's. With `onTap` the entire card is one door;
/// without it, `onAct` makes the foot's act the only control the frame
/// draws, for tiles whose bodies carry their own.
///
/// Either way a hold arranges the page. The tiles cover most of it, and
/// the page's own hold lives behind them, so a tile that took no hold
/// left "press and hold anywhere" true only of the gaps.
struct ChapelTileFrame<Content: View, Floor: View>: View {
    let tile: ChapelTile
    let span: Int
    let surface: ChapelSurface
    var note: String? = nil
    var act: String? = nil
    var footNote: String? = nil
    var footRuled: Bool = true

    /// The card's padding, where a tile's design departs from the
    /// standard measure (the painting runs its road to the floor)
    var padding: EdgeInsets? = nil

    /// Edits the tile's own list from its title line; see `ChapelTileHeader`
    var onEdit: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var onAct: (() -> Void)? = nil
    var accessibilityLabel: String? = nil
    let content: Content
    let floor: Floor

    @Environment(AppRouter.self) private var router

    /// A finger resting on a tile that opens on a tap: the card press
    /// settle, drawn here because the tile is not a Button
    @State private var pressed = false

    init(
        tile: ChapelTile,
        span: Int,
        surface: ChapelSurface,
        note: String? = nil,
        act: String? = nil,
        footNote: String? = nil,
        footRuled: Bool = true,
        padding: EdgeInsets? = nil,
        onEdit: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        onAct: (() -> Void)? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder floor: () -> Floor
    ) {
        self.tile = tile
        self.span = span
        self.surface = surface
        self.note = note
        self.act = act
        self.footNote = footNote
        self.footRuled = footRuled
        self.padding = padding
        self.onEdit = onEdit
        self.onTap = onTap
        self.onAct = onAct
        self.accessibilityLabel = accessibilityLabel
        self.content = content()
        self.floor = floor()
    }

    var body: some View {
        if let onTap {
            // A tap and a hold, as two gestures rather than a Button: a
            // Button fires on release, so a hold that had just arranged
            // the page would also have opened the tile under the finger
            card
                .scaleEffect(pressed ? 0.98 : 1)
                .opacity(pressed ? 0.92 : 1)
                .animation(.easeOut(duration: 0.18), value: pressed)
                .contentShape(RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius))
                .onTapGesture(perform: onTap)
                .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 8) {
                    pressed = false
                    router.beginChapelArranging()
                } onPressingChanged: { isPressing in
                    pressed = isPressing
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel ?? tile.title)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onTap() }
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelTileHeader(
                title: span == 2 ? tile.title : tile.shortTitle,
                span: span,
                note: note,
                onEdit: onEdit,
                overPainting: surface.isPainting
            )
            .contentShape(Rectangle())
            .modifier(ChapelHoldToArrange(active: onTap == nil))

            content

            Spacer(minLength: 0)

            floor

            if act != nil || footNote != nil {
                ChapelTileFoot(
                    span: span,
                    note: footNote,
                    act: act,
                    ruled: footRuled,
                    action: onTap == nil ? onAct : nil
                )
            }
        }
        .padding(padding ?? ChapelTileMetrics.padding(span))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                ChapelCardGround(surface: surface, span: span)

                // Behind the body, so it answers only between the doors
                if onTap == nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .modifier(ChapelHoldToArrange(active: true))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: ChapelTileMetrics.cornerRadius)
                .strokeBorder(AppColors.gold.opacity(surface.borderOpacity), lineWidth: AppLine.hairline)
        )
        .modifier(ChapelCardHalo(active: surface.isLit))
    }
}

extension ChapelTileFrame where Floor == EmptyView {
    init(
        tile: ChapelTile,
        span: Int,
        surface: ChapelSurface,
        note: String? = nil,
        act: String? = nil,
        footNote: String? = nil,
        footRuled: Bool = true,
        padding: EdgeInsets? = nil,
        onEdit: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        onAct: (() -> Void)? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            tile: tile,
            span: span,
            surface: surface,
            note: note,
            act: act,
            footNote: footNote,
            footRuled: footRuled,
            padding: padding,
            onEdit: onEdit,
            onTap: onTap,
            onAct: onAct,
            accessibilityLabel: accessibilityLabel,
            content: content,
            floor: { EmptyView() }
        )
    }
}

/// A figure in Cinzel with what it counts beside it — "Day 14 / 33",
/// "12 days in a row" — set as one line of text so the two share a
/// baseline whatever their sizes.
private func chapelFigure(
    _ number: String,
    size: CGFloat,
    denominator: String? = nil,
    denominatorSize: CGFloat = 16,
    caption: String? = nil,
    captionSize: CGFloat = 15
) -> Text {
    var line = Text(number)
        .font(AppFonts.titleFont(size))
        .foregroundColor(AppColors.cream)
    if let denominator {
        line = line + Text(" \(denominator)")
            .font(AppFonts.titleFont(denominatorSize))
            .foregroundColor(AppColors.cream.opacity(0.6))
    }
    if let caption {
        line = line + Text("  \(caption)")
            .font(AppFonts.italicFont(captionSize))
            .foregroundColor(AppColors.cream.opacity(0.85))
    }
    return line
}

// MARK: - Today (the rule)

/// The user's rule of prayer, act by act, as a string of beads: one
/// bead to an act, a gold one for each offered, the next ringed and lit
/// on a wash of gold, the rest waiting. The tile that drives the focus
/// block at the top of the page — the ledger is the picker — so every
/// row shows at its trailing edge what a tap does: the seal once an act
/// is offered, BEGIN (or CONTINUE) until then.
struct ChapelRuleTile: View {

    let acts: [ChapelAct]
    let span: Int
    let onAct: (ChapelAct) -> Void
    let onEditRule: () -> Void

    private var doneCount: Int { acts.filter(\.done).count }
    private var next: ChapelAct? { acts.first { !$0.done } }

    var body: some View {
        ChapelTileFrame(
            tile: .rule,
            span: span,
            surface: .lit,
            footNote: span == 2 && !acts.isEmpty ? "\(doneCount) of \(acts.count) offered" : nil,
            onEdit: onEditRule
        ) {
            if span == 2 { full } else { half }
        }
    }

    // MARK: Full — the string of beads

    @ViewBuilder
    private var full: some View {
        if acts.isEmpty {
            Text("No devotions on your rule yet.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 14)
                .padding(.bottom, 12)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(acts) { act in
                    row(act)
                }
            }
            // The thread the beads hang on, from the first bead to the
            // last, behind them
            .background(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.24))
                    .frame(width: 1)
                    .padding(.vertical, 26)
                    .padding(.leading, 10.5)
                    .accessibilityHidden(true)
            }
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
    }

    private func row(_ act: ChapelAct) -> some View {
        let isNext = act.id == next?.id
        return Button(action: { onAct(act) }) {
            HStack(spacing: 12) {
                ChapelRuleBead(mark: act.done ? .offered : (isNext ? .next : .waiting))

                VStack(alignment: .leading, spacing: 2) {
                    Text(act.focusTitle)
                        .font(AppFonts.titleFont(isNext ? 16.5 : 14))
                        .foregroundColor(
                            AppColors.cream.opacity(isNext ? 1 : (act.done ? 0.55 : 0.85))
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(act.subtitle)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                trailing(act, isNext: isNext)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            // The next act is lit where it hangs, the wash running a
            // little past the beads' column on either side
            if isNext {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.gold.opacity(0.08))
                    .padding(.horizontal, -8)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, isNext ? 2 : 0)
        .animation(Motion.crossfade, value: isNext)
        .accessibilityLabel(accessibility(for: act))
    }

    /// What the row's tap does, drawn at its trailing edge. The two
    /// crossfade in place as the act is offered.
    private func trailing(_ act: ChapelAct, isNext: Bool) -> some View {
        ZStack(alignment: .trailing) {
            if act.done {
                HStack(spacing: 6) {
                    Text("OFFERED")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.55))

                    AppIcon("ph-seal-check-fill", size: 16)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                }
                .transition(.opacity)
            } else {
                HStack(spacing: 8) {
                    Text(act.rowAction.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                    AppIcon("ph-caret-right", size: 9)
                }
                .foregroundColor(AppColors.gold.opacity(isNext ? 1 : 0.75))
                .frame(minHeight: 44)
                .transition(.opacity)
            }
        }
        .animation(Motion.crossfade, value: act.done)
    }

    private func accessibility(for act: ChapelAct) -> String {
        act.done ? "\(act.focusTitle), offered." : "\(act.rowAction) \(act.focusTitle)"
    }

    // MARK: Half — the figure and a row of cells

    @ViewBuilder
    private var half: some View {
        if acts.isEmpty {
            Text("No devotions yet.")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 14)
        } else {
            chapelFigure("\(doneCount)", size: 30, denominator: "/ \(acts.count)", denominatorSize: 14)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
                .animation(Motion.crossfade, value: doneCount)
                .padding(.top, 14)

            Text("offered today")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .padding(.top, 2)

            // One 44pt row of equal cells, one per act, bleeding 8pt into
            // the card's padding on each side. Each cell is the half
            // tile's only way to offer its act.
            HStack(spacing: 2) {
                ForEach(acts) { act in
                    cell(act)
                }
            }
            .padding(.horizontal, -8)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private func cell(_ act: ChapelAct) -> some View {
        let isNext = act.id == next?.id
        return Button(action: { onAct(act) }) {
            VStack(spacing: 5) {
                AppIcon(act.shortcut.icon, size: 15)
                    .foregroundColor(
                        isNext ? AppColors.goldLight : (act.done ? AppColors.gold : AppColors.gold.opacity(0.45))
                    )

                ChapelRuleBead(mark: act.done ? .offered : (isNext ? .next : .waiting), scale: 0.7)
                    .frame(height: 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.gold.opacity(isNext ? 0.08 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility(for: act))
    }
}

/// One bead of the rule's string: gold once offered, ringed and lit for
/// the next act, and an empty ring for the acts still waiting.
private struct ChapelRuleBead: View {
    enum Mark { case offered, next, waiting }

    let mark: Mark
    var scale: CGFloat = 1

    var body: some View {
        ZStack {
            switch mark {
            case .offered:
                Circle()
                    .fill(AppColors.goldGradient)
                    .frame(width: 9 * scale, height: 9 * scale)
                    .shadow(color: AppColors.gold.opacity(0.55), radius: 1.5)
            case .next:
                Circle()
                    .fill(AppColors.cardElevated)
                    .overlay(Circle().strokeBorder(AppColors.gold, lineWidth: 1.5))
                    .overlay(
                        Circle()
                            .fill(AppColors.goldLight)
                            .frame(width: 5 * scale, height: 5 * scale)
                    )
                    .frame(width: 15 * scale, height: 15 * scale)
                    .haloGlow(AppColors.gold, radius: 9, intensity: 0.5)
            case .waiting:
                Circle()
                    .fill(AppColors.cardElevated)
                    .overlay(Circle().strokeBorder(AppColors.textSecondary.opacity(0.6), lineWidth: 1))
                    .frame(width: 9 * scale, height: 9 * scale)
            }
        }
        .frame(width: 22 * scale, height: 22 * scale)
        .animation(Motion.settle, value: mark)
        .accessibilityHidden(true)
    }
}

// MARK: - Prayer Streak

/// The streak as an ember in the dark. It never scolds: only days
/// prayed are marked, the note says "Not yet today" and never "missed",
/// and the milestone ahead is an invitation. The whole tile opens the
/// Prayer Record.
///
/// Two facts, kept apart so neither is mistaken for the other: the
/// streak — days in a row, the figure — and the week, drawn as a small
/// calendar beneath it with each day's initial over its bead and today
/// ringed. An earlier draft set the words "This week" under the streak
/// and seven bare dots beside it, and the number read as this week's
/// count while the dots said nothing about which day was which.
struct ChapelFlameTile: View {

    let span: Int
    let streak: Int
    let hasPrayedToday: Bool
    let weekStatus: [(date: Date, didPray: Bool)]
    let onOpen: () -> Void

    private var streakLabel: String {
        switch streak {
        case 0:  return "Begin Your Streak"
        case 1:  return "1 Day of Prayer"
        default: return "\(streak) Days of Prayer"
        }
    }

    /// "Novena · 1 day away" — the next milestone by name, and how far
    /// off it stands. Word for word the Prayer Record's own line
    /// (`MilestoneProgressLine`), so the two surfaces agree. Still an
    /// invitation ahead, never a warning: the distance is to something,
    /// not from something lost.
    private var milestoneLine: String? {
        guard let next = StreakMilestone.next(after: streak) else { return nil }
        let away = next.days - streak
        return "\(next.name) · \(away == 1 ? "1 day away" : "\(away) days away")"
    }

    private var litNote: String { hasPrayedToday ? "Lit today" : "Not yet today" }

    private var daysPrayedThisWeek: Int { weekStatus.filter(\.didPray).count }

    private var accessibilityLabel: String {
        var line = "Prayer Streak. \(streakLabel), \(litNote.lowercased())."
        if !weekStatus.isEmpty {
            line += " Prayed \(daysPrayedThisWeek) of 7 days this week."
        }
        return line + " Opens the Prayer Record."
    }

    var body: some View {
        if span == 2 {
            ChapelTileFrame(
                tile: .flame,
                span: 2,
                surface: .ember,
                note: litNote,
                onTap: onOpen,
                accessibilityLabel: accessibilityLabel
            ) {
                full
            }
        } else {
            ChapelTileFrame(
                tile: .flame,
                span: 1,
                surface: .ember,
                onTap: onOpen,
                accessibilityLabel: accessibilityLabel
            ) {
                halfFigure
            } floor: {
                if !weekStatus.isEmpty {
                    halfWeek
                        .padding(.top, 4)
                        .padding(.bottom, 14)
                }
            }
        }
    }

    // MARK: Full — the ember beside the figure, the week beneath

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 18) {
                ChapelFlameMedallion(size: 64, isLit: hasPrayedToday)
                    .frame(width: 96)

                VStack(alignment: .leading, spacing: 6) {
                    if streak > 0 {
                        chapelFigure(
                            "\(streak)",
                            size: 42,
                            caption: streak == 1 ? "day of prayer" : "days in a row"
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .contentTransition(.numericText())
                        .animation(Motion.crossfade, value: streak)
                    } else {
                        Text("Begin Your Streak")
                            .font(AppFonts.titleFont(21))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(milestoneLine ?? "Each day you pray adds one")
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .padding(.bottom, 14)

            if !weekStatus.isEmpty {
                fullWeek
                    .padding(.top, 2)
                    .padding(.bottom, 16)
            }
        }
    }

    private static let dayInitial: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // S, M, T…
        return f
    }()

    /// The week, Sunday to Saturday, as a small calendar: each day's
    /// initial over its bead. Only the prayed days are lit — never a mark
    /// for a missed one, and a day still to come looks the same as one
    /// let pass — and today is ringed, so the eye knows where in the week
    /// it stands.
    private var fullWeek: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekStatus.enumerated()), id: \.offset) { _, day in
                let isToday = PrayerDay.isToday(day.date)
                VStack(spacing: 6) {
                    Text(Self.dayInitial.string(from: day.date).uppercased())
                        .font(AppFonts.bodyFont(11))
                        .tracking(1)
                        .foregroundColor(isToday ? AppColors.gold : AppColors.textSecondary)

                    ZStack {
                        if isToday {
                            Circle()
                                .strokeBorder(AppColors.goldLight, lineWidth: 1.5)
                        }
                        weekBead(prayed: day.didPray, prayedSize: 9, restSize: 7)
                    }
                    .frame(width: 26, height: 26)
                }
                .frame(maxWidth: .infinity)
            }
        }
        // A day lit while the page is open — a Rosary just finished —
        // warms up rather than switching on
        .animation(Motion.settle, value: weekStatus.map(\.didPray))
        .accessibilityHidden(true)
    }

    // MARK: Half — the ember over the figure, the week on the floor

    private var halfFigure: some View {
        VStack(spacing: 8) {
            ChapelFlameMedallion(size: 48, isLit: hasPrayedToday)

            if streak > 0 {
                chapelFigure("\(streak)", size: 30, caption: streak == 1 ? "day" : "days", captionSize: 14)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())
                    .animation(Motion.crossfade, value: streak)
            } else {
                Text("Begin Your Streak")
                    .font(AppFonts.titleFont(14))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    /// The week as seven beads with no initials — a half has no room for
    /// them — today ringed
    private var halfWeek: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekStatus.enumerated()), id: \.offset) { _, day in
                ZStack {
                    if PrayerDay.isToday(day.date) {
                        Circle()
                            .strokeBorder(AppColors.gold.opacity(0.8), lineWidth: 1)
                            .frame(width: 12, height: 12)
                    }
                    weekBead(prayed: day.didPray, prayedSize: 6, restSize: 6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 12)
        .animation(Motion.settle, value: weekStatus.map(\.didPray))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func weekBead(prayed: Bool, prayedSize: CGFloat, restSize: CGFloat) -> some View {
        if prayed {
            Circle()
                .fill(AppColors.goldGradient)
                .frame(width: prayedSize, height: prayedSize)
                .shadow(color: AppColors.gold.opacity(0.6), radius: 2)
        } else {
            Circle()
                .fill(AppColors.textSecondary.opacity(0.4))
                .frame(width: restSize, height: restSize)
        }
    }
}

/// The flame in its ember: a soft gold disc, a blurred glow behind it,
/// and the flame. Quieter until the day is lit, never dark.
private struct ChapelFlameMedallion: View {
    let size: CGFloat
    let isLit: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.gold.opacity(isLit ? 0.35 : 0.22))
                .blur(radius: 7)
            Circle()
                .fill(AppColors.gold.opacity(isLit ? 0.22 : 0.14))
            AppIcon("ph-flame-fill", size: (size * 0.44).rounded())
                .foregroundColor(AppColors.goldLight.opacity(isLit ? 1 : 0.75))
        }
        .frame(width: size, height: size)
        .animation(Motion.settle, value: isLit)
        .accessibilityHidden(true)
    }
}

// MARK: - Consecration

/// The user's place on the 33-day path, over the preparation's own
/// painting — the one its day page opens on — with de Montfort's four
/// preparations as a segmented road along the card's floor, each track
/// as long as its true share of the days. The whole tile opens the
/// consecration.
struct ChapelConsecrationTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    private var active: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    private var completed: ConsecrationProgress? {
        consecrations.first { $0.isCompleted }
    }

    /// The four preparations, with their true lengths.
    static let phases: [(name: String, from: Int, to: Int)] = [
        ("The World", 1, 12),
        ("Yourself", 13, 19),
        ("Our Lady", 20, 26),
        ("Christ", 27, 33)
    ]

    /// The preparation a day falls in, as the Chapel names it — the
    /// rule's ledger row borrows this for the Consecration's line.
    static func phaseName(day: Int) -> String {
        switch day {
        case ...12:   return "Renouncing the world"
        case 13...19: return "Knowing yourself"
        case 20...26: return "Knowing Our Lady"
        case 27...33: return "Knowing Christ"
        default:      return "The day of consecration"
        }
    }

    /// What VoiceOver says for the tile under way. The day of
    /// consecration is not a thirty-fourth day of the preparation.
    private static func spoken(day: Int) -> String {
        day > 33
            ? "Consecration. The day of consecration. Continue."
            : "Consecration. Day \(day) of 33, \(phaseName(day: day)). Continue."
    }

    /// The painting the day's preparation is set under on its own page
    private static func paintingName(day: Int) -> String {
        (ConsecrationPhase.phase(for: day) ?? .consecrationDay).heroImageName
    }

    /// The card's padding: the road runs to the floor, with no foot
    /// beneath it
    private var padding: EdgeInsets {
        span == 2
            ? EdgeInsets(top: 18, leading: 18, bottom: 0, trailing: 18)
            : EdgeInsets(top: 16, leading: 14, bottom: 0, trailing: 14)
    }

    /// Tall enough that the painting is seen above the day
    private var minHeight: CGFloat { span == 2 ? 270 : 222 }

    private func open() {
        router.switchTo(.consecration)
    }

    var body: some View {
        if let active {
            activeTile(day: active.currentDayNumber)
        } else if let completed {
            completedTile(completed)
        } else {
            invitation
        }
    }

    // MARK: Under way

    private func activeTile(day: Int) -> some View {
        ChapelTileFrame(
            tile: .consecration,
            span: span,
            surface: .painting(Self.paintingName(day: day)),
            padding: padding,
            onTap: open,
            accessibilityLabel: Self.spoken(day: day)
        ) {
            EmptyView()
        } floor: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: span == 2 ? 4 : 3) {
                        dayFigure(day)

                        Text(dayLine(day))
                            .font(AppFonts.italicFont(span == 2 ? 16 : 14))
                            .foregroundColor(AppColors.cream.opacity(0.92))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if span == 2 {
                        Spacer(minLength: 0)
                        ChapelFootAct(title: "Continue")
                            .frame(minHeight: 44)
                    }
                }

                ChapelRoad(day: min(day, 33), height: span == 2 ? 4 : 3)
                    .padding(.top, span == 2 ? 12 : 10)
                    .padding(.bottom, span == 2 ? 16 : 14)
            }
        }
        .frame(minHeight: minHeight)
    }

    /// "Day 14 / 33" at full width, "14 / 33" at half. The day of
    /// consecration is named rather than counted: a figure of
    /// "Day 33 / 33" over "The day of consecration" said two different
    /// days at once.
    @ViewBuilder
    private func dayFigure(_ day: Int) -> some View {
        if day > 33 {
            Text("Consecration Day")
                .font(AppFonts.titleFont(span == 2 ? 26 : 18))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            chapelFigure(
                span == 2 ? "Day \(day)" : "\(day)",
                size: span == 2 ? 30 : 32,
                denominator: "/ 33",
                denominatorSize: span == 2 ? 16 : 14
            )
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    /// The day's own title at full width ("Humble Subjection"), which
    /// says what today asks; the preparation's name at half, where the
    /// room is for a short line
    private func dayLine(_ day: Int) -> String {
        if span == 2 || day > 33 {
            return ConsecrationData.day(day)?.title ?? Self.phaseName(day: day)
        }
        return Self.phaseName(day: day)
    }

    // MARK: Made

    private func completedTile(_ progress: ConsecrationProgress) -> some View {
        ChapelTileFrame(
            tile: .consecration,
            span: span,
            surface: .painting(ConsecrationPhase.consecrationDay.heroImageName),
            padding: padding,
            onTap: open,
            accessibilityLabel: "Consecration, made. Revisit."
        ) {
            EmptyView()
        } floor: {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        AppIcon("ph-seal-check-fill", size: span == 2 ? 20 : 16)
                            .foregroundColor(AppColors.gold)
                        Text("Consecrated")
                            .font(AppFonts.titleFont(span == 2 ? 26 : 18))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    if let date = progress.completedAt {
                        Text("On \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppFonts.italicFont(span == 2 ? 16 : 14))
                            .foregroundColor(AppColors.cream.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                if span == 2 {
                    Spacer(minLength: 0)
                    ChapelFootAct(title: "Revisit")
                        .frame(minHeight: 44)
                }
            }
            .padding(.bottom, span == 2 ? 16 : 14)
        }
        .frame(minHeight: minHeight)
    }

    // MARK: Not yet begun

    private var invitation: some View {
        ChapelTileFrame(
            tile: .consecration,
            span: span,
            surface: .painting(ConsecrationPhase.knowledgeOfMary.heroImageName),
            padding: padding,
            onTap: open,
            accessibilityLabel: "Total Consecration. A 33-day preparation to give yourself to Jesus through Mary. Begin."
        ) {
            EmptyView()
        } floor: {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Consecration")
                        .font(AppFonts.titleFont(span == 2 ? 26 : 18))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(span == 2
                         ? "A 33-day preparation to give yourself to Jesus through Mary."
                         : "Thirty-three days")
                        .font(AppFonts.italicFont(span == 2 ? 15 : 14))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if span == 2 {
                    Spacer(minLength: 0)
                    ChapelFootAct(title: "Begin")
                        .frame(minHeight: 44)
                }
            }
            .padding(.bottom, span == 2 ? 16 : 14)
        }
        .frame(minHeight: minHeight)
    }
}

/// The segmented road: four tracks as long as their preparations, the
/// days walked filled in gold.
private struct ChapelRoad: View {
    let day: Int
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            let unit = max(0, geo.size.width - 12) / 33
            HStack(spacing: 4) {
                ForEach(ChapelConsecrationTile.phases, id: \.name) { phase in
                    let length = phase.to - phase.from + 1
                    let walked = min(length, max(0, day - phase.from + 1))

                    Capsule()
                        .fill(AppColors.cream.opacity(0.18))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.goldCTAGradient)
                                .frame(width: CGFloat(walked) * unit)
                        }
                        .clipShape(Capsule())
                        .frame(width: CGFloat(length) * unit)
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Reading

/// The book left open, standing on a shelf with the others still under
/// way beside it as spines. One book at a time on the page — an oratory
/// has a book open on the prie-dieu, not a list of them — but the face
/// slides: a reader keeping two or three going swipes another forward,
/// or taps its spine where it stands beside the open one. Tapping the
/// face, or the foot's act, takes the book in front up where it was
/// left.
///
/// The body has doors of its own — the face and the spines — so the
/// tile is not one door. An earlier cut made it one: every spine then
/// opened the book in front of it, and the books behind could not be
/// reached from the tile at all.
///
/// The shelf shows no share of the book read: a percentage of a book is
/// a judgement of the reader, which the shelf never makes.
struct ChapelReadingTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    @Query(sort: \BookReadingProgress.updatedAt, order: .reverse)
    private var progress: [BookReadingProgress]

    /// Which book's face is forward. Nil until the reader brings one
    /// forward; the most recent stands in front until then.
    @State private var shownID: String?

    private typealias Entry = (row: BookReadingProgress, info: LibraryBookInfo)

    /// Every book with a reading under way, most recent first. Books the
    /// catalog no longer carries fall out rather than drawing a face
    /// with no cloth.
    private var underWay: [Entry] {
        progress.compactMap { row in
            guard let info = LibraryCatalog.book(id: row.bookID) else { return nil }
            return (row, info)
        }
    }

    /// The book showing: the one brought forward, else the most recent.
    private var shownBookID: String? {
        underWay.contains { $0.row.bookID == shownID } ? shownID : underWay.first?.row.bookID
    }

    private var front: Entry? { underWay.first { $0.row.bookID == shownBookID } }

    /// The books standing beside `entry` — everything under way but it
    private func others(than entry: Entry) -> [Entry] {
        underWay.filter { $0.row.bookID != entry.row.bookID }
    }

    var body: some View {
        if let front {
            ChapelTileFrame(
                tile: .reading,
                span: span,
                surface: .cloth,
                note: span == 2 ? restNote(front) : nil,
                act: "Continue",
                footRuled: span == 1,
                onAct: { takeUp(front.row, front.info) }
            ) {
                if span == 2 { full } else { half(front) }
            }
        } else {
            empty
        }
    }

    // MARK: Full — the open book, its fellows beside it, its facts

    /// The open book's cover, which the spines stand level with
    private static let fullCover = CGSize(width: 76, height: 110)
    private static let halfCover = CGSize(width: 54, height: 78)

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            pager { page in
                fullPage(page)
            }
            // The cover's height, and room above it for the ribbon
            .frame(height: Self.fullCover.height + 4)
            .padding(.top, 14)
            .padding(.horizontal, 4)

            ChapelShelfLine()
                .padding(.horizontal, -18)
        }
    }

    /// One face of the full tile: the open book with its fellows standing
    /// beside it, and its title and place. Tapping the cover or the
    /// words takes the book up; tapping a spine brings that book forward.
    private func fullPage(_ entry: Entry) -> some View {
        HStack(alignment: .bottom, spacing: 18) {
            HStack(alignment: .bottom, spacing: 0) {
                Button(action: { takeUp(entry.row, entry.info) }) {
                    ChapelBookCover(
                        color: entry.info.bindingColor,
                        width: Self.fullCover.width,
                        height: Self.fullCover.height,
                        ornamented: true,
                        ribbon: true,
                        ribbonLength: 35
                    )
                }
                .buttonStyle(SacredCardButtonStyle())
                // The words beside it carry the same door, with its label
                .accessibilityHidden(true)

                ForEach(Array(others(than: entry).prefix(2).enumerated()), id: \.element.row.bookID) { index, other in
                    spineButton(other, height: index == 0 ? 104 : 98)
                }
            }

            Button(action: { takeUp(entry.row, entry.info) }) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.info.title)
                        .font(AppFonts.titleFont(17))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(placeLine(entry))
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.cream.opacity(0.8))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(entry.info.title), \(chapterLine(entry.row) ?? "under way"). Continue reading.")
        }
    }

    /// "Two more open" — the rest of the shelf still under way
    private func restNote(_ entry: Entry) -> String? {
        switch others(than: entry).count {
        case 0:  return nil
        case 1:  return "One more open"
        case 2:  return "Two more open"
        case 3:  return "Three more open"
        case let count: return "\(count) more open"
        }
    }

    /// "St. Thérèse · Chapter IV" — whose book it is, and where the
    /// reader left it
    private func placeLine(_ entry: Entry) -> String {
        let author = Self.shortAuthor(entry.info)
        guard let chapter = chapterLine(entry.row) else { return author }
        return "\(author) · \(chapter)"
    }

    // MARK: Half — the book on its shelf, its facts beneath

    private func half(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            pager { page in
                halfPage(page)
            }
            .frame(height: Self.halfCover.height + 4)
            .padding(.top, 12)
            .padding(.horizontal, 2)

            ChapelShelfLine()
                .padding(.horizontal, -14)

            Button(action: { takeUp(entry.row, entry.info) }) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.info.title)
                        .font(AppFonts.titleFont(13.5))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(chapterLine(entry.row) ?? Self.shortAuthor(entry.info))
                        .font(AppFonts.italicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.bottom, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(entry.info.title), \(chapterLine(entry.row) ?? "under way"). Continue reading.")
            .animation(Motion.crossfade, value: entry.row.bookID)
        }
    }

    private func halfPage(_ entry: Entry) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            Button(action: { takeUp(entry.row, entry.info) }) {
                ChapelBookCover(
                    color: entry.info.bindingColor,
                    width: Self.halfCover.width,
                    height: Self.halfCover.height,
                    ornamented: true,
                    ribbon: true,
                    ribbonLength: 24
                )
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityHidden(true)

            ForEach(Array(others(than: entry).prefix(2).enumerated()), id: \.element.row.bookID) { index, other in
                spineButton(other, height: index == 0 ? 74 : 70)
            }

            Spacer(minLength: 0)
        }
    }

    /// A standing spine that brings its book forward — the same move as
    /// swiping the face, one tap instead. Drawn 11 wide; answers to 20.
    private func spineButton(_ entry: Entry, height: CGFloat) -> some View {
        Button {
            withAnimation(Motion.crossfade) {
                shownID = entry.row.bookID
            }
        } label: {
            ChapelBookSpine(color: entry.info.bindingColor, height: height)
                .frame(width: 20, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bring \(entry.info.title) forward")
    }

    // MARK: The slide

    /// The books beside each other, one face showing — a reader keeping
    /// several going swipes any of them forward, and a spine tapped
    /// scrolls to its own book through the same binding.
    private func pager<Page: View>(
        @ViewBuilder page: @escaping (Entry) -> Page
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(underWay, id: \.row.bookID) { entry in
                    page(entry)
                        // On the pager's floor, the shelf, with the room
                        // above for the ribbon standing over the cover
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .containerRelativeFrame(.horizontal)
                        .id(entry.row.bookID)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $shownID)
    }

    // MARK: Empty — the shelf's cloths, and an invitation

    private var empty: some View {
        ChapelTileFrame(
            tile: .reading,
            span: span,
            surface: .cloth,
            act: "The shelf",
            footRuled: span == 1,
            onTap: { router.push(.spiritualReading) },
            accessibilityLabel: "Reading. Nothing open yet — take up and read. Opens the shelf."
        ) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(LibraryCatalog.books.prefix(span == 2 ? 4 : 3)) { book in
                        ChapelBookCover(color: book.bindingColor, width: 26, height: 38, shadowed: false)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 16)
                .padding(.horizontal, 4)

                ChapelShelfLine()
                    .padding(.horizontal, span == 2 ? -18 : -14)

                Text("Tolle, lege — take up and read.")
                    .font(AppFonts.italicFont(span == 2 ? 14 : 12.5))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
            }
        }
    }

    // MARK: Bits

    private func chapterLine(_ row: BookReadingProgress) -> String? {
        guard LibraryProgressStore.isCurrent(row), !row.lastChapterTitle.isEmpty
        else { return nil }
        return row.lastChapterTitle
    }

    /// The author as a tile has room to say — the name a reader knows
    /// the book by, the way "De Montfort" stands for the saint.
    private static func shortAuthor(_ info: LibraryBookInfo) -> String {
        switch info.id {
        case "imitation-of-christ":         return "à Kempis"
        case "story-of-a-soul":             return "St. Thérèse"
        case "confessions-of-st-augustine": return "St. Augustine"
        case "dolorous-passion":            return "Emmerich"
        default:                            return info.author
        }
    }

    /// Resumes whichever hand the book was last held in: the voice if it
    /// was heard since the page was last read, else the page itself.
    private func takeUp(_ row: BookReadingProgress, _ info: LibraryBookInfo) {
        let listened = row.lastListenedAt ?? .distantPast
        let read = row.lastReadAt ?? .distantPast

        if row.hasResumableTrack, listened > read {
            router.push(.libraryBook(id: info.id))
        } else if LibraryProgressStore.isCurrent(row) {
            router.push(.libraryChapter(bookID: info.id, chapterIndex: row.lastChapterIndex))
        } else {
            router.push(.libraryBook(id: info.id))
        }
    }
}

/// The shelf the books stand on: a gilt edge fading at both ends, with
/// the shadow it throws.
private struct ChapelShelfLine: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.gold.opacity(0), location: 0),
                .init(color: AppColors.gold.opacity(0.4), location: 0.12),
                .init(color: AppColors.gold.opacity(0.4), location: 0.88),
                .init(color: AppColors.gold.opacity(0), location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .shadow(color: .black.opacity(0.45), radius: 5, y: 6)
        .accessibilityHidden(true)
    }
}

/// A small cloth cover, drawn rather than imaged: the binding colour lit
/// from the upper left, gilt rules at head and tail, and — ornamented —
/// a diamond between them and a marker ribbon over the top edge.
struct ChapelBookCover: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var ornamented: Bool = false
    var ribbon: Bool = false
    var ribbonLength: CGFloat = 12
    var shadowed: Bool = true

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                // The Home shelf's own ramp — lit from the upper left,
                // falling toward the fore-edge. A fade to the colour's
                // own transparency washed the cloth toward the page
                LinearGradient(
                    colors: [color.lightened(by: 0.10), color, color.darkened(by: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if ornamented {
                    VStack(spacing: 0) {
                        gilt
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.75))
                            .frame(width: 6, height: 6)
                            .rotationEffect(.degrees(45))
                        Spacer(minLength: 0)
                        gilt
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal, 8)
                } else if width >= 30 {
                    VStack(spacing: 0) {
                        gilt
                        Spacer(minLength: 0)
                        gilt
                    }
                    .padding(.vertical, 7)
                }
            }
            // The spine's edge, shadowed where the boards meet it
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(alignment: .topTrailing) {
                if ribbon {
                    ChapelRibbon()
                        .fill(AppColors.gold)
                        .frame(width: 5, height: ribbonLength)
                        .padding(.trailing, width * 0.16)
                        .offset(y: -3)
                        .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                }
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(shadowed ? 0.5 : 0), radius: 7, y: 6)
            .accessibilityHidden(true)
    }

    private var gilt: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.6))
            .frame(height: AppLine.hairline)
    }
}

/// A silk marker with its swallowtail end.
private struct ChapelRibbon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.82))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A small standing spine in a book's binding colour, gilt-ruled near
/// head and tail — drawn, never imaged.
private struct ChapelBookSpine: View {
    let color: Color
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [color.darkened(by: 0.2), color.lightened(by: 0.06), color.darkened(by: 0.16)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                VStack {
                    Rectangle().fill(AppColors.gold.opacity(0.55)).frame(height: AppLine.hairline)
                    Spacer()
                    Rectangle().fill(AppColors.gold.opacity(0.55)).frame(height: AppLine.hairline)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 2)
            )
            .frame(width: 11, height: height)
            .accessibilityHidden(true)
    }
}

// MARK: - Liturgy

/// The day as the Church keeps it: the date on a calendar leaf, the
/// feast with its class and its colour, and a ledger of the Church's own
/// two books for it — the Mass by its Introit, the Office by the hour it
/// is. Split out of the Library so one heading is true of everything
/// beneath it: these are the liturgy, and the rest of the shelf is not.
///
/// The feast, its class and its colour are the missal's, read through
/// the page's `TodayInChurch`, and the Introit is the day's own proper.
/// Until the day is known — or with the missal unreachable — the leaf
/// says the plain thing and the doors still open.
struct ChapelLiturgyTile: View {

    let span: Int
    let today: TodayInChurch

    @Environment(AppRouter.self) private var router

    private var hour: CanonicalHour { CanonicalClock.shared.hour }

    var body: some View {
        ChapelTileFrame(
            tile: .liturgy,
            span: span,
            surface: .deep,
            note: span == 2 ? "1962" : nil
        ) {
            if span == 2 { fullDay } else { halfDay }
        } floor: {
            if span == 2 { fullLedger } else { halfLedger }
        }
    }

    /// "III class · white", whichever parts the day carries
    private var rankLine: String? {
        let parts = [today.proper?.info.rankLabel, today.vestment?.name.lowercased()].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: Full — the leaf and the feast, the ledger beneath

    private var fullDay: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(spacing: 2) {
                Text(Date.now.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .lineLimit(1)

                Text(Date.now.formatted(.dateTime.day()))
                    .font(AppFonts.titleFont(30))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
            }
            .frame(width: 64)
            .padding(.top, 10)
            .padding(.bottom, 9)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColors.gold.opacity(0.3), lineWidth: AppLine.hairline)
            )
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 4) {
                Text(today.title)
                    .font(AppFonts.titleFont(23))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(Motion.crossfade, value: today.title)

                if let rankLine {
                    HStack(spacing: 8) {
                        if let vestment = today.vestment {
                            Rectangle()
                                .fill(vestment.swatch)
                                .frame(width: 7, height: 7)
                                .rotationEffect(.degrees(45))
                                .accessibilityHidden(true)
                        }

                        Text(rankLine)
                            .font(AppFonts.italicFont(14))
                            .foregroundColor(AppColors.cream.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .transition(.opacity)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    private var fullLedger: some View {
        VStack(spacing: 0) {
            ledgerRow(
                kicker: "Holy Mass",
                title: today.introitIncipit ?? "Daily Missal",
                line: today.introitIncipit == nil ? "The propers of the day" : "The Introit of the day",
                route: .missal,
                divided: true
            )
            ledgerRow(
                kicker: "Office",
                title: hour.label,
                line: "The hour now",
                route: .office,
                divided: false
            )
        }
        .padding(.bottom, 6)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.16))
                .frame(height: AppLine.hairline)
        }
    }

    private func ledgerRow(kicker: String, title: String, line: String, route: AppRoute, divided: Bool) -> some View {
        Button {
            router.push(route)
        } label: {
            HStack(spacing: 12) {
                Text(kicker.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 92, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.titleFont(15.5))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(line)
                        .font(AppFonts.italicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                AppIcon("ph-caret-right", size: 10)
                    .foregroundColor(AppColors.gold)
            }
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if divided {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.14))
                    .frame(height: AppLine.hairline)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kicker): \(title), \(line.lowercased())")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Half — the date and the feast over two doors

    private var halfDay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .lineLimit(1)

            Text(today.title)
                .font(AppFonts.titleFont(17))
                .foregroundColor(AppColors.cream)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(Motion.crossfade, value: today.title)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var halfLedger: some View {
        VStack(spacing: 0) {
            halfDoor("Holy Mass", route: .missal, divided: true)
            halfDoor(hour.label, route: .office, divided: false)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.16))
                .frame(height: AppLine.hairline)
        }
    }

    private func halfDoor(_ title: String, route: AppRoute, divided: Bool) -> some View {
        Button {
            router.push(route)
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.italicFont(14.5))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                AppIcon("ph-caret-right", size: 9)
                    .foregroundColor(AppColors.gold)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if divided {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.14))
                    .frame(height: AppLine.hairline)
            }
        }
        .accessibilityLabel(route == .office ? "The Office: \(title)" : title)
    }
}

private extension TodayInChurch {
    /// The day's Mass named the way a missal's index names it: by the
    /// first words of its Introit, in Latin — "In medio Ecclesiae",
    /// "Gaudeamus omnes". Nil until the propers are known, or when the
    /// day carries no Introit the app can read.
    var introitIncipit: String? {
        guard let section = proper?.sections.first(where: {
            ($0.id ?? "").lowercased().hasPrefix("introit")
        }) else { return nil }

        for passage in section.body {
            // Each passage is an [english, latin] pair; a single-element
            // passage carries the same text for both
            let latin = passage.count > 1 ? passage[1] : (passage.first ?? "")
            for line in latin.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                // A line in asterisks is the citation, not the text
                guard !trimmed.isEmpty, !trimmed.hasPrefix("*") else { continue }
                return Self.incipit(of: trimmed)
            }
        }
        return nil
    }

    /// The opening words of a line, up to its first stop and no more than
    /// three of them, with the marks a missal prints before a text left off
    static func incipit(of line: String) -> String? {
        let stops = CharacterSet(charactersIn: ":;,.!?")
        let opening = line.components(separatedBy: stops).first ?? line
        let words = opening
            .replacingOccurrences(of: "℣.", with: "")
            .replacingOccurrences(of: "℟.", with: "")
            .replacingOccurrences(of: "Ant.", with: "")
            .split(whereSeparator: \.isWhitespace)
            .prefix(3)
        guard !words.isEmpty else { return nil }
        return words.joined(separator: " ")
    }
}

// MARK: - Library

/// The chapel's shelf, bound like a book: the books and the guides as a
/// ruled index of doors, each with a line saying what it holds, over
/// Augustine's line. The liturgy has its own tile, so this heading is
/// true of every door beneath it.
struct ChapelLibraryTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    private struct Door {
        let title: String
        let line: String
        let route: AppRoute
    }

    private static let books: [Door] = [
        Door(title: "True Devotion", line: "St. Louis de Montfort", route: .trueDevotionBook),
        Door(title: "Spiritual Reading", line: "The saints\u{2019} own books", route: .spiritualReading),
        Door(title: "Marian Library", line: "Our Lady in the tradition", route: .marianLibrary)
    ]

    private static let guides: [Door] = [
        Door(title: "How to Pray", line: "The Rosary, step by step", route: .howToPray),
        Door(title: "In Scripture", line: "Each mystery in the Gospel", route: .scripture),
        Door(title: "Carlo Acutis", line: "A saint of our day", route: .carloAcutis)
    ]

    var body: some View {
        if span == 2 {
            ChapelTileFrame(
                tile: .library,
                span: 2,
                surface: .bound,
                padding: EdgeInsets(top: 20, leading: 22, bottom: 4, trailing: 22)
            ) {
                full
            }
        } else {
            ChapelTileFrame(
                tile: .library,
                span: 1,
                surface: .bound,
                act: "Three more",
                footRuled: false,
                onAct: { router.push(.explore) }
            ) {
                half
            }
        }
    }

    // MARK: Full — the index, and the colophon

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                section("Books", Self.books)
                section("Guides", Self.guides)
            }
            .padding(.top, 18)
            .padding(.bottom, 10)

            Text("Our heart is restless until it rests in thee.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .padding(.bottom, 18)
        }
    }

    private func section(_ name: String, _ doors: [Door]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(doors.enumerated()), id: \.element.title) { index, door in
                doorRow(door, size: 17, minHeight: 54, showsLine: true, divided: index < doors.count - 1)
            }
        }
    }

    // MARK: Half — the books, and a door to the rest

    private var half: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Self.books, id: \.title) { door in
                doorRow(door, size: 15, minHeight: 44, showsLine: false, divided: true)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    private func doorRow(_ door: Door, size: CGFloat, minHeight: CGFloat, showsLine: Bool, divided: Bool) -> some View {
        Button {
            router.push(door.route)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(door.title)
                        .font(AppFonts.bodyFont(size))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if showsLine {
                        Text(door.line)
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                AppIcon("ph-caret-right", size: 9)
                    .foregroundColor(AppColors.gold.opacity(0.7))
            }
            .frame(minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if divided {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.12))
                    .frame(height: AppLine.hairline)
            }
        }
        .accessibilityLabel(showsLine ? "\(door.title), \(door.line)" : door.title)
    }
}

// MARK: - Chant

/// Sung prayer kept close to hand: a round play control, the chant by
/// name, and a staff whose notes light as the chant is sung. The name
/// opens the chant's own page (its score, its practice); the foot's act
/// opens the Chant Library, where another is chosen. The tile holds
/// whatever the library last sang, or the antiphon of the season until
/// it has sung anything.
struct ChapelChantTile: View {

    let span: Int
    let player: ChantPlayer
    let onOpenChant: () -> Void
    let onOpenLibrary: () -> Void

    private var chant: Chant { player.current }

    /// What stands under the chant's name: a failure to play it, else the
    /// setting it is sung in, else its English name.
    private var statusLine: String {
        player.errorMessage ?? chant.setting ?? chant.englishTitle
    }

    /// The title line's note: how far into the chant, once it is sounding
    /// here; else that it is the season's antiphon, when it is.
    private var note: String? {
        if let elapsed = player.elapsedLabel { return elapsed }
        return ChantCatalog.antiphonOfTheSeason()?.id == chant.id ? "Antiphon of the season" : nil
    }

    var body: some View {
        ChapelTileFrame(
            tile: .chant,
            span: span,
            surface: .cloth,
            note: span == 2 ? note : nil,
            act: span == 2 ? "Chant library" : "Library",
            onAct: onOpenLibrary
        ) {
            if span == 2 { full } else { half }
        }
    }

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying,
                    isLoading: player.isLoading,
                    size: 50,
                    label: chant.latinTitle
                ) {
                    player.togglePlayback()
                }

                name(size: 15, tracking: 2.5, lineSize: 14, lines: 1)
            }
            .padding(.vertical, 16)

            staff
                .frame(height: 34)
                .padding(.top, 6)
                .padding(.horizontal, 2)
                .padding(.bottom, 14)
        }
    }

    private var half: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ChantPlayDisc(
                    isPlaying: player.isPlaying,
                    isLoading: player.isLoading,
                    size: 38,
                    label: chant.latinTitle
                ) {
                    player.togglePlayback()
                }

                name(size: 11, tracking: 1.5, lineSize: 12.5, lines: 2)
            }
            .padding(.vertical, 12)

            staff
                .frame(height: 24)
                .padding(.top, 4)
                .padding(.bottom, 6)
        }
    }

    /// The chant's name, in tracked capitals, over its setting — the door
    /// to its own page
    private func name(size: CGFloat, tracking: CGFloat, lineSize: CGFloat, lines: Int) -> some View {
        Button(action: onOpenChant) {
            VStack(alignment: .leading, spacing: 3) {
                Text(chant.latinTitle.uppercased())
                    .font(AppFonts.labelFont(size))
                    .tracking(tracking)
                    .foregroundColor(AppColors.cream)
                    .lineLimit(lines)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                Text(statusLine)
                    .font(AppFonts.italicFont(lineSize))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the chant with its score")
    }

    private var staff: some View {
        ChapelChantStaff(
            chantID: chant.id,
            progress: player.holds(chant) ? player.progress : nil
        )
    }
}

/// Four lines of a chant staff with a melody's square notes along them,
/// lit up to the point the chant has reached and dim beyond it, and the
/// playhead standing where the voice is. The melody is drawn for the
/// chant — the same line every time for the same chant — and is a
/// picture of chant, not its score: the score is a tap away on its page.
private struct ChapelChantStaff: View {
    let chantID: String

    /// 0…1 through the recording while the library holds it; nil when it
    /// is not loaded, and nothing is lit
    let progress: Double?

    private static let noteCount = 25

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let levels = Self.melody(for: chantID)
            let step = (width - 12) / CGFloat(Self.noteCount - 1)
            let head = progress.map { CGFloat($0) * width }

            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { line in
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.28))
                        .frame(width: width, height: AppLine.hairline)
                        .offset(y: height * CGFloat(line) / 3)
                }

                ForEach(0..<levels.count, id: \.self) { index in
                    let x = 4 + CGFloat(index) * step
                    let sung = head.map { x + 3.5 <= $0 } ?? false
                    RoundedRectangle(cornerRadius: 1)
                        .fill(sung ? AppColors.goldLight : AppColors.gold.opacity(0.38))
                        .frame(width: 7, height: 6)
                        .offset(x: x, y: Self.noteTop(level: levels[index], height: height))
                }

                if let head {
                    Rectangle()
                        .fill(AppColors.gold)
                        .frame(width: 1, height: height + 12)
                        .shadow(color: AppColors.gold.opacity(0.6), radius: 3)
                        .offset(x: min(max(head, 0), width), y: -6)
                }
            }
            // Glides between the player's ticks instead of stepping with
            // them
            .animation(.linear(duration: 0.5), value: progress)
        }
        .accessibilityHidden(true)
    }

    /// Where a note stands: level 0 on the second line from the bottom,
    /// each level a line or a space higher
    private static func noteTop(level: Int, height: CGFloat) -> CGFloat {
        height * 2 / 3 - CGFloat(level) * height / 6 - 3
    }

    /// A melody walked a step at a time, seeded by the chant's id so the
    /// same chant always draws the same line
    private static func melody(for id: String) -> [Int] {
        var seed: UInt64 = 1_469_598_103_934_665_603
        for byte in id.utf8 {
            seed = (seed ^ UInt64(byte)) &* 1_099_511_628_211
        }
        var level = 0
        var levels: [Int] = []
        for _ in 0..<noteCount {
            levels.append(level)
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let move = Int((seed >> 33) % 3) - 1
            level = min(4, max(-1, level + move))
        }
        return levels
    }
}

// MARK: - Reflections

/// The latest journal entry, opened by an illuminated versal — writing,
/// not a list. An entry that opens on a quotation mark has its mark
/// gilded in the letter's place; one that opens on no letter at all
/// takes a gold rule down its side instead. The whole tile opens the
/// journal.
struct ChapelReflectionsTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    /// One entry, because one is all the tile draws. Unlimited, this
    /// materialized every reflection the user has ever written on every
    /// change to the store, for a single line of text.
    @Query(Self.latestEntry)
    private var entries: [JournalEntry]

    private static var latestEntry: FetchDescriptor<JournalEntry> {
        var descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\JournalEntry.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return descriptor
    }

    private var latest: JournalEntry? { entries.first }

    private func open() {
        router.switchTo(.journal)
    }

    var body: some View {
        if let latest {
            let text = tileText(latest)
            let day = Self.dayNote(latest.createdAt)
            ChapelTileFrame(
                tile: .reflections,
                span: span,
                surface: .quote,
                note: span == 2 ? day : nil,
                act: span == 2 ? "Open the journal" : nil,
                footNote: span == 2 ? nil : day,
                onTap: open,
                accessibilityLabel: "Reflections, \(day). \(text). Opens the journal."
            ) {
                entryBlock(
                    text,
                    versalSize: span == 2 ? 50 : 36,
                    bodySize: span == 2 ? 16.5 : 14.5,
                    lines: span == 2 ? 3 : 5
                )
                .padding(.top, span == 2 ? 16 : 14)
                .padding(.bottom, span == 2 ? 12 : 8)
            }
        } else {
            ChapelTileFrame(
                tile: .reflections,
                span: span,
                surface: .quote,
                act: span == 2 ? "Open the journal" : "Journal",
                onTap: open,
                accessibilityLabel: "Reflections. Your reflections will gather here after prayer. Opens the journal."
            ) {
                Text("Your reflections will gather here after prayer.")
                    .font(AppFonts.italicFont(span == 2 ? 15 : 13))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
            }
        }
    }

    // MARK: Bits

    /// When the entry was written, as a reader says it: "Today",
    /// "Yesterday", the weekday through the week, then the date.
    private static func dayNote(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        if days < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// What the tile quotes from the entry. A passage kept from a book is
    /// set as the quotation it is, without the citation and its rights
    /// note — the journal's own page sets those apart, and on a tile of
    /// a few lines they crowded out the passage. Any other entry is the
    /// journal's own preview, its newlines flattened, so a paragraph
    /// break never spends one of those lines on nothing.
    private func tileText(_ entry: JournalEntry) -> String {
        if let kept = entry.keptPassage {
            let passage = kept.passage
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            return "\u{201C}\(passage)\u{201D}"
        }
        return entry.previewText
    }

    /// The entry under its versal — the gilded first letter, or the
    /// gilded opening mark when the entry begins on a quotation — or,
    /// when it opens on no letter at all, beside a rule of gold fading
    /// down.
    private func entryBlock(_ text: String, versalSize: CGFloat, bodySize: CGFloat, lines: Int) -> some View {
        let cut = VersalCut.of(text)
        let opensOnQuotation = cut?.opensOnQuotation ?? false

        // The words beside the illumination: after the letter when the
        // letter is gilded, and as typed — case and all — after the mark
        // when the mark is
        let words = cut.map { opensOnQuotation ? $0.wordsAfterLead : $0.rest } ?? text

        // A few lines of the reader's own writing, in the upright medium
        // face, which holds its weight on the dark ground, at a reading
        // leading of about one and a half
        let writing = Text(words)
            .font(AppFonts.bodyFont(bodySize))
            .foregroundColor(AppColors.cream.opacity(0.92))
            .lineSpacing((bodySize * 0.36).rounded())
            .lineLimit(lines)

        return Group {
            if let cut {
                // A hair between the initial and the rest of its word: the
                // two are separate views, and any more air than that splits
                // "Be" into "B  e". A mark stands off its words a little more.
                HStack(alignment: .top, spacing: opensOnQuotation ? 9 : 6) {
                    versalText(cut, size: versalSize, bodySize: bodySize)
                        .shadow(color: AppColors.gold.opacity(0.35), radius: 7)
                        .frame(height: versalSize * 0.8, alignment: opensOnQuotation ? .topLeading : .bottomLeading)
                        .padding(.top, 4)

                    writing
                }
            } else {
                // The rule is laid over the words' own margin, so it runs
                // exactly as tall as they do. As a sibling in a stack sized
                // to its content it was offered no height to fill, and
                // stood as a ten-point stub at the top.
                writing
                    .padding(.leading, 11)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.gold, AppColors.gold.opacity(0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2)
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    /// The illumination, cut by the rule every versal in the app
    /// follows (`VersalCut`): the entry's first letter, capitalised —
    /// or, when the entry opens on a quotation, the opening mark itself
    /// gilded in place of a letter, as `DropCapText` sets it on the
    /// journal's own pages. Cinzel's mark fills only the upper third of
    /// its em, so it is set larger to stand as tall as a letter would.
    /// An apostrophe the entry opens on ('Tis) is no quotation: it stays
    /// at the body size, hung before the gilded letter it belongs to.
    private func versalText(_ cut: VersalCut, size: CGFloat, bodySize: CGFloat) -> Text {
        if cut.opensOnQuotation {
            return Text(cut.lead)
                .font(AppFonts.titleFont((size * 1.5).rounded()))
                .foregroundColor(AppColors.gold)
        }
        return Text(cut.lead)
            .font(AppFonts.bodyFont(bodySize))
            .foregroundColor(AppColors.cream.opacity(0.92))
        + Text(cut.letter)
            .font(AppFonts.titleFont(size))
            .foregroundColor(AppColors.gold)
    }
}
