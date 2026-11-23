//
//  WidgetParts.swift
//  Lumen Viae Widgets
//
//  Pieces several widgets share: the links, the Lock Screen's forms, the
//  ring, and what a widget shows before the app has written anything.
//

import SwiftUI
import WidgetKit

/// The app's `lumenviae://` links, as `AppRouter.destination(of:)` reads them
enum LumenLink {
    static let home = URL(string: "lumenviae://home")!
    static let todaysMysteries = URL(string: "lumenviae://rosary/today")!
    static let continueRosary = URL(string: "lumenviae://rosary/continue")!
    static let missalToday = URL(string: "lumenviae://missal/today")!
    static let angelus = URL(string: "lumenviae://prayer/angelus")!
    static let record = URL(string: "lumenviae://record")!
    static let officeNow = URL(string: "lumenviae://office/now")!
    static let consecrationToday = URL(string: "lumenviae://consecration/today")!

    static func novena(_ id: String?) -> URL {
        guard let id, let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "lumenviae://novena/\(encoded)") else { return home }
        return url
    }
}

/// A Lock Screen rectangle: the mark and a bold first line, then up to
/// two lines, in the system's face and the Lock Screen's tint
struct LockRectangle<Footer: View>: View {
    let title: String
    let lines: [String]
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 5) {
                LumenMark(white: true).frame(width: 10, height: 15)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .widgetAccentable()
            }
            ForEach(Array(lines.filter { !$0.isEmpty }.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .opacity(0.82)
            }
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

extension LockRectangle where Footer == EmptyView {
    init(title: String, lines: [String]) {
        self.init(title: title, lines: lines) { EmptyView() }
    }
}

/// A ring round a Lock Screen circle
struct ProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.28), lineWidth: 5)
            Circle()
                .trim(from: 0, to: max(0, min(fraction, 1)))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
        .padding(2.5)
    }
}

/// Before the app has written a snapshot (a widget added before the app
/// was opened): the mark and a line asking that it be opened
struct OpenTheApp: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("widget.openApp", tableName: "Widgets")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                LumenMark(white: true).frame(width: 18, height: 27)
            }
        case .accessoryRectangular:
            HStack(spacing: 6) {
                LumenMark(white: true).frame(width: 12, height: 18)
                Text("widget.openApp", tableName: "Widgets")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(spacing: 10) {
                LumenMark().frame(width: 22, height: 34)
                Text("widget.openApp", tableName: "Widgets")
                    .font(WidgetFonts.garamondItalic(14.5))
                    .foregroundStyle(WidgetColors.italic)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
