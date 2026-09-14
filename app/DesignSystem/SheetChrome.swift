//
//  SheetChrome.swift
//  Lumen Viae
//
//  How a sheet is set, once. Every tray, index, and options sheet in the
//  app follows the consecration day's index, which read well where the
//  others did not:
//
//    - the system's drag indicator, never a hand-drawn grabber, over the
//      app's own gradient (`sheetGround()`)
//    - a header: a small gold kicker over the title in the display face,
//      with room above it for the indicator (`SheetHeader`)
//    - full-width ruled rows: glyph, name, an italic line, and at the
//      trailing edge a caret, a small tracked state (HERE, QUICK TAP), a
//      check, or the row's own control (`SheetRow`)
//    - the row that is current or chosen lit in gold light on a faint
//      wash of gold, and no filled card around the rows
//
//  A sheet that is something other than a list — a calendar, a writing
//  form, a page of reading — keeps its own body and takes the ground and
//  the header only.
//
//  Tappable rows are wrapped by their caller:
//  `Button { … } label: { SheetRow(…) }.buttonStyle(SacredCardButtonStyle())`.
//

import SwiftUI

// MARK: - Metrics

enum SheetMetrics {
    /// The sheet's side margin, for header and rows alike
    static let gutter: CGFloat = 24

    /// From the sheet's rim to the kicker, clear of the drag indicator.
    /// The trays once opened with their first line twelve points under
    /// the rim, pressed against a grabber drawn by hand.
    static let headerTop: CGFloat = 34

    static let headerBottom: CGFloat = 16

    /// A row's least height; the whole row is its tap target
    static let rowMinHeight: CGFloat = 52
}

// MARK: - Ground

extension View {
    /// The ground every sheet stands on: the page gradient, the system's
    /// drag indicator, and the background the sheet's rim is cut from
    /// (without it the system's white shows as a hairline at the rim).
    func sheetGround() -> some View {
        background(AppColors.appGradient.ignoresSafeArea())
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColors.background)
    }
}

// MARK: - Header

/// A sheet's heading: the kicker says where or when, the title says what.
struct SheetHeader<Trailing: View>: View {
    let kicker: String?
    let title: String
    let lead: String?
    let trailing: Trailing

    init(
        kicker: String? = nil,
        title: String,
        lead: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.kicker = kicker
        self.title = title
        self.lead = lead
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if let kicker {
                    Text(kicker.uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(2.5)
                        .foregroundColor(AppColors.gold)
                }

                Text(title)
                    .font(AppFonts.headlineFont(22))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let lead {
                    Text(lead)
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            trailing
                // `SheetHeaderAction` centres itself on the kicker's line;
                // with no kicker the first line is the title's, lower down
                .padding(.top, kicker == nil ? 7 : 0)
        }
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.top, SheetMetrics.headerTop)
        .padding(.bottom, SheetMetrics.headerBottom)
    }
}

extension SheetHeader where Trailing == EmptyView {
    init(kicker: String? = nil, title: String, lead: String? = nil) {
        self.init(kicker: kicker, title: title, lead: lead) { EmptyView() }
    }
}

/// A header's quiet act (DONE, CLOSE): small tracked gold type, level
/// with the kicker, answering to 44.
struct SheetHeaderAction: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.labelFont(10))
                .tracking(2)
                .foregroundColor(AppColors.gold)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        // Centred on the kicker's line rather than hanging below it
        .offset(y: -15)
        .accessibilityLabel(title)
    }
}

// MARK: - Rows

/// What stands at a row's trailing edge when it has no control of its own.
enum SheetRowAccessory: Equatable {
    case none
    /// A way on to somewhere
    case caret
    /// Chosen
    case check
    /// A small tracked state: HERE, QUICK TAP, PLAYING
    case label(String)
}

/// One ruled row of a sheet.
struct SheetRow<Trailing: View>: View {
    let title: String
    let detail: String?
    let icon: String?
    let isLit: Bool
    let showsDivider: Bool
    let detailLineLimit: Int?
    let trailing: Trailing

    init(
        _ title: String,
        detail: String? = nil,
        icon: String? = nil,
        isLit: Bool = false,
        showsDivider: Bool = true,
        detailLineLimit: Int? = 1,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.isLit = isLit
        self.showsDivider = showsDivider
        self.detailLineLimit = detailLineLimit
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            if let icon {
                AppIcon(icon, size: 16)
                    .foregroundColor(isLit ? AppColors.goldLight : AppColors.gold.opacity(0.6))
                    .frame(width: 22)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFonts.bodyFont(16))
                    .foregroundColor(isLit ? AppColors.goldLight : AppColors.cream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(AppFonts.italicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(detailLineLimit)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .padding(.horizontal, SheetMetrics.gutter)
        .padding(.vertical, 11)
        .frame(minHeight: SheetMetrics.rowMinHeight)
        .background(isLit ? AppColors.gold.opacity(0.07) : Color.clear)
        .overlay(alignment: .bottom) {
            if showsDivider {
                SheetRule()
            }
        }
        .contentShape(Rectangle())
    }
}

extension SheetRow where Trailing == SheetRowAccessoryView {
    init(
        _ title: String,
        detail: String? = nil,
        icon: String? = nil,
        accessory: SheetRowAccessory = .caret,
        isLit: Bool = false,
        showsDivider: Bool = true,
        detailLineLimit: Int? = 1
    ) {
        self.init(
            title,
            detail: detail,
            icon: icon,
            isLit: isLit,
            showsDivider: showsDivider,
            detailLineLimit: detailLineLimit
        ) {
            SheetRowAccessoryView(accessory: accessory)
        }
    }
}

/// The drawn form of a `SheetRowAccessory`
struct SheetRowAccessoryView: View {
    let accessory: SheetRowAccessory

    @ViewBuilder
    var body: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .caret:
            AppIcon("ph-caret-right", size: 10)
                .foregroundColor(AppColors.gold.opacity(0.4))
                .accessibilityHidden(true)
        case .check:
            AppIcon("ph-check", size: 13)
                .foregroundColor(AppColors.goldLight)
        case .label(let text):
            Text(text.uppercased())
                .font(AppFonts.labelFont(8))
                .tracking(1.5)
                .foregroundColor(AppColors.goldLight)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

// MARK: - Furniture

/// The hairline between rows, inset to the gutter
struct SheetRule: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.1))
            .frame(height: AppLine.hairline)
            .padding(.horizontal, SheetMetrics.gutter)
    }
}

/// A group's name inside a sheet: SPEED, TEXT SIZE, YOUR MARKS
struct SheetSectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.labelFont(9))
            .tracking(2.5)
            .foregroundColor(AppColors.gold.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

/// An italic line at a sheet's foot, or under a group, saying what the
/// choices above it do
struct SheetNote: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFonts.italicFont(13))
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SheetMetrics.gutter)
            .padding(.vertical, 14)
    }
}

// MARK: - Controls

/// A switch as a sheet's ruled row. The whole row is the control: a tap
/// anywhere on it, the words or the switch, flips the setting once.
///
/// The switch is drawn but takes no touches of its own. Left live inside
/// a row that also answered taps, a tap on the switch reached both the
/// switch and the row, and the setting flipped twice and stayed put.
struct SheetToggleRow: View {
    let title: String
    var detail: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool
    var tint: Color = AppColors.gold
    var showsDivider: Bool = true
    var detailLineLimit: Int? = nil

    var body: some View {
        Button {
            withAnimation(Motion.settle) { isOn.toggle() }
        } label: {
            SheetRow(
                title,
                detail: detail,
                icon: icon,
                showsDivider: showsDivider,
                detailLineLimit: detailLineLimit
            ) {
                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(tint)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(detail ?? "")
        .accessibilityAddTraits(.isToggle)
    }
}

/// A reading surface's size slider under its name: the same control on
/// every page that can be read larger, bound to whichever scale the sheet
/// owns.
struct SheetSizeSlider: View {

    var label: String = "Text size"
    @Binding var scale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetSectionLabel(label)

            HStack(spacing: 14) {
                Text("A")
                    .font(AppFonts.readingFont(13))
                    .foregroundColor(AppColors.textSecondary)

                Slider(value: $scale, in: 0...1)
                    .tint(AppColors.gold)
                    .accessibilityLabel("Text size")

                Text("A")
                    .font(AppFonts.readingFont(24))
                    .foregroundColor(AppColors.cream)
            }
            .padding(.horizontal, SheetMetrics.gutter)
        }
    }
}

// MARK: - Fitted detent

extension View {
    /// Opens the sheet exactly as tall as this content stands: measured,
    /// not counted. Apply it to a tray's content before its ground.
    ///
    /// The trays once added up a fixed header height and their rows by
    /// hand, and held every header to one line to keep the sum true, so
    /// a meditation's longer name was shrunk and then cut off. `estimate`
    /// stands only for the frame before the first measurement.
    func fittedSheetDetent(estimate: CGFloat) -> some View {
        modifier(FittedSheetDetent(estimate: estimate))
    }
}

private struct FittedSheetDetent: ViewModifier {
    let estimate: CGFloat

    @State private var measured: CGFloat?

    /// What the tray stands in: its own content, and the room beneath it
    /// the home indicator takes. The detent has to carry both, or the
    /// last row sits under the indicator and the tray opens short.
    ///
    /// Nonisolated because `onGeometryChange` measures off the main actor.
    private nonisolated struct Extent: Equatable {
        var content: CGFloat
        var bottomInset: CGFloat

        var total: CGFloat { content + bottomInset }
    }

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: Extent.self) { proxy in
                Extent(
                    content: proxy.size.height.rounded(.up),
                    bottomInset: proxy.safeAreaInsets.bottom
                )
            } action: { extent in
                // A height of nothing is a view not yet laid out, never a
                // tray asking to open at nothing tall
                guard extent.content > 0 else { return }
                measured = extent.total
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Never shorter than the counted estimate: measuring is here to
            // give a tray the room its own words need, and the arithmetic
            // it replaces was right about the common case
            .presentationDetents([.height(max(estimate, measured ?? estimate))])
    }
}
