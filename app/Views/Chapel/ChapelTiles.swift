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
//  Three visual registers, deliberately, so the page doesn't read as a
//  stack of identical cards: Today, Consecration, Library and Chant are
//  ruled straight onto the page with hairlines; Reading, Reflections
//  and the Prayer Streak stand in outlined cards; nothing on the page
//  takes a filled card surface.
//

import SwiftUI
import SwiftData

// MARK: - ChapelAct

/// One act of the user's rule, resolved for today: what it is, its live
/// context line, whether it has been offered, and whether it is checked
/// by hand or by the app seeing it finish.
struct ChapelAct: Identifiable {
    let shortcut: PrayerShortcut
    let subtitle: String
    let done: Bool
    let manual: Bool

    var id: String { shortcut.rawValue }

    /// The act's name as the focus block sets it, large.
    var focusTitle: String {
        switch shortcut {
        case .todaysRosary:     return "The Rosary"
        case .chooseMeditation: return "A Meditation"
        case .sevenSorrows:     return "Seven Sorrows"
        case .mass:             return "The Mass"
        case .office:           return "The Office"
        case .consecration:     return "Consecration"
        }
    }

    /// The gold act under the focus title.
    var focusAction: String {
        switch shortcut {
        case .todaysRosary:     return "Begin the Rosary"
        case .chooseMeditation: return "Choose a Meditation"
        case .sevenSorrows:     return "Begin the Chaplet"
        case .mass:             return "Begin the Mass"
        case .office:           return "Begin the Office"
        case .consecration:     return "Continue the Preparation"
        }
    }
}

// MARK: - Shared furniture

/// The engraved kicker every frameless tile opens with: a 12pt glyph
/// and a tracked label, with room for a trailing note.
struct ChapelKicker<Trailing: View>: View {
    let icon: String
    let title: String
    var compact: Bool = false
    @ViewBuilder var trailing: Trailing

    init(
        _ icon: String,
        _ title: String,
        compact: Bool = false,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.compact = compact
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 7) {
            AppIcon(icon, size: 12)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .accessibilityHidden(true)

            Text(title.uppercased())
                .font(AppFonts.labelFont(compact ? 9.5 : 10))
                .tracking(compact ? 2 : 2.5)
                .foregroundColor(AppColors.gold.opacity(0.75))
                .lineLimit(1)

            Spacer(minLength: 0)

            trailing
        }
    }
}

/// A tracked italic note on a kicker's right — "2 of 5 offered".
struct ChapelKickerNote: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(12))
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(1)
    }
}

/// The 1pt section rule under a frameless tile's kicker.
struct ChapelRule: View {
    var opacity: Double = 0.22

    var body: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(opacity))
            .frame(height: 1)
    }
}

/// The 16pt-radius hairline shell the outlined tiles stand in.
struct ChapelOutline: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderOpacity: Double = 0.24

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AppColors.gold.opacity(borderOpacity), lineWidth: 0.5)
        )
    }
}

/// The quiet gold text act tiles close with — "CONTINUE ›".
private struct ChapelTextAct: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title.uppercased())
                    .font(AppFonts.labelFont(10))
                    .tracking(2)
                AppIcon("ph-caret-right", size: 9)
            }
            .foregroundColor(AppColors.gold)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Today (the rule)

/// The user's rule of prayer, act by act. This is the tile that drives
/// the focus block at the top of the page — the ledger is the picker.
struct ChapelRuleTile: View {

    let acts: [ChapelAct]
    let span: Int
    let onAct: (ChapelAct) -> Void
    let onEditRule: () -> Void

    private var doneCount: Int { acts.filter(\.done).count }
    private var next: ChapelAct? { acts.first { !$0.done } }

    var body: some View {
        if span == 2 { full } else { half }
    }

    // MARK: Full — the ledger

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker("ph-scroll", "Today") {
                if !acts.isEmpty {
                    ChapelKickerNote("\(doneCount) of \(acts.count) offered")
                }
            }
            .padding(.bottom, 12)

            ChapelRule()

            if acts.isEmpty {
                emptyRule
            } else {
                ForEach(acts) { act in
                    row(act)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func row(_ act: ChapelAct) -> some View {
        Button(action: { onAct(act) }) {
            HStack(spacing: 15) {
                ZStack {
                    AppIcon(act.shortcut.icon, size: 17)
                        .foregroundColor(dialTint(act))
                }
                .frame(width: 24, height: 24)
                .modifier(NextActHalo(active: act.id == next?.id))

                VStack(alignment: .leading, spacing: 2) {
                    Text(act.shortcut.title)
                        .font(AppFonts.bodyFont(15.5))
                        .foregroundColor(
                            act.done || act.id == next?.id
                                ? AppColors.cream
                                : AppColors.cream.opacity(0.72)
                        )
                        .lineLimit(1)

                    Text(act.subtitle)
                        .font(AppFonts.bodyFont(11.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                AppIcon("ph-seal-check-fill", size: 20)
                    .foregroundColor(AppColors.gold)
                    .opacity(act.done ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: act.done)
            }
            .padding(.horizontal, 2)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.11))
                .frame(height: 0.5)
        }
        .accessibilityLabel(accessibility(for: act))
    }

    private func dialTint(_ act: ChapelAct) -> Color {
        if act.id == next?.id { return AppColors.goldLight }
        return act.done ? AppColors.gold : AppColors.gold.opacity(0.45)
    }

    private func accessibility(for act: ChapelAct) -> String {
        if act.done {
            return act.manual
                ? "\(act.shortcut.title), offered. Double-tap to unmark."
                : "\(act.shortcut.title), offered."
        }
        return act.manual
            ? "Mark \(act.shortcut.title) offered"
            : "Begin \(act.shortcut.title)"
    }

    private var emptyRule: some View {
        VStack(spacing: 8) {
            Text("No devotions on your rule yet.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 16)

            QuietGoldButton(
                title: "Choose your rule",
                size: 10,
                color: AppColors.gold,
                horizontalPadding: 0,
                action: onEditRule
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Half — the day as a bar chart

    private var half: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker("ph-scroll", "Today", compact: true)
                .padding(.bottom, 10)

            ChapelRule()

            if acts.isEmpty {
                Text("No devotions yet.")
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 14)
            } else {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(acts) { act in
                        tick(act)
                    }
                }
                // The ticks carry their own 44pt targets now, so the
                // row brings most of this spacing with it.
                .padding(.top, 2)
                .padding(.bottom, 6)

                (Text("\(doneCount)")
                    .font(AppFonts.headlineFont(26))
                    .foregroundColor(AppColors.cream)
                 + Text(" / \(acts.count)")
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.45)))
                    .lineLimit(1)

                Text("offered today")
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 5)
            }
        }
        .padding(.vertical, 2)
        // `.contain`, not `.ignore`: each tick is an act the user can
        // offer, and flattening the tile to one label would take those
        // actions away from VoiceOver exactly as dropping the buttons
        // took them away from everyone else.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today: \(doneCount) of \(acts.count) offered")
    }

    /// One act as a bar. The bar is drawn short, but it answers to a
    /// full 44pt column: this is the half tile's only way to offer an
    /// act, and the Mass and the Office are marked by hand — with no
    /// control here, a rule holding either could never be completed and
    /// the focus block would stay pinned to it forever.
    private func tick(_ act: ChapelAct) -> some View {
        let isNext = act.id == next?.id
        return Button(action: { onAct(act) }) {
            Group {
                if act.done {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.goldCTAGradient)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            isNext
                                ? AppColors.gold.opacity(0.45)
                                : AppColors.cream.opacity(0.13)
                        )
                }
            }
            .frame(height: isNext ? 26 : 18)
            .frame(maxWidth: .infinity)
            .shadow(color: AppColors.gold.opacity(isNext ? 0.35 : 0), radius: 4.5)
            // Bottom-aligned inside the target, so the bars keep their
            // common baseline and only the target is tall.
            .frame(minHeight: 44, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility(for: act))
    }
}

/// The halo the next act's dial carries.
private struct NextActHalo: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content
            .shadow(color: AppColors.gold.opacity(active ? 0.4 : 0), radius: 5)
            .shadow(color: AppColors.gold.opacity(active ? 0.18 : 0), radius: 11)
            .animation(.easeOut(duration: 0.4), value: active)
    }
}

// MARK: - Consecration

/// The user's place on the 33-day path, with de Montfort's four
/// preparations as a segmented road — each track as long as its true
/// share of the days.
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

    private static func footLine(day: Int) -> String {
        switch day {
        case ...12:  return "Renouncing the world — days 1 to 12"
        case 13...19: return "Knowing yourself — days 13 to 19"
        case 20...26: return "Knowing Our Lady — days 20 to 26"
        case 27...33: return "Knowing Christ — days 27 to 33"
        default:      return "The day of consecration"
        }
    }

    private static func phaseName(day: Int) -> String {
        switch day {
        case ...12:  return "Renouncing the world"
        case 13...19: return "Knowing yourself"
        case 20...26: return "Knowing Our Lady"
        case 27...33: return "Knowing Christ"
        default:      return "Consecration day"
        }
    }

    var body: some View {
        if span == 2 { full } else { half }
    }

    // MARK: Full — the segmented path

    @ViewBuilder
    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker("ph-crown", "Consecration") {
                if let active {
                    let toGo = max(0, 33 - min(active.currentDayNumber, 33))
                    if toGo > 0 {
                        ChapelKickerNote("\(toGo) days to go")
                    }
                }
            }
            .padding(.bottom, 12)

            ChapelRule(opacity: 0.24)

            if let active {
                let day = min(active.currentDayNumber, 33)

                Text("Day \(day) of 33")
                    .font(AppFonts.headlineFont(20))
                    .foregroundColor(AppColors.cream)
                    .padding(.horizontal, 2)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                path(day: day)
                    .padding(.horizontal, 2)

                HStack(spacing: 12) {
                    Text(Self.footLine(day: active.currentDayNumber))
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)

                    ChapelTextAct(title: "Continue") {
                        router.switchTo(.consecration)
                    }
                    .padding(.vertical, -10)
                }
                .padding(.horizontal, 2)
                .padding(.top, 14)
                .padding(.bottom, 12)
            } else if let completed {
                completedBody(completed)
            } else {
                invitation
            }

            ChapelRule(opacity: 0.24)
        }
        .padding(.vertical, 2)
    }

    private func path(day: Int) -> some View {
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
                                    .fill(AppColors.goldCTAGradient)
                                    .frame(
                                        width: CGFloat(length) * unit
                                            * CGFloat(filled) / CGFloat(length)
                                    )
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(day) of 33. \(Self.phaseName(day: day)).")
    }

    @ViewBuilder
    private func completedBody(_ progress: ConsecrationProgress) -> some View {
        HStack(spacing: 10) {
            AppIcon("ph-seal-check-fill", size: 18)
                .foregroundColor(AppColors.gold)

            Text("Consecrated")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.cream)

            Spacer(minLength: 0)

            ChapelTextAct(title: "Revisit") {
                router.switchTo(.consecration)
            }
            .padding(.vertical, -10)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var invitation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total Consecration")
                .font(AppFonts.headlineFont(18))
                .foregroundColor(AppColors.cream)
                .padding(.top, 14)

            Text("A 33-day preparation to give yourself to Jesus through Mary.")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ChapelTextAct(title: "Begin") {
                router.switchTo(.consecration)
            }
            .padding(.vertical, -10)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 2)
    }

    // MARK: Half — the day and one bar

    @ViewBuilder
    private var half: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker("ph-crown", "Consecration", compact: true)
                .padding(.bottom, 10)

            ChapelRule(opacity: 0.24)

            if let active {
                let day = min(active.currentDayNumber, 33)

                (Text("Day \(day)")
                    .font(AppFonts.headlineFont(26))
                    .foregroundColor(AppColors.cream)
                 + Text(" / 33")
                    .font(AppFonts.headlineFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.45)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 14)
                    .padding(.bottom, 3)

                Text(Self.phaseName(day: active.currentDayNumber))
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 12)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.background.opacity(0.6))
                        Capsule()
                            .fill(AppColors.goldCTAGradient)
                            .frame(width: geo.size.width * CGFloat(day) / 33)
                    }
                }
                .frame(height: 5)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Day \(day) of 33")
            } else if completed != nil {
                Text("Consecrated")
                    .font(AppFonts.headlineFont(18))
                    .foregroundColor(AppColors.cream)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                AppIcon("ph-seal-check-fill", size: 18)
                    .foregroundColor(AppColors.gold)
                    .padding(.bottom, 8)
            } else {
                Text("Not yet begun")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 14)

                ChapelTextAct(title: "Begin") {
                    router.switchTo(.consecration)
                }
                .padding(.vertical, -10)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Reading

/// The book left face-down. One book at a time on the page — an oratory
/// has a book open on the prie-dieu, not a list of them — but the tile
/// slides: a reader keeping two or three going can bring another
/// forward, and the spines beneath restack to whatever is not showing.
/// Tapping the book takes it up where it was left.
struct ChapelReadingTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    @Query(sort: \BookReadingProgress.updatedAt, order: .reverse)
    private var progress: [BookReadingProgress]

    /// Which book's face is forward. Nil until the reader slides.
    @State private var shownID: String?

    /// Every book with a reading under way, most recent first. Books the
    /// catalog no longer carries fall out rather than drawing a face
    /// with no cloth.
    private var underWay: [(row: BookReadingProgress, info: LibraryBookInfo)] {
        progress.compactMap { row in
            guard let info = LibraryCatalog.book(id: row.bookID) else { return nil }
            return (row, info)
        }
    }

    /// The book showing: the slid-to one, else the most recent.
    private var shownBookID: String? {
        underWay.contains { $0.row.bookID == shownID } ? shownID : underWay.first?.row.bookID
    }

    /// The rest of the shelf — everything under way except the book
    /// that is forward, so sliding restacks the spines.
    private var others: [(row: BookReadingProgress, info: LibraryBookInfo)] {
        underWay.filter { $0.row.bookID != shownBookID }
    }

    var body: some View {
        Group {
            if span == 2 { full } else { half }
        }
        .padding(span == 2 ? 0 : 1) // hairline breathing room in the half column
    }

    // MARK: Full — the open book and the shelf beneath

    @ViewBuilder
    private var full: some View {
        VStack(alignment: .leading, spacing: 12) {
            if underWay.isEmpty {
                invitation
            } else {
                pager { entry in
                    fullPage(entry.row, entry.info)
                }

                if underWay.count > 1 {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.2))
                        .frame(height: 0.5)

                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(
                            Array(others.prefix(3).enumerated()),
                            id: \.element.row.bookID
                        ) { index, entry in
                            spineButton(
                                entry.row,
                                entry.info,
                                height: Self.spineHeights[index % Self.spineHeights.count]
                            )
                        }

                        Spacer(minLength: 0)

                        Text("Also reading")
                            .font(AppFonts.italicFont(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .animation(.easeOut(duration: 0.25), value: shownBookID)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ChapelOutline())
    }

    /// One face of the full tile: the cover and its facts. The whole
    /// page is the door — tapping it takes the book up.
    private func fullPage(_ row: BookReadingProgress, _ info: LibraryBookInfo) -> some View {
        Button(action: { takeUp(row, info) }) {
            HStack(alignment: .center, spacing: 16) {
                BookCover(info: info, isLettered: false)
                    .frame(width: 48)
                    .shadow(color: .black.opacity(0.35), radius: 3.5, y: 5)
                    .accessibilityHidden(true)

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

                    if let place = chapterLine(row) {
                        Text(place)
                            .font(AppFonts.italicFont(13))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text("CONTINUE READING")
                            .font(AppFonts.labelFont(10))
                            .tracking(2)
                        AppIcon("ph-caret-right", size: 9)
                    }
                    .foregroundColor(AppColors.gold)
                    .padding(.top, 6)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.title), \(chapterLine(row) ?? "under way"). Continue reading.")
    }

    /// Uneven on purpose — books on a shelf don't align at the top.
    private static let spineHeights: [CGFloat] = [36, 29, 33]

    /// A standing spine that brings its book forward when tapped —
    /// the same move as sliding, one tap instead.
    private func spineButton(
        _ row: BookReadingProgress,
        _ info: LibraryBookInfo,
        height: CGFloat
    ) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                shownID = row.bookID
            }
        } label: {
            ChapelBookSpine(color: info.bindingColor, height: height)
                .frame(width: 24, height: 44, alignment: .bottom)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bring \(info.title) forward")
    }

    // MARK: Half — the book stands upright

    @ViewBuilder
    private var half: some View {
        VStack(spacing: 11) {
            if underWay.isEmpty {
                AppIcon("ph-book-open", size: 22)
                    .foregroundColor(AppColors.gold.opacity(0.6))
                    .padding(.top, 4)

                Text("Tolle, lege")
                    .font(AppFonts.italicFont(13))
                    .foregroundColor(AppColors.cream.opacity(0.85))

                ChapelTextAct(title: "The shelf") {
                    router.push(.spiritualReading)
                }
                .padding(.vertical, -12)
            } else {
                pager { entry in
                    halfPage(entry.row, entry.info)
                }

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
                    .animation(.easeOut(duration: 0.25), value: shownBookID)
                    .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .modifier(ChapelOutline())
    }

    /// One face of the compact tile: the cover upright, the title
    /// beneath. Tapping it takes the book up.
    private func halfPage(_ row: BookReadingProgress, _ info: LibraryBookInfo) -> some View {
        Button(action: { takeUp(row, info) }) {
            VStack(spacing: 11) {
                BookCover(info: info, isLettered: false)
                    .frame(width: 54)
                    .shadow(color: .black.opacity(0.35), radius: 3.5, y: 5)
                    .accessibilityHidden(true)

                Text(info.title)
                    .font(AppFonts.headlineFont(14))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let place = chapterLine(row) {
                    Text(place)
                        .font(AppFonts.italicFont(12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.title), \(chapterLine(row) ?? "under way"). Take it up.")
    }

    // MARK: The slide

    /// The books beside each other, one face showing — the same
    /// viewAligned slide the Me page's reading card used, so a reader
    /// keeping several books going can bring any of them forward.
    private func pager<Page: View>(
        @ViewBuilder page: @escaping ((row: BookReadingProgress, info: LibraryBookInfo)) -> Page
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

    // MARK: Bits

    private func chapterLine(_ row: BookReadingProgress) -> String? {
        guard LibraryProgressStore.isCurrent(row), !row.lastChapterTitle.isEmpty
        else { return nil }
        return row.lastChapterTitle
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

    private var invitation: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(LibraryCatalog.books.prefix(4)) { book in
                    BookCover(info: book, isLettered: false)
                        .frame(width: 40)
                }
            }
            .accessibilityHidden(true)

            Text("Tolle, lege — take up and read")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.cream.opacity(0.85))

            ChapelTextAct(title: "The shelf") {
                router.push(.spiritualReading)
            }
            .padding(.vertical, -10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nothing open yet. Take up and read.")
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
                    colors: [color, color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack {
                    Spacer().frame(height: height * 0.16)
                    Rectangle().fill(AppColors.gold.opacity(0.5)).frame(height: 0.5)
                    Spacer()
                    Rectangle().fill(AppColors.gold.opacity(0.5)).frame(height: 0.5)
                    Spacer().frame(height: height * 0.16)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 0.5)
            )
            .frame(width: 11, height: height)
            .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
            .accessibilityHidden(true)
    }
}

// MARK: - Library

/// An open book: two leaves under a gold fold line — the liturgy on the
/// left, the reading on the right — closing on Augustine's colophon.
struct ChapelLibraryTile: View {

    let span: Int

    @Environment(AppRouter.self) private var router

    private var liturgyLeaf: [(icon: String, title: String, route: AppRoute)] {
        [
            ("ch-altar", "Daily Missal", .missal),
            ("ph-clock", "Divine Office", .office),
            ("ch-rosary", "How to Pray", .howToPray),
            ("ch-bible", "In Scripture", .scripture)
        ]
    }

    private var readingLeaf: [(icon: String, title: String, route: AppRoute)] {
        [
            ("ph-crown", "True Devotion", .trueDevotionBook),
            ("ph-book-open", "Spiritual Reading", .spiritualReading),
            ("ch-lily", "Marian Library", .marianLibrary),
            ("ch-monstrance", "Carlo Acutis", .carloAcutis)
        ]
    }

    var body: some View {
        if span == 2 { full } else { half }
    }

    // MARK: Full — the open spread

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker("ph-book", "Library")
                .padding(.bottom, 10)

            HStack(alignment: .top, spacing: 0) {
                leaf("The Liturgy", rows: liturgyLeaf)

                // The fold, fading out before the foot
                LinearGradient(
                    stops: [
                        .init(color: AppColors.gold.opacity(0.26), location: 0),
                        .init(color: AppColors.gold.opacity(0.26), location: 0.82),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 1)
                .padding(.horizontal, 11.5)
                .accessibilityHidden(true)

                leaf("Reading", rows: readingLeaf)
            }

            ChapelRule(opacity: 0.18)
                .padding(.top, 6)

            VStack(spacing: 7) {
                Text("Thou hast made us for thyself, and our heart is restless until it rests in thee.")
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.82))
                    .multilineTextAlignment(.center)

                Text("ST. AUGUSTINE · CONFESSIONS")
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.8)
                    .foregroundColor(AppColors.gold.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.top, 13)
            .padding(.bottom, 6)
        }
        .padding(.vertical, 2)
    }

    private func leaf(_ head: String, rows: [(icon: String, title: String, route: AppRoute)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(head.uppercased())
                .font(AppFonts.labelFont(8.5))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.6))
                .padding(.bottom, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppColors.gold.opacity(0.16))
                        .frame(height: 0.5)
                }
                .padding(.bottom, 3)

            ForEach(rows, id: \.title) { row in
                door(row.icon, row.title, minHeight: 44) {
                    router.push(row.route)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func door(
        _ icon: String,
        _ title: String,
        minHeight: CGFloat,
        divided: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
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
            .frame(minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if divided {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.1))
                    .frame(height: 0.5)
            }
        }
        .accessibilityLabel(title)
    }

    // MARK: Half — the left leaf alone

    private var half: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapelKicker("ph-book", "Library", compact: true)
                .padding(.bottom, 10)

            ChapelRule()

            ForEach(liturgyLeaf, id: \.title) { row in
                door(row.icon, row.title, minHeight: 44, divided: true) {
                    router.push(row.route)
                }
            }

            Text("Four more on the shelf")
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 11)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Chant

/// Sung prayer kept close to hand: a round play control, the piece by
/// name, and a scrub line. The overflow opens the chant sheet.
struct ChapelChantTile: View {

    let span: Int
    let player: ChapelChantPlayer
    let onOpenSheet: () -> Void

    var body: some View {
        if span == 2 { full } else { half }
    }

    private var full: some View {
        VStack(alignment: .leading, spacing: 11) {
            // Every other frameless tile opens on a kicker and a rule.
            // Without one this section began on a play button, so it read
            // as a control belonging to whatever sat above it rather than
            // as a section of the page.
            ChapelKicker("ph-music-note", "Chant")

            ChapelRule()
                .padding(.bottom, 2)

            HStack(spacing: 14) {
                playButton(size: 46, iconSize: 15)

                VStack(alignment: .leading, spacing: 4) {
                    Text(player.current.latinTitle.uppercased())
                        .font(AppFonts.labelFont(10))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(player.errorMessage ?? player.current.detail)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                overflowButton
            }

            scrubLine
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var half: some View {
        VStack(spacing: 10) {
            // The sheet is the only place the chant can be changed, so
            // the half tile keeps its door too — dropped here, choosing
            // a different recording became impossible without widening
            // the tile again in arrange mode. The kicker shares the row:
            // at half width there is no room to stack it above.
            HStack(spacing: 0) {
                ChapelKicker("ph-music-note", "Chant", compact: true)
                overflowButton
            }
            .padding(.bottom, -10)

            playButton(size: 52, iconSize: 16)

            Text(player.current.latinTitle.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)

            // The error outranks the time: a chant that could not be
            // reached has no time to report, and saying nothing about it
            // is how the half tile came to swallow the failure whole.
            Text(player.errorMessage ?? player.timeLabel ?? player.current.detail)
                .font(AppFonts.italicFont(12))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            scrubLine
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var overflowButton: some View {
        Button(action: onOpenSheet) {
            AppIcon("ph-dots-three", size: 16)
                .foregroundColor(AppColors.gold.opacity(0.65))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All chants")
    }

    private func playButton(size: CGFloat, iconSize: CGFloat) -> some View {
        Button(action: { player.togglePlayback() }) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                Circle()
                    .strokeBorder(AppColors.goldLight, lineWidth: 1)

                if player.isLoading {
                    ProgressView()
                        .tint(AppColors.goldLight)
                        .scaleEffect(0.8)
                } else {
                    AppIcon(player.isPlaying ? "ph-pause-fill" : "ph-play-fill", size: iconSize)
                        .foregroundColor(AppColors.goldLight)
                }
            }
            .frame(width: size, height: size)
            .haloGlow(AppColors.gold, radius: 9, intensity: 0.3)
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
            }
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Reflections

/// The latest journal entry, opened by an illuminated versal — writing,
/// not a list.
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

    var body: some View {
        if span == 2 { full } else { half }
    }

    private var full: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let latest {
                entryLine(latest.text, versalSize: 42, bodySize: 15)

                HStack(spacing: 12) {
                    Text(dateLine(latest))
                        .font(AppFonts.labelFont(9))
                        .tracking(1.5)
                        .foregroundColor(AppColors.gold.opacity(0.7))

                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)

                    ChapelTextAct(title: "Open journal") {
                        router.switchTo(.journal)
                    }
                    .padding(.vertical, -10)
                }
                .padding(.top, 12)
            } else {
                emptyBody
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ChapelOutline())
    }

    private var half: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let latest {
                if let versal = versal(of: latest.text) {
                    Text(versal)
                        .font(AppFonts.headlineFont(34))
                        .foregroundColor(AppColors.gold)
                        .frame(height: 26, alignment: .bottomLeading)
                }

                // The reader's own writing, so it keeps the card floor
                // and the shared reading rhythm rather than a literal
                // leading that would not move when the text size does.
                Text(remainder(of: latest.text))
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.88))
                    .lineSpacing(ReadingTypography.lineSpacing(for: 15))
                    .lineLimit(versal(of: latest.text) == nil ? 4 : 3)

                Text(dateLine(latest))
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.7))
                    .padding(.top, 2)
            } else {
                AppIcon("ph-note-pencil", size: 20)
                    .foregroundColor(AppColors.gold.opacity(0.6))

                Text("Your reflections will gather here after prayer.")
                    .font(AppFonts.italicFont(12.5))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 15)
        .padding(.bottom, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ChapelOutline())
    }

    // MARK: Bits

    private func entryLine(_ text: String, versalSize: CGFloat, bodySize: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 13) {
            if let versal = versal(of: text) {
                Text(versal)
                    .font(AppFonts.headlineFont(versalSize))
                    .foregroundColor(AppColors.gold)
                    .frame(height: versalSize * 0.78, alignment: .bottomLeading)
                    .padding(.top, 3)
            }

            Text(remainder(of: text))
                .font(AppFonts.readingItalicFont(bodySize))
                .foregroundColor(AppColors.cream.opacity(0.88))
                .lineSpacing(ReadingTypography.lineSpacing(for: bodySize))
                .lineLimit(3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    /// The illuminated initial — only when the entry opens on a letter.
    /// An entry that opens on a quotation mark gets no illumination at
    /// all, the same rule DropCapText follows: a gilded quote mark reads
    /// as a mistake.
    private func versal(of text: String) -> String? {
        guard let first = text.first, first.isLetter else { return nil }
        return String(first).uppercased()
    }

    private func remainder(of text: String) -> String {
        guard let first = text.first, first.isLetter else { return text }
        return String(text.dropFirst())
    }

    private func dateLine(_ entry: JournalEntry) -> String {
        entry.createdAt
            .formatted(date: .abbreviated, time: .omitted)
            .uppercased()
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your reflections will gather here after prayer.")
                .font(AppFonts.italicFont(14))
                .foregroundColor(AppColors.textSecondary)

            ChapelTextAct(title: "Open journal") {
                router.switchTo(.journal)
            }
            .padding(.vertical, -10)
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Prayer Streak

/// The streak as a burning orb. It never scolds: only days prayed are
/// marked, and the milestone ahead is an invitation. Tapping it opens
/// the Prayer Record.
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

    /// "A Novena begins at nine." — the next milestone as a standing
    /// invitation, in words rather than a countdown.
    private var milestoneLine: String? {
        guard let next = StreakMilestone.next(after: streak) else { return nil }
        switch next.days {
        case 3:   return "A Triduum begins at three."
        case 7:   return "A faithful week begins at seven."
        case 9:   return "A Novena begins at nine."
        case 33:  return "The Consecration begins at thirty-three."
        case 54:  return "The great Novena begins at fifty-four."
        default:  return "\(next.name) begins at \(next.days)."
        }
    }

    var body: some View {
        Button(action: onOpen) {
            Group {
                if span == 2 { full } else { half }
            }
            .frame(maxWidth: .infinity)
            .modifier(ChapelOutline(cornerRadius: 20, borderOpacity: 0.28))
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak: \(streakLabel). Opens the Prayer Record.")
    }

    private var full: some View {
        HStack(spacing: 18) {
            FlameOrb(isLit: hasPrayedToday, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT STREAK")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Text(streakLabel)
                    .font(AppFonts.headlineFont(19))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let milestoneLine {
                    Text(milestoneLine)
                        .font(AppFonts.italicFont(12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 0)

            if !weekStatus.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(weekStatus.enumerated()), id: \.offset) { _, day in
                        Circle()
                            .fill(
                                day.didPray
                                    ? AppColors.gold
                                    : AppColors.cream.opacity(0.16)
                            )
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var half: some View {
        VStack(spacing: 10) {
            FlameOrb(isLit: hasPrayedToday, size: 46)

            Text("CURRENT STREAK")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold)

            Text(streakLabel)
                .font(AppFonts.headlineFont(15))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)

            if let milestoneLine {
                Text(milestoneLine)
                    .font(AppFonts.italicFont(12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }
}
