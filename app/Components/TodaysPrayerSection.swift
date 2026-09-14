//
//  TodaysPrayerSection.swift
//  Lumen Viae
//
//  "Today's Prayer" — the day's three practices on the home page: the
//  Total Consecration, the Mass, the Divine Office. A section heading in
//  the home page's own voice, then the consecration — the user's own
//  devotion, whatever the day — and under it the feast heading the two
//  rows that keep it, the Mass and the Office. No card, no panel, no fill.
//
//  Named for the user's prayer rather than the Church's calendar,
//  because the Total Consecration is a private devotion and not a
//  liturgical observance — the third row would otherwise be filed under
//  a heading it does not belong to.
//
//  Every row carries the same three parts — the door's own glyph, its
//  name, and the row's own live fact — so the eye reads down the column
//  of facts: the day's silk, the hour it is (TERCE), the day of the
//  preparation. Each glyph is the one that door wears everywhere else in
//  the app. A plain line under each name once said what the row was;
//  the section read slower for it, and the names and facts already say it.
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

            // The preparation stands first, under the section's own name.
            // It is the user's own devotion, kept whatever day it is, and
            // being no part of the Church's calendar it stands apart from
            // the feast rather than under it.
            consecrationRow
                .padding(.top, 8)

            // Then the Church's day, a part of this section rather than a
            // section of its own: its feast named over a rule, and the
            // two liturgical books that keep it beneath
            feastLine
                .padding(.top, 14)

            liturgyRows
                .padding(.top, 2)
        }
        .animation(Motion.crossfade, value: today.title)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    /// The section's name set as the home page sets its others — "Sacred
    /// Mysteries", "Spiritual Reading" — with the date where they keep
    /// their link. It was a small tracked label under a larger feast, so
    /// the section's name read as a caption to the day.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today's Prayer")
                .font(AppFonts.headlineFont(19))
                .foregroundColor(AppColors.goldLight)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            // Abbreviated: the full weekday-and-month form was the
            // widest thing in the block and earned none of that width.
            Text(dateLine)
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    /// The day's feast, naming the part of the section the Mass and the
    /// Office belong to: small engraved capitals over a hairline that runs
    /// to the section's edge, the way a card names one of its parts.
    /// Set in the reading italic at 18 with air around it, it read as a
    /// second section title under "Today's Prayer" rather than a part of
    /// it. The day's class and colour are the Mass's facts, and stand
    /// beside the Mass row's silk.
    private var feastLine: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(today.title.uppercased())
                .font(AppFonts.labelFont(9.5))
                .tracking(2.2)
                .lineSpacing(3)
                .foregroundColor(AppColors.gold.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                // Crossfades in place as the day turns. Re-identified with
                // `.id`, the old and new names were laid out side by side
                // in this row for the length of the fade.
                .contentTransition(.opacity)

            Rectangle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(minWidth: 24)
                .frame(height: AppLine.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
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

    // MARK: - The rows

    /// The feast's two rows: the Church's public prayer of the day
    private var liturgyRows: some View {
        VStack(spacing: 0) {
            massRow

            rowDivider

            officeRow
        }
    }

    /// Inset so it starts at the text, not under the medallion
    private var rowDivider: some View {
        Rectangle()
            .fill(AppColors.gold.opacity(0.1))
            .frame(height: AppLine.hairline)
            .padding(.leading, 50)
            .accessibilityHidden(true)
    }

    // MARK: Row 1 — The Mass

    private var massRow: some View {
        LedgerRow(
            icon: "ch-altar",
            name: "The Mass",
            accessibility: ["The Mass, today's propers", massRank, today.vestment?.name]
                .compactMap { $0 }
                .joined(separator: ", ")
        ) {
            // The day's class and colour in words, beside its silk —
            // "II CLASS · RED" — set as the Office row sets its hour, so
            // the column of facts reads as one
            HStack(spacing: 10) {
                if let massFact {
                    Text(massFact)
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold.opacity(0.9))
                        .lineLimit(1)
                        .fixedSize()
                        .contentTransition(.opacity)
                }

                if let vestment = today.vestment {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(vestment.swatch)
                        .frame(width: 4, height: 24)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
            }
            .animation(Motion.crossfade, value: massFact)
        } action: {
            router.push(.missal)
        }
    }

    /// "II class", once the day's propers are known
    private var massRank: String? {
        today.proper?.info.rankLabel
    }

    /// "II CLASS · RED" — whichever of the two the day carries
    private var massFact: String? {
        let parts = [massRank, today.vestment?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ").uppercased()
    }

    // MARK: Row 2 — The Divine Office

    private var officeRow: some View {
        let hour = clock.hour

        return LedgerRow(
            icon: "ph-clock",
            name: "The Divine Office",
            accessibility: "The Divine Office, \(hour.label), the hour now"
        ) {
            // The hour itself, lit — "TERCE" says which hour it is, where
            // "NOW" only said that there was one.
            HStack(spacing: 8) {
                LitHourDot(size: 9, box: 16, glow: 4)

                Text(hour.label.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold.opacity(0.9))
                    .lineLimit(1)
                    .fixedSize()
            }
        } action: {
            router.push(.office)
        }
        .id(hour)
        .transition(.opacity)
        .animation(Motion.crossfade, value: hour)
    }

    // MARK: Row 3 — Total Consecration

    /// Nothing is greyed out and nothing is hidden. A user who has never
    /// begun sees an invitation in the same place, at the same weight —
    /// no "0 days", no empty progress track, nothing that reads as a
    /// reproach.
    private var consecrationRow: some View {
        let day = consecrationDay

        return LedgerRow(
            icon: "ch-consecration",
            name: "Total Consecration",
            accessibility: day.map { "Total Consecration, day \($0) of 33" }
                ?? "Total Consecration, thirty-three days to Our Lady"
        ) {
            if let day {
                VStack(alignment: .trailing, spacing: 6) {
                    Text("DAY \(day)")
                        .font(AppFonts.labelFont(11))
                        .tracking(1.5)
                        .foregroundColor(AppColors.goldLight)
                        .contentTransition(.numericText())

                    ProgressHair(fraction: Double(day) / 33)
                }
                .animation(Motion.crossfade, value: day)
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

/// One row of the ledger: medallion, name, the row's own live fact,
/// chevron. The same parts in the same places on every row, so the three
/// read as one ledger rather than three cards in a stack.
private struct LedgerRow<Fact: View>: View {

    let icon: String
    var iconSize: CGFloat = 17
    let name: String
    let accessibility: String

    @ViewBuilder let fact: Fact

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                medallion

                Text(name)
                    .font(AppFonts.headlineFont(16.5))
                    .foregroundColor(AppColors.cream)
                    .lineLimit(1)

                Spacer(minLength: 8)

                fact

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.5))
            }
            .padding(.vertical, 13)
            .frame(minHeight: 60)
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
            .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.35), lineWidth: AppLine.hairline))
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
