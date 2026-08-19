//
//  MeditationSet.swift
//  Lumen Viae
//
//  A meditation set groups 5 meditations (one per mystery) under a theme,
//  e.g. "Traditional Meditations" for the Joyful mysteries.
//
//  - List: GET /api/meditation-sets?category=joyful → [MeditationSetSummary]
//  - Detail: GET /api/meditation-sets/:id → MeditationSet (with meditations)
//
//  Both carry the same artwork block: a painting's URL, the point in it the
//  crop should keep, its pixel size, alt text, and where it came from. Every
//  one of those keys is null together when a set has no painting, so
//  `artwork` branches on the URL alone.
//

import Foundation

// MARK: - Label Display

/// How API labels are worded in the picker.
///
/// Labels are matched and filtered as the raw, case-sensitive strings the
/// API sends — this only changes what the user reads, so the app never has
/// to wait on a backend relabel to say something better.
enum MeditationLabel {

    private static let displayNames: [String: String] = [
        "Considerations": "Reflections"
    ]

    /// The user-facing wording for an API label.
    static func displayName(_ label: String) -> String {
        displayNames[label] ?? label
    }

    /// A set's labels as one tracked line — "SAINTS  ·  REFLECTIONS" — the
    /// way every shelf and hero renders them.
    static func displayLine(_ labels: [String]) -> String {
        labels.map { displayName($0) }.joined(separator: "  ·  ").uppercased()
    }
}

// MARK: - Artwork

/// Where a set's painting came from. For a credits line, never the player.
nonisolated struct ArtworkAttribution: Codable, Hashable {
    let title: String?
    let artist: String?
    let year: String?
    let sourceUrl: String?
    let license: String?

    enum CodingKeys: String, CodingKey {
        case title, artist, year, license
        case sourceUrl = "source_url"
    }

    /// "Christ Carrying the Cross · El Greco · c. 1580" — whichever parts
    /// the record carries, or nil when it carries none.
    var creditLine: String? {
        let parts = [title, artist, year].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }
}

/// A set's painting and how to crop it, lifted off the flat `image_*` keys
/// once `image_url` says there is one.
///
/// The focal point is normalized 0…1 — `(0.5, 0.24)` means the subject sits
/// 24% down the canvas — so one value crops correctly at any size the app
/// draws it. `width`/`height` are the pixel size, known before the bytes
/// arrive so a frame can be reserved at the right ratio. Kept as plain
/// numbers here: this file is `Foundation`-only so offline reads can decode
/// it off the main actor; the view side turns it into a `UnitPoint`.
nonisolated struct SetArtwork: Hashable {
    let url: String
    let focalX: Double
    let focalY: Double
    let width: Int?
    let height: Int?
    let alt: String?
    let attribution: ArtworkAttribution?

    /// Builds the block from the flat keys, or nil when there is no
    /// painting. `image_url` alone decides; the rest default sensibly if
    /// they were ever to arrive without it.
    init?(
        url: String?,
        focalX: Double?,
        focalY: Double?,
        width: Int?,
        height: Int?,
        alt: String?,
        attribution: ArtworkAttribution?
    ) {
        guard let url, !url.isEmpty else { return nil }
        self.url = url
        self.focalX = focalX ?? 0.5
        self.focalY = focalY ?? 0.5
        self.width = width
        self.height = height
        self.alt = alt
        self.attribution = attribution
    }

    /// The pixel size, when the API sent one and it is usable.
    var intrinsicSize: CGSize? {
        guard let width, let height, width > 0, height > 0 else { return nil }
        return CGSize(width: Double(width), height: Double(height))
    }
}

// MARK: - MeditationSet

/// A complete meditation set with all meditations included (detail endpoint).
///
/// The `Codable` conformance is `nonisolated` — the module defaults to
/// `@MainActor`, but offline reads decode these off the main actor.
struct MeditationSet: nonisolated Codable, Identifiable, Hashable {

    // MARK: - Properties

    let id: Int

    /// Set name (e.g., "Traditional Meditations")
    let name: String

    /// Category string (e.g., "joyful")
    let category: String

    /// Optional description of this meditation style
    let description: String?

    /// Descriptive labels for browsing/filtering (e.g., ["Saints", "Scriptural"]).
    /// The first label is the set's primary group. Optional — absent until
    /// the API sends it, in which case the picker shows a flat list.
    let labels: [String]?

    /// Array of meditations, one per mystery (5 for standard Rosary).
    /// Optional because list endpoint doesn't include this.
    let meditations: [Meditation]?

    /// Whose voice the set is, when the API can say so for the whole set:
    /// the set's own byline, or the meditations' when every one agrees.
    /// Null for a set of mixed voices — render nothing rather than a name
    /// true of most of it.
    let author: String?

    /// The book the meditations were drawn from, on the same terms as `author`
    let source: String?

    /// When every `audio_url` in this response stops working, ISO 8601.
    /// Kept as the string the server sent: the offline store round-trips
    /// this struct through a plain encoder, and a date would change shape
    /// on the way. See `audioExpiry`.
    let audioExpiresAt: String?

    // Artwork — flat, as the API sends them. Read through `artwork`.
    let imageUrl: String?
    let imageAlignment: String?
    let imageFocalX: Double?
    let imageFocalY: Double?
    let imageWidth: Int?
    let imageHeight: Int?
    let imageAlt: String?
    let imageAttribution: ArtworkAttribution?

    // Every key is listed — leaving `meditations` out of an explicit
    // CodingKeys does not throw, it decodes to nil and empties the prayer
    // screen.
    enum CodingKeys: String, CodingKey {
        case id, name, category, description, labels, meditations, author, source
        case audioExpiresAt = "audio_expires_at"
        case imageUrl = "image_url"
        case imageAlignment = "image_alignment"
        case imageFocalX = "image_focal_x"
        case imageFocalY = "image_focal_y"
        case imageWidth = "image_width"
        case imageHeight = "image_height"
        case imageAlt = "image_alt"
        case imageAttribution = "image_attribution"
    }

    init(
        id: Int,
        name: String,
        category: String,
        description: String?,
        labels: [String]?,
        meditations: [Meditation]?,
        author: String? = nil,
        source: String? = nil,
        audioExpiresAt: String? = nil,
        imageUrl: String? = nil,
        imageAlignment: String? = nil,
        imageFocalX: Double? = nil,
        imageFocalY: Double? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageAlt: String? = nil,
        imageAttribution: ArtworkAttribution? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.labels = labels
        self.meditations = meditations
        self.author = author
        self.source = source
        self.audioExpiresAt = audioExpiresAt
        self.imageUrl = imageUrl
        self.imageAlignment = imageAlignment
        self.imageFocalX = imageFocalX
        self.imageFocalY = imageFocalY
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageAlt = imageAlt
        self.imageAttribution = imageAttribution
    }

    // MARK: - Computed Properties

    /// Type-safe category enum, or nil if category string is invalid
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// Whether any meditation in this set has audio available
    var hasAudio: Bool {
        meditations?.contains { $0.hasAudio } ?? false
    }

    /// Number of meditations (typically 5)
    var meditationCount: Int {
        meditations?.count ?? 0
    }

    /// The set's painting, or nil when it has none
    var artwork: SetArtwork? {
        SetArtwork(
            url: imageUrl, focalX: imageFocalX, focalY: imageFocalY,
            width: imageWidth, height: imageHeight, alt: imageAlt,
            attribution: imageAttribution
        )
    }

    /// The moment the audio URLs in this set stop working, if the server
    /// said. Nil for a response that predates the field, and for stored
    /// copies written before it was kept.
    var audioExpiry: Date? {
        audioExpiresAt.flatMap { try? Date($0, strategy: .iso8601) }
    }

    /// Whether the audio URLs are known to be dead. Unknown reads as
    /// false — the player learns the truth from the load and refreshes
    /// then, rather than paying a round trip on every mystery for sets
    /// that never said.
    var audioURLsHaveExpired: Bool {
        guard let audioExpiry else { return false }
        return audioExpiry <= Date()
    }
}

// MARK: - MeditationSetSummary

/// A meditation set without the meditations array (list endpoint).
/// When the user selects one, fetch the full MeditationSet by ID.
struct MeditationSetSummary: nonisolated Codable, Identifiable, Hashable {

    // MARK: - Properties

    let id: Int

    /// Set name (e.g., "St. Louis de Montfort")
    let name: String

    /// Category string (e.g., "sorrowful")
    let category: String

    /// Optional description
    let description: String?

    /// Descriptive labels for browsing/filtering (e.g., ["Saints", "Scriptural"]).
    /// The first label is the set's primary group; nil until the API sends it.
    let labels: [String]?

    /// Whose voice the set is, on the same terms as `MeditationSet.author`
    let author: String?

    /// The book behind it, on the same terms as `MeditationSet.source`
    let source: String?

    // Artwork — flat, as the API sends them. Read through `artwork`.
    let imageUrl: String?
    let imageAlignment: String?
    let imageFocalX: Double?
    let imageFocalY: Double?
    let imageWidth: Int?
    let imageHeight: Int?
    let imageAlt: String?
    let imageAttribution: ArtworkAttribution?

    enum CodingKeys: String, CodingKey {
        case id, name, category, description, labels, author, source
        case imageUrl = "image_url"
        case imageAlignment = "image_alignment"
        case imageFocalX = "image_focal_x"
        case imageFocalY = "image_focal_y"
        case imageWidth = "image_width"
        case imageHeight = "image_height"
        case imageAlt = "image_alt"
        case imageAttribution = "image_attribution"
    }

    init(
        id: Int,
        name: String,
        category: String,
        description: String?,
        labels: [String]?,
        author: String? = nil,
        source: String? = nil,
        imageUrl: String? = nil,
        imageAlignment: String? = nil,
        imageFocalX: Double? = nil,
        imageFocalY: Double? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageAlt: String? = nil,
        imageAttribution: ArtworkAttribution? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.labels = labels
        self.author = author
        self.source = source
        self.imageUrl = imageUrl
        self.imageAlignment = imageAlignment
        self.imageFocalX = imageFocalX
        self.imageFocalY = imageFocalY
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageAlt = imageAlt
        self.imageAttribution = imageAttribution
    }

    // MARK: - Computed Properties

    /// Type-safe category enum
    var mysteryCategory: MysteryCategory? {
        MysteryCategory(fromAPIString: category)
    }

    /// The label this set is grouped under when browsing unfiltered
    var primaryLabel: String? {
        labels?.first
    }

    /// The set's painting, or nil when it has none
    var artwork: SetArtwork? {
        SetArtwork(
            url: imageUrl, focalX: imageFocalX, focalY: imageFocalY,
            width: imageWidth, height: imageHeight, alt: imageAlt,
            attribution: imageAttribution
        )
    }
}
