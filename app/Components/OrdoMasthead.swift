//
//  OrdoMasthead.swift
//  Lumen Viae
//
//  The day's leaf in an ordo — the Divine Office's page head, and the
//  shape any book stepped a day at a time would take. (The Daily Missal
//  once shared it and now carries its own collapsing chrome instead;
//  this stays the Office's, and stays general.) Unlike every other
//  header in the app on purpose: a full-bleed page head whose surface
//  runs up behind the navigation bar, so Back and the book's name stand
//  ON the leaf rather than floating over it. The day's vestment colour
//  runs as a band across the whole width, the date is a page-turning
//  strip under it, and the feast stands large on the leaf beneath —
//  colour, day, feast, in reading order.
//
//  The Office's engine names no colour, so its leaf is threaded in gold
//  instead: same silhouette, its own cloth.
//

import SwiftUI

struct OrdoMasthead<Feast: View>: View {

    let dateLabel: String
    let isToday: Bool

    /// The day's vestment colour. Nil — a book that doesn't know its
    /// colour — threads the head in gold instead.
    var band: Color? = nil

    let onStep: (Int) -> Void
    let onCalendar: () -> Void
    let onToday: () -> Void

    @ViewBuilder let feast: Feast

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                dateStrip
                    .padding(.horizontal, 10)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.14))
                    .frame(height: 0.5)
                    .padding(.horizontal, 24)

                feast
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity)
            .background(
                // The leaf's surface, carried up behind the navigation
                // bar so the bar's controls sit on it — one head, not
                // chrome floating over a card.
                AppColors.cardBackground
                    .padding(.top, -300)
            )
            .overlay(alignment: .bottom) {
                // The leaf closes on the day's own colour — the vestment
                // thread along its foot — or a gold thread where the
                // book names no colour. The colour lives on the leaf's
                // edge, not as a stripe between the bar and the page.
                LinearGradient(
                    stops: [
                        .init(color: threadColor.opacity(0.05), location: 0),
                        .init(color: threadColor.opacity(threadOpacity), location: 0.5),
                        .init(color: threadColor.opacity(0.05), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: band == nil ? 1 : 2)
            }

            if !isToday {
                QuietGoldButton(
                    title: "Return to today",
                    leadingIcon: "ph-arrow-counter-clockwise",
                    leadingIconSize: 10,
                    size: 10
                ) {
                    onToday()
                }
            }
        }
    }

    private var threadColor: Color {
        band ?? AppColors.gold
    }

    private var threadOpacity: Double {
        band == nil ? 0.45 : 0.75
    }

    // MARK: - Date strip

    /// Turning the leaf: yesterday and tomorrow at the edges, the date —
    /// a door to the calendar — in the middle.
    private var dateStrip: some View {
        HStack(spacing: 0) {
            stepButton(icon: "ph-caret-left", label: "Previous day", days: -1)

            Button(action: onCalendar) {
                HStack(spacing: 8) {
                    Text(dateLabel)
                        .font(AppFonts.headlineFont(19))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    AppIcon("ph-calendar-dots", size: 13)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .contentShape(Rectangle())
            }
            .buttonStyle(SacredCardButtonStyle())
            .accessibilityLabel("\(dateLabel). Open the calendar")

            stepButton(icon: "ph-caret-right", label: "Next day", days: 1)
        }
    }

    private func stepButton(icon: String, label: String, days: Int) -> some View {
        Button {
            onStep(days)
        } label: {
            AppIcon(icon, size: 16)
                .foregroundColor(AppColors.gold)
                .frame(width: 52, height: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.appGradient.ignoresSafeArea()

        VStack(spacing: 24) {
            OrdoMasthead(
                dateLabel: "Tuesday, August 25",
                isToday: true,
                band: Color(hex: "#b0524a"),
                onStep: { _ in }, onCalendar: {}, onToday: {}
            ) {
                VStack(spacing: 8) {
                    Text("FERIA III AFTER XIII SUNDAY AFTER PENTECOST")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.7))

                    Text("St. Louis IX")
                        .font(AppFonts.headlineFont(23))
                        .foregroundColor(AppColors.cream)

                    Text("III CLASS · RED")
                        .font(AppFonts.labelFont(10))
                        .tracking(2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            OrdoMasthead(
                dateLabel: "Tuesday, August 25",
                isToday: false,
                onStep: { _ in }, onCalendar: {}, onToday: {}
            ) {
                Text("S. Ludovici Regis Franciæ Confessoris")
                    .font(AppFonts.headlineFont(21))
                    .foregroundColor(AppColors.cream)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
    }
}
