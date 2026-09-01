//
//  TodaysPrayerSection.swift
//  Lumen Viae
//
//  "Today's Prayer" — the day's three practices given equal standing on
//  the home page: the Mass, the Divine Office, the Total Consecration.
//  A header line, the feast, then three ruled rows standing directly on
//  the page. No card, no panel, no fill.
//
//  Named for the user's prayer rather than the Church's calendar,
//  because the Total Consecration is a private devotion and not a
//  liturgical observance — the third row would otherwise be filed under
//  a heading it does not belong to.
//
//  Every row carries the same four parts — a mark, a name, one plain
//  line saying what it is, and the row's own live fact — so the eye
//  reads down the column of facts rather than across three different
//  shapes: the day's silk, the hour that is passing, the day of the
//  preparation.
//

import SwiftUI
import SwiftData

// MARK: - TodaysPrayerSection

struct TodaysPrayerSection: View {

    let today: TodayInChurch

    @Environment(AppRouter.self) private var router

    /// The hour, kept by the clock rather than read off `Date()` in this
    /// body — the row must roll over at noon whether or not anything
    /// else on the page happens to redraw.
    private var clock = CanonicalClock.shared

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    init(today: TodayInChurch) {
        self.today = today
    }

    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    /// Day 1–33 of the preparation. The record runs to 34 — the day of
    /// consecration itself — but the counter names the preparation, and
    /// "DAY 34 of 33" is not a thing a ledger says.
    private var consecrationDay: Int? {
        activeConsecration.map { min($0.currentDayNumber, 33) }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            rows
                .padding(.top, 18)
        }
        .animation(.easeOut(duration: 0.35), value: today.title)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("TODAY'S PRAYER")
                    .font(AppFonts.labelFont(10))
                    .tracking(2.6)
                    .foregroundColor(AppColors.gold.opacity(0.78))

                Spacer()

                // Abbreviated: the full weekday-and-month form was the
                // widest thing in the block and earned none of that width.
                Text(dateLine)
                    .font(AppFonts.labelFont(9.5))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(today.title)
                .font(AppFonts.headlineFont(23))
                .lineSpacing(23 * 0.2)
                .foregroundColor(AppColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
                .id(today.title)
                .transition(.opacity)

            if let meta = today.meta {
                HStack(spacing: 8) {
                    vestmentDot

                    Text(meta)
                        .font(AppFonts.italicFont(14))
                        .foregroundColor(AppColors.accentSoft)
                }
                .padding(.top, 2)
                .transition(.opacity)
            }
        }
    }

    /// The day's liturgical colour. The same swatch the missal's
    /// calendar marks a day with, and the same the Mass row wears as its
    /// silk two lines below.
    @ViewBuilder
    private var vestmentDot: some View {
        if let vestment = today.vestment {
            Circle()
                .fill(vestment.swatch)
                .frame(width: 7, height: 7)
                .shadow(color: vestment.swatch.opacity(0.45), radius: 1.5)
                .accessibilityHidden(true)
        }
    }

    /// "MON 31 AUG". A fixed pattern rather than a localized one: the
    /// locale's own short form puts the month first and hangs a comma
    /// off the weekday, and this line is set as engraved caps beside a
    /// tracked label, where a comma reads as grit.
    private var dateLine: String {
        Self.dateFormatter.string(from: .now).uppercased()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()

    // MARK: - The three rows

    private var rows: some View {
        VStack(spacing: 0) {
            massRow

            rowDivider

            officeRow

            rowDivider

            consecrationRow
        }
    }

    /// Inset so it starts at the text, not under the medallion
    private var rowDivider: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.1))
            .frame(height: 0.5)
            .padding(.leading, 50)
            .accessibilityHidden(true)
    }

    // MARK: Row 1 — The Mass

    private var massRow: some View {
        LedgerRow(
            icon: "lv-chalice",
            iconSize: 17,
            name: "The Mass",
            subline: "Today's propers, Latin and English",
            accessibility: today.vestment.map { "The Mass, today's propers, \($0.name)" }
                ?? "The Mass, today's propers"
        ) {
            // The day's silk, standing where the other rows keep their
            // own fact
            if let vestment = today.vestment {
                RoundedRectangle(cornerRadius: 1)
                    .fill(vestment.swatch)
                    .frame(width: 4, height: 24)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
        } action: {
            router.push(.missal)
        }
    }

    // MARK: Row 2 — The Divine Office

    private var officeRow: some View {
        let hour = clock.hour

        return LedgerRow(
            icon: "lv-breviary",
            iconSize: 17,
            name: "The Divine Office",
            // Names the hour and says what part of day it is, so the row
            // answers "which hour is it now?" without opening anything.
            subline: hour.namedDayPart,
            accessibility: "The Divine Office, \(hour.label), the hour now"
        ) {
            HStack(spacing: 8) {
                LitHourDot(size: 9, box: 16, glow: 4)

                Text("NOW")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.9))
            }
        } action: {
            router.push(.office)
        }
        .id(hour)
        .transition(.opacity)
        .animation(.easeOut(duration: 0.4), value: hour)
    }

    // MARK: Row 3 — Total Consecration

    /// Nothing is greyed out and nothing is hidden. A user who has never
    /// begun sees an invitation in the same place, at the same weight —
    /// no "0 days", no empty progress track, nothing that reads as a
    /// reproach.
    private var consecrationRow: some View {
        let day = consecrationDay

        return LedgerRow(
            icon: "ph-crown",
            iconSize: 16,
            name: "Total Consecration",
            subline: day == nil
                ? "Thirty-three days to Our Lady"
                : "Montfort's thirty-three days",
            accessibility: day.map { "Total Consecration, day \($0) of 33" }
                ?? "Total Consecration, thirty-three days to Our Lady"
        ) {
            if let day {
                VStack(alignment: .trailing, spacing: 6) {
                    Text("DAY \(day)")
                        .font(AppFonts.labelFont(11))
                        .tracking(1.5)
                        .foregroundColor(AppColors.goldLight)

                    ProgressHair(fraction: Double(day) / 33)
                }
            } else {
                Text("BEGIN")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.9))
            }
        } action: {
            // The tab knows both states: mid-preparation it opens the
            // day, and otherwise it opens the invitation to begin.
            router.selectedTab = .consecration
        }
    }
}

// MARK: - LedgerRow

/// One row of the ledger: medallion, name, one plain line, the row's own
/// live fact, chevron. Four parts in the same places on every row, so
/// the three read as one ledger rather than three cards in a stack.
private struct LedgerRow<Fact: View>: View {

    let icon: String
    var iconSize: CGFloat = 17
    let name: String
    let subline: String
    let accessibility: String

    @ViewBuilder let fact: Fact

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                medallion

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(AppFonts.headlineFont(16.5))
                        .foregroundColor(AppColors.cream)

                    Text(subline)
                        .font(AppFonts.bodyFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                fact

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.vertical, 15)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(accessibility)
    }

    private var medallion: some View {
        AppIcon(icon, size: iconSize)
            .foregroundColor(AppColors.gold)
            .frame(width: 34, height: 34)
            .background(Circle().fill(AppColors.gold.opacity(0.05)))
            .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: 0.5))
            .accessibilityHidden(true)
    }
}

// MARK: - LitHourDot

/// The mark that says "this hour, now": the lit disc inside a gold ring.
/// The same object on the home ledger and in the arch's crown, at the
/// two sizes each needs.
struct LitHourDot: View {

    var size: CGFloat = 9
    var box: CGFloat = 16
    var glow: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .fill(LitHourMark.disc)
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(AppColors.goldLight, lineWidth: 1)
        }
        .frame(width: box, height: box)
        .shadow(color: AppColors.gold.opacity(0.5), radius: glow / 2)
        .accessibilityHidden(true)
    }
}

// MARK: - ProgressHair

/// The preparation's progress as a hairline, never a percentage.
private struct ProgressHair: View {

    let fraction: Double

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(AppColors.gold.opacity(0.16))

            Capsule()
                .fill(AppColors.gold)
                .frame(width: 46 * min(max(fraction, 0), 1))
        }
        .frame(width: 46, height: 1.5)
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.appGradient.ignoresSafeArea()

        TodaysPrayerSection(today: TodayInChurch())
            .environment(AppRouter())
            .padding(.horizontal, 20)
    }
    .modelContainer(for: ConsecrationProgress.self, inMemory: true)
}
