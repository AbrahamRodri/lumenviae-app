//
//  DayWidgets.swift
//  Lumen Viae Widgets
//
//  3 Novena, 4 Today in the Church and 5 The Angelus.
//

import SwiftUI
import WidgetKit

// MARK: - 3 Novena

struct NovenaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Novena", provider: LumenTimeline()) { entry in
            NovenaWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.novena.name", tableName: "Widgets"))
        .description(Text("widget.gallery.novena.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct NovenaWidgetView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    private var novena: WidgetSnapshot.Novena? { entry.prayerDay?.novenas.first }

    var body: some View {
        Group {
            if let labels = entry.snapshot?.labels {
                if let novena {
                    switch family {
                    case .systemMedium: medium(novena, labels: labels)
                    case .accessoryCircular: circle(novena)
                    case .accessoryRectangular:
                        LockRectangle(title: novena.name, lines: ["\(novena.dayLine) · \(novena.statusLine)"]) {
                            NovenaDashes(novena: novena, onLockScreen: true).padding(.top, 4)
                        }
                    default: small(novena, labels: labels)
                    }
                } else {
                    noNovena(labels)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.novena(novena?.id))
        .lumenBackground()
    }

    private func small(_ novena: WidgetSnapshot.Novena, labels: WidgetSnapshot.Labels) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: labels.novena)
            Title(text: novena.name).padding(.top, 5)
            Spacer(minLength: 0)
            Text(novena.dayLine)
                .font(WidgetFonts.garamond(17))
                .foregroundStyle(WidgetColors.cream)
            NovenaDashes(novena: novena).padding(.top, 8).padding(.bottom, 7)
            ItalicLine(text: novena.statusLine, size: 13, color: WidgetColors.muted, lines: 1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func medium(_ novena: WidgetSnapshot.Novena, labels: WidgetSnapshot.Labels) -> some View {
        ZStack(alignment: .topLeading) {
            HalfPainting(name: novena.painting)
            BesidePainting {
                Kicker(text: labels.novena)
                Title(text: novena.name, size: 23).padding(.top, 5)
                Spacer(minLength: 0)
                Text(novena.dayLine)
                    .font(WidgetFonts.garamond(17))
                    .foregroundStyle(WidgetColors.cream)
                NovenaDashes(novena: novena, wide: true).padding(.top, 8).padding(.bottom, 7)
                ItalicLine(text: novena.statusLine, size: 13.5, color: WidgetColors.muted, lines: 1)
            }
        }
    }

    private func circle(_ novena: WidgetSnapshot.Novena) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            ProgressRing(fraction: Double(novena.prayedDays.count) / Double(max(novena.length, 1)))
            Text("\(novena.currentDay)/\(novena.length)")
                .font(.system(size: 19, weight: .bold))
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(novena.name), \(novena.dayLine), \(novena.statusLine)"))
    }

    @ViewBuilder
    private func noNovena(_ labels: WidgetSnapshot.Labels) -> some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                LumenMark(white: true).frame(width: 18, height: 27)
            }
        case .accessoryRectangular:
            LockRectangle(title: labels.yourNovenas, lines: [labels.beginANovena.capitalizedSentence])
        default:
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: labels.novena)
                Title(text: labels.yourNovenas).padding(.top, 5)
                Spacer(minLength: 0)
                GoLink(text: labels.beginANovena)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// The novena's days as dashes: prayed in gold, today's an outline until
/// it is prayed, the rest quiet
struct NovenaDashes: View {
    let novena: WidgetSnapshot.Novena
    var wide = false
    var onLockScreen = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...max(novena.length, 1), id: \.self) { day in
                dash(day)
                    .frame(width: onLockScreen ? 12 : (wide ? 15 : 11), height: wide ? 6 : 5)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func dash(_ day: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        if novena.prayedDays.contains(day) {
            shape.fill(onLockScreen ? Color.white : WidgetColors.gold)
        } else if day == novena.currentDay {
            shape.strokeBorder(onLockScreen ? Color.white : WidgetColors.goldLight, lineWidth: 1.5)
        } else {
            shape.fill(onLockScreen ? Color.white.opacity(0.3) : WidgetColors.muted.opacity(0.35))
        }
    }
}

extension String {
    /// "BEGIN A NOVENA" as a sentence: "Begin a novena"
    var capitalizedSentence: String {
        let lower = lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }
}

// MARK: - 4 Today in the Church

struct TodayInChurchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayInChurch", provider: LumenTimeline()) { entry in
            TodayInChurchView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.church.name", tableName: "Widgets"))
        .description(Text("widget.gallery.church.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct TodayInChurchView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let day = entry.day, let labels = entry.snapshot?.labels {
                let feast = day.liturgicalDay
                let title = feast?.title ?? labels.todaysMass
                let rank = feast?.rank ?? (feast == nil ? labels.massFallbackLine : nil)
                switch family {
                case .accessoryInline:
                    Text(title)
                case .accessoryRectangular:
                    LockRectangle(
                        title: title,
                        lines: [[feast?.rank, feast?.colourName].compactMap { $0 }.joined(separator: " · "), day.dateLineFull])
                case .systemMedium:
                    ZStack(alignment: .topLeading) {
                        HalfPainting(name: feast?.painting ?? "topic_holy_mass")
                        BesidePainting {
                            Kicker(text: day.dateLine)
                            Spacer(minLength: 0)
                            Title(text: title, size: 23, lines: 3)
                            if let rank { ItalicLine(text: rank, size: 16).padding(.top, 4) }
                            colour(feast).padding(.top, 12)
                        }
                    }
                default:
                    VStack(alignment: .leading, spacing: 0) {
                        Kicker(text: day.dateLine.replacingOccurrences(of: " · ", with: "\n"))
                        Spacer(minLength: 0)
                        Title(text: title, lines: 3)
                        if let rank { ItalicLine(text: rank).padding(.top, 3) }
                        colour(feast).padding(.top, 10)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.missalToday)
        .lumenBackground()
    }

    @ViewBuilder
    private func colour(_ feast: WidgetSnapshot.LiturgicalDay?) -> some View {
        if let name = feast?.colourName, let hex = feast?.colourHex {
            HStack(spacing: 6) {
                Circle()
                    .fill(WidgetColors.hex(hex))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                    .frame(width: 9, height: 9)
                Kicker(text: name, color: WidgetColors.muted)
            }
        }
    }
}

// MARK: - 5 The Angelus

struct AngelusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Angelus", provider: LumenTimeline()) { entry in
            AngelusWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.angelus.name", tableName: "Widgets"))
        .description(Text("widget.gallery.angelus.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct AngelusWidgetView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    /// The bell rung now (its whole hour), or nil between bells
    private var bellNow: Int? {
        let hour = Calendar.current.component(.hour, from: entry.date)
        return [6, 12, 18].firstIndex(of: hour)
    }

    /// The next bell: 0 for six, 1 for noon, 2 for six in the evening
    private var nextBell: Int {
        let hour = Calendar.current.component(.hour, from: entry.date)
        if hour < 6 { return 0 }
        if hour < 12 { return 1 }
        if hour < 18 { return 2 }
        return 0
    }

    var body: some View {
        Group {
            if let day = entry.day, let labels = entry.snapshot?.labels {
                let bell = bellNow ?? nextBell
                switch family {
                case .accessoryInline:
                    Text(day.angelus.atLines[safe: bell] ?? day.angelus.title)
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        VStack(spacing: 1) {
                            Text(labels.angelusTimes[safe: bell]?.split(separator: ":").first.map(String.init) ?? "")
                                .font(.system(size: 21, weight: .bold))
                            Text(day.angelus.shortName.uppercased())
                                .font(.system(size: 8.5, weight: .semibold))
                                .minimumScaleFactor(0.7)
                                .opacity(0.85)
                        }
                    }
                default:
                    if let now = bellNow {
                        atTheHour(day, kicker: labels.angelusAtTheHour[safe: now] ?? "")
                    } else {
                        nextTime(day, labels: labels, bell: bell)
                    }
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.angelus)
        .lumenBackground(atTheHour: bellNow != nil && family == .systemSmall)
    }

    private func nextTime(_ day: WidgetSnapshot.Day, labels: WidgetSnapshot.Labels, bell: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                LumenMark().frame(width: 15, height: 22)
                Kicker(text: day.angelus.title)
            }
            Text(labels.angelusTimes[safe: bell] ?? "")
                .font(WidgetFonts.cinzel(40))
                .foregroundStyle(WidgetColors.cream)
                .padding(.top, 6)
            Kicker(text: labels.angelusHourNames[safe: bell] ?? "", color: WidgetColors.muted).padding(.top, 4)
            Spacer(minLength: 0)
            ItalicLine(text: day.angelus.firstLine, size: 13.5, lines: 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func atTheHour(_ day: WidgetSnapshot.Day, kicker: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                LumenMark().frame(width: 15, height: 22)
                Kicker(text: kicker)
            }
            Spacer(minLength: 0)
            Title(text: day.angelus.prayLine, color: WidgetColors.goldLight)
            ItalicLine(text: day.angelus.firstLine, size: 13.5, lines: 2).padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
