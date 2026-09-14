import AVFoundation
import AppKit

// sheet <movie> <out.png> <step> <from> <to> [cols] [thumbWidth]
let a = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let out = a[2]
let step = Double(a[3])!, from = Double(a[4])!, to = Double(a[5])!
let cols = a.count > 6 ? Int(a[6])! : 8
let tw = a.count > 7 ? Int(a[7])! : 150

let gen = AVAssetImageGenerator(asset: asset)
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
gen.maximumSize = CGSize(width: tw * 2, height: tw * 5)
let duration = CMTimeGetSeconds(asset.duration)

var images: [(Double, CGImage)] = []
var t = from
while t < min(duration, to) {
    if let cg = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
        images.append((t, cg))
    }
    t += step
}
guard let first = images.first?.1 else { fatalError("no frames") }
let th = Int(Double(tw) * Double(first.height) / Double(first.width))
let rows = (images.count + cols - 1) / cols
let labelH = 14
let W = cols * tw, H = rows * (th + labelH)
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setFillColor(CGColor(gray: 0.08, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
let font = CTFontCreateWithName("Menlo" as CFString, 10, nil)
for (i, (time, cg)) in images.enumerated() {
    let col = i % cols, row = i / cols
    let x = col * tw
    let y = H - (row + 1) * (th + labelH) // CG origin bottom-left
    ctx.draw(cg, in: CGRect(x: x, y: y + labelH, width: tw, height: th))
    let attr = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: CGColor(gray: 0.9, alpha: 1)] as CFDictionary
    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, String(format: "%.2fs", time) as CFString, attr))
    ctx.textPosition = CGPoint(x: CGFloat(x) + 3, y: CGFloat(y) + 3)
    CTLineDraw(line, ctx)
}
let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("sheet \(W)x\(H), \(images.count) frames")
