//
//  HowToPrayData.swift
//  Lumen Viae
//
//  How to Pray the Rosary: the steps, each tied to the prayer said at
//  it, and St. Louis de Montfort's counsel for praying it well — his two
//  methods and his advice, from The Secret of the Rosary — as readings.
//

import Foundation

// MARK: - A Step

struct RosaryStep: Identifiable {
    let id: Int
    let title: String
    let detail: String

    /// The prayers said at this step, in order (`DevotionPrayers`)
    var prayerIDs: [String] = []
}

enum HowToPrayData {

    static let steps: [RosaryStep] = [
        RosaryStep(id: 1, title: "Make the Sign of the Cross", detail: "Holding the crucifix, sign yourself from forehead to breast, and shoulder to shoulder.", prayerIDs: ["sign_of_cross"]),
        RosaryStep(id: 2, title: "Pray the Apostles' Creed", detail: "Still holding the crucifix, profess the faith of the Church.", prayerIDs: ["apostles_creed"]),
        RosaryStep(id: 3, title: "Pray one Our Father", detail: "On the first large bead.", prayerIDs: ["our_father"]),
        RosaryStep(id: 4, title: "Pray three Hail Marys", detail: "On the three small beads — traditionally offered for an increase of faith, hope, and charity.", prayerIDs: ["hail_mary"]),
        RosaryStep(id: 5, title: "Pray the Glory Be", detail: "On reaching the next large bead, before anything else is said on it.", prayerIDs: ["glory_be"]),
        RosaryStep(id: 6, title: "Announce the first mystery", detail: "Name it — \u{201C}The first Joyful Mystery: the Annunciation\u{201D} — and picture the scene. Then, on the large bead, pray the Our Father.", prayerIDs: ["our_father"]),
        RosaryStep(id: 7, title: "Pray ten Hail Marys", detail: "On the ten small beads of the decade, keeping the mystery before your mind's eye.", prayerIDs: ["hail_mary"]),
        RosaryStep(id: 8, title: "Close the decade", detail: "On the next large bead, before its Our Father: the Glory Be, then the Fatima Prayer, which Our Lady asked for at Fatima.", prayerIDs: ["glory_be", "fatima_prayer"]),
        RosaryStep(id: 9, title: "Pray the other four decades", detail: "Announce each mystery in turn, then the Our Father, ten Hail Marys, the Glory Be and the Fatima Prayer."),
        RosaryStep(id: 10, title: "Conclude", detail: "Pray the Hail, Holy Queen and the closing prayer, and end with the Sign of the Cross. Many add the Memorare, the Prayer to Saint Michael, or an Our Father, Hail Mary and Glory Be for the Holy Father before the last Sign of the Cross.", prayerIDs: ["hail_holy_queen", "rosary_closing_prayer"])
    ]

    // MARK: - Montfort's Counsel

    static let methods = ReadingShelf(
        id: "montfort_methods",
        icon: "ch-rosary",
        title: "Montfort's Counsel",
        marginLabel: "Praying\nit well",
        subtitle: "From St. Louis de Montfort's The Secret of the Rosary",
        entries: [
            LibraryReading(
                id: "montfort_offering",
                title: "Offer Each Decade",
                detail: "His first method",
                paragraphs: [
                    "St. Louis de Montfort, the great apostle of the Rosary, left several methods for praying it more fruitfully. Each uses the same beads and the same prayers; what changes is how deeply the mystery enters them. In the first, each decade is offered to Our Lord before it is prayed, in honour of its mystery, with a request through Mary for the grace that mystery teaches.",
                    "After the decade, ask for that grace again: \u{201C}May the grace of the mystery of the Incarnation come down into our souls. Amen.\u{201D} He wrote the method for the fifteen traditional mysteries; the same spirit carries naturally into the Luminous."
                ],
                quote: ReadingQuote(
                    text: "We offer Thee, O Lord Jesus, this first decade in honour of Thy Incarnation, and we ask of Thee, through this mystery and through the intercession of Thy most holy Mother, a profound humility. Amen.",
                    citation: "The offering of the first Joyful Mystery"
                ),
                doors: [.act(.todaysRosary, note: "Pray it this way today")],
                tables: [
                    ReadingTable("The Joyful Mysteries", """
The Annunciation — a profound humility
The Visitation — charity towards our neighbour
The Nativity — detachment from the things of the world and love of poverty
The Presentation — purity of body and soul
The Finding in the Temple — true wisdom
"""),
                    ReadingTable("The Sorrowful Mysteries", """
The Agony in the Garden — contrition for our sins
The Scourging — mortification of our senses
The Crowning with Thorns — contempt of the world
The Carrying of the Cross — patience in bearing our crosses
The Crucifixion — horror of sin, love of the Cross, and the grace of a holy death
"""),
                    ReadingTable("The Glorious Mysteries", """
The Resurrection — a lively faith
The Ascension — a firm hope and a longing for heaven
The Descent of the Holy Spirit — the coming of the Holy Spirit into our souls
The Assumption — a tender devotion to Mary
The Coronation — perseverance in grace and a crown of glory
""")
                ]
            ),
            LibraryReading(
                id: "montfort_clauses",
                title: "A Word Within Each Hail Mary",
                detail: "His shorter method",
                paragraphs: [
                    "The second method keeps the mystery present through every bead. After the name of Jesus in each Hail Mary of the decade, add a few words that recall the mystery — \u{201C}and blessed is the fruit of thy womb, Jesus, becoming man\u{201D} — and go on with the prayer.",
                    "It is the simplest way to keep the mind from wandering, because the mystery is spoken ten times in the decade and the Hail Mary becomes a meditation of its own. The clause for each mystery:"
                ],
                quote: ReadingQuote(
                    text: "\u{2026}and blessed is the fruit of thy womb, Jesus, becoming man. Holy Mary, Mother of God\u{2026}",
                    citation: "The first Joyful Mystery"
                ),
                doors: [.act(.todaysRosary, note: "Pray it this way today")],
                tables: [
                    ReadingTable("The Joyful Mysteries", """
The Annunciation — Jesus becoming man
The Visitation — Jesus sanctifying
The Nativity — Jesus born in poverty
The Presentation — Jesus sacrificed
The Finding in the Temple — Jesus, holy of holies
"""),
                    ReadingTable("The Sorrowful Mysteries", """
The Agony in the Garden — Jesus in His agony
The Scourging — Jesus scourged
The Crowning with Thorns — Jesus crowned with thorns
The Carrying of the Cross — Jesus carrying His cross
The Crucifixion — Jesus crucified
"""),
                    ReadingTable("The Glorious Mysteries", """
The Resurrection — Jesus risen from the dead
The Ascension — Jesus ascending to heaven
The Descent of the Holy Spirit — Jesus filling thee with the Holy Spirit
The Assumption — Jesus raising thee up
The Coronation — Jesus crowning thee
""")
                ]
            ),
            LibraryReading(
                id: "montfort_well",
                title: "Saying It Well",
                detail: "His counsel for every Rosary",
                paragraphs: [
                    "Begin with purity of intention. Offer the Rosary for a definite grace or intention, in union with Jesus praying in you, and remember whom you are speaking to.",
                    "Picture the scene. Before each decade, pause and place the mystery before your mind's eye — the stable, the garden, the empty tomb — and stay in it while you pray. The words are the beads' work; the heart's work is to look.",
                    "Pray without rushing. Montfort asks for small pauses within the prayers themselves, and says that one Rosary said slowly and attentively is worth more than several hurried ones.",
                    "Fight distractions gently. They will come, and they are not a failure. Each time you notice you have wandered, return to the mystery without fuss; that quiet return is itself a prayer.",
                    "Persevere in dryness. The Rosary prayed faithfully when it feels dry and unrewarding is especially pleasing to God. Fidelity, not feeling, is the measure."
                ],
                quote: ReadingQuote(
                    text: "The Rosary without meditation on the sacred mysteries of our salvation would almost be a body without a soul.",
                    citation: "St. Louis de Montfort, The Secret of the Rosary"
                ),
                doors: [
                    .page(.libraryReading(id: "montfort"), icon: "ph-user", title: "St. Louis de Montfort", note: "The Marian Saints")
                ]
            )
        ]
    )

    // MARK: - How Often Each Prayer Is Said

    /// How often each prayer comes round in one Rosary of five decades —
    /// what a beginner most wants to know before learning them
    static let prayerCounts: [String: String] = [
        "sign_of_cross": "At the beginning and the end",
        "apostles_creed": "Once, on the crucifix",
        "our_father": "Six times — once on each large bead",
        "hail_mary": "Fifty-three times — ten on each decade, three at the start",
        "glory_be": "Six times — after the three and after each decade",
        "fatima_prayer": "Five times — after each decade",
        "hail_holy_queen": "Once, at the end",
        "rosary_closing_prayer": "Once, at the very end"
    ]

    // MARK: - Questions Beginners Ask

    static let questions = ReadingShelf(
        id: "rosary_questions",
        icon: "ph-question",
        title: "Questions Beginners Ask",
        marginLabel: "Questions",
        subtitle: "What people wonder before their first Rosary",
        entries: [
            LibraryReading(
                id: "q_beads",
                title: "Do I need a rosary?",
                detail: "No — ten fingers will do",
                paragraphs: [
                    "Beads help, because they keep the count so your mind does not have to, but they are not required. Count the Hail Marys on your ten fingers, or on a knotted cord, as Christians did for centuries before beads were common.",
                    "If you would like a rosary, any parish or Catholic shop will have one, and many parishes give them away. It is customary to have it blessed by a priest, but an unblessed rosary prays just as well."
                ],
                quote: nil
            ),
            LibraryReading(
                id: "q_by_heart",
                title: "Do I have to know the prayers by heart?",
                detail: "No — read them",
                paragraphs: [
                    "Read them from the page as you go; your first Rosary, the last step of the course, shows every word. After a few times you will find you know them, without ever having sat down to memorise anything.",
                    "Start with the Hail Mary, since it is said fifty-three times in a Rosary. The first half is the angel Gabriel's greeting and St. Elizabeth's words from the Gospel of Luke; the second half is a request for Mary's prayers."
                ],
                quote: nil,
                doors: [.page(.devotionPrayer(id: "hail_mary"), icon: "ph-hands-praying", title: "The Hail Mary", note: "The words, on a page of their own")]
            ),
            LibraryReading(
                id: "q_think",
                title: "What do I think about while I pray?",
                detail: "The mystery",
                paragraphs: [
                    "Each decade has a mystery — a scene from the life of Jesus and Mary: the angel's visit to Nazareth, the agony in the garden, the empty tomb. While your lips say the Hail Marys, your mind stays with that scene.",
                    "It can help to picture it as if you were there. Where is Mary standing? What does she see? What would you say? The words of the prayer become like music playing while you look.",
                    "Some people read the Gospel passage first. Others ask, in each decade, for the grace the mystery teaches — humility, patience, faith. There is no wrong way to look at Christ."
                ],
                quote: ReadingQuote(
                    text: "Without contemplation, the Rosary is a body without a soul.",
                    citation: "St. Paul VI, Marialis Cultus"
                ),
                doors: [.page(.scripture, icon: "lv-breviary", title: "The Mysteries in Scripture", note: "Each mystery's passage, to read first")]
            ),
            LibraryReading(
                id: "q_wander",
                title: "What if my mind wanders?",
                detail: "It will — come back gently",
                paragraphs: [
                    "It happens to everyone, saints included. When you notice that you have drifted, do not scold yourself and do not start again. Simply come back to the mystery and carry on from the bead you are on.",
                    "Each return is itself an act of love. A Rosary full of wandering and returning is still a Rosary prayed."
                ],
                quote: nil
            ),
            LibraryReading(
                id: "q_count",
                title: "What if I lose count?",
                detail: "Carry on",
                paragraphs: [
                    "The beads keep the count so you do not have to. If you lose track, go on from wherever you think you are. God is not counting Hail Marys; He is looking at the heart that says them.",
                    "In your first Rosary, the drawing of the beads shows exactly where you are, bead by bead."
                ],
                quote: nil
            ),
            LibraryReading(
                id: "q_mary",
                title: "Is it praying to Mary instead of God?",
                detail: "It is praying with her",
                paragraphs: [
                    "Every mystery of the Rosary is about Jesus: His birth, His suffering, His rising. We ask Mary to pray for us, as we might ask a friend, and she does what she has always done — she points to her Son.",
                    "Most of the Hail Mary is Scripture: the angel's words, \u{201C}Hail, full of grace, the Lord is with thee,\u{201D} and Elizabeth's, \u{201C}Blessed art thou among women, and blessed is the fruit of thy womb.\u{201D} Its centre is the name of Jesus.",
                    "The Rosary begins with the Creed and the Our Father and ends with a prayer to God. Mary is the one who walks beside us through it."
                ],
                quote: ReadingQuote(
                    text: "To recite the Rosary is nothing other than to contemplate with Mary the face of Christ.",
                    citation: "St. John Paul II, Rosarium Virginis Mariae, n. 3"
                ),
                doors: [.page(.libraryReading(id: "cana"), icon: "ch-lily", title: "The Wedding at Cana", note: "\u{201C}Whatsoever he shall say to you, do ye\u{201D}")]
            ),
            LibraryReading(
                id: "q_one_decade",
                title: "Can I pray just one decade?",
                detail: "Yes — it is a good beginning",
                paragraphs: [
                    "A single decade — an Our Father, ten Hail Marys and a Glory Be, on one mystery — is a real prayer, and many people begin with one a day. The whole Rosary is five decades.",
                    "You can also divide a Rosary through the day: a decade in the morning, one on the way to work, the rest in the evening."
                ],
                quote: nil
            ),
            LibraryReading(
                id: "q_where",
                title: "Where and how should I pray it?",
                detail: "Anywhere",
                paragraphs: [
                    "In a church before the tabernacle, at home, walking, on a bus, lying awake at night. Kneeling is a beautiful posture if you are able; sitting or walking is fine. Praying it aloud with others — a family, a group, a parish — is a treasured custom, and so is praying it alone and silent.",
                    "What matters is attention, not position. Find a time you can keep, and come back to it."
                ],
                quote: nil
            ),
            LibraryReading(
                id: "q_not_catholic",
                title: "Can I pray it if I'm not Catholic?",
                detail: "Yes — anyone may",
                paragraphs: [
                    "The Rosary belongs to anyone who wants to meet Christ in the Gospel. Many have come to faith by way of it, and many Christians of other traditions pray it.",
                    "If you are exploring the faith, the Rosary is a gentle place to begin: it walks you through the life of Jesus, a scene at a time, in the company of His Mother."
                ],
                quote: nil
            )
        ]
    )
}
