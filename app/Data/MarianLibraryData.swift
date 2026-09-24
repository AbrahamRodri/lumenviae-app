//
//  MarianLibraryData.swift
//  Lumen Viae
//
//  The Marian Library's content: six shelves of entries on Our Lady,
//  and the Marian feasts of the 1962 calendar.
//
//  Each entry is a short reading, not a card: a few paragraphs of prose,
//  one saying set apart as a quotation, and — where the app holds it —
//  the door to where the truth is prayed: its feast in the Missal, its
//  mysteries on the beads, its prayer, or the book it comes from.
//
//  Scripture is quoted from the Douay-Rheims with its numbering (3 Kings,
//  not 1 Kings), as everywhere else in the app. Feasts marked `inMissal`
//  are on the universal 1962 calendar and the Missal will open them;
//  local feasts are named without a door, since the missal would open a
//  different day's Mass.
//

import Foundation

enum MarianLibraryData {

    // MARK: - The Marian Year

    /// The feasts of Our Lady on the universal 1962 calendar, in the
    /// order of the year, and the one kept in the Americas.
    static let feasts: [KeptFeast] = [
        KeptFeast(month: 2, day: 2, name: "The Purification"),
        KeptFeast(month: 2, day: 11, name: "Our Lady of Lourdes"),
        KeptFeast(month: 3, day: 25, name: "The Annunciation"),
        KeptFeast(month: 5, day: 31, name: "The Queenship of Mary"),
        KeptFeast(month: 7, day: 2, name: "The Visitation"),
        KeptFeast(month: 7, day: 16, name: "Our Lady of Mount Carmel"),
        KeptFeast(month: 8, day: 5, name: "Our Lady of the Snows"),
        KeptFeast(month: 8, day: 15, name: "The Assumption"),
        KeptFeast(month: 8, day: 22, name: "The Immaculate Heart of Mary"),
        KeptFeast(month: 9, day: 8, name: "The Nativity of Our Lady"),
        KeptFeast(month: 9, day: 12, name: "The Holy Name of Mary"),
        KeptFeast(month: 9, day: 15, name: "The Seven Sorrows"),
        KeptFeast(month: 10, day: 7, name: "The Most Holy Rosary"),
        KeptFeast(month: 10, day: 11, name: "The Maternity of Our Lady"),
        KeptFeast(month: 11, day: 21, name: "The Presentation of Our Lady"),
        KeptFeast(month: 12, day: 8, name: "The Immaculate Conception"),
        KeptFeast(month: 12, day: 12, name: "Our Lady of Guadalupe", inMissal: false, keptBy: "the Americas")
    ]

    /// The painting a feast is shown in, where the app holds one that
    /// is its own scene; the Coronation stands in for the rest
    static func painting(for feast: KeptFeast) -> String {
        [
            "The Purification": "joyful_presentation",
            "The Annunciation": "joyful_annunciation",
            "The Queenship of Mary": "glorious_coronation",
            "The Visitation": "joyful_visitation",
            "The Assumption": "glorious_assumption",
            "The Seven Sorrows": "seven_sorrows_pieta",
            "The Maternity of Our Lady": "joyful_nativity"
        ][feast.name] ?? "glorious_coronation"
    }

    /// The library's reading about a feast, where it has one, and the
    /// short name its act goes by. Most readings stand under another name
    /// than the feast's — the Rosary's is Lepanto — so the act says where
    /// it leads ("READ · LEPANTO"); `nil` where the reading is the feast's
    /// own name, and a bare READ is true.
    static func reading(for feast: KeptFeast) -> (id: String, name: String?)? {
        [
            "Our Lady of Lourdes": ("lourdes", nil),
            "The Annunciation": ("new_eve", "The New Eve"),
            "The Queenship of Mary": ("queen_mother", "The Queen Mother"),
            "The Visitation": ("ark", "The Ark"),
            "The Assumption": ("assumption", nil),
            "The Immaculate Heart of Mary": ("fatima", "Fatima"),
            "The Nativity of Our Lady": ("morning_star", "Morning Star"),
            "The Seven Sorrows": ("behold_thy_mother", "Behold Thy Mother"),
            "The Most Holy Rosary": ("lepanto", "Lepanto"),
            "The Maternity of Our Lady": ("theotokos", "Mother of God"),
            "The Immaculate Conception": ("immaculate_conception", nil),
            "Our Lady of Guadalupe": ("guadalupe", nil)
        ][feast.name]
    }

    /// The feast kept today, or else the next one to come
    static func nextFeast(from now: Date = .now) -> KeptFeast? {
        feasts.min { a, b in
            (a.nextDate(from: now) ?? .distantFuture) < (b.nextDate(from: now) ?? .distantFuture)
        }
    }

    // MARK: - Shelves

    static let sections: [ReadingShelf] = [dogmas, scripture, apparitions, saints, rosary, titles]

    // MARK: The Four Marian Dogmas

    static let dogmas = ReadingShelf(
        id: "dogmas",
        icon: "ph-star-fill",
        title: "The Four Marian Dogmas",
        marginLabel: "The\ndogmas",
        subtitle: "What the Church solemnly teaches",
        entries: [
            LibraryReading(
                id: "theotokos",
                title: "Mother of God",
                detail: "Theotokos · Council of Ephesus, A.D. 431",
                paragraphs: [
                    "Mary is truly the Mother of God, because the Son she conceived and bore is truly God. She did not give birth to a divine nature, which has no beginning; she gave birth to a Person, and the Person born of her is the eternal Word. A mother is the mother of her son, not of a part of him — and her Son is God.",
                    "In the fifth century Nestorius, archbishop of Constantinople, preached that Mary should be called only Christotokos, the mother of Christ, as though the man born of her were one person and the Word of God another dwelling in him. St. Cyril of Alexandria answered him, and in 431 the Council of Ephesus confirmed the ancient title. The people of Ephesus waited outside the church through the day of the session, and when the bishops came out that evening they were led to their lodgings by torchlight.",
                    "Every other Marian truth flows from this one. She was preserved from sin because she was to be His Mother; she remained a virgin because her motherhood was wholly His; she was taken up body and soul because the flesh that gave Him flesh would not see corruption. The oldest known prayer to Our Lady, the Sub tuum praesidium, already calls her Theotokos: \u{201C}We fly to thy patronage, O holy Mother of God.\u{201D}"
                ],
                quote: ReadingQuote(
                    text: "If anyone does not confess that Emmanuel is truly God, and that the holy Virgin is therefore the Mother of God, for she bore according to the flesh the Word of God made flesh, let him be anathema.",
                    citation: "St. Cyril of Alexandria, the first of the Twelve Anathemas, received at Ephesus"
                ),
                painting: "joyful_nativity",
                feast: KeptFeast(month: 10, day: 11, name: "The Maternity of Our Lady"),
                doors: [.mysteries(.joyful, note: "The Nativity, the third Joyful Mystery")]
            ),
            LibraryReading(
                id: "virginity",
                title: "Perpetual Virginity",
                detail: "Ever-Virgin · Lateran Council, A.D. 649",
                paragraphs: [
                    "Mary was a virgin before, during, and after the birth of Christ — Semper Virgo, ever-virgin. The Creed confesses that the Son was \u{201C}born of the Virgin Mary\u{201D}; the Second Council of Constantinople in 553 called her \u{201C}ever-virgin\u{201D}; and the Lateran Council of 649, under Pope St. Martin I, taught that she conceived without seed by the Holy Ghost, gave birth without corruption, and remained a virgin after the birth.",
                    "Her virginity is not a mere absence. It is the sign that her Son has no father but God, and it is the form her total gift took: body and soul, she belonged to Him alone. When the angel came she asked, \u{201C}How shall this be done, because I know not man?\u{201D} — a question St. Augustine and many after him read as the word of one already resolved to remain a virgin.",
                    "The \u{201C}brethren of the Lord\u{201D} in the Gospels are His kinsmen: the Hebrew and Aramaic of the time had no separate word for cousin, and St. Jerome showed that James and Joseph, named among them, were sons of another Mary. From the Cross Jesus gave His mother into the keeping of St. John — which He would not have needed to do had she other sons to take her in."
                ],
                quote: ReadingQuote(
                    text: "This gate shall be shut, it shall not be opened, and no man shall pass through it: because the Lord the God of Israel hath entered in by it.",
                    citation: "Ezechiel 44:2, read by the Fathers of Our Lady"
                ),
                painting: "joyful_annunciation",
                feast: KeptFeast(month: 3, day: 25, name: "The Annunciation"),
                doors: [.mysteries(.joyful, note: "The Annunciation, the first Joyful Mystery")]
            ),
            LibraryReading(
                id: "immaculate_conception",
                title: "The Immaculate Conception",
                detail: "Bl. Pius IX · Ineffabilis Deus, 1854",
                paragraphs: [
                    "From the first instant of her conception, Mary was preserved free from every stain of original sin. This is not to say she did not need a Saviour. She was redeemed more wonderfully than we are: we are lifted out of the pit, and she was kept from falling into it, by the merits of the same Christ, applied in advance.",
                    "The Church had long kept a feast of her conception, and the question of how it could be holy was argued for centuries. Bl. John Duns Scotus opened the way in the thirteenth century, reasoning that the most perfect Redeemer would redeem one person in the most perfect way, by preserving her. On 8 December 1854 Bl. Pius IX, having consulted the bishops of the world, defined it as revealed by God.",
                    "Four years later, on the feast of the Annunciation, a poor girl in the Pyrenees asked the Lady in the grotto her name. The Lady raised her eyes to heaven, joined her hands, and answered in the local dialect: \u{201C}I am the Immaculate Conception.\u{201D} St. Bernadette did not know what the words meant, and repeated them all the way to the parish priest so as not to forget them."
                ],
                quote: ReadingQuote(
                    text: "The most Blessed Virgin Mary, in the first instant of her conception, by a singular grace and privilege granted by Almighty God, in view of the merits of Jesus Christ, the Saviour of the human race, was preserved free from all stain of original sin.",
                    citation: "Bl. Pius IX, Ineffabilis Deus"
                ),
                painting: "joyful_annunciation",
                feast: KeptFeast(month: 12, day: 8, name: "The Immaculate Conception"),
                doors: [
                    .page(.libraryReading(id: "lourdes"), icon: "ph-sun", title: "Our Lady of Lourdes", note: "Where she gave the dogma its name")
                ]
            ),
            LibraryReading(
                id: "assumption",
                title: "The Assumption",
                detail: "Ven. Pius XII · Munificentissimus Deus, 1950",
                paragraphs: [
                    "When the course of her earthly life was finished, Mary was taken up body and soul into the glory of heaven. She already shares fully in her Son's Resurrection, and she is what the whole Church will be when He comes again: the first of the redeemed to stand before God in the flesh.",
                    "No city ever claimed her relics, though the tombs of the Apostles were kept and venerated from the first. The East has kept the feast of her Dormition — her falling asleep — since at least the sixth century, and the West took it up as the Assumption. The definition does not settle whether she died first; it says only that she was taken up \u{201C}having completed the course of her earthly life\u{201D}, and most of the tradition holds that she died as her Son did, and was raised.",
                    "Ven. Pius XII defined the dogma on 1 November 1950, the feast of All Saints, before a crowd in St. Peter's Square, after asking the bishops of the world whether it should be defined and receiving an all but unanimous yes. It is the mystery contemplated in the fourth Glorious Mystery, and her crowning follows in the fifth."
                ],
                quote: ReadingQuote(
                    text: "The Immaculate Mother of God, the ever-Virgin Mary, having completed the course of her earthly life, was assumed body and soul into heavenly glory.",
                    citation: "Ven. Pius XII, Munificentissimus Deus"
                ),
                painting: "glorious_assumption",
                feast: KeptFeast(month: 8, day: 15, name: "The Assumption"),
                doors: [.mysteries(.glorious, note: "The Assumption, the fourth Glorious Mystery")]
            )
        ]
    )

    // MARK: Mary in Scripture

    static let scripture = ReadingShelf(
        id: "scripture",
        icon: "ch-bible",
        title: "Mary in Scripture",
        marginLabel: "In\nScripture",
        subtitle: "From Genesis to the Apocalypse",
        entries: [
            LibraryReading(
                id: "new_eve",
                title: "The New Eve",
                detail: "Genesis 3:15",
                paragraphs: [
                    "In the garden, before the curse is spoken, God promises a victory: there will be enmity between the serpent and the woman, between his seed and hers, and she — the woman's seed — will crush his head. The Fathers called this verse the Protoevangelium, the first gospel, because it is the first word of the Redeemer, and it comes with a woman at His side.",
                    "St. Justin Martyr, writing around the year 155, and St. Irenaeus a generation later, set Eve and Mary side by side. A virgin listened to a fallen angel and believed him, and death came into the world; a virgin listened to a holy angel and believed him, and Life came into the world. Where Eve said no to God, Mary said, \u{201C}Be it done to me according to thy word.\u{201D}",
                    "That is why Jesus calls His mother \u{201C}Woman\u{201D} at Cana and again from the Cross: not coldly, but by the name of the first promise. The new Adam has His new Eve beside Him, and she becomes, as the first Eve was named, the mother of all the living."
                ],
                quote: ReadingQuote(
                    text: "The knot of Eve's disobedience was loosed by the obedience of Mary. For what the virgin Eve had bound fast through unbelief, this did the virgin Mary set free through faith.",
                    citation: "St. Irenaeus, Against Heresies III.22"
                ),
                painting: "joyful_annunciation",
                feast: KeptFeast(month: 3, day: 25, name: "The Annunciation"),
                doors: [.mysteries(.joyful, note: "The Annunciation, the first Joyful Mystery")]
            ),
            LibraryReading(
                id: "ark",
                title: "The Ark of the Covenant",
                detail: "2 Kings 6 & Luke 1:39\u{2013}56",
                paragraphs: [
                    "St. Luke tells the Visitation in the words of the Old Testament's story of the Ark. David rose and went to bring the Ark up from the hill country of Judah; Mary rose and went into the hill country of Juda. David asked, \u{201C}How shall the ark of the Lord come to me?\u{201D}; Elizabeth asks, \u{201C}Whence is this to me, that the mother of my Lord should come to me?\u{201D} David danced before the Ark; John leaps in his mother's womb. The Ark stayed three months in the house of Obededom; Mary stays about three months with Elizabeth.",
                    "The old Ark held the tablets of the Law, a golden urn of manna, and the rod of Aaron that had blossomed. Mary carried the Word who gave the Law, the living Bread come down from heaven, and the eternal High Priest. The glory of God overshadowed the tabernacle; the power of the Most High overshadowed her.",
                    "St. John makes the same connection at the end of the Bible. \u{201C}The temple of God was opened in heaven: and the ark of his testament was seen in his temple\u{201D} — and the very next thing he sees is the woman clothed with the sun. In the house of Elizabeth, Mary answered the greeting with the Magnificat, which the Church has sung at Vespers every evening since."
                ],
                quote: ReadingQuote(
                    text: "And whence is this to me, that the mother of my Lord should come to me?",
                    citation: "Luke 1:43"
                ),
                painting: "joyful_visitation",
                feast: KeptFeast(month: 7, day: 2, name: "The Visitation"),
                doors: [
                    .prayer(id: "magnificat", note: "Her own words in the house of Elizabeth"),
                    .mysteries(.joyful, note: "The Visitation, the second Joyful Mystery")
                ]
            ),
            LibraryReading(
                id: "queen_mother",
                title: "The Queen Mother",
                detail: "3 Kings 2:19\u{2013}20 & Apocalypse 12:1",
                paragraphs: [
                    "In the kingdom of David the queen was not the king's wife — Solomon had hundreds — but his mother, the Gebirah, the Great Lady. When Bethsabee came to Solomon to ask a favour, the king rose to meet her, bowed to her, and had a throne set for her at his right hand. She was the one person in the kingdom who could bring the people's petitions to the king and be sure of a hearing.",
                    "Christ is the Son of David, and the Gospel of St. Luke opens by saying so: \u{201C}the Lord God shall give unto him the throne of David his father.\u{201D} The mother of the Son of David is therefore the Queen Mother of His kingdom. She does not rule beside Him as an equal; she intercedes, as Bethsabee did, and her Son does not turn away her face.",
                    "St. John sees her crowned: a woman clothed with the sun, the moon under her feet, and on her head a crown of twelve stars. Ven. Pius XII taught the doctrine in Ad Caeli Reginam in 1954, and the Church keeps the Queenship of Mary on 31 May, the last day of her month."
                ],
                quote: ReadingQuote(
                    text: "And a great sign appeared in heaven: A woman clothed with the sun, and the moon under her feet, and on her head a crown of twelve stars.",
                    citation: "Apocalypse 12:1"
                ),
                painting: "glorious_coronation",
                feast: KeptFeast(month: 5, day: 31, name: "The Queenship of Mary"),
                doors: [.mysteries(.glorious, note: "The Coronation, the fifth Glorious Mystery")]
            ),
            LibraryReading(
                id: "cana",
                title: "The Wedding at Cana",
                detail: "John 2:1\u{2013}11",
                paragraphs: [
                    "At a wedding in Galilee the wine gives out, and Mary is the first to notice. She does not tell her Son what to do; she tells Him what is wanting — \u{201C}They have no wine\u{201D} — and leaves it with Him. His answer sounds like a refusal: \u{201C}Woman, what is that to me and to thee? my hour is not yet come.\u{201D} She answers it by turning to the servants.",
                    "Her last recorded words in the Gospels are those she said to them: \u{201C}Whatsoever he shall say to you, do ye.\u{201D} Six jars of water become the best wine of the feast, and St. John says that this was the beginning of His miracles, and His disciples believed in Him. The first sign of His glory was worked at His mother's asking.",
                    "Here in small is the whole of her place in the Church: she sees what we lack before we do, she brings it to her Son, and she sends us back to Him to do what He says. The Church reads this Gospel on the second Sunday after the Epiphany, and St. John Paul II made it the second of the Luminous Mysteries."
                ],
                quote: ReadingQuote(
                    text: "His mother saith to the waiters: Whatsoever he shall say to you, do ye.",
                    citation: "John 2:5"
                ),
                painting: "luminous_cana",
                doors: [.mysteries(.luminous, note: "The Wedding at Cana, the second Luminous Mystery")]
            ),
            LibraryReading(
                id: "behold_thy_mother",
                title: "Behold Thy Mother",
                detail: "John 19:25\u{2013}27",
                paragraphs: [
                    "There stood by the Cross of Jesus His mother. She did not faint or flee; she stood, as the Stabat Mater sings, and offered with Him what He was offering. Simeon had told her in the Temple that a sword would pierce her own soul, and on Calvary it did.",
                    "From the Cross Jesus saw her and the disciple He loved, and gave them to each other: \u{201C}Woman, behold thy son,\u{201D} and to the disciple, \u{201C}Behold thy mother.\u{201D} These are among His last words, spoken when every breath cost Him. St. John does not name himself; he is simply the disciple, and the Church has always read the gift as made to every disciple after him.",
                    "\u{201C}And from that hour, the disciple took her to his own.\u{201D} St. Louis de Montfort's whole devotion is this verse lived: to take Mary into one's own home as St. John did, and to give her everything, so as to belong entirely to her Son."
                ],
                quote: ReadingQuote(
                    text: "After that, he saith to the disciple: Behold thy mother. And from that hour, the disciple took her to his own.",
                    citation: "John 19:27"
                ),
                painting: "seven_sorrows_pieta",
                feast: KeptFeast(month: 9, day: 15, name: "The Seven Sorrows"),
                doors: [.mysteries(.sevenSorrows, note: "Seven Sorrows of Mary, the chaplet")]
            )
        ]
    )

    // MARK: Approved Apparitions

    static let apparitions = ReadingShelf(
        id: "apparitions",
        icon: "ph-sun",
        title: "Approved Apparitions",
        marginLabel: "Apparitions",
        subtitle: "When Heaven visited earth",
        entries: [
            LibraryReading(
                id: "guadalupe",
                title: "Our Lady of Guadalupe",
                detail: "Mexico, 1531 · St. Juan Diego",
                paragraphs: [
                    "Ten years after the fall of the Aztec capital, a baptised Indian named Juan Diego Cuauhtlatoatzin was crossing the hill of Tepeyac on his way to Mass when he heard singing, and saw a Lady dressed like a princess of his own people. She asked him to go to the bishop, Fray Juan de Zumárraga, and ask that a church be built on that spot.",
                    "The bishop asked for a sign. On 12 December the Lady sent Juan Diego to the top of the barren hill, where he found Castilian roses blooming out of season; she arranged them in his tilma, his cactus-fibre cloak, and told him to open it before no one but the bishop. When he let the roses fall, her image was on the cloth — the same image that hangs today in the basilica at the foot of Tepeyac, on a coarse cloth of agave fibre that has outlasted five centuries.",
                    "In the decade that followed, millions of the native peoples of Mexico were baptised. She is Patroness of the Americas and of the unborn — the image shows her with child — and St. John Paul II canonised Juan Diego in 2002."
                ],
                quote: ReadingQuote(
                    text: "Am I not here, I who am your Mother? Are you not under my shadow and protection? Is there anything else that you need?",
                    citation: "Our Lady to St. Juan Diego, from the Nican Mopohua"
                ),
                feast: KeptFeast(month: 12, day: 12, name: "Our Lady of Guadalupe", inMissal: false, keptBy: "the Americas")
            ),
            LibraryReading(
                id: "miraculous_medal",
                title: "The Miraculous Medal",
                detail: "Paris, 1830 · St. Catherine Labouré",
                paragraphs: [
                    "Catherine Labouré was a novice of the Daughters of Charity in the Rue du Bac in Paris. On the night of 18 July 1830 a child woke her and led her to the chapel, where Our Lady came and sat in the director's chair, and Catherine knelt with her hands in Our Lady's lap and spoke with her for two hours.",
                    "On 27 November Our Lady appeared again, standing on a globe, rays of light streaming from rings on her fingers — the graces, she said, that she gives to those who ask for them; the rings that gave no light were graces no one asked for. An oval formed around her with the words \u{201C}O Mary, conceived without sin, pray for us who have recourse to thee,\u{201D} and the vision turned to show the reverse: an M surmounted by a cross, and the Hearts of Jesus and Mary. \u{201C}Have a medal struck after this model.\u{201D}",
                    "The medal was struck in 1832, and the graces that followed were so many that the people named it miraculous before the Church did. It spread the prayer to the Immaculate Conception across the world twenty-four years before the dogma was defined. Catherine told no one but her confessor that she was the sister who had seen it, and lived forty-six years more caring for old men in a hospice at Enghien. Her body lies incorrupt in the chapel of the Rue du Bac."
                ],
                quote: ReadingQuote(
                    text: "O Mary, conceived without sin, pray for us who have recourse to thee.",
                    citation: "The prayer of the Miraculous Medal"
                ),
                feast: KeptFeast(month: 11, day: 27, name: "Our Lady of the Miraculous Medal", inMissal: false, keptBy: "the Vincentian family"),
                doors: [
                    .page(.libraryReading(id: "immaculate_conception"), icon: "ph-star-fill", title: "The Immaculate Conception", note: "The dogma the medal prepared")
                ]
            ),
            LibraryReading(
                id: "la_salette",
                title: "Our Lady of La Salette",
                detail: "France, 1846 · Mélanie Calvat & Maximin Giraud",
                paragraphs: [
                    "On 19 September 1846, high in the French Alps above the village of La Salette, two young cowherds — Mélanie, fourteen, and Maximin, eleven — saw a globe of light open, and inside it a Lady seated on a stone with her face in her hands, weeping. She stood, and spoke to them first in French and then, when they did not follow, in their own dialect.",
                    "She grieved over two things above all: that the name of her Son was taken in vain, and that Sunday was not kept holy. She warned of a failing harvest and of famine, and asked for prayer, morning and evening. On her breast hung a crucifix with a hammer and pincers at either side, and the light that surrounded her came from it.",
                    "After five years of inquiry the Bishop of Grenoble approved the apparition in 1851, on its anniversary. A spring that had been dry began to flow on the spot where she sat, and it has not stopped."
                ],
                quote: ReadingQuote(
                    text: "Come near, my children, do not be afraid. I am here to tell you great news.",
                    citation: "Our Lady to Mélanie and Maximin"
                ),
                feast: KeptFeast(month: 9, day: 19, name: "Our Lady of La Salette", inMissal: false, keptBy: "the diocese of Grenoble and the La Salette Missionaries")
            ),
            LibraryReading(
                id: "lourdes",
                title: "Our Lady of Lourdes",
                detail: "France, 1858 · St. Bernadette Soubirous",
                paragraphs: [
                    "On 11 February 1858, Bernadette Soubirous, a fourteen-year-old girl so poor her family lived in a disused jail, went to gather firewood by the grotto of Massabielle outside Lourdes. In a niche in the rock she saw a young Lady in white, a blue sash at her waist and a yellow rose on each foot, a rosary on her arm. Bernadette took out her own beads and prayed, and the Lady passed her beads through her fingers with her, joining in at each Glory Be.",
                    "There were eighteen apparitions between February and July. The Lady asked for penance and prayer for sinners, and for a chapel to be built and processions to come. On 25 February she told Bernadette to drink from a spring; there was only mud, and Bernadette dug in it before the jeering crowd, and by the next day a spring was running that now gives thousands of litres a day. On 25 March the Lady gave her name: \u{201C}I am the Immaculate Conception.\u{201D}",
                    "The bishop approved the apparitions in 1862. The Church's medical bureau has examined the healings at Lourdes ever since, and some seventy have been declared miraculous. Bernadette became a Sister of Charity at Nevers, kept out of sight, and died there at thirty-five after long illness, as the Lady had foretold she would find no happiness in this world. Her body lies incorrupt in the convent chapel."
                ],
                quote: ReadingQuote(
                    text: "I do not promise to make you happy in this world, but in the other.",
                    citation: "Our Lady to St. Bernadette, 18 February 1858"
                ),
                feast: KeptFeast(month: 2, day: 11, name: "Our Lady of Lourdes"),
                doors: [
                    .page(.libraryReading(id: "immaculate_conception"), icon: "ph-star-fill", title: "The Immaculate Conception", note: "The name she gave herself")
                ]
            ),
            LibraryReading(
                id: "pontmain",
                title: "Our Lady of Pontmain",
                detail: "France, 1871",
                paragraphs: [
                    "In January 1871 France was losing the Franco-Prussian War. Paris was under siege, the Prussian army was at the gates of Laval, and thirty-eight young men of the little village of Pontmain were at the front. On the evening of 17 January, twelve-year-old Eugène Barbedette stepped out of his father's barn and saw a Lady in the sky above the house opposite, in a blue gown scattered with gold stars, smiling at him.",
                    "His brother saw her too, and then two little girls from the convent school; the adults saw nothing. The parish priest came, and the village knelt in the snow and prayed the Rosary, the Magnificat, and the litany, and as they prayed a banner unrolled beneath her feet and letters appeared on it one by one: \u{201C}But pray, my children. God will hear you in a little while. My Son allows Himself to be moved.\u{201D}",
                    "The apparition lasted three hours. That night the Prussian advance on Laval halted without an order anyone could explain, and eleven days later the armistice was signed. All thirty-eight of Pontmain's soldiers came home. The bishop approved the apparition a year later as Our Lady of Hope."
                ],
                quote: ReadingQuote(
                    text: "But pray, my children. God will hear you in a little while. My Son allows Himself to be moved.",
                    citation: "The words written beneath Our Lady at Pontmain"
                ),
                feast: KeptFeast(month: 1, day: 17, name: "Our Lady of Hope of Pontmain", inMissal: false, keptBy: "the diocese of Laval")
            ),
            LibraryReading(
                id: "knock",
                title: "Our Lady of Knock",
                detail: "Ireland, 1879",
                paragraphs: [
                    "On the wet evening of 21 August 1879, in the village of Knock in County Mayo, a group of villagers saw a light at the south gable of the parish church, and in it Our Lady, crowned, her hands raised in prayer and her eyes lifted to heaven. At her right stood St. Joseph, his head bowed toward her; at her left St. John the Evangelist, vested as a bishop, holding a book.",
                    "Beside them stood an altar, and on the altar a lamb, before a cross, with angels hovering around it. The witnesses — the youngest six, the oldest seventy-five — stood in the rain for two hours praying the Rosary, and the ground beneath the apparition stayed dry.",
                    "Nothing was said. It is the silent apparition, and what it shows is the Mass: the Lamb upon the altar, and Our Lady and the saints standing in adoration beside Him. Ireland was only a generation past the Famine. St. John Paul II came to Knock as a pilgrim for the shrine's centenary in 1979."
                ],
                quote: ReadingQuote(
                    text: "Behold the Lamb of God, behold him who taketh away the sin of the world.",
                    citation: "John 1:29, the scene the witnesses of Knock were shown"
                ),
                feast: KeptFeast(month: 8, day: 17, name: "Our Lady of Knock", inMissal: false, keptBy: "Ireland")
            ),
            LibraryReading(
                id: "fatima",
                title: "Our Lady of Fatima",
                detail: "Portugal, 1917 · Sts. Francisco & Jacinta, Ven. Lúcia",
                paragraphs: [
                    "On 13 May 1917, while Europe was at war, three shepherd children — Lúcia dos Santos, ten, and her cousins Francisco and Jacinta Marto, eight and seven — were grazing sheep at the Cova da Iria when a Lady \u{201C}brighter than the sun\u{201D} appeared over a small holm-oak. She asked them to come back on the thirteenth of each month for six months, and to pray the Rosary every day for peace in the world. An angel had prepared them the year before, teaching them to pray and to make sacrifices for sinners.",
                    "In July she showed them hell, and asked for devotion to her Immaculate Heart, for the consecration of Russia to it, and for the Communion of reparation on the first Saturdays. She promised a miracle so that all would believe, and on 13 October some seventy thousand people, believers and scoffers together, standing in rain-soaked fields, watched the sun tremble, spin, and plunge toward the earth, and found their clothes dry afterward.",
                    "Francisco and Jacinta died in the influenza epidemic within three years, as she had told them they would, and were canonised in 2017 — the youngest saints who were not martyrs. Lúcia became a Carmelite and lived until 2005. Ven. Pius XII consecrated the world to the Immaculate Heart in 1942 and extended its feast to the whole Church, kept on 22 August."
                ],
                quote: ReadingQuote(
                    text: "In the end, my Immaculate Heart will triumph.",
                    citation: "Our Lady to the children of Fatima, 13 July 1917"
                ),
                feast: KeptFeast(month: 8, day: 22, name: "The Immaculate Heart of Mary"),
                doors: [
                    .page(.howToPray, icon: "ch-rosary", title: "How to Pray the Rosary", note: "Every day, as she asked")
                ]
            ),
            LibraryReading(
                id: "beauraing_banneux",
                title: "Beauraing & Banneux",
                detail: "Belgium, 1932\u{2013}1933",
                paragraphs: [
                    "On the evening of 29 November 1932, in the town of Beauraing, four children walking to fetch a friend from the convent school saw a Lady in white walking in the air above the railway viaduct. Over the next five weeks five children — the Voisin and Degeimbre brothers and sisters, aged nine to fifteen — saw her thirty-three times in the convent garden, under a hawthorn tree. At the last she opened her arms and showed them a heart of gold.",
                    "\u{201C}Do you love my Son? Do you love me?\u{201D} she asked one of the children. \u{201C}Then sacrifice yourself for me.\u{201D} She asked for a chapel, for pilgrims, and above all for prayer: \u{201C}Pray, pray very much.\u{201D}",
                    "Twelve days after the last apparition at Beauraing, on 15 January 1933, Our Lady appeared to Mariette Beco, eleven, in the garden of her family's poor cottage at Banneux, near Liège. She led the girl to a spring at the roadside and told her to dip her hands in it: \u{201C}This spring is reserved for me — for all nations, to relieve the sick.\u{201D} Asked who she was, she said: \u{201C}I am the Virgin of the Poor.\u{201D} Both apparitions were approved in 1949."
                ],
                quote: ReadingQuote(
                    text: "I am the Virgin of the Poor.",
                    citation: "Our Lady to Mariette Beco at Banneux"
                )
            )
        ],
        footnote: "Each has been judged worthy of belief by the bishop of its place. The faithful are free to believe them; the Church never binds anyone to a private revelation."
    )

    // MARK: The Marian Saints

    static let saints = ReadingShelf(
        id: "saints",
        icon: "ph-user",
        title: "The Marian Saints",
        marginLabel: "The\nsaints",
        subtitle: "In their own words",
        entries: [
            LibraryReading(
                id: "bernard",
                title: "St. Bernard of Clairvaux",
                detail: "1090\u{2013}1153 · Doctor of the Church",
                paragraphs: [
                    "St. Bernard entered the struggling abbey of Cîteaux with thirty companions he had talked into coming with him, and two years later was sent to found Clairvaux. He preached a crusade, counselled popes and kings, and healed a schism, and the Church calls him the Mellifluous Doctor — the doctor sweet as honey — for the way he wrote of Christ and of His mother.",
                    "His four homilies on the words \u{201C}The angel Gabriel was sent\u{201D} are among the most loved pages ever written on Our Lady. In one he stands with all creation at the Annunciation waiting for her answer: \u{201C}Answer, O Virgin, answer quickly.\u{201D} In another he tells the Christian tossed on the sea of this world to look to the star — Maria, the star of the sea — and call on her.",
                    "In a sermon for the Nativity of Our Lady he called her the aqueduct: the grace of God flows down to us from its source through her. St. Louis de Montfort would build on that image five centuries later. The Church keeps his feast on 20 August."
                ],
                quote: ReadingQuote(
                    text: "In dangers, in doubts, in difficulties, think of Mary, call upon Mary. If you follow her, you cannot go astray; if you pray to her, you cannot despair; if you think of her, you cannot err. If she holds you, you cannot fall; if she protects you, you need not fear; if she guides you, you will never tire.",
                    citation: "St. Bernard, Second Homily in Praise of the Virgin Mother"
                ),
                feast: KeptFeast(month: 8, day: 20, name: "St. Bernard"),
                doors: [.prayer(id: "ave_maris_stella", note: "Hail, star of the sea")]
            ),
            LibraryReading(
                id: "dominic",
                title: "St. Dominic",
                detail: "1170\u{2013}1221 · Founder of the Order of Preachers",
                paragraphs: [
                    "St. Dominic de Guzmán was a Castilian canon who, travelling through the south of France, found whole regions lost to the Albigensians, who taught that the flesh was evil and the material world the work of an evil god. He saw that the Church's legates, arriving in state, could not answer men who lived in poverty, and he went on foot, begging, to preach.",
                    "Tradition, handed down through the Dominican Bl. Alan de la Roche in the fifteenth century, holds that Our Lady gave St. Dominic the Rosary as the weapon for that fight, around 1214: a psalter of Hail Marys joined to the preaching of the mysteries of her Son's life, which by teaching the Incarnation answered the heresy at its root. Where preaching alone had failed, the Rosary converted.",
                    "Historians still argue how much of the Rosary's shape was Dominic's own. What is certain is that his Order made it theirs, preached it across the world, and has kept it ever since, and that Leo XIII and many popes before him honoured Dominic as its father. His feast is 4 August."
                ],
                quote: ReadingQuote(
                    text: "Arm yourself with prayer rather than a sword; wear humility rather than fine clothes.",
                    citation: "Attributed to St. Dominic"
                ),
                feast: KeptFeast(month: 8, day: 4, name: "St. Dominic"),
                doors: [
                    .page(.libraryReading(id: "dominic_confraternity"), icon: "ch-rosary", title: "St. Dominic and the Confraternity", note: "The Rosary Through History")
                ]
            ),
            LibraryReading(
                id: "montfort",
                title: "St. Louis de Montfort",
                detail: "1673\u{2013}1716 · Apostle of Total Consecration",
                paragraphs: [
                    "St. Louis-Marie Grignion was born at Montfort in Brittany and took the name of the town where he was baptised. He was a priest who could not stay put: he walked the roads of western France preaching missions to the poor, rebuilding ruined chapels, and carving great calvaries with the villagers, and he was driven out of diocese after diocese for his zeal. He died at forty-three, worn out.",
                    "Around 1712 he wrote a treatise on true devotion to the Blessed Virgin, and prophesied that it would be hidden \u{201C}in the darkness and silence of a chest.\u{201D} It was: the manuscript was found in 1842, in a chest of old books at his community's house in Saint-Laurent-sur-Sèvre. It teaches the total consecration of oneself to Jesus through Mary — body and soul, goods and merits — so that she may form us in Christ as she formed Him.",
                    "The book shaped a pope: St. John Paul II took his motto, Totus Tuus, from Montfort's formula of consecration. Ven. Pius XII canonised him in 1947. The thirty-three day preparation in this app is his, and his book is on the shelf in full."
                ],
                quote: ReadingQuote(
                    text: "The more one is consecrated to Mary, the more one is consecrated to Jesus Christ.",
                    citation: "St. Louis de Montfort, True Devotion to Mary, n. 120"
                ),
                feast: KeptFeast(month: 4, day: 28, name: "St. Louis de Montfort", inMissal: false, keptBy: "the Montfortian family"),
                doors: [
                    .page(.trueDevotionBook, icon: "ph-crown", title: "True Devotion to Mary", note: "The book, in the Faber translation"),
                    .page(.trueDevotion, icon: "ph-scroll", title: "The Devotion in Summary", note: "What the consecration is"),
                    .act(.consecration, note: "His thirty-three days of preparation, kept here")
                ]
            ),
            LibraryReading(
                id: "alphonsus",
                title: "St. Alphonsus Liguori",
                detail: "1696\u{2013}1787 · Doctor of the Church",
                paragraphs: [
                    "St. Alphonsus was a Neapolitan lawyer who had never lost a case until he lost one through an oversight, and left the courts for the priesthood. He founded the Redemptorists to preach to the abandoned poor of the countryside, became a bishop against his will, and wrote moral theology so balanced that the Church made him the patron of confessors.",
                    "In 1750 he published The Glories of Mary, a commentary on the Salve Regina — the Hail, Holy Queen — phrase by phrase, gathered from the Fathers and the saints and full of stories of her mercy. It has been reprinted more than eight hundred times, and it is still one of the most widely read books ever written about Our Lady.",
                    "He also wrote the Stations of the Cross most parishes still pray, and hymns sung in Italy to this day, among them the Christmas carol \u{201C}Tu scendi dalle stelle\u{201D}. He lived to ninety, and was canonised in 1839. His feast is 2 August."
                ],
                quote: ReadingQuote(
                    text: "Mary being in heaven nearer to God and more united to Him, knows our miseries better, compassionates them more, and can more efficaciously help us.",
                    citation: "St. Alphonsus Liguori, The Glories of Mary"
                ),
                feast: KeptFeast(month: 8, day: 2, name: "St. Alphonsus Liguori")
            ),
            LibraryReading(
                id: "kolbe",
                title: "St. Maximilian Kolbe",
                detail: "1894\u{2013}1941 · Martyr of Auschwitz",
                paragraphs: [
                    "As a boy in Poland, Raymond Kolbe asked Our Lady what would become of him. She came to him holding two crowns, one white for purity and one red for martyrdom, and asked which he would choose. He said he would take both.",
                    "He became a Franciscan, and in 1917, in Rome, founded the Militia Immaculatae, the Knights of the Immaculata, to win souls to Christ through her. Back in Poland he built Niepokalanów, the City of the Immaculata, a friary of some seven hundred friars running printing presses and a radio station, and he founded another in Nagasaki.",
                    "Arrested by the Gestapo in 1941, he was sent to Auschwitz. When a prisoner escaped, ten men were chosen to die of starvation in reprisal, and one of them cried out for his wife and children. Father Kolbe stepped forward and asked to take his place. He led the condemned men in prayer and hymns in the bunker for two weeks, and was killed by injection on 14 August, the eve of the Assumption. St. John Paul II canonised him in 1982, with the man he saved in the crowd."
                ],
                quote: ReadingQuote(
                    text: "Never be afraid of loving the Blessed Virgin too much. You can never love her more than Jesus did.",
                    citation: "Attributed to St. Maximilian Kolbe"
                ),
                feast: KeptFeast(month: 8, day: 14, name: "St. Maximilian Kolbe", inMissal: false)
            ),
            LibraryReading(
                id: "john_paul",
                title: "St. John Paul II",
                detail: "1920\u{2013}2005 · Totus Tuus",
                paragraphs: [
                    "Karol Wojtyła lost his mother when he was eight, and later said that it was then that he began to look to Our Lady as his mother. As a young man in occupied Kraków, working in a quarry and studying for the priesthood in secret, he read St. Louis de Montfort, and he took his episcopal motto from Montfort's formula of consecration: Totus Tuus — \u{201C}totally yours.\u{201D}",
                    "On 13 May 1981, the anniversary of the first apparition at Fatima, he was shot in St. Peter's Square. He was sure that a mother's hand had guided the bullet, and a year later he went to Fatima to give thanks; the bullet was set in the crown of her statue there.",
                    "In Redemptoris Mater (1987) he presented Mary as the one who goes before the Church on her pilgrimage of faith. In Rosarium Virginis Mariae (2002) he called the Rosary a compendium of the Gospel and proposed the five Luminous Mysteries, the mysteries of Christ's public life. His feast is 22 October."
                ],
                quote: ReadingQuote(
                    text: "To recite the Rosary is nothing other than to contemplate with Mary the face of Christ.",
                    citation: "St. John Paul II, Rosarium Virginis Mariae, n. 3"
                ),
                feast: KeptFeast(month: 10, day: 22, name: "St. John Paul II", inMissal: false),
                doors: [.mysteries(.luminous, note: "The mysteries he gave the Church")]
            ),
            LibraryReading(
                id: "padre_pio",
                title: "St. Pio of Pietrelcina",
                detail: "1887\u{2013}1968 · Stigmatist of San Giovanni Rotondo",
                paragraphs: [
                    "Padre Pio was a Capuchin friar who, in 1918, while praying before a crucifix in the choir of his friary at San Giovanni Rotondo, received the wounds of Christ in his hands, feet and side. He bore them for fifty years. He heard confessions for up to sixteen hours a day, and his Mass, which could last hours, drew pilgrims from all over the world.",
                    "He prayed the Rosary almost without ceasing — dozens of times a day, by the friars' count — and called it his weapon. When a friar asked him to leave the brothers something before he died, he answered: \u{201C}Love Our Lady and make her loved. Always recite the Rosary.\u{201D}",
                    "He died on 23 September 1968 with his beads in his hands and the names of Jesus and Mary on his lips. St. John Paul II, who as a young priest had gone to him for confession, canonised him in 2002. The Church keeps his feast on 23 September."
                ],
                quote: ReadingQuote(
                    text: "The Rosary is the weapon for these times.",
                    citation: "St. Pio of Pietrelcina"
                ),
                feast: KeptFeast(month: 9, day: 23, name: "St. Pio of Pietrelcina", inMissal: false),
                doors: [
                    .page(.howToPray, icon: "ch-rosary", title: "How to Pray the Rosary", note: "\u{201C}Always recite the Rosary\u{201D}")
                ]
            )
        ]
    )

    // MARK: The Rosary Through History

    static let rosary = ReadingShelf(
        id: "rosary_history",
        icon: "ch-rosary",
        title: "The Rosary Through History",
        marginLabel: "The\nRosary",
        subtitle: "Eight centuries of Our Lady's Psalter",
        entries: [
            LibraryReading(
                id: "psalter",
                title: "Our Lady's Psalter",
                detail: "Medieval origins",
                paragraphs: [
                    "The monks of the Middle Ages prayed all 150 Psalms each week. The lay brothers, and the ordinary faithful, who could not read the Latin psalter, prayed 150 Our Fathers in their place — counted on strings of knots or beads that came to be called paternosters, and the craftsmen who made them paternosterers.",
                    "As devotion to Our Lady grew, the Angel's greeting took the place of the Our Father, and the 150 Hail Marys came to be called Our Lady's Psalter. The Hail Mary itself was only the words of Gabriel and Elizabeth at first; the name of Jesus was added to it in the thirteenth century, and the second half, \u{201C}Holy Mary, Mother of God, pray for us sinners,\u{201D} was fixed in its present form by St. Pius V's breviary in 1568.",
                    "Slowly the beads were joined to meditation on the life of Christ: a short phrase for each Hail Mary at first, then a mystery for each ten. The Carthusian Dominic of Prussia wrote fifty such phrases in the fifteenth century, and by its end the Rosary had its fifteen mysteries and its shape — vocal prayer and contemplation become one."
                ],
                quote: ReadingQuote(
                    text: "Hail, full of grace, the Lord is with thee: blessed art thou among women.",
                    citation: "Luke 1:28, the Angel's greeting"
                ),
                doors: [
                    .page(.howToPray, icon: "ch-rosary", title: "How to Pray the Rosary", note: "The prayers, bead by bead")
                ]
            ),
            LibraryReading(
                id: "dominic_confraternity",
                title: "St. Dominic and the Confraternity",
                detail: "1214 · Bl. Alan de la Roche, 15th century",
                paragraphs: [
                    "Tradition holds that Our Lady gave the Rosary to St. Dominic as the weapon against the Albigensian heresy. Two centuries later the devotion had grown cold, and a Breton Dominican, Bl. Alan de la Roche, set out to revive it. He preached it across northern France, Flanders and Germany, taught its fifteen mysteries, and in 1470 founded the Confraternity of the Rosary at Douai; within a few years the confraternity at Cologne counted its members by the tens of thousands.",
                    "The confraternity joined its members in one great chain of prayer: each promised to pray the whole Psalter each week, and each shared in the prayers of all the others, living and dead. It still exists, and anyone may join it.",
                    "The Fifteen Promises of Our Lady to those who pray the Rosary faithfully have been handed down through Bl. Alan's writings. The Church has never defined them, but she has let them be printed and loved as a pious tradition, and they have encouraged generations to keep their beads in hand."
                ],
                quote: ReadingQuote(
                    text: "Whoever shall faithfully serve me by the recitation of the Rosary shall receive signal graces.",
                    citation: "The first of the Fifteen Promises, from Bl. Alan de la Roche"
                ),
                doors: [
                    .page(.libraryReading(id: "dominic"), icon: "ph-user", title: "St. Dominic", note: "The Marian Saints")
                ]
            ),
            LibraryReading(
                id: "lepanto",
                title: "Lepanto and the Feast of the Rosary",
                detail: "7 October 1571 · Pope St. Pius V",
                paragraphs: [
                    "In 1571 the Ottoman fleet controlled the eastern Mediterranean and threatened Italy. Pope St. Pius V, himself a Dominican, gathered a Holy League of Spain, Venice and the papacy under Don John of Austria, and asked all of Christendom to pray the Rosary for its victory. On the morning of the battle the confraternities of Rome walked in procession praying it.",
                    "The two fleets met off Lepanto in the Gulf of Patras on 7 October — more than four hundred galleys, the largest sea battle in centuries. The League was outnumbered, and the wind was against it until, around midday, it turned. By evening the Ottoman fleet was destroyed and some fifteen thousand Christian galley slaves were free. Tradition says that at that hour the Pope rose from a meeting in Rome, went to the window, and told those with him to give thanks: the victory was won.",
                    "He instituted a feast of Our Lady of Victory in thanksgiving. His successor Gregory XIII renamed it the feast of the Holy Rosary, and Clement XI extended it to the whole Church after another victory over the Ottomans in 1716. It is kept on 7 October, and October has been the month of the Rosary ever since."
                ],
                quote: ReadingQuote(
                    text: "Neither powers, nor arms, nor leaders, but Our Lady of the Rosary made us victors.",
                    citation: "The Venetian Senate, beneath its painting of the battle"
                ),
                feast: KeptFeast(month: 10, day: 7, name: "The Most Holy Rosary"),
                doors: [
                    .page(.libraryReading(id: "help_of_christians"), icon: "ph-star", title: "Help of Christians", note: "The title Lepanto gave the Litany")
                ]
            ),
            LibraryReading(
                id: "rosary_popes",
                title: "The Rosary Popes",
                detail: "Leo XIII to St. John Paul II",
                paragraphs: [
                    "Pope Leo XIII wrote eleven encyclicals on the Rosary between 1883 and 1898 — one almost every September, to prepare the Church for October — and earned the name the Rosary Pope. He dedicated the month of October to it, added \u{201C}Queen of the most holy Rosary\u{201D} to the Litany of Loreto, and called it the most excellent form of prayer and the most efficacious means of attaining eternal life.",
                    "At Fatima in 1917 Our Lady asked for the daily Rosary in every one of her six apparitions, and on 13 October named herself: \u{201C}I am the Lady of the Rosary.\u{201D} Ven. Pius XII, St. John XXIII and St. Paul VI each wrote on it in turn, Paul VI in Marialis Cultus teaching that without contemplation it is \u{201C}a body without a soul.\u{201D}",
                    "St. John Paul II crowned the tradition in Rosarium Virginis Mariae in 2002, the twenty-fifth year of his pontificate, calling the Rosary his favourite prayer and proposing the Luminous Mysteries to the Church — so that the beads would pass through the whole Gospel, from the Annunciation to the Coronation, by way of the Jordan, Cana, and the Upper Room."
                ],
                quote: ReadingQuote(
                    text: "The Rosary is my favourite prayer. A marvellous prayer! Marvellous in its simplicity and in its depth.",
                    citation: "St. John Paul II, 29 October 1978, quoted in Rosarium Virginis Mariae"
                ),
                doors: [.mysteries(.luminous, note: "The mysteries of light, added in 2002")]
            )
        ]
    )

    // MARK: Titles of Our Lady

    static let titles = ReadingShelf(
        id: "titles",
        icon: "ph-star",
        title: "Titles of Our Lady",
        marginLabel: "Her\ntitles",
        subtitle: "From the Litany and sacred Tradition",
        entries: [
            LibraryReading(
                id: "mediatrix",
                title: "Mediatrix of All Graces",
                detail: "Mediatrix Omnium Gratiarum",
                paragraphs: [
                    "There is one Mediator between God and men, the man Christ Jesus, and every grace comes from Him. Yet God willed that His grace should reach us through Mary. She gave the world its Redeemer by her consent, she stood beside Him when He won our redemption on Calvary, and she prays now in heaven for all that He won to be given to her children.",
                    "St. Bernard taught that God willed us to have everything through Mary. Leo XIII wrote that nothing of the immense treasury of grace which the Lord amassed is given to us except through Mary, and Benedict XV granted a feast of Mary, Mediatrix of All Graces, in 1921. Her mediation adds nothing to Christ's; it is His, shared with her, as a king might give his mother the distribution of his gifts.",
                    "The doctrine has not been solemnly defined, and many of the faithful pray that it will be, as a fifth Marian dogma. It is the keystone of St. Louis de Montfort's True Devotion: we give everything to her because everything comes to us through her."
                ],
                quote: ReadingQuote(
                    text: "Such is the will of God, who would have us receive everything through Mary.",
                    citation: "St. Bernard, Sermon on the Aqueduct"
                ),
                doors: [
                    .page(.trueDevotion, icon: "ph-scroll", title: "The Devotion in Summary", note: "Montfort's consecration")
                ]
            ),
            LibraryReading(
                id: "morning_star",
                title: "Morning Star",
                detail: "Stella Matutina · Stella Maris",
                paragraphs: [
                    "The morning star rises before the sun and tells the night that day is coming. Mary rose before Christ, the Sun of Justice, and her birth told the world that its salvation was near. The Church sings on the feast of her Nativity that it announced joy to the whole world.",
                    "Sailors steered by the star of the sea, the fixed star by which they found their way in the dark, and from the early Middle Ages Christians gave that name to Mary. The ninth-century hymn Ave Maris Stella, which the Office sings at Vespers on her feasts, greets her by it: \u{201C}Hail, O Star of the ocean.\u{201D}",
                    "The two titles say the same thing from two sides. She is not the light; she is the one who shows where the light is, and who shines only with the light of the Sun she goes before."
                ],
                quote: ReadingQuote(
                    text: "Hail, O Star of the ocean, God's own Mother blest, ever sinless Virgin, gate of heavenly rest.",
                    citation: "Ave Maris Stella, the Vespers hymn of her feasts"
                ),
                feast: KeptFeast(month: 9, day: 8, name: "The Nativity of Our Lady"),
                doors: [.prayer(id: "ave_maris_stella", note: "The hymn of her Vespers")]
            ),
            LibraryReading(
                id: "gate_of_heaven",
                title: "Gate of Heaven",
                detail: "Janua Caeli",
                paragraphs: [
                    "Through Mary, God came down to us; through Mary, we go up to God. Jacob, waking from his dream of the ladder, cried out that the place was nothing other than the house of God and the gate of heaven, and the Church sings those words of her.",
                    "St. Louis de Montfort calls her the Eastern Gate of Ezechiel's temple, by which the High Priest entered the world and by which He will come again. The gate was shut, and no man passed through it, because the Lord had entered by it.",
                    "A gate is not a destination. No one prays to Mary in order to stop at her; she opens on her Son. That is why the Church can call her the Gate of Heaven without ever confusing her with heaven itself."
                ],
                quote: ReadingQuote(
                    text: "How terrible is this place! this is no other but the house of God, and the gate of heaven.",
                    citation: "Genesis 28:17"
                ),
                doors: [.prayer(id: "litany_loreto", note: "Where she is hailed Janua Caeli")]
            ),
            LibraryReading(
                id: "help_of_christians",
                title: "Help of Christians",
                detail: "Auxilium Christianorum",
                paragraphs: [
                    "The title is old, but it entered the Litany of Loreto, as tradition holds, in thanksgiving for the victory at Lepanto in 1571, when Christendom had prayed the Rosary and been delivered.",
                    "Pope Pius VII, held prisoner for five years by Napoleon, came home to Rome on 24 May 1814. The next year, in gratitude to Our Lady, he instituted a feast of Mary, Help of Christians, to be kept on that day.",
                    "St. John Bosco made it his title for her. He built his great basilica in Turin in her honour, and told his boys that everything he had done, she had done: \u{201C}Have devotion to Mary Help of Christians, and you will see what miracles are.\u{201D}"
                ],
                quote: ReadingQuote(
                    text: "Have devotion to Mary Help of Christians, and you will see what miracles are.",
                    citation: "St. John Bosco"
                ),
                feast: KeptFeast(month: 5, day: 24, name: "Mary, Help of Christians", inMissal: false, keptBy: "the Salesians and many dioceses"),
                doors: [
                    .page(.libraryReading(id: "lepanto"), icon: "ch-rosary", title: "Lepanto", note: "The Rosary Through History")
                ]
            ),
            LibraryReading(
                id: "queen_of_peace",
                title: "Queen of Peace",
                detail: "Regina Pacis",
                paragraphs: [
                    "Pope Benedict XV added this invocation to the Litany of Loreto in 1917, in the third year of the First World War, after his appeals to the warring nations had gone unheard. He asked the whole Church to turn to the Mother of the Prince of Peace.",
                    "Eight days after he asked it, Our Lady appeared for the first time at Fatima, and asked the three children to pray the Rosary every day \u{201C}to obtain peace for the world, and the end of the war.\u{201D}",
                    "The peace she brings begins in the heart. Where her Rosary is prayed families are reconciled and the anxious are quieted, and the Church has always believed that the same prayer can reach the affairs of nations."
                ],
                quote: ReadingQuote(
                    text: "Pray the Rosary every day, in order to obtain peace for the world, and the end of the war.",
                    citation: "Our Lady at Fatima, 13 May 1917"
                ),
                doors: [
                    .page(.libraryReading(id: "fatima"), icon: "ph-sun", title: "Our Lady of Fatima", note: "Approved Apparitions")
                ]
            )
        ],
        footnote: "\u{2026}and many more, sung in the Litany of Loreto."
    )
}
