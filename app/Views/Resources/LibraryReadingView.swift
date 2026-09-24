//
//  LibraryReadingView.swift
//  Lumen Viae
//
//  One reading of the Marian Library, set like a short chapter: the
//  shelf and its place on it as the kicker, the name in Cinzel, the line
//  that dates it, a painting in the arch where one belongs, the saying
//  set apart as a quotation, and then the prose, opening on a versal.
//
//  Beneath the reading, a ruled ledger of what the page leads to — the
//  feast it is kept on (which opens that day's Mass), the mysteries or
//  prayer it is prayed in, and the pages it belongs beside. A reading
//  that only informs is a card; this one ends in a door.
//
//  The foot steps to the neighbouring readings on the same shelf in
//  place, as the chapter readers do, so walking a shelf never stacks a
//  screen per page. A step fades the page out, swaps the reading and
//  returns to the top while nothing is drawn, then fades the new one in:
//  re-identifying the page inside the scroll view laid the two readings
//  out together, and the scroll to the top ran over the old title before
//  the new one arrived. A door to a reading on another shelf is pushed,
//  so Back still returns to the reading it was opened from.
//
//  `DevotionPrayerView`, at the foot of the file, is the page a prayer
//  door opens: the Litany, the hymns, the Magnificat. The readings
//  themselves are data (`Models/LibraryReading.swift`).
//

import SwiftUI

// MARK: - LibraryReadingView

struct LibraryReadingView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(UserSettings.self) private var settings

    /// The reading on the page — starts as the one pushed, and moves as
    /// the foot steps along the shelf
    @State private var entryID: String

    /// Lowered while a step is under way, so the swap happens unseen
    @State private var pageVisible = true

    /// The reading a step is turning to; set by the foot and the
    /// same-shelf doors, taken up where the scroll proxy lives
    @State private var turnTarget: String?

    init(entryID: String) {
        _entryID = State(initialValue: entryID)
    }

    private static let topAnchor = "marian-entry-top"

    private var readingSize: CGFloat { max(16, settings.meditationFontSize - 2) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.appGradient
                    .ignoresSafeArea()

                if let located = LibraryReadings.locate(id: entryID) {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            page(
                                section: located.section,
                                index: located.index,
                                width: geometry.size.width
                            )
                            .opacity(pageVisible ? 1 : 0)
                        }
                        .topChromeFade()
                        .onChange(of: turnTarget) { _, target in
                            guard let target else { return }
                            turnPage(to: target, proxy: proxy)
                        }
                    }
                } else {
                    Text("This page could not be found.")
                        .font(AppFonts.readingItalicFont(16))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }

    // MARK: - Page

    /// Out, swap and scroll unseen, in. The swap runs with animations
    /// disabled, so the scroll to the top is a jump nobody watches and
    /// the new reading is laid out alone.
    private func turnPage(to id: String, proxy: ScrollViewProxy) {
        withAnimation(Motion.ease(0.16)) {
            pageVisible = false
        } completion: {
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) {
                entryID = id
                proxy.scrollTo(Self.topAnchor, anchor: .top)
            }
            turnTarget = nil
            withAnimation(Motion.ease(0.28)) {
                pageVisible = true
            }
        }
    }

    /// Asks for a step along the shelf; one at a time, and never to the
    /// page already open
    private func turn(to id: String) {
        guard turnTarget == nil, id != entryID else { return }
        turnTarget = id
    }

    private func page(section: ReadingShelf, index: Int, width: CGFloat) -> some View {
        let entry = section.entries[index]

        return VStack(spacing: 0) {
            Color.clear
                .frame(height: 1)
                .id(Self.topAnchor)

            titling(entry, section: section, index: index)
                .devotionalEntrance()

            if let painting = entry.painting {
                frontispiece(painting, width: min(width * 0.46, 210))
                    .padding(.top, 26)
                    .devotionalEntrance(delay: 0.06)
            }

            if let quote = entry.quote {
                QuotedPassageText(passage: quote.text, citation: quote.citation, size: readingSize - 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                    .padding(.trailing, 28)
                    .padding(.top, 30)
                    .devotionalEntrance(delay: 0.1)
            }

            if !entry.paragraphs.isEmpty {
                ReadingText(
                    text: entry.paragraphs.joined(separator: "\n\n"),
                    size: readingSize,
                    showsDropCap: true
                )
                .padding(.horizontal, 28)
                .padding(.top, 30)
                .devotionalEntrance(delay: 0.14)
            }

            if !entry.parts.isEmpty {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(entry.parts, id: \.self) { part in
                        VStack(alignment: .leading, spacing: 12) {
                            engravedHeading(part.title)

                            ReadingText(text: part.text, size: readingSize)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 30)
                .devotionalEntrance(delay: 0.16)
            }

            if !entry.tables.isEmpty {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(entry.tables, id: \.self) { table in
                        tableView(table)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
            }

            ledger(entry, section: section)
                .padding(.top, 34)

            stepper(section: section, index: index)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 48)
        }
        .padding(.top, 8)
    }

    // MARK: - Titling

    private func titling(_ entry: LibraryReading, section: ReadingShelf, index: Int) -> some View {
        VStack(spacing: 16) {
            Text("\(section.title.uppercased()) · \(ReadingShelf.numeral(index + 1)) OF \(ReadingShelf.numeral(section.entries.count))")
                .font(AppFonts.labelFont(9))
                .tracking(2.4)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            OrnamentDivider()
                .frame(width: 150)

            Text(entry.title)
                .font(AppFonts.titleFont(27))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.detail)
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.gold.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func frontispiece(_ painting: String, width: CGFloat) -> some View {
        let arch = GothicArchShape(riseRatio: 0.34)

        return arch
            .fill(AppColors.cardBackground)
            .frame(width: width, height: width * 1.22)
            .overlay(CachedAssetImage(painting))
            .clipShape(arch)
            .accessibilityHidden(true)
    }

    // MARK: - Tables

    /// A heading in engraved caps over a hairline, then each row as the
    /// label in quiet type and its value in the reading face beneath —
    /// a mystery, and the grace to ask in it.
    private func tableView(_ table: ReadingTable) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            engravedHeading(table.title)

            ForEach(table.rows, id: \.self) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.label)
                        .font(AppFonts.readingItalicFont(max(14, readingSize - 4)))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(row.value)
                        .font(AppFonts.readingFont(max(16, readingSize - 1)))
                        .foregroundColor(AppColors.cream.opacity(0.92))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// A part's name in engraved caps over a hairline that fades out
    private func engravedHeading(_ title: String) -> some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.gold.opacity(0.85))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.35), AppColors.gold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppLine.hairline)
                .frame(minWidth: 24)
        }
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Ledger

    @ViewBuilder
    private func ledger(_ entry: LibraryReading, section: ReadingShelf) -> some View {
        let prayerDoors = entry.doors.filter {
            if case .page = $0 { return false }
            return true
        }
        let pageDoors = entry.doors.filter {
            if case .page = $0 { return true }
            return false
        } + homeDoor(for: entry, section: section)

        if entry.feast != nil || !prayerDoors.isEmpty || !pageDoors.isEmpty {
            VStack(spacing: 0) {
                if let feast = entry.feast {
                    SetSection(label: "Feast day") {
                        feastBlock(feast)
                    }
                }

                if !prayerDoors.isEmpty {
                    SetSection(label: "Pray") {
                        doorList(prayerDoors)
                    }
                }

                if !pageDoors.isEmpty {
                    SetSection(label: "Read more") {
                        doorList(pageDoors)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func feastBlock(_ feast: KeptFeast) -> some View {
        let isToday = feast.isToday()

        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(feast.dateLabel)
                    .font(AppFonts.readingFont(16))
                    .foregroundColor(isToday ? AppColors.goldLight : AppColors.cream.opacity(0.92))

                if isToday {
                    Text("TODAY")
                        .font(AppFonts.labelFont(8))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.8))
                }
            }

            Text(feast.keptBy.map { "\(feast.name) · kept in \($0)" } ?? feast.name)
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let note = feast.calendarNote {
                Text(note)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.textSecondary.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if feast.inMissal, let date = feast.nextDate() {
                // The act's 44pt frame carries 10pt of air under its words;
                // the section's own 26pt foot is margin enough, so that air
                // is let into it rather than added to it — as the door rows
                // below do
                QuietGoldButton(
                    title: isToday ? "Today's Mass" : "The day's Mass",
                    trailingIcon: "ph-caret-right",
                    horizontalPadding: 0
                ) {
                    router.push(.missalDay(date))
                }
                .padding(.top, 2)
                .padding(.bottom, -10)
            }
        }
    }

    private func doorList(_ doors: [ReadingDoor]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(doors, id: \.self) { door in
                switch door {
                case .mysteries(let category, let note):
                    LedgerDoorRow(title: category.devotionTitle, note: note, icon: "ch-rosary") {
                        router.navigateToMeditationSelection(category: category)
                    }

                case .prayer(let id, let note):
                    LedgerDoorRow(title: Self.prayerTitle(id, language: settings.prayerLanguage), note: note, icon: "ph-hands-praying") {
                        router.push(.devotionPrayer(id: id))
                    }

                case .act(let shortcut, let note):
                    LedgerDoorRow(title: shortcut.title, note: note, icon: shortcut.icon) {
                        router.run(shortcut)
                    }

                case .page(let route, let icon, let title, let note):
                    LedgerDoorRow(title: title, note: note, icon: icon) {
                        open(route)
                    }
                }
            }
        }
        .padding(.vertical, -10)
    }

    /// A door to another reading on the same shelf turns the page in
    /// place, like the foot; a reading on another shelf, and any other
    /// page, is pushed — turned in place, Back skipped the reading the
    /// door was opened from, and the kicker changed shelves under the
    /// reader's feet.
    private func open(_ route: AppRoute) {
        if case .libraryReading(let id) = route,
           let here = LibraryReadings.locate(id: entryID),
           here.section.entries.contains(where: { $0.id == id }) {
            turn(to: id)
        } else {
            router.push(route)
        }
    }

    /// The library the shelf stands in, as the ledger's last door — a
    /// reading opened from Explore or How to Pray otherwise names its
    /// shelf and offers no way to the rest of it. Left out where the
    /// reading already opens that page.
    private func homeDoor(for entry: LibraryReading, section: ReadingShelf) -> [ReadingDoor] {
        guard let home = LibraryReadings.home(of: section),
              case .page(let homeRoute, _, _, _) = home else { return [] }
        let alreadyThere = entry.doors.contains {
            if case .page(let route, _, _, _) = $0 { return route == homeRoute }
            return false
        }
        return alreadyThere ? [] : [home]
    }

    static func prayerTitle(_ id: String, language: PrayerLanguage) -> String {
        DevotionPrayers.find(id)?.displayTitle(for: language) ?? ""
    }

    // MARK: - Stepper

    /// The readings either side on the same shelf, named, so the reader
    /// knows where a step leads before taking it. Missing at a shelf's
    /// end rather than greyed.
    private func stepper(section: ReadingShelf, index: Int) -> some View {
        let previous = index > 0 ? section.entries[index - 1] : nil
        let next = index + 1 < section.entries.count ? section.entries[index + 1] : nil

        return VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.gold.opacity(0.18))
                .frame(height: AppLine.hairline)

            HStack(alignment: .top, spacing: 16) {
                if let previous {
                    stepButton(previous, label: "Previous", leading: true)
                } else {
                    Spacer()
                }

                if let next {
                    stepButton(next, label: "Next", leading: false)
                } else {
                    Spacer()
                }
            }
            .padding(.top, 14)
        }
    }

    private func stepButton(_ entry: LibraryReading, label: String, leading: Bool) -> some View {
        Button {
            turn(to: entry.id)
        } label: {
            VStack(alignment: leading ? .leading : .trailing, spacing: 5) {
                HStack(spacing: 5) {
                    if leading { AppIcon("ph-caret-left", size: 8) }
                    Text(label.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1.8)
                    if !leading { AppIcon("ph-caret-right", size: 8) }
                }
                .foregroundColor(AppColors.gold.opacity(0.75))

                Text(entry.title)
                    .font(AppFonts.readingFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.88))
                    .multilineTextAlignment(leading ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: leading ? .leading : .trailing)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(entry.title)")
    }
}

// MARK: - DevotionPrayerView

/// A prayer of Our Lady on a page of its own: the Latin name as the
/// kicker, the English in Cinzel, and the prayer beneath in the
/// prayer-book grammar, in the reader's prayer language.
struct DevotionPrayerView: View {

    let prayerID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings

    private var prayer: BilingualConsecrationPrayer? {
        DevotionPrayers.find(prayerID)
    }

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            if let prayer {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            Text(prayer.latinTitle.uppercased())
                                .font(AppFonts.labelFont(9.5))
                                .tracking(3)
                                .foregroundColor(AppColors.gold)
                                .multilineTextAlignment(.center)

                            OrnamentDivider()
                                .frame(width: 150)

                            Text(prayer.englishTitle)
                                .font(AppFonts.titleFont(27))
                                .foregroundColor(AppColors.cream)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                                .minimumScaleFactor(0.6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 28)
                        .frame(maxWidth: .infinity)
                        .devotionalEntrance()

                        PrayerText(
                            content: prayer.formattedContent(for: settings.prayerLanguage),
                            size: max(16, settings.meditationFontSize - 2),
                            alignment: .leading,
                            showsDropCap: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.top, 34)
                        .padding(.bottom, 56)
                        .devotionalEntrance(delay: 0.08)
                    }
                    .padding(.top, 8)
                }
                .topChromeFade()
            } else {
                Text("This prayer could not be found.")
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        AppIcon("ph-caret-left", size: 14)
                        Text("Back")
                            .font(AppFonts.bodyFont(16))
                    }
                    .foregroundColor(AppColors.gold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Entry") {
    NavigationStack {
        LibraryReadingView(entryID: "lourdes")
            .environment(AppRouter())
            .environment(UserSettings.shared)
    }
}

#Preview("Prayer") {
    NavigationStack {
        DevotionPrayerView(prayerID: "litany_loreto")
            .environment(UserSettings.shared)
    }
}
