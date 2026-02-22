//
//  TrueDevotionData.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  TRUE DEVOTION TO MARY - KEY TEACHINGS AND PRINCIPLES
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Contains the key aspects, principles, and ejaculatory prayers from
//  St. Louis de Montfort's "True Devotion to Mary"
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - Models

struct DevotionSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let items: [DevotionItem]
}

struct DevotionItem: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

// MARK: - TrueDevotionData

enum TrueDevotionData {

    // MARK: - Key Principles

    static let keyPrinciples = DevotionSection(
        title: "Key Principles of True Devotion",
        icon: "book.closed.fill",
        items: [
            DevotionItem(
                title: "Perfect Consecration",
                content: """
True Devotion to Mary consists in giving oneself entirely to the Blessed Virgin in order to belong entirely to Jesus Christ through her. We must give her:

• Our body with all its senses and members
• Our soul with all its powers
• Our exterior goods (present and future)
• Our interior and spiritual goods (merits, virtues, and good works)

This is done without reserve, and forever.
"""
            ),
            DevotionItem(
                title: "Total Dependence on Mary",
                content: """
We should do all our actions through Mary, with Mary, in Mary, and for Mary, in order to do them more perfectly through Jesus, with Jesus, in Jesus, and for Jesus.

Through Mary: We employ her intercession and accept her as the Mediatrix between ourselves and Jesus.

With Mary: We unite ourselves to her as she offers herself to God.

In Mary: We enter into the interior dispositions with which she fulfills all her actions.

For Mary: We do all our actions out of love for Mary as our final end, after Jesus.
"""
            ),
            DevotionItem(
                title: "The Slavery of Love",
                content: """
St. Louis de Montfort calls this devotion a "slavery of love" - the voluntary giving of ourselves entirely to Mary, who is the Mother of God.

This slavery is:
• The most perfect way to give ourselves to Jesus Christ
• The surest way, since Mary will never mislead us
• The easiest way, because Mary carries our burdens
• The quickest way to union with Jesus
• The most perfect way to honor God through His Mother
"""
            ),
            DevotionItem(
                title: "Mary as the Mold of God",
                content: """
St. Louis de Montfort teaches that Mary is the "mold of God" - the perfect vessel in which Jesus was formed.

Just as Jesus was formed in Mary, so we too must be formed in Mary to become true images of Christ. Only in her can we be transformed into other Christs without danger of deception or pride.
"""
            ),
            DevotionItem(
                title: "Interior Practice",
                content: """
The interior practice consists in developing within ourselves a great devotion to the Blessed Virgin.

This includes:
• Esteeming her highly as the masterpiece of grace
• Rejoicing in her exaltation and privileges
• Loving her as our tender Mother
• Imitating her virtues
• Trusting in her power and goodness
• Having recourse to her in all our needs
• Seeking Jesus only through Mary
"""
            ),
            DevotionItem(
                title: "Exterior Practice",
                content: """
The exterior practice includes:
• Making the act of consecration (initially and renewed often)
• Wearing a small chain as a sign of slavery to Jesus through Mary
• Having special devotion to the Rosary and Magnificat
• Saying the Ave Maris Stella and other prayers to Mary
• Making everything we do an act of consecration
• Giving alms, fasting, and mortifying ourselves in Mary's honor
"""
            )
        ]
    )

    // MARK: - Marks of True Devotion

    static let marksOfTrueDevotion = DevotionSection(
        title: "Marks of True Devotion to Mary",
        icon: "checkmark.seal.fill",
        items: [
            DevotionItem(
                title: "Interior",
                content: """
True devotion to Mary is interior - it comes from the mind and the heart. It flows from:

• The esteem we have for her
• The high idea we have formed of her greatness
• The love which we have for her
"""
            ),
            DevotionItem(
                title: "Tender",
                content: """
True devotion to Mary is tender - it is full of confidence in her, like a child's confidence in a loving mother.

It makes us fly to her in all our bodily and spiritual needs with great simplicity, trust, and tenderness.
"""
            ),
            DevotionItem(
                title: "Holy",
                content: """
True devotion to Mary is holy - it leads us to avoid sin and to imitate her virtues, particularly:

• Her profound humility
• Her lively faith
• Her continual prayer
• Her universal mortification
• Her divine purity
• Her ardent charity
• Her heroic patience
• Her angelic sweetness
• Her divine wisdom
"""
            ),
            DevotionItem(
                title: "Constant",
                content: """
True devotion to Mary is constant - it strengthens us in good and does not let us easily abandon our spiritual exercises.

It makes us courageous in opposing the world, the flesh, and the devil. A true child of Mary is not inconstant or scrupulous.
"""
            ),
            DevotionItem(
                title: "Disinterested",
                content: """
True devotion to Mary is disinterested - it inspires us to seek God alone in Mary, and not ourselves.

The true subject of Mary does not serve her for temporal or eternal reward, but solely because she has a right to be served, and God alone in her.
"""
            )
        ]
    )

    // MARK: - Benefits of True Devotion

    static let benefits = DevotionSection(
        title: "Benefits of This Devotion",
        icon: "gift.fill",
        items: [
            DevotionItem(
                title: "Freedom from Scruples and Servile Fear",
                content: """
This devotion makes us free with the liberty of the children of God. Since we reduce ourselves to slavery out of love, God rewards us by:

• Filling us with holy freedom
• Delivering us from scruples
• Taking away servile fear that might contract our hearts
"""
            ),
            DevotionItem(
                title: "Great Confidence in God and Mary",
                content: """
By consecrating ourselves thus to Jesus through Mary, we give Him, in the person of His Mother, all our good works.

Mary:
• Purifies them
• Embellishes them
• Makes them acceptable to her Son
• Obtains for us great graces and blessings
"""
            ),
            DevotionItem(
                title: "A Perfect Renewal of Baptismal Promises",
                content: """
In this consecration we:
• Renounce Satan and the world
• Give ourselves entirely to Jesus Christ through Mary
• Fulfill our baptismal promises perfectly
"""
            ),
            DevotionItem(
                title: "Mary Defends Us Against Our Enemies",
                content: """
Consecrating ourselves to Mary means:
• She watches over us constantly
• She defends us against our enemies
• She protects us as her property
• She crushes the serpent's head in us
"""
            ),
            DevotionItem(
                title: "Greater Merit and Grace",
                content: """
All our actions, being done through Mary:
• Become her actions
• Are infinitely more meritorious
• Are more sanctifying
• Are more glorious to God
• Are more profitable to our neighbor
"""
            )
        ]
    )

    // MARK: - Ejaculatory Prayers (English)

    static let ejaculatoryPrayersEnglish = DevotionSection(
        title: "Ejaculatory Prayers (English)",
        icon: "flame.fill",
        items: [
            DevotionItem(
                title: "The Little Crown",
                content: """
V. Grant me to praise thee, O Sacred Virgin.
R. Give me strength against thine enemies.
"""
            ),
            DevotionItem(
                title: "Totus Tuus",
                content: """
I am all Yours, and all that I have is Yours, O most loving Jesus, through Mary, Your most holy Mother.
"""
            ),
            DevotionItem(
                title: "O Jesus Living in Mary",
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
            DevotionItem(
                title: "Short Aspiration",
                content: """
Mary, my Mother and my Queen, I am all thine, and all that I have is thine.
"""
            ),
            DevotionItem(
                title: "Morning Offering Through Mary",
                content: """
O Mary, I give thee my heart; form in it the heart of Jesus.
"""
            ),
            DevotionItem(
                title: "In Temptation",
                content: """
O Mary, conceived without sin, pray for us who have recourse to thee.

My Mother, my confidence!
"""
            ),
            DevotionItem(
                title: "Throughout the Day",
                content: """
All for thee, most Sacred Heart of Jesus, through the Immaculate Heart of Mary.

Jesus, Mary, Joseph, I love you; save souls!
"""
            ),
            DevotionItem(
                title: "The Memorare (St. Bernard)",
                content: """
Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided.
"""
            ),
            DevotionItem(
                title: "Before Holy Communion",
                content: """
O Mary, Mother of Jesus, make my heart like unto thine, that I may worthily receive thy Divine Son.
"""
            ),
            DevotionItem(
                title: "During the Rosary",
                content: """
Hail Mary, Daughter of God the Father; Hail Mary, Mother of God the Son; Hail Mary, Spouse of God the Holy Spirit; Hail Mary, Temple of the Most Blessed Trinity.
"""
            )
        ]
    )

    // MARK: - Ejaculatory Prayers (Latin)

    static let ejaculatoryPrayersLatin = DevotionSection(
        title: "Ejaculatory Prayers (Latin)",
        icon: "flame.fill",
        items: [
            DevotionItem(
                title: "The Little Crown",
                content: """
V. Dignare me laudare te, Virgo sacrata.
R. Da mihi virtutem contra hostes tuos.
"""
            ),
            DevotionItem(
                title: "Totus Tuus",
                content: """
Totus Tuus ego sum, et omnia mea Tua sunt, O amantissime Jesu, per Mariam, Matrem Tuam sanctissimam.
"""
            ),
            DevotionItem(
                title: "O Jesu Vivens in Maria",
                content: """
O Jesu vivens in Maria,
Veni et vive in famulis tuis,
In spiritu sanctitatis tuae,
In plenitudine virtutis tuae,
In veritate virtutum tuarum,
In perfectione viarum tuarum,
In communione mysteriorum tuorum;
Domina omnem adversam potestatem
In Spiritu tuo, ad gloriam Patris.
Amen.
"""
            ),
            DevotionItem(
                title: "Brevis Aspiratio",
                content: """
Maria, Mater mea et Regina mea, tota Tua sum, et omnia mea Tua sunt.
"""
            ),
            DevotionItem(
                title: "Oblatio Matutina per Mariam",
                content: """
O Maria, do tibi cor meum; forma in eo cor Jesu.
"""
            ),
            DevotionItem(
                title: "In Tentatione",
                content: """
O Maria, sine labe concepta, ora pro nobis qui confugimus ad te.

Mater mea, fiducia mea!
"""
            ),
            DevotionItem(
                title: "Per Diem",
                content: """
Omnia pro te, Cor Jesu sacratissimum, per Cor Mariae Immaculatum.

Jesu, Maria, Joseph, vos amo; salvate animas!
"""
            ),
            DevotionItem(
                title: "Memorare (S. Bernardi)",
                content: """
Memorare, O piissima Virgo Maria, non esse auditum a saeculo, quemquam ad tua currentem praesidia, tua implorantem auxilia, tua petentem suffragia, esse derelictum.
"""
            ),
            DevotionItem(
                title: "Ante Communionem",
                content: """
O Maria, Mater Jesu, fac cor meum simile Tuo, ut digne recipiam Filium Tuum divinum.
"""
            ),
            DevotionItem(
                title: "Durante Rosario",
                content: """
Ave Maria, Filia Dei Patris; Ave Maria, Mater Dei Filii; Ave Maria, Sponsa Spiritus Sancti; Ave Maria, Templum Sanctissimae Trinitatis.
"""
            )
        ]
    )

    // MARK: - Ejaculatory Prayers (Both)

    static let ejaculatoryPrayersBoth = DevotionSection(
        title: "Ejaculatory Prayers (Latin & English)",
        icon: "flame.fill",
        items: [
            DevotionItem(
                title: "The Little Crown",
                content: """
V. Dignare me laudare te, Virgo sacrata.|||V. Grant me to praise thee, O Sacred Virgin.
R. Da mihi virtutem contra hostes tuos.|||R. Give me strength against thine enemies.
"""
            ),
            DevotionItem(
                title: "Totus Tuus",
                content: """
Totus Tuus ego sum, et omnia mea Tua sunt, O amantissime Jesu, per Mariam, Matrem Tuam sanctissimam.|||I am all Yours, and all that I have is Yours, O most loving Jesus, through Mary, Your most holy Mother.
"""
            ),
            DevotionItem(
                title: "O Jesu Vivens in Maria",
                content: """
O Jesu vivens in Maria,|||O Jesus living in Mary,
Veni et vive in famulis tuis,|||Come and live in Thy servants,
In spiritu sanctitatis tuae,|||In the spirit of Thy holiness,
In plenitudine virtutis tuae,|||In the fullness of Thy might,
In veritate virtutum tuarum,|||In the truth of Thy virtues,
In perfectione viarum tuarum,|||In the perfection of Thy ways,
In communione mysteriorum tuorum;|||In the communion of Thy mysteries;
Domina omnem adversam potestatem|||Subdue every hostile power
In Spiritu tuo, ad gloriam Patris.|||In Thy spirit, for the glory of the Father.
Amen.|||Amen.
"""
            ),
            DevotionItem(
                title: "Short Aspiration",
                content: """
Maria, Mater mea et Regina mea, tota Tua sum, et omnia mea Tua sunt.|||Mary, my Mother and my Queen, I am all thine, and all that I have is thine.
"""
            ),
            DevotionItem(
                title: "Morning Offering Through Mary",
                content: """
O Maria, do tibi cor meum; forma in eo cor Jesu.|||O Mary, I give thee my heart; form in it the heart of Jesus.
"""
            ),
            DevotionItem(
                title: "In Temptation",
                content: """
O Maria, sine labe concepta, ora pro nobis qui confugimus ad te.|||O Mary, conceived without sin, pray for us who have recourse to thee.

Mater mea, fiducia mea!|||My Mother, my confidence!
"""
            ),
            DevotionItem(
                title: "Throughout the Day",
                content: """
Omnia pro te, Cor Jesu sacratissimum, per Cor Mariae Immaculatum.|||All for thee, most Sacred Heart of Jesus, through the Immaculate Heart of Mary.

Jesu, Maria, Joseph, vos amo; salvate animas!|||Jesus, Mary, Joseph, I love you; save souls!
"""
            ),
            DevotionItem(
                title: "The Memorare (St. Bernard)",
                content: """
Memorare, O piissima Virgo Maria, non esse auditum a saeculo, quemquam ad tua currentem praesidia, tua implorantem auxilia, tua petentem suffragia, esse derelictum.|||Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided.
"""
            ),
            DevotionItem(
                title: "Before Holy Communion",
                content: """
O Maria, Mater Jesu, fac cor meum simile Tuo, ut digne recipiam Filium Tuum divinum.|||O Mary, Mother of Jesus, make my heart like unto thine, that I may worthily receive thy Divine Son.
"""
            ),
            DevotionItem(
                title: "During the Rosary",
                content: """
Ave Maria, Filia Dei Patris; Ave Maria, Mater Dei Filii; Ave Maria, Sponsa Spiritus Sancti; Ave Maria, Templum Sanctissimae Trinitatis.|||Hail Mary, Daughter of God the Father; Hail Mary, Mother of God the Son; Hail Mary, Spouse of God the Holy Spirit; Hail Mary, Temple of the Most Blessed Trinity.
"""
            )
        ]
    )

    // MARK: - Ejaculatory Prayers (English & Latin)

    static let ejaculatoryPrayersLatinUnderEnglish = DevotionSection(
        title: "Ejaculatory Prayers (English & Latin)",
        icon: "flame.fill",
        items: [
            DevotionItem(
                title: "The Little Crown",
                content: """
V. Grant me to praise thee, O Sacred Virgin.
   Dignare me laudare te, Virgo sacrata.

R. Give me strength against thine enemies.
   Da mihi virtutem contra hostes tuos.
"""
            ),
            DevotionItem(
                title: "Totus Tuus",
                content: """
I am all Yours, and all that I have is Yours, O most loving Jesus, through Mary, Your most holy Mother.|||Totus Tuus ego sum, et omnia mea Tua sunt, O amantissime Jesu, per Mariam, Matrem Tuam sanctissimam.
"""
            ),
            DevotionItem(
                title: "O Jesus Living in Mary",
                content: """
O Jesus living in Mary,|||O Jesu vivens in Maria,
Come and live in Thy servants,|||Veni et vive in famulis tuis,
In the spirit of Thy holiness,|||In spiritu sanctitatis tuae,
In the fullness of Thy might,|||In plenitudine virtutis tuae,
In the truth of Thy virtues,|||In veritate virtutum tuarum,
In the perfection of Thy ways,|||In perfectione viarum tuarum,
In the communion of Thy mysteries;|||In communione mysteriorum tuorum;
Subdue every hostile power|||Domina omnem adversam potestatem
In Thy spirit, for the glory of the Father.|||In Spiritu tuo, ad gloriam Patris.
Amen.|||Amen.
"""
            ),
            DevotionItem(
                title: "Short Aspiration",
                content: """
Mary, my Mother and my Queen, I am all thine, and all that I have is thine.|||Maria, Mater mea et Regina mea, tota Tua sum, et omnia mea Tua sunt.
"""
            ),
            DevotionItem(
                title: "Morning Offering Through Mary",
                content: """
O Mary, I give thee my heart; form in it the heart of Jesus.|||O Maria, do tibi cor meum; forma in eo cor Jesu.
"""
            ),
            DevotionItem(
                title: "In Temptation",
                content: """
O Mary, conceived without sin, pray for us who have recourse to thee.|||O Maria, sine labe concepta, ora pro nobis qui confugimus ad te.

My Mother, my confidence!|||Mater mea, fiducia mea!
"""
            ),
            DevotionItem(
                title: "Throughout the Day",
                content: """
All for thee, most Sacred Heart of Jesus, through the Immaculate Heart of Mary.|||Omnia pro te, Cor Jesu sacratissimum, per Cor Mariae Immaculatum.

Jesus, Mary, Joseph, I love you; save souls!|||Jesu, Maria, Joseph, vos amo; salvate animas!
"""
            ),
            DevotionItem(
                title: "The Memorare (St. Bernard)",
                content: """
Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided.|||Memorare, O piissima Virgo Maria, non esse auditum a saeculo, quemquam ad tua currentem praesidia, tua implorantem auxilia, tua petentem suffragia, esse derelictum.
"""
            ),
            DevotionItem(
                title: "Before Holy Communion",
                content: """
O Mary, Mother of Jesus, make my heart like unto thine, that I may worthily receive thy Divine Son.|||O Maria, Mater Jesu, fac cor meum simile Tuo, ut digne recipiam Filium Tuum divinum.
"""
            ),
            DevotionItem(
                title: "During the Rosary",
                content: """
Hail Mary, Daughter of God the Father; Hail Mary, Mother of God the Son; Hail Mary, Spouse of God the Holy Spirit; Hail Mary, Temple of the Most Blessed Trinity.|||Ave Maria, Filia Dei Patris; Ave Maria, Mater Dei Filii; Ave Maria, Sponsa Spiritus Sancti; Ave Maria, Templum Sanctissimae Trinitatis.
"""
            )
        ]
    )

    // MARK: - The Spirit of This Devotion

    static let spirit = DevotionSection(
        title: "The Spirit of This Devotion",
        icon: "heart.fill",
        items: [
            DevotionItem(
                title: "Spirit of Humility",
                content: """
• We acknowledge our nothingness and sinfulness
• We rely entirely on Mary's intercession
• We seek to do all through Mary, not through our own merits
• We glory in our dependence on her as children
"""
            ),
            DevotionItem(
                title: "Spirit of Confidence",
                content: """
• We trust in Mary's maternal care
• We believe in her power as Mother of God
• We rely on her never-failing intercession
• We cast all our cares upon her
"""
            ),
            DevotionItem(
                title: "Spirit of Love",
                content: """
• We love Mary as our tender Mother
• We seek to please her in all things
• We imitate her virtues
• We rejoice in her glory and happiness
"""
            ),
            DevotionItem(
                title: "Spirit of Imitation",
                content: """
We seek to imitate Mary's:
• Interior life of union with God
• Purity of intention in all actions
• Perfect submission to God's will
• Profound humility and self-effacement
• Universal mortification and self-denial
"""
            )
        ]
    )

    // MARK: - All Sections

    /// Get all sections with the specified prayer language preference
    static func allSections(prayerLanguage: PrayerLanguage = .both) -> [DevotionSection] {
        let prayerSection: DevotionSection
        switch prayerLanguage {
        case .english:
            prayerSection = ejaculatoryPrayersEnglish
        case .latin:
            prayerSection = ejaculatoryPrayersLatin
        case .both:
            prayerSection = ejaculatoryPrayersBoth
        case .latinUnderEnglish:
            prayerSection = ejaculatoryPrayersLatinUnderEnglish
        }

        return [
            keyPrinciples,
            marksOfTrueDevotion,
            benefits,
            prayerSection,
            spirit
        ]
    }
}
