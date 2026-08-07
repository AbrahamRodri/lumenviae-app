//
//  TrueDevotionData.swift
//  Lumen Viae
//
//  Key aspects, principles, and ejaculatory prayers from
//  St. Louis de Montfort's "True Devotion to Mary".
//

import Foundation

// MARK: - Models

struct DevotionSection: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let items: [DevotionItem]

    init(id: UUID = UUID(), title: String, icon: String, items: [DevotionItem]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.items = items
    }
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
        icon: "ch-bible",
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
        icon: "ph-seal-check-fill",
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
        icon: "ph-sparkle",
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
All our actions, being done through Mary, gain in value, because she:
• Purifies them of self-love and hidden attachment
• Embellishes them, adorning them with her own merits
• Presents them to Jesus with her own hands
• Makes them more glorious to God
• Makes them more profitable to our neighbor
"""
            )
        ]
    )

    // MARK: - False Devotions to Avoid

    static let falseDevotions = DevotionSection(
        title: "False Devotions to Avoid",
        icon: "ph-shield",
        items: [
            DevotionItem(
                title: "The Critical Devotee",
                content: """
Proud scholars who question and criticize nearly every approved devotion to Our Lady — the pious practices of the simple faithful seem beneath them.

Montfort answers: the Church, guided by the Holy Spirit, has approved these devotions for centuries; humility receives what pride dissects.
"""
            ),
            DevotionItem(
                title: "The Scrupulous Devotee",
                content: """
Those who fear that honoring the Mother dishonors the Son — who avoid speaking of Mary lest they "take away" from Jesus.

In truth, we honor Mary only that Jesus may be more perfectly honored; we go to her only as the way that leads to Him, who is our final end.
"""
            ),
            DevotionItem(
                title: "The External Devotee",
                content: """
Those whose devotion consists entirely in outward practices — many rosaries hurried through, medals worn, processions joined — with no interior spirit, no effort to amend their lives.
"""
            ),
            DevotionItem(
                title: "The Presumptuous Devotee",
                content: """
Sinners who hide behind a cloak of devotion to Mary while remaining attached to their sins, presuming she will save them without conversion.

This presumption, Montfort warns, is a detestable abuse: true devotion to Mary is holy — it leads us away from sin, never provides cover for it.
"""
            ),
            DevotionItem(
                title: "The Inconstant Devotee",
                content: """
Those devout by fits and starts — fervent one month, lukewarm the next; taking up practices and abandoning them at the first dryness.

True devotion is constant: better a short rule kept faithfully than great practices soon abandoned.
"""
            ),
            DevotionItem(
                title: "The Hypocritical Devotee",
                content: """
Those who cloak their sins under the mantle of the Virgin so as to pass for what they are not in the eyes of others.
"""
            ),
            DevotionItem(
                title: "The Self-Interested Devotee",
                content: """
Those who have recourse to Mary only to win a lawsuit, escape a danger, be cured of an illness, or obtain some temporal good — and otherwise never think of her.

We may certainly bring her our needs, but true devotion serves her for God's sake, not merely for our own.
"""
            )
        ]
    )

    // MARK: - Foundations

    static let foundations = DevotionSection(
        title: "Foundations of the Devotion",
        icon: "ch-church",
        items: [
            DevotionItem(
                title: "It Begins and Ends with Jesus",
                content: """
"Jesus Christ our Saviour, true God and true man, must be the ultimate end of all our other devotions; otherwise they would be false and misleading."

Montfort opens True Devotion with this rule. Devotion to Mary is not a rival to devotion to Christ — it exists only to form Christ in us more perfectly. It was through Mary that Jesus came into the world, and it is through Mary that He wishes to reign in souls.
"""
            ),
            DevotionItem(
                title: "The Figure of Rebecca and Jacob",
                content: """
Montfort's great scriptural figure (Genesis 27): as Rebecca clothed her beloved son Jacob in the garments of his elder brother to obtain the father's blessing, so Mary clothes her children in the merits and virtues of her Son, that they may be blessed by the Father.

Those who give themselves to her are dressed, cared for, and presented by her hands — and the Father, finding in them the fragrance of His Son, blesses them.
"""
            ),
            DevotionItem(
                title: "Tested and Approved by the Church",
                content: """
Montfort wrote True Devotion around 1712 and foretold that it would be hidden by the devil — the manuscript lay unknown in a trunk until 1842, and was published in 1843.

Since then: St. Pius X granted an apostolic blessing to all who would read it; Pius XII canonized Montfort in 1947; and St. John Paul II took his papal motto, Totus Tuus, from Montfort's formula of consecration, calling the book "a decisive turning point" in his life.
"""
            )
        ]
    )

    // MARK: - The Spirit of This Devotion

    static let spirit = DevotionSection(
        title: "The Spirit of This Devotion",
        icon: "ch-sacred-heart",
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
        // Use the efficient bilingual prayer structure that generates format dynamically
        let prayerSection = TrueDevotionPrayers.prayers.toDevotionSection(for: prayerLanguage)

        return [
            foundations,
            keyPrinciples,
            marksOfTrueDevotion,
            falseDevotions,
            benefits,
            prayerSection,
            spirit
        ]
    }
}
