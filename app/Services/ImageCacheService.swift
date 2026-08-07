//
//  ImageCacheService.swift
//  Lumen Viae
//
//  Preloads and caches mystery images for instant display.
//

import SwiftUI
import UIKit

/// Preloads and caches images to prevent flashing when navigating.
///
/// Asset catalog images are loaded from disk on first access, which can
/// cause a brief flash. This service preloads them into memory during
/// the launch screen so they display instantly when needed.
final class ImageCacheService: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = ImageCacheService()

    // MARK: - State

    /// Cached UIImage instances keyed by asset name (access synchronized via lock)
    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()

    /// Whether preloading has completed
    private(set) var isReady = false

    // MARK: - Image Names

    /// All mystery images used in the app: every per-mystery image from
    /// Constants plus the Seven Sorrows category card.
    private let mysteryCardImages: [String] = Array(Set(
        Constants.joyfulMysteryImages
            + Constants.sorrowfulMysteryImages
            + Constants.gloriousMysteryImages
            + Constants.luminousMysteryImages
            + Constants.sevenSorrowsMysteryImages
            + ["seven_sorrows_pieta"]
    ))

    // MARK: - Preloading

    /// Preloads all mystery images into memory.
    ///
    /// Call this during the launch screen to ensure images are ready
    /// before the user sees the home screen. Images are loaded and
    /// decompressed in parallel on background threads.
    func preloadImages() async {
        await withTaskGroup(of: (String, UIImage?).self) { group in
            for imageName in mysteryCardImages {
                group.addTask {
                    guard let uiImage = UIImage(named: imageName) else {
                        return (imageName, nil)
                    }
                    // Force decompression by rendering into a graphics context
                    let format = UIGraphicsImageRendererFormat.default()
                    format.scale = uiImage.scale
                    let renderer = UIGraphicsImageRenderer(size: uiImage.size, format: format)
                    let decompressed = renderer.image { _ in
                        uiImage.draw(at: .zero)
                    }
                    return (imageName, decompressed)
                }
            }
            for await (name, image) in group {
                if let image {
                    lock.withLock { cache[name] = image }
                }
            }
        }
        isReady = true
    }

    /// Gets a cached image, falling back to loading from assets if needed.
    func image(named name: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[name] {
            return cached
        }
        // Fallback: load and cache if not preloaded
        if let uiImage = UIImage(named: name) {
            cache[name] = uiImage
            return uiImage
        }
        return nil
    }
}

// MARK: - CachedAssetImage

/// A SwiftUI Image view that uses the preloaded cache.
///
/// Usage:
/// ```swift
/// CachedAssetImage("joyful_annunciation")
///     .aspectRatio(contentMode: .fill)
/// ```
struct CachedAssetImage: View {
    let name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some View {
        if let uiImage = ImageCacheService.shared.image(named: name) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            // Missing asset: render a quiet themed surface instead of nothing
            LinearGradient(
                colors: [AppColors.cardBackground, AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
