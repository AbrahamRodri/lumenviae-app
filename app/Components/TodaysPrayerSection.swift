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

    private var activeConsecration: ConsecrationProgress? {
        consecrations.first { !$0.isCompleted }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(spacing: 4) {
                TodaysPrayerRowView(row: .consecration(activeConsecration)) {
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
            let now = fixedNow ?? context.date
            let order = PrayerBook.dayOrder(at: now)
            TodaysPrayerRowView(row: .hourOrder(order, at: now, prayed: store.wasOffered(order.id, on: now))) {
                router.push(.prayerBook)
            }
        }
    }

    // MARK: - The Hours of Prayer

    private var officeRow: some View {
        let hour = fixedNow.map { CanonicalHour.present(atClockHour: Calendar.current.component(.hour, from: $0)) }
            ?? clock.hour

        return TodaysPrayerRowView(row: .office(hour)) {
            router.push(.office)
        }
        .id(hour)
        .transition(.opacity)
        .animation(Motion.crossfade, value: hour)
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

    /// The preparation's painting while it is under way is its period's
    /// own, the one its day page opens on; before it, the Coronation.
    static func consecration(_ progress: ConsecrationProgress?, now: Date = Date()) -> TodaysPrayerRow {
        let name = "Consecration to Mary"
        let coronation = ConsecrationPhase.consecrationDay.heroImageName

        guard let progress else {
            return TodaysPrayerRow(
                painting: coronation,
                focal: UnitPoint(x: 0.5, y: 0.12),
                name: name,
                subtitle: "Give yourself to Jesus through Mary",
                fact: "BEGIN",
                spoken: "\(name). Give yourself to Jesus through Mary, a 33-day preparation. Begin."
            )
        }

        // Chosen ahead: the day it begins, never a count
        guard progress.hasBegun(asOf: now) else {
            let start = progress.startDate
            return TodaysPrayerRow(
                painting: coronation,
                focal: UnitPoint(x: 0.5, y: 0.12),
                name: name,
                subtitle: "Give yourself to Jesus through Mary",
                fact: "BEGINS \(start.formatted(.dateTime.month(.abbreviated).day()).uppercased())",
                spoken: "\(name), begins \(start.formatted(.dateTime.weekday(.wide).month(.wide).day()))"
            )
        }

        // Day 1 to 33 of the preparation, then the day of consecration
        // itself, which "DAY 34 OF 33" would be no way to say
        let day = progress.currentDayNumber
        let title = ConsecrationData.day(day)?.title ?? ""
        let prayed = progress.isDayCompleted(day)
        let isConsecrationDay = day > 33
        let fact = isConsecrationDay ? "THE DAY OF CONSECRATION" : "DAY \(day) OF 33"
        let spokenDay = isConsecrationDay ? "the day of consecration" : "day \(day) of 33"

        return TodaysPrayerRow(
            painting: (ConsecrationPhase.phase(for: day) ?? .consecrationDay).heroImageName,
            focal: UnitPoint(x: 0.5, y: 0.25),
            name: name,
            subtitle: title,
            fact: fact,
            isPrayed: prayed,
            spoken: [name, spokenDay, title, prayed ? "prayed today" : nil]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        )
    }

    // MARK: The hour's prayers

    /// The Prayer Book's order for the hour, said in the Prayers page's
    /// own sentence, and PRAYED once prayed to its Amen this prayer day.
    /// Never "missed": an hour gone by is simply not this row any more.
    static func hourOrder(_ order: PrayerOrder, at now: Date, prayed: Bool) -> TodaysPrayerRow {
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
            spoken: "\(title), \(prayed ? "prayed today" : moment.lowercased()). \(summary)"
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

        return TodaysPrayerRow(
            painting: "topic_holy_mass",
            focal: UnitPoint(x: 0.5, y: 0.5),
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
        let until = untilWord(hour.following.beginsAtClockHour)

        return TodaysPrayerRow(
            painting: "topic_daily_prayers",
            focal: UnitPoint(x: 0.5, y: 0.45),
            name: "Hours of Prayer",
            subtitle: "\(hour.plainName) (\(hour.label))",
            fact: "NOW · UNTIL \(until.uppercased())",
            mark: .litHour,
            spoken: "Hours of Prayer, \(hour.plainName), \(hour.label), the hour now, until \(until)"
        )
    }

    /// "noon", "midnight", "2 PM": the clock hour an hour of the Office
    /// begins at, said as the row says it
    static func untilWord(_ clockHour: Int) -> String {
        switch clockHour {
        case 0, 24: return "midnight"
        case 12: return "noon"
        case 1..<12: return "\(clockHour) AM"
        default: return "\(clockHour - 12) PM"
        }
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

                    Text(row.subtitle)
                        .font(AppFonts.bodyFont(14.5))
                        .foregroundColor(AppColors.cream.opacity(0.72))
                        .lineLimit(1)
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
