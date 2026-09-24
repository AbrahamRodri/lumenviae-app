//
//  CarloAcutisData.swift
//  Lumen Viae
//
//  St. Carlo Acutis: his life in five short chapters, his four
//  devotions, his sayings, and a prayer for his intercession.
//
//  The life and the devotions are `LibraryReading`s, read and stepped
//  through in `LibraryReadingView` like the Marian Library's entries;
//  each devotion ends in the door to where the app prays it with him.
//
//  His sayings are the ones his mother and his biographers have handed
//  on; none is from a book of his own, because he wrote none.
//

import Foundation

enum CarloAcutisData {

    /// Not on the 1962 calendar — he was raised to the altars in 2025 —
    /// so it names the day and opens no Mass
    static let feast = KeptFeast(
        month: 10,
        day: 12,
        name: "St. Carlo Acutis",
        inMissal: false
    )

    static var shelves: [ReadingShelf] { [life, devotions] }

    // MARK: - His Life

    static let life = ReadingShelf(
        id: "carlo_life",
        icon: "ch-monstrance",
        title: "The Life of St. Carlo",
        marginLabel: "His\nlife",
        subtitle: "Milan, Assisi, and the internet",
        entries: [
            LibraryReading(
                id: "carlo_boy",
                title: "An Ordinary Boy",
                detail: "London, 1991 · Milan",
                paragraphs: [
                    "Carlo Acutis was born in London on 3 May 1991, where his Italian parents were living for his father's work, and was baptised there a fortnight later. Within a few months the family went home to Milan. His parents, Andrea and Antonia, were not people who went to Mass; his mother said afterward that she had been to church three times in her life before her son took her.",
                    "It was a Polish nanny, Beata, who taught the small boy to pray, and he took to it as though it had been waiting for him. He asked to be taken into every church he passed, to greet Jesus in the tabernacle, and he asked for his First Communion early. He received it on 16 June 1998, at seven, in the quiet of a convent of enclosed nuns outside Milan, and from that day he went to Mass every day of his life.",
                    "He was, for all that, an ordinary boy of his place and time. He loved football and his dogs and cats, made funny films with his friends, played video games — though he rationed himself to an hour a week — and was good at a computer long before most adults. His mother, reading the Scriptures to answer his questions, came back to the faith herself."
                ],
                quote: ReadingQuote(
                    text: "To always be close to Jesus, that's my life plan.",
                    citation: "St. Carlo Acutis, as a child"
                )
            ),
            LibraryReading(
                id: "carlo_programmer",
                title: "God's Programmer",
                detail: "The Eucharistic miracles exhibition",
                paragraphs: [
                    "Carlo taught himself to program from university textbooks, and built websites for his parish, his school, and a volunteer project of the Jesuits. His classmates called him the one to ask when a computer would not do what it was told.",
                    "At eleven he set out on the work he is remembered for: a catalogue of the Eucharistic miracles the Church has recognised through the centuries — the flesh and blood of Lanciano, the Host of Siena kept incorrupt since 1730, the bleeding Host of Buenos Aires examined in the 1990s. He persuaded his parents to take him to many of the places himself, photographed them, wrote up each one, and built the panels and the website to show them. It took him two and a half years.",
                    "The exhibition has since been shown in thousands of parishes on five continents, and at shrines from Fatima to Lourdes. He wanted the internet to carry people toward the tabernacle, not away from it: the same screen that could waste a life, he thought, could just as well be used for heaven."
                ],
                quote: ReadingQuote(
                    text: "The more Eucharist we receive, the more we will become like Jesus, so that on this earth we will have a foretaste of heaven.",
                    citation: "St. Carlo Acutis"
                ),
                doors: [
                    .act(.mass, note: "The day's Mass, where every miracle points")
                ]
            ),
            LibraryReading(
                id: "carlo_friend",
                title: "A Friend to the Forgotten",
                detail: "School, the streets of Milan, the porter",
                paragraphs: [
                    "At school Carlo stood beside the classmates no one else stood beside. He defended a boy with disabilities from the others' jokes, took in the new ones, and went to the homes of friends whose parents were divorcing so that they would not be alone with it.",
                    "With his pocket money he bought sleeping bags for the men who slept rough in Milan, and he carried meals to them himself, sometimes in the family's leftover containers, stopping to talk. When he died, the family was astonished by the number of strangers — the poor of the neighbourhood, immigrants, the homeless — who came to his funeral and told them what he had done.",
                    "The family's household help, Rajesh Mohur, was a Hindu from Mauritius. Carlo spoke to him about Jesus and the sacraments so simply and so often that Rajesh asked to be baptised, and said afterward that it was the boy's example that had brought him."
                ],
                quote: ReadingQuote(
                    text: "Sadness is looking at ourselves; happiness is looking towards God.",
                    citation: "St. Carlo Acutis"
                )
            ),
            LibraryReading(
                id: "carlo_offering",
                title: "The Offering",
                detail: "Monza, October 2006",
                paragraphs: [
                    "In the first days of October 2006, Carlo came down with what everyone took for the flu. Within a few days he was in hospital at Monza, diagnosed with acute promyelocytic leukaemia, the most aggressive form of the disease. He was fifteen.",
                    "He was not afraid. He told his mother that he was offering all his sufferings for the Pope and for the Church, and he received the Anointing of the Sick with calm. When a nurse asked if he was in much pain, he said that there were people who suffered much more than he did.",
                    "He died on 12 October 2006. He had asked to be buried in Assisi, the town of St. Francis, which he loved above any place on earth, and he was. In 2019 his remains were moved into the Sanctuary of the Spoliation, the church where the young Francis stripped himself of his father's clothes, and there he lies in a glass tomb, dressed as he lived, in jeans and trainers."
                ],
                quote: ReadingQuote(
                    text: "I offer all the suffering I will have to suffer to the Lord for the Pope and for the Church, so as not to go to Purgatory but to go straight to Heaven.",
                    citation: "St. Carlo Acutis, in his last illness"
                ),
                feast: feast
            ),
            LibraryReading(
                id: "carlo_saint",
                title: "The First Millennial Saint",
                detail: "Beatified 2020 · canonised 2025",
                paragraphs: [
                    "In 2013 a small boy in Campo Grande, Brazil, born with a malformed pancreas that made him vomit whatever he ate, touched a relic of Carlo — a piece of one of his shirts — and asked to stop throwing up. He was healed, and the Church, after years of examination, recognised it as a miracle. Carlo was beatified in Assisi on 10 October 2020.",
                    "A second miracle followed: in 2022 a young Costa Rican woman studying in Florence, Valeria Valverde, was given little chance of surviving a head injury from a bicycle accident. Her mother prayed at Carlo's tomb in Assisi, and Valeria recovered completely.",
                    "His canonisation was set for April 2025 and postponed when Pope Francis died in the days before it. Pope Leo XIV canonised him in St. Peter's Square on 7 September 2025, together with Pier Giorgio Frassati — the first saint to have grown up with the internet. His feast is kept on 12 October, the day he died."
                ],
                quote: ReadingQuote(
                    text: "All people are born as originals, but many die as photocopies.",
                    citation: "St. Carlo Acutis"
                ),
                feast: feast
            )
        ]
    )

    // MARK: - His Devotions

    static let devotions = ReadingShelf(
        id: "carlo_devotions",
        icon: "ch-monstrance",
        title: "The Devotions of St. Carlo",
        marginLabel: "His\ndevotions",
        subtitle: "What he did every day, and how to do it with him",
        entries: [
            LibraryReading(
                id: "carlo_mass",
                title: "Daily Mass and Adoration",
                detail: "\u{201C}My highway to heaven\u{201D}",
                paragraphs: [
                    "From his First Communion at seven until he died, Carlo went to Mass every day. When the family travelled, the first thing he looked up was where Mass was said. He stayed afterward, or came before, to pray before the tabernacle, and he did not understand why the crowds queued for concerts and football matches while Jesus waited in empty churches.",
                    "He called the Eucharist his highway to heaven. It was the whole of his faith in one place: Christ really present, body, blood, soul and divinity, and given to be received. He made his exhibition of Eucharistic miracles so that others would believe it as simply as he did."
                ],
                quote: ReadingQuote(
                    text: "When we face the sun we get a tan, but when we stand before Jesus in the Eucharist we become saints.",
                    citation: "St. Carlo Acutis"
                ),
                doors: [
                    .act(.mass, note: "The day's Mass in the 1962 Missal")
                ]
            ),
            LibraryReading(
                id: "carlo_rosary",
                title: "The Daily Rosary",
                detail: "\u{201C}The shortest ladder to heaven\u{201D}",
                paragraphs: [
                    "Every day Carlo kept what he called his appointment with Our Lady: he prayed the Rosary. He consecrated himself to her, renewed the consecration often, and made pilgrimages to Fatima and Lourdes.",
                    "He liked to say that the Virgin Mary was the only woman in his life. The Rosary was not a duty for him but a conversation he looked forward to, bead by bead — the life of her Son, seen through her eyes."
                ],
                quote: ReadingQuote(
                    text: "The Rosary is the shortest ladder to climb to heaven.",
                    citation: "St. Carlo Acutis"
                ),
                doors: [
                    .act(.todaysRosary, note: "Pray it with him today"),
                    .page(.marianLibrary, icon: "ch-lily", title: "The Marian Library", note: "The Lady he kept his appointment with")
                ]
            ),
            LibraryReading(
                id: "carlo_confession",
                title: "Weekly Confession",
                detail: "The hot-air balloon",
                paragraphs: [
                    "Carlo went to confession every week, and he explained why with a picture a child could understand. A hot-air balloon rises by dropping its weights; the soul rises to God the same way, by letting go of its sins, even the small ones that hold it down.",
                    "He examined his conscience honestly, and what he confessed was ordinary — impatience, greed at the table, laziness at school. He did not wait for great sins to go; he went so that small ones would never grow."
                ],
                quote: ReadingQuote(
                    text: "What does it matter if you can win a thousand battles if you cannot win against your own corrupt passions?",
                    citation: "St. Carlo Acutis"
                )
            ),
            LibraryReading(
                id: "carlo_angel",
                title: "His Guardian Angel",
                detail: "\u{201C}Your best friend\u{201D}",
                paragraphs: [
                    "Carlo spoke to his guardian angel as to a companion who was always there, and urged his friends to do the same: to ask the angel's help constantly, in small things as well as great.",
                    "It was of a piece with the rest of him. Heaven was not far away; it was near, and full of friends — the angels, the saints, Our Lady — and he lived as one expected there."
                ],
                quote: ReadingQuote(
                    text: "Continuously ask your guardian angel for help. Your guardian angel has to become your best friend.",
                    citation: "St. Carlo Acutis"
                )
            )
        ]
    )

    // MARK: - His Life, Dated

    struct Moment: Hashable {
        let year: String
        let title: String
        let line: String
        let readingID: String
    }

    /// His life as the page's timeline, each moment opening its chapter
    static let timeline: [Moment] = [
        Moment(year: "1991", title: "Born in London", line: "3 May, to Italian parents; home to Milan within months", readingID: "carlo_boy"),
        Moment(year: "1998", title: "First Communion", line: "At seven — and daily Mass from that day on", readingID: "carlo_boy"),
        Moment(year: "2002", title: "God's programmer", line: "Begins his exhibition of the Eucharistic miracles", readingID: "carlo_programmer"),
        Moment(year: "2005", title: "A friend to the forgotten", line: "High school in Milan: the bullied, the homeless, the porter who asked to be baptised", readingID: "carlo_friend"),
        Moment(year: "2006", title: "The offering", line: "Leukaemia at fifteen, offered for the Pope and the Church", readingID: "carlo_offering"),
        Moment(year: "2020", title: "Beatified in Assisi", line: "10 October, after a boy in Brazil was healed", readingID: "carlo_saint"),
        Moment(year: "2025", title: "Canonised", line: "7 September, by Pope Leo XIV", readingID: "carlo_saint")
    ]

    // MARK: - His Rule of Life

    struct Habit: Hashable {
        let icon: String
        let name: String
        let often: String
        let readingID: String
        let act: PrayerShortcut?
        let actTitle: String?
    }

    /// What he did, every day or every week — each with the door to do
    /// it with him today
    static let rule: [Habit] = [
        Habit(icon: "ch-altar", name: "Holy Mass", often: "Daily", readingID: "carlo_mass", act: .mass, actTitle: "The day's Mass"),
        Habit(icon: "ch-monstrance", name: "Adoration", often: "Daily", readingID: "carlo_mass", act: nil, actTitle: nil),
        Habit(icon: "ch-rosary", name: "The Rosary", often: "Daily", readingID: "carlo_rosary", act: .todaysRosary, actTitle: "Pray it"),
        Habit(icon: "ph-hands-praying", name: "Confession", often: "Weekly", readingID: "carlo_confession", act: nil, actTitle: nil),
        Habit(icon: "ph-sparkle", name: "His guardian angel", often: "Always", readingID: "carlo_angel", act: nil, actTitle: nil)
    ]

    /// One saying a day, the same all day
    static func sayingOfTheDay(_ date: Date = .now) -> Int {
        (Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0) % sayings.count
    }

    // MARK: - His Sayings

    static let sayings: [String] = [
        "The Eucharist is my highway to heaven.",
        "All people are born as originals, but many die as photocopies.",
        "To always be close to Jesus, that's my life plan.",
        "Our aim has to be the infinite and not the finite. The infinite is our homeland. We have always been expected in Heaven.",
        "Sadness is looking at ourselves; happiness is looking towards God.",
        "The Virgin Mary is the only woman in my life.",
        "The Rosary is the shortest ladder to climb to heaven.",
        "Not I, but God."
    ]

    // MARK: - A Prayer

    /// A prayer for his intercession, set in the prayer-book grammar
    static let prayer = """
O God, who gave to the young Carlo Acutis a heart aflame with love for the Holy Eucharist, grant, we pray, that through his intercession we too may seek Thee above all things, live as originals and not as copies, and one day share with him the joy of Thy kingdom. Through Christ our Lord. ℟. Amen.

St. Carlo Acutis, ℟. pray for us.
"""
}
