//
//  Chant.swift
//  Lumen Viae
//
//  The Chant Library's vocabulary. A chant is one recording and its score:
//  sung and engraved by Verbum Gloriae, a Spanish apostolate of Gregorian
//  chant, kept by our server and on the phone once it has come down, so
//  it sounds in a chapel with no signal. The pieces
//  themselves — which chants, their titles, the prayers each is a sung
//  form of, their timed lines — are the server's chant library
//  (`LibraryContent.chantLibrary`); the recordings and scores are kept on
//  the phone by `ChantAssetStore`, and stream until they are.
//
//  Verbum Gloriae publishes under a copyleft licence: free to copy, adapt
//  and use for any purpose, no attribution required, so long as an
//  adaptation carries the same licence. The files here are adaptations
//  (the Ogg recordings re-encoded as AAC, the SVG scores rewritten as the
//  drawing the app recolours), so they carry it, and the app says so
//  wherever a chant plays (`ChantCatalog.credit`).
//

import Foundation
import CoreGraphics

// MARK: - ChantScorePart

/// One engraved stave of a chant's score. Most chants have one; a hymn
/// adds its versicle and collect, a litany one part per section.
struct ChantScorePart: Hashable {
    /// The drawing's name, `<file>.lvscore` (see `ChantScoreDrawing`)
    let file: String
    /// What the part is, in Latin or in English ("Oremus. Deus qui corda")
    let caption: String
    /// Width over height of the engraving
    let aspectRatio: CGFloat
    /// The drawing on the server, kept on the phone by `ChantAssetStore`
    let asset: ChantFile
}

// MARK: - ChantLine

/// One sung line of a chant: its words, a plain English rendering, and
/// where it stands in the recording. Lines come from
/// `Tools/ChantLines/<chant id>.json`, derived from the chant's recording
/// and checked line by line before they are added; a chant without that
/// file has none, and every surface that steps by the line falls back to
/// the whole chant. No timing is ever guessed.
struct ChantLine: Hashable {
    let latin: String
    let english: String
    /// Seconds into the chant's recording
    let start: TimeInterval
    let end: TimeInterval
    /// The score part the line is engraved on, when the file names one
    var part: Int? = nil

    var length: TimeInterval { max(0, end - start) }
}

// MARK: - ChantGroup

/// A section of the library, after the Parish Book of Chant's contents:
/// the Ordinary of the Mass, the hymns to Our Lady, the seasons.
struct ChantGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String?
    /// Its chants in the book's order, under a subheading where the book
    /// sets one (a Mass of the Kyriale, a season); a section without
    /// subheadings is one part with no title
    let parts: [ChantGroupPart]
}

/// A run of a section's chants, under its own subheading or none
struct ChantGroupPart: Hashable {
    let title: String?
    /// When the part is sung, where the section says
    let note: String?
    let chantIDs: [String]
}

// MARK: - Chant

struct Chant: Identifiable, Hashable {
    let id: String
    let groupID: String
    let latinTitle: String
    let englishTitle: String
    /// The version, where a chant is sung more than one way ("Simple
    /// melody")
    let setting: String?
    /// When it is sung, in one line
    let detail: String
    /// The app's own prayers this chant is a sung form of
    let prayerIDs: [String]
    /// Seconds, measured from the recording
    let duration: TimeInterval
    let score: [ChantScorePart]
    /// The recording on the server, kept on the phone by `ChantAssetStore`
    let audio: ChantFile
    /// The chant's own page at Verbum Gloriae
    let sourceURL: URL
    /// Its sung lines, timed against the recording — empty until the
    /// chant's lines have been derived and checked (`ChantLine`)
    var lines: [ChantLine] = []

    /// Whether the chant can be stepped, repeated and practised a line
    /// at a time
    var hasLines: Bool { !lines.isEmpty }

    /// The line sounding at `time`, or the one just sung while the
    /// recording rests between two
    func lineIndex(at time: TimeInterval) -> Int? {
        guard !lines.isEmpty else { return nil }
        if let index = lines.lastIndex(where: { $0.start <= time + 0.05 }) { return index }
        return 0
    }

    /// The recording on the phone, or the server's, which streams until
    /// it is
    var audioURL: URL? {
        ChantAssetStore.shared.playableURL(for: audio)
    }

    /// Every file the chant needs: its recording and its score's pages
    var files: [ChantFile] { [audio] + score.map(\.asset) }

    var group: ChantGroup? {
        ChantCatalog.index.groups[groupID]
    }

    /// "4:08"
    var durationLabel: String {
        let whole = Int(duration.rounded())
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }

    /// The setting, where neither title already says it: a title naming
    /// its own setting is not also "· short chant" beneath it, and Credo
    /// III is not "The Nicene Creed · credo iii".
    var distinctSetting: String? {
        guard let setting,
              !englishTitle.localizedCaseInsensitiveContains(setting),
              !latinTitle.localizedCaseInsensitiveContains(setting) else { return nil }
        return setting
    }

    /// The distinct setting as it reads after a "·" mid-line: "simple
    /// melody", "with alleluia", but a name keeps its capitals — "Mass of
    /// the Angels", never "mass of the angels". A setting with a capital
    /// after its first word is a name.
    var settingMidLine: String? {
        guard let setting = distinctSetting else { return nil }
        let named = setting.split(separator: " ").dropFirst().contains { word in
            word.first?.isUppercase == true
        }
        return named ? setting : setting.lowercased()
    }

    /// Its two names as VoiceOver says them: "Salve Regina, Hail, Holy
    /// Queen". A Latin title is never heard alone.
    var spokenName: String { "\(latinTitle), \(englishTitle)" }

    /// Its names with the setting where neither says it, for a control
    /// that must tell two settings of one work apart: "Salve Regina, Hail,
    /// Holy Queen, simple melody"
    var spokenNameAndSetting: String {
        settingMidLine.map { "\(spokenName), \($0)" } ?? spokenName
    }

    /// The English name with the Latin after it, where one line holds
    /// both: "Hail, Holy Queen (Salve Regina)"
    var englishWithLatin: String { "\(englishTitle) (\(latinTitle))" }

    /// The title with its setting, for a row that has room for one line:
    /// "Salve Regina · Simple melody", and Credo III alone, never twice
    var fullTitle: String {
        if let setting, !latinTitle.localizedCaseInsensitiveContains(setting) {
            return "\(latinTitle) · \(setting)"
        }
        return latinTitle
    }
}

// MARK: - ChantCatalog

/// Every chant the app carries, and the ways to find one. The data is the
/// chant library's document as this launch reads it.
enum ChantCatalog {

    /// The Parish Book of Chant's sections, in its order
    static let groups: [ChantGroup] = groups(from: LibraryContent.chantLibrary)

    static func groups(from document: ChantLibraryDocument) -> [ChantGroup] {
        document.groups.map { group in
            ChantGroup(
                id: group.id, title: group.title, note: group.note,
                parts: group.parts.map { ChantGroupPart(title: $0.title, note: $0.note, chantIDs: $0.chantIDs) }
            )
        }
    }

    /// Every chant, in the catalog's order (which decides a prayer's
    /// first chant: the simple melody before the solemn)
    static let all: [Chant] = LibraryContent.chantLibrary.chants.map { Chant(document: $0) }

    /// The catalog read once into the lookups the library asks of it on
    /// every row: a chant by its id, the chants of a prayer, a work's
    /// settings. Each was a scan of all of it.
    static let index = ChantCatalogIndex(chants: all, groups: groups)

    static func chant(_ id: String) -> Chant? {
        index.chants[id]
    }

    /// The chants that are a sung form of one of the app's prayers, in the
    /// catalog's order (so a simple tone comes before a solemn one).
    static func chants(forPrayer prayerID: String) -> [Chant] {
        index.byPrayer[prayerID] ?? []
    }

    /// A section's chants in its own order, part after part
    static func chants(in group: ChantGroup) -> [Chant] {
        group.parts.flatMap { chants(in: $0) }
    }

    static func chants(in part: ChantGroupPart) -> [Chant] {
        index.chants(in: part)
    }

    /// The other settings of the same prayer — the solemn tone beside the
    /// simple — for a chant's page to offer.
    static func otherSettings(of chant: Chant) -> [Chant] {
        guard !chant.prayerIDs.isEmpty else { return [] }
        if let known = index.otherSettings[chant.id] { return known }
        return ChantCatalogIndex.otherSettings(of: chant, in: all)
    }

    /// Chants whose Latin or English title holds `query`, accents and
    /// case aside.
    static func search(_ query: String) -> [Chant] {
        let needle = SearchText.needle(query)
        guard !needle.isEmpty else { return [] }
        return index.foldedTitles.compactMap { entry in
            entry.latin.contains(needle) || entry.english.contains(needle) ? entry.chant : nil
        }
    }

    /// The antiphon of Our Lady the season sings tonight — tonight's song
    /// to Mary, as the screens call it — in its simple melody — the library's first piece and the Chapel tile's until the
    /// reader chooses another.
    static func antiphonOfTheSeason(on date: Date = Date()) -> Chant? {
        chants(forPrayer: PrayerBook.antiphon(on: date).prayerID).first
    }

    // MARK: Credit

    /// Said wherever a chant plays. The licence asks for no attribution;
    /// the app gives it anyway, and says the files are shared on the same
    /// terms, which the licence does ask.
    static let credit = "Recordings and sheet music by Verbum Gloriae"
    /// The library page's one line of credit, a link to their site
    static let libraryCredit = "Recordings and scores by Verbum Gloriae"
    static let licenceNote = "Shared under Verbum Gloriae's free licence, a copyleft licence. Our copies are compressed and recoloured, and they carry the same licence."
    static let sourceSite = URL(string: "https://www.verbumgloriae.es")!
    static let licenceURL = URL(string: "https://www.verbumgloriae.es/licencia-copyleft/")!
}

// MARK: - From the document

extension Chant {
    /// What the player holds when the catalog could not be read at all: no
    /// recording, so a play says the chant could not be played
    static let unavailable = Chant(
        id: "", groupID: "", latinTitle: "", englishTitle: "", setting: nil, detail: "",
        prayerIDs: [], duration: 0, score: [],
        audio: ChantFile(url: nil, bytes: 0, sha256: "", fileExtension: "m4a"),
        sourceURL: ChantCatalog.sourceSite
    )
}

extension Chant {
    init(document chant: ChantLibraryDocument.Chant) {
        self.init(
            id: chant.id,
            groupID: chant.groupID,
            latinTitle: chant.latinTitle,
            englishTitle: chant.englishTitle,
            setting: chant.setting,
            detail: chant.detail,
            prayerIDs: chant.prayerIDs,
            duration: chant.duration,
            score: chant.score.map { part in
                ChantScorePart(
                    file: part.file, caption: part.caption, aspectRatio: CGFloat(part.aspectRatio),
                    asset: ChantFile(
                        url: part.url.flatMap(URL.init(string:)), bytes: part.bytes, sha256: part.sha256,
                        fileExtension: "lvscore", key: "score:\(part.file)")
                )
            },
            audio: ChantFile(
                url: chant.audio.url.flatMap(URL.init(string:)), bytes: chant.audio.bytes,
                sha256: chant.audio.sha256, fileExtension: "m4a", key: "audio:\(chant.id)"),
            sourceURL: URL(string: chant.sourceURL) ?? ChantCatalog.sourceSite,
            lines: chant.lines.map {
                ChantLine(latin: $0.latin, english: $0.english, start: $0.start, end: $0.end, part: $0.part)
            }
        )
    }
}

// MARK: - ChantCatalogIndex

/// The catalog's lookups, built once from its chants: what the library's
/// rows, search and pages ask of it again and again. The catalog is fixed
/// for the life of the app, so none of this goes stale.
struct ChantCatalogIndex {
    let chants: [String: Chant]
    let groups: [String: ChantGroup]
    /// Each prayer's chants, in the catalog's order
    let byPrayer: [String: [Chant]]
    /// Each chant's work (`Chant.workKey`), and each work's settings in
    /// the catalog's order
    let workKeys: [String: String]
    let settings: [String: [Chant]]
    /// Each chant's other settings of the same prayer
    let otherSettings: [String: [Chant]]
    /// The seasons each chant belongs to, in the year's order
    let seasons: [String: [ChantSeason]]
    /// Each kind's chants in the catalog's order, and each length's,
    /// shortest first
    let forms: [ChantForm: [Chant]]
    let lengths: [ChantLength: [Chant]]
    /// Every chant's titles folded for search (`SearchText.fold`), in the
    /// catalog's order
    let foldedTitles: [(chant: Chant, latin: String, english: String)]

    init(chants all: [Chant], groups: [ChantGroup]) {
        chants = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.groups = Dictionary(groups.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var byPrayer: [String: [Chant]] = [:]
        var workKeys: [String: String] = [:]
        var settings: [String: [Chant]] = [:]
        for chant in all {
            // A chant once to each prayer, however often it names it
            for prayerID in Set(chant.prayerIDs) {
                byPrayer[prayerID, default: []].append(chant)
            }
            let key = Chant.workKey(latinTitle: chant.latinTitle, prayerIDs: chant.prayerIDs)
            workKeys[chant.id] = key
            settings[key, default: []].append(chant)
        }
        self.byPrayer = byPrayer
        self.workKeys = workKeys
        self.settings = settings

        otherSettings = Dictionary(
            all.map { ($0.id, Self.otherSettings(of: $0, in: all)) },
            uniquingKeysWith: { first, _ in first }
        )

        var seasons: [String: [ChantSeason]] = [:]
        for season in ChantSeason.allCases {
            for id in Set(ChantLibraryData.seasonChants[season] ?? []) {
                seasons[id, default: []].append(season)
            }
        }
        self.seasons = seasons

        forms = Dictionary(grouping: all, by: \.form)
        lengths = Dictionary(grouping: all) { ChantLength.of($0.duration) }
            .mapValues { $0.sorted { $0.duration < $1.duration } }

        foldedTitles = all.map { ($0, SearchText.fold($0.latinTitle), SearchText.fold($0.englishTitle)) }
    }

    /// A part's chants, in its order: what a section's page lists
    func chants(in part: ChantGroupPart) -> [Chant] {
        part.chantIDs.compactMap { chants[$0] }
    }

    /// The other settings of `chant`'s prayers among `all`: the solemn
    /// tone beside the simple
    static func otherSettings(of chant: Chant, in all: [Chant]) -> [Chant] {
        guard !chant.prayerIDs.isEmpty else { return [] }
        return all.filter { other in
            other.id != chant.id && !Set(other.prayerIDs).isDisjoint(with: chant.prayerIDs)
        }
    }
}
