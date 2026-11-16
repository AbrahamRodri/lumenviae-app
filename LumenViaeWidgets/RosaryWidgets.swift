//
//  RosaryWidgets.swift
//  Lumen Viae Widgets
//
//  1 Today's Mysteries and 2 Continue Your Rosary.
//

import SwiftUI
import WidgetKit

// MARK: - 1 Today's Mysteries

struct TodaysMysteriesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodaysMysteries", provider: LumenTimeline()) { entry in
            TodaysMysteriesView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.mysteries.name", tableName: "Widgets"))
        .description(Text("widget.gallery.mysteries.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct TodaysMysteriesView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let day = entry.day {
                switch family {
                case .systemMedium: medium(day)
                case .systemLarge: large(day)
                case .accessoryRectangular: lock(day)
                default: small(day)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.todaysMysteries)
        .lumenBackground()
    }

    private func small(_ day: WidgetSnapshot.Day) -> some View {
        ZStack(alignment: .bottomLeading) {
            FullPainting(name: day.mysteries.paintings.first)
            VStack(alignment: .leading, spacing: 5) {
                Kicker(text: day.todayLine)
                Title(text: day.mysteries.title, size: 16)
            }
            .padding(16)
        }
    }

    private func medium(_ day: WidgetSnapshot.Day) -> some View {
        ZStack(alignment: .topLeading) {
            HalfPainting(name: day.mysteries.paintings.first)
            BesidePainting {
                HStack(spacing: 6) {
                    LumenMark().frame(width: 15, height: 22)
                    Kicker(text: day.todayLine)
                }
                // A step down, and the first mystery only where it fits whole
                // on one line (design: English keeps it, Spanish leaves it out)
                Title(text: day.mysteries.title, size: 21).padding(.top, 8)
                WholeLineOrNothing(text: day.mysteries.firstLine).padding(.top, 4)
                Spacer(minLength: 0)
                GoLink(text: entry.snapshot?.labels.begin ?? "")
            }
        }
    }

    private func large(_ day: WidgetSnapshot.Day) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                FullPainting(name: day.mysteries.paintings.first, focusY: 0.18)
                    .frame(height: proxy.size.height * 0.48)
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 118)
                    Kicker(text: day.todayLine)
                    Title(text: day.mysteries.title, size: 23).padding(.top, 5)
                    VStack(spacing: 0) {
                        ForEach(Array(day.mysteries.names.prefix(7).enumerated()), id: \.offset) { index, name in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(RomanNumeral.of(index + 1))
                                    .font(WidgetFonts.cinzelSemiBold(10))
                                    .foregroundStyle(WidgetColors.gold)
                                    .frame(width: 18, alignment: .leading)
                                Text(name)
                                    .font(WidgetFonts.garamond(16))
                                    .foregroundStyle(WidgetColors.cream)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, day.mysteries.names.count > 5 ? 5 : 7.5)
                            .overlay(alignment: .top) {
                                Rectangle().fill(WidgetColors.gold.opacity(0.18)).frame(height: 0.5)
                            }
                        }
                    }
                    .padding(.top, 12)
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
        }
    }

    private func lock(_ day: WidgetSnapshot.Day) -> some View {
        LockRectangle(title: day.mysteries.title, lines: [day.todayLine, day.mysteries.firstLine])
    }
}

// MARK: - 2 Continue Your Rosary

struct ContinueRosaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ContinueRosary", provider: LumenTimeline()) { entry in
            ContinueRosaryView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.continue.name", tableName: "Widgets"))
        .description(Text("widget.gallery.continue.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct ContinueRosaryView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, let rosary = snapshot.rosaryLeftOff(at: entry.date) {
                switch family {
                case .systemMedium: medium(rosary, labels: snapshot.labels)
                case .accessoryCircular: circle(rosary)
                case .accessoryRectangular:
                    LockRectangle(title: rosary.title, lines: [rosary.placeLine, rosary.beadLine])
                default: small(rosary, labels: snapshot.labels)
                }
            } else if let snapshot = entry.snapshot, let day = entry.day {
                // No Rosary open today: today's, to begin
                switch family {
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        LumenMark(white: true).frame(width: 18, height: 27)
                    }
                case .accessoryRectangular:
                    LockRectangle(title: day.mysteries.title, lines: [snapshot.labels.todaysRosary, day.mysteries.firstLine])
                case .systemMedium: beginMedium(day, labels: snapshot.labels)
                default: begin(day, labels: snapshot.labels)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.continueRosary)
        .lumenBackground()
    }

    private func small(_ rosary: WidgetSnapshot.Rosary, labels: WidgetSnapshot.Labels) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                LumenMark().frame(width: 15, height: 22)
                Kicker(text: labels.continueWord)
            }
            Title(text: rosary.shortTitle).padding(.top, 10)
            Text(rosary.placeLine)
                .font(WidgetFonts.garamond(15))
                .foregroundStyle(WidgetColors.cream)
                .padding(.top, 3)
            Spacer(minLength: 0)
            ItalicLine(text: rosary.beadLine, lines: 1).padding(.bottom, 8)
            DecadeBeads(rosary: rosary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func medium(_ rosary: WidgetSnapshot.Rosary, labels: WidgetSnapshot.Labels) -> some View {
        ZStack(alignment: .topLeading) {
            HalfPainting(name: rosary.painting)
            BesidePainting {
                Kicker(text: "\(labels.continueWord) · \(rosary.shortTitle)")
                // Three lines a step down, so a long name stands whole (design)
                Title(text: rosary.mysteryName, size: 17, lines: 3).padding(.top, 8)
                Spacer(minLength: 0)
                // Two lines, as the small one sets them, never "of 10" alone
                Text(rosary.placeLine)
                    .font(WidgetFonts.garamond(15))
                    .foregroundStyle(WidgetColors.cream)
                ItalicLine(text: rosary.beadLine, lines: 1).padding(.top, 2).padding(.bottom, 8)
                DecadeBeads(rosary: rosary)
            }
        }
    }

    /// Nothing open, medium: the medium pattern the other widgets wear,
    /// the painting at the left and the words beside it (design)
    private func beginMedium(_ day: WidgetSnapshot.Day, labels: WidgetSnapshot.Labels) -> some View {
        ZStack(alignment: .topLeading) {
            HalfPainting(name: day.mysteries.paintings.first)
            BesidePainting {
                Kicker(text: labels.todaysRosary)
                Title(text: day.mysteries.title, size: 23).padding(.top, 10)
                Spacer(minLength: 0)
                GoLink(text: labels.begin)
            }
        }
    }

    private func begin(_ day: WidgetSnapshot.Day, labels: WidgetSnapshot.Labels) -> some View {
        ZStack(alignment: .bottomLeading) {
            FullPainting(name: day.mysteries.paintings.first)
            VStack(alignment: .leading, spacing: 5) {
                Kicker(text: labels.todaysRosary)
                Title(text: day.mysteries.title, size: 16)
                GoLink(text: labels.begin).padding(.top, 3)
            }
            .padding(16)
        }
    }

    private func circle(_ rosary: WidgetSnapshot.Rosary) -> some View {
        let bead = max(0, min(rosary.beadIndex ?? 0, rosary.hailMarys))
        return ZStack {
            AccessoryWidgetBackground()
            ProgressRing(fraction: Double(bead) / Double(rosary.hailMarys))
            VStack(spacing: 1) {
                Text("\(rosary.mysteryIndex + 1)")
                    .font(.system(size: 21, weight: .bold, design: .default))
                Text("\(bead)/\(rosary.hailMarys)")
                    .font(.system(size: 9, weight: .semibold))
                    .opacity(0.85)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(rosary.title), \(rosary.placeLine), \(rosary.beadLine)"))
    }
}

/// The ten Hail Marys of the decade (seven in the chaplet): those prayed
/// in gold, the one under the hand ringed and lit
struct DecadeBeads: View {
    let rosary: WidgetSnapshot.Rosary

    var body: some View {
        let bead = rosary.beadIndex ?? 0
        HStack(spacing: 4.5) {
            ForEach(1...rosary.hailMarys, id: \.self) { index in
                Group {
                    if index < bead {
                        Circle().fill(WidgetColors.goldGradient)
                    } else if index == bead {
                        Circle()
                            .strokeBorder(WidgetColors.goldLight, lineWidth: 1.5)
                            .shadow(color: WidgetColors.goldLight.opacity(0.6), radius: 3)
                    } else {
                        Circle().strokeBorder(WidgetColors.gold.opacity(0.55), lineWidth: 1.2)
                    }
                }
                .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

enum RomanNumeral {
    static func of(_ number: Int) -> String {
        ["I", "II", "III", "IV", "V", "VI", "VII"][max(0, min(number - 1, 6))]
    }
}
