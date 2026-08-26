//
//  DailyMissalView.swift
//  Lumen Viae
//
//  The Daily Missal: the 1962 propers for any day, served by Missale
//  Meum, under one collapsing header. A single scroll surface carries
//  the Mass; the header holds the day's feast on a plate that gives
//  way — as the reader moves into the text — to the feast's name in
//  the chrome, a jump-to-section rail, and a hair of progress. Three
//  sheets do everything the old three-band masthead did without
//  standing on the page: reading settings (Aa), the Ordo Missæ index
//  (☰), and the month's calendar (the date pill).
//
//  The header is the screen's own chrome — back button included — so
//  this is the one pushed page that hides the system bar.
//

import SwiftUI

struct DailyMissalView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(UserSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var viewModel = MissalViewModel()

    private enum MissalSheet: String, Identifiable {
        case reading
        case index
        case calendar

        var id: String { rawValue }
    }

    @State private var sheet: MissalSheet?
    @State private var showLayoutChoice = false
    @State private var showAbout = false
    @State private var showOrdoPage = false

    /// Header collapse, driven by scroll offset with hysteresis —
    /// collapse past 96, expand back under 44 — so the boundary never
    /// flutters.
    @State private var collapsed = false

    /// Index into `readerSections` of the section under the header
    @State private var activeSectionIndex = 0

    /// Natural height of the feast plate — the part that collapses
    @State private var plateHeight: CGFloat = 150

    /// Measured height of the rail-and-progress block under the plate
    @State private var railBlockHeight: CGFloat = 70

    /// A section id waiting to be scrolled to
    @State private var pendingJump: String?

    /// The day's Mass as the reader shows it — see `rebuildSections()`
    @State private var readerSections: [MissalReaderSection] = []

    /// Where the header's inset area begins, in global points — the
    /// datum the scroll markers are read against, so the offset math
    /// owes nothing to any scroll view coordinate convention.
    @State private var headerGlobalTop: CGFloat = 0

    /// The bilingual order restored when "Both" is re-chosen here, so a
    /// switch to Latin and back never overrides the order set in Account.
    @State private var preferredBilingual: PrayerLanguage = .both

    // MARK: - Layout Constants

    private static let topAnchorID = "missal-top"
    private static let contentSpace = "missalContent"

    /// The air between the collapsed header and a jumped-to section
    private static let jumpGap: CGFloat = 22

    /// Section run — 36 points between sections, split so each
    /// section's scroll anchor carries the jump gap above itself
    private static let sectionGap: CGFloat = 36

    /// The chrome row's height (its circular buttons are 44pt)
    private static let chromeHeight: CGFloat = 44

    // MARK: - Derived

    private var readingSize: CGFloat { settings.missalFontSize }

    /// The scroll inset the header keeps for itself: its collapsed
    /// height. The plate's share rides at the top of the content
    /// instead, so it scrolls away exactly as the plate collapses —
    /// the inset never changes size underneath a reading in progress.
    private var collapsedHeaderHeight: CGFloat { Self.chromeHeight + railBlockHeight }

    /// Everything the page's section list is built from. Rebuilding is
    /// keyed on this rather than derived in the body: the header writes
    /// `scrolledPastTop` on every frame of every scroll, and deriving
    /// the whole Mass there re-walked the propers and scanned the Ordo
    /// sixty times a second. The Ordo's arrival is part of the key —
    /// it lands after the first render and changes what every section
    /// index means, which the old reset list quietly missed.
    private var sectionsKey: String {
        [
            viewModel.selectedProper?.id ?? "",
            MissalAPIService.dayString(for: viewModel.date),
            String(viewModel.selectedIndex),
            String(viewModel.ordo.count),
            settings.missalScopeRaw,
            settings.missalHighMass ? "high" : "low"
        ].joined(separator: "|")
    }

    private func rebuildSections() {
        guard let proper = viewModel.selectedProper else {
            readerSections = []
            resetSectionTracking()
            return
        }
        readerSections = MissalOrderData.readerSections(
            propers: proper.sections,
            ordo: viewModel.ordo,
            scope: settings.missalScope,
            info: proper.info,
            date: viewModel.date,
            highMass: settings.missalHighMass
        )
        resetSectionTracking()
    }

    /// The measured tops name section *indices*, so any rebuild that can
    /// renumber them has to throw them away with the list.
    private func resetSectionTracking() {
        sectionTops = [:]
        activeSectionIndex = 0
    }

    /// The day's vestment — the plate's dot and the calendar's
    private var vestment: MissalVestment? {
        viewModel.selectedProper?.info.colors?.first
            .flatMap { MissalVestment(rawValue: $0) }
    }

    /// The design system's --ease-out — cubic-bezier(0, 0, 0.58, 1).
    /// Nothing bounces, nothing springs past its mark, and everything
    /// stills under Reduce Motion.
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
                MissalReadingSheet(preferredBilingual: $preferredBilingual)
                    .presentationDetents([.height(620)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(22)

            case .index:
                MissalIndexSheet(
                    sections: readerSections,
                    activeIndex: activeSectionIndex
                ) { target in
                    pendingJump = target
                }
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(22)

            case .calendar:
                MissalCalendarSheet { chosen in
                    Task { await viewModel.jump(to: chosen) }
                }
                .presentationDetents([.height(640)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(22)
            }
        }
        // The first-open question: how should the translation read?
        // Undismissable — choosing is the only way through — and asked
        // exactly once; the Aa sheet owns the setting afterward.
        .sheet(isPresented: $showLayoutChoice) {
            MissalLayoutChoiceSheet()
                .presentationDetents([.height(560)])
                .interactiveDismissDisabled()
        }
        .navigationDestination(isPresented: $showOrdoPage) {
            OrdoMissaeView()
        }
        .onChange(of: sectionsKey) { rebuildSections() }
        .onChange(of: viewModel.date) { pendingJump = Self.topAnchorID }
        .onChange(of: viewModel.selectedIndex) { pendingJump = Self.topAnchorID }
        .onAppear {
            if !settings.hasChosenMissalLayout {
                showLayoutChoice = true
            }
        }
        .task {
            if settings.prayerLanguage.isBilingual {
                preferredBilingual = settings.prayerLanguage
            }
            await viewModel.load()
            rebuildSections()
            await viewModel.loadOrdo()
            rebuildSections()
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
                // will slide beneath as the page scrolls.
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
                withAnimation(travelAnim(0.5)) {
                    proxy.scrollTo(target, anchor: .top)
                }
                pendingJump = nil
            }
        }
    }

    // MARK: - Scroll Handling

    /// The header's inset foot, in the same global points the markers
    /// report — where the content's top rests before any scroll.
    private var headerFootGlobal: CGFloat { headerGlobalTop + collapsedHeaderHeight }

    /// Each section's top measured against the content itself — values
    /// that scrolling never moves, so a mid-flight misreport from a
    /// lazily built section is always corrected by its settling layout.
    @State private var sectionTops: [Int: CGFloat] = [:]

    /// How far the content's top has risen past the header's foot
    @State private var scrolledPastTop: CGFloat = 0

    private func handleScrollOffset(_ markerGlobalMinY: CGFloat) {
        scrolledPastTop = headerFootGlobal - markerGlobalMinY
        let shouldCollapse = collapsed ? scrolledPastTop > 44 : scrolledPastTop > 96
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

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            chromeRow
            plate
            railBlock
        }
        .background(alignment: .top) { headerBackground }
    }

    /// The page's own colour, dissolving at the foot — text passes
    /// into the chrome instead of hitting a panel edge.
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
            PrayerHeaderButton(icon: "ph-caret-left", size: 16, label: "Back") {
                dismiss()
            }

            Spacer(minLength: 0)

            PrayerHeaderButton(icon: "ph-list", size: 17, label: "Order of Mass") {
                sheet = .index
            }

            PrayerHeaderButton(icon: "ph-text-aa", size: 18, label: "Reading settings") {
                sheet = .reading
            }
        }
        .padding(.horizontal, 12)
        .frame(height: Self.chromeHeight)
        // Centred on the screen, not flexed between the buttons — the
        // two right-hand buttons would otherwise pull the pill left.
        .overlay { chromeCenter }
    }

    /// The date pill and the collapsed title share the centre slot and
    /// crossfade as the header collapses.
    private var chromeCenter: some View {
        ZStack {
            datePill
                .opacity(collapsed ? 0 : 1)
                .animation(anim(0.24), value: collapsed)
                .allowsHitTesting(!collapsed)

            collapsedTitle
                .opacity(collapsed ? 1 : 0)
                .offset(y: collapsed ? 0 : 5)
                .animation(anim(0.26), value: collapsed)
                .allowsHitTesting(false)
        }
    }

    private var datePill: some View {
        Button {
            sheet = .calendar
        } label: {
            HStack(spacing: 9) {
                Text(Self.pillDateFormatter.string(from: viewModel.date).uppercased())
                    .font(AppFonts.labelFont(9.5))
                    .tracking(1.6)

                AppIcon("ph-caret-down", size: 11)
            }
            .foregroundColor(AppColors.gold)
            .lineLimit(1)
            .padding(.horizontal, 15)
            .frame(height: 30)
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(0.28), lineWidth: 0.5))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(GoldCTAButtonStyle())
        .accessibilityLabel("Choose a day")
    }

    private var collapsedTitle: some View {
        Text((viewModel.selectedProper?.info.title ?? viewModel.dateLabel).uppercased())
            .font(AppFonts.labelFont(12.5))
            .tracking(2.5)
            .foregroundColor(AppColors.cream)
            .lineLimit(1)
            .frame(maxWidth: 210)
    }

    // MARK: - Feast Plate

    /// The collapsing band: measured at its natural height, then framed
    /// to zero when collapsed — the CSS max-height collapse, in layout.
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

    /// What stands on the plate: the feast, or the reason there isn't
    /// one yet — loading and failure live inside the same slot, so the
    /// page never breaks its shape while the day travels.
    private var plateContent: some View {
        VStack(spacing: 18) {
            if let info = viewModel.selectedProper?.info {
                feastPlate(info)
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(AppColors.gold)
                    .padding(.vertical, 24)
            } else if let error = viewModel.errorMessage {
                errorState(error)
            } else {
                emptyState
            }

            // Turning the leaf. The date pill opens the month, but a
            // missal is read a day at a time and yesterday and tomorrow
            // should cost one tap, not a sheet — and a reader who has
            // wandered needs the way back to today.
            dayStepRow
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        // A new day's feast eases onto the plate rather than snapping.
        .animation(anim(0.3), value: viewModel.selectedProper?.id ?? "")
    }

    @ViewBuilder
    private func feastPlate(_ info: MissalInfo) -> some View {
        if let tempora = nonEmpty(info.tempora) {
            Text(tempora.uppercased())
                .font(AppFonts.labelFont(8.5))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }

        Text(info.title)
            .font(AppFonts.titleFont(28))
            .foregroundColor(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

        rubricRow(info)

        if let commemorations = info.commemorations, !commemorations.isEmpty {
            Text("Commemoration of \(commemorations.map(\.title).joined(separator: " and "))")
                .font(AppFonts.italicFont(13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The vestment as a lit dot beside its name, then the 1962 class.
    @ViewBuilder
    private func rubricRow(_ info: MissalInfo) -> some View {
        let rank = info.rankLabel

        HStack(spacing: 9) {
            if let vestment {
                Circle()
                    .fill(vestment.swatch)
                    .frame(width: 7, height: 7)
                    .shadow(color: vestment.swatch.opacity(0.45), radius: 3)

                Text(vestment.name.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.textSecondary)
            }

            if vestment != nil && rank != nil {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.25))
                    .frame(width: 1, height: 9)
            }

            if let rank {
                Text(rank.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    /// Yesterday and tomorrow at the edges, and the way home between
    /// them. It rides on the plate rather than in the chrome row: the
    /// centre slot there is already the date pill's, and squeezing two
    /// more controls beside it would crowd the pill into an ellipsis.
    private var dayStepRow: some View {
        HStack(spacing: 0) {
            dayStepButton(icon: "ph-caret-left", label: "Previous day", days: -1)

            Spacer(minLength: 8)

            if viewModel.isToday {
                Text("TODAY")
                    .font(AppFonts.labelFont(9))
                    .tracking(2.5)
                    .foregroundColor(AppColors.gold.opacity(0.6))
            } else {
                QuietGoldButton(
                    title: "Return to today",
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 10,
                    size: 10
                ) {
                    Task { await viewModel.goToToday() }
                }
            }

            Spacer(minLength: 8)

            dayStepButton(icon: "ph-caret-right", label: "Next day", days: 1)
        }
        .frame(maxWidth: .infinity)
    }

    private func dayStepButton(icon: String, label: String, days: Int) -> some View {
        Button {
            Task { await viewModel.step(by: days) }
        } label: {
            AppIcon(icon, size: 15)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Rail and Progress

    private var railBlock: some View {
        VStack(spacing: 0) {
            if !readerSections.isEmpty {
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

    private var sectionRail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(Array(readerSections.enumerated()), id: \.element.id) { index, section in
                        railItem(section, index: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: activeSectionIndex) { _, index in
                withAnimation(anim(0.3)) {
                    proxy.scrollTo(index, anchor: UnitPoint(x: 0.22, y: 0.5))
                }
            }
        }
    }

    private func railItem(_ section: MissalReaderSection, index: Int) -> some View {
        let isActive = index == activeSectionIndex
        let color: Color = isActive ? AppColors.gold : AppColors.textSecondary

        return Button {
            pendingJump = section.id
        } label: {
            VStack(spacing: 7) {
                Text(section.englishName.uppercased())
                    .font(AppFonts.labelFont(10.5))
                    .tracking(2)
                    .lineLimit(1)
                    .foregroundColor(color)

                Rectangle()
                    .fill(isActive ? AppColors.gold.opacity(0.85) : .clear)
                    .frame(height: 1)
            }
            .animation(anim(0.25), value: activeSectionIndex)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.englishName)
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
            // spacer gives that much back to keep the resting position
            // level with the full header's foot.
            Color.clear
                .frame(height: max(0, plateHeight - Self.jumpGap))
                .id(Self.topAnchorID)

            if viewModel.propers.count > 1 {
                celebrationPicker
                    .padding(.top, 4)
            }

            if let about = nonEmpty(viewModel.selectedProper?.info.description) {
                aboutDisclosure(about)
                    .padding(.top, 4)
            }

            let versalID = readerSections.first(where: \.isProper)?.id

            ForEach(Array(readerSections.enumerated()), id: \.element.id) { index, section in
                MissalReaderSectionView(
                    section: section,
                    size: readingSize,
                    language: settings.prayerLanguage,
                    layout: settings.missalLayout,
                    showsPosture: settings.missalPostureCues,
                    // The illuminated versal opens the day's own text —
                    // the Introit — not the Ordinary prayers before it.
                    showsDropCap: section.id == versalID
                )
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .named(Self.contentSpace)).minY
                } action: { minY in
                    handleSectionTop(index, minY)
                }
                .padding(.top, Self.jumpGap)
                .padding(.bottom, Self.sectionGap - Self.jumpGap)
                .id(section.id)
            }

            if !readerSections.isEmpty {
                colophon
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 90)
        .coordinateSpace(name: Self.contentSpace)
        // The whole content column carries the scroll marker: unlike a
        // marker view inside the lazy stack, it can never be released
        // mid-scroll, so the offset never goes stale.
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).minY
        } action: { minY in
            handleScrollOffset(minY)
        }
    }

    // MARK: - Celebration Picker

    /// A day carrying more than one Mass — Christmas — offers each.
    private var celebrationPicker: some View {
        Menu {
            ForEach(Array(viewModel.propers.enumerated()), id: \.element.id) { index, proper in
                Button {
                    viewModel.selectedIndex = index
                } label: {
                    if index == viewModel.selectedIndex {
                        Label(proper.info.title, systemImage: "checkmark")
                    } else {
                        Text(proper.info.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("\(viewModel.propers.count) Masses this day")
                    .font(AppFonts.labelFont(10))
                    .tracking(2)

                AppIcon("ph-caret-down", size: 9)
            }
            .foregroundColor(AppColors.gold.opacity(0.7))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    // MARK: - About

    /// The feast's explanation, behind a quiet disclosure so the propers
    /// stay one scroll away.
    private func aboutDisclosure(_ about: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAbout.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("ABOUT THIS DAY")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)

                    AppIcon(showAbout ? "ph-caret-up" : "ph-caret-down", size: 9)

                    Spacer()
                }
                .foregroundColor(AppColors.gold.opacity(0.7))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }

            if showAbout {
                ReadingText(
                    text: about,
                    size: max(14, readingSize - 2)
                )
            }
        }
    }

    // MARK: - Colophon

    private var colophon: some View {
        VStack(spacing: 14) {
            OrnamentDivider()
                .frame(width: 150)
                .padding(.top, 8)

            Text("ITE, MISSA EST")
                .font(AppFonts.labelFont(10))
                .tracking(3)
                .foregroundColor(AppColors.gold.opacity(0.5))

            QuietGoldButton(
                title: "The Order of Mass",
                leadingIcon: "ph-book-open",
                trailingIcon: "ph-caret-right",
                size: 10,
                color: AppColors.gold.opacity(0.7)
            ) {
                showOrdoPage = true
            }
            .padding(.top, 4)

            Text("Missale Romanum 1962 · texts served by Missale Meum")
                .font(AppFonts.bodyFont(11))
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - States

    private func errorState(_ error: String) -> some View {
        VStack(spacing: 14) {
            Text(error)
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
                Task { await viewModel.retry() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Mass texts for this day.")
                .font(AppFonts.italicFont(16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            QuietGoldButton(
                title: "Try again",
                leadingIcon: "ph-arrow-counter-clockwise",
                leadingIconSize: 11,
                size: 10,
                color: AppColors.gold
            ) {
                Task { await viewModel.retry() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func nonEmpty(_ string: String?) -> String? {
        guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// "TUESDAY · 25 AUGUST"
    private static let pillDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE '·' d MMMM"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DailyMissalView()
    }
    .environment(UserSettings.shared)
}
