// Frames a simulator screenshot for the App Store: the navy ground, a
// two-line headline in EB Garamond, a gold line beneath it, and the
// screen inside an iPhone, run off the foot of the image. Written to
// match the 3.0 set, so every release's screenshots read as one set.
//
//   swift Tools/AppStore/screenshots/frame.swift <raw.png> <out.png> "<line 1>|<line 2>" "<subline>"
//
// The simulator's capture carries the Dynamic Island itself.
// The output is 1320x2868, opaque (App Store Connect refuses alpha).
// The raw capture should be an iPhone 17 Pro Max's (1320x2868); any
// portrait capture is scaled to the screen.

import AppKit
import CoreText
import Foundation
import ImageIO

let width = 1320
let height = 2868

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// Sampled from the 3.0 set's pixels
let groundTop = color(0x151530)
let groundMid = color(0x0C0C1A)
let groundFoot = color(0x050509)
let headlineInk = color(0xF6F1E4)
let sublineInk = color(0xC9B98F)

// The phone, in the output's pixels (top-left origin)
let phone = CGRect(x: 179, y: 741, width: 962, height: 2025)
let phoneRadius: CGFloat = 140
let rim: CGFloat = 12
let screen = CGRect(x: 211, y: 773, width: 898, height: 1951)
let screenRadius: CGFloat = 112

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(("frame: " + message + "\n").data(using: .utf8)!)
    exit(1)
}

let args = CommandLine.arguments
guard args.count == 5 else { fail("usage: frame.swift <raw.png> <out.png> \"<line 1>|<line 2>\" \"<subline>\"") }
let (rawPath, outPath, headline, subline) = (args[1], args[2], args[3], args[4])

// The app's own faces
let fonts = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .appendingPathComponent("../../../app/Resources/Fonts").standardized
for name in ["EBGaramond-Regular.ttf", "EBGaramond-Medium.ttf"] {
    CTFontManagerRegisterFontsForURL(fonts.appendingPathComponent(name) as CFURL, .process, nil)
}

guard let rawImage = NSImage(contentsOfFile: rawPath),
    let raw = rawImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else { fail("cannot read \(rawPath)") }

let ctx = CGContext(
    data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Draw in top-left coordinates
ctx.translateBy(x: 0, y: CGFloat(height))
ctx.scaleBy(x: 1, y: -1)

// The ground
let ground = CGGradient(
    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [groundTop, groundTop, groundMid, groundFoot, groundFoot] as CFArray,
    locations: [0, 0.17, 0.49, 0.75, 1])!
ctx.drawLinearGradient(ground, start: .zero, end: CGPoint(x: 0, y: height), options: [])

// Text, centred on a baseline
func drawCentred(_ text: String, font: String, size: CGFloat, ink: CGColor, baseline: CGFloat, kern: CGFloat = 0) {
    let ctFont = CTFontCreateWithName(font as CFString, size, nil)
    let attributed = NSAttributedString(
        string: text,
        attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): ctFont,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink,
            NSAttributedString.Key(kCTKernAttributeName as String): kern,
        ])
    let line = CTLineCreateWithAttributedString(attributed)
    let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
    if lineWidth > Double(width) - 80 { fail("\"\(text)\" is too wide (\(Int(lineWidth))px); shorten it") }
    ctx.saveGState()
    ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    ctx.textPosition = CGPoint(x: (CGFloat(width) - CGFloat(lineWidth)) / 2, y: baseline)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

let lines = headline.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
guard lines.count == 2 else { fail("the headline is two lines, split with |") }
drawCentred(lines[0], font: "EBGaramond-Regular", size: 152, ink: headlineInk, baseline: 272)
drawCentred(lines[1], font: "EBGaramond-Regular", size: 152, ink: headlineInk, baseline: 445)
drawCentred(subline, font: "EBGaramond-Regular", size: 60, ink: sublineInk, baseline: 563)

// The phone: a soft shadow, the titanium rim, side buttons, the black bezel
func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 30), blur: 90, color: color(0x000000, 0.6))
ctx.addPath(rounded(phone, phoneRadius))
ctx.setFillColor(color(0x2A2A2D))
ctx.fillPath()
ctx.restoreGState()

let buttons: [CGRect] = [
    CGRect(x: phone.minX - 8, y: 1160, width: 10, height: 86),  // action
    CGRect(x: phone.minX - 8, y: 1318, width: 10, height: 150),  // volume up
    CGRect(x: phone.minX - 8, y: 1512, width: 10, height: 150),  // volume down
    CGRect(x: phone.maxX - 2, y: 1372, width: 10, height: 230),  // side
]
for b in buttons {
    ctx.addPath(rounded(b, 4))
    ctx.setFillColor(color(0x4A4A4E))
    ctx.fillPath()
}

ctx.saveGState()
ctx.addPath(rounded(phone, phoneRadius))
ctx.clip()
let metal = CGGradient(
    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [color(0x8A898C), color(0x4A4A4E), color(0x6E6D70), color(0x3E3E42)] as CFArray,
    locations: [0, 0.35, 0.7, 1])!
ctx.drawLinearGradient(
    metal, start: CGPoint(x: phone.minX, y: phone.minY),
    end: CGPoint(x: phone.maxX, y: phone.maxY), options: [])
ctx.restoreGState()
ctx.addPath(rounded(phone.insetBy(dx: rim / 2, dy: rim / 2), phoneRadius - rim / 2))
ctx.setStrokeColor(color(0x9A999A, 0.5))
ctx.setLineWidth(1.5)
ctx.strokePath()
ctx.addPath(rounded(phone.insetBy(dx: rim, dy: rim), phoneRadius - rim))
ctx.setFillColor(color(0x000000))
ctx.fillPath()

// The screen
ctx.saveGState()
ctx.addPath(rounded(screen, screenRadius))
ctx.clip()
let scale = screen.width / CGFloat(raw.width)
let drawn = CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: CGFloat(raw.height) * scale)
ctx.saveGState()
ctx.translateBy(x: drawn.minX, y: drawn.maxY)
ctx.scaleBy(x: 1, y: -1)
ctx.interpolationQuality = .high
ctx.draw(raw, in: CGRect(origin: .zero, size: drawn.size))
ctx.restoreGState()
ctx.restoreGState()

guard let out = ctx.makeImage() else { fail("could not render") }
// Through ImageIO, so the PNG carries its sRGB profile and the ground
// shows as drawn
guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outPath) as CFURL, "public.png" as CFString, 1, nil)
else { fail("cannot write \(outPath)") }
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { fail("could not encode \(outPath)") }
