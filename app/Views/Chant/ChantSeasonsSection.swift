//
//  ChantSeasonsSection.swift
//  Lumen Viae
//
//  The Seasons board: the Church's year as a wheel, Advent at its head —
//  the seasons round its rim and the four antiphons of Our Lady on a
//  thread within, today marked where it falls, and in its middle how
//  long until the next season. Beneath it the seasons as chips, the
//  chosen one's chants, the chant to learn before the next season comes,
//  and the feasts ahead with the chant that goes with each.
//

import SwiftUI

struct ChantSeasonsSection: View {

    let open: (Chant) -> Void
    let learn: (Chant) -> Void

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    @State private var chosen: ChantSeason?

    init(open: @escaping (Chant) -> Void, learn: @escaping (Chant) -> Void) {
        self.open = open
        self.learn = learn
    }

    var body: some View {
        let today = Date()
        let year = ChantYear.containing(today)
        let current = year.season(on: today)
        let shown = chosen ?? current

        return VStack(alignment: .leading, spacing: 40) {
            VStack(spacing: 16) {
                ChantYearWheel(year: year, today: today, highlighted: shown)
                    .frame(maxWidth: 330)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                legend
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 18) {
                seasonChips(current: current, shown: shown)
                // The season's chants in a slot of their own, identified by
                // the season, so the list leaving and the list arriving
                // crossfade over one another
                ZStack(alignment: .top) {
                    inSeason(shown, current: current, year: year, today: today)
                        .id(shown)
                        .transition(.opacity)
                }
                .padding(.horizontal, 20)
            }
            .animation(Motion.crossfade, value: shown)

            comingUp(year: year, today: today)
                .padding(.horizontal, 20)

            feastsAhead(from: today)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 22) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(AppColors.gold.opacity(0.75))
                    .frame(width: 18, height: 5)
                Text("Church seasons")
            }
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppColors.cream.opacity(0.8))
                    .frame(width: 18, height: 1.5)
                Text("Night hymn to Mary")
            }
        }
        .font(AppFonts.readingItalicFont(13.5))
        .foregroundColor(AppColors.textSecondary)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Chips

    private func seasonChips(current: ChantSeason, shown: ChantSeason) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChantSeason.allCases) { season in
                        let lit = season == shown
                        Button {
                            chosen = season
                        } label: {
                            HStack(spacing: 6) {
                                if season == current {
                                    Circle()
                                        .fill(AppColors.gold)
                                        .frame(width: 4, height: 4)
                                }
                                Text(season.title.uppercased())
                                    .font(AppFonts.labelFont(9))
                                    .tracking(1.5)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(Capsule().fill(lit ? AppColors.gold.opacity(0.14) : Color.clear))
                            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(lit ? 0.6 : 0.25), lineWidth: AppLine.hairline))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(SacredCardButtonStyle())
                        .id(season)
                        .accessibilityLabel(season == current ? "\(season.title), now" : season.title)
                        .accessibilityAddTraits(lit ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear { proxy.scrollTo(shown, anchor: .center) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Season")
    }

    // MARK: - The season's chants

    private func inSeason(_ season: ChantSeason, current: ChantSeason, year: ChantYear, today: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(
                kicker: kicker(for: season, current: current, year: year, today: today),
                title: season.title,
                note: season.note
            )
            ChantRule()
            VStack(spacing: 0) {
                ForEach(season.chants) { chant in
                    ChantLibraryRow(chant: chant, player: player) {
                        open(chant)
                    }
                }
            }
        }
    }

    private func kicker(for season: ChantSeason, current: ChantSeason, year: ChantYear, today: Date) -> String {
        if season == current { return "In season now" }
        guard let span = year.span(of: season) else { return "Through the year" }
        if span.start > today {
            return "From \(span.start.formatted(.dateTime.day().month(.wide)))"
        }
        return "Kept earlier this year"
    }

    // MARK: - Coming up

    @ViewBuilder
    private func comingUp(year: ChantYear, today: Date) -> some View {
        let next = year.daysUntilNextSeason(from: today)
        if let chant = next.season.signatureChant, !shelf.isLearned(chant.id), next.days <= 70 {
            let begun = shelf.step(of: chant.id) != nil
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("COMING UP")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                    Text("Learn \(chant.latinTitle) before \(next.season.prose)")
                        .font(AppFonts.titleFont(19))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(timeLeft(days: next.days, season: next.season))
                        .font(AppFonts.readingItalicFont(14.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    QuietGoldButton(
                        title: begun ? "Continue learning" : "Start learning",
                        trailingIcon: "ph-caret-right",
                        horizontalPadding: 0
                    ) {
                        learn(chant)
                    }
                }
                Spacer(minLength: 0)
                ChantThumbnail(name: ChantCatalog.painting(subject: next.season.painting), size: 56, radius: 12)
            }
            .chantShell(padding: 18)
        }
    }

    private func timeLeft(days: Int, season: ChantSeason) -> String {
        let weeks = days / 7
        if weeks >= 2 {
            return "You have \(Self.number(weeks)) weeks. A few minutes a night is enough."
        }
        if days > 1 {
            return "\(season.title) begins in \(days) days. A few minutes a night is enough."
        }
        return days == 1 ? "\(season.title) begins tomorrow." : "\(season.title) begins today."
    }

    private static func number(_ n: Int) -> String {
        let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
        return words.indices.contains(n) ? words[n] : "\(n)"
    }

    // MARK: - Feasts ahead

    private func feastsAhead(from today: Date) -> some View {
        let feasts = ChantFeast.upcoming(from: today, count: 4)
        return VStack(alignment: .leading, spacing: 10) {
            ChantSectionHeading(kicker: "Coming up", title: "Feast days ahead", note: "The chant that goes with each one.")
            ChantRule()
            VStack(spacing: 0) {
                ForEach(feasts, id: \.feast.id) { item in
                    if let chant = item.feast.chant {
                        feastRow(item.feast, date: item.date, chant: chant)
                    }
                }
            }
        }
    }

    static func painting(of feast: ChantFeast, chant: Chant) -> String {
        feast.painting.map { ChantCatalog.painting(subject: $0) } ?? ChantCatalog.painting(for: chant)
    }

    private func feastRow(_ feast: ChantFeast, date: Date, chant: Chant) -> some View {
        let parts = ChantDates.dayAndMonth(date)
        return Button {
            open(chant)
        } label: {
            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text(parts.day)
                        .font(AppFonts.titleFont(24))
                        .foregroundColor(Rubric.text)
                        .monospacedDigit()
                    Text(parts.month)
                        .font(AppFonts.labelFont(8))
                        .tracking(1.5)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(width: 40)

                Rectangle()
                    .fill(AppColors.gold.opacity(0.3))
                    .frame(width: AppLine.hairline, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(feast.name)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(chant.latinTitle) · \(chant.durationLabel)")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                // The feast's own painting, as Coming Up hangs the season's;
                // a feast with none shows its chant's
                ChantThumbnail(name: Self.painting(of: feast, chant: chant), size: 56, radius: 12)
            }
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { ChantRule(opacity: 0.12) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date.formatted(.dateTime.day().month(.wide))), \(feast.name): \(chant.latinTitle), \(ChantPlayer.spoken(chant.duration))")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the chant")
    }
}

// MARK: - ChantYearWheel

/// The year from Advent to Advent as a ring: its seasons round the rim,
/// the season shown full gold and the rest at rest; within it a thread
/// for the four antiphons of Our Lady, broken where one gives way to the
/// next; today a mark on the rim; and in the middle, the days until the
/// next season. VoiceOver hears it as one sentence.
struct ChantYearWheel: View {
    let year: ChantYear
    let today: Date
    let highlighted: ChantSeason

    /// Each label's measured width, so a label near the rim's edge is
    /// kept inside the wheel's frame — AFTER PENTECOST, at the larger
    /// text sizes, once ran off the screen
    @State private var labelWidths: [ChantSeason: CGFloat] = [:]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ring = side / 2 - 30
            let thread = ring - 22

            ZStack {
                Canvas { context, _ in
                    draw(in: &context, center: center, ring: ring, thread: thread)
                }

                centre

                ForEach(year.seasons.filter { $0.value != .pentecost }, id: \.value) { span in
                    label(span.value, at: angle(of: midpoint(span)), radius: ring, center: center, bounds: geo.size)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: Drawing

    private func draw(in context: inout GraphicsContext, center: CGPoint, ring: CGFloat, thread: CGFloat) {
        // Week ticks round the outside, faint
        for week in 0..<52 {
            let a = angle(ofFraction: Double(week) / 52)
            let inner = point(center, ring + 14, a)
            let outer = point(center, ring + 18, a)
            var tick = Path()
            tick.move(to: inner)
            tick.addLine(to: outer)
            context.stroke(tick, with: .color(AppColors.gold.opacity(0.18)), lineWidth: 1)
        }

        // The seasons
        let gap = 0.004
        for span in year.seasons {
            let from = year.fraction(of: span.start) + gap
            let to = year.fraction(of: span.end) - gap
            guard to > from else { continue }
            let lit = span.value == highlighted
            context.stroke(
                arc(center, ring, from, to),
                with: .color(AppColors.gold.opacity(lit ? 0.95 : 0.26)),
                style: StrokeStyle(lineWidth: lit ? 16 : 13, lineCap: .butt)
            )
        }

        // The antiphons of Our Lady, a thread broken at each change
        for span in year.antiphons {
            let from = year.fraction(of: span.start) + 0.006
            let to = year.fraction(of: span.end) - 0.006
            guard to > from else { continue }
            context.stroke(arc(center, thread, from, to), with: .color(AppColors.cream.opacity(0.75)), lineWidth: 1.2)
            let dot = point(center, thread, angle(ofFraction: from))
            context.fill(
                Path(ellipseIn: CGRect(x: dot.x - 2.5, y: dot.y - 2.5, width: 5, height: 5)),
                with: .color(AppColors.cream.opacity(0.85))
            )
        }

        // Today, across the rim
        let now = angle(ofFraction: year.fraction(of: today))
        var mark = Path()
        mark.move(to: point(center, thread - 8, now))
        mark.addLine(to: point(center, ring + 14, now))
        context.stroke(mark, with: .color(AppColors.goldLight.opacity(0.9)), lineWidth: 1.2)
        let sun = point(center, ring + 14, now)
        var glow = context
        glow.addFilter(.shadow(color: AppColors.gold.opacity(0.8), radius: 5))
        glow.fill(
            Path(ellipseIn: CGRect(x: sun.x - 5, y: sun.y - 5, width: 10, height: 10)),
            with: .color(AppColors.goldLight)
        )
    }

    private var centre: some View {
        let next = year.daysUntilNextSeason(from: today)
        let current = year.season(on: today)
        return VStack(spacing: 4) {
            Text("NOW: \(current.title.uppercased())")
                .font(AppFonts.labelFont(8.5))
                .tracking(1.5)
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)
            Text("\(next.days)")
                .font(AppFonts.titleFont(46))
                .foregroundColor(AppColors.cream)
                .monospacedDigit()
            Text(next.days == 1 ? "day until \(next.season.title)" : "days until \(next.season.title)")
                .font(AppFonts.readingItalicFont(15))
                .foregroundColor(AppColors.cream.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 150)
    }

    private func label(_ season: ChantSeason, at a: Angle, radius: CGFloat, center: CGPoint, bounds: CGSize) -> some View {
        let lit = season == highlighted
        let place = point(center, radius, a)
        let half = (labelWidths[season] ?? 0) / 2
        let x = max(half, min(bounds.width - half, place.x))
        return Text(season.title.uppercased())
            .font(AppFonts.labelFont(8))
            .tracking(1.2)
            .foregroundColor(lit ? AppColors.background : AppColors.cream.opacity(0.85))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(lit ? AppColors.goldLight : AppColors.background))
            .overlay(Capsule().strokeBorder(AppColors.gold.opacity(lit ? 0 : 0.5), lineWidth: AppLine.hairline))
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { labelWidths[season] = $0 }
            .position(x: x, y: place.y)
    }

    // MARK: Geometry

    /// Clockwise from the head of the ring, as a clock's hand goes
    private func angle(ofFraction t: Double) -> Angle {
        .radians(-.pi / 2 + 2 * .pi * t)
    }

    private func angle(of date: Date) -> Angle {
        angle(ofFraction: year.fraction(of: date))
    }

    private func midpoint(_ span: ChantYear.Span<ChantSeason>) -> Date {
        span.start.addingTimeInterval(span.end.timeIntervalSince(span.start) / 2)
    }

    private func point(_ center: CGPoint, _ radius: CGFloat, _ a: Angle) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(cos(a.radians)), y: center.y + radius * CGFloat(sin(a.radians)))
    }

    private func arc(_ center: CGPoint, _ radius: CGFloat, _ from: Double, _ to: Double) -> Path {
        var path = Path()
        let steps = max(2, Int((to - from) * 240))
        for i in 0...steps {
            let t = from + (to - from) * Double(i) / Double(steps)
            let p = point(center, radius, angle(ofFraction: t))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }

    private var accessibilitySummary: String {
        let next = year.daysUntilNextSeason(from: today)
        let current = year.season(on: today)
        let antiphon = year.antiphons.first { today >= $0.start && today < $0.end }
        var summary = "The Church's year. Now: \(current.title). \(next.days) \(next.days == 1 ? "day" : "days") until \(next.season.title)."
        if let antiphon, let chant = ChantCatalog.chants(forPrayer: antiphon.value.prayerID).first {
            summary += " The night hymn to Mary is the \(chant.latinTitle)."
        }
        return summary
    }
}
