//
//  TodaysPrayerSection.swift
//  Lumen Viae
//
//  "Today's Prayer" — the day's four rows on the home page: the
//  Consecration to Mary, the hour's prayers, the Mass, the Hours of
//  Prayer. A section heading in the home page's own voice, then the
//  four as a list of routines (the "routine list" design, option B,
//  Oct 2026): each row a painting, its name, one line saying what today
//  holds, and the row's own live fact in small capitals beneath.
//
//  Named for the user's prayer rather than the Church's calendar,
//  because the consecration is a private devotion and not a liturgical
//  observance. The consecration and the hour's prayers stand first, as
//  the user's own; the Mass and the Office follow, and the feast they
//  keep is named in the Mass row's line rather than over them.
//
//  The fact is where a routine app puts a duration. This app never
//  estimates one, so the slot says what is true now: DAY 12 OF 33, ON
//  WAKING, LESSER FEAST · WHITE, NOW · UNTIL NOON. A check rides on the
//  painting only where the app knows the prayer was prayed — today's
//  day of the consecration and the hour's order. The Mass and the
//  Office are never marked: the app cannot see them prayed. No state
//  here shames anyone: no "0 days", no "missed".
//

import SwiftData
import SwiftUI

// MARK: - TodaysPrayerSection

struct TodaysPrayerSection: View {

    let today: TodayInChurch

    @Environment(AppRouter.self) private var router

    /// The hour, kept by the clock rather than read off `Date()` in this
    /// body — the row must roll over at noon whether or not anything
    /// else on the page happens to redraw.
    private var clock = CanonicalClock.shared

    /// Where the hour's order is marked prayed
    private let store: PrayerBookStore

    /// A fixed moment for snapshots and previews; the clock otherwise
    private let fixedNow: Date?

    @Query(sort: \ConsecrationProgress.createdAt, order: .reverse)
    private var consecrations: [ConsecrationProgress]

    init(today: TodayInChurch, store: PrayerBookStore = .shared, now: Date? = nil) {
        self.today = today
        self.store = store
        self.fixedNow = now
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(spacing: 4) {
                let now = fixedNow ?? .now
                let shown = TodaysPrayerRow.shownConsecration(among: consecrations, at: now)
                TodaysPrayerRowView(row: .consecration(shown, now: now)) {
                    // The tab knows every state: mid-preparation it opens
                    // the day, chosen ahead the page that waits for Day 1,
                    // and otherwise the invitation to begin.
                    router.selectedTab = .consecration
                }

                hourRow

                TodaysPrayerRowView(row: .mass(today)) {
                    router.push(.missal)
                }
                .animation(Motion.crossfade, value: today.title)

                officeRow
            }
            .padding(.top, 10)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    /// The section's name set as the home page sets its others — "Rosary
    /// Mysteries", "Spiritual Reading" — with the date where they keep
    /// their link.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today's Prayer")
                .font(AppFonts.headlineFont(19))
                .foregroundColor(AppColors.goldLight)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Text(Self.dateLine(fixedNow ?? .now))
                .font(AppFonts.labelFont(9.5))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    /// "TUE 13 OCT". A fixed pattern rather than a localized one: the
    /// locale's own short form puts the month first and hangs a comma
    /// off the weekday, and this line is set as engraved caps.
    private static func dateLine(_ date: Date) -> String {
        dateFormatter.string(from: date).uppercased()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()

    // MARK: - The hour's prayers

    /// The Prayer Book's order for the hour it is — Morning Prayers, the
    /// Angelus, Night Prayers. Redrawn when the book's hour turns, which
    /// is never when the Office's does: on the canonical clock alone the
    /// row kept the Angelus from eight until midnight.
    private var hourRow: some View {
        TimelineView(PrayerBookHourSchedule()) { context in
            TodaysPrayerRowView(row: .hourOrder(at: fixedNow ?? context.date, store: store)) {
                router.push(.prayerBook)
            }
        }
    }

    // MARK: - The Hours of Prayer

    private var officeRow: some View {
        let hour = fixedNow.map { CanonicalHour.present(atClockHour: Calendar.current.component(.hour, from: $0)) }
            ?? clock.hour

        // The row's words crossfade in place as the hour turns
        return TodaysPrayerRowView(row: .office(hour)) {
            router.push(.office)
        }
    }
}

// MARK: - TodaysPrayerRow

/// What one row says: its painting, name, line and fact, whether it was
/// prayed, and all of it as VoiceOver hears it. Built from the app's own
/// state by the four builders below, so each row's words live in one place.
struct TodaysPrayerRow: Equatable {

    /// What stands before the fact
    enum Mark: Equatable {
        case none
        /// The day's silk, in the vestment's colour
        case silk(MissalVestment)
        /// The lit dot of the hour it is now
        case litHour
    }

    let painting: String
    let focal: UnitPoint
    let name: String
    let subtitle: String
    /// Nil while the row has nothing true to say yet (the Mass before
    /// the day's propers arrive); the line keeps its height regardless
    let fact: String?
    var mark: Mark = .none
    var isPrayed = false
    let spoken: String

    // MARK: Consecration to Mary

    /// The record the row shows: the preparation under way, or one made
    /// today, so completing it on the day of consecration does not turn
    /// the row back to BEGIN. One made on an earlier day is done, and the
    /// row invites a new one.
    static func shownConsecration(among records: [ConsecrationProgress], at now: Date) -> ConsecrationProgress? {
        records.first { !$0.isCompleted }
            ?? records.first { progress in
                progress.completedAt.map { Calendar.current.isDate($0, inSameDayAs: now) } ?? false
            }
    }

    /// The preparation's painting while it is under way is its period's
    /// own, the one its day page opens on; before it, and once it is
    /// made, the Coronation.
    static func consecration(_ progress: ConsecrationProgress?, now: Date = Date()) -> TodaysPrayerRow {
        let name = "Consecration to Mary"
        let invitation = "Give yourself to Jesus through Mary"
        let coronation = ConsecrationPhase.consecrationDay.heroImageName
        let coronationFocal = UnitPoint(x: 0.5, y: 0.12)
        let consecrationTitle = ConsecrationData.day(34)?.title ?? "Total Consecration"

        guard let progress else {
            return TodaysPrayerRow(
                painting: coronation,
                focal: coronationFocal,
                name: name,
                subtitle: invitation,
                fact: "BEGIN",
                spoken: "\(name). \(invitation), a 33-day preparation. Begin."
            )
        }

        // Made today: the row keeps its place and its seal for the day
        if progress.isCompleted {
            return TodaysPrayerRow(
                painting: coronation,
                focal: coronationFocal,
                name: name,
                subtitle: consecrationTitle,
                fact: "CONSECRATED TODAY",
                isPrayed: true,
                spoken: "\(name), \(consecrationTitle), consecrated today"
            )
        }

        // Chosen ahead: the day it begins, never a count
        guard progress.hasBegun(asOf: now) else {
            let start = progress.startDate
            return TodaysPrayerRow(
                painting: coronation,
                focal: coronationFocal,
                name: name,
                subtitle: invitation,
                fact: "BEGINS \(start.formatted(.dateTime.month(.abbreviated).day()).uppercased())",
                spoken: "\(name). \(invitation). Begins \(start.formatted(.dateTime.weekday(.wide).month(.wide).day()))"
            )
        }

        // Day 1 to 33 of the preparation, then the day of consecration,
        // which "DAY 34 OF 33" would be no way to say. Past it, with the
        // act not yet made, the row says it is ready, never that it is late.
        let daysIn = progress.daysSinceStart(asOf: now) + 1
        let day = min(daysIn, 34)
        let title = ConsecrationData.day(day)?.title ?? ""
        let prayed = progress.isDayCompleted(day)

        let fact: String
        let spokenDay: String
        switch daysIn {
        case ..<34:
            fact = "DAY \(day) OF 33"
            spokenDay = "day \(day) of 33"
        case 34:
            fact = "THE DAY OF CONSECRATION"
            spokenDay = "the day of consecration"
        default:
            fact = "READY TO CONSECRATE"
            spokenDay = "ready to consecrate"
        }

        return TodaysPrayerRow(
            painting: (ConsecrationPhase.phase(for: day) ?? .consecrationDay).heroImageName,
            focal: day >= 34 ? coronationFocal : UnitPoint(x: 0.5, y: 0.25),
            name: name,
            subtitle: title,
            fact: fact,
            isPrayed: prayed,
            spoken: [name, title, spokenDay, prayed ? "prayed today" : nil]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        )
    }

    // MARK: The hour's prayers

    /// The Prayer Book's order for the hour, said in the Prayers page's
    /// own sentence, and PRAYED once prayed to its Amen. The Angelus is
    /// the bell's, not the day's, as on the Prayers page: one said at
    /// noon leaves the evening's still to pray (`PrayerBook.isOfferedNow`).
    /// Never "missed": an hour gone by is simply not this row any more.
    static func hourOrder(at now: Date, store: PrayerBookStore) -> TodaysPrayerRow {
        let order = PrayerBook.dayOrder(at: now)
        let prayed = PrayerBook.isOfferedNow(
            order,
            at: now,
            offeredToday: store.wasOffered(order.id, on: now),
            lastOffered: store.lastOffered(order.id)
        )
        let painting = PrayerBookPainting.hour(order, on: now)
        let title = order.title(on: now)
        let moment = PrayerBook.dayOrderMoment(at: now)
        let summary = PrayerBook.daySummary(of: order, on: now)

        return TodaysPrayerRow(
            painting: painting.resolvedAsset,
            focal: painting.focal,
            name: title,
            subtitle: summary,
            fact: prayed ? "PRAYED" : moment.uppercased(),
            isPrayed: prayed,
            spoken: [
                title,
                summary.trimmingCharacters(in: CharacterSet(charactersIn: ".")),
                prayed ? "prayed today" : moment.lowercased(),
            ].joined(separator: ", ")
        )
    }

    // MARK: Today's Mass

    /// The feast in the line, its rank and silk in the fact: "St. Edward"
    /// over LESSER FEAST · WHITE. Until the propers arrive the line says
    /// what the Mass holds, and the fact waits.
    static func mass(_ today: TodayInChurch) -> TodaysPrayerRow {
        let name = "Today's Mass"
        let known = today.proper != nil
        let subtitle = known ? today.title : "Prayers and readings for today"

        let fact: String? = today.rank.map { rank in
            guard let vestment = today.vestment else { return rank.uppercased() }
            return "\(rank) · \(vestment.name)".uppercased()
        }

        let painting = PrayerBookPainting.topic(id: "mass")

        return TodaysPrayerRow(
            painting: painting.asset,
            focal: painting.focal,
            name: name,
            subtitle: subtitle,
            fact: fact,
            mark: today.vestment.map { .silk($0) } ?? .none,
            // The colour said in words, where the screen shows the silk
            spoken: [name, subtitle, today.spokenMeta].compactMap { $0 }.joined(separator: ", ")
        )
    }

    // MARK: The Hours of Prayer

    /// The hour it is in plain words over its Church name, and how long
    /// it is the hour: NOW · UNTIL NOON
    static func office(_ hour: CanonicalHour) -> TodaysPrayerRow {
        let until = CanonicalHour.clockWord(hour.following.beginsAtClockHour)
        let painting = PrayerBookPainting.topic(id: "day")

        return TodaysPrayerRow(
            painting: painting.asset,
            focal: painting.focal,
            name: "Hours of Prayer",
            subtitle: "\(hour.plainName) (\(hour.label))",
            fact: "NOW · UNTIL \(until.uppercased())",
            mark: .litHour,
            spoken: "Hours of Prayer, \(hour.plainName), \(hour.label), the hour now, until \(until)"
        )
    }
}

// MARK: - TodaysPrayerRowView

/// One routine: painting, name, line, fact, chevron. The same parts in
/// the same places on every row, so the four read as one list.
struct TodaysPrayerRowView: View {

    let row: TodaysPrayerRow
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                painting

                VStack(alignment: .leading, spacing: 3) {
                    // A name is never cut: at the larger text sizes it
                    // takes a second line
                    Text(row.name)
                        .font(AppFonts.headlineFont(16.5))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Two lines, so the hour's sentence is read whole
                    Text(row.subtitle)
                        .font(AppFonts.bodyFont(14.5))
                        .foregroundColor(AppColors.cream.opacity(0.72))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)

                    factLine
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AppIcon("ph-caret-right", size: 12)
                    .foregroundColor(AppColors.gold.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 9)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityLabel(row.spoken)
        .animation(Motion.crossfade, value: row.isPrayed)
        .animation(Motion.crossfade, value: row.fact)
    }

    /// The painting, cut square with a gold hairline edge, the check on
    /// its corner once prayed
    private var painting: some View {
        CachedAssetImage(row.painting, focal: row.focal)
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColors.gold.opacity(0.28), lineWidth: AppLine.hairline)
            )
            .overlay(alignment: .topTrailing) {
                if row.isPrayed {
                    PrayedSeal()
                        .offset(x: 5, y: -5)
                        .transition(.opacity)
                }
            }
            .accessibilityHidden(true)
    }

    private var factLine: some View {
        HStack(spacing: 7) {
            switch row.mark {
            case .silk(let vestment):
                RoundedRectangle(cornerRadius: 1)
                    .fill(vestment.swatch)
                    .frame(width: 3, height: 11)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            case .litHour:
                LitHourDot(size: 6, box: 11, glow: 3)
            case .none:
                EmptyView()
            }

            // A space while there is nothing to say, so every row keeps
            // its height and the list does not jump when the feast arrives
            Text(row.fact ?? " ")
                .font(AppFonts.labelFont(9))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .contentTransition(.opacity)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - PrayedSeal

/// The check on a prayed row's painting: the seal in gold on the
/// deepest ground, ringed so it reads over any painting
private struct PrayedSeal: View {

    var body: some View {
        AppIcon("ph-seal-check-fill", size: 16)
            .foregroundColor(AppColors.gold)
            .frame(width: 20, height: 20)
            .background(Circle().fill(AppColors.backgroundDeep))
            .overlay(Circle().strokeBorder(AppColors.gold.opacity(0.4), lineWidth: AppLine.hairline))
    }
}

// MARK: - LitHourDot

/// The mark that says "this hour, now": the lit disc inside a gold ring.
/// The same object on the home list and in the Office's arch, at the
/// sizes each needs.
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
