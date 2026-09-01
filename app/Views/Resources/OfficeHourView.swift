//
//  OfficeHourView.swift
//  Lumen Viae
//
//  One canonical hour, read in full — Lauds at dawn, Compline before
//  sleep — under the missal's own reader.
//
//  The hour is named in the bar and nowhere else on the screen. Beneath
//  it the day is stated once, in two lines: the date with the day's
//  class, and the feast. An earlier draft repeated the hour as a 28pt
//  heading under a bar already reading TERCE, carried the full Latin
//  day-title, set a TERTIA · III. CLASSIS row, and hung a ‹ TODAY ›
//  stepper below all of it — four ways of saying what the bar and one
//  line already say. The chrome above the text is now two lines and a
//  rail, and the reading begins about a third of the way up the screen
//  instead of halfway down.
//
//  The date is kept here, unlike the landing, because the reader can be
//  opened on another day from the landing's calendar and has no other
//  way of saying which day's office you are in. It is a statement, not
//  a control: the day is chosen on the landing.
//
//  Matins runs to nine psalms and nine lessons. Without a rail and an
//  index it is a thumb's length of scrolling to find the Te Deum, which
//  is the whole reason the missal grew this chrome.
//
//  The header is the screen's own chrome — back button included — so
//  this page hides the system bar, and every branch it can draw carries
//  that Back.
//

import SwiftUI

struct OfficeHourView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewModel: OfficeViewModel

    @State var hour: CanonicalHour

    // MARK: - State

    private enum OfficeSheet: String, Identifiable {
        case reading
        case index

        var id: String { rawValue }
    }

    @State private var sheet: OfficeSheet?

    @State private var office: OfficeHour?
    @State private var isLoading = false
    @State private var loadFailed = false

    /// The hour as the reader shows it — named, addressable sections.
    /// Built when a load lands rather than derived in the body, which
    /// every frame of every scroll would otherwise re-walk.
    @State private var readerSections: [OfficeReaderSection] = []

    /// Header collapse, driven by scroll offset with hysteresis so the
    /// boundary never flutters. The thresholds are taken from the
    /// plate's own height rather than the missal's 96/44: this plate is
    /// two lines, and a fixed 96 would have left the text sliding under
    /// a plate that was still standing.
    @State private var collapsed = false

    /// Index into `readerSections` of the section under the header
    @State private var activeSectionIndex = 0

    /// Natural height of the day plate — the part that collapses
    @State private var plateHeight: CGFloat = 60

    /// Measured height of the rail-and-progress block under the plate
    @State private var railBlockHeight: CGFloat = 70

    /// A section id waiting to be scrolled to
    @State private var pendingJump: String?

    /// Where the header's inset area begins, in global points
    @State private var headerGlobalTop: CGFloat = 0

    /// Each section's top measured against the content itself — values
    /// that scrolling never moves.
    @State private var sectionTops: [Int: CGFloat] = [:]

    /// How far the content's top has risen past the header's foot
    @State private var scrolledPastTop: CGFloat = 0

    /// The bilingual order restored when "Both" is re-chosen here, so a
    /// switch to Latin and back never overrides the order set in Account.
    @State private var preferredBilingual: PrayerLanguage = .both

    // MARK: - Layout Constants

    private static let topAnchorID = "office-top"
    private static let contentSpace = "officeContent"

    /// The air between the collapsed header and a jumped-to section
    private static let jumpGap: CGFloat = 22

    /// Section run — split so each section's anchor carries the jump gap
    private static let sectionGap: CGFloat = 36

    /// The chrome row's height (its circular buttons are 44pt)
    private static let chromeHeight: CGFloat = 44

    // MARK: - Derived

    /// The breviary is set at the missal's size: the same kind of page,
    /// and a reader who sets the type once should not set it twice.
    private var readingSize: CGFloat { settings.missalFontSize }

    /// The scroll inset the header keeps for itself: its collapsed
    /// height. The plate's share rides at the top of the content, so it
    /// scrolls away exactly as the plate collapses.
    private var collapsedHeaderHeight: CGFloat { Self.chromeHeight + railBlockHeight }

    /// A load is owed whenever the day or the hour changes
    private var reloadKey: String { "\(viewModel.dayString)|\(hour.rawValue)" }

    /// The index sheet stands as tall as its own ledger: Prime keeps six
    /// sections and Matins fifteen, and a fixed detent leaves the short
    /// hours mostly empty sheet.
    private var indexSheetHeight: CGFloat {
        let rows = CGFloat(readerSections.named.count)
        return min(660, max(300, rows * 60 + 130))
    }

    /// The day's place in the calendar — the hour's own copy once it has
    /// landed, the ledger's until then, so the plate is complete before
    /// the text arrives. Read for the day's class only.
    private var celebration: OfficeCelebration? {
        office?.celebration ?? viewModel.day?.celebration
    }

    /// The feast, in English where the missal can supply it — the
    /// breviary names the day only in Latin, and the chrome above the
    /// text is English throughout. Falls back to the engine's own
    /// wording rather than leaving the plate half-empty.
    private var feastTitle: String? {
        viewModel.feastTitle ?? celebration?.title
    }

    /// The design system's --ease-out — cubic-bezier(0, 0, 0.58, 1).
    private func anim(_ duration: Double) -> Animation? {
        reduceMotion ? nil : .timingCurve(0, 0, 0.58, 1, duration: duration)
    }

    /// Ease-in-out for travel — the jump to a section leaves as gently
    /// as it arrives.
    private func travelAnim(_ duration: Double) -> Animation? {
        reduceMotion ? nil : .timingCurve(0.42, 0, 0.58, 1, duration: duration)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.appGradient
                .ignoresSafeArea()

            reader
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $sheet) { presented in
            switch presented {
            case .reading:
                OfficeReadingSheet(preferredBilingual: $preferredBilingual)
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(22)

            case .index:
                OfficeIndexSheet(
                    hour: hour,
                    sections: readerSections,
                    activeIndex: activeSectionIndex
                ) { target in
                    pendingJump = target
                }
                .presentationDetents([.height(indexSheetHeight)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(22)
            }
        }
        .onChange(of: reloadKey) { pendingJump = Self.topAnchorID }
        .task(id: reloadKey) {
            if settings.prayerLanguage.isBilingual {
                preferredBilingual = settings.prayerLanguage
            }
            await load()
        }
    }

    // MARK: - Reader

    private var reader: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                content
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                // The inset holds only the collapsed chrome; the plate
                // overflows it downward, drawn over the content that
                // slides beneath as the page scrolls.
                header
                    .frame(height: collapsedHeaderHeight, alignment: .top)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).minY
                    } action: { top in
                        headerGlobalTop = top
                    }
            }
            .onChange(of: pendingJump) { _, target in
                guard let target else { return }
                // The last section is the end of the leaf. Pulled to the
                // top it asks for more page than exists, and a lazily
                // built column answers that by scrolling past its own
                // end into blank. Anchored to the foot, the same tap
                // lands on the conclusion with the colophon beneath it.
                let anchor: UnitPoint = target == readerSections.last?.id ? .bottom : .top
                withAnimation(travelAnim(0.5)) {
                    proxy.scrollTo(target, anchor: anchor)
                }
                pendingJump = nil
            }
        }
    }

    // MARK: - Scroll Handling

    /// The header's inset foot, in the same global points the markers
    /// report — where the content's top rests before any scroll.
    private var headerFootGlobal: CGFloat { headerGlobalTop + collapsedHeaderHeight }

    private func handleScrollOffset(_ markerGlobalMinY: CGFloat) {
        scrolledPastTop = headerFootGlobal - markerGlobalMinY
        // The missal's 0.64 / 0.29 of the plate, which on its 150pt
        // plate is the 96 / 44 that page was tuned at. Floored, so a
        // plate measured at zero before its first layout cannot collapse
        // the header on the very first pixel of scroll.
        let plate = max(24, plateHeight)
        let shouldCollapse = collapsed
            ? scrolledPastTop > plate * 0.29
            : scrolledPastTop > plate * 0.64
        if shouldCollapse != collapsed {
            collapsed = shouldCollapse
        }
        refreshActiveSection()
    }

    private func handleSectionTop(_ index: Int, _ contentMinY: CGFloat) {
        sectionTops[index] = contentMinY
        refreshActiveSection()
    }

    /// The active section is the last one whose top has risen into the
    /// band just under the collapsed header.
    private func refreshActiveSection() {
        let limit = scrolledPastTop + 33
        let active = sectionTops.filter { $0.value < limit }.keys.max() ?? 0
        if active != activeSectionIndex {
            activeSectionIndex = active
        }
    }

    /// The measured tops name section *indices*, so a new hour has to
    /// throw them away with the list.
    private func resetSectionTracking() {
        sectionTops = [:]
        activeSectionIndex = 0
        collapsed = false
        scrolledPastTop = 0
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            chromeRow
            plate
            railBlock
        }
        .background(alignment: .top) { headerBackground }
    }

    /// The page's own colour, dissolving at the foot — text passes into
    /// the chrome instead of hitting a panel edge.
    private var headerBackground: some View {
        LinearGradient(
            stops: [
                .init(color: AppColors.background, location: 0),
                .init(color: AppColors.background, location: 0.84),
                .init(color: AppColors.background.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Chrome Row

    private var chromeRow: some View {
        HStack(spacing: 4) {
            PrayerHeaderButton(icon: "ph-caret-left", size: 16, label: "The hours") {
                dismiss()
            }

            Spacer(minLength: 0)

            PrayerHeaderButton(icon: "ph-list", size: 17, label: "This hour's order") {
                sheet = .index
            }

            PrayerHeaderButton(icon: "ph-text-aa", size: 18, label: "Reading settings") {
                sheet = .reading
            }
        }
        .padding(.horizontal, 12)
        .frame(height: Self.chromeHeight)
        // Centred on the screen, not flexed between the buttons — the
        // two right-hand buttons would otherwise pull the title left.
        .overlay { hourTitle }
    }

    /// The hour, named here and nowhere else on the screen. It no longer
    /// crossfades with anything: the plate beneath states the day, the
    /// bar states the hour, and neither has to take turns.
    private var hourTitle: some View {
        Text(hour.label.uppercased())
            .font(AppFonts.labelFont(12.5))
            .tracking(2.5)
            .foregroundColor(AppColors.cream)
            .lineLimit(1)
            .frame(maxWidth: 210)
            .allowsHitTesting(false)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Day Plate

    /// The collapsing band: measured at its natural height, then framed
    /// to zero when collapsed.
    private var plate: some View {
        plateContent
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                plateHeight = height
            }
            .opacity(collapsed ? 0 : 1)
            .animation(anim(0.24), value: collapsed)
            .frame(height: collapsed ? 0 : plateHeight, alignment: .top)
            .clipped()
            .offset(y: collapsed ? -10 : 0)
            .animation(anim(0.34), value: collapsed)
    }

    /// The day, in two lines. Never has to wait for the text: the date
    /// is known before a line is fetched, and the day's class and feast
    /// come from the ledger's own copy until the hour lands with its.
    private var plateContent: some View {
        VStack(spacing: 5) {
            Text(dayLine)
                .font(AppFonts.labelFont(9.5))
                .tracking(2.4)
                .foregroundColor(AppColors.gold.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let feastTitle {
                Text(feastTitle)
                    .font(AppFonts.italicFont(14.5))
                    .foregroundColor(AppColors.accentSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .animation(anim(0.3), value: feastTitle ?? "")
    }

    /// "THURSDAY, 27 AUGUST  ·  THIRD CLASS" — the day's class in
    /// English, mapped from the engine's Latin rather than printed as it
    /// arrived. A feria carries no class and the line is just the date.
    private var dayLine: String {
        let date = Self.plateDateFormatter.string(from: viewModel.date)
        guard let rank = OfficeRank(celebration?.rank).englishLabel else {
            return date.uppercased()
        }
        return "\(date)  ·  \(rank)".uppercased()
    }

    // MARK: - Rail and Progress

    private var railBlock: some View {
        VStack(spacing: 0) {
            if !railSections.isEmpty {
                sectionRail
                    .padding(.top, 16)

                progressLine
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 12)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            railBlockHeight = height
        }
    }

    /// Only named sections ride the rail; an unnamed one is a
    /// continuation of the section above it.
    private var railSections: [OfficeReaderSection] {
        readerSections.named
    }

    /// The rail's lit item, by the same rule the ☰ ledger lights a row
    /// with — `namedSection(containing:)` holds it for both.
    private var activeRailIndex: Int? {
        readerSections.namedSection(containing: activeSectionIndex)?.index
    }

    private var sectionRail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(railSections) { section in
                        railItem(section)
                            .id(section.index)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: activeRailIndex) { _, index in
                guard let index else { return }
                withAnimation(anim(0.3)) {
                    proxy.scrollTo(index, anchor: UnitPoint(x: 0.22, y: 0.5))
                }
            }
            // The rail reads as scrollable without a scrollbar: the
            // last name runs out under the page's own colour instead of
            // stopping at the margin.
            .overlay(alignment: .trailing) {
                LinearGradient(
                    colors: [AppColors.background.opacity(0), AppColors.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 52)
                .allowsHitTesting(false)
            }
        }
    }

    private func railItem(_ section: OfficeReaderSection) -> some View {
        let isActive = section.index == activeRailIndex
        let color: Color = isActive ? AppColors.gold : AppColors.textSecondary

        return Button {
            pendingJump = section.id
        } label: {
            VStack(spacing: 7) {
                Text(section.railName.uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(2)
                    .lineLimit(1)
                    .foregroundColor(color)

                Rectangle()
                    .fill(isActive ? AppColors.gold.opacity(0.85) : .clear)
                    .frame(height: 1)
            }
            .animation(anim(0.25), value: isActive)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.railName)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var progressLine: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.12))

                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.gold.opacity(0.35), AppColors.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * progressFraction)
            }
        }
        .frame(height: 1)
        .animation(anim(0.4), value: activeSectionIndex)
        .accessibilityHidden(true)
    }

    private var progressFraction: CGFloat {
        guard !readerSections.isEmpty else { return 0 }
        return CGFloat(activeSectionIndex + 1) / CGFloat(readerSections.count)
    }

    // MARK: - Content

    private var content: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // The plate's share of the resting header. The first
            // section's own top padding supplies the jump gap, so this
            // spacer gives that much back.
            Color.clear
                .frame(height: max(0, plateHeight - Self.jumpGap))
                .id(Self.topAnchorID)

            if isLoading {
                loadingState
            } else if loadFailed {
                errorState
            } else {
                // The versal opens the hour's own first words — the
                // section view withholds it when those words begin on a
                // rubric mark rather than a letter.
                let versalID = readerSections.first?.id

                ForEach(readerSections) { section in
                    OfficeSectionView(
                        section: section,
                        size: readingSize,
                        language: settings.prayerLanguage,
                        layout: settings.missalLayout,
                        showsDropCap: section.id == versalID
                    )
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .named(Self.contentSpace)).minY
                    } action: { minY in
                        handleSectionTop(section.index, minY)
                    }
                    .padding(.top, Self.jumpGap)
                    .padding(.bottom, Self.sectionGap - Self.jumpGap)
                    .id(section.id)
                }

                if !readerSections.isEmpty {
                    colophon
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 90)
        .coordinateSpace(name: Self.contentSpace)
        // The whole content column carries the scroll marker: unlike a
        // marker inside the lazy stack, it can never be released
        // mid-scroll, so the offset never goes stale.
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).minY
        } action: { minY in
            handleScrollOffset(minY)
        }
    }

    // MARK: - Colophon

    /// The scribe's close — "here ends Lauds" — and then the way on, to
    /// the hour before or after this one. Not "Benedicamus Domino": the
    /// hour's own Conclusio prints those words three lines above, and a
    /// colophon repeating them reads as a stutter rather than a close.
    private var colophon: some View {
        VStack(spacing: 14) {
            OrnamentDivider()
                .frame(width: 150)
                .padding(.top, 8)

            Text(hour.explicit)
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(AppColors.gold.opacity(0.5))

            HStack {
                if let previous = hour.previous {
                    QuietGoldButton(
                        title: previous.label,
                        leadingIcon: "ph-caret-left",
                        leadingIconSize: 9,
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 0
                    ) {
                        hour = previous
                    }
                }

                Spacer()

                if let next = hour.next {
                    QuietGoldButton(
                        title: next.label,
                        trailingIcon: "ph-caret-right",
                        size: 10,
                        color: AppColors.gold,
                        horizontalPadding: 0
                    ) {
                        hour = next
                    }
                }
            }
            .padding(.top, 6)

            Text("Breviarium Romanum 1962 · texts served by \(office?.source.name ?? "The Divinum Officium Project")")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - States

    private var loadingState: some View {
        ProgressView()
            .tint(AppColors.gold)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
    }

    private var errorState: some View {
        VStack(spacing: 16) {
            Text("\(hour.label) could not be reached. Check your connection and try again.")
                .font(AppFonts.bodyFont(14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            QuietGoldButton(
                title: "Try again",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 11,
                size: 10,
                color: AppColors.gold
            ) {
                Task { await load() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Loading

    private func load() async {
        office = nil
        readerSections = []
        resetSectionTracking()
        isLoading = true
        loadFailed = false

        do {
            let fetched = try await viewModel.loadHour(hour)
            office = fetched
            readerSections = OfficeReaderSection.build(from: fetched.sections)
        } catch {
            loadFailed = true
        }

        isLoading = false
    }

    // MARK: - Helpers

    /// "Thursday, 27 August"
    private static let plateDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OfficeHourView(viewModel: OfficeViewModel(), hour: .lauds)
    }
    .environment(UserSettings.shared)
}
