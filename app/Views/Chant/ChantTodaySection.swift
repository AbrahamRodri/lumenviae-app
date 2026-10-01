//
//  ChantTodaySection.swift
//  Lumen Viae
//
//  The Today board: what the Church sings now. The day's four hours on
//  an arc with the present one lit; tonight's antiphon of Our Lady, the
//  board's one gold act; the weekday's traditional devotion and its
//  chants; the month's dedication; and, when a chant is being learned,
//  the way back to it.
//

import SwiftUI

struct ChantTodaySection: View {

    let open: (Chant) -> Void
    let learn: (Chant) -> Void
    let openOccasion: (ChantOccasion) -> Void

    private var player = ChantPlayer.shared
    private var shelf = ChantShelfStore.shared

    /// The setting of tonight's antiphon the reader chose; the simple
    /// until they choose
    @State private var tonightSettingID: String?

    /// A weekday chosen from the row of seven; today until one is
    @State private var weekdayChosen: Int?

    init(
        open: @escaping (Chant) -> Void,
        learn: @escaping (Chant) -> Void,
        openOccasion: @escaping (ChantOccasion) -> Void
    ) {
        self.open = open
        self.learn = learn
        self.openOccasion = openOccasion
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            throughTheDay
                .padding(.horizontal, 20)

            if let antiphon = ChantCatalog.antiphonOfTheSeason() {
                tonight(antiphon)
            }

            weekday
                .padding(.horizontal, 20)

            if let month = ChantMonth.of(Date()) {
                monthCard(month)
                    .padding(.horizontal, 20)
            }

            if let progress = shelf.latestInProgress {
                continueLearning(progress.chant, step: progress.step)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Through the day

    private var throughTheDay: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            let present = ChantHour.present(at: now)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    ChantSectionHeading(kicker: "Through the day", title: present.headline, titleSize: 19)
                    Text(now.formatted(date: .omitted, time: .shortened).uppercased())
                        .font(AppFonts.labelFont(9))
                        .tracking(1)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }

                ChantDayArc(now: now, present: present)
                    .frame(height: 78)

                HStack(alignment: .top, spacing: 4) {
                    ForEach(ChantHour.allCases) { hour in
                        hourStation(hour, lit: hour == present, on: now)
                    }
                }
            }
        }
    }

    private func hourStation(_ hour: ChantHour, lit: Bool, on now: Date) -> some View {
        let chant = hour.chant(on: now)
        return Button {
            if let chant { open(chant) }
        } label: {
            VStack(spacing: 3) {
                Text(hour.time.uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.5)
                    .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                Text(chant.map(shortTitle) ?? "")
                    .font(AppFonts.readingItalicFont(14))
                    .foregroundColor(lit ? AppColors.cream : AppColors.cream.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("\(hour.time): \(chant?.latinTitle ?? "")")
        .accessibilityAddTraits(lit ? [.isSelected] : [])
        .accessibilityHint("Opens the chant")
    }

    /// The station's name, as short as it can honestly be
    private func shortTitle(_ chant: Chant) -> String {
        chant.id == "angelus" ? "Angelus" : chant.latinTitle
    }

    // MARK: - Tonight's chant

    private func tonight(_ antiphon: Chant) -> some View {
        let settings = antiphon.settings
        let chosen = settings.first { $0.id == tonightSettingID } ?? antiphon
        let holds = player.holds(chosen)

        return VStack(alignment: .leading, spacing: 0) {
            ChantPainting(
                name: ChantCatalog.painting(subject: "hour_night", else: ChantCatalog.painting(for: chosen)),
                height: 250,
                dissolveFrom: 0.3
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("TONIGHT'S CHANT")
                    .font(AppFonts.labelFont(9))
                    .tracking(2)
                    .foregroundColor(AppColors.gold)

                Text(chosen.latinTitle)
                    .font(AppFonts.titleFont(30))
                    .foregroundColor(AppColors.cream)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(ChantCatalog.tonightLine(for: chosen))
                    .font(AppFonts.readingItalicFont(16))
                    .foregroundColor(AppColors.cream.opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        tonightTransport(chosen, holds: holds)
                        Spacer(minLength: 8)
                        if settings.count > 1 {
                            settingPill(settings, chosen: chosen)
                                .frame(width: 170)
                        }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        tonightTransport(chosen, holds: holds)
                        if settings.count > 1 {
                            settingPill(settings, chosen: chosen)
                        }
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, -64)
        }
    }

    private func tonightTransport(_ chant: Chant, holds: Bool) -> some View {
        HStack(spacing: 14) {
            ChantGoldPlayButton(
                isPlaying: player.isPlaying(chant),
                isLoading: player.current.id == chant.id && player.isLoading,
                size: 56,
                label: chant.latinTitle
            ) {
                player.toggle(chant)
            }

            Button {
                open(chant)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chant.setting ?? chant.englishTitle)
                        .font(AppFonts.readingFont(16))
                        .foregroundColor(AppColors.cream)
                        .lineLimit(1)
                    Text(holds ? (player.timeLabel ?? chant.durationLabel) : chant.durationLabel)
                        .font(AppFonts.readingItalicFont(13))
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the chant with its score")
        }
    }

    private func settingPill(_ settings: [Chant], chosen: Chant) -> some View {
        ChantSettingPill(settings: settings, selected: chosen.id) { setting in
            let wasSounding = player.isPlaying(chosen)
            tonightSettingID = setting.id
            // A reader listening who chooses the other setting hears it
            if wasSounding { player.play(setting) }
        }
    }

    // MARK: - The day of the week

    private var weekday: some View {
        let today = ChantWeekday.of(Date())
        let shown = ChantLibraryData.weekdays.first { $0.weekday == weekdayChosen } ?? today
        let isToday = shown.weekday == today.weekday

        return VStack(alignment: .leading, spacing: 16) {
            ChantSectionHeading(
                kicker: shown.name,
                title: shown.headline,
                note: isToday
                    ? "Each day of the week has a traditional devotion. Here is today's."
                    : "Each day of the week has a traditional devotion."
            )

            HStack(spacing: 0) {
                ForEach(ChantLibraryData.weekdays) { day in
                    weekdayBead(day, lit: day.weekday == shown.weekday, today: day.weekday == today.weekday)
                }
            }
            .sensoryFeedback(.selection, trigger: shown.weekday)

            if let featured = shown.chants.first {
                weekdayCard(shown, featured: featured)
            }
        }
        .animation(Motion.crossfade, value: shown.weekday)
    }

    private func weekdayBead(_ day: ChantWeekday, lit: Bool, today: Bool) -> some View {
        Button {
            weekdayChosen = day.weekday
        } label: {
            VStack(spacing: 4) {
                Text(day.initial)
                    .font(AppFonts.labelFont(11))
                    .foregroundColor(lit ? AppColors.goldLight : AppColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle().strokeBorder(
                            lit ? AppColors.gold : AppColors.gold.opacity(0.25),
                            lineWidth: lit ? 1 : AppLine.hairline
                        )
                    )
                    .shadow(color: lit ? AppColors.gold.opacity(0.3) : .clear, radius: 6)
                Circle()
                    .fill(AppColors.gold.opacity(today ? 0.8 : 0))
                    .frame(width: 3, height: 3)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuietGlyphButtonStyle())
        .accessibilityLabel("\(day.name), \(day.devotion)\(today ? ", today" : "")")
        .accessibilityAddTraits(lit ? [.isSelected] : [])
    }

    private func weekdayCard(_ day: ChantWeekday, featured: Chant) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ChantThumbnail(name: ChantCatalog.painting(subject: day.painting), size: 64, radius: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(featured.form.singular) · \(featured.durationLabel)".uppercased())
                    .font(AppFonts.labelFont(8.5))
                    .tracking(1.5)
                    .foregroundColor(AppColors.gold.opacity(0.8))

                Button {
                    open(featured)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(featured.latinTitle)
                            .font(AppFonts.headlineFont(17))
                            .foregroundColor(AppColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(featured.detail)
                            .font(AppFonts.readingItalicFont(14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the chant with its score")

                HStack(spacing: 10) {
                    ChantPlayDisc(
                        isPlaying: player.isPlaying(featured),
                        isLoading: player.current.id == featured.id && player.isLoading,
                        size: 32,
                        label: featured.latinTitle
                    ) {
                        player.toggle(featured)
                    }

                    if day.chants.count > 1 {
                        Button {
                            player.play(ChantQueue.chants(day.chants, title: "\(day.name)'s chants"))
                        } label: {
                            Text("Play all \(day.chants.count) \(day.collective)")
                                .font(AppFonts.readingFont(14.5))
                                .foregroundColor(AppColors.gold)
                                .underline(color: AppColors.gold.opacity(0.4))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(QuietGlyphButtonStyle())
                    }
                }
            }
        }
        .chantShell()
    }

    // MARK: - The month

    private func monthCard(_ month: ChantMonth) -> some View {
        VStack(spacing: 12) {
            Text(month.name.uppercased())
                .font(AppFonts.labelFont(9))
                .tracking(2.5)
                .foregroundColor(AppColors.gold)

            Text(month.title)
                .font(AppFonts.titleFont(22))
                .foregroundColor(AppColors.cream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let line = feastLine(month) {
                Text(line)
                    .font(AppFonts.readingItalicFont(15))
                    .foregroundColor(AppColors.cream.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                if let occasion = month.occasion {
                    monthRow(
                        kicker: "Sung together",
                        title: occasion.title,
                        note: occasion.note,
                        trailing: minutes(occasion.duration())
                    ) {
                        openOccasion(occasion)
                    }
                }
                if let chant = month.feast?.chant {
                    monthRow(
                        kicker: "For the feast",
                        title: chant.latinTitle,
                        note: chant.englishTitle,
                        trailing: chant.durationLabel
                    ) {
                        open(chant)
                    }
                }
                ForEach(month.chants) { chant in
                    monthRow(
                        kicker: "For the month",
                        title: chant.latinTitle,
                        note: chant.englishTitle,
                        trailing: chant.durationLabel
                    ) {
                        open(chant)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColors.gold.opacity(0.24), lineWidth: AppLine.hairline)
        )
        .overlay(OrnateCornersOverlay(inset: 8, length: 12, opacity: 0.45))
    }

    private func monthRow(
        kicker: String,
        title: String,
        note: String,
        trailing: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kicker.uppercased())
                        .font(AppFonts.labelFont(8))
                        .tracking(1.5)
                        .foregroundColor(AppColors.gold.opacity(0.7))
                    Text(title)
                        .font(AppFonts.readingFont(17))
                        .foregroundColor(AppColors.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(note)
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(trailing.uppercased())
                    .font(AppFonts.labelFont(9))
                    .tracking(1)
                    .foregroundColor(AppColors.textSecondary)
                    .monospacedDigit()
                AppIcon("ph-caret-right", size: 10)
                    .foregroundColor(AppColors.gold.opacity(0.45))
            }
            .padding(.vertical, 10)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) { ChantRule(opacity: 0.18) }
        .accessibilityElement(children: .combine)
    }

    /// "The Feast of Our Lady of the Rosary is Wednesday, October 7."
    private func feastLine(_ month: ChantMonth) -> String? {
        guard let feast = month.feast else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        guard let date = feast.date(in: year),
              calendar.component(.month, from: date) == month.month else { return nil }
        let name = feast.name.hasPrefix("The ") ? "the " + String(feast.name.dropFirst(4)) : feast.name
        let day = calendar.startOfDay(for: now)
        if calendar.isDate(date, inSameDayAs: day) {
            return "Today is the Feast of \(name)."
        }
        let tense = date > day ? "is" : "was"
        return "The Feast of \(name) \(tense) \(ChantDates.feastDay(date))."
    }

    private func minutes(_ duration: TimeInterval) -> String {
        let whole = max(1, Int((duration / 60).rounded()))
        return "\(whole) min"
    }

    // MARK: - Continue learning

    private func continueLearning(_ chant: Chant, step: ChantLearningStep) -> some View {
        Button {
            learn(chant)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONTINUE LEARNING")
                        .font(AppFonts.labelFont(9))
                        .tracking(2)
                        .foregroundColor(AppColors.gold)
                    Text(chant.latinTitle)
                        .font(AppFonts.readingFont(18))
                        .foregroundColor(AppColors.cream)
                    ChantStepBeads(step: step)
                    Text("Step \(step.rawValue) of 4: \(step.title)")
                        .font(AppFonts.readingItalicFont(13.5))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer(minLength: 8)
                AppIcon("ph-caret-right", size: 11)
                    .foregroundColor(AppColors.gold.opacity(0.6))
            }
            .chantShell()
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the practice for this chant")
    }
}

// MARK: - ChantDayArc

/// The day as the sun's arc, from four in the morning to four the next,
/// with the four hours the library sings for strung along it: the
/// present one ringed, the arc behind the present time in gold. A
/// drawing only; the stations beneath it are the doors.
struct ChantDayArc: View {
    let now: Date
    let present: ChantHour

    /// Where each station stands along the arc, evenly, as the board
    /// draws them
    private static let stations: [CGFloat] = [0.125, 0.375, 0.625, 0.875]

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 8
            func point(_ t: CGFloat) -> CGPoint {
                let x = inset + (size.width - inset * 2) * t
                let rise = sin(.pi * t)
                let y = size.height - 6 - (size.height - 16) * rise
                return CGPoint(x: x, y: y)
            }

            let nowT = Self.position(of: now)

            var behind = Path()
            var ahead = Path()
            let steps = 80
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let p = point(t)
                if t <= nowT {
                    if i == 0 { behind.move(to: p) } else { behind.addLine(to: p) }
                } else {
                    if ahead.isEmpty { ahead.move(to: point(nowT)) }
                    ahead.addLine(to: p)
                }
            }
            context.stroke(behind, with: .color(AppColors.gold.opacity(0.65)), lineWidth: 1)
            context.stroke(
                ahead,
                with: .color(AppColors.gold.opacity(0.25)),
                style: StrokeStyle(lineWidth: 1, dash: [2, 4])
            )

            for (index, t) in Self.stations.enumerated() {
                let p = point(t)
                let lit = index == present.rawValue
                let radius: CGFloat = lit ? 6 : 3.5
                let ring = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                context.fill(ring, with: .color(AppColors.background))
                context.stroke(ring, with: .color(lit ? AppColors.goldLight : AppColors.gold.opacity(0.6)), lineWidth: 1)
            }

            let sun = point(nowT)
            context.addFilter(.shadow(color: AppColors.gold.opacity(0.7), radius: 5))
            context.fill(
                Path(ellipseIn: CGRect(x: sun.x - 4.5, y: sun.y - 4.5, width: 9, height: 9)),
                with: .color(AppColors.goldLight)
            )
        }
        .accessibilityHidden(true)
    }

    /// 0…1 along the arc for a moment of the day: stations at their
    /// places, the time between them spread evenly
    static func position(of date: Date, calendar: Calendar = .current) -> CGFloat {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        var hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60
        let start = Double(PrayerBook.dayBeginsAtHour)
        if hour < start { hour += 24 }
        let anchors: [(hour: Double, t: Double)] = [
            (start, 0),
            (ChantHour.morning.clockHour, Double(stations[0])),
            (ChantHour.noon.clockHour, Double(stations[1])),
            (ChantHour.evening.clockHour, Double(stations[2])),
            (ChantHour.night.clockHour, Double(stations[3])),
            (start + 24, 1)
        ]
        for (a, b) in zip(anchors, anchors.dropFirst()) where hour >= a.hour && hour <= b.hour {
            let span = b.hour - a.hour
            let f = span > 0 ? (hour - a.hour) / span : 0
            return CGFloat(a.t + (b.t - a.t) * f)
        }
        return 0
    }
}
