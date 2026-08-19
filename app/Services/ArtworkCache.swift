//
//  ArtworkCache.swift
//  Lumen Viae
//
//  Set paintings from the API, decoded once and kept for the session.
//
//  The URLs are unsigned, carry a hash of the file, and come back with
//  `Cache-Control: public, max-age=31536000, immutable` — a painting is the
//  same bytes forever and a replaced one has a different URL. So the fetch
//  goes through a session with a roomy disk URLCache, which makes a
//  painting one download per install, and "is my copy stale" is never a
//  question the app has to ask the network. A copy saved by
//  OfflineContentService is read before anything else: it is the same
//  file, already on disk, and it is what makes the page work on a plane.
//

import SwiftUI
import UIKit

final class ArtworkCache {

    static let shared = ArtworkCache()

    // MARK: - State

    /// Decoded paintings by URL. Read synchronously from view bodies so a
    /// revisited page shows its plate on the first frame rather than
    /// after a task.
    private var images: [String: UIImage] = [:]

    /// The one load in flight per URL, shared by every view asking for it
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    /// Fetches through a cache that honours the server's year-long
    /// immutable answer. Separate from the API session: its timeouts are
    /// for a cold Fly machine, not for a few hundred KB from S3.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 16 * 1024 * 1024,
            diskCapacity: 128 * 1024 * 1024,
            diskPath: "artwork"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 90
        return URLSession(configuration: config)
    }()

    // MARK: - Reads

    /// The painting if it is already decoded this session
    func cached(_ url: String) -> UIImage? {
        images[url]
    }

    /// The painting, from memory, the offline copy, or the network — nil
    /// only when none of those can produce it. Decoding happens off the
    /// main actor; the result is memoized under the URL. Failures are not
    /// memoized: the next page to ask tries again, which is how a set
    /// opened offline gets its plate once the connection is back.
    func image(for artwork: SetArtwork, setId: Int) async -> UIImage? {
        if let hit = images[artwork.url] { return hit }

        if let running = inFlight[artwork.url] {
            return await running.value
        }

        let local = OfflineContentService.shared.localArtworkURL(setId: setId, remote: artwork.url)
        let session = session
        let url = artwork.url

        let task = Task<UIImage?, Never> {
            await Self.load(remote: url, local: local, session: session)
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = await task.value
        if let image { images[url] = image }
        return image
    }

    // MARK: - Off-Main Loading

    /// Reads and decodes the bytes on the cooperative pool — `@concurrent`
    /// because a plain `nonisolated async` function would inherit the
    /// main-actor caller's isolation and decode a 2400px JPEG on the UI
    /// thread.
    @concurrent
    private nonisolated static func load(remote: String, local: URL?, session: URLSession) async -> UIImage? {
        if let local, let data = try? Data(contentsOf: local), let image = decode(data) {
            return image
        }

        guard let url = URL(string: remote) else { return nil }
        guard let (data, response) = try? await session.data(from: url) else { return nil }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            return nil
        }
        return decode(data)
    }

    /// Decodes and force-decompresses, so the first draw on the main
    /// thread is a blit rather than a JPEG decode.
    private nonisolated static func decode(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in image.draw(at: .zero) }
    }
}
