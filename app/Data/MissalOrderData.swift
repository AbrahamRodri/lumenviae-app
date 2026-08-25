//
//  MissalOrderData.swift
//  Lumen Viae
//
//  The shape of the Mass, as data: what the body does during each part,
//  which parts are the day's own (the propers) against the fixed frame
//  around them (the Ordinary), and where every part of the Ordinary
//  stands among the propers — Asperges through the Last Gospel, after
//  the order of the 1962 Missale Romanum (cf. the Ipsissima Verba
//  Extraordinary Form order-of-Mass reference). Missale Meum serves the
//  propers in liturgical order but says nothing about posture, tier, or
//  the Ordinary's places, so all of that lives here, keyed by the
//  section names the API uses.
//
//  The variable parts are computed per day as best the data allows:
//  the Gloria falls away with penitential vestments, the Credo belongs
//  to Sundays and the greater feasts, the Asperges to the sung Sunday
//  Mass, the incensing to High Mass, and the Leonine prayers to Low.
//
//  Sections the tables don't know — Candlemas's blessing of candles,
//  the Holy Week rites — read as propers with no posture cue, so an
//  unusual day degrades to a plain page, never a broken one.
//

import Foundation

// MARK: - MissalPosture

/// What the congregation does through a section, broadly.
enum MissalPosture: String {
    case stand = "Stand"
    case sit = "Sit"
    case kneel = "Kneel"
}

// MARK: - MissalReaderSection

/// One section of the day's Mass as the reader shows it: the text
/// joined to the bundled knowledge of its place — names in both
/// tongues, posture, and whether it is proper to the day.
struct MissalReaderSection: Identifiable {
    let id: String
    let latinName: String
    let englishName: String
    let isProper: Bool
    let posture: MissalPosture?
    let section: MissalSection
}

// MARK: - MissalOrderData

enum MissalOrderData {

    // MARK: - Proper Roles

    private struct Role {
        let posture: MissalPosture?
        let isProper: Bool
    }

    /// Posture and tier for the section ids the propers use, keyed
    /// lowercased. The Preface travels with the propers — the day
    /// decides which one — but belongs to the Ordinary's tier.
    private static let roles: [String: Role] = [
        "introitus":                    Role(posture: .stand, isProper: true),
        "oratio":                       Role(posture: .stand, isProper: true),
        "commemoratio oratio":          Role(posture: .stand, isProper: true),
        "lectio":                       Role(posture: .sit, isProper: true),
        "epistola":                     Role(posture: .sit, isProper: true),
        "graduale":                     Role(posture: .sit, isProper: true),
        "tractus":                      Role(posture: .sit, isProper: true),
        "sequentia":                    Role(posture: .sit, isProper: true),
        "evangelium":                   Role(posture: .stand, isProper: true),
        "offertorium":                  Role(posture: .sit, isProper: true),
        "secreta":                      Role(posture: .sit, isProper: true),
        "commemoratio secreta":         Role(posture: .sit, isProper: true),
        "prefatio":                     Role(posture: .stand, isProper: false),
        "communio":                     Role(posture: .kneel, isProper: true),
        "postcommunio":                 Role(posture: .stand, isProper: true),
        "commemoratio postcommunio":    Role(posture: .stand, isProper: true)
    ]

    // MARK: - Ordinary Parts

    /// One fixed part of the Mass, drawn from the Ordo by its label.
    private struct OrdinaryPart {
        /// `MissalSection.label` in the Ordo, lowercased
        let ordoLabel: String
        let latinName: String
        let englishName: String
        let posture: MissalPosture

        /// Nil: the part belongs to every Mass. True: High Mass only.
        /// False: Low Mass only.
        var highMassOnly: Bool? = nil
    }

    private static let asperges = OrdinaryPart(
        ordoLabel: "asperges",
        latinName: "Asperges",
        englishName: "Asperges",
        posture: .stand,
        highMassOnly: true
    )

    /// Before the day's Introit
    private static let beforeIntroit: [OrdinaryPart] = [
        OrdinaryPart(
            ordoLabel: "prayers at the foot of the altar",
            latinName: "At the Foot of the Altar",
            englishName: "At the Foot of the Altar",
            posture: .kneel
        )
    ]

    /// After the day's Introit — the Gloria only when the day says it
    private static let kyrie = OrdinaryPart(
        ordoLabel: "kyrie",
        latinName: "Kyrie",
        englishName: "Kyrie",
        posture: .stand
    )

    private static let gloria = OrdinaryPart(
        ordoLabel: "gloria",
        latinName: "Gloria",
        englishName: "Gloria",
        posture: .stand
    )

    /// After the day's Gospel, when the day says it
    private static let credo = OrdinaryPart(
        ordoLabel: "credo",
        latinName: "Credo",
        englishName: "Credo",
        posture: .stand
    )

    /// After the day's Offertory verse, through the Secret
    private static let afterOffertory: [OrdinaryPart] = [
        OrdinaryPart(
            ordoLabel: "offertory prayers",
            latinName: "Offertory Prayers",
            englishName: "Offertory Prayers",
            posture: .sit
        ),
        OrdinaryPart(
            ordoLabel: "incensing",
            latinName: "Incensing",
            englishName: "Incensing",
            posture: .sit,
            highMassOnly: true
        ),
        OrdinaryPart(
            ordoLabel: "lavabo",
            latinName: "Lavabo",
            englishName: "Lavabo",
            posture: .sit
        ),
        OrdinaryPart(
            ordoLabel: "prayer to the most holy trinity",
            latinName: "Súscipe, Sancta Trínitas",
            englishName: "Prayer to the Holy Trinity",
            posture: .sit
        ),
        OrdinaryPart(
            ordoLabel: "orate fratres",
            latinName: "Oráte, Fratres",
            englishName: "Pray, Brethren",
            posture: .sit
        )
    ]

    /// The Canon itself; the Our Father follows it, then everything to
    /// the ablutions — all before the day's Communion verse.
    private static let canon = OrdinaryPart(
        ordoLabel: "canon",
        latinName: "Canon Missæ",
        englishName: "Canon of the Mass",
        posture: .kneel
    )

    private static let afterCanon: [OrdinaryPart] = [
        OrdinaryPart(
            ordoLabel: "fraction – breaking of the sacred host",
            latinName: "The Fraction",
            englishName: "The Fraction",
            posture: .kneel
        ),
        OrdinaryPart(
            ordoLabel: "agnus dei",
            latinName: "Agnus Dei",
            englishName: "Agnus Dei",
            posture: .kneel
        ),
        OrdinaryPart(
            ordoLabel: "prayers for holy communion",
            latinName: "Prayers for Holy Communion",
            englishName: "Prayers for Holy Communion",
            posture: .kneel
        ),
        OrdinaryPart(
            ordoLabel: "communion of the priest",
            latinName: "Communion of the Priest",
            englishName: "Communion of the Priest",
            posture: .kneel
        ),
        OrdinaryPart(
            ordoLabel: "communion of the people",
            latinName: "Communion of the People",
            englishName: "Communion of the People",
            posture: .kneel
        ),
        OrdinaryPart(
            ordoLabel: "ablutions",
            latinName: "Ablutions",
            englishName: "Ablutions",
            posture: .sit
        )
    ]

    /// After the day's Postcommunion, closing the Mass
    private static let closing: [OrdinaryPart] = [
        OrdinaryPart(
            ordoLabel: "conclusion",
            latinName: "Ite, Missa Est",
            englishName: "Conclusion",
            posture: .stand
        ),
        OrdinaryPart(
            ordoLabel: "the last gospel",
            latinName: "Ultimum Evangélium",
            englishName: "The Last Gospel",
            posture: .stand
        ),
        OrdinaryPart(
            ordoLabel: "prayers ordered by the pope leo xiii",
            latinName: "Leonine Prayers",
            englishName: "Leonine Prayers",
            posture: .kneel,
            highMassOnly: false
        )
    ]

    // MARK: - Day Rules

    /// The Gloria falls away with the penitential colours — violet,
    /// black, and the rose that stands in for violet twice a year.
    static func saysGloria(_ info: MissalInfo?) -> Bool {
        guard let first = info?.colors?.first else { return true }
        return !["v", "b", "p"].contains(first)
    }

    /// The Credo belongs to Sundays and the greater feasts.
    static func saysCredo(_ info: MissalInfo?, date: Date) -> Bool {
        if Calendar.current.component(.weekday, from: date) == 1 { return true }
        if let rank = info?.rank, rank <= 2 { return true }
        return false
    }

    /// The Asperges opens the principal sung Mass of a Sunday.
    static func saysAsperges(date: Date, highMass: Bool) -> Bool {
        highMass && Calendar.current.component(.weekday, from: date) == 1
    }

    // MARK: - Building the Page

    /// The reader's section list for one Mass: the day's propers in the
    /// order the API serves them and — when the full Mass is asked for
    /// and the Ordo is on hand — the whole Ordinary let into its
    /// places, its variable parts decided by the day and by whether the
    /// Mass is sung. Propers-only keeps the day's own texts alone.
    static func readerSections(
        propers: [MissalSection],
        ordo: [MissalSection],
        scope: MissalScope,
        info: MissalInfo?,
        date: Date,
        highMass: Bool
    ) -> [MissalReaderSection] {
        var builder = Builder(ordo: ordo, scope: scope, highMass: highMass)

        let keys = propers.map { sectionKey($0) }
        let carried = Set(keys)

        // The Ordinary is laid out on the Mass's own fixed order and
        // merged with the propers, rather than hung off proper sections
        // the day may not carry: a Mass the API serves with no Prefatio
        // still reaches its Sanctus, and one with no Communio still gets
        // its Canon.
        var pending: [(station: Int, emit: (inout Builder) -> Void)] = []
        func schedule(_ station: Int, _ emit: @escaping (inout Builder) -> Void) {
            pending.append((station, emit))
        }

        if saysAsperges(date: date, highMass: highMass) {
            schedule(Station.asperges) { $0.add(asperges) }
        }
        schedule(Station.foreMass) { $0.add(beforeIntroit) }
        schedule(Station.kyrie) { $0.add(kyrie) }
        if saysGloria(info) { schedule(Station.gloria) { $0.add(gloria) } }
        if saysCredo(info, date: date) { schedule(Station.credo) { $0.add(credo) } }
        // The Offertory dialogue opens the day's Offertory verse where
        // there is one — see the prefix below — and stands on its own
        // where there isn't.
        if !carried.contains("offertorium") {
            schedule(Station.offertoryDialogue) { $0.addOffertoryDialogue() }
        }
        schedule(Station.offertoryPrayers) { $0.add(afterOffertory) }
        schedule(Station.sursumCorda) { $0.addSursumCorda() }
        // The day's own Preface yields the Ordo's; a day that brought
        // none reads the Common Preface in its place.
        if !carried.contains("prefatio") {
            schedule(Station.preface) { $0.addCommonPreface() }
        }
        schedule(Station.sanctus) { $0.addSanctus() }
        schedule(Station.canon) { $0.add(canon) }
        schedule(Station.paterNoster) { $0.addPaterNoster() }
        schedule(Station.fraction) { $0.add(afterCanon) }
        schedule(Station.closing) { $0.add(closing) }

        pending.sort { $0.station < $1.station }

        var next = 0
        // A section the tables don't know keeps the station of the one
        // before it, so an unusual rite stays where the API put it
        // instead of dragging the Ordinary out of order around it.
        var station = 0

        for (index, section) in propers.enumerated() {
            let key = keys[index]
            station = stations[key] ?? station

            while next < pending.count, pending[next].station < station {
                pending[next].emit(&builder)
                next += 1
            }

            builder.addProper(
                section,
                index: index,
                role: roles[key],
                prefixedBy: key == "offertorium" ? builder.ordoBody("offertory") : []
            )
        }

        while next < pending.count {
            pending[next].emit(&builder)
            next += 1
        }

        return builder.sections
    }

    /// The API's own name for a section, lowercased — the key both the
    /// role table and the station table are read with.
    private static func sectionKey(_ section: MissalSection) -> String {
        (trimmed(section.id) ?? trimmed(section.label) ?? "").lowercased()
    }

    // MARK: - Stations

    /// Where each part stands in the fixed order of the Mass. The
    /// propers and the Ordinary share one scale, so the page is built
    /// by merging two ordered streams — which is what lets a missing
    /// proper cost only itself.
    private enum Station {
        static let asperges = 10
        static let foreMass = 20
        static let introit = 30
        static let kyrie = 40
        static let gloria = 50
        static let collect = 60
        static let epistle = 70
        static let gradual = 80
        static let gospel = 90
        static let credo = 100
        static let offertoryDialogue = 105
        static let offertory = 110
        static let offertoryPrayers = 120
        static let secret = 130
        static let sursumCorda = 140
        static let preface = 150
        static let sanctus = 160
        static let canon = 170
        static let paterNoster = 180
        static let fraction = 190
        static let communion = 200
        static let postcommunion = 210
        static let closing = 220
    }

    /// The station of each proper section id the API serves.
    private static let stations: [String: Int] = [
        "introitus":                    Station.introit,
        "oratio":                       Station.collect,
        "commemoratio oratio":          Station.collect,
        "lectio":                       Station.epistle,
        "epistola":                     Station.epistle,
        "graduale":                     Station.gradual,
        "tractus":                      Station.gradual,
        "sequentia":                    Station.gradual,
        "evangelium":                   Station.gospel,
        "offertorium":                  Station.offertory,
        "secreta":                      Station.secret,
        "commemoratio secreta":         Station.secret,
        "prefatio":                     Station.preface,
        "communio":                     Station.communion,
        "postcommunio":                 Station.postcommunion,
        "commemoratio postcommunio":    Station.postcommunion
    ]

    // MARK: - Builder

    /// Accumulates the page, resolving Ordo parts and keeping the
    /// once-only and scope rules in one place.
    private struct Builder {
        let ordo: [MissalSection]
        let scope: MissalScope
        let highMass: Bool

        var sections: [MissalReaderSection] = []

        private var includesOrdinary: Bool { scope == .full && !ordo.isEmpty }

        // MARK: Propers

        mutating func addProper(
            _ section: MissalSection,
            index: Int,
            role: Role?,
            prefixedBy prefix: [[String]] = []
        ) {
            // Every section the day served belongs on the day's page,
            // whatever tier it reads at. `isProper` decides the diamond
            // stud and nothing else: the Preface is set at the
            // Ordinary's tier but is the day's own text, and treating
            // the flag as a visibility test dropped it from every
            // propers-only page — and from every page loaded before the
            // Ordo arrived.
            let isProper = role?.isProper ?? true

            let latin = MissalOrderData.trimmed(section.id)
            let english = MissalOrderData.trimmed(section.label)

            var body = section.body
            if includesOrdinary, !prefix.isEmpty {
                body = prefix + body
            }

            sections.append(MissalReaderSection(
                id: "proper-\(index)",
                latinName: latin ?? english ?? "",
                englishName: english ?? latin ?? "",
                isProper: isProper,
                posture: role?.posture,
                section: MissalSection(id: section.id, label: section.label, body: body)
            ))
        }

        // MARK: Ordinary Parts

        mutating func add(_ parts: [OrdinaryPart]) {
            for part in parts { add(part) }
        }

        mutating func add(_ part: OrdinaryPart) {
            guard includesOrdinary else { return }
            if let highOnly = part.highMassOnly, highOnly != highMass { return }

            let body = ordoBody(part.ordoLabel)
            guard !body.isEmpty else { return }

            append(part, body: body)
        }

        /// The prayer passages of one Ordo section — the single-sided
        /// rubric commentary and the "– Introit in today Mass –"
        /// placeholders left out.
        func ordoBody(_ label: String) -> [[String]] {
            guard includesOrdinary,
                  let section = ordo.first(where: {
                      MissalOrderData.trimmed($0.label)?.lowercased() == label
                  }) else { return [] }

            return section.body.filter { passage in
                guard passage.count > 1 else { return false }
                let first = passage[0].trimmingCharacters(in: .whitespacesAndNewlines)
                return !(first.hasPrefix("–") && first.hasSuffix("–"))
            }
        }

        /// The Ordinary's ℣ ℟ dialogue as a section of its own — used
        /// only where the day serves no Offertory verse for it to open.
        mutating func addOffertoryDialogue() {
            let body = ordoBody("offertory")
            guard !body.isEmpty else { return }

            append(
                OrdinaryPart(
                    ordoLabel: "offertory",
                    latinName: "Offertorium",
                    englishName: "Offertory",
                    posture: .sit
                ),
                body: body
            )
        }

        /// The Ordo's own Preface — the Common one — standing where the
        /// day's would, on a day that brought none. Everything between
        /// the dialogue and the Sanctus, both of which are set apart.
        mutating func addCommonPreface() {
            let body = ordoBody("preface")
            guard body.count >= 3 else { return }

            append(
                OrdinaryPart(
                    ordoLabel: "common preface",
                    latinName: "Præfatio Communis",
                    englishName: "Common Preface",
                    posture: .stand
                ),
                body: Array(body.dropFirst().dropLast())
            )
        }

        /// The Ordo's Preface section holds the ℣ ℟ dialogue, the
        /// Common Preface, and the Sanctus. The dialogue stands before
        /// the day's own Preface, the Sanctus after it, and the Common
        /// Preface text yields to the day's — the whole section is used
        /// only when the day brought none.
        mutating func addSursumCorda() {
            let body = ordoBody("preface")
            guard let dialogue = body.first else { return }

            append(
                OrdinaryPart(
                    ordoLabel: "preface",
                    latinName: "Sursum Corda",
                    englishName: "Preface Dialogue",
                    posture: .stand
                ),
                body: [dialogue]
            )
        }

        mutating func addSanctus() {
            let body = ordoBody("preface")
            guard body.count >= 2, let sanctus = body.last else { return }

            append(
                OrdinaryPart(
                    ordoLabel: "sanctus",
                    latinName: "Sanctus",
                    englishName: "Sanctus",
                    posture: .kneel
                ),
                body: [sanctus]
            )
        }

        /// The Our Father with its introduction — "Admonished by Thy
        /// saving precepts…" — which the Ordo keeps as its own little
        /// section labelled "Communion".
        mutating func addPaterNoster() {
            let body = ordoBody("communion") + ordoBody("pater noster")
            guard !body.isEmpty else { return }

            append(
                OrdinaryPart(
                    ordoLabel: "pater noster",
                    latinName: "Pater Noster",
                    englishName: "Our Father",
                    posture: .kneel
                ),
                body: body
            )
        }

        private mutating func append(_ part: OrdinaryPart, body: [[String]]) {
            sections.append(MissalReaderSection(
                id: "ordo-\(part.ordoLabel)-\(sections.count)",
                latinName: part.latinName,
                englishName: part.englishName,
                isProper: false,
                posture: part.posture,
                section: MissalSection(id: nil, label: part.ordoLabel, body: body)
            ))
        }
    }

    private static func trimmed(_ string: String?) -> String? {
        guard let value = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }
}
