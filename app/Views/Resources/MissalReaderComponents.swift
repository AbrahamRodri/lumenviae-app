//
//  MissalReaderComponents.swift
//  Lumen Viae
//
//  The Daily Missal reader's pieces: one section of the Mass — posture
//  cue, tiered heading, passages — and the two sheets the header's
//  buttons raise: Reading (the Aa settings) and Ordo Missæ (the
//  jump-to-section index). All of it draws through the shared missal
//  passage views, so the text itself is set the same way everywhere.
//

import SwiftUI

// MARK: - MissalReaderSectionView

/// One section of the day's Mass. The propers' gold diamond is the one
/// mark that sets them apart from the Ordinary — both read at full
/// strength.
struct MissalReaderSectionView: View {

    let section: MissalReaderSection
    let size: CGFloat
    let language: PrayerLanguage
    let layout: MissalLayout
    let showsPosture: Bool

    /// The illuminated versal belongs to the first section only
    let showsDropCap: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsPosture, let posture = section.posture {
                postureCue(posture)
                    .padding(.bottom, 18)
            }

            heading
                .padding(.bottom, 16)

            passages
        }
    }

    // MARK: - Posture Cue

    private func postureCue(_ posture: MissalPosture) -> some View {
        HStack(spacing: 10) {
            fadingRule(leading: true)

            Text(posture.rawValue.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(3)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize()

            fadingRule(leading: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(posture.rawValue)
    }

    private func fadingRule(leading: Bool) -> some View {
        LinearGradient(
            colors: leading
                ? [AppColors.gold.opacity(0), AppColors.gold.opacity(0.22)]
                : [AppColors.gold.opacity(0.22), AppColors.gold.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }

    // MARK: - Heading

    /// A diamond stud (propers only), the Latin name, and the English
    /// name a step smaller beside it — one wrapping line.
    private var heading: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            if section.isProper {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.85))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            headingText
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var showsBothNames: Bool {
        !section.englishName.isEmpty
            && section.latinName.caseInsensitiveCompare(section.englishName) != .orderedSame
    }

    private var headingText: Text {
        let latin = Text(section.latinName.uppercased())
            .font(AppFonts.headlineFont(12))
            .tracking(2.5)
            .foregroundColor(AppColors.gold)

        guard showsBothNames else { return latin }

        let english = Text(section.englishName.uppercased())
            .font(AppFonts.labelFont(10))
            .tracking(2)
            .foregroundColor(AppColors.gold.opacity(0.42))

        return latin + Text("  ") + english
    }

    // MARK: - Passages

    private var passages: some View {
        let body = section.section.body

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(body.enumerated()), id: \.offset) { index, pair in
                MissalPassage(
                    pair: pair,
                    size: size,
                    language: language,
                    layout: layout,
                    showsDropCap: showsDropCap && index == 0 && dropCapAllowed
                )
                .padding(.bottom, spacingBelow(pair, index: index, count: body.count))
            }
        }
    }

    /// The versal is suppressed in columns — half a page is too narrow
    /// a measure for a floated initial.
    private var dropCapAllowed: Bool {
        !(language.isBilingual && layout == .sideBySide)
    }

    /// A versicle-and-response pair reads as one exchange: a passage
    /// opening on a ℣/℟/✠ mark keeps its response close.
    private func spacingBelow(_ pair: [String], index: Int, count: Int) -> CGFloat {
        guard index < count - 1 else { return 0 }
        return hasLeadingMark(pair) ? 9 : 16
    }

    private func hasLeadingMark(_ pair: [String]) -> Bool {
        let text = pair.count > 1 ? pair[1] : (pair.first ?? "")
        guard let first = text.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return false
        }
        return first == "℣" || first == "℟" || first == "☩" || first == "✠"
    }
}

// MARK: - MissalSheetShell

/// The shared shell of the missal's and the breviary's bottom sheets,
/// set in the app's one sheet grammar (`SheetChrome`): the system's
/// indicator over the page gradient, a kicker and title, then whatever
/// the sheet holds. An empty title leaves the head to the sheet itself —
/// the calendars set a month stepper there instead.
///
/// The shell draws no side margin. Ruled rows run edge to edge so the
/// lit row's wash does, and carry the gutter themselves; anything else
/// the sheet holds pads itself to `SheetMetrics.gutter`.
struct MissalSheetShell<Content: View>: View {

    let kicker: String?
    let title: String
    let content: () -> Content

    init(
        kicker: String? = nil,
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.kicker = kicker
        self.title = title
        self.content = content
    }

    /// A sheet that draws its own head needs only the indicator's
    /// clearance: the calendars' chevrons carry their own 44pt of air.
    private static var bareHeadTop: CGFloat { 24 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if title.isEmpty {
                Color.clear
                    .frame(height: Self.bareHeadTop)
            } else {
                SheetHeader(kicker: kicker, title: title)
            }

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheetGround()
    }
}

// MARK: - MissalSheetChip

/// One option in a sheet's chip row — equal-width pills, the selected
/// one lit in gold.
struct MissalSheetChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(isSelected ? AppColors.gold : AppColors.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(isSelected ? AppColors.gold.opacity(0.1) : Color.clear))
                .overlay(Capsule().strokeBorder(
                    AppColors.gold.opacity(isSelected ? 0.5 : 0.16),
                    lineWidth: AppLine.hairline
                ))
                .contentShape(Capsule())
                .animation(.timingCurve(0, 0, 0.58, 1, duration: 0.18), value: isSelected)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - MissalSheetChipGroup

/// One choice in an Aa sheet: its name, then its chips in a row on the
/// gutter. The missal's sheet and the breviary's each drew their own
/// copy of this; a setting both books share is offered one way.
struct MissalSheetChipGroup<Chips: View>: View {

    let label: String
    let chips: () -> Chips

    init(_ label: String, @ViewBuilder chips: @escaping () -> Chips) {
        self.label = label
        self.chips = chips
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetSectionLabel(label)

            HStack(spacing: 8) {
                chips()
            }
            .padding(.horizontal, SheetMetrics.gutter)
        }
    }
}

// MARK: - MissalProperDiamond

/// The propers' diamond stud, as the index and its legend draw it: the
/// one mark that sets a proper apart from the Ordinary.
private struct MissalProperDiamond: View {

    var isLit = false

    var body: some View {
        Rectangle()
            .fill(isLit ? AppColors.goldLight : AppColors.gold.opacity(0.85))
            .frame(width: 5, height: 5)
            .rotationEffect(.degrees(45))
            .accessibilityHidden(true)
    }
}

// MARK: - MissalReadingSheet

/// The Aa sheet: language, bilingual layout, contents, text size, and
/// the posture-cue toggle. Every choice writes straight to settings, so
/// the page behind resets as the chips are struck.
struct MissalReadingSheet: View {

    @Environment(UserSettings.self) private var settings

    /// The bilingual order restored when "Both" is re-chosen, owned by
    /// the missal screen so a Latin detour never loses it.
    @Binding var preferredBilingual: PrayerLanguage

    var body: some View {
        @Bindable var settings = settings

        return MissalSheetShell(kicker: "Daily Missal", title: "Reading") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    MissalSheetChipGroup("Language") {
                        MissalSheetChip(
                            title: "Latin",
                            isSelected: settings.prayerLanguage == .latin
                        ) { choose(.latin) }

                        MissalSheetChip(
                            title: "English",
                            isSelected: settings.prayerLanguage == .english
                        ) { choose(.english) }

                        MissalSheetChip(
                            title: "Both",
                            isSelected: settings.prayerLanguage.isBilingual
                        ) { chooseBoth() }
                    }

                    MissalSheetChipGroup("Latin and English") {
                        MissalSheetChip(
                            title: "Stacked",
                            isSelected: settings.missalLayout == .interlinear
                        ) {
                            settings.missalLayoutPreference = MissalLayout.interlinear.rawValue
                        }

                        MissalSheetChip(
                            title: "Side by side",
                            isSelected: settings.missalLayout == .sideBySide
                        ) { chooseSideBySide() }
                    }

                    MissalSheetChipGroup("Contents") {
                        MissalSheetChip(
                            title: "Propers only",
                            isSelected: settings.missalScope == .propersOnly
                        ) {
                            settings.missalScopeRaw = MissalScope.propersOnly.rawValue
                        }

                        MissalSheetChip(
                            title: "With the Ordinary",
                            isSelected: settings.missalScope == .full
                        ) {
                            settings.missalScopeRaw = MissalScope.full.rawValue
                        }
                    }

                    SheetSizeSlider(scale: $settings.missalTextScale)

                    // The two switches stand as a ruled ledger beneath the
                    // controls, each saying what it does to the page
                    SheetRule()
                        .padding(.top, 22)

                    toggleRow(
                        title: "Posture cues",
                        detail: "Stand, kneel and sit, marked in the text",
                        isOn: $settings.missalPostureCues
                    )

                    toggleRow(
                        title: "High Mass",
                        detail: "The sung Mass — Asperges and incensing; the Leonine prayers follow Low Mass",
                        isOn: $settings.missalHighMass
                    )
                }
                .padding(.bottom, 36)
            }
        }
    }

    // MARK: - Choices

    private func choose(_ language: PrayerLanguage) {
        if settings.prayerLanguage.isBilingual {
            preferredBilingual = settings.prayerLanguage
        }
        settings.prayerLanguagePreference = language.rawValue
    }

    private func chooseBoth() {
        settings.prayerLanguagePreference = preferredBilingual.rawValue
    }

    /// Two columns need two languages: side by side forces Both.
    private func chooseSideBySide() {
        settings.missalLayoutPreference = MissalLayout.sideBySide.rawValue
        if !settings.prayerLanguage.isBilingual {
            settings.prayerLanguagePreference = preferredBilingual.rawValue
        }
    }

    // MARK: - Pieces

    /// A switch in the sheet's row grammar: the setting's name, what it
    /// does to the page in full (never cut to a line), and the switch at
    /// the trailing edge.
    private func toggleRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        SheetToggleRow(
            title: title,
            detail: detail,
            isOn: isOn,
            tint: AppColors.gold.opacity(0.55)
        )
    }
}

// MARK: - MissalIndexSheet

/// The ☰ sheet: every visible section as a ruled ledger — the active
/// one lit and marked HERE, propers with their diamond — a tap jumps
/// the page there and puts the sheet away.
struct MissalIndexSheet: View {

    @Environment(\.dismiss) private var dismiss

    let sections: [MissalReaderSection]
    let activeIndex: Int
    let onJump: (String) -> Void

    var body: some View {
        MissalSheetShell(kicker: "Daily Missal", title: "Ordo Missæ") {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        row(section, index: index)
                    }

                    legend
                }
                .padding(.bottom, 36)
            }
        }
    }

    private func row(_ section: MissalReaderSection, index: Int) -> some View {
        let isActive = index == activeIndex

        return Button {
            onJump(section.id)
            dismiss()
        } label: {
            MissalIndexRow(section: section, isActive: isActive)
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    /// The legend keeps its diamond in the rows' mark column, so the mark
    /// it explains stands where the marks above it do, and its words
    /// under the rows' names.
    private var legend: some View {
        SheetNote("Marked parts are proper to today; the rest is the Ordinary.")
            .padding(.leading, MissalIndexRow.nameInset)
            .overlay(alignment: .topLeading) {
                MissalProperDiamond()
                    .frame(width: MissalIndexRow.markColumn, height: 18)
                    .padding(.leading, SheetMetrics.gutter)
                    .padding(.top, 14)
            }
    }
}

// MARK: - MissalIndexRow

/// One row of the Ordo's index, in `SheetRow`'s measure — gutter, mark
/// column, name over an italic line, the lit wash, the rule — built here
/// because its leading mark is the propers' diamond, which is the
/// missal's own mark and not a glyph `SheetRow` can take by name. The
/// row being read says HERE; every other row keeps its posture as a
/// quiet state at the trailing edge.
private struct MissalIndexRow: View {

    let section: MissalReaderSection
    let isActive: Bool

    /// SheetRow's glyph column and the space after it
    static let markColumn: CGFloat = 22
    static let markSpacing: CGFloat = 14

    /// How far past the gutter a row's name begins
    static var nameInset: CGFloat { markColumn + markSpacing }

    private var showsBothNames: Bool {
        !section.englishName.isEmpty
            && section.latinName.caseInsensitiveCompare(section.englishName) != .orderedSame
    }

    var body: some View {
        HStack(spacing: Self.markSpacing) {
            ZStack {
                if section.isProper {
                    MissalProperDiamond(isLit: isActive)
                }
            }
            .frame(width: Self.markColumn)

            VStack(alignment: .leading, spacing: 3) {
                Text(section.latinName)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(isActive ? AppColors.goldLight : AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if showsBothNames {
                    Text(section.englishName)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isActive {
                SheetRowAccessoryView(accessory: .label("Here"))
            } else if let posture = section.posture {
                Text(posture.rawValue.uppercased())
                    .font(AppFonts.labelFont(8))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.42))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.vertical, 11)
        .frame(minHeight: SheetMetrics.rowMinHeight)
        .background(isActive ? AppColors.gold.opacity(0.07) : Color.clear)
        .overlay(alignment: .bottom) {
            SheetRule()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Collapsing Plate

/// How far a reader's text has risen past the foot of its header. It
/// lives in its own observable, not the reader's `@State`, so that the
/// plate — the one view that reads it — is the one view drawn again on
/// every frame of a scroll, and the Mass beneath it is not.
@Observable
final class ReaderScrollOffset {
    var pastTop: CGFloat = 0
}

/// How much of a collapsing plate's top edge dissolves as it passes
/// under the chrome. At file scope because a generic type can hold no
/// static stored property of its own.
private let readerPlateEdgeFade: CGFloat = 14

/// The missal's and the Office's header plate, collapsed by the scroll
/// itself. The plate's height is taken point for point from how far the
/// text has risen, so the rail beneath it rides on the first line of
/// the reading and the two travel as one surface until the plate is
/// gone. It is cut from the top, the way a page passes under a bar, and
/// dissolves as it goes.
///
/// It once collapsed on its own clock: an animation set off when the
/// scroll crossed a threshold. Until then the text slid under a plate
/// that stood still, and after it the rail leapt a plate's height while
/// the plate's words hung behind it fading — the header answered the
/// finger a beat late in both directions. Direct manipulation, so it
/// stays under Reduce Motion.
struct CollapsingReaderPlate<Content: View>: View {

    let offset: ReaderScrollOffset

    /// The plate's natural height, measured here and kept by the reader,
    /// whose content column leaves the same room at its head
    @Binding var naturalHeight: CGFloat

    @ViewBuilder let content: Content

    var body: some View {
        let risen: CGFloat = min(max(offset.pastTop, 0), naturalHeight)
        let progress: Double = naturalHeight > 0 ? Double(risen / naturalHeight) : 0

        content
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                naturalHeight = height
            }
            .opacity(1 - min(1, progress * 1.25))
            .frame(height: naturalHeight - risen, alignment: .bottom)
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: min(readerPlateEdgeFade, risen))
                    Color.black
                }
            }
            .allowsHitTesting(progress < 0.5)
    }
}
