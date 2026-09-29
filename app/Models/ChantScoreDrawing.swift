//
//  ChantScoreDrawing.swift
//  Lumen Viae
//
//  A chant's engraved score as the app draws it. Verbum Gloriae engrave
//  their scores as SVG; Tools/Chants rewrites each one as the ordered
//  drawing operations it is made of — fills in ink and in red, the white
//  shapes that erase what lies under them, a few stroked staff lines —
//  and ships them DEFLATE-compressed (`<file>.lvscore`). The app replays
//  them on a Canvas, so a score is vector at any zoom and takes the page's
//  own colours: the notes in cream, the initials in the rubric red.
//
//  Why not the asset catalog: it stores SVG uncompressed (the scores came
//  to 30 MB there against 6.6 MB here), CoreSVG would not read every one,
//  and a template image takes one colour where a score needs two.
//
//  The file, once inflated, is lines of text:
//
//      LVSCORE 1
//      <min-x> <min-y> <width> <height>       the engraving's viewBox
//      I <path>|<path>|…                      fill in ink
//      R <path>|…                             fill in red
//      W <path>|…                             erase (a white shape)
//      S<width> <path>|…  /  T<width> …       stroke in ink / in red
//
//  in the order the engraving lays them down. Each <path> is SVG path
//  data, parsed on its own because its relative moves start from its own
//  origin.
//

import Foundation
import CoreGraphics

nonisolated struct ChantScoreDrawing: @unchecked Sendable {

    enum Ink { case ink, rubric }

    enum Operation {
        case fill(CGPath, Ink)
        case erase(CGPath)
        case stroke(CGPath, Ink, CGFloat)
    }

    /// The engraving's viewBox, in its own units
    let bounds: CGRect
    let operations: [Operation]

    /// The bundled score, inflated and parsed. Nil if it is missing or not
    /// a score this build can read.
    static func load(file: String) -> ChantScoreDrawing? {
        guard let url = Bundle.main.url(forResource: file, withExtension: "lvscore"),
              let packed = try? Data(contentsOf: url),
              let inflated = try? (packed as NSData).decompressed(using: .zlib),
              let text = String(data: inflated as Data, encoding: .utf8)
        else { return nil }
        return parse(text)
    }

    static func parse(_ text: String) -> ChantScoreDrawing? {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: true)[...]
        guard lines.popFirst() == "LVSCORE 1", let box = lines.popFirst() else { return nil }
        let v = box.split(separator: " ").compactMap { Double($0) }
        guard v.count == 4, v[2] > 0, v[3] > 0 else { return nil }

        var operations: [Operation] = []
        for line in lines {
            guard let space = line.firstIndex(of: " "), let kind = line.first else { continue }
            let path = CGMutablePath()
            for data in line[line.index(after: space)...].split(separator: "|") {
                SVGPathData.append(data, to: path)
            }
            switch kind {
            case "I": operations.append(.fill(path, .ink))
            case "R": operations.append(.fill(path, .rubric))
            case "W": operations.append(.erase(path))
            case "S", "T":
                let width = CGFloat(Double(line[line.index(after: line.startIndex)..<space]) ?? 1)
                operations.append(.stroke(path, kind == "T" ? .rubric : .ink, width))
            default:
                continue
            }
        }
        return ChantScoreDrawing(
            bounds: CGRect(x: v[0], y: v[1], width: v[2], height: v[3]),
            operations: operations
        )
    }
}

// MARK: - ChantScoreStore

/// Scores parsed once and kept: the biggest (the Lauda Sion, the litanies)
/// are a hundred thousand numbers, read off the main actor.
@MainActor
final class ChantScoreStore {

    static let shared = ChantScoreStore()

    private var cache: [String: ChantScoreDrawing] = [:]

    func cached(_ file: String) -> ChantScoreDrawing? {
        cache[file]
    }

    func load(_ file: String) async -> ChantScoreDrawing? {
        if let hit = cache[file] { return hit }
        let drawing = await Self.read(file)
        if let drawing { cache[file] = drawing }
        return drawing
    }

    @concurrent
    private nonisolated static func read(_ file: String) async -> ChantScoreDrawing? {
        ChantScoreDrawing.load(file: file)
    }
}

// MARK: - SVGPathData

/// SVG path data — every command, relative and absolute, arcs included —
/// appended to a CGPath.
nonisolated enum SVGPathData {

    static func append<S: StringProtocol>(_ data: S, to path: CGMutablePath) {
        var scan = PathScanner(bytes: Array(data.utf8))
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?
        var command: UInt8 = 0

        while true {
            if let next = scan.command() {
                command = next
            } else if !scan.hasNumber() || command == 0 || command == UInt8(ascii: "Z") || command == UInt8(ascii: "z") {
                break
            }
            let relative = command >= UInt8(ascii: "a")
            let origin = relative ? current : .zero
            var cubicControl: CGPoint?
            var quadControl: CGPoint?

            switch command | 0x20 {  // lowercase
            case UInt8(ascii: "m"):
                guard let p = scan.point(from: origin) else { return }
                path.move(to: p)
                current = p
                subpathStart = p
                // Further pairs after a move are lines
                command = relative ? UInt8(ascii: "l") : UInt8(ascii: "L")

            case UInt8(ascii: "l"):
                guard let p = scan.point(from: origin) else { return }
                path.addLine(to: p)
                current = p

            case UInt8(ascii: "h"):
                guard let x = scan.number() else { return }
                current = CGPoint(x: (relative ? current.x : 0) + x, y: current.y)
                path.addLine(to: current)

            case UInt8(ascii: "v"):
                guard let y = scan.number() else { return }
                current = CGPoint(x: current.x, y: (relative ? current.y : 0) + y)
                path.addLine(to: current)

            case UInt8(ascii: "c"):
                guard let c1 = scan.point(from: origin), let c2 = scan.point(from: origin),
                      let p = scan.point(from: origin) else { return }
                path.addCurve(to: p, control1: c1, control2: c2)
                cubicControl = c2
                current = p

            case UInt8(ascii: "s"):
                guard let c2 = scan.point(from: origin), let p = scan.point(from: origin) else { return }
                let c1 = lastCubicControl.map { reflect($0, about: current) } ?? current
                path.addCurve(to: p, control1: c1, control2: c2)
                cubicControl = c2
                current = p

            case UInt8(ascii: "q"):
                guard let c = scan.point(from: origin), let p = scan.point(from: origin) else { return }
                path.addQuadCurve(to: p, control: c)
                quadControl = c
                current = p

            case UInt8(ascii: "t"):
                guard let p = scan.point(from: origin) else { return }
                let c = lastQuadControl.map { reflect($0, about: current) } ?? current
                path.addQuadCurve(to: p, control: c)
                quadControl = c
                current = p

            case UInt8(ascii: "a"):
                guard let rx = scan.number(), let ry = scan.number(), let rotation = scan.number(),
                      let large = scan.flag(), let sweep = scan.flag(),
                      let p = scan.point(from: origin) else { return }
                addArc(to: path, from: current, to: p, rx: rx, ry: ry,
                       rotation: rotation, largeArc: large, sweep: sweep)
                current = p

            case UInt8(ascii: "z"):
                path.closeSubpath()
                current = subpathStart

            default:
                return
            }

            lastCubicControl = cubicControl
            lastQuadControl = quadControl
        }
    }

    private static func reflect(_ point: CGPoint, about center: CGPoint) -> CGPoint {
        CGPoint(x: 2 * center.x - point.x, y: 2 * center.y - point.y)
    }

    /// An elliptical arc as cubic curves, by the SVG specification's
    /// endpoint-to-centre conversion (Implementation Notes, F.6.5).
    private static func addArc(
        to path: CGMutablePath, from p0: CGPoint, to p1: CGPoint,
        rx rxIn: CGFloat, ry ryIn: CGFloat, rotation: CGFloat, largeArc: Bool, sweep: Bool
    ) {
        guard p0 != p1 else { return }
        var rx = abs(Double(rxIn)), ry = abs(Double(ryIn))
        guard rx > 0, ry > 0 else {
            path.addLine(to: p1)
            return
        }
        let phi = Double(rotation) * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx2 = Double(p0.x - p1.x) / 2, dy2 = Double(p0.y - p1.y) / 2
        let x1p = cosPhi * dx2 + sinPhi * dy2
        let y1p = -sinPhi * dx2 + cosPhi * dy2

        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let rx2 = rx * rx, ry2 = ry * ry
        let numerator = max(0, rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p)
        let denominator = rx2 * y1p * y1p + ry2 * x1p * x1p
        guard denominator > 0 else {
            path.addLine(to: p1)
            return
        }
        var coefficient = (numerator / denominator).squareRoot()
        if largeArc == sweep { coefficient = -coefficient }
        let cxp = coefficient * (rx * y1p / ry)
        let cyp = coefficient * -(ry * x1p / rx)
        let cx = cosPhi * cxp - sinPhi * cyp + Double(p0.x + p1.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + Double(p0.y + p1.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let length = ((ux * ux + uy * uy) * (vx * vx + vy * vy)).squareRoot()
            guard length > 0 else { return 0 }
            let a = acos(min(1, max(-1, (ux * vx + uy * vy) / length)))
            return ux * vy - uy * vx < 0 ? -a : a
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        func map(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: cx + rx * cosPhi * x - ry * sinPhi * y,
                    y: cy + rx * sinPhi * x + ry * cosPhi * y)
        }
        let segments = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let step = delta / Double(segments)
        let t = 4.0 / 3.0 * tan(step / 4)
        var theta = theta1
        for index in 0..<segments {
            let next = theta + step
            let c1 = map(cos(theta) - t * sin(theta), sin(theta) + t * cos(theta))
            let c2 = map(cos(next) + t * sin(next), sin(next) - t * cos(next))
            // Land the last segment exactly on the endpoint the data named
            let end = index == segments - 1 ? p1 : map(cos(next), sin(next))
            path.addCurve(to: end, control1: c1, control2: c2)
            theta = next
        }
    }
}

// MARK: - PathScanner

/// Reads path data a byte at a time: command letters, numbers in every
/// form the grammar allows ("-.5", "1e-3", "1.5.5" as two numbers), and
/// an arc's flags, which may be written with no separator at all.
nonisolated private struct PathScanner {
    let bytes: [UInt8]
    var index = 0

    private static let space = UInt8(ascii: " "), comma = UInt8(ascii: ","),
                       minus = UInt8(ascii: "-"), plus = UInt8(ascii: "+"),
                       dot = UInt8(ascii: "."), zero = UInt8(ascii: "0"), nine = UInt8(ascii: "9")

    private mutating func skipSeparators() {
        while index < bytes.count {
            let b = bytes[index]
            guard b == Self.space || b == Self.comma || b == 9 || b == 10 || b == 13 else { break }
            index += 1
        }
    }

    private static func isDigit(_ b: UInt8) -> Bool { b >= zero && b <= nine }

    mutating func command() -> UInt8? {
        skipSeparators()
        guard index < bytes.count else { return nil }
        let b = bytes[index] | 0x20
        // Every command letter but "e", which belongs to an exponent
        guard b >= UInt8(ascii: "a"), b <= UInt8(ascii: "z"), b != UInt8(ascii: "e") else { return nil }
        index += 1
        return bytes[index - 1]
    }

    mutating func hasNumber() -> Bool {
        skipSeparators()
        guard index < bytes.count else { return false }
        let b = bytes[index]
        return Self.isDigit(b) || b == Self.minus || b == Self.plus || b == Self.dot
    }

    mutating func number() -> CGFloat? {
        guard hasNumber() else { return nil }
        var sign = 1.0
        if bytes[index] == Self.minus { sign = -1; index += 1 } else if bytes[index] == Self.plus { index += 1 }
        var value = 0.0
        var sawDigit = false
        while index < bytes.count, Self.isDigit(bytes[index]) {
            value = value * 10 + Double(bytes[index] - Self.zero)
            index += 1
            sawDigit = true
        }
        if index < bytes.count, bytes[index] == Self.dot {
            index += 1
            var scale = 0.1
            while index < bytes.count, Self.isDigit(bytes[index]) {
                value += Double(bytes[index] - Self.zero) * scale
                scale /= 10
                index += 1
                sawDigit = true
            }
        }
        guard sawDigit else { return nil }
        if index < bytes.count, bytes[index] | 0x20 == UInt8(ascii: "e") {
            var look = index + 1
            var expSign = 1.0
            if look < bytes.count, bytes[look] == Self.minus { expSign = -1; look += 1 }
            else if look < bytes.count, bytes[look] == Self.plus { look += 1 }
            if look < bytes.count, Self.isDigit(bytes[look]) {
                var exponent = 0.0
                while look < bytes.count, Self.isDigit(bytes[look]) {
                    exponent = exponent * 10 + Double(bytes[look] - Self.zero)
                    look += 1
                }
                value *= pow(10, expSign * exponent)
                index = look
            }
        }
        return CGFloat(sign * value)
    }

    mutating func point(from origin: CGPoint) -> CGPoint? {
        guard let x = number(), let y = number() else { return nil }
        return CGPoint(x: origin.x + x, y: origin.y + y)
    }

    /// An arc flag: a single 0 or 1, which may run straight into the next
    /// number ("a1 1 0 01.5 2")
    mutating func flag() -> Bool? {
        skipSeparators()
        guard index < bytes.count else { return nil }
        switch bytes[index] {
        case Self.zero: index += 1; return false
        case Self.zero + 1: index += 1; return true
        default: return nil
        }
    }
}
