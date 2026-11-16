//
//  DevotionWidgets.swift
//  Lumen Viae Widgets
//
//  6 A Word for Today, 7 Prayer Record, 8 Hours of Prayer and
//  9 Consecration.
//

import SwiftUI
import WidgetKit

// MARK: - 6 A Word for Today

struct WordForTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WordForToday", provider: LumenTimeline()) { entry in
            WordForTodayView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.word.name", tableName: "Widgets"))
        .description(Text("widget.gallery.word.description", tableName: "Widgets"))
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct WordForTodayView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let day = entry.day, let labels = entry.snapshot?.labels {
                switch family {
                case .accessoryRectangular:
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.quote)
                            .font(.system(size: 13.5).italic())
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                        Text(day.quoteAuthor)
                            .font(.system(size: 11.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                case .systemLarge: large(day, labels: labels)
                default: medium(day, labels: labels)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.home)
        .lumenBackground()
    }

    private func medium(_ day: WidgetSnapshot.Day, labels: WidgetSnapshot.Labels) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                LumenMark().frame(width: 15, height: 22)
                Kicker(text: labels.aWordForToday)
            }
            Spacer(minLength: 6)
            Text(day.quote)
                .font(WidgetFonts.garamondItalic(17))
                .foregroundStyle(WidgetColors.cream)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Kicker(text: day.quoteAuthor, color: WidgetColors.muted).padding(.top, 9)
        }
        .padding(EdgeInsets(top: 18, leading: 22, bottom: 18, trailing: 22))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func large(_ day: WidgetSnapshot.Day, labels: WidgetSnapshot.Labels) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ZStack {
                    if let image = WidgetPaintings.image(WidgetSnapshot.wordForTodayPainting) {
                        FocalImage(image: image, focusY: 0.3)
                            .frame(width: proxy.size.width, height: proxy.size.height * 0.5)
                    }
                    LinearGradient(
                        stops: [
                            .init(color: WidgetColors.ground.opacity(0), location: 0.45),
                            .init(color: WidgetColors.ground.opacity(0.9), location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom)
                }
                .frame(height: proxy.size.height * 0.5)
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: proxy.size.height * 0.5 - 22)
                    Kicker(text: labels.aWordForToday)
                    Text("\u{201C}")
                        .font(WidgetFonts.cinzel(34))
                        .foregroundStyle(WidgetColors.gold)
                        .frame(height: 16, alignment: .top)
                        .padding(.top, 16)
                    Text(day.quote)
                        .font(WidgetFonts.garamondItalic(21))
                        .foregroundStyle(WidgetColors.cream)
                        .lineSpacing(3)
                        .lineLimit(5)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 4)
                    Kicker(text: day.quoteAuthor, color: WidgetColors.muted)
                }
                .padding(22)
            }
        }
    }
}

// MARK: - 7 Prayer Record

struct PrayerRecordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PrayerRecord", provider: LumenTimeline()) { entry in
            PrayerRecordView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.record.name", tableName: "Widgets"))
        .description(Text("widget.gallery.record.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct PrayerRecordView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let record = entry.prayerDay?.record, let labels = entry.snapshot?.labels {
                switch family {
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        VStack(spacing: 0) {
                            Image(systemName: "flame.fill").font(.system(size: 17)).widgetAccentable()
                            Text("\(record.daysInARow)").font(.system(size: 19, weight: .bold))
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(record.line))
                default:
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            Flame(lit: record.prayedToday)
                            Kicker(text: labels.currentStreak, size: 8.5)
                        }
                        // A size under the others, and never closer than 8 pt
                        // to the week: PRAY TODAY TO BEGIN ran into it
                        Title(text: record.line, size: 17).padding(.top, 10)
                        Spacer(minLength: 8)
                        WeekBeads(record: record, initials: labels.weekInitials)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.record)
        .lumenBackground()
    }
}

/// The streak's ember: quieter until the day is lit
struct Flame: View {
    var lit: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [WidgetColors.goldLight.opacity(lit ? 0.35 : 0.18), WidgetColors.gold.opacity(0.08)],
                    center: UnitPoint(x: 0.5, y: 0.6), startRadius: 0, endRadius: 20))
                .overlay(Circle().strokeBorder(WidgetColors.gold.opacity(0.4), lineWidth: 1))
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundStyle(WidgetColors.goldGradient)
                .opacity(lit ? 1 : 0.6)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }
}

/// Sunday to Saturday: each day's initial under its bead, prayed in
/// gold, today ringed
struct WeekBeads: View {
    let record: WidgetSnapshot.Record
    let initials: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 4) {
                    Group {
                        if record.week[safe: index] == true {
                            Circle().fill(WidgetColors.goldGradient)
                        } else if index == record.todayInWeek {
                            Circle().strokeBorder(WidgetColors.goldLight, lineWidth: 1.5)
                        } else {
                            Circle().strokeBorder(WidgetColors.muted.opacity(0.5), lineWidth: 1.2)
                        }
                    }
                    .frame(width: 13, height: 13)
                    Text(initials[safe: index] ?? "")
                        .font(WidgetFonts.cinzelSemiBold(8.5))
                        .foregroundStyle(WidgetColors.muted)
                }
                if index < 6 { Spacer(minLength: 0) }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - 8 Hours of Prayer

struct HoursOfPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HoursOfPrayer", provider: LumenTimeline()) { entry in
            HoursOfPrayerView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.hours.name", tableName: "Widgets"))
        .description(Text("widget.gallery.hours.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct HoursOfPrayerView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let hour = entry.snapshot?.hour(at: entry.date), let labels = entry.snapshot?.labels {
                // The hour by its plain name, the Church's beside NOW, as the app names it
                switch family {
                case .systemMedium:
                    ZStack(alignment: .topLeading) {
                        HalfPainting(name: hour.painting)
                        BesidePainting {
                            // The small one's label on one line: NOW · SEXT (design)
                            HStack(spacing: 6) {
                                LumenMark().frame(width: 15, height: 22)
                                Kicker(text: "\(labels.now) · \(hour.churchName)")
                            }
                            Spacer(minLength: 0)
                            Title(text: hour.name, size: 23)
                            ItalicLine(text: hour.firstLine, size: 16).padding(.top, 6)
                        }
                    }
                default:
                    ZStack(alignment: .bottomLeading) {
                        FullPainting(name: hour.painting, strongFade: true)
                        VStack(alignment: .leading, spacing: 0) {
                            // The label and the name alone, low over the fade
                            Kicker(text: "\(labels.now) · \(hour.churchName)")
                            Title(text: hour.name).padding(.top, 5)
                        }
                        .padding(16)
                    }
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.officeNow)
        .lumenBackground()
    }
}

// MARK: - 9 Consecration

struct ConsecrationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Consecration", provider: LumenTimeline()) { entry in
            ConsecrationWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.consecration.name", tableName: "Widgets"))
        .description(Text("widget.gallery.consecration.description", tableName: "Widgets"))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct ConsecrationWidgetView: View {
    let entry: LumenEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let day = entry.day, let labels = entry.snapshot?.labels {
                if let consecration = day.consecration, !consecration.isCompleted {
                    if consecration.hasBegun {
                        underWay(consecration, labels: labels)
                    } else {
                        waiting(consecration, labels: labels)
                    }
                } else {
                    notChosen(day.consecration, labels: labels)
                }
            } else {
                OpenTheApp()
            }
        }
        .widgetURL(LumenLink.consecrationToday)
        .lumenBackground()
    }

    @ViewBuilder
    private func underWay(_ consecration: WidgetSnapshot.Consecration, labels: WidgetSnapshot.Labels) -> some View {
        switch family {
        case .accessoryRectangular:
            LockRectangle(title: consecration.dayLine, lines: [labels.consecration, consecration.dayTitle])
        case .systemMedium:
            ZStack(alignment: .topLeading) {
                HalfPainting(name: consecration.painting)
                BesidePainting {
                    Kicker(text: labels.consecration)
                    Title(text: consecration.dayLine, size: 23).padding(.top, 5)
                    Spacer(minLength: 0)
                    ItalicLine(text: consecration.dayTitle, size: 16).padding(.bottom, 10)
                    DayTicks(consecration: consecration)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: labels.consecration)
                Title(text: consecration.dayLine).padding(.top, 5)
                Spacer(minLength: 0)
                ItalicLine(text: consecration.dayTitle).padding(.bottom, 10)
                DayTicks(consecration: consecration)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func waiting(_ consecration: WidgetSnapshot.Consecration, labels: WidgetSnapshot.Labels) -> some View {
        switch family {
        case .accessoryRectangular:
            LockRectangle(title: labels.consecrationTitle, lines: [consecration.beginsLine, consecration.feastLine])
        default:
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    LumenMark().frame(width: 15, height: 22)
                    Kicker(text: labels.consecration)
                }
                Spacer(minLength: 0)
                Title(text: consecration.beginsLine, size: family == .systemMedium ? 19 : 16)
                ItalicLine(text: consecration.feastLine, size: 13.5, color: WidgetColors.muted).padding(.top, 5)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func notChosen(_ consecration: WidgetSnapshot.Consecration?, labels: WidgetSnapshot.Labels) -> some View {
        let made = consecration?.isCompleted == true
        let title = made ? labels.consecrated : labels.consecrationTitle
        switch family {
        case .accessoryRectangular:
            LockRectangle(title: title, lines: made ? [] : [labels.consecrationInvite])
        default:
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    LumenMark().frame(width: 15, height: 22)
                    Kicker(text: labels.consecration)
                }
                Spacer(minLength: 0)
                Title(text: title, size: 16)
                if !made {
                    ItalicLine(text: labels.consecrationInvite, size: 13.5, color: WidgetColors.muted, lines: 3).padding(.top, 5)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// The 33 days as ticks: prayed in gold, today an outline, the rest quiet
struct DayTicks: View {
    let consecration: WidgetSnapshot.Consecration

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...33, id: \.self) { day in
                let shape = RoundedRectangle(cornerRadius: 1.5)
                Group {
                    if day < consecration.dayNumber || (day == consecration.dayNumber && consecration.todayPrayed) {
                        shape.fill(WidgetColors.gold)
                    } else if day == consecration.dayNumber {
                        shape.strokeBorder(WidgetColors.goldLight, lineWidth: 1.2)
                    } else {
                        shape.fill(WidgetColors.muted.opacity(0.3))
                    }
                }
                .frame(height: 7)
            }
        }
        .accessibilityHidden(true)
    }
}
