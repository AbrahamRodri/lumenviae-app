//
//  ConsecrationData.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  CONSECRATION DATA - STATIC DATA FOR THE 33-DAY CONSECRATION
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Contains all prayers and day definitions for the 33-Day Total Consecration
//  to Jesus through Mary (St. Louis de Montfort).
//
//  Note: Prayer texts and meditation content are placeholders.
//  Actual content should be added from authorized sources.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - ConsecrationData

/// Static data source for the 33-Day Consecration.
enum ConsecrationData {

    // MARK: - Prayers

    /// All prayers used throughout the consecration, keyed by ID
    static let allPrayers: [String: ConsecrationPrayer] = [
        "veni_creator": ConsecrationPrayer(
            id: "veni_creator",
            title: "Come, Creator Spirit",
            latinTitle: "Veni Creator Spiritus",
            content: """
Come, Holy Spirit, Creator blest,
and in our souls take up Thy rest;
come with Thy grace and heavenly aid
to fill the hearts which Thou hast made.

O comforter, to Thee we cry,
O heavenly gift of God Most High,
O fount of life and fire of love,
and sweet anointing from above.

Thou in Thy sevenfold gifts are known;
Thou, finger of God's hand we own;
Thou, promise of the Father, Thou
Who dost the tongue with power imbue.

Kindle our sense from above,
and make our hearts o'erflow with love;
with patience firm and virtue high
the weakness of our flesh supply.

Far from us drive the foe we dread,
and grant us Thy peace instead;
so shall we not, with Thee for guide,
turn from the path of life aside.

Oh, may Thy grace on us bestow
the Father and the Son to know;
and Thee, through endless times confessed,
of both the eternal Spirit blest.

Now to the Father and the Son,
Who rose from death, be glory given,
with Thou, O Holy Comforter,
henceforth by all in earth and heaven.

Amen.
"""
        ),
        "ave_maris_stella": ConsecrationPrayer(
            id: "ave_maris_stella",
            title: "Hail, Star of the Sea",
            latinTitle: "Ave Maris Stella",
            content: """
Hail, O Star of the ocean,
God's own Mother blest,
ever sinless Virgin,
gate of heav'nly rest.

Taking that sweet Ave,
which from Gabriel came,
peace confirm within us,
changing Eve's name.

Break the sinners' fetters,
make our blindness day,
Chase all evils from us,
for all blessings pray.

Show thyself a Mother,
may the Word divine
born for us thine Infant
hear our prayers through thine.

Virgin all excelling,
mildest of the mild,
free from guilt preserve us
meek and undefiled.

Keep our life all spotless,
make our way secure
till we find in Jesus,
joy for evermore.

Praise to God the Father,
honor to the Son,
in the Holy Spirit,
be the glory one.

Amen.
"""
        ),
        "magnificat": ConsecrationPrayer(
            id: "magnificat",
            title: "The Canticle of Mary",
            latinTitle: "Magnificat",
            content: """
My soul doth magnify the Lord.
And my spirit hath rejoiced in God my Savior.
Because He hath regarded the humility of his handmaid:
for behold from henceforth all generations shall call me blessed.
Because He that is mighty hath done great things to me:
and holy is His name.
And His mercy is from generation unto generations,
to them that fear Him.
He hath showed might in His arm:
He hath scattered the proud in the conceit of their heart.
He hath put down the mighty from their seat:
and hath exalted the humble.
He hath filled the hungry with good things:
and the rich He hath sent empty away.
He hath received Israel His servant:
being mindful of His mercy.
As He spoke to our fathers:
to Abraham and to his seed forever.

Glory be to the Father, and to the Son, and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be, world without end.

Amen.
"""
        ),
        "glory_be": ConsecrationPrayer(
            id: "glory_be",
            title: "Glory Be",
            latinTitle: "Gloria Patri",
            content: """
Glory be to the Father,
and to the Son,
and to the Holy Spirit,
as it was in the beginning,
is now, and ever shall be,
world without end.

Amen.
"""
        ),
        "litany_holy_ghost": ConsecrationPrayer(
            id: "litany_holy_ghost",
            title: "Litany of the Holy Ghost",
            latinTitle: nil,
            content: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.

Father all powerful, have mercy on us.
Jesus, Eternal Son of the Father, Redeemer of the world, save us.
Spirit of the Father and the Son, boundless life of both, sanctify us.
Holy Trinity, hear us.

Holy Ghost, Who proceedest from the Father and the Son, enter our hearts.
Holy Ghost, Who art equal to the Father and the Son, enter our hearts.

Promise of God the Father, have mercy on us.
Ray of heavenly light, have mercy on us.
Author of all good, have mercy on us.
Source of heavenly water, have mercy on us.
Consuming fire, have mercy on us.
Ardent charity, have mercy on us.
Spiritual unction, have mercy on us.
Spirit of love and truth, have mercy on us.
Spirit of wisdom and understanding, have mercy on us.
Spirit of counsel and fortitude, have mercy on us.
Spirit of knowledge and piety, have mercy on us.
Spirit of the fear of the Lord, have mercy on us.
Spirit of grace and prayer, have mercy on us.
Spirit of peace and meekness, have mercy on us.
Spirit of modesty and innocence, have mercy on us.
Holy Ghost, the Comforter, have mercy on us.
Holy Ghost, the Sanctifier, have mercy on us.
Holy Ghost, Who governest the Church, have mercy on us.
Gift of God, the Most High, have mercy on us.
Spirit Who fillest the universe, have mercy on us.
Spirit of the adoption of the children of God, have mercy on us.

Holy Ghost, inspire us with horror of sin.
Holy Ghost, come and renew the face of the earth.
Holy Ghost, shed Thy light in our souls.
Holy Ghost, engrave Thy law in our hearts.
Holy Ghost, inflame us with the flame of Thy love.
Holy Ghost, open to us the treasures of Thy graces.
Holy Ghost, teach us to pray well.
Holy Ghost, enlighten us with Thy heavenly inspirations.
Holy Ghost, lead us in the way of salvation.
Holy Ghost, grant us the only necessary knowledge.
Holy Ghost, inspire in us the practice of good.
Holy Ghost, grant us the merits of all virtues.
Holy Ghost, make us persevere in justice.
Holy Ghost, be Thou our everlasting reward.

Lamb of God, Who takest away the sins of the world, Send us Thy Holy Ghost.
Lamb of God, Who takest away the sins of the world, pour down into our souls the gifts of the Holy Ghost.
Lamb of God, Who takest away the sins of the world, grant us the Spirit of wisdom and piety.

V. Come, Holy Ghost! Fill the hearts of Thy faithful,
R. And enkindle in them the fire of Thy love.

Let Us Pray.
Grant, O merciful Father, that Thy Divine Spirit may enlighten, inflame and purify us, that He may penetrate us with His heavenly dew and make us fruitful in good works, through Our Lord Jesus Christ, Thy Son, Who with Thee, in the unity of the same Spirit, liveth and reigneth forever and ever.

R. Amen.
"""
        ),
        "litany_loreto": ConsecrationPrayer(
            id: "litany_loreto",
            title: "Litany of the Blessed Virgin Mary",
            latinTitle: "Litaniae Lauretanae",
            content: """
Lord, have mercy on us, Christ have mercy on us.
Lord, have mercy on us. Christ hear us. Christ, graciously hear us.

God the Father of Heaven, have mercy on us.
God the Son, Redeemer of the world, have mercy on us.
God the Holy Ghost, have mercy on us.
Holy Trinity, One God, have mercy on us.

Holy Mary, pray for us.
Holy Mother of God, pray for us.
Holy Virgin of virgins, pray for us.
Mother of Christ, pray for us.
Mother of divine grace, pray for us.
Mother most pure, pray for us.
Mother most chaste, pray for us.
Mother inviolate, pray for us.
Mother undefiled, pray for us.
Mother most amiable, pray for us.
Mother most admirable, pray for us.
Mother of good counsel, pray for us.
Mother of our Creator, pray for us.
Mother of our Saviour, pray for us.
Mother of the Church, pray for us.
Virgin most prudent, pray for us.
Virgin most venerable, pray for us.
Virgin most renowned, pray for us.
Virgin most powerful, pray for us.
Virgin most merciful, pray for us.
Virgin most faithful, pray for us.
Mirror of justice, pray for us.
Seat of wisdom, pray for us.
Cause of our joy, pray for us.
Vessel of honor, pray for us.
Singular vessel of devotion, pray for us.
Mystical rose, pray for us.
Tower of David, pray for us.
Tower of ivory, pray for us.
House of gold, pray for us.
Ark of the covenant, pray for us.
Gate of Heaven, pray for us.
Morning star, pray for us.
Health of the sick, pray for us.
Refuge of sinners, pray for us.
Comforter of the afflicted, pray for us.
Help of Christians, pray for us.
Queen of angels, pray for us.
Queen of patriarchs, pray for us.
Queen of prophets, pray for us.
Queen of Apostles, pray for us.
Queen of martyrs, pray for us.
Queen of confessors, pray for us.
Queen of virgins, pray for us.
Queen of all saints, pray for us.
Queen conceived without Original Sin, pray for us.
Queen assumed into Heaven, pray for us.
Queen of the most holy Rosary, pray for us.
Queen of peace, pray for us.

Lamb of God, Who takest away the sins of the world, Spare us, O Lord.
Lamb of God, Who takest away the sins of the world, Graciously hear us, O Lord.
Lamb of God, Who takest away the sins of the world, Have mercy on us.

V. Pray for us, O holy Mother of God,
R. That we may be made worthy of the promises of Christ.

Let Us Pray.
Grant, we beseech Thee, O Lord God, unto us Thy servants, that we may rejoice in continual health of mind and body, and by the glorious intercession of Blessed Mary, ever virgin, may be delivered from present sadness, and enter into the joy of Thine eternal gladness. Through Christ Our Lord.

R. Amen.
"""
        ),
        "litany_holy_name": ConsecrationPrayer(
            id: "litany_holy_name",
            title: "Litany of the Holy Name of Jesus",
            latinTitle: nil,
            content: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us. Jesus, hear us.
Jesus, graciously hear us.

God the Father of Heaven, have mercy on us.
God the Son, Redeemer of the world, have mercy on us.
God the Holy Ghost, have mercy on us.
Holy Trinity, One God, have mercy on us.
Jesus, Son of the living God, have mercy on us.
Jesus, splendor of the Father, have mercy on us.
Jesus, brightness of eternal light, have mercy on us.
Jesus, King of glory, have mercy on us.
Jesus, sun of justice, have mercy on us.
Jesus, Son of the Virgin Mary, have mercy on us.
Jesus, most amiable, have mercy on us.
Jesus, most admirable, have mercy on us.
Jesus, mighty God, have mercy on us.
Jesus, Father of the world to come, have mercy on us.
Jesus, angel of great counsel, have mercy on us.
Jesus, most powerful, have mercy on us.
Jesus, most patient, have mercy on us.
Jesus, most obedient, have mercy on us.
Jesus, meek and humble, have mercy on us.
Jesus, lover of chastity, have mercy on us.
Jesus, lover of us, have mercy on us.
Jesus, God of peace, have mercy on us.
Jesus, author of life, have mercy on us.
Jesus, model of virtues, have mercy on us.
Jesus, lover of souls, have mercy on us.
Jesus, our God, have mercy on us.
Jesus, our refuge, have mercy on us.
Jesus, Father of the poor, have mercy on us.
Jesus, treasure of the faithful, have mercy on us.
Jesus, Good Shepherd, have mercy on us.
Jesus, true light, have mercy on us.
Jesus, eternal wisdom, have mercy on us.
Jesus, infinite goodness, have mercy on us.
Jesus, our way and our life, have mercy on us.
Jesus, joy of angels, have mercy on us.
Jesus, King of patriarchs, have mercy on us.
Jesus, master of Apostles, have mercy on us.
Jesus, teacher of Evangelists, have mercy on us.
Jesus, strength of martyrs, have mercy on us.
Jesus, light of confessors, have mercy on us.
Jesus, purity of virgins, have mercy on us.
Jesus, crown of all saints, have mercy on us.

Be merciful, spare us, O Jesus.
Be merciful, graciously hear us, O Jesus.

From all evil, Jesus, deliver us.
From all sin, Jesus, deliver us.
From Thy wrath, Jesus, deliver us.
From the snares of the devil, Jesus, deliver us.
From the spirit of fornication, Jesus, deliver us.
From everlasting death, Jesus, deliver us.
From the neglect of Thine inspirations, Jesus, deliver us.

Through the mystery of Thy holy Incarnation, Jesus, deliver us.
Through Thy nativity, Jesus, deliver us.
Through Thine infancy, Jesus, deliver us.
Through Thy most divine life, Jesus, deliver us.
Through Thy labors, Jesus, deliver us.
Through Thine agony and Passion, Jesus, deliver us.
Through Thy cross and dereliction, Jesus, deliver us.
Through Thy sufferings, Jesus, deliver us.
Through Thy death and burial, Jesus, deliver us.
Through Thy Resurrection, Jesus, deliver us.
Through Thine Ascension, Jesus, deliver us.
Through Thine institution of the most Holy Eucharist, Jesus, deliver us.
Through Thy joys, Jesus, deliver us.
Through Thy glory, Jesus, deliver us.

Lamb of God, Who takest away the sins of the world, Spare us, O Jesus.
Lamb of God, Who takest away the sins of the world, Graciously hear us, O Jesus.
Lamb of God, Who takest away the sins of the world, Have mercy on us.

Jesus, hear us,
Jesus, graciously hear us.

Let Us Pray.
O Lord Jesus Christ, Who hast said: Ask and ye shall receive, seek and ye shall find, knock and it shall be opened unto you; grant, we beseech Thee, to us who ask the gift of Thy divine love, that we may ever love Thee with all our hearts, and in all our words and actions, and never cease from praising Thee.

Give us, O Lord, a perpetual fear and love of Thy holy Name; for Thou never failest to govern those whom Thou dost solidly establish in Thy love, Who livest and reignest world without end.

R. Amen.
"""
        ),
        "st_louis_prayer_mary": ConsecrationPrayer(
            id: "st_louis_prayer_mary",
            title: "St. Louis De Montfort's Prayer to Mary",
            latinTitle: nil,
            content: """
Hail Mary, beloved Daughter of the Eternal Father! Hail Mary, admirable Mother of the Son! Hail Mary, faithful spouse of the Holy Ghost! Hail Mary, my dear Mother, my loving Mistress, my powerful sovereign! Hail my joy, my glory, my heart and my soul! Thou art all mine by mercy, and I am all thine by justice. But I am not yet sufficiently thine. I now give myself wholly to thee without keeping anything back for myself or others. If thou still seest in me anything which does not belong to thee, I beseech thee to take it and to make thyself the absolute Mistress of all that is mine. Destroy in me all that may be displeasing to God, root it up and bring it to nought; place and cultivate in me everything that is pleasing to thee.

May the light of thy faith dispel the darkness of my mind; may thy profound humility take the place of my pride; may thy sublime contemplation check the distractions of my wandering imagination; may thy continuous sight of God fill my memory with His presence; may the burning love of thy heart inflame the lukewarmness of mine; may thy virtues take the place of my sins; may thy merits be my only adornment in the sight of God and make up for all that is wanting in me. Finally, dearly beloved Mother, grant, if it be possible, that I may have no other spirit but thine to know Jesus and His divine will; that I may have no other soul but thine to praise and glorify the Lord; that I may have no other heart but thine to love God with a love as pure and ardent as thine. I do not ask thee for visions, revelations, sensible devotion or spiritual pleasures. It is thy privilege to see God clearly; it is thy privilege to enjoy heavenly bliss; it is thy privilege to triumph gloriously in Heaven at the right hand of thy Son and to hold absolute sway over angels, men and demons; it is thy privilege to dispose of all the gifts of God, just as thou willest.

Such is, O heavenly Mary, the "best part," which the Lord has given thee and which shall never be taken away from thee - and this thought fills my heart with joy. As for my part here below, I wish for no other than that which was thine: to believe sincerely without spiritual pleasures; to suffer joyfully without human consolation; to die continually to myself without respite; and to work zealously and unselfishly for thee until death as the humblest of thy servants. The only grace I beg thee to obtain for me is that every day and every moment of my life I may say: Amen, so be it - to all that thou didst do while on earth; Amen, so be it - to all that thou art now doing in Heaven; Amen, so be it - to all that thou art doing in my soul, so that thou alone mayest fully glorify Jesus in me for time and eternity.

Amen.
"""
        ),
        "st_louis_prayer_jesus": ConsecrationPrayer(
            id: "st_louis_prayer_jesus",
            title: "St. Louis De Montfort's Prayer to Jesus",
            latinTitle: nil,
            content: """
O most loving Jesus, deign to let me pour forth my gratitude before Thee, for the grace Thou hast bestowed upon me in giving me to Thy holy Mother through the devotion of Holy Bondage, that she may be my advocate in the presence of Thy majesty and my support in my extreme misery. Alas, O Lord! I am so wretched that without this dear Mother I should be certainly lost. Yes, Mary is necessary for me at Thy side and everywhere: that she may appease Thy just wrath, because I have so often offended Thee; that she may save me from the eternal punishment of Thy justice, which I deserve; that she may contemplate Thee, speak to Thee, pray to Thee, approach Thee and please Thee; that she may help me to save my soul and the souls of others; in short, Mary is necessary for me that I may always do Thy holy will and seek Thy greater glory in all things.

Ah, would that I could proclaim throughout the whole world the mercy that Thou hast shown to me! Would that everyone might know I should be already damned, were it not for Mary! Would that I might offer worthy thanksgiving for so great a blessing! Mary is in me. Oh, what a treasure! Oh, what a consolation! And shall I not be entirely hers? Oh, what ingratitude! My dear Saviour, send me death rather than such a calamity, for I would rather die than live without belonging entirely to Mary.

With St. John the Evangelist at the foot of the Cross, I have taken her a thousand times for my own and as many times have given myself to her; but if I have not yet done it as Thou, dear Jesus, dost wish, I now renew this offering as Thou dost desire me to renew it. And if Thou seest in my soul or my body anything that does not belong to this august princess, I pray Thee to take it and cast it far from me, for whatever in me does not belong to Mary is unworthy of Thee.

O Holy Spirit, grant me all these graces. Plant in my soul the Tree of true Life, which is Mary; cultivate it and tend it so that it may grow and blossom and bring forth the fruit of life in abundance. O Holy Spirit, give me great devotion to Mary, Thy faithful spouse; give me great confidence in her maternal heart and an abiding refuge in her mercy, so that by her Thou mayest truly form in me Jesus Christ, great and mighty, unto the fullness of His perfect age.

Amen.
"""
        ),
        "o_jesus_living_in_mary": ConsecrationPrayer(
            id: "o_jesus_living_in_mary",
            title: "O Jesus Living in Mary",
            latinTitle: nil,
            content: """
O Jesus living in Mary,
Come and live in Thy servants,
In the spirit of Thy holiness,
In the fullness of Thy might,
In the truth of Thy virtues,
In the perfection of Thy ways,
In the communion of Thy mysteries;
Subdue every hostile power
In Thy spirit, for the glory of the Father.

Amen.
"""
        ),
        "act_of_consecration": ConsecrationPrayer(
            id: "act_of_consecration",
            title: "Act of Consecration",
            latinTitle: nil,
            content: "[Prayer content placeholder]"
        ),
        "rosary": ConsecrationPrayer(
            id: "rosary",
            title: "The Holy Rosary",
            latinTitle: "Sanctissimum Rosarium",
            content: """
Pray at least five decades of the Rosary, meditating on the mysteries appropriate for today.

[Use the Rosary tab to pray a full Rosary with guided meditations]
"""
        )
    ]

    /// Get prayers for a specific phase
    static func prayers(for phase: ConsecrationPhase) -> [ConsecrationPrayer] {
        phase.prayerIds.compactMap { allPrayers[$0] }
    }

    /// Get a specific prayer by ID
    static func prayer(_ id: String) -> ConsecrationPrayer? {
        allPrayers[id]
    }

    /// Get prayers for a phase with language preference applied
    static func prayers(for phase: ConsecrationPhase, language: PrayerLanguage) -> [ConsecrationPrayer] {
        let bilingualPrayers = BilingualConsecrationPrayers.allPrayers()

        return phase.prayerIds.compactMap { id in
            // Try to get bilingual version first
            if let bilingualPrayer = bilingualPrayers[id] {
                return bilingualPrayer.toConsecrationPrayer(for: language)
            }
            // Fall back to original prayer (for lit anies and others not yet converted)
            return allPrayers[id]
        }
    }

    // MARK: - Days

    /// All 34 days of the consecration
    static let days: [ConsecrationDay] = buildAllDays()

    /// Get a specific day by number (1-34)
    static func day(_ number: Int) -> ConsecrationDay? {
        guard number >= 1, number <= days.count else { return nil }
        return days[number - 1]
    }

    /// Get the phase for a given day number
    static func phase(for dayNumber: Int) -> ConsecrationPhase? {
        ConsecrationPhase.phase(for: dayNumber)
    }

    // MARK: - Private Helpers

    private static func buildAllDays() -> [ConsecrationDay] {
        var allDays: [ConsecrationDay] = []

        // MARK: Preparatory Period (Days 1-12)

        // Day 1
        allDays.append(ConsecrationDay(
            dayNumber: 1,
            phase: .preparatory,
            title: "The Spirit of the World",
            meditationTitle: "Matthew 5:1-19",
            meditationText: """
And seeing the multitudes, he went up into a mountain, and when he was set down, his disciples came unto him. And opening his mouth, he taught them, saying: Blessed are the poor in spirit: for theirs is the kingdom of heaven. Blessed are the meek: for they shall possess the land. Blessed are they that mourn: for they shall be comforted. Blessed are they that hunger and thirst after justice: for they shall have their fill. Blessed are the merciful: for they shall obtain mercy. Blessed are the clean of heart: for they shall see God. Blessed are the peacemakers: for they shall be called children of God. Blessed are they that suffer persecution for justice' sake: for theirs is the kingdom of heaven. Blessed are ye when they shall revile you, and persecute you, and speak all that is evil against you, untruly, for my sake: Be glad and rejoice, for your reward is very great in heaven. For so they persecuted the prophets that were before you.

You are the salt of the earth. But if the salt lose its savour, wherewith shall it be salted? It is good for nothing any more but to be cast out, and to be trodden on by men. You are the light of the world. A city seated on a mountain cannot be hid. Neither do men light a candle and put it under a bushel, but upon a candlestick, that it may shine to all that are in the house. So let your light shine before men, that they may see your good works, and glorify your Father who is in heaven. Do not think that I am come to destroy the law, or the prophets. I am not come to destroy, but to fulfill. For amen I say unto you, till heaven and earth pass, one jot, or one tittle shall not pass of the law, till all be fulfilled. He therefore that shall break one of these least commandments, and shall so teach men, shall be called the least in the kingdom of heaven. But he that shall do and teach, he shall be called great in the kingdom of heaven.

─────

Examine your conscience, pray, practice renouncement of your own will; mortification, purity of heart. This purity is the indispensable condition for contemplating God in heaven, to see Him on earth and to know Him by the light of faith. The first part of the preparation should be employed in casting off the spirit of the world which is contrary to that of Jesus Christ.

The spirit of the world consists essentially in the denial of the supreme dominion of God; a denial which is manifested in practice by sin and disobedience; thus it is principally opposed to the spirit of Christ, which is also that of Mary.

It manifests itself by the concupiscence of the flesh, by the concupiscence of the eyes and by the pride of life. By disobedience to God's laws and the abuse of created things. Its works are: sin in all forms, then all else by which the devil leads to sin; works which bring error and darkness to the mind, and seduction and corruption to the will. Its pomps are the splendor and the charms employed by the devil to render sin alluring in persons, places and things.
""",
            meditationSource: "Douay-Rheims Bible",
            journalPrompt: "What worldly attachments or attitudes do you need to release to follow Christ more fully?"
        ))

        // Day 2
        allDays.append(ConsecrationDay(
            dayNumber: 2,
            phase: .preparatory,
            title: "Seeking God's Approval",
            meditationTitle: "Matthew 5:48, 6:1-15",
            meditationText: """
Be you therefore perfect, as also your heavenly Father is perfect.

Take heed that you do not your justice before men, to be seen by them: otherwise you shall not have a reward of your Father who is in heaven. Therefore when thou dost an almsdeed, sound not a trumpet before thee, as the hypocrites do in the synagogues and in the streets, that they may be honoured by men. Amen I say to you, they have received their reward. But when thou dost alms, let not thy left hand know what thy right hand doth. That thy alms may be in secret, and thy Father who seeth in secret will repay thee.

And when ye pray, you shall not be as the hypocrites, that love to stand and pray in the synagogues and corners of the streets, that they may be seen by men: Amen I say to you, they have received their reward. But thou when thou shalt pray, enter into thy chamber, and having shut the door, pray to thy Father in secret: and thy Father who seeth in secret will repay thee.

And when you are praying, speak not much, as the heathens. For they think that in their much speaking they may be heard. Be not you therefore like to them, for your Father knoweth what is needful for you, before you ask him.

Thus therefore shall you pray: Our Father who art in heaven, hallowed be thy name. Thy kingdom come. Thy will be done on earth as it is in heaven. Give us this day our supersubstantial bread. And forgive us our debts, as we also forgive our debtors. And lead us not into temptation. But deliver us from evil. Amen.

For if you will forgive men their offences, your heavenly Father will forgive you also your offences. But if you will not forgive men, neither will your Father forgive you your offences.
""",
            meditationSource: "Douay-Rheims Bible",
            journalPrompt: "Do you seek God's approval or the approval of others? How can you practice charity and prayer in secret?"
        ))

        // Day 3
        allDays.append(ConsecrationDay(
            dayNumber: 3,
            phase: .preparatory,
            title: "The Narrow Path",
            meditationTitle: "Matthew 7:1-14",
            meditationText: """
Judge not, that you may not be judged, For with what judgment you judge, you shall be judged: and with what measure you mete, it shall be measured to you again. Any why seest thou the mote that is in thy brother's eye; and seest not the beam that is in thy own eye? Or how sayest thou to thy brother: Let me cast the mote out of thy eye; and behold a beam is in thy own eye? Thou hypocrite, cast out first the beam in thy own eye, and then shalt thou see to cast out the mote out of thy brother's eye.

Give not that which is holy to dogs; neither cast ye your pearls before swine, lest perhaps they trample them under their feet, and turning upon you, they tear you.

Ask, and it shall be given you: seek, and you shall find: knock, and it shall be opened to you. For every one that asketh, receiveth: and he that seeketh, findeth: and to him that knocketh, it shall be opened. Or what man is there among you, of whom if his son shall ask bread, will he reach him a stone? Or if he shall ask him a fish, will he reach him a serpent? If you then being evil, know how to give good gifts to your children: how much more will your Father who is in heaven, give good things to them that ask him?

All things therefore whatsoever you would that men should do to you, do you also to them. For this is the law and the prophets.

Enter ye in at the narrow gate: for wide is the gate, and broad is the way that leadeth to destruction, and many there are who go in thereat. How narrow is the gate, and strait is the way that leadeth to life: and few there are that find it!
""",
            meditationSource: "Douay-Rheims Bible",
            journalPrompt: "How is Christ calling you to enter through the narrow gate? What must you leave behind?"
        ))

        // Day 4
        allDays.append(ConsecrationDay(
            dayNumber: 4,
            phase: .preparatory,
            title: "Our Nothingness Before God",
            meditationTitle: "Imitation of Christ, Book 3, Chapters 7 & 40",
            meditationText: """
That man has no good of himself, and that he cannot glory in anything.

Lord, what is man, that Thou art mindful of him; or the son of man, that Thou visit him? What has man deserved that Thou should give him grace? Lord, what cause have I to complain, if Thou forsakest me, or what can I justly allege, if what I petition Thou shalt not grant? This most assuredly, I may truly think and say: Lord I am nothing, I can do nothing of myself, that is good, but I am in all things defective and ever tend to nothing. And unless I am assisted and interiorly instructed by Thee, I become wholly tepid and relaxed, but Thou, O Lord, art always the same, and endurest unto eternity, ever good, just and holy, doing all things well, justly and holily and disposing them in wisdom.

But I who am more inclined to go back, than to go forward, continue not always in one state, for I am changed, seven different times. But it quickly becomes better when it pleases Thee, and Thou stretchest out Thy helping hand: for Thou alone, without man's aid can assist me and so strengthen me, that my countenance shall be more diversely changed: but my heart be converted and find its rest in Thee alone.

He who would be too secure in time of peace will often be found too much dejected in time of war. If you could always continue to be humble and little in your own eyes, and keep your spirit in due order and subjection, you would not fall so easily into danger and offense. It is good counsel that, when you have conceived the spirit of fervor, you should meditate how it will be when that light shall be withdrawn.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "In what ways do you rely on yourself rather than God's grace? How does recognizing your nothingness lead to greater trust in God?"
        ))

        // Day 5
        allDays.append(ConsecrationDay(
            dayNumber: 5,
            phase: .preparatory,
            title: "Rejecting Vainglory",
            meditationTitle: "Imitation of Christ, Book 3, Chapter 40",
            meditationText: """
Wherefore, but I did know well, how to cast from me all human comfort, either for the sake of devotion, or through the necessity by which I am compelled to seek Thee, because there is no man that can comfort me. Then might I deservedly hope in Thy favor, and rejoice in the gift of a new consolation.

Thanks be to Thee from Whom all things proceed, as often as it happens to me. I, indeed, am but vanity, and nothing in Thy sight, an inconstant and weak man. Where, therefore, can I glory, or for what do I desire to be thought of highly?

Forsooth of my very nothingness; and this is most vain. Truly vainglory is an evil plague, because it draws away from true glory, and robs us of heavenly grace. For, while a man takes complacency in himself, he displeases Thee; while he wants for human applause, he is deprived of true virtues.

But true glory and holy exultation is to glory in Thee, and not in one's self; to rejoice in Thy Name, but not in one's own strength. To find pleasure in no creature, save only for Thy sake.

Let Thy Name be praised, not mine; let Thy work be magnified, not mine; let Thy Holy Name be blessed, but let nothing be attributed to me of the praise of men. Thou art my glory; Thou art the exultation of my heart; in Thee, will I glory and rejoice all the day; but for myself, I will glory in nothing but in my infirmities.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "Where do you seek human approval rather than God's glory? How can you redirect your desire for praise toward glorifying God?"
        ))

        // Day 6
        allDays.append(ConsecrationDay(
            dayNumber: 6,
            phase: .preparatory,
            title: "The Example of the Holy Fathers",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 18",
            meditationText: """
On the examples of the Holy Fathers.

Look upon the lively examples of the holy Fathers in whom shone real perfection and the religious life, and you will see how little it is, and almost nothing that we do. Alas, what is our life when we compare it with theirs? Saints and friends of Christ, they served our Lord in hunger and in thirst, in cold, in nakedness, in labor and in weariness, in watching, in fasting, prayers and holy meditations, and in frequent persecutions and reproaches.

Oh, how many grievous tribulations did the Apostles suffer and the Martyrs and Confessors and Virgins, and all the rest who resolved to follow the steps of Christ! For they hated their lives in this world, that they might keep them in life everlasting.

Oh what a strict and self-renouncing life the holy Fathers of the desert led! What long and grievous temptations did they bear! How often were they harassed by the enemy, what frequent and fervent prayers did they offer up to God, what rigorous abstinence did they practice!

What a valiant contest waged they to subdue their imperfections! What purity and straightforwardness of purpose kept they towards God! By day they labored, and much of the night they spent in prayer; though while they labored, they were far from leaving off mental prayer. They spent all their time profitably. Every hour seemed short to spend with God; and even their necessary bodily refreshment was forgotten in the great sweetness of contemplation.

They renounced all riches, dignities, honors and kindred; they hardly took what was necessary for life. It grieved them to serve the body even in its necessity. Accordingly, they were poor in earthly things, but very rich in grace and virtues.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "What sacrifices are you called to make for Christ? How does the example of the saints inspire you?"
        ))

        // Day 7
        allDays.append(ConsecrationDay(
            dayNumber: 7,
            phase: .preparatory,
            title: "Spiritual Lukewarmness",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 18 (cont.)",
            meditationText: """
Outwardly they suffered want, but within they were refreshed with grace and Divine consolation. They were aliens to the world; they seemed as nothing and the world despised them; but they were precious and beloved in the sight of God. They persevered in true humility, they lived in simple obedience, they walked in charity and patience, and so every day they advanced in spirit and gained great favor with God.

They were given for example to all religious, and ought more to excite us to advance in good, than the number of lukewarm to induce us to grow remiss.

Oh! how great was the fervor of all religious in the beginning of their holy institute! Oh, how great was their devotion in prayer, how great was their zeal for virtue! How vigorous the discipline that was kept up, what reverence and obedience, under the rule of the superior, flourished in all!

Their traces that remain still bear witness, that they were truly holy and perfect men who did battle so stoutly, and trampled the world under their feet. Now, he is thought great who is not a transgressor; and who can, with patience, endure what he has undertaken.

Ah, the lukewarmness and negligence of our state! that we soon fall away from our first fervor, and are even now tired with life, from slothfulness and tepidity. Oh that advancement in virtue be not quite asleep in thee, who has so often seen the manifold examples of the devout!
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "Where has your spiritual fervor grown cold? How can you rekindle the fire of your first devotion?"
        ))

        // Days 8-12 - placeholders for now
        let preparatoryData: [(title: String, prompt: String)] = [
            ("Resisting Temptation", "What temptations do you struggle with most?"),
            ("Beginnings of Temptation", "How can you resist temptation at its first appearance?"),
            ("Despising the World", "What worldly pleasures hold you back from serving God?"),
            ("Amendment of Life", "What concrete steps can you take to grow in virtue today?"),
            ("Keeping Christ Crucified Before You", "How does meditation on Christ's passion strengthen you?")
        ]

        for i in 8...12 {
            let data = preparatoryData[i - 8]
            allDays.append(ConsecrationDay(
                dayNumber: i,
                phase: .preparatory,
                title: data.title,
                meditationTitle: "Meditation for Day \(i)",
                meditationText: "[Meditation content to be added]",
                meditationSource: "Preparatory Period",
                journalPrompt: data.prompt
            ))
        }

        // MARK: Week 1 - Knowledge of Self (Days 13-19)
        let week1Titles = [
            "Knowledge of Self",
            "The Misery of Sin",
            "Our Nothingness",
            "Humility",
            "Self-Knowledge",
            "Our Weakness",
            "Trust in God Alone"
        ]

        for i in 13...19 {
            let index = i - 13
            allDays.append(ConsecrationDay(
                dayNumber: i,
                phase: .knowledgeOfSelf,
                title: week1Titles[index],
                meditationTitle: "Meditation for Day \(i)",
                meditationText: "[Meditation content placeholder for Day \(i)]",
                meditationSource: "Week One",
                journalPrompt: "How does today's reading help you understand yourself better?"
            ))
        }

        // MARK: Week 2 - Knowledge of Mary (Days 20-26)
        let week2Titles = [
            "Knowledge of the Blessed Virgin",
            "Mary's Role in Salvation",
            "Mary's Virtues",
            "Mary as Mother",
            "Mary's Intercession",
            "Devotion to Mary",
            "True Devotion"
        ]

        for i in 20...26 {
            let index = i - 20
            allDays.append(ConsecrationDay(
                dayNumber: i,
                phase: .knowledgeOfMary,
                title: week2Titles[index],
                meditationTitle: "Meditation for Day \(i)",
                meditationText: "[Meditation content placeholder for Day \(i)]",
                meditationSource: "Week Two",
                journalPrompt: "What has today's meditation revealed about the Blessed Virgin?"
            ))
        }

        // MARK: Week 3 - Knowledge of Jesus (Days 27-33)
        let week3Titles = [
            "Knowledge of Jesus Christ",
            "Jesus Our Redeemer",
            "Jesus Our King",
            "Jesus Our Friend",
            "Living in Jesus",
            "Union with Christ",
            "Preparation for Consecration"
        ]

        for i in 27...33 {
            let index = i - 27
            allDays.append(ConsecrationDay(
                dayNumber: i,
                phase: .knowledgeOfJesus,
                title: week3Titles[index],
                meditationTitle: "Meditation for Day \(i)",
                meditationText: "[Meditation content placeholder for Day \(i)]",
                meditationSource: "Week Three",
                journalPrompt: "How is Christ calling you to deeper union with Him?"
            ))
        }

        // MARK: Consecration Day (Day 34)
        allDays.append(ConsecrationDay(
            dayNumber: 34,
            phase: .consecrationDay,
            title: "Total Consecration",
            meditationTitle: "The Act of Consecration",
            meditationText: "[Consecration Day content placeholder]",
            meditationSource: nil,
            journalPrompt: "Record your thoughts and feelings on this day of consecration."
        ))

        return allDays
    }
}
