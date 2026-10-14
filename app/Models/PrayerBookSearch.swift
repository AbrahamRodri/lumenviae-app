//
//  PrayerBookSearch.swift
//  Lumen Viae
//
//  How the Prayer Book is searched: prayers by name or words, orders of
//  prayer and topics by name. Every name is folded and split once, the
//  first time the book is searched, so a search reads prepared words
//  rather than folding the whole book again at every keystroke.
//

import Foundation

extension PrayerBook {

    /// Whether two names are one name, whatever their case, accents or
    /// leading article: "Tantum Ergo" and "Tantum ergo", "The Memorare"
    /// and "Memorare"
    static func isSameName(_ one: String, _ other: String) -> Bool {
        func bare(_ name: String) -> String {
            let folded = SearchText.fold(name)
            return folded.hasPrefix("the ") ? String(folded.dropFirst(4)) : folded
        }
        return bare(one) == bare(other)
    }

    /// The other names a prayer is looked for by
    static let prayerSearchWords: [String: [String]] = [
        "litany_loreto": ["litany of loreto", "loretto", "litany of our lady"],
        "peace_prayer": ["prayer of st francis", "instrument of thy peace", "instrument of your peace"],
        "divine_mercy_chaplet": ["divine mercy", "chaplet", "st faustina"],
        "efficacious_novena": ["novena", "padre pio"],
        "litany_of_the_saints": ["all saints", "litaniae sanctorum"],
        "litany_seven_sorrows": ["our lady of sorrows", "seven sorrows"],
        "st_anthony": ["lost things", "anthony of padua"],
        "st_jude": ["hopeless cases", "desperate cases"],
        "st_peregrine": ["cancer"],
        "prayer_for_travel": ["journey", "travel", "itinerarium"],
        "aquinas_before_study": ["study", "students", "exams"],
        "prayer_for_the_sick": ["sick", "illness", "healing"],
        "lead_kindly_light": ["newman"],
        "newman_definite_service": ["newman", "purpose"],
        "christ_the_king": ["consecration to christ the king"],
        "consecration_sacred_heart": ["sacred heart", "enthronement"],
        "st_benedict_medal": ["vade retro satana", "benedict medal", "exorcism"],
        "hail_holy_queen": ["salve regina"],
        "st_michael_prayer": ["st michael", "michael the archangel"],
        "ad_te_beate_ioseph": ["st joseph", "prayer to st joseph"],
        "angele_dei": ["guardian angel"],
        "memorare": ["remember o most gracious"],
        "anima_christi": ["soul of christ"],
        "regina_caeli": ["queen of heaven rejoice"],
    ]

    /// The other names an order of prayer is looked for by
    static let orderSearchWords: [String: [String]] = [
        "visit": ["blessed sacrament", "visit to the blessed sacrament", "adoration", "tabernacle"],
        "table": ["grace", "meals", "at table"],
        "holy_souls": ["purgatory", "the dead", "for the dead", "holy souls", "for the holy souls"],
        "trouble": ["help", "danger"],
    ]


    /// Prayers a search finds. A name answers when every word searched
    /// begins one of its words — "St Joseph", "loreto", "hail ma" — the
    /// title, the Latin title and the names it is looked for by alike,
    /// with "st", "st." and "saint" one word; a prayer whose words hold
    /// the whole search comes after the names. It once matched only the
    /// whole search as one string, so "St Michael" found nothing.
    static func search(_ needle: String) -> [BookPrayer] {
        let wanted = searchWords(needle, asName: false)
        guard !wanted.isEmpty else { return [] }

        let phrase = SearchText.needle(needle)
        let readsWords = phrase.count >= 4

        var named: [BookPrayer] = []
        var worded: [BookPrayer] = []
        for entry in prayerIndex {
            if entry.names.contains(where: { answers(wanted, $0) }) {
                named.append(entry.prayer)
            } else if readsWords, entry.english.contains(phrase) || entry.latin.contains(phrase) {
                worded.append(entry.prayer)
            }
        }
        return named + worded
    }

    /// The orders of prayer a search names — "blessed sacrament" finds
    /// Visiting Jesus in Church — by their title, Latin title, when they
    /// are said and the names they are looked for by
    static func searchOrders(_ needle: String) -> [PrayerOrder] {
        let wanted = searchWords(needle, asName: false)
        guard !wanted.isEmpty, wanted.joined().count >= 3 else { return [] }
        return orderIndex
            .filter { entry in entry.names.contains { answers(wanted, $0) } }
            .map(\.order)
    }

    /// The chapters a search names as topics: "mary" finds Prayers to
    /// Mary, "holy ghost" the Holy Spirit's, under the names the book
    /// once printed as well as its own. Every word searched must begin a
    /// word of the topic's name, so "hail mary" finds the prayer and not
    /// the whole chapter, and the small words — "the", "prayers", "to" —
    /// count for nothing, or every topic would answer "pra".
    static func topics(matching needle: String) -> [PrayerBookChapter] {
        let wanted = topicWords(needle)
        guard let last = wanted.last, wanted.joined().count >= 3, last.count >= 2 else { return [] }

        return topicIndex
            .filter { entry in
                entry.names.contains { words in
                    wanted.allSatisfy { want in words.contains { $0.hasPrefix(want) } }
                }
            }
            .map(\.chapter)
    }

    // MARK: The prepared words

    /// A prayer as the search reads it: each of its names as words, and
    /// its text folded, English and Latin
    private struct PrayerEntry {
        let prayer: BookPrayer
        let names: [[String]]
        let english: String
        let latin: String
    }

    private struct OrderEntry {
        let order: PrayerOrder
        let names: [[String]]
    }

    private struct TopicEntry {
        let chapter: PrayerBookChapter
        let names: [[String]]
    }

    /// Every prayer the book prints, each once, in the order the topics
    /// first print it, which is the order the results are listed in
    private static let prayerIndex: [PrayerEntry] = {
        var seen = Set<String>()
        return chapters.flatMap(\.prayerIDs)
            .filter { seen.insert($0).inserted }
            .compactMap { prayer($0) }
            .map { prayer in
                PrayerEntry(
                    prayer: prayer,
                    names: nameWords([prayer.title, prayer.listTitle, prayer.latinTitle ?? ""] + prayer.searchWords),
                    english: SearchText.fold(prayer.english),
                    latin: SearchText.fold(prayer.latin ?? "")
                )
            }
    }()

    private static let orderIndex: [OrderEntry] = orders.map { order in
        OrderEntry(order: order, names: nameWords([order.title, order.latinTitle, order.occasion] + order.searchWords))
    }

    private static let topicIndex: [TopicEntry] = chapters.map { chapter in
        let names = [chapter.title, chapter.topic, chapter.latinTitle] + chapter.searchWords
        return TopicEntry(chapter: chapter, names: names.map { topicWords($0) }.filter { !$0.isEmpty })
    }

    /// Names as words, a name with none left out, since it answers nothing
    private static func nameWords(_ names: [String]) -> [[String]] {
        names.map { searchWords($0) }.filter { !$0.isEmpty }
    }

    /// Every word wanted begins one of the name's words. A lone "st"
    /// searched is a saint's or the start of a word, so it finds St
    /// Michael and the Stabat Mater alike.
    private static func answers(_ wanted: [String], _ words: [String]) -> Bool {
        wanted.allSatisfy { want in
            words.contains { $0.hasPrefix(want) || (want == "st" && $0 == "saint") }
        }
    }

    /// A name or a search as the prayer search reads it: folded, split
    /// into words, the words that name nothing ("the", "of", "to") left
    /// out, unless they are all there is. In a name, "st" and "st." read
    /// as "saint"; searched, "st" stays as typed (`answers`).
    private static func searchWords(_ text: String, asName: Bool = true) -> [String] {
        let words = SearchText.fold(text)
            .split { !$0.isLetter }
            .map { asName && $0 == "st" ? "saint" : String($0) }
        let kept = words.filter { !searchStopWords.contains($0) }
        return kept.isEmpty ? words : kept
    }

    private static let searchStopWords: Set<String> = ["a", "an", "and", "of", "the", "to", "o", "for", "in", "on", "at"]

    private static let topicStopWords: Set<String> = [
        "a", "an", "and", "at", "for", "in", "of", "on", "the", "to", "with",
        "pray", "prayer", "prayers"
    ]

    /// A name as the topic search reads it: folded, split into words,
    /// the small words dropped
    private static func topicWords(_ text: String) -> [String] {
        SearchText.fold(text)
            .split { !$0.isLetter }
            .map(String.init)
            .filter { !topicStopWords.contains($0) }
    }
}
