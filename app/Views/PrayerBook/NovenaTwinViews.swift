//
//  NovenaTwinViews.swift
//  Lumen Viae
//
//  What a novena's twin carries on the pray-along page, one day at a time
//  (design option A, frames reports/design/prayer-format/frames/n-a-day.png
//  and n-a-how.png, on the dark page with no painting): the days as buttons with CLOSING after them, and a quiet row to pray it as a
//  novena, the app keeping the day.
//

import SwiftUI

/// The page of a twin shown: a day, or how each day goes with the prayer
/// said every day
enum NovenaTwinPage: Equatable, Hashable {
    case day(Int)
    case closing

    /// The day shown, nil on the closing page
    var day: Int? {
        if case .day(let n) = self { return n }
        return nil
    }
}

/// DAY OF THE NOVENA: a button for each day and CLOSING after them
struct NovenaDayButtons: View {
    let length: Int
    let hasClosing: Bool
    @Binding var page: NovenaTwinPage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                String(
                    localized: "DAY OF THE NOVENA",
                    comment: "Pray-along page, a novena read as text: the label over its day buttons")
            )
            .font(AppFonts.labelFont(10))
            .tracking(2.6)
            .foregroundColor(AppColors.gold)
            .accessibilityAddTraits(.isHeader)

            // One row across the measure, as drawn; at a larger text size
            // that will not fit, the same row scrolls
            ViewThatFits(in: .horizontal) {
                buttons(filling: true)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        buttons(filling: false)
                    }
                    // The trailing edge fades, so the row reads as more
                    .mask(
                        LinearGradient(
                            stops: [.init(color: .black, location: 0.85), .init(color: .clear, location: 1)],
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .onAppear { proxy.scrollTo(page, anchor: .center) }
                }
            }
        }
    }

    private func buttons(filling: Bool) -> some View {
        HStack(spacing: filling ? 4 : 8) {
            ForEach(1...max(length, 1), id: \.self) { day in
                chip(lit: page == .day(day), filling: filling, inset: 12) {
                    Text(verbatim: "\(day)")
                        .font(AppFonts.bodyFont(17))
                } action: {
                    page = .day(day)
                }
                .accessibilityLabel(
                    String(
                        localized: "Day \(day)",
                        comment: "Pray-along page, a novena's day button, to VoiceOver")
                )
                .id(NovenaTwinPage.day(day))
            }
            if hasClosing {
                chip(lit: page == .closing, filling: false, inset: filling ? 8 : 12) {
                    Text(
                        String(
                            localized: "CLOSING",
                            comment:
                                "Pray-along page, a novena read as text: the button after its days, showing how each day goes and the prayer said every day"
                        )
                    )
                    .font(AppFonts.labelFont(10))
                    .tracking(1.4)
                    .lineLimit(1)
                    .fixedSize()
                } action: {
                    page = .closing
                }
                // Its word whole; the days share what is left
                .layoutPriority(1)
                .id(NovenaTwinPage.closing)
            }
        }
    }

    /// A day fills its share of the row (never under 24 points across,
    /// and 44 tall); CLOSING keeps its word's width
    private func chip<Label: View>(
        lit: Bool, filling: Bool, inset: CGFloat, @ViewBuilder label: () -> Label, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            label()
                .foregroundColor(lit ? AppColors.background : AppColors.cream)
                .padding(.horizontal, filling ? 0 : inset)
                .frame(minWidth: filling ? 24 : 44, idealWidth: filling ? 26 : nil, maxWidth: filling ? .infinity : nil)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(lit ? AppColors.gold : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.textSecondary.opacity(lit ? 0 : 0.3), lineWidth: AppLine.hairline)
                )
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityAddTraits(lit ? .isSelected : [])
    }
}

/// PRAY IT AS A NOVENA: the quiet way to the novena itself
struct PrayAsNovenaRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        String(
                            localized: "PRAY IT AS A NOVENA",
                            comment:
                                "Pray-along page, a novena read as text: the row leading to the novena prayed day by day"
                        )
                    )
                    .font(AppFonts.labelFont(11))
                    .tracking(2.4)
                    .foregroundColor(AppColors.gold)
                    Text(
                        String(
                            localized: "Nine days with the Rosary; the app keeps your day",
                            comment: "Pray-along page, a novena read as text: the line under PRAY IT AS A NOVENA")
                    )
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                AppIcon("ph-caret-right", size: 14)
                    .foregroundColor(AppColors.gold)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColors.gold.opacity(0.45), lineWidth: AppLine.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
    }
}
