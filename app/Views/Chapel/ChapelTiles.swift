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
//  One anatomy for every tile, at both spans (the "Chapel Tiles"
//  handoff): a kicker on the page above the shell — a 12pt glyph, a
//  tracked label, a trailing italic note — then one 16pt hairline shell
//  with no fill and no shadow, and a foot pinned to its floor: an
//  italic note on the left, a gold text act on the right. The grid's
//  rows stretch, so two halves always end on the same line. The tile's
//  own character lives in its body and nowhere else: a ledger, a road,
//  an open book, a diptych, an index, a transport, a versal, an orb.
//
//  The page once drew three registers — ruled, outlined at 16, outlined
//  at 20 — with kickers on some tiles and not others, centred halves
//  beside left-aligned ones, and rows that top-aligned with ragged
//  bottoms. Any tile now sits well beside any other. Halves are
//  left-aligned, never centred, and lead with one figure: a number in
//  Cinzel 26 with its denominator muted at 15, or a headline at 14–15,
//  then one italic line.
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

    var id: String { shortcut.rawValue }

    /// The act's name as the ledger and the focus block set it.
    var focusTitle: String { shortcut.actName }

    /// The gold act under the focus title.
    var focusAction: String {
        switch shortcut {
        case .todaysRosary:     return "Pray with a Meditation"
        case .chooseMeditation: return "Choose a Meditation"
        case .sevenSorrows:     return "Begin the Chaplet"
        case .scripturalRosary: return "Begin the Scriptural Rosary"
        case .mass:             return "Begin the Mass"
        case .office:           return "Begin the Office"
        case .consecration:     return "Continue the Preparation"
        }
    }

    /// The gold word on the ledger row's trailing act — CONTINUE for a
    /// preparation already under way, BEGIN for everything else.
    var rowAction: String {
        shortcut == .consecration ? "Continue" : "Begin"
    }
}

// MARK: - The shared anatomy

/// The measures every tile is built to, in one place, so the grid's
/// furniture (the ✕ badge) can find the shell's corner without asking.
enum ChapelTileMetrics {
    /// The kicker's line on the page above the shell
    static let kickerHeight: CGFloat = 18
    /// The air between the kicker and the shell's top edge
    static let kickerGap: CGFloat = 10
    /// Where the shell begins, measured from the tile's top
    static var shellTop: CGFloat { kickerHeight + kickerGap }
    static let cornerRadius: CGFloat = 16
}

/// The kicker every tile opens with, on the page above its shell: a
/// 12pt glyph, a tracked label, and room for a trailing italic note.
/// The same sizes at both spans, so a pair of halves shares one title
/// line; at half width the label truncates before the note does.
struct ChapelKicker: View {
    let icon: String
    let title: String
    var note: String? = nil

    /// Edits the tile's own list (the Today tile's rule) from its title
    /// line, where a list's edit control is looked for. As EDIT RULE in
    /// the foot it stood at the right under the rows, lined up with their
    /// BEGIN and CONTINUE, and read as one more of them.
    var onEdit: (() -> Void)? = nil

    init(_ icon: String, _ title: String, note: String? = nil, onEdit: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.note = note
        self.onEdit = onEdit
    }

    var body: some View {
        HStack(spacing: 7) {
            AppIcon(icon, size: 12)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .accessibilityHidden(true)

            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2.5)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: note == nil && onEdit == nil ? 0 : 8)

            if let note {
                ChapelKickerNote(note)
                    .layoutPriority(1)
            }

            if let onEdit {
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        AppIcon("ph-pencil-simple", size: 11)
                        Text("EDIT")
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                    }
                    .foregroundColor(AppColors.gold)
                    .padding(.leading, 12)
                    // Drawn to the title line's height, answering to 44:
                    // a taller kicker would break the line a pair of
                    // halves shares
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.vertical, -(44 - ChapelTileMetrics.kickerHeight) / 2)
                }
                .buttonStyle(QuietGlyphButtonStyle())
                .accessibilityLabel("Edit \(title.lowercased())")
                .layoutPriority(1)
            }
        }
        .frame(minHeight: ChapelTileMetrics.kickerHeight)
    }
}

/// The italic note on a kicker's right — "2 of 4 offered", "Lit today".
struct ChapelKickerNote: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(1)
            // A count or a clock rolls its digits; a word crossfades
            .contentTransition(
                text.contains(where: \.isNumber) ? ContentTransition.numericText() : .opacity
            )
            .animation(Motion.crossfade, value: text)
    }
}

/// A 1pt rule inside a shell — under the Today tile's opening line.
struct ChapelRule: View {
    var opacity: Double = 0.22

    var body: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(opacity))
            .frame(height: 1)
    }
}

/// The 16pt-radius hairline every shell is drawn with: no fill, no
/// shadow. The flame stands in it like everything else.
struct ChapelOutline: ViewModifier {
    var cornerRadius: CGFloat = ChapelTileMetrics.cornerRadius
    var borderOpacity: Double = 0.24

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AppColors.gold.opacity(borderOpacity), lineWidth: AppLine.hairline)
        )
    }
}

/// The one shell: the design's padding at each span, filling whatever
/// height the row offers so its foot can be pinned to the floor.
struct ChapelShell<Content: View>: View {
    let span: Int

    /// A list-style body (rows of doors) sits closer to the shell's top
    /// edge than a body that opens on a figure.
    var topPadding: CGFloat? = nil

    let content: Content

    init(span: Int, topPadding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.span = span
        self.topPadding = topPadding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.top, topPadding ?? (span == 2 ? 14 : 12))
        .padding(.horizontal, span == 2 ? 16 : 14)
        .padding(.bottom, span == 2 ? 6 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(ChapelOutline())
    }
}

/// The italic line at a foot's left — a fact, never a judgement.
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
    }
}

/// The gold text act every foot closes on — "CONTINUE ›".
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

/// A tile's foot, pinned to the shell's floor by the Spacer above it.
/// Full: the note on the left, the act on the right. Half: the act
/// alone, left-aligned — or the note alone where a tile has no act.
///
/// The act is a button of its own only when the tile's body has doors
/// of its own; otherwise the whole tile is the door and the act is a
/// label inside it.
struct ChapelFoot<Note: View>: View {
    let span: Int
    let act: String?
    var ruled: Bool = false
    var action: (() -> Void)? = nil
    let note: Note

    init(
        span: Int,
        act: String?,
        ruled: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder note: () -> Note
    ) {
        self.span = span
        self.act = act
        self.ruled = ruled
        self.action = action
        self.note = note()
    }

    var body: some View {
        Group {
            if span == 2 { full } else { half }
        }
        .padding(.top, ruled ? 4 : 0)
        .overlay(alignment: .top) {
            if ruled {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.18))
                    .frame(height: AppLine.hairline)
            }
        }
    }

    private var full: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) { note }
                .frame(maxWidth: .infinity, alignment: .leading)

            if let act {
                actView(act)
            }
        }
        // A foot with no act (the Liturgy's feast line) keeps the
        // height an act would have given it
        .frame(minHeight: 44)
    }

    private var half: some View {
        HStack(spacing: 0) {
            if let act {
                // Drawn 32 tall, answering to 44: the design's half foot
                // is shallow, and the tap target is not.
                actView(act)
                    .padding(.vertical, -6)
            } else {
                ZStack(alignment: .leading) { note }
                    .frame(minHeight: 32, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
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

/// A hold on the quiet parts of a tile — its kicker, its shell between
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

/// The whole anatomy, assembled: kicker, shell, body, foot. A tile
/// hands it a body and, at most, a foot note; everything else is the
/// design's. With `onTap` the entire tile — kicker, shell and foot —
/// is one door; without it, `onAct` makes the foot's act the only
/// control the frame draws, for tiles whose bodies carry their own.
///
/// Either way a hold arranges the page. The tiles cover most of it, and
/// the page's own hold lives behind them, so a tile that took no hold
/// left "press and hold anywhere" true only of the gaps.
struct ChapelTileFrame<Content: View, FootNote: View>: View {
    let tile: ChapelTile
    let span: Int
    var note: String? = nil
    var shellTop: CGFloat? = nil
    var act: String? = nil
    var footRuled: Bool = false

    /// Edits the tile's own list from its title line; see `ChapelKicker`
    var onEdit: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var onAct: (() -> Void)? = nil
    var accessibilityLabel: String? = nil
    let content: Content
    let footNote: FootNote

    @Environment(AppRouter.self) private var router

    /// A finger resting on a tile that opens on a tap: the card press
    /// settle, drawn here because the tile is not a Button
    @State private var pressed = false

    init(
        tile: ChapelTile,
        span: Int,
        note: String? = nil,
        shellTop: CGFloat? = nil,
        act: String? = nil,
        footRuled: Bool = false,
        onEdit: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        onAct: (() -> Void)? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footNote: () -> FootNote
    ) {
        self.tile = tile
        self.span = span
        self.note = note
        self.shellTop = shellTop
        self.act = act
        self.footRuled = footRuled
        self.onEdit = onEdit
        self.onTap = onTap
        self.onAct = onAct
        self.accessibilityLabel = accessibilityLabel
        self.content = content()
        self.footNote = footNote()
    }

    var body: some View {
        if let onTap {
            // A tap and a hold, as two gestures rather than a Button: a
            // Button fires on release, so a hold that had just arranged
            // the page would also have opened the tile under the finger
            frame
                .scaleEffect(pressed ? 0.98 : 1)
                .opacity(pressed ? 0.92 : 1)
                .animation(.easeOut(duration: 0.18), value: pressed)
                .contentShape(Rectangle())
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
            frame
        }
    }

    private var frame: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker(tile.icon, span == 2 ? tile.title : tile.shortTitle, note: note, onEdit: onEdit)
                .padding(.bottom, ChapelTileMetrics.kickerGap)
                .contentShape(Rectangle())
                .modifier(ChapelHoldToArrange(active: onTap == nil))

            ChapelShell(span: span, topPadding: shellTop) {
                content

                Spacer(minLength: 0)

                ChapelFoot(
                    span: span,
                    act: act,
                    ruled: footRuled,
                    action: onTap == nil ? onAct : nil
                ) {
                    footNote
                }
            }
            // Behind the body, so it answers only between the doors
            .background {
                if onTap == nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .modifier(ChapelHoldToArrange(active: true))
                }
            }
        }
    }
}

extension ChapelTileFrame where FootNote == EmptyView {
    init(
        tile: ChapelTile,
        span: Int,
        note: String? = nil,
        shellTop: CGFloat? = nil,
        act: String? = nil,
        footRuled: Bool = false,
        onEdit: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        onAct: (() -> Void)? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            tile: tile,
            span: span,
            note: note,
            shellTop: shellTop,
            act: act,
            footRuled: footRuled,
            onEdit: onEdit,
            onTap: onTap,
            onAct: onAct,
            accessibilityLabel: accessibilityLabel,
            content: content,
            footNote: { EmptyView() }
        )
    }
}

/// A half tile's leading figure: the number in Cinzel 26 with its
/// denominator muted at 15 — "12 days", "Day 14 / 33", "2 / 4".
private func chapelFigure(_ number: String, _ denominator: String) -> some View {
    (Text(number)
        .font(AppFonts.headlineFont(26))
        .foregroundColor(AppColors.cream)
     + Text(denominator)
        .font(AppFonts.headlineFont(15))
        .foregroundColor(AppColors.cream.opacity(0.45)))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
}

// MARK: - Today (the rule)

/// The user's rule of prayer, act by act. This is the tile that drives
/// the focus block at the top of the page — the ledger is the picker —
/// and the one tile that is not obviously a link, so it explains itself
/// in its first line and shows on every row what a tap will do.
struct ChapelRuleTile: View {

    let acts: [ChapelAct]
    let span: Int
    let onAct: (ChapelAct) -> Void
    let onEditRule: () -> Void

    private var doneCount: Int { acts.filter(\.done).count }
    private var next: ChapelAct? { acts.first { !$0.done } }

    var body: some View {
        // The title line carries EDIT, so the count stands in the foot at
        // full width; at half, the tile's figure already says it
        ChapelTileFrame(
            tile: .rule,
            span: span,
            shellTop: span == 2 ? 12 : nil,
            onEdit: onEditRule
        ) {
            if span == 2 { full } else { half }
        } footNote: {
            if span == 2, !acts.isEmpty {
                ChapelFootNote("\(doneCount) of \(acts.count) offered")
            }
        }
    }

    // MARK: Full — the ledger

    @ViewBuilder
    private var full: some View {
        Text("Your rule of prayer — the devotions you mean to offer each day.")
            .font(AppFonts.italicFont(13))
            .foregroundColor(AppColors.cream.opacity(0.8))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 10)

        ChapelRule()

        if acts.isEmpty {
            Text("No devotions on your rule yet.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .padding(.vertical, 16)
        } else {
            ForEach(acts) { act in
                row(act, isLast: act.id == acts.last?.id)
            }
        }
    }

    /// One act of the rule; the hairline runs between rows, never
    /// under the last, which the foot already rules off.
    private func row(_ act: ChapelAct, isLast: Bool) -> some View {
        let isNext = act.id == next?.id
        return Button(action: { onAct(act) }) {
            HStack(spacing: 15) {
                AppIcon(act.shortcut.icon, size: 17)
                    .foregroundColor(tint(act, isNext: isNext))
                    .frame(width: 24, height: 24)
                    .modifier(NextActHalo(active: isNext))

                VStack(alignment: .leading, spacing: 2) {
                    Text(act.focusTitle)
                        .font(AppFonts.bodyFont(15.5))
                        .foregroundColor(
                            act.done || isNext
                                ? AppColors.cream
                                : AppColors.cream.opacity(0.72)
                        )
                        .lineLimit(1)

                    Text(act.subtitle)
                        .font(AppFonts.bodyFont(11.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                trailing(act)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.11))
                    .frame(height: AppLine.hairline)
            }
        }
        .accessibilityLabel(accessibility(for: act))
    }

    /// What the row's tap does, drawn at its trailing edge: the seal
    /// once an act is offered, and BEGIN (or CONTINUE) until then —
    /// every act on the rule is one the app watches finish. The two
    /// crossfade in place as the act is offered.
    private func trailing(_ act: ChapelAct) -> some View {
        ZStack(alignment: .trailing) {
            if act.done {
                HStack(spacing: 6) {
                    Text("OFFERED")
                        .font(AppFonts.labelFont(8.5))
                        .tracking(1.5)
                        .foregroundColor(AppColors.gold.opacity(0.7))

                    AppIcon("ph-seal-check-fill", size: 20)
                        .foregroundColor(AppColors.gold)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                HStack(spacing: 6) {
                    Text(act.rowAction.uppercased())
                        .font(AppFonts.labelFont(9.5))
                        .tracking(2)
                    AppIcon("ph-caret-right", size: 9)
                }
                .foregroundColor(AppColors.gold)
                .frame(minHeight: 44)
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: act.done)
    }

    private func tint(_ act: ChapelAct, isNext: Bool) -> Color {
        if isNext { return AppColors.goldLight }
        return act.done ? AppColors.gold : AppColors.gold.opacity(0.45)
    }

    private func accessibility(for act: ChapelAct) -> String {
        act.done ? "\(act.focusTitle), offered." : "\(act.rowAction) \(act.focusTitle)"
    }

    // MARK: Half — the figure and a row of cells

    @ViewBuilder
    private var half: some View {
        if acts.isEmpty {
            Text("No devotions yet.")
                .font(AppFonts.italicFont(12.5))
                .foregroundColor(AppColors.textSecondary)
        } else {
            chapelFigure("\(doneCount)", " / \(acts.count)")

            // One 44pt row of equal cells, one per act, bleeding 8pt into
            // the shell's padding on each side. Each cell is the half
            // tile's only way to offer its act.
            HStack(spacing: 2) {
                ForEach(acts) { act in
                    cell(act)
                }
            }
            .padding(.horizontal, -8)
            .padding(.top, 8)
        }
    }

    private func cell(_ act: ChapelAct) -> some View {
        let isNext = act.id == next?.id
        return Button(action: { onAct(act) }) {
            VStack(spacing: 5) {
                AppIcon(act.shortcut.icon, size: 15)
                    .foregroundColor(tint(act, isNext: isNext))
                    .modifier(NextActHalo(active: isNext))

                RoundedRectangle(cornerRadius: 1)
                    .fill(tick(act, isNext: isNext))
                    .frame(width: 10, height: 2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.gold.opacity(isNext ? 0.07 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility(for: act))
    }

    private func tick(_ act: ChapelAct, isNext: Bool) -> AnyShapeStyle {
        if act.done { return AnyShapeStyle(AppColors.goldGradient) }
        return AnyShapeStyle(
            isNext ? AppColors.gold.opacity(0.45) : AppColors.cream.opacity(0.13)
        )
    }
}

/// The halo the next act's glyph carries.
private struct NextActHalo: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content
            .shadow(color: AppColors.gold.opacity(active ? 0.4 : 0), radius: 5)
            .animation(.easeOut(duration: 0.4), value: active)
    }
}

// MARK: - Prayer Streak

/// The streak as a burning orb, in the same shell as every other tile.
/// It never scolds: only days prayed are marked, the kicker says "Not
/// yet today" and never "missed", and the milestone ahead is an
/// invitation. The whole tile opens the Prayer Record.
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

    /// What the figure counts, said under it — so the streak is never
    /// read as this week's tally
    private var streakCaption: String {
        streak == 0 ? "Each day you pray adds one" : "In a row"
    }

    private var daysPrayedThisWeek: Int { weekStatus.filter(\.didPray).count }

    private var accessibilityLabel: String {
        var line = "Prayer Streak. \(streakLabel), \(litNote.lowercased())."
        if !weekStatus.isEmpty {
            line += " Prayed \(daysPrayedThisWeek) of 7 days this week."
        }
        return line + " Opens the Prayer Record."
    }

    var body: some View {
        if span == 2 { full } else { half }
    }

    private var full: some View {
        ChapelTileFrame(
            tile: .flame,
            span: 2,
            note: litNote,
            act: "Prayer record",
            onTap: onOpen,
            accessibilityLabel: accessibilityLabel
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    FlameOrb(isLit: hasPrayedToday, size: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(streakLabel)
                            .font(AppFonts.headlineFont(19))
                            .foregroundColor(AppColors.cream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .contentTransition(.numericText())
                            .animation(Motion.crossfade, value: streakLabel)

                        Text(streakCaption)
                            .font(AppFonts.italicFont(12.5))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }

                if !weekStatus.isEmpty {
                    weekStrip(letterSize: 7.5, dot: 7, ring: 13)
                }
            }
        } footNote: {
            if let milestoneLine {
                ChapelFootNote(milestoneLine)
            }
        }
    }

    private var half: some View {
        ChapelTileFrame(
            tile: .flame,
            span: 1,
            note: litNote,
            act: "Record",
            onTap: onOpen,
            accessibilityLabel: accessibilityLabel
        ) {
            HStack(spacing: 12) {
                FlameOrb(isLit: hasPrayedToday, size: 34)

                if streak > 0 {
                    chapelFigure("\(streak)", streak == 1 ? " day" : " days")
                        .contentTransition(.numericText())
                        .animation(Motion.crossfade, value: streak)
                } else {
                    Text("Begin your streak")
                        .font(AppFonts.headlineFont(14))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !weekStatus.isEmpty {
                weekStrip(letterSize: 7, dot: 6, ring: 12)
                    .padding(.top, 10)
            }
        }
    }

    private static let dayInitial: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // S, M, T…
        return f
    }()

    /// The week, Sunday to Saturday, as a small calendar: each day's
    /// initial over its bead, spread across the shell. Only the prayed
    /// days are lit — never a mark for a missed one, and a day still to
    /// come looks the same as one let pass — and today is ringed, so
    /// the eye knows where in the week it stands.
    private func weekStrip(letterSize: CGFloat, dot: CGFloat, ring: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(weekStatus.enumerated()), id: \.offset) { _, day in
                let isToday = Calendar.current.isDateInToday(day.date)
                VStack(spacing: 5) {
                    Text(Self.dayInitial.string(from: day.date).uppercased())
                        .font(AppFonts.labelFont(letterSize))
                        .tracking(1)
                        .foregroundColor(isToday ? AppColors.gold : AppColors.textSecondary.opacity(0.8))

                    ZStack {
                        if isToday {
                            Circle()
                                .strokeBorder(AppColors.goldLight.opacity(0.8), lineWidth: AppLine.hairline)
                                .frame(width: ring, height: ring)
                        }
                        Circle()
                            .fill(day.didPray ? AppColors.gold : AppColors.cream.opacity(0.16))
                            .frame(width: dot, height: dot)
                    }
                    .frame(width: ring, height: ring)
                }
                .frame(maxWidth: .infinity)
            }
        }
        // A day lit while the page is open — a Rosary just finished —
        // warms up rather than switching on
        .animation(Motion.settle, value: weekStatus.map(\.didPray))
        .accessibilityHidden(true)
    }
}

// MARK: - Consecration

/// The user's place on the 33-day path, with de Montfort's four
/// preparations as a segmented road — each track as long as its true
/// share of the days. The whole tile opens the consecration.
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
    private static let phases: [(name: String, from: Int, to: Int)] = [
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

    /// "Today: Humble Subjection" — the day's own title from the
    /// preparation, so the foot says what today asks rather than which
    /// week it is in (the road already says that).
    private static func todayLine(day: Int) -> String {
        if let title = ConsecrationData.day(day)?.title {
            return "Today: \(title)"
        }
        return phaseName(day: day)
    }

    private func open() {
        router.switchTo(.consecration)
    }

    var body: some View {
        if let active {
            let day = active.currentDayNumber
            if span == 2 { fullActive(day: day) } else { halfActive(day: day) }
        } else if let completed {
            if span == 2 { fullCompleted(completed) } else { halfCompleted }
        } else {
            if span == 2 { fullInvitation } else { halfInvitation }
        }
    }

    // MARK: Full

    private func fullActive(day: Int) -> some View {
        let shown = min(day, 33)
        let toGo = max(0, 33 - shown)
        return ChapelTileFrame(
            tile: .consecration,
            span: 2,
            note: toGo == 0 ? nil : (toGo == 1 ? "1 day to go" : "\(toGo) days to go"),
            act: "Continue",
            onTap: open,
            accessibilityLabel: Self.spoken(day: day)
        ) {
            Text(day > 33 ? "Consecration Day" : "Day \(day) of 33")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)
                .lineLimit(1)

            road(day: shown)
                .padding(.top, 12)
                .padding(.bottom, 8)
        } footNote: {
            ChapelFootNote(Self.todayLine(day: day))
        }
    }

    private func fullCompleted(_ progress: ConsecrationProgress) -> some View {
        ChapelTileFrame(
            tile: .consecration,
            span: 2,
            act: "Revisit",
            onTap: open,
            accessibilityLabel: "Consecration, made. Revisit."
        ) {
            HStack(spacing: 10) {
                AppIcon("ph-seal-check-fill", size: 18)
                    .foregroundColor(AppColors.gold)

                Text("Consecrated")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
            }
        } footNote: {
            if let date = progress.completedAt {
                ChapelFootNote("On \(date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }

    private var fullInvitation: some View {
        ChapelTileFrame(
            tile: .consecration,
            span: 2,
            act: "Begin",
            onTap: open,
            accessibilityLabel: "Total Consecration. A 33-day preparation to give yourself to Jesus through Mary. Begin."
        ) {
            Text("Total Consecration")
                .font(AppFonts.headlineFont(20))
                .foregroundColor(AppColors.cream)

            Text("A 33-day preparation to give yourself to Jesus through Mary.")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .padding(.bottom, 4)
        }
    }

    /// The segmented road: four pills as long as their preparations,
    /// the days walked filled in gold, each named beneath.
    private func road(day: Int) -> some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let unit = (geo.size.width - 15) / 33
                HStack(spacing: 5) {
                    ForEach(Self.phases, id: \.name) { phase in
                        let length = phase.to - phase.from + 1
                        let filled = min(length, max(0, day - phase.from + 1))

                        Capsule()
                            .fill(AppColors.background.opacity(0.6))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.goldGradient)
                                    .frame(width: CGFloat(filled) * unit)
                            }
                            .clipShape(Capsule())
                            .frame(width: CGFloat(length) * unit)
                    }
                }
            }
            .frame(height: 7)

            GeometryReader { geo in
                let unit = (geo.size.width - 15) / 33
                HStack(spacing: 5) {
                    ForEach(Self.phases, id: \.name) { phase in
                        let length = phase.to - phase.from + 1
                        let current = day >= phase.from && day <= phase.to
                        let begun = day >= phase.from

                        Text(phase.name.uppercased())
                            .font(AppFonts.labelFont(8))
                            .tracking(1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(
                                current
                                    ? AppColors.gold
                                    : AppColors.cream.opacity(begun ? 0.55 : 0.3)
                            )
                            .frame(width: CGFloat(length) * unit)
                    }
                }
            }
            .frame(height: 10)
        }
        .accessibilityHidden(true)
    }

    // MARK: Half

    private func halfActive(day: Int) -> some View {
        let shown = min(day, 33)
        return ChapelTileFrame(
            tile: .consecration,
            span: 1,
            act: "Continue",
            onTap: open,
            accessibilityLabel: Self.spoken(day: day)
        ) {
            // The day of consecration is named rather than counted: a
            // figure of "Day 33 / 33" over "The day of consecration" said
            // two different days at once
            if day > 33 {
                Text("Consecration Day")
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                chapelFigure("Day \(day)", " / 33")
            }

            Text(day > 33 ? (ConsecrationData.day(day)?.title ?? "Total Consecration") : Self.phaseName(day: day))
                .font(AppFonts.italicFont(12.5))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.background.opacity(0.6))
                    Capsule()
                        .fill(AppColors.goldGradient)
                        .frame(width: geo.size.width * CGFloat(shown) / 33)
                }
            }
            .frame(height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .accessibilityHidden(true)
        }
    }

    private var halfCompleted: some View {
        ChapelTileFrame(
            tile: .consecration,
            span: 1,
            act: "Revisit",
            onTap: open,
            accessibilityLabel: "Consecration, made. Revisit."
        ) {
            HStack(spacing: 8) {
                AppIcon("ph-seal-check-fill", size: 16)
                    .foregroundColor(AppColors.gold)

                Text("Consecrated")
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private var halfInvitation: some View {
        ChapelTileFrame(
            tile: .consecration,
            span: 1,
            act: "Begin",
            onTap: open,
            accessibilityLabel: "Total Consecration, a 33-day preparation. Begin."
        ) {
            Text("Total Consecration")
                .font(AppFonts.headlineFont(14))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Thirty-three days")
                .font(AppFonts.italicFont(12.5))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .padding(.top, 6)
        }
    }
}

// MARK: - Reading

/// The book left face-down. One book at a time on the page — an oratory
/// has a book open on the prie-dieu, not a list of them — but the face
/// slides: a reader keeping two or three going swipes another forward,
/// or taps its spine where it stands beside the open one, and the
/// spines restack to whatever is not showing. Tapping the face, or the
/// foot's act, takes the book in front up where it was left.
///
/// The body has doors of its own — the face and the spines — so the
/// tile is not one door. An earlier cut made it one: every spine then
/// opened the book in front of it, and the books behind could not be
/// reached from the tile at all.
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

    /// The rest of the shelf — everything under way but the book in
    /// front, so bringing one forward restacks the spines.
    private var others: [Entry] { underWay.filter { $0.row.bookID != shownBookID } }

    var body: some View {
        if let front {
            if span == 2 { full(front) } else { half(front) }
        } else {
            if span == 2 { emptyFull } else { emptyHalf }
        }
    }

    // MARK: Full — the open book, the others standing beside it

    /// The open book's cover height, which the spines stand level with
    private static let fullCoverHeight: CGFloat = 68

    private func full(_ entry: Entry) -> some View {
        ChapelTileFrame(
            tile: .reading,
            span: 2,
            note: fullNote(entry.row),
            act: "Continue reading",
            onAct: { takeUp(entry.row, entry.info) }
        ) {
            HStack(alignment: .center, spacing: 12) {
                pager { page in
                    fullFace(page.row, page.info)
                }
                .frame(height: Self.fullCoverHeight)

                if !others.isEmpty {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(Array(others.prefix(2).enumerated()), id: \.element.row.bookID) { index, other in
                            spineButton(other, height: index == 0 ? 36 : 29)
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: shownBookID)
                }
            }
        }
    }

    /// One face of the full tile: the cover and its facts. Tapping it
    /// takes the book up.
    private func fullFace(_ row: BookReadingProgress, _ info: LibraryBookInfo) -> some View {
        Button(action: { takeUp(row, info) }) {
            HStack(alignment: .center, spacing: 16) {
                ChapelBookCover(color: info.bindingColor, width: 48, height: Self.fullCoverHeight)

                VStack(alignment: .leading, spacing: 4) {
                    Text(info.author.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                        .lineLimit(1)

                    Text(info.title)
                        .font(AppFonts.headlineFont(16))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.title), \(chapterLine(row) ?? "under way"). Continue reading.")
    }

    /// A standing spine that brings its book forward — the same move as
    /// swiping the face, one tap instead. Drawn 11 wide; answers to 24
    /// by the cover's full height.
    private func spineButton(_ entry: Entry, height: CGFloat) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                shownID = entry.row.bookID
            }
        } label: {
            ChapelBookSpine(color: entry.info.bindingColor, height: height)
                .frame(width: 24, height: Self.fullCoverHeight, alignment: .bottom)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bring \(entry.info.title) forward")
    }

    /// "Chapter IX · two more open" — the place, and the rest of the
    /// shelf still under way.
    private func fullNote(_ row: BookReadingProgress) -> String? {
        let place = chapterLine(row)
        let rest: String? = {
            switch others.count {
            case 0:  return nil
            case 1:  return "one more open"
            case 2:  return "two more open"
            case 3:  return "three more open"
            default: return "\(others.count) more open"
            }
        }()
        switch (place, rest) {
        case let (place?, rest?): return "\(place) · \(rest)"
        case let (place?, nil):   return place
        case let (nil, rest?):    return rest.prefix(1).uppercased() + rest.dropFirst()
        case (nil, nil):          return nil
        }
    }

    // MARK: Half — the cover and the title, sliding

    private func half(_ entry: Entry) -> some View {
        ChapelTileFrame(
            tile: .reading,
            span: 1,
            note: shortChapterLine(entry.row),
            act: "Continue",
            onAct: { takeUp(entry.row, entry.info) }
        ) {
            pager { page in
                halfFace(page.row, page.info)
            }

            // No room for spines at half width, so the books under way
            // are counted beneath the face, the one showing lit
            if underWay.count > 1 {
                HStack(spacing: 5) {
                    ForEach(underWay, id: \.row.bookID) { entry in
                        Circle()
                            .fill(
                                entry.row.bookID == shownBookID
                                    ? AppColors.gold.opacity(0.9)
                                    : AppColors.gold.opacity(0.22)
                            )
                            .frame(width: 4.5, height: 4.5)
                    }
                }
                .padding(.top, 8)
                .animation(.easeOut(duration: 0.25), value: shownBookID)
                .accessibilityHidden(true)
            }
        }
    }

    /// One face of the compact tile. Tapping it takes the book up.
    private func halfFace(_ row: BookReadingProgress, _ info: LibraryBookInfo) -> some View {
        Button(action: { takeUp(row, info) }) {
            HStack(alignment: .top, spacing: 12) {
                ChapelBookCover(
                    color: info.bindingColor,
                    width: 34,
                    height: 46,
                    ornamented: true,
                    ribbon: true
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(info.title)
                        .font(AppFonts.headlineFont(14))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(Self.shortAuthor(info))
                        .font(AppFonts.italicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.title), \(chapterLine(row) ?? "under way"). Continue reading.")
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

    private var emptyFull: some View {
        ChapelTileFrame(
            tile: .reading,
            span: 2,
            note: "empty",
            act: "The shelf",
            onTap: { router.push(.spiritualReading) },
            accessibilityLabel: "Reading. Nothing open yet — take up and read. Opens the shelf."
        ) {
            HStack(spacing: 6) {
                ForEach(LibraryCatalog.books.prefix(4)) { book in
                    ChapelBookCover(color: book.bindingColor, width: 22, height: 30, shadowed: false)
                }
            }

            Text("Tolle, lege — take up and read.")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .padding(.top, 10)
                .padding(.bottom, 2)
        }
    }

    private var emptyHalf: some View {
        ChapelTileFrame(
            tile: .reading,
            span: 1,
            note: "empty",
            act: "The shelf",
            onTap: { router.push(.spiritualReading) },
            accessibilityLabel: "Reading. Nothing open yet — take up and read. Opens the shelf."
        ) {
            HStack(spacing: 6) {
                ForEach(LibraryCatalog.books.prefix(3)) { book in
                    ChapelBookCover(color: book.bindingColor, width: 22, height: 30, shadowed: false)
                }
            }

            Text("Tolle, lege — take up and read.")
                .font(AppFonts.italicFont(12.5))
                .foregroundColor(AppColors.cream.opacity(0.85))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
    }

    // MARK: Bits

    private func chapterLine(_ row: BookReadingProgress) -> String? {
        guard LibraryProgressStore.isCurrent(row), !row.lastChapterTitle.isEmpty
        else { return nil }
        return row.lastChapterTitle
    }

    /// "Chapter IX" → "Ch. IX", for the half kicker's little room
    private func shortChapterLine(_ row: BookReadingProgress) -> String? {
        guard let line = chapterLine(row) else { return nil }
        if line.hasPrefix("Chapter ") {
            return "Ch. " + line.dropFirst("Chapter ".count)
        }
        return line
    }

    /// The author as a half tile has room to say — the surname a reader
    /// knows the book by, the way "De Montfort" stands for the saint.
    private static func shortAuthor(_ info: LibraryBookInfo) -> String {
        switch info.id {
        case "imitation-of-christ":         return "à Kempis"
        case "story-of-a-soul":             return "St. Thérèse"
        case "confessions-of-st-augustine": return "St. Augustine"
        case "dolorous-passion":            return "Emmerich"
        default:                            return info.author
        }
    }

    /// Resumes whichever hand the book was last held in — the same rule
    /// the Me page's reading card followed.
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

/// A small cloth cover, drawn rather than imaged: the binding colour lit
/// from the upper left, gilt rules at head and tail, and — ornamented —
/// a diamond between them and a marker ribbon over the top edge.
struct ChapelBookCover: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var ornamented: Bool = false
    var ribbon: Bool = false
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
                        giltPair
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.75))
                            .frame(width: 4, height: 4)
                            .rotationEffect(.degrees(45))
                        Spacer(minLength: 0)
                        giltPair
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 6)
                } else if width >= 30 {
                    VStack(spacing: 0) {
                        gilt
                        Spacer(minLength: 0)
                        gilt
                    }
                    .padding(.vertical, 7)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
            )
            .overlay(alignment: .topTrailing) {
                if ribbon {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(AppColors.goldLight)
                        .frame(width: 4, height: 12)
                        .padding(.trailing, 6)
                        .offset(y: -3)
                        .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                }
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(shadowed ? 0.35 : 0), radius: 8, y: 5)
            .accessibilityHidden(true)
    }

    private var gilt: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.5))
            .frame(height: AppLine.hairline)
    }

    private var giltPair: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.55))
                .frame(height: AppLine.hairline)
            Rectangle()
                .fill(AppColors.gold.opacity(0.55))
                .frame(height: AppLine.hairline)
        }
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
                    colors: [color.lightened(by: 0.10), color, color.darkened(by: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack {
                    Spacer().frame(height: height * 0.16)
                    Rectangle().fill(AppColors.gold.opacity(0.5)).frame(height: AppLine.hairline)
                    Spacer()
                    Rectangle().fill(AppColors.gold.opacity(0.5)).frame(height: AppLine.hairline)
                    Spacer().frame(height: height * 0.16)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline)
            )
            .frame(width: 11, height: height)
            .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
            .accessibilityHidden(true)
    }
}

// MARK: - Liturgy

/// The Church's own two books for the day — the Missal and the
/// Breviary — as a diptych, each leaf a door, over the day's feast.
/// Split out of the Library so one heading is true of everything
/// beneath it: these are the liturgy, and the rest of the shelf is not.
struct ChapelLiturgyTile: View {

    let span: Int

    /// "Saturday · The Most Holy Name of Mary" — the page's own day line
    let dayLine: String

    /// The feast alone, for the half tile's narrower foot; nil until known
    let feast: String?

    @Environment(AppRouter.self) private var router

    var body: some View {
        if span == 2 { full } else { half }
    }

    // MARK: Full — the diptych

    private var full: some View {
        ChapelTileFrame(
            tile: .liturgy,
            span: 2,
            note: "1962 Missal · Breviary",
            footRuled: true
        ) {
            HStack(alignment: .center, spacing: 12) {
                leaf("ch-altar", "Daily Missal", "The Mass", .missal)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.22))
                    .frame(width: 1)
                    .padding(.vertical, 4)
                    .accessibilityHidden(true)

                leaf("ph-clock", "Divine Office", "The Hours", .office)
            }
            .padding(.bottom, 8)
        } footNote: {
            ChapelFootNote(dayLine)
        }
    }

    private func leaf(_ icon: String, _ title: String, _ under: String, _ route: AppRoute) -> some View {
        Button {
            router.push(route)
        } label: {
            HStack(spacing: 12) {
                AppIcon(icon, size: 20)
                    .foregroundColor(AppColors.gold)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFonts.headlineFont(14))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(under.uppercased())
                        .font(AppFonts.labelFont(8))
                        .tracking(2)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(title), \(under.lowercased())")
    }

    // MARK: Half — two door rows over the feast

    private var half: some View {
        ChapelTileFrame(
            tile: .liturgy,
            span: 1,
            shellTop: 2
        ) {
            ChapelDoorRow("ch-altar", "Daily Missal", divided: true) {
                router.push(.missal)
            }
            ChapelDoorRow("ph-clock", "Divine Office") {
                router.push(.office)
            }
        } footNote: {
            ChapelFootNote(feast ?? dayLine, size: 12.5)
        }
    }
}

/// One 44pt door in a ruled list: a 13pt glyph and the door's name.
private struct ChapelDoorRow: View {
    let icon: String
    let title: String
    var divided: Bool = false
    let action: () -> Void

    init(_ icon: String, _ title: String, divided: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.divided = divided
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                AppIcon(icon, size: 13)
                    .foregroundColor(AppColors.gold.opacity(0.8))
                    .frame(width: 16)

                Text(title)
                    .font(AppFonts.bodyFont(12.5))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if divided {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.11))
                    .frame(height: AppLine.hairline)
            }
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Library

/// The chapel's shelf: six doors in two columns — the books, the
/// guides, and the saints — over Augustine's line. The liturgy has its
/// own tile now, so this heading is true of every door beneath it.
struct ChapelLibraryTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    private typealias Door = (icon: String, title: String, route: AppRoute)

    /// Read down the columns: the books and the Marian library on the
    /// left, the two Rosary guides and the saint on the right.
    private static let left: [Door] = [
        ("ph-crown", "True Devotion", .trueDevotionBook),
        ("ph-book-open", "Spiritual Reading", .spiritualReading),
        ("ch-lily", "Marian Library", .marianLibrary)
    ]

    private static let right: [Door] = [
        ("ch-rosary", "How to Pray", .howToPray),
        ("ch-bible", "In Scripture", .scripture),
        ("ch-monstrance", "Carlo Acutis", .carloAcutis)
    ]

    var body: some View {
        if span == 2 { full } else { half }
    }

    // MARK: Full — the index

    private var full: some View {
        ChapelTileFrame(
            tile: .library,
            span: 2,
            note: "Six doors",
            shellTop: 4,
            act: "The shelf",
            footRuled: true,
            onAct: { router.push(.spiritualReading) }
        ) {
            HStack(alignment: .top, spacing: 18) {
                column(Self.left)
                column(Self.right)
            }
        } footNote: {
            ChapelFootNote("Our heart is restless until it rests in thee.")
        }
    }

    private func column(_ doors: [Door]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(doors.enumerated()), id: \.element.title) { index, door in
                ChapelDoorRow(door.icon, door.title, divided: index < doors.count - 1) {
                    router.push(door.route)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Half — the first two doors, and a door to the rest

    private var half: some View {
        ChapelTileFrame(
            tile: .library,
            span: 1,
            shellTop: 2,
            act: "Four more",
            onAct: { router.push(.explore) }
        ) {
            ForEach(Array(Self.left.prefix(2).enumerated()), id: \.element.title) { index, door in
                ChapelDoorRow(door.icon, door.title, divided: index == 0) {
                    router.push(door.route)
                }
            }
        }
    }
}

// MARK: - Chant

/// Sung prayer kept close to hand: a round play control, the piece by
/// name, and a scrub line. The foot's act opens the chant sheet, the
/// only place the piece can be changed.
struct ChapelChantTile: View {

    let span: Int
    let player: ChapelChantPlayer
    let onOpenSheet: () -> Void

    var body: some View {
        if span == 2 { full } else { half }
    }

    private var full: some View {
        ChapelTileFrame(
            tile: .chant,
            span: 2,
            note: player.elapsedLabel,
            act: "All chants",
            onAct: onOpenSheet
        ) {
            HStack(spacing: 14) {
                playDisc(size: 46, iconSize: 15)

                VStack(alignment: .leading, spacing: 4) {
                    Text(player.current.latinTitle.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // The error outranks the detail: a chant that could
                    // not be reached should say so where its name is
                    Text(player.errorMessage ?? player.current.detail)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            scrubLine
                .padding(.top, 14)
                .padding(.bottom, 6)
        }
    }

    private var half: some View {
        ChapelTileFrame(
            tile: .chant,
            span: 1,
            act: "All chants",
            onAct: onOpenSheet
        ) {
            Text(player.current.latinTitle)
                .font(AppFonts.headlineFont(15))
                .foregroundColor(AppColors.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            Text(player.errorMessage ?? player.current.detail)
                .font(AppFonts.italicFont(12.5))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .padding(.top, 4)

            // The time is said once, here on the transport row, and
            // not in the kicker as well
            HStack(spacing: 10) {
                playDisc(size: 36, iconSize: 14)

                scrubLine

                if let elapsed = player.elapsedLabel {
                    Text(elapsed)
                        .font(AppFonts.bodyFont(11))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    private func playDisc(size: CGFloat, iconSize: CGFloat) -> some View {
        Button(action: { player.togglePlayback() }) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)

                // Play, pause and the spinner crossfade over one
                // another rather than swapping under the thumb
                ZStack {
                    if player.isLoading {
                        ProgressView()
                            .tint(AppColors.goldLight)
                            .scaleEffect(0.8)
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    } else if player.isPlaying {
                        AppIcon("ph-pause-fill", size: iconSize)
                            .foregroundColor(AppColors.goldLight)
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    } else {
                        AppIcon("ph-play-fill", size: iconSize)
                            .foregroundColor(AppColors.goldLight)
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    }
                }
                .animation(Motion.crossfade, value: player.isLoading)
                .animation(Motion.crossfade, value: player.isPlaying)
            }
            .frame(width: size, height: size)
            .shadow(color: AppColors.gold.opacity(0.3), radius: 9)
            .shadow(color: AppColors.gold.opacity(0.15), radius: 20)
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(
            player.isPlaying
                ? "Pause \(player.current.latinTitle)"
                : "Sing \(player.current.latinTitle)"
        )
    }

    private var scrubLine: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.15))
                Rectangle()
                    .fill(AppColors.gold)
                    .frame(width: geo.size.width * player.progress)
                    // Glides between the player's ticks instead of
                    // stepping with them
                    .animation(.linear(duration: 0.5), value: player.progress)
            }
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Reflections

/// The latest journal entry, opened by an illuminated versal — writing,
/// not a list. An entry that opens on a quotation mark has no letter to
/// illuminate and takes a gold rule down its side instead. The whole
/// tile opens the journal.
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
            if span == 2 { full(latest) } else { half(latest) }
        } else {
            empty
        }
    }

    private func full(_ entry: JournalEntry) -> some View {
        let text = tileText(entry)
        return ChapelTileFrame(
            tile: .reflections,
            span: 2,
            note: entry.createdAt.formatted(date: .abbreviated, time: .omitted),
            act: "Open journal",
            onTap: open,
            accessibilityLabel: "Reflections. \(text). Opens the journal."
        ) {
            entryBlock(text, versalSize: 42, bodySize: 15, lines: 3)
                .padding(.bottom, 6)
        } footNote: {
            // A fading rule in the note's place: the entry's own
            // sentence is the note, and nothing should compete with it
            LinearGradient(
                colors: [AppColors.gold.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
    }

    private func half(_ entry: JournalEntry) -> some View {
        let text = tileText(entry)
        return ChapelTileFrame(
            tile: .reflections,
            span: 1,
            note: entry.createdAt.formatted(.dateTime.month(.abbreviated).day()),
            act: "Journal",
            onTap: open,
            accessibilityLabel: "Reflections. \(text). Opens the journal."
        ) {
            // The card floor for reading text is 15, at half width too
            entryBlock(text, versalSize: 34, bodySize: 15, lines: 2)
                .padding(.bottom, 4)
        }
    }

    private var empty: some View {
        ChapelTileFrame(
            tile: .reflections,
            span: span,
            act: span == 2 ? "Open journal" : "Journal",
            onTap: open,
            accessibilityLabel: "Reflections. Your reflections will gather here after prayer. Opens the journal."
        ) {
            Text("Your reflections will gather here after prayer.")
                .font(AppFonts.italicFont(span == 2 ? 15 : 13))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
        }
    }

    // MARK: Bits

    /// What the tile quotes from the entry. A passage kept from a book is
    /// set as the quotation it is, without the citation and its rights
    /// note — the journal's own page sets those apart, and on a tile of
    /// two or three lines they crowded out the passage. Any other entry
    /// is the journal's own preview, its newlines flattened, so a
    /// paragraph break never spends one of those lines on nothing.
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

        // A few lines of the reader's own writing, at the quote leading —
        // about 1.45 — so they read as one breath rather than a list; the
        // medium italic holds its weight on the dark ground where the
        // light face thinned
        let writing = Text(words)
            .font(AppFonts.italicFont(bodySize))
            .foregroundColor(AppColors.cream.opacity(0.88))
            .lineSpacing(ReadingTypography.quoteLineSpacing(for: bodySize))
            .lineLimit(lines)

        return Group {
            if let cut {
                // A hair between the initial and the rest of its word: the
                // two are separate views, and any more air than that splits
                // "Be" into "B  e". A mark stands off its words a little more.
                HStack(alignment: .top, spacing: opensOnQuotation ? 7 : 4) {
                    versalText(cut, size: versalSize, bodySize: bodySize)
                        .frame(height: versalSize * 0.8, alignment: opensOnQuotation ? .topLeading : .bottomLeading)
                        .padding(.top, 5)

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
                .font(AppFonts.headlineFont((size * 1.5).rounded()))
                .foregroundColor(AppColors.gold)
        }
        return Text(cut.lead)
            .font(AppFonts.italicFont(bodySize))
            .foregroundColor(AppColors.cream.opacity(0.88))
        + Text(cut.letter)
            .font(AppFonts.headlineFont(size))
            .foregroundColor(AppColors.gold)
    }
}
