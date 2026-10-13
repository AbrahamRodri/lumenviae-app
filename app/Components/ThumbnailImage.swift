//
//  ThumbnailImage.swift
//  Lumen Viae
//
//  A painting drawn small, from a copy scaled down to the size it is
//  drawn at and kept. The Prayers page's tiles, rows and cards and the
//  Chant Library's paintings once each decoded the whole painting, 1235
//  by 1600 pixels, on the main actor, to show it 44 points wide: the
//  first visit to either page stalled while thirty of them were read.
//  The copy is made off the main actor; until it is ready the frame
//  holds the card's ground, and the painting fades in over it.
//

import SwiftUI
import UIKit

// MARK: - ThumbnailImage

/// A bundled painting cut to fill `size` about `focal`, from a copy scaled
/// to that size. A painting no larger than the frame already is drawn as
/// it is.
struct ThumbnailImage: View {
    let name: String
    let focal: UnitPoint
    let size: CGSize

    @Environment(\.displayScale) private var displayScale

    /// Bumped when the copy is ready, so the body reads the cache again
    @State private var made = 0

    var body: some View {
        // Read so the body is drawn again once the copy is made
        let _ = made
        let request = PaintingThumbnails.Request(name: name, size: size, scale: displayScale)
        ZStack {
            switch PaintingThumbnails.ready(request) {
            case .small(let image):
                FocalFill(uiImage: image, focal: focal)
                    .transition(.opacity)
            case .whole:
                CachedAssetImage(name, focal: focal)
            case .pending:
                AppColors.cardBackground
                    .task(id: request) {
                        await PaintingThumbnails.prepare(request)
                        withAnimation(Motion.crossfade) { made += 1 }
                    }
            }
        }
    }
}

// MARK: - PaintingThumbnails

/// The scaled-down copies, by painting and size, let go under memory
/// pressure and made again when next drawn
enum PaintingThumbnails {

    /// A painting at a size and scale: what one copy is made for
    nonisolated struct Request: Hashable, Sendable {
        let name: String
        let size: CGSize
        let scale: CGFloat

        var key: NSString {
            "\(name)|\(Int(size.width))x\(Int(size.height))@\(Int(scale))" as NSString
        }
    }

    enum Readiness {
        case small(UIImage)
        /// Missing, or no larger than the frame: drawn as it is
        case whole
        case pending
    }

    /// Whether a copy not yet made is made at once, on the main actor,
    /// rather than fetched in the background. The snapshot tests set it,
    /// so a page is drawn the same at every instant; nothing else does.
    static var makesAtOnce = false

    /// What the frame can draw now: the copy, the painting as it is, or
    /// nothing yet. Made at once here only for the snapshots.
    static func ready(_ request: Request) -> Readiness {
        if let small = Store.kept.object(forKey: request.key) { return .small(small) }
        if Store.whole.object(forKey: request.key) != nil { return .whole }
        guard makesAtOnce else { return .pending }
        return image(named: request.name, filling: request.size, scale: request.scale).map(Readiness.small) ?? .whole
    }

    /// Makes the copy off the main actor and keeps it, or notes that the
    /// painting is drawn as it is
    @concurrent
    static func prepare(_ request: Request) async {
        _ = Store.make(request)
    }

    /// The painting scaled to cover `size` at `scale`, keeping its
    /// shape, or nil when it is missing or no larger than that already.
    /// Kept, so a second ask is the same image.
    static func image(named name: String, filling size: CGSize, scale: CGFloat) -> UIImage? {
        Store.make(Request(name: name, size: size, scale: scale))
    }

    /// The caches and the making, which any thread may use: NSCache is
    /// thread-safe, and so are UIImage(named:) and preparingThumbnail
    private nonisolated enum Store {
        nonisolated(unsafe) static let kept: NSCache<NSString, UIImage> = {
            let cache = NSCache<NSString, UIImage>()
            cache.countLimit = 300
            return cache
        }()

        /// Paintings drawn as they are, so they are not looked at again
        nonisolated(unsafe) static let whole = NSCache<NSString, NSNull>()

        static func make(_ request: Request) -> UIImage? {
            let key = request.key
            if let small = kept.object(forKey: key) { return small }
            let size = request.size
            guard size.width > 0, size.height > 0, request.scale > 0,
                let full = UIImage(named: request.name), full.size.width > 0, full.size.height > 0
            else {
                whole.setObject(NSNull(), forKey: key)
                return nil
            }
            let cover = max(size.width / full.size.width, size.height / full.size.height)
            let pixels = CGSize(
                width: (full.size.width * cover * request.scale).rounded(.up),
                height: (full.size.height * cover * request.scale).rounded(.up)
            )
            guard pixels.width < full.size.width * full.scale,
                let small = full.preparingThumbnail(of: pixels)
            else {
                whole.setObject(NSNull(), forKey: key)
                return nil
            }
            kept.setObject(small, forKey: key)
            return small
        }
    }
}
