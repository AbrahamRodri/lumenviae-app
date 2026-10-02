//
//  ChantLibrary.swift
//  Lumen Viae
//
//  The ways the Chant Library is browsed, as the "Chant Library Redesign"
//  boards lay them out: by the hour of the day and the day of the week,
//  by the Church's seasons and her feasts, by the occasion a set of chants
//  is sung for, by the kind of chant, and as a course learned by heart.
//
//  The vocabulary lives here; the tables — which chant belongs to which
//  season, form, weekday or occasion — are `Data/ChantLibraryData.swift`.
//  The seasons are computed on the device from the same rules as the rest
//  of the app (`ScheduleService` for Easter and Advent, `PrayerBook` for
//  the antiphon of Our Lady), so nothing here waits on a signal.
//

import Foundation

// MARK: - ChantForm

/// The kind of chant: what the Types board lists, each a lettered tile.
/// Every chant has exactly one (`ChantLibraryData.forms`).
enum ChantForm: String, CaseIterable, Identifiable {
    case shortChant
    case hymn
    case sequence
    case litany
    case psalm
    case everydayPrayer

    var id: String { rawValue }

    /// The tile's versal
    var letter: String {
        switch self {
        case .shortChant:     return "S"
        case .hymn:           return "H"
        case .sequence:       return "F"
        case .litany:         return "L"
        case .psalm:          return "P"
        case .everydayPrayer: return "E"
        }
    }

    var title: String {
        switch self {
        case .shortChant:     return "Short Chants"
        case .hymn:           return "Hymns"
        case .sequence:       return "Feast Poems"
        case .litany:         return "Litanies"
        case .psalm:          return "Psalms and Canticles"
        case .everydayPrayer: return "Everyday Prayers"
        }
    }

    /// One of them, for a kicker: "HYMN · 4:24", in the tile's own word
    var singular: String {
        switch self {
        case .shortChant:     return "Short chant"
        case .hymn:           return "Hymn"
        case .sequence:       return "Feast poem"
        case .litany:         return "Litany"
        case .psalm:          return "Psalm"
        case .everydayPrayer: return "Prayer"
        }
    }

    /// What the kind is, plainly, with the Church's own name for it
    var note: String {
        switch self {
        case .shortChant:
            return "Antiphons: a few lines, sung before or after a psalm, or on their own at the close of the day."
        case .hymn:
            return "Poems in verses, each verse sung to the same melody: at morning and evening prayer, at Adoration and in processions."
        case .sequence:
            return "Sequences: long poems sung at Mass, just before the Gospel, on the greatest feasts."
        case .litany:
            return "Short petitions, each answered by the same response: the singer calls, and everyone answers."
        case .psalm:
            return "Psalms, and canticles: great songs of praise like Mary's Magnificat and the Te Deum, sung verse by verse."
        case .everydayPrayer:
            return "The prayers said every day, the Rosary's and the Mass's among them, set to chant."
        }
    }

    /// Its chants, in the catalog's order
    var chants: [Chant] {
        ChantCatalog.all.filter { $0.form == self }
    }
}

// MARK: - ChantLength

/// The Types board's "Short on time?": the chants by how long they take.
enum ChantLength: String, CaseIterable, Identifiable {
    case underAMinute
    case aFewMinutes
    case aLongWhile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .underAMinute: return "Under a minute"
        case .aFewMinutes:  return "1 to 7 minutes"
        case .aLongWhile:   return "Over 7 minutes"
        }
    }

    static func of(_ duration: TimeInterval) -> ChantLength {
        if duration < 60 { return .underAMinute }
        if duration <= 7 * 60 { return .aFewMinutes }
        return .aLongWhile
    }

    /// Its chants, shortest first
    var chants: [Chant] {
        ChantCatalog.all
            .filter { ChantLength.of($0.duration) == self }
            .sorted { $0.duration < $1.duration }
    }
}

// MARK: - ChantSeason

/// The seasons of the Church's year as the library keeps them. The year
/// is cut where its chants change: Christmas runs on to Septuagesima, and
/// Lent begins there, when the Alleluia is put away. Pentecost is its own
/// week, the octave; after it the long green season runs to Advent. The
/// boundaries are `ScheduleService`'s, and for display only: they never
/// decide which mysteries are prayed.
enum ChantSeason: String, CaseIterable, Identifiable {
    case advent
    case christmas
    case lent
    case easter
    case pentecost
    case afterPentecost

    var id: String { rawValue }

    var title: String {
        switch self {
        case .advent:         return "Advent"
        case .christmas:      return "Christmas"
        case .lent:           return "Lent"
        case .easter:         return "Easter"
        case .pentecost:      return "Pentecost"
        case .afterPentecost: return "After Pentecost"
        }
    }

    /// "for Easter", "until Advent": the season as a preposition takes it
    var prose: String {
        self == .afterPentecost ? "the season after Pentecost" : title
    }

    var note: String { ChantLibraryData.seasonNotes[self] ?? "" }

    /// Its own chants, in the order the board lists them
    var chants: [Chant] {
        (ChantLibraryData.seasonChants[self] ?? []).compactMap { ChantCatalog.chant($0) }
    }

    /// Its painting, by subject (`ChantCatalog.painting(subject:)`)
    var painting: String {
        ChantLibraryData.seasonPaintings[self] ?? "glorious_coronation"
    }

    /// The chant to learn before the season comes
    var signatureChant: Chant? {
        ChantLibraryData.seasonSignatures[self].flatMap { ChantCatalog.chant($0) }
    }

    /// The season after this one, round the year
    var next: ChantSeason {
        let all = ChantSeason.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }

    // MARK: Dates

    /// The season `date` falls in
    static func season(on date: Date) -> ChantSeason {
        ChantYear.containing(date).season(on: date)
    }
}

// MARK: - ChantYear

/// One year of the Church, Advent to Advent, cut into the library's
/// seasons and into the four antiphons of Our Lady. What the Seasons
/// board's wheel draws.
struct ChantYear {

    struct Span<Value> {
        let value: Value
        let start: Date
        let end: Date
    }

    let start: Date
    let end: Date
    let seasons: [Span<ChantSeason>]
    let antiphons: [Span<MarianAntiphon>]

    private let calendar: Calendar

    init(containing date: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)
        let thisAdvent = ScheduleService.adventStart(year: year, calendar: calendar) ?? day

        let startYear = day >= thisAdvent ? year : year - 1
        let start = ScheduleService.adventStart(year: startYear, calendar: calendar) ?? day
        let end = ScheduleService.adventStart(year: startYear + 1, calendar: calendar)
            ?? calendar.date(byAdding: .day, value: 364, to: start) ?? day
        self.start = start
        self.end = end

        // Every boundary is ScheduleService's, where the app's calendar
        // lives; nothing here reckons a date of its own
        let easterYear = startYear + 1
        let christmas = calendar.date(from: DateComponents(year: startYear, month: 12, day: 25)) ?? start
        let easter = ScheduleService.easterSunday(year: easterYear, calendar: calendar) ?? end
        let septuagesima = ScheduleService.septuagesima(year: easterYear, calendar: calendar) ?? easter
        let pentecost = ScheduleService.pentecost(year: easterYear, calendar: calendar) ?? easter
        let trinity = ScheduleService.trinitySunday(year: easterYear, calendar: calendar) ?? pentecost

        let bounds: [(ChantSeason, Date, Date)] = [
            (.advent, start, christmas),
            (.christmas, christmas, septuagesima),
            (.lent, septuagesima, easter),
            (.easter, easter, pentecost),
            (.pentecost, pentecost, trinity),
            (.afterPentecost, trinity, end)
        ]
        seasons = bounds.map { Span(value: $0.0, start: $0.1, end: $0.2) }

        // The antiphons are read from the Prayer Book's own rule a day at
        // a time, so the wheel and Night Prayers can never disagree
        var runs: [Span<MarianAntiphon>] = []
        var cursor = start
        var runStart = start
        var current = PrayerBook.antiphon(on: start, calendar: calendar)
        while cursor < end {
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            let antiphon = next < end ? PrayerBook.antiphon(on: next, calendar: calendar) : current
            if antiphon != current || next >= end {
                runs.append(Span(value: current, start: runStart, end: next))
                runStart = next
                current = antiphon
            }
            cursor = next
        }
        antiphons = runs
    }

    /// The year holding `date`, built once a day: a year is some three
    /// hundred and sixty reads of the antiphon's rule, and the search
    /// results ask it of every row
    static func containing(_ date: Date) -> ChantYear {
        let day = Calendar.current.startOfDay(for: date)
        if let cached = cache, cached.day == day { return cached.year }
        let year = ChantYear(containing: day)
        cache = (day, year)
        return year
    }

    private static var cache: (day: Date, year: ChantYear)?

    func season(on date: Date) -> ChantSeason {
        let day = calendar.startOfDay(for: date)
        return seasons.first { day >= $0.start && day < $0.end }?.value ?? .afterPentecost
    }

    func span(of season: ChantSeason) -> Span<ChantSeason>? {
        seasons.first { $0.value == season }
    }

    /// 0…1 round the year
    func fraction(of date: Date) -> Double {
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1, max(0, date.timeIntervalSince(start) / total))
    }

    /// Whole days from `date` to the start of the season after its own
    func daysUntilNextSeason(from date: Date) -> (season: ChantSeason, days: Int) {
        let day = calendar.startOfDay(for: date)
        let current = season(on: day)
        let nextStart = span(of: current)?.end ?? end
        let days = calendar.dateComponents([.day], from: day, to: nextStart).day ?? 0
        return (current.next, max(0, days))
    }
}

// MARK: - ChantFeast

/// A feast the library has a chant for: Our Lady of the Rosary and her
/// Litany, All Souls and the Dies Iræ. The 1962 calendar's dates.
struct ChantFeast: Identifiable, Hashable {

    enum Rule: Hashable {
        /// The same day every year
        case fixed(month: Int, day: Int)
        /// Days from Easter Sunday: Pentecost is 49
        case easter(Int)
        /// The last Sunday of October: Christ the King
        case lastSundayOfOctober
        /// The Sunday between the 2nd and the 5th of January, else the
        /// 2nd: the Holy Name
        case holyName
    }

    let id: String
    let name: String
    let rule: Rule
    let chantID: String
    /// Its painting, by subject, where one is drawn for it
    var painting: String? = nil

    var chant: Chant? { ChantCatalog.chant(chantID) }

    func date(in year: Int, calendar: Calendar = .current) -> Date? {
        switch rule {
        case .fixed(let month, let day):
            return calendar.date(from: DateComponents(year: year, month: month, day: day))
        case .easter(let offset):
            return ScheduleService.easterSunday(year: year, calendar: calendar)
                .flatMap { calendar.date(byAdding: .day, value: offset, to: $0) }
        case .lastSundayOfOctober:
            guard let last = calendar.date(from: DateComponents(year: year, month: 10, day: 31)) else { return nil }
            let weekday = calendar.component(.weekday, from: last)  // 1 = Sunday
            return calendar.date(byAdding: .day, value: -(weekday - 1), to: last)
        case .holyName:
            for day in 2...5 {
                if let date = calendar.date(from: DateComponents(year: year, month: 1, day: day)),
                   calendar.component(.weekday, from: date) == 1 {
                    return date
                }
            }
            return calendar.date(from: DateComponents(year: year, month: 1, day: 2))
        }
    }

    /// The next `count` feasts on or after `date`, soonest first
    static func upcoming(from date: Date, count: Int, calendar: Calendar = .current) -> [(feast: ChantFeast, date: Date)] {
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)
        var found: [(feast: ChantFeast, date: Date)] = []
        for feast in ChantLibraryData.feasts {
            for candidate in [year, year + 1] {
                if let when = feast.date(in: candidate, calendar: calendar), when >= day {
                    found.append((feast, when))
                    break
                }
            }
        }
        return Array(found.sorted { $0.date < $1.date }.prefix(count))
    }

    static func feast(_ id: String) -> ChantFeast? {
        ChantLibraryData.feasts.first { $0.id == id }
    }
}

// MARK: - ChantWeekday

/// Each day of the week's traditional devotion, and its chants: the
/// Today board's row of seven.
struct ChantWeekday: Identifiable, Hashable {
    /// 1 = Sunday, as `Calendar` counts
    let weekday: Int
    /// "the Blessed Sacrament"
    let devotion: String
    /// "Thursdays honour the Blessed Sacrament"
    let headline: String
    /// What "Play all" names them: "chants of the Blessed Sacrament"
    let collective: String
    let chantIDs: [String]
    /// Its painting, by subject (`ChantCatalog.painting(subject:)`)
    let painting: String

    var id: Int { weekday }

    var chants: [Chant] { chantIDs.compactMap { ChantCatalog.chant($0) } }

    /// "Thursday"
    var name: String {
        let symbols = Calendar.current.standaloneWeekdaySymbols
        return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : ""
    }

    /// "T"
    var initial: String { String(name.prefix(1)) }

    static func of(_ date: Date, calendar: Calendar = .current) -> ChantWeekday {
        let weekday = calendar.component(.weekday, from: date)
        return ChantLibraryData.weekdays.first { $0.weekday == weekday } ?? ChantLibraryData.weekdays[0]
    }
}

// MARK: - ChantMonth

/// The month's traditional dedication, with what the library sings for it.
struct ChantMonth: Hashable {
    let month: Int
    /// "The Month of the Holy Rosary"
    let title: String
    let chantIDs: [String]
    /// A set of chants sung together for it — the Sung Rosary in October
    let occasionID: String?
    /// The month's own feast, which names its chant
    let feastID: String?

    var chants: [Chant] { chantIDs.compactMap { ChantCatalog.chant($0) } }
    var occasion: ChantOccasion? { occasionID.flatMap { ChantOccasion.occasion($0) } }
    var feast: ChantFeast? { feastID.flatMap { ChantFeast.feast($0) } }

    /// "October"
    var name: String {
        let symbols = Calendar.current.standaloneMonthSymbols
        return symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
    }

    static func of(_ date: Date, calendar: Calendar = .current) -> ChantMonth? {
        let month = calendar.component(.month, from: date)
        return ChantLibraryData.months.first { $0.month == month }
    }
}

// MARK: - ChantHour

/// The four times of the day the library sings for, as the Today board's
/// arc draws them: the Angelus at six and at noon (the Regina Cæli in its
/// place through Eastertide), the Magnificat at evening, and at night the
/// antiphon of Our Lady the season keeps.
enum ChantHour: Int, CaseIterable, Identifiable {
    case morning
    case noon
    case evening
    case night

    var id: Int { rawValue }

    /// "6 AM", "NOON"
    var time: String {
        switch self {
        case .morning: return "6 am"
        case .noon:    return "Noon"
        case .evening: return "Evening"
        case .night:   return "Night"
        }
    }

    /// The clock hour the chant is sung at, for placing the hour on the arc
    var clockHour: Double {
        switch self {
        case .morning: return 6
        case .noon:    return 12
        case .evening: return 18
        case .night:   return 21
        }
    }

    /// "It is evening: time for Mary's song, the Magnificat", naming the
    /// chant the hour sings on `date`: through the Easter season morning
    /// and noon sing Queen of Heaven, not the Angelus
    func headline(on date: Date, calendar: Calendar = .current) -> String {
        let eastertide = PrayerBook.isEastertide(date, calendar: calendar)
        switch self {
        case .morning:
            return eastertide ? "It is morning: time to sing Queen of Heaven" : "It is morning: time for the Angelus"
        case .noon:
            return eastertide ? "It is midday: time to sing Queen of Heaven" : "It is midday: time for the Angelus"
        case .evening:
            return "It is evening: time for Mary's song, the Magnificat"
        case .night:
            return "It is night: time for the song to Mary"
        }
    }

    func chant(on date: Date, calendar: Calendar = .current) -> Chant? {
        switch self {
        case .morning, .noon:
            return PrayerBook.isEastertide(date, calendar: calendar)
                ? ChantCatalog.chant("regina_caeli_simple")
                : ChantCatalog.chant("angelus")
        case .evening:
            return ChantCatalog.chant("magnificat")
        case .night:
            return ChantCatalog.antiphonOfTheSeason(on: date)
        }
    }

    /// The hour it is, on the Prayer Book's turns: four, eleven, three
    /// and eight
    static func present(at date: Date, calendar: Calendar = .current) -> ChantHour {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case PrayerBook.dayBeginsAtHour..<11: return .morning
        case 11..<15: return .noon
        case 15..<20: return .evening
        default:      return .night
        }
    }
}

// MARK: - ChantOccasion

/// Where a step of an occasion takes its chant from: a chant by id, or
/// the antiphon of Our Lady the season sings tonight.
enum ChantRef: Hashable {
    case chant(String)
    case antiphonOfTheSeason

    func resolve(on date: Date = Date()) -> Chant? {
        switch self {
        case .chant(let id):        return ChantCatalog.chant(id)
        case .antiphonOfTheSeason:  return ChantCatalog.antiphonOfTheSeason(on: date)
        }
    }
}

/// One chant of an occasion, sung `times` over: the Ave Maria ten
/// times in a decade.
struct ChantOccasionStep: Hashable {
    let chant: ChantRef
    var times: Int = 1
}

/// What happens between chants, in red, and the chants it leads to,
/// sung `rounds` over: the five decades.
struct ChantOccasionBlock: Hashable {
    let rubric: String?
    let steps: [ChantOccasionStep]
    var rounds: Int = 1
}

/// A set of chants in the order they are sung, for an occasion:
/// Benediction, a visit, a sung Rosary.
struct ChantOccasion: Identifiable, Hashable {
    let id: String
    let title: String
    /// One line under the title
    let note: String
    let painting: String
    let blocks: [ChantOccasionBlock]

    /// Every chant in the order it sounds, repeats and rounds unrolled
    func sequence(on date: Date = Date()) -> [Chant] {
        var chants: [Chant] = []
        for block in blocks {
            for _ in 0..<max(1, block.rounds) {
                for step in block.steps {
                    guard let chant = step.chant.resolve(on: date) else { continue }
                    chants.append(contentsOf: Array(repeating: chant, count: max(1, step.times)))
                }
            }
        }
        return chants
    }

    /// The different chants it holds
    func distinctChants(on date: Date = Date()) -> [Chant] {
        var seen = Set<String>()
        return sequence(on: date).filter { seen.insert($0.id).inserted }
    }

    func duration(on date: Date = Date()) -> TimeInterval {
        sequence(on: date).reduce(0) { $0 + $1.duration }
    }

    static func occasion(_ id: String) -> ChantOccasion? {
        ChantLibraryData.occasions.first { $0.id == id }
    }
}

// MARK: - ChantLearningPath

/// A stage of the Learn board's course: the Rosary's prayers first, then
/// the antiphons of Our Lady, then the hymns of adoration.
struct ChantLearningPath: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let chantIDs: [String]

    var chants: [Chant] { chantIDs.compactMap { ChantCatalog.chant($0) } }
}

// MARK: - ChantLearningStep

/// The four steps a chant is learned in, the learner's own to take: no
/// step is scored, and the last is theirs to call done.
enum ChantLearningStep: Int, CaseIterable, Identifiable {
    case listen = 1
    case readAlong = 2
    case singAlong = 3
    case onYourOwn = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .listen:    return "Listen"
        case .readAlong: return "Read along"
        case .singAlong: return "Sing along"
        case .onYourOwn: return "On your own"
        }
    }

    var note: String {
        switch self {
        case .listen:    return "Hear it sung"
        case .readAlong: return "Follow the words"
        case .singAlong: return "Sing with the recording"
        case .onYourOwn: return "Sing without help"
        }
    }

    var next: ChantLearningStep? { ChantLearningStep(rawValue: rawValue + 1) }
}

// MARK: - Chant + library

extension Chant {

    var form: ChantForm { ChantLibraryData.forms[id] ?? .hymn }

    /// What it is, for a kicker — "CANTICLE · 7:31": its kind's word for
    /// one of them, unless the kind holds more than one sort of chant
    var kindName: String { ChantLibraryData.kindNames[id] ?? form.singular }

    /// The seasons it belongs to; none for a chant of the whole year
    var seasons: [ChantSeason] {
        ChantSeason.allCases.filter { ChantLibraryData.seasonChants[$0]?.contains(id) == true }
    }

    /// Chants of one work in its settings share this: the simple and the
    /// solemn Salve Regina, never the Rosary's Ave Maria and the Advent
    /// Offertory, which share only a name
    var workKey: String {
        "\(latinTitle)|\(prayerIDs.sorted().joined(separator: ","))"
    }

    /// The other settings of the same work, this one among them, in the
    /// catalog's order (simple before solemn)
    var settings: [Chant] {
        ChantCatalog.all.filter { $0.workKey == workKey }
    }

    /// "Simple", "Solemn": the setting without its "melody", for a pill;
    /// none where the title already says it, so Credo III never plays as
    /// "Credo III · Credo III"
    var settingName: String? {
        guard let setting, !latinTitle.localizedCaseInsensitiveContains(setting) else { return nil }
        let word = setting
            .replacingOccurrences(of: " melody", with: "")
            .replacingOccurrences(of: " tone", with: "")
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    /// When it is sung in the year, against `date`: "this season, until
    /// Advent", "for Easter", or nil for a chant of every season
    func seasonLine(on date: Date = Date()) -> String? {
        let seasons = self.seasons
        guard !seasons.isEmpty else { return nil }
        let now = ChantYear.containing(date).season(on: date)
        if seasons.contains(now) {
            var last = now
            while seasons.contains(last.next), last.next != now { last = last.next }
            return "this season, until \(last.next.prose)"
        }
        return "for \(seasons[0].prose)"
    }

    /// The Prayer Book's own text of the prayer the chant sings, when
    /// it carries one
    var bookPrayer: BookPrayer? {
        for id in prayerIDs {
            if let prayer = PrayerBook.prayer(id) ?? BookPrayer.bundled(id, origin: nil, note: nil) {
                return prayer
            }
        }
        return nil
    }

    /// The words, as the chant's own lines when it has them, else the
    /// Prayer Book's text of its prayer
    var words: (latin: String?, english: String?)? {
        if hasLines {
            return (lines.map(\.latin).joined(separator: "\n"),
                    lines.map(\.english).joined(separator: "\n"))
        }
        guard let prayer = bookPrayer else { return nil }
        return (prayer.latin, prayer.english)
    }
}

// MARK: - ChantCatalog + library

extension ChantCatalog {

    /// "All 77 chants work offline." Said at the foot of the library,
    /// counted from the catalog.
    static var offlineNote: String {
        "All \(all.count) chants work offline."
    }

    /// The painting a chant is shown with where a board hangs one: the
    /// antiphons of Our Lady, an occasion's chants
    static func painting(for chant: Chant) -> String {
        ChantLibraryData.paintings[chant.id]
            ?? ChantLibraryData.groupPaintings[chant.groupID]
            ?? "glorious_coronation"
    }

    /// A painting asked for by its subject — `season_advent`,
    /// `devotion_holy_souls` — or the painting standing in for it until
    /// that imageset is in the app: `fallback` when one is given, else
    /// the curation's (`ChantLibraryData.subjectPaintings`). The one place
    /// the swap happens, so a painting that lands needs no other change.
    /// A name that is already an imageset is itself.
    static func painting(subject: String, else fallback: String? = nil) -> String {
        // Whether the subject's imageset is in the app is asked once: the
        // image cache keeps only what it finds, and the answer cannot
        // change while the app runs
        let present: Bool
        if let known = subjectsPresent[subject] {
            present = known
        } else {
            present = ImageCacheService.shared.image(named: subject) != nil
            subjectsPresent[subject] = present
        }
        if present { return subject }
        return fallback ?? ChantLibraryData.subjectPaintings[subject] ?? "glorious_coronation"
    }

    private static var subjectsPresent: [String: Bool] = [:]

    /// How the Today board introduces tonight's antiphon
    static func tonightLine(for chant: Chant) -> String {
        ChantLibraryData.tonightLines[chant.workKey] ?? chant.detail
    }
}
