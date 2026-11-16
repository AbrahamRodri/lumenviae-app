//
//  WidgetStyle.swift
//  Lumen Viae Widgets
//
//  The widgets' look, drawn to design's frames (reports/design/widgets,
//  Abraham's Yes 16 Nov 2026): the app's dark ground on any wallpaper,
//  gold kickers in Cinzel, titles in Cinzel, lines in EB Garamond, the
//  paintings dissolving into the ground.
//

import SwiftUI
import UIKit
import WidgetKit

enum WidgetColors {
    static let gold = Color(red: 0xE3 / 255, green: 0xBC / 255, blue: 0x5B / 255)
    static let goldLight = Color(red: 0xF3 / 255, green: 0xD8 / 255, blue: 0x9A / 255)
    static let goldPale = Color(red: 0xFF / 255, green: 0xF3 / 255, blue: 0xD0 / 255)
    static let cream = Color(red: 0xF2 / 255, green: 0xEF / 255, blue: 0xE6 / 255)
    static let muted = Color(red: 0x8B / 255, green: 0x8B / 255, blue: 0xA5 / 255)
    static let italic = Color(red: 0xC9 / 255, green: 0xC6 / 255, blue: 0xD6 / 255)
    static let ground = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x14 / 255)
    static let groundMid = Color(red: 0x0F / 255, green: 0x0F / 255, blue: 0x1C / 255)
    static let groundTop = Color(red: 0x1A / 255, green: 0x18 / 255, blue: 0x36 / 255)
    static let sideShade = Color(red: 0x0D / 255, green: 0x0D / 255, blue: 0x19 / 255)

    static let goldGradient = LinearGradient(colors: [goldLight, gold], startPoint: .top, endPoint: .bottom)

    static func hex(_ hex: String) -> Color {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(digits, radix: 16) ?? 0xEDE7D6
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }
}

enum WidgetFonts {
    /// The widget registers the app's faces itself: the extension is a
    /// process of its own
    static let registered: Void = {
        for name in ["Cinzel-Regular", "Cinzel-SemiBold", "EBGaramond-Regular", "EBGaramond-Italic", "EBGaramond-Medium"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    static func cinzel(_ size: CGFloat) -> Font { _ = registered; return .custom("Cinzel-Regular", fixedSize: size) }
    static func cinzelSemiBold(_ size: CGFloat) -> Font { _ = registered; return .custom("Cinzel-SemiBold", fixedSize: size) }
    static func garamond(_ size: CGFloat) -> Font { _ = registered; return .custom("EBGaramond-Regular", fixedSize: size) }
    static func garamondItalic(_ size: CGFloat) -> Font { _ = registered; return .custom("EBGaramond-Italic", fixedSize: size) }
}

// MARK: - Type

/// The small gold capitals over a widget: "TODAY · MONDAY"
struct Kicker: View {
    let text: String
    var color: Color = WidgetColors.gold
    var size: CGFloat = 9.5

    var body: some View {
        Text(text.uppercased())
            .font(WidgetFonts.cinzelSemiBold(size))
            .tracking(size * 0.18)
            .foregroundStyle(color)
            .lineLimit(2)
    }
}

/// A widget's title in Cinzel: 16, 19 or 23 points
struct Title: View {
    let text: String
    var size: CGFloat = 19
    var color: Color = WidgetColors.cream
    var lines = 2

    /// Never cut a name short (design): the title keeps the height its
    /// lines need, so it wraps rather than being squeezed to one line and
    /// cut; only a name too long for its lines is scaled
    var body: some View {
        Text(text)
            .font(WidgetFonts.cinzel(size))
            .tracking(size * 0.01)
            .foregroundStyle(color)
            .lineLimit(lines)
            .minimumScaleFactor(0.75)
            .lineSpacing(size * 0.02)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A line in EB Garamond's italic
struct ItalicLine: View {
    let text: String
    var size: CGFloat = 14.5
    var color: Color = WidgetColors.italic
    var lines = 2

    var body: some View {
        Text(text)
            .font(WidgetFonts.garamondItalic(size))
            .foregroundStyle(color)
            .lineLimit(lines)
            .minimumScaleFactor(0.85)
    }
}

/// A line shown only where it fits whole on one line, and left out
/// rather than cut (design: no ellipsis on Today's Mysteries)
struct WholeLineOrNothing: View {
    let text: String
    var size: CGFloat = 14.5

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(text)
                .font(WidgetFonts.garamondItalic(size))
                .foregroundStyle(WidgetColors.italic)
                .lineLimit(1)
                .fixedSize()
            Color.clear.frame(width: 0, height: 0)
        }
    }
}

/// "BEGIN ›", the light-gold way in
struct GoLink: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Text(text.uppercased())
                .font(WidgetFonts.cinzelSemiBold(9.5))
                .tracking(9.5 * 0.16)
            Image(systemName: "chevron.right")
                .font(.system(size: 6.5, weight: .bold))
        }
        .foregroundStyle(WidgetColors.goldLight)
    }
}

// MARK: - The mark

/// The app's mark, the arch and its star, from the logo suite
struct LumenMark: View {
    var white = false

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 60, size.height / 98)
            let offset = CGPoint(x: (size.width - 60 * scale) / 2, y: (size.height - 98 * scale) / 2)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: offset.x + (x - 20) * scale, y: offset.y + y * scale)
            }
            var arch = Path()
            arch.move(to: p(25, 94))
            arch.addLine(to: p(25, 48))
            arch.addArc(center: p(75, 48), radius: 50 * scale, startAngle: .degrees(180), endAngle: .degrees(240), clockwise: false)
            arch.addArc(center: p(25, 48), radius: 50 * scale, startAngle: .degrees(300), endAngle: .degrees(360), clockwise: false)
            arch.addLine(to: p(75, 94))
            var star = Path()
            star.move(to: p(50, 18))
            star.addQuadCurve(to: p(63.5, 40), control: p(51.7, 38.3))
            star.addQuadCurve(to: p(50, 91), control: p(52.4, 42.4))
            star.addQuadCurve(to: p(36.5, 40), control: p(47.6, 42.4))
            star.addQuadCurve(to: p(50, 18), control: p(48.3, 38.3))
            star.closeSubpath()
            let shading: GraphicsContext.Shading = white
                ? .color(.white)
                : .linearGradient(
                    Gradient(stops: [
                        .init(color: WidgetColors.goldPale, location: 0),
                        .init(color: WidgetColors.goldLight, location: 0.3),
                        .init(color: WidgetColors.gold, location: 1),
                    ]),
                    startPoint: CGPoint(x: 0, y: offset.y), endPoint: CGPoint(x: 0, y: offset.y + 96 * scale))
            context.stroke(arch, with: shading, lineWidth: (white ? 7 : 6) * scale)
            context.fill(star, with: shading)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Grounds and paintings

/// The app's ground: a radial glow from the top of the card
struct WidgetGround: View {
    var atTheHour = false

    var body: some View {
        GeometryReader { proxy in
            RadialGradient(
                stops: atTheHour
                    ? [
                        .init(color: Color(red: 0x3A / 255, green: 0x30 / 255, blue: 0x10 / 255), location: 0),
                        .init(color: Color(red: 0x1A / 255, green: 0x16 / 255, blue: 0x08 / 255), location: 0.6),
                        .init(color: WidgetColors.ground, location: 1),
                    ]
                    : [
                        .init(color: WidgetColors.groundTop, location: 0),
                        .init(color: WidgetColors.groundMid, location: 0.55),
                        .init(color: WidgetColors.ground, location: 1),
                    ],
                center: .top,
                startRadius: 0,
                endRadius: max(proxy.size.width, proxy.size.height) * 1.05
            )
        }
    }
}

enum WidgetPaintings {
    /// A painting the app copied beside the snapshot, or nil
    static func image(_ name: String?) -> UIImage? {
        guard let name, !name.isEmpty, let folder = SnapshotReader.paintingsFolder else { return nil }
        return UIImage(contentsOfFile: folder.appendingPathComponent("\(name).jpg").path)
    }
}

/// A painting filling its frame, cut about a point `focusY` down it, as
/// the app's `FocalFill` cuts one
struct FocalImage: View {
    let image: UIImage
    var focusY: CGFloat = 0.25

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.size
            let scale = max(frame.width / max(image.size.width, 1), frame.height / max(image.size.height, 1))
            let drawn = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let spareY = drawn.height - frame.height
            let y = -min(max(drawn.height * focusY - frame.height / 2, 0), spareY)
            Image(uiImage: image)
                .resizable()
                .frame(width: drawn.width, height: drawn.height)
                .offset(x: -(drawn.width - frame.width) / 2, y: y)
        }
        .clipped()
    }
}

/// A painting filling the card, its foot dissolving into the ground
struct FullPainting: View {
    let name: String?
    var focusY: CGFloat = 0.25
    /// Clear at a quarter down, mostly dark by the middle, solid at the
    /// foot, so cream reads over any painting, the brightest included
    /// (design, the Hours small)
    var strongFade = false

    var body: some View {
        ZStack {
            if let image = WidgetPaintings.image(name) {
                FocalImage(image: image, focusY: focusY)
            }
            LinearGradient(
                stops: strongFade
                    ? [
                        .init(color: WidgetColors.ground.opacity(0), location: 0.25),
                        .init(color: WidgetColors.ground.opacity(0.85), location: 0.5),
                        .init(color: WidgetColors.ground, location: 1),
                    ]
                    : [
                        .init(color: WidgetColors.ground.opacity(0.05), location: 0.2),
                        .init(color: WidgetColors.ground.opacity(0.72), location: 0.62),
                        .init(color: WidgetColors.ground.opacity(0.96), location: 1),
                    ],
                startPoint: .top, endPoint: .bottom)
        }
    }
}

/// A painting down the leading 46% of a medium card, fading into the
/// ground beneath the words
struct HalfPainting: View {
    let name: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                if let image = WidgetPaintings.image(name) {
                    FocalImage(image: image, focusY: 0.22)
                        .frame(width: proxy.size.width * 0.46, height: proxy.size.height)
                }
                LinearGradient(
                    stops: [
                        .init(color: WidgetColors.sideShade.opacity(0), location: 0.30),
                        .init(color: WidgetColors.sideShade, location: 0.47),
                    ],
                    startPoint: .leading, endPoint: .trailing)
            }
        }
    }
}

/// The words beside a half painting, in the trailing part of the card
struct BesidePainting<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 0) { content }
                .padding(EdgeInsets(top: 16, leading: 6, bottom: 16, trailing: 16))
                .frame(width: proxy.size.width * 0.54, height: proxy.size.height, alignment: .topLeading)
                .offset(x: proxy.size.width * 0.46)
        }
    }
}

extension View {
    /// The app's ground behind a widget, the system's own behind an
    /// accessory widget on the Lock Screen
    func lumenBackground(atTheHour: Bool = false) -> some View {
        containerBackground(for: .widget) { WidgetGround(atTheHour: atTheHour) }
    }
}
