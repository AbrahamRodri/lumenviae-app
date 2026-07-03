//
//  ConsecrationData.swift
//  Lumen Viae
//
//  All prayers and day definitions for the 33-Day Total Consecration
//  to Jesus through Mary (St. Louis de Montfort).
//
//  Content follows the traditional 33-day plan of readings from Sacred
//  Scripture (Douay-Rheims), The Imitation of Christ, and the writings of
//  St. Louis de Montfort (True Devotion to the Blessed Virgin Mary,
//  The Secret of Mary).
//

import Foundation

// MARK: - ConsecrationData

/// Static data source for the 33-Day Consecration.
enum ConsecrationData {

    // MARK: - Prayers

    /// All prayers used throughout the consecration, keyed by ID
    static let allPrayers: [String: ConsecrationPrayer] = [
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
            content: """
O Eternal and incarnate Wisdom! O sweetest and most adorable Jesus! True God and true man, only Son of the Eternal Father, and of Mary, always virgin! I adore Thee profoundly in the bosom and splendors of Thy Father during eternity; and I adore Thee also in the virginal bosom of Mary, Thy most worthy Mother, in the time of Thine incarnation.

I give Thee thanks for that Thou hast annihilated Thyself, taking the form of a slave in order to rescue me from the cruel slavery of the devil. I praise and glorify Thee for that Thou hast been pleased to submit Thyself to Mary, Thy holy Mother, in all things, in order to make me Thy faithful slave through her. But, alas! Ungrateful and faithless as I have been, I have not kept the promises which I made so solemnly to Thee in my Baptism; I have not fulfilled my obligations; I do not deserve to be called Thy child, nor yet Thy slave; and as there is nothing in me which does not merit Thine anger and Thy repulse, I dare not come by myself before Thy most holy and august Majesty. It is on this account that I have recourse to the intercession of Thy most holy Mother, whom Thou hast given me for a mediatrix with Thee. It is through her that I hope to obtain of Thee contrition, the pardon of my sins, and the acquisition and preservation of wisdom.

Hail, then, O immaculate Mary, living tabernacle of the Divinity, where the Eternal Wisdom willed to be hidden and to be adored by angels and by men! Hail, O Queen of Heaven and earth, to whose empire everything is subject which is under God. Hail, O sure refuge of sinners, whose mercy fails no one. Hear the desires which I have of the Divine Wisdom; and for that end receive the vows and offerings which in my lowliness I present to thee.

I, a faithless sinner, renew and ratify today in thy hands the vows of my Baptism; I renounce forever Satan, his pomps and works; and I give myself entirely to Jesus Christ, the Incarnate Wisdom, to carry my cross after Him all the days of my life, and to be more faithful to Him than I have ever been before. In the presence of all the heavenly court I choose thee this day for my Mother and Mistress. I deliver and consecrate to thee, as thy slave, my body and soul, my goods, both interior and exterior, and even the value of all my good actions, past, present and future; leaving to thee the entire and full right of disposing of me, and all that belongs to me, without exception, according to thy good pleasure, for the greater glory of God in time and in eternity.

Receive, O benignant Virgin, this little offering of my slavery, in honor of, and in union with, that subjection which the Eternal Wisdom deigned to have to thy maternity; in homage to the power which both of you have over this poor sinner, and in thanksgiving for the privileges with which the Holy Trinity has favored thee. I declare that I wish henceforth, as thy true slave, to seek thy honor and to obey thee in all things.

O admirable Mother, present me to thy dear Son as His eternal slave, so that as He has redeemed me by thee, by thee He may receive me! O Mother of mercy, grant me the grace to obtain the true Wisdom of God; and for that end receive me among those whom thou lovest and teachest, whom thou leadest, nourishest and protectest as thy children and thy slaves.

O faithful Virgin, make me in all things so perfect a disciple, imitator and slave of the Incarnate Wisdom, Jesus Christ thy Son, that I may attain, by thine intercession and by thine example, to the fullness of His age on earth and of His glory in Heaven.

Amen.
"""
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

        // Day 8
        allDays.append(ConsecrationDay(
            dayNumber: 8,
            phase: .preparatory,
            title: "Resisting Temptation",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 13",
            meditationText: """
Of Resisting Temptations.

As long as we live in this world, we cannot be without temptations and tribulations. Hence it is written in Job "Man's life on earth is a temptation." Everyone therefore should be solicitous about his temptations and watch in prayer lest the devil find an opportunity to catch him: who never sleeps, but goes about, seeking whom he can devour.

No one is so perfect and holy as sometimes not to have temptations and we can never be wholly free from them. Nevertheless, temptations are very profitable to man, troublesome and grievous though they may be, for in them, a man is humbled, purified and instructed. All the Saints passed through many tribulations and temptations and were purified by them. And they that could not support temptations, became reprobate, and fell away.

Many seek to flee temptations, and fall worse into them. We cannot conquer by flight alone, but by patience and true humility we become stronger than all our enemies. He who only declines them outwardly, and does not pluck out their root, will profit little; nay, temptations will sooner return and he will find himself in a worse condition.

By degrees and by patience you will, by God's grace, better overcome them than by harshness and your own importunity. Take counsel the oftener in temptation, and do not deal harshly with one who is tempted; but pour in consolation, as thou wouldst wish to be done unto yourself.

Inconstancy of mind and little confidence in God, is the beginning of all temptations. For as a ship without a helm is driven to and fro by the waves, so the man who neglects and gives up his resolutions is tempted in many ways.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "What temptations do you struggle with most? How might patience and humility, rather than flight, help you overcome them?"
        ))

        // Day 9
        allDays.append(ConsecrationDay(
            dayNumber: 9,
            phase: .preparatory,
            title: "Beginnings of Temptation",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 13 (cont.)",
            meditationText: """
Fire tries iron, and temptation a just man. We often know not what we are able to do, but temptations discover what we are. Still, we must watch, especially in the beginning of temptation; for then the enemy is more easily overcome, if he be not suffered to enter the door of the mind, but is withstood upon the threshold the very moment he knocks.

Whence a certain one has said "Resist beginnings; all too late the cure." When ills have gathered strength, by long delay, first there comes from the mind a simple thought; then a strong imagination, afterwards delight, and the evil motion and consent and so, little by little the fiend does gain entrance, when he is not resisted in the beginning. The longer anyone has been slothful in resisting, so much the weaker he becomes, daily in himself, and the enemy, so much the stronger in him.

Some suffer grievous temptations in the beginning of their conversion, others in the end and others are troubled nearly their whole life. Some are very lightly tempted, according to the wisdom and the equity of the ordinance of God who weighs man's condition and merits, and pre-ordaineth all things for the salvation of His elect.

We must not, therefore, despair when we are tempted, but the more fervently pray to God to help us in every tribulation: Who, of a truth, according to the sayings of St. Paul, will make such issue with the temptation, that we are able to sustain it.

Let us then humble our souls under the hand of God in every temptation and tribulation, for the humble in spirit, He will save and exalt. In temptation and tribulations, it is proved what progress man has made; and there also is great merit, and virtue is made more manifest.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "How can you resist temptation at its first appearance, before it gains strength in your mind?"
        ))

        // Day 10
        allDays.append(ConsecrationDay(
            dayNumber: 10,
            phase: .preparatory,
            title: "Despising the World",
            meditationTitle: "Imitation of Christ, Book 3, Chapter 10",
            meditationText: """
That it is sweet to despise the world and to serve God.

Now, will I speak again, O Lord, and will not be silent, I will say in the hearing of my God and my King Who is on high: Oh, how great is the abundance of Thy sweetness, O Lord, which Thou hast hidden for those that fear Thee! But what art Thou, for those who love Thee? What, to those who serve Thee with their whole heart? Unspeakable indeed is the sweetness of Thy contemplation, which Thou bestowest on those who love Thee.

In this most of all hast Thou showed me the sweetness of Thy love, that when I had no being, Thou didst make me; and when I was straying far from Thee, Thou brought me back again, that I might serve Thee: and Thou hast commanded me to serve Thee.

O Fountain of everlasting love, what shall I say of Thee? How can I forget Thee, Who hast vouchsafed to remember me even after I was corrupted and lost? Beyond all hope Thou showest mercy to Thy servant; and beyond all desert, hast Thou manifested Thy grace and friendship.

What return shall I make to Thee for this favor? Is it much that I should serve Thee, Whom the whole creation is bound to serve? It ought not to seem much to me to serve Thee; but this does rather appear great and wonderful to me, that Thou vouchsafest to receive one so wretched and unworthy as Thy servant.

It is a great honor, a great glory, to serve Thee, and to despise all things for Thee, for they who willingly subject themselves to Thy holy service, shall have great grace. They shall experience the most sweet consolation of the Holy Spirit, Who for the love of Thee, have cast aside all carnal delight.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "What worldly pleasures hold you back from serving God? What sweetness have you tasted in His service?"
        ))

        // Day 11
        allDays.append(ConsecrationDay(
            dayNumber: 11,
            phase: .preparatory,
            title: "Amendment of Life",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 25",
            meditationText: """
On the Fervent Amendment of our Whole Life.

When a certain anxious person, who often times wavered between hope and fear, once overcome with sadness, threw himself upon the ground in prayer, before one of the altars in the Church and thinking these things in his mind, said "Oh, if I only knew how to persevere," that very instant he heard within him, this heavenly answer: "And if thou didst know this, what would thou do? Do now what you would do, and thou shall be perfectly secure."

And immediately being consoled, and comforted, he committed himself to the Divine Will, and his anxious thoughts ceased. He no longer wished for curious things; searching to find out what would happen to him, but studied rather to learn what was the acceptable and perfect will of God for the beginning and the perfection of every good work.

"Hope in the Lord," said the Prophet, "And do all good, and inhabit the land, and thou shall be fed of the riches thereof."

There is one thing that keeps many back from spiritual progress, and from fervor in amendment namely: the labor that is necessary for the struggle. And assuredly they especially advance beyond others in virtues, who strive the most manfully to overcome the very things which are the hardest and most contrary to them. For there a man does profit more and merit more abundant grace, when he does most to overcome himself and mortify his spirit.

All have not, indeed, equal difficulties to overcome and mortify, but a diligent and zealous person will make a greater progress though he have more passions than another, who is well regulated but less fervent in the pursuit of virtues.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "What concrete steps can you take to grow in virtue today? What is hardest for you to overcome?"
        ))

        // Day 12
        allDays.append(ConsecrationDay(
            dayNumber: 12,
            phase: .preparatory,
            title: "Keeping Christ Crucified Before You",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 25 (cont.)",
            meditationText: """
But if thou observest any thing worthy of reproof, beware thou do not the same. And if at any time thou hast done it, labor quickly to amend thyself. As thine eye observeth others, so art thou by others noted again.

How sweet and pleasant a thing it is, to see brethren fervent and devout, obedient and well-disciplined! How sad and grievous a thing it is, to see them walk disorderly, not applying themselves to that for which they are called! How hurtful a thing it is, when they neglect the purpose of their calling and busy themselves in things not committed to their care!

Be mindful of the purpose thou hast embraced, and set always before thee the image of the Crucified. Good cause thou hast to be ashamed in looking upon the life of Jesus Christ, seeing thou hast not as yet endeavored to conform thyself more unto Him, though thou hast been a long time in the way of God.

A religious person that exercizeth himself seriously and devoutly in the most holy life and passion of our Lord, shall there abundantly find whatsoever is profitable and necessary for him, neither shall he need to seek any better thing, besides Jesus. O if Jesus crucified would come into our hearts, how quickly and fully should we be taught!

It is harder toil to resist vices and passions, than to sweat in bodily labors. He that avoideth not small faults, by little and little falleth into greater. Thou wilt always rejoice in the evening, if thou spend the day profitably. Be watchful over thyself, stir up thyself, warn thyself, and whatsoever becometh of others, neglect not thyself. The more violent thou uses against thyself, the more shalt thou progress. Amen.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "How does meditation on Christ's passion strengthen you? What small faults need your watchfulness today?"
        ))

        // MARK: Week 1 - Knowledge of Self (Days 13-19)

        // Day 13
        allDays.append(ConsecrationDay(
            dayNumber: 13,
            phase: .knowledgeOfSelf,
            title: "Knowledge of Self",
            meditationTitle: "Theme for the Week & Luke 11:1-10",
            meditationText: """
Theme for the Week: Knowledge of Self.

Prayers, examinations, reflection, acts of renouncement of our own will, of contrition for our sins, of contempt of self, all performed at the feet of Mary, for it is from her that we hope for light to know ourselves. It is near her, that we shall be able to measure the abyss of our miseries without despairing.

We should employ all our pious actions in asking for a knowledge of ourselves and contrition of our sins: and we should do this in a spirit of piety. During this period, we shall consider not so much the opposition that exists between the spirit of Jesus and ours, as the miserable and humiliating state to which our sins have reduced us. Moreover, the True Devotion being an easy, short, sure and perfect way to arrive at that union with Our Lord which is Christlike perfection, we shall enter seriously upon this way, strongly convinced of our misery and helplessness. But how attain this without a knowledge of ourselves?

─────

And it came to pass, that as he was in a certain place praying, when he ceased, one of his disciples said to him: Lord, teach us to pray, as John also taught his disciples. And he said to them: When you pray, say: Father, hallowed be thy name. Thy kingdom come. Give us this day our daily bread. And forgive us our sins, for we also forgive every one that is indebted to us. And lead us not into temptation.

And he said to them: Which of you shall have a friend, and shall go to him at midnight, and shall say to him: Friend, lend me three loaves, Because a friend of mine is come off his journey to me, and I have not what to set before him. And he from within should answer, and say: Trouble me not, the door is now shut, and my children are with me in bed; I cannot rise and give thee. Yet if he shall continue knocking, I say to you, although he will not rise and give him, because he is his friend; yet, because of his importunity, he will rise, and give him as many as he needeth.

And I say to you, Ask, and it shall be given you: seek, and you shall find: knock, and it shall be opened to you. For every one that asketh, receiveth; and he that seeketh, findeth; and to him that knocketh, it shall be opened.
""",
            meditationSource: "Luke 11:1-10, Douay-Rheims Bible",
            journalPrompt: "Ask Our Lady for the grace of self-knowledge. What miseries and weaknesses is God inviting you to see honestly, without despair?"
        ))

        // Day 14
        allDays.append(ConsecrationDay(
            dayNumber: 14,
            phase: .knowledgeOfSelf,
            title: "Humble Subjection",
            meditationTitle: "Imitation of Christ, Book 3, Chapter 13",
            meditationText: """
Of the Obedience of One in Humble Subjection, After the Example of Jesus Christ.

My son, he that endeavoreth to withdraw himself from obedience, withdraweth himself from grace; and he who seeketh for himself private benefit, loseth those which are common. He that doth not cheerfully and freely submit himself to his superior, it is a sign that his flesh is not as yet perfectly obedient unto him, but oftentimes kicketh and murmureth against him.

Learn thou therefore quickly to submit thyself to thy superior, if thou desire to keep thine own flesh under the yoke. For more speedily is the outward enemy overcome, if the inward man be not laid waste. There is no worse nor more troublesome enemy to the soul than thou art unto thyself, if thou be not well in harmony with the Spirit.

It is altogether necessary that thou take up a true contempt for thyself, if thou desire to prevail against flesh and blood. Because as yet thou lovest thyself too inordinately, therefore thou art afraid to resign thyself wholly to the will of others. And yet, what great matter is it, if thou, who art but dust and nothing, subject thyself to a man for God's sake, when I, the Almighty and the Most Highest who created all things of nothing, humbly subjected Myself to man for thy sake?

I became of all men the most humble and the most abject, that thou mightest overcome thy pride with My humility. O dust! learn to be obedient. Learn to humble thyself, thou earth and clay, and to bow thyself down under the feet of all men. Learn to break thine own wishes, and to yield thyself to all subjection.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "Where does your self-will resist obedience? How does Christ's humility challenge your pride?"
        ))

        // Day 15
        allDays.append(ConsecrationDay(
            dayNumber: 15,
            phase: .knowledgeOfSelf,
            title: "Dying to Self",
            meditationTitle: "Luke 13:1-5 & True Devotion, Nos. 81-82",
            meditationText: """
And there were present, at that very time, some that told him of the Galileans, whose blood Pilate had mingled with their sacrifices. And he answering, said to them: Think you that these Galileans were sinners above all the men of Galilee, because they suffered such things? No, I say to you: but unless you shall do penance, you shall all likewise perish. Or those eighteen upon whom the tower fell in Siloe, and slew them: think you, that they also were debtors above all the men that dwelt in Jerusalem? No, I say to you; but except you do penance, you shall all likewise perish.

─────

We Need Mary in order to Die to Ourselves.

Secondly, in order to empty ourselves of self, we must die daily to ourselves. This involves our renouncing what the powers of the soul and the senses of the body incline us to do. We must see as if we did not see, hear as if we did not hear and use the things of this world as if we did not use them. This is what St. Paul calls "dying daily". Unless the grain of wheat falls to the ground and dies, it remains only a single grain and does not bear any good fruit.

If we do not die to self and if our holiest devotions do not lead us to this necessary and fruitful death, we shall not bear fruit of any worth and our devotions will cease to be profitable. All our good works will be tainted by self-love and self-will so that our greatest sacrifices and our best actions will be unacceptable to God. Consequently when we come to die we shall find ourselves devoid of virtue and merit and discover that we do not possess even one spark of that pure love which God shares only with those who have died to themselves and whose life is hidden with Jesus Christ in him.

Thirdly, we must choose among all the devotions to the Blessed Virgin the one which will lead us more surely to this dying to self. This devotion will be the best and the most sanctifying for us.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "What would 'dying daily' to self-love and self-will look like in your life this week?"
        ))

        // Day 16
        allDays.append(ConsecrationDay(
            dayNumber: 16,
            phase: .knowledgeOfSelf,
            title: "The Grace of Self-Knowledge",
            meditationTitle: "True Devotion, No. 228 & Imitation, Book 2, Chapter 5",
            meditationText: """
Preparatory Exercises.

During the first week they should offer up all their prayers and acts of devotion to acquire knowledge of themselves and sorrow for their sins. Let them perform all their actions in a spirit of humility. Or else they may meditate on the following three considerations of St. Bernard: "Remember what you were - corrupted seed; what you are - a body destined for decay; what you will be - food for worms."

They will ask our Lord and the Holy Spirit to enlighten them saying, "Lord, that I may see," or "Lord, let me know myself," or the "Come, Holy Spirit". They will turn to our Blessed Lady and beg her to obtain for them that great grace which is the foundation of all others, the grace of self-knowledge.

─────

Of Self-consideration.

We cannot trust over much to ourselves, because grace oftentimes is wanting to us, and understanding also. Little light is there in us, and this we quickly lose by our negligence. Oftentimes too we perceive not our inward blindness how great it is. Oftentimes we do evil, and excuse it worse. We are sometimes moved with passion, and we think it zeal. We reprehend small things in others, and pass over our own greater matters. Quickly enough we feel and weigh what we suffer at the hands of others; but we mind not how much others suffer from us. He that well and rightly considereth his own works, will find little cause to judge hardly of another.
""",
            meditationSource: "St. Louis de Montfort & Thomas à Kempis",
            journalPrompt: "Pray 'Lord, let me know myself.' Where do you excuse in yourself what you condemn in others?"
        ))

        // Day 17
        allDays.append(ConsecrationDay(
            dayNumber: 17,
            phase: .knowledgeOfSelf,
            title: "Rendering an Account",
            meditationTitle: "Of Judgment & Luke 16:1-8",
            meditationText: """
Of Judgment, and the Punishment of Sinners.

In all things look to the end; and how thou wilt stand before that strict Judge to whom nothing is hid, who is not appeased with gifts, nor admitteth excuses, but will judge according to right. O wretched and foolish sinner, who sometimes art in terror at the countenance of an angry man, what answer wilt thou make to God who knoweth all thy wickedness! Why dost thou not provide for thyself against the day of judgement, when no man can be excused or defended by another, but every one shall be a sufficient burden for himself!

─────

The Crafty Steward.

And he said also to his disciples: There was a certain rich man who had a steward: and the same was accused unto him, that he had wasted his goods. And he called him, and said to him: How is it that I hear this of thee? give an account of thy stewardship: for now thou canst be steward no longer. And the steward said within himself: What shall I do, because my lord taketh away from me the stewardship? To dig I am not able; to beg I am ashamed. I know what I will do, that when I shall be removed from the stewardship, they may receive me into their houses.

Therefore calling together every one of his lord's debtors, he said to the first: How much dost thou owe my lord? But he said: An hundred barrels of oil. And he said to him: Take thy bill and sit down quickly, and write fifty. Then he said to another: And how much dost thou owe? Who said: An hundred quarters of wheat. He said to him: Take thy bill, and write eighty. And the lord commended the unjust steward, forasmuch as he had done wisely: for the children of this world are wiser in their generation than the children of light.
""",
            meditationSource: "Luke 16:1-8, Douay-Rheims Bible",
            journalPrompt: "If you had to render an account of your stewardship today, what would you want to set right?"
        ))

        // Day 18
        allDays.append(ConsecrationDay(
            dayNumber: 18,
            phase: .knowledgeOfSelf,
            title: "Unprofitable Servants",
            meditationTitle: "Luke 17:1-10 & Imitation, Book 3, Chapter 47",
            meditationText: """
And he said to his disciples: It is impossible that scandals should not come: but woe to him through whom they come. It were better for him, that a millstone were hanged about his neck, and he cast into the sea, than that he should scandalize one of these little ones.

Take heed to yourselves. If thy brother sin against thee, reprove him: and if he do penance, forgive him. And if he sin against thee seven times in a day, and seven times in a day be converted unto thee, saying, I repent; forgive him.

And the apostles said to the Lord: Increase our faith. And the Lord said: If you had faith like to a grain of mustard seed, you might say to this mulberry tree, Be thou rooted up, and be thou transplanted into the sea: and it would obey you.

But which of you having a servant ploughing, or feeding cattle, will say to him, when he is come from the field: Immediately go, sit down to meat: And will not rather say to him: Make ready my supper, and gird thyself, and serve me, whilst I eat and drink, and afterwards thou shalt eat and drink? Doth he thank that servant, for doing the things which he commanded him? I think not. So you also, when you shall have done all these things that are commanded you, say: We are unprofitable servants; we have done that which we ought to do.

─────

That All Grievous Things Are to Be Endured For the Sake of Eternal Life.

My son, be not wearied out by the labors which thou hast undertaken for My sake, nor let tribulation cast thee down ever at all; but let My promise strengthen and comfort thee under every circumstance. I am well able to reward thee, above all measure and degree. Thou shalt not long toil here, nor always be oppressed with griefs. Wait a little while, and thou shalt see a speedy end of thine evils.
""",
            meditationSource: "Luke 17:1-10, Douay-Rheims Bible & Thomas à Kempis",
            journalPrompt: "Do you serve God expecting recognition, or as an 'unprofitable servant' who serves out of love?"
        ))

        // Day 19
        allDays.append(ConsecrationDay(
            dayNumber: 19,
            phase: .knowledgeOfSelf,
            title: "Receiving the Kingdom as a Child",
            meditationTitle: "Luke 18:15-30",
            meditationText: """
And they brought unto him also infants, that he might touch them. Which when the disciples saw, they rebuked them. But Jesus, calling them together, said: Suffer children to come to me, and forbid them not: for of such is the kingdom of God. Amen, I say to you: Whosoever shall not receive the kingdom of God as a child, shall not enter into it.

And a certain ruler asked him, saying: Good master, what shall I do to possess everlasting life? And Jesus said to him: Why dost thou call me good? None is good but God alone. Thou knowest the commandments: Thou shalt not kill: Thou shalt not commit adultery: Thou shalt not steal: Thou shalt not bear false witness: Honour thy father and mother. Who said: All these things have I kept from my youth. Which when Jesus had heard, he said to him: Yet one thing is wanting to thee: sell all whatever thou hast, and give to the poor, and thou shalt have treasure in heaven: and come, follow me. He having heard these things, became sorrowful; for he was very rich.

And Jesus seeing him become sorrowful, said: How hardly shall they that have riches enter into the kingdom of God. For it is easier for a camel to pass through the eye of a needle, than for a rich man to enter into the kingdom of God. And they that heard it, said: Who then can be saved? He said to them: The things that are impossible with men, are possible with God.

Then Peter said: Behold, we have left all things, and have followed thee. Who said to them: Amen, I say to you, there is no man that hath left house, or parents, or brethren, or wife, or children, for the kingdom of God's sake, Who shall not receive much more in this present time, and in the world to come life everlasting.
""",
            meditationSource: "Douay-Rheims Bible",
            journalPrompt: "What is the 'one thing wanting' that Jesus asks of you? What riches are hard for you to surrender?"
        ))

        // MARK: Week 2 - Knowledge of Mary (Days 20-26)

        // Day 20
        allDays.append(ConsecrationDay(
            dayNumber: 20,
            phase: .knowledgeOfMary,
            title: "Knowledge of the Blessed Virgin",
            meditationTitle: "Theme for the Week & Luke 2:16-21, 45-52",
            meditationText: """
Theme for the Week: Knowledge of the Blessed Virgin.

Acts of love, pious affection for the Blessed Virgin, imitation of her virtues, especially her profound humility, her lively faith, her blind obedience, her continual mental prayer, her mortification in all things, her surpassing purity, her ardent charity, her heroic patience, her angelic sweetness, and her divine wisdom: "these being," as St. Louis de Montfort says, "the ten principal virtues of the Blessed Virgin."

We must unite ourselves to Jesus through Mary — this is the characteristic of our devotion; therefore, St. Louis de Montfort asks that we employ ourselves in acquiring a knowledge of the Blessed Virgin.

Mary is our sovereign and our mediatrix, our Mother and our Mistress. Let us then endeavor to know the effects of this royalty, of this mediation, and of this maternity, as well as the grandeurs and prerogatives which are the foundation or consequences thereof. Our Mother is also a perfect mold wherein we are to be molded in order to make her intentions and dispositions ours. This we cannot achieve without studying the interior life of Mary; namely, her virtues, her sentiments, her actions, her participation in the mysteries of Christ and her union with Him.

─────

And they came with haste; and they found Mary and Joseph, and the infant lying in the manger. And seeing, they understood of the word that had been spoken to them concerning this child. And all that heard, wondered; and at those things that were told them by the shepherds. But Mary kept all these words, pondering them in her heart.

...And it came to pass, that, after three days, they found him in the temple, sitting in the midst of the doctors, hearing them, and asking them questions. And seeing him, they wondered. And his mother said to him: Son, why hast thou done so to us? behold thy father and I have sought thee sorrowing. And he said to them: How is it that you sought me? did you not know, that I must be about my father's business? And he went down with them, and came to Nazareth, and was subject to them. And his mother kept all these words in her heart. And Jesus advanced in wisdom, and age, and grace with God and men.
""",
            meditationSource: "Luke 2, Douay-Rheims Bible",
            journalPrompt: "Mary 'kept all these words, pondering them in her heart.' Which of her ten principal virtues do you most need to imitate?"
        ))

        // Day 21
        allDays.append(ConsecrationDay(
            dayNumber: 21,
            phase: .knowledgeOfMary,
            title: "True Devotion to Our Lady",
            meditationTitle: "The Secret of Mary, Nos. 23-24",
            meditationText: """
True Devotion to Our Blessed Lady.

If we would go up to God, and be united with Him, we must use the same means He used to come down to us to be made Man and to impart His graces to us. This means is a true devotion to our Blessed Lady.

There are several true devotions to our Lady: here I do not speak of those which are false. The first consists in fulfilling our Christian duties, avoiding mortal sin, acting more out of love than with fear, praying to our Lady now and then, honoring her as the Mother of God, yet without having any special devotion to her.

The second consists in entertaining for our Lady more perfect feelings of esteem and love, of confidence and veneration. It leads us to join the Confraternities of the Holy Rosary and of the Scapular, to recite the five or the fifteen decades of the Holy Rosary, to honor Mary's images and altars, to publish her praises and to enroll ourselves in her sodalities. This devotion is good, holy and praiseworthy if we keep ourselves free from sin. But it is not so perfect as the next, nor so efficient in severing our soul from creatures, in detaching ourselves in order to be united with Jesus Christ.

The third devotion to our Lady, known and practiced by very few persons, is this I am about to disclose to you, predestinate soul. It consists in giving one's self entirely and as a slave to Mary, and to Jesus through Mary, and after that, to do all that we do, through Mary, with Mary, in Mary and for Mary.

We should choose a special feast day on which we give, consecrate and sacrifice to Mary voluntarily, lovingly and without constraint, entirely and without reserve: our body and soul, our exterior property such as house, family and income, and also our interior and spiritual possessions: namely, our merits, graces, virtues, and satisfactions.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "What would it mean for you to give yourself entirely to Jesus through Mary — holding nothing back?"
        ))

        // Day 22
        allDays.append(ConsecrationDay(
            dayNumber: 22,
            phase: .knowledgeOfMary,
            title: "Marks of True Devotion",
            meditationTitle: "True Devotion, Nos. 106-110",
            meditationText: """
Marks of authentic devotion to our Lady.

First, true devotion to our Lady is interior, that is, it comes from within the mind and the heart and follows from the esteem in which we hold her, the high regard we have for her greatness, and the love we bear her.

Second, it is trustful, that is to say, it fills us with confidence in the Blessed Virgin, the confidence that a child has for its loving Mother. It prompts us to go to her in every need of body and soul with great simplicity, trust and affection.

Third, true devotion to our Lady is holy, that is, it leads us to avoid sin and to imitate the virtues of Mary. Her ten principal virtues are: deep humility, lively faith, blind obedience, unceasing prayer, constant self-denial, surpassing purity, ardent love, heroic patience, angelic kindness, and heavenly wisdom.

Fourth, true devotion to our Lady is constant. It strengthens us in our desire to do good and prevents us from giving up our devotional practices too easily. It gives us the courage to oppose the fashions and maxims of the world, the vexations and unruly inclinations of the flesh and the temptations of the devil. Thus a person truly devoted to our Blessed Lady is not changeable, fretful, scrupulous or timid.

Fifth, true devotion to Mary is disinterested. It inspires us to seek God alone in his Blessed Mother and not ourselves. The true subject of Mary does not serve his illustrious Queen for selfish gain. He does not serve her for temporal or eternal well-being but simply and solely because she has the right to be served and God alone in her.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "Is your devotion interior, trustful, holy, constant, and disinterested? Which mark needs the most growth?"
        ))

        // Day 23
        allDays.append(ConsecrationDay(
            dayNumber: 23,
            phase: .knowledgeOfMary,
            title: "The Perfect Consecration",
            meditationTitle: "True Devotion, Nos. 120-121",
            meditationText: """
Nature of perfect devotion to the Blessed Virgin, or perfect consecration to Jesus Christ.

As all perfection consists in our being conformed, united and consecrated to Jesus, it naturally follows that the most perfect of all devotions is that which conforms, unites, and consecrates us most completely to Jesus. Now of all God's creatures Mary is the most conformed to Jesus. It therefore follows that, of all devotions, devotion to her makes for the most effective consecration and conformity to him. The more one is consecrated to Mary, the more one is consecrated to Jesus. That is why perfect consecration to Jesus is but a perfect and complete consecration of oneself to the Blessed Virgin, which is the devotion I teach; or in other words, it is the perfect renewal of the vows and promises of holy baptism.

This devotion consists in giving oneself entirely to Mary in order to belong entirely to Jesus through her. It requires us to give:

(1) Our body with its senses and members;
(2) Our soul with its faculties;
(3) Our present material possessions and all we shall acquire in the future;
(4) Our interior and spiritual possessions, that is, our merits, virtues and good actions of the past, the present and the future.

In other words, we give her all that we possess both in our natural life and in our spiritual life as well as everything we shall acquire in the future in the order of nature, of grace, and of glory in heaven. This we do without any reservation, not even of a penny, a hair, or the smallest good deed. And we give for all eternity without claiming or expecting, in return for our offering and our service, any other reward than the honour of belonging to our Lord through Mary and in Mary, even though our Mother were not — as in fact she always is — the most generous and appreciative of all God's creatures.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "This consecration is a perfect renewal of your baptismal promises. What does belonging entirely to Jesus through Mary ask of you?"
        ))

        // Day 24
        allDays.append(ConsecrationDay(
            dayNumber: 24,
            phase: .knowledgeOfMary,
            title: "A Smooth, Short, Perfect and Sure Way",
            meditationTitle: "True Devotion, Nos. 152-164",
            meditationText: """
This devotion is a smooth, short, perfect and sure way of attaining union with our Lord, in which Christian perfection consists.

(a) This devotion is a smooth way. It is the path which Jesus Christ opened up in coming to us and in which there is no obstruction to prevent us reaching him. It is quite true that we can attain to divine union by other roads, but these involve many more crosses and exceptional setbacks and many difficulties that we cannot easily overcome.

(b) This devotion is a short way to discover Jesus, either because it is a road we do not wander from, or because we walk along this road with greater ease and joy, and consequently with greater speed. We advance more in a brief period of submission to Mary and dependence on her than in whole years of self-will and self-reliance.

(c) This devotion is a perfect way to reach our Lord and be united to him, for Mary is the most perfect and the most holy of all creatures, and Jesus, who came to us in a perfect manner, chose no other road for his great and wonderful journey. The Most High, the Incomprehensible One, the Inaccessible One, He who is, deigned to come down to us poor earthly creatures who are nothing at all. How was this done? The Most High God came down to us in a perfect way through the humble Virgin Mary, without losing anything of his divinity or holiness. It is likewise through Mary that we poor creatures must ascend to almighty God in a perfect manner without having anything to fear.

(d) This devotion to our Lady is a sure way to go to Jesus and to acquire holiness through union with him. The devotion which I teach is not new. Indeed it could not be condemned without overthrowing the foundations of Christianity. It is obvious then that this devotion is not new. If it is not commonly practised, the reason is that it is too sublime to be appreciated and undertaken by everyone. This devotion is a safe means of going to Jesus Christ, because it is Mary's role to lead us safely to her Son.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "Where have years of self-will and self-reliance gotten you? What would submission to Mary's guidance change?"
        ))

        // Day 25
        allDays.append(ConsecrationDay(
            dayNumber: 25,
            phase: .knowledgeOfMary,
            title: "Wonderful Effects of This Devotion",
            meditationTitle: "True Devotion, Nos. 213-225",
            meditationText: """
My dear friend, be sure that if you remain faithful to the interior and exterior practices of this devotion which I will point out, the following effects will be produced in your soul:

1. Knowledge of our unworthiness. By the light which the Holy Spirit will give you through Mary, his faithful spouse, you will perceive the evil inclinations of your fallen nature and how incapable you are of any good. Finally, the humble Virgin Mary will share her humility with you so that, although you regard yourself with distaste and desire to be disregarded by others, you will not look down slightingly upon anyone.

2. A share in Mary's faith. Mary will share her faith with you. Her faith on earth was stronger than that of all the patriarchs, prophets, apostles and saints.

3. The gift of pure love. The Mother of fair love will rid your heart of all scruples and inordinate servile fear.

4. Great confidence in God and in Mary. Our Blessed Lady will fill you with unbounded confidence in God and in herself, because you will no longer approach Jesus by yourself but always through Mary, your loving Mother.

5. Communication of the spirit of Mary. The soul of Mary will be communicated to you to glorify the Lord. Her spirit will take the place of yours to rejoice in God, her Saviour, but only if you are faithful to the practices of this devotion.

6. Transformation into the likeness of Jesus. If Mary, the Tree of Life, is well cultivated in our soul by fidelity to this devotion, she will in due time bring forth her fruit which is none other than Jesus.

7. The greater glory of Christ. If you live this devotion sincerely, you will give more glory to Jesus in a month than in many years of a more demanding devotion.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "Which of these seven effects do you most long for? Ask Mary to share her faith and her spirit with you."
        ))

        // Day 26
        allDays.append(ConsecrationDay(
            dayNumber: 26,
            phase: .knowledgeOfMary,
            title: "Queen of Our Hearts",
            meditationTitle: "True Devotion, Nos. 12-38",
            meditationText: """
"If you wish to understand the Mother," says a saint, "then understand the Son. She is a worthy Mother of God." Hic taceat omnis lingua: Here let every tongue be silent.

My heart has dictated with special joy all that I have written to show that Mary has been unknown up till now, and that that is one of the reasons why Jesus Christ is not known as he should be. If then, as is certain, the knowledge and the kingdom of Jesus Christ must come into the world, it can only be as a necessary consequence of the knowledge and reign of Mary. She who first gave him to the world will establish his kingdom in the world.

With the whole Church I acknowledge that Mary, being a mere creature fashioned by the hands of God is, compared to his infinite majesty, less than an atom, or rather is simply nothing, since he alone can say, "I am he who is". Consequently, this great Lord, who is ever independent and self-sufficient, never had and does not now have any absolute need of the Blessed Virgin for the accomplishment of his will and the manifestation of his glory. To do all things he has only to will them. However, I declare that, considering things as they are, because God has decided to begin and accomplish his greatest works through the Blessed Virgin ever since he created her, we can safely believe that he will not change his plan in the time to come, for he is God and therefore does not change in his thoughts or his way of acting.

Mary is the Queen of heaven and earth by grace as Jesus is king by nature and by conquest. But as the kingdom of Jesus Christ exists primarily in the heart or interior of man, according to the words of the Gospel, "The kingdom of God is within you", so the kingdom of the Blessed Virgin is principally in the interior of man, that is, in his soul. It is principally in souls that she is glorified with her Son more than in any visible creature. So we may call her, as the saints do, Queen of our hearts.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "Is Mary truly Queen of your heart? What part of your interior life have you not yet given over to her Son?"
        ))

        // MARK: Week 3 - Knowledge of Jesus (Days 27-33)

        // Day 27
        allDays.append(ConsecrationDay(
            dayNumber: 27,
            phase: .knowledgeOfJesus,
            title: "Knowledge of Jesus Christ",
            meditationTitle: "Theme for the Week & True Devotion, Nos. 61-62",
            meditationText: """
Theme for the Week: Knowledge of Jesus Christ.

During this period we shall apply ourselves to the study of Jesus Christ. What is to be studied in Christ? First the God-Man, His grace and glory; then His rights to sovereign dominion over us; since, after having renounced Satan and the world, we have taken Jesus Christ for our Lord. What next shall be the object of our study? His exterior actions and also His interior life; namely, the virtues and acts of His Sacred Heart; His association with Mary in the mysteries of the Annunciation and Incarnation, during His infancy and hidden life, at the feast of Cana and on Calvary.

─────

Jesus, our Saviour, true God and true man must be the ultimate end of all our other devotions; otherwise they would be false and misleading. He is the Alpha and the Omega, the beginning and end of everything. "We labour," says St. Paul, "only to make all men perfect in Jesus Christ."

For in him alone dwells the entire fullness of the divinity and the complete fullness of grace, virtue and perfection. In him alone we have been blessed with every spiritual blessing; he is the only teacher from whom we must learn; the only Lord on whom we should depend; the only Head to whom we should be united and the only model that we should imitate. He is the only Physician that can heal us; the only Shepherd that can feed us; the only Way that can lead us; the only Truth that we can believe; the only Life that can animate us. He alone is everything to us and he alone can satisfy all our desires.

If then we are establishing sound devotion to our Blessed Lady, it is only in order to establish devotion to our Lord more perfectly, by providing a smooth but certain way of reaching Jesus Christ. If devotion to our Lady distracted us from our Lord, we would have to reject it as an illusion of the devil. But this is far from being the case. This devotion is necessary, simply and solely because it is a way of reaching Jesus perfectly, loving him tenderly, and serving him faithfully.
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "Jesus is the ultimate end of this consecration. Is He truly your only Teacher, Physician, Shepherd, Way, Truth, and Life?"
        ))

        // Day 28
        allDays.append(ConsecrationDay(
            dayNumber: 28,
            phase: .knowledgeOfJesus,
            title: "The Last Supper and the Agony",
            meditationTitle: "Matthew 26:1, 26-29, 36-46",
            meditationText: """
And it came to pass, when Jesus had ended all these words, he said to his disciples: You know that after two days shall be the pasch, and the son of man shall be delivered up to be crucified.

And whilst they were at supper, Jesus took bread, and blessed, and broke: and gave to his disciples, and said: Take ye, and eat. This is my body. And taking the chalice, he gave thanks, and gave to them, saying: Drink ye all of this. For this is my blood of the new testament, which shall be shed for many unto remission of sins. And I say to you, I will not drink from henceforth of this fruit of the vine, until that day when I shall drink it with you new in the kingdom of my Father.

Then Jesus came with them into a country place which is called Gethsemani; and he said to his disciples: Sit you here, till I go yonder and pray. And taking with him Peter and the two sons of Zebedee, he began to grow sorrowful and to be sad. Then he saith to them: My soul is sorrowful even unto death: stay you here, and watch with me. And going a little further, he fell upon his face, praying, and saying: My Father, if it be possible, let this chalice pass from me. Nevertheless not as I will, but as thou wilt.

And he cometh to his disciples, and findeth them asleep, and he saith to Peter: What? Could you not watch one hour with me? Watch ye, and pray that ye enter not into temptation. The spirit indeed is willing, but the flesh weak. Again the second time, he went and prayed, saying: My Father, if this chalice may not pass away, but I must drink it, thy will be done. And he cometh again and findeth them sleeping: for their eyes were heavy. And leaving them, he went again: and he prayed the third time, saying the selfsame word. Then he cometh to his disciples, and saith to them: Sleep ye now and take your rest; behold the hour is at hand, and the Son of man shall be betrayed into the hands of sinners. Rise, let us go: behold he is at hand that will betray me.
""",
            meditationSource: "Douay-Rheims Bible",
            journalPrompt: "'Not as I will, but as thou wilt.' Can you watch one hour with Christ? What chalice are you asking God to take away?"
        ))

        // Day 29
        allDays.append(ConsecrationDay(
            dayNumber: 29,
            phase: .knowledgeOfJesus,
            title: "The Imitation of Christ",
            meditationTitle: "Imitation of Christ, Book 1, Chapter 1",
            meditationText: """
Of the Imitation of Christ, and Contempt of all the Vanities of the World.

He that followeth Me, walketh not in darkness, saith the Lord. These are the words of Christ, by which we are admonished, how we ought to imitate His life and manners, if we would truly be enlightened, and delivered from all blindness of heart. Let therefore our chiefest endeavour be, to meditate upon the life of Jesus Christ.

The doctrine of Christ exceedeth all the doctrine of holy men; and he that hath the Spirit will find therein the hidden manna. But it falleth out that many who often hear the Gospel of Christ, feel little desire after it, because they have not the Spirit of Christ. But whosoever will fully and with relish understand the words of Christ, must endeavor to conform his life wholly to the life of Christ.

What doth it avail thee to discourse profoundly of the Trinity, if thou be void of humility, and art thereby displeasing to the Trinity? Surely profound words do not make a man holy and just; but a virtuous life maketh him dear to God. I had rather feel contrition, than know the definition thereof. If thou didst know the whole Bible by heart, and the sayings of all the philosophers, what would all that profit thee without the love of God, and without His grace?

Vanity of vanities, and all is vanity, except to love God, and to serve Him only. This is the highest wisdom, by contempt of the world to press forward towards heavenly kingdoms.
""",
            meditationSource: "Thomas à Kempis",
            journalPrompt: "'I had rather feel contrition, than know the definition thereof.' Does your knowledge of the faith translate into a life conformed to Christ?"
        ))

        // Day 30
        allDays.append(ConsecrationDay(
            dayNumber: 30,
            phase: .knowledgeOfJesus,
            title: "The Royal Road of the Holy Cross",
            meditationTitle: "Matthew 27:36-44 & Imitation, Book 2, Chapter 12",
            meditationText: """
And they sat and watched him. And they put over his head his cause written: THIS IS JESUS THE KING OF THE JEWS. Then were crucified with him two thieves: one on the right hand, and one on the left. And they that passed by, blasphemed him, wagging their heads, And saying: Vah, thou that destroyest the temple of God, and in three days dost rebuild it: save thy own self: if thou be the Son of God, come down from the cross. In like manner also the chief priests, with the scribes and ancients, mocking, said: He saved others; himself he cannot save. If he be the king of Israel, let him now come down from the cross, and we will believe him.

─────

Of the King's High Way of the Holy Cross.

Unto many this seemeth an hard saying, "Deny thyself, take up thy cross, and follow Jesus." But much harder will it be to hear that last word, "Depart from Me, ye cursed, into everlasting fire." For they who now willingly hear and follow the word of the Cross, shall not then fear to hear the sentence of everlasting damnation. This sign of the Cross shall be in the heaven, when the Lord shall come to judgment. Then all the servants of the Cross, who in their life-time conformed themselves unto Christ crucified, shall draw near unto Christ the Judge with great confidence.

Why therefore fearest thou to take up the Cross which leadeth thee to a kingdom? In the Cross is salvation, in the Cross is life, in the Cross is protection against our enemies, in the Cross is infusion of heavenly sweetness, in the Cross is strength of mind, in the Cross joy of spirit, in the Cross the height of virtue, in the Cross the perfection of holiness.

Take up therefore thy Cross and follow Jesus, and thou shalt go into life everlasting.
""",
            meditationSource: "Douay-Rheims Bible & Thomas à Kempis",
            journalPrompt: "What cross are you afraid to take up? How might embracing it lead you closer to Christ's kingdom?"
        ))

        // Day 31
        allDays.append(ConsecrationDay(
            dayNumber: 31,
            phase: .knowledgeOfJesus,
            title: "Jesus in the Blessed Sacrament",
            meditationTitle: "Imitation, Book 4, Chapter 2 & True Devotion, Nos. 243-254",
            meditationText: """
That the Great Goodness and Love of God Is Exhibited to Man in This Sacrament.

In confidence of Thy goodness and great mercy, O Lord, I draw near, sick to the Healer, hungry and thirsty to the Fountain of life, needy to the King of Heaven, a servant to his Lord, a creature to the Creator, desolate to my own tender Comforter. "But whence is this to me," that Thou comest unto me? What am I, that Thou shouldest grant me Thine own self? How dare a sinner appear before Thee?

And how is it that Thou dost vouchsafe to come unto a sinner? Thou knowest Thy servant, and art well aware that he hath in him no good thing, for which Thou shouldest grant him this. I confess therefore mine own vileness, I acknowledge Thy goodness, I praise Thy tender mercy, and give Thee thanks for Thy transcendent love.

─────

Loving slaves of Jesus in Mary should hold in high esteem devotion to Jesus, the Word of God, in the great mystery of the Incarnation, March 25th, which is the mystery proper to this devotion, because it was inspired by the Holy Spirit: (a) That we might honour and imitate the wondrous dependence which God the Son chose to have on Mary, for the glory of his Father and for the redemption of man. This dependence is revealed especially in this mystery where Jesus becomes a captive and slave in the womb of his Blessed Mother, depending on her for everything. (b) That we might thank God for the incomparable graces he has conferred upon Mary and especially that of choosing her to be his most worthy Mother.

Those who accept this devotion should have a great love for the Hail Mary, or, as it is called, the Angelic Salutation. Few Christians, however enlightened, understand the value, merit, excellence and necessity of the Hail Mary. Our Blessed Lady herself had to appear on several occasions to men of great holiness and insight, such as St. Dominic, St. John Capistran and Blessed Alan de Rupe, to convince them of the richness of this prayer.
""",
            meditationSource: "Thomas à Kempis & St. Louis de Montfort",
            journalPrompt: "Jesus made Himself dependent on Mary in the Incarnation. How does His humility in the Eucharist and the womb of Mary move you?"
        ))

        // Day 32
        allDays.append(ConsecrationDay(
            dayNumber: 32,
            phase: .knowledgeOfJesus,
            title: "The Love of Jesus Above All Things",
            meditationTitle: "Imitation, Book 2, Chapter 7 & True Devotion, Nos. 257-260",
            meditationText: """
Of the Love of Jesus above All Things.

Blessed is he that understandeth what it is to love Jesus, and to despise himself for Jesus' sake. Thou oughtest to leave thy beloved, for thy Beloved; for that Jesus will be loved alone above all things. The love of things created is deceitful and inconstant; the love of Jesus is faithful and persevering. He that cleaveth unto a creature, shall fall with that which is subject to fall; he that embraceth Jesus shall be made strong for ever.

Love Him, and keep Him for thy friend, who, when all go away, will not forsake thee, nor suffer thee to perish in the end. Some time or other thou must be separated from all, whether thou wilt or no. Keep close to Jesus both in life and in death, and commit thyself unto His faithfulness, who, when all fail, can alone help thee. Thy Beloved is of that nature, that He will admit of no rival; but will have thy heart alone, and sit on His throne as King. If thou couldest empty thyself perfectly from all creatures, Jesus would willingly dwell with thee.

─────

There are some very sanctifying interior practices for those souls who feel called by the Holy Spirit to a high degree of perfection. They may be expressed in four words: doing everything through Mary, with Mary, in Mary, and for Mary, in order to do it more perfectly through Jesus, with Jesus, in Jesus, and for Jesus.

Through Mary: we must obey her always and be led in all things by her spirit, which is the Holy Spirit of God. "Those who are led by the Spirit of God are children of God," says St. Paul. Those who are led by the spirit of Mary are children of Mary, and, consequently children of God.

With Mary: in all our actions we must look upon Mary, although a simple human being, as the perfect model of every virtue and perfection, fashioned by the Holy Spirit for us to imitate. In every action then we should consider how Mary performed it or how she would perform it if she were in our place.
""",
            meditationSource: "Thomas à Kempis & St. Louis de Montfort",
            journalPrompt: "Jesus 'will admit of no rival.' What creature-attachments compete with Him for your heart?"
        ))

        // Day 33
        allDays.append(ConsecrationDay(
            dayNumber: 33,
            phase: .knowledgeOfJesus,
            title: "In Mary and For Mary",
            meditationTitle: "Imitation, Book 4, Chapter 11 & True Devotion, Nos. 261-265",
            meditationText: """
O most sweet Lord Jesus, how great is the pleasure of the devout soul that feasteth with Thee in Thy banquet; where there is set for her no other food to be eaten but Thyself, her only Beloved, and most to be desired above all the desires of her heart! For in this Sacrament I have Thee mystically present, hidden under another shape. For to look upon Thee in Thine own Divine brightness, mine eyes would not be able to endure; nor could even the whole world stand in the splendor of the glory of Thy majesty. Herein then Thou hast regard to my weakness, that Thou dost hide Thyself under this Sacrament.

─────

In Mary: we must do everything in Mary. To understand this we must realise that the Blessed Virgin is the true earthly paradise of the new Adam and that the ancient paradise was only a symbol of her. There are in this earthly paradise untold riches, beauties, rarities and delights, which the new Adam, Jesus Christ, has left there. It is in this paradise that he "took his delights" for nine months, worked his wonders and displayed his riches with the magnificence of God himself. In this earthly paradise grows the real Tree of Life which bore our Lord, the fruit of Life. The Holy Spirit, speaking through the Fathers of the Church, also calls our Lady the Eastern Gate, through which the High Priest, Jesus Christ, enters and goes out into the world.

For Mary: finally, we must do everything for Mary. We take Mary for our proximate end, our mysterious intermediary and the easiest way of reaching Jesus. Relying on her protection, we should undertake and carry out great things for our noble Queen. We must defend her privileges when they are questioned and uphold her good name when it is under attack. We must attract everyone, if possible, to her service and to this true and sound devotion. As a reward for these little services, we should expect nothing in return save the honour of belonging to such a lovable Queen and the joy of being united through her to Jesus, her Son, by a bond that is indissoluble in time and in eternity.
""",
            meditationSource: "Thomas à Kempis & St. Louis de Montfort",
            journalPrompt: "Tomorrow you make your consecration. Are you ready to give everything — through Mary, with Mary, in Mary, and for Mary?"
        ))

        // MARK: Consecration Day (Day 34)
        allDays.append(ConsecrationDay(
            dayNumber: 34,
            phase: .consecrationDay,
            title: "Total Consecration",
            meditationTitle: "The Day of Consecration",
            meditationText: """
Today is the day of your Total Consecration to Jesus through Mary.

On the day of consecration, either fast, give alms, or offer a votive candle for the good of another (or all of the above); do some spiritual penance and approach consecration in the spirit of mortification.

Go to Confession (or, if that is not possible, go during the 8 days prior) and then receive Communion with the intention of giving yourself to Jesus, as a slave of love, by the hands of Mary.

Then pray the words of the consecration. Copy them and have them with you at church; read them after the Mass — in front of the tabernacle would be fitting — and sign your copy of the Act of Consecration.

─────

Living the Consecration.

Once you have consecrated yourself to Jesus through Mary, live that consecration. St. Louis de Montfort recommended the following:

• Keep praying to develop a "great contempt" for the spirit of this world.
• Maintain a special devotion to the Mystery of the Incarnation, through meditation, spiritual reading, and the Feasts of the Annunciation and the Nativity.
• Frequently recite the Hail Mary, the Rosary, and the Magnificat.
• Do everything through, with, in and for Mary for the sake of Jesus, with the prayer, "I am all thine, Immaculate One, with all that I have: in time and in eternity" in your heart and on your lips.
• Associate yourself with Mary in a special way before, during, and after Communion.
• Renew the consecration once a year on the same date, following the same 33-day period of exercises. If desired, also renew it monthly with the prayer, "I am all thine and all I have is thine, O dear Jesus, through Mary, Thy holy Mother."
""",
            meditationSource: "St. Louis de Montfort",
            journalPrompt: "Record your thoughts and feelings on this day of consecration. What are you giving to Jesus through Mary today?"
        ))

        return allDays
    }
}
