//
//  PrayerBookEucharist2.swift
//  Lumen Viae
//
//  More prayers of the Blessed Sacrament: before Mass, at Communion, in thanksgiving and at a visit.
//  Sources: The Roman Missal, Præparatio ad Missam and Gratiarum actio post Missam (Latin; English our own literal rendering)
//  The Ordinary of the Mass, Domine, non sum dignus (Latin; English after the Douay-Rheims, Matthew 8:8)
//  The Litany of the Most Blessed Sacrament, the traditional Latin text (English our own literal rendering)
//  Lucia dos Santos, Memórias, the Angel's prayer of 1916 (English our own literal rendering from the Portuguese)
//  St Alphonsus Liguori, Visits to the Most Holy Sacrament, ed. Eugene Grimm, C.SS.R. (Benziger, 1886)
//

import Foundation

extension PrayerBookTexts {

    static let eucharist2: [BookPrayer] = [
        BookPrayer(
            id: "st_ambrose_before_mass",
            title: "Prayer of St Ambrose before Mass",
            latinTitle: "Summe sacerdos et vere pontifex",
            origin: "Attributed to St Ambrose · the Roman Missal",
            note: "Said in preparation for Mass; the Missal divides the long prayer over the days of the week, and this is its first part.",
            english: """
O High Priest and true Pontiff, Who didst offer Thyself to God the Father, a pure and spotless victim, upon the altar of the cross for us miserable sinners; Who didst give us Thy flesh to eat and Thy blood to drink, and didst ordain this mystery in the power of the Holy Spirit, saying: As often as you do these things, you shall do them in memory of Me:

I beseech Thee by that same blood of Thine, the great price of our salvation; I beseech Thee by that wonderful and unspeakable love with which Thou didst vouchsafe so to love us, miserable and unworthy as we are, that Thou didst wash us from our sins in Thy blood:

teach me, Thine unworthy servant, whom, among Thy other gifts, Thou hast vouchsafed to call to the priestly office, by no merits of mine but by the sole condescension of Thy mercy; teach me, by Thy Holy Spirit, to handle so great a mystery with that reverence and honour, that devotion and fear, which are due and fitting. Amen.
""",
            latin: """
Summe Sacerdos et vere Pontifex, qui te obtulisti Deo Patri hostiam puram et immaculatam in ara crucis pro nobis miseris peccatoribus, et qui dedisti nobis carnem tuam ad manducandum et sanguinem tuum ad bibendum, et posuisti mysterium istud in virtute Spiritus Sancti, dicens: Haec quotiescumque feceritis, in mei memoriam facietis:

rogo per eumdem sanguinem tuum, magnum pretium salutis nostrae; rogo per istam mirabilem ineffabilemque caritatem, qua nos miseros et indignos sic amare dignatus es, ut lavares nos a peccatis nostris in sanguine tuo:

doce me indignum servum tuum, quem inter cetera dona tua ad officium sacerdotale, nullis meis meritis, sed sola dignatione misericordiae tuae vocare dignatus es; doce me, per Spiritum Sanctum tuum, tantum tractare mysterium ea reverentia et honore, ea devotione et timore, quo oportet et decet. Amen.
"""
        ),
        BookPrayer(
            id: "transfige",
            title: "Prayer of St Bonaventure after Mass",
            latinTitle: "Transfige, dulcissime Domine Iesu",
            origin: "St Bonaventure · 13th century",
            note: "Said in thanksgiving after Holy Communion; the Missal sets it among the prayers after Mass.",
            english: """
Pierce, O most sweet Lord Jesus, the inmost marrow of my soul with the most sweet and healing wound of Thy love, with true, serene and most holy apostolic charity, that my soul may ever languish and melt with love and longing for Thee alone; that it may yearn for Thee and faint for Thy courts, and long to be dissolved and to be with Thee.

Grant that my soul may hunger after Thee, the Bread of Angels, the refreshment of holy souls, our daily and supersubstantial bread, having all sweetness and savour and every delight of taste.

May my heart ever hunger after and feed upon Thee, upon Whom the angels desire to look, and may my inmost soul be filled with the sweetness of Thy savour; may it ever thirst for Thee, the fountain of life, the fountain of wisdom and knowledge, the fountain of eternal light, the torrent of pleasure, the fulness of the house of God;

may it ever seek Thee, ever find Thee, tend to Thee, come to Thee, meditate upon Thee, speak of Thee, and do all things to the praise and glory of Thy name, with humility and discretion, with love and delight, with readiness and affection, and with perseverance unto the end;

and be Thou alone ever my hope, my whole confidence, my riches, my delight, my pleasure, my joy, my rest and tranquillity, my peace, my sweetness, my fragrance, my sweet savour, my food, my refreshment, my refuge, my help, my wisdom, my portion, my possession and my treasure, in Whom may my mind and my heart be ever fixed and firm and rooted immovably. Amen.
""",
            latin: """
Transfige, dulcissime Domine Iesu, medullas et viscera animae meae suavissimo ac saluberrimo amoris tui vulnere, vera serenaque et apostolica sanctissima caritate, ut langueat et liquefiat anima mea solo semper amore et desiderio tui; te concupiscat et deficiat in atria tua, cupiat dissolvi et esse tecum.

Da ut anima mea te esuriat, panem Angelorum, refectionem animarum sanctarum, panem nostrum quotidianum, supersubstantialem, habentem omnem dulcedinem et saporem, et omne delectamentum suavitatis.

Te, in quem desiderant Angeli prospicere, semper esuriat et comedat cor meum, et dulcedine saporis tui repleantur viscera animae meae; te semper sitiat fontem vitae, fontem sapientiae et scientiae, fontem aeterni luminis, torrentem voluptatis, ubertatem domus Dei;

te semper ambiat, te quaerat, te inveniat, ad te tendat, ad te perveniat, te meditetur, te loquatur, et omnia operetur in laudem et gloriam nominis tui, cum humilitate et discretione, cum dilectione et delectatione, cum facilitate et affectu, cum perseverantia usque in finem;

ut tu sis solus semper spes mea, tota fiducia mea, divitiae meae, delectatio mea, iucunditas mea, gaudium meum, quies et tranquillitas mea, pax mea, suavitas mea, odor meus, dulcedo mea, cibus meus, refectio mea, refugium meum, auxilium meum, sapientia mea, portio mea, possessio mea, thesaurus meus, in quo fixa et firma et immobiliter semper sit radicata mens mea et cor meum. Amen.
"""
        ),
        BookPrayer(
            id: "angels_prayer_fatima",
            title: "The Angel's Prayer at Fatima",
            latinTitle: nil,
            origin: "The Angel of Peace at Fatima · 1916",
            note: "Taught by the Angel to the three children, who said it prostrate before the Host he held; said in adoration and reparation.",
            english: """
Most Holy Trinity, Father, Son and Holy Spirit, I adore Thee profoundly, and I offer Thee the most precious Body, Blood, Soul and Divinity of Jesus Christ, present in all the tabernacles of the earth, in reparation for the outrages, sacrileges and indifferences by which He Himself is offended. And by the infinite merits of His most Sacred Heart and of the Immaculate Heart of Mary, I beg of Thee the conversion of poor sinners.
""",
            latin: nil
        ),
        BookPrayer(
            id: "domine_non_sum_dignus",
            title: "Lord, I Am Not Worthy",
            latinTitle: "Domine, non sum dignus",
            origin: "The Mass · Matthew 8:8",
            note: "Said three times before Holy Communion, striking the breast, in the words of the centurion.",
            english: """
Lord, I am not worthy that Thou shouldst enter under my roof: say but the word, and my soul shall be healed.
""",
            latin: """
Domine, non sum dignus, ut intres sub tectum meum: sed tantum dic verbo, et sanabitur anima mea.
"""
        ),
        BookPrayer(
            id: "st_alphonsus_visit",
            title: "Prayer for a Visit to the Blessed Sacrament",
            latinTitle: nil,
            origin: "St Alphonsus Liguori · 1745",
            note: "Said at every visit to Jesus in the tabernacle, as St Alphonsus set it before each of his Visits.",
            english: """
My Lord Jesus Christ, Who, for the love which Thou bearest to men, remainest night and day in this Sacrament, full of compassion and of love, awaiting, calling and welcoming all who come to visit Thee: I believe that Thou art present in the Sacrament of the Altar. I adore Thee from the abyss of my nothingness, and I thank Thee for all the graces which Thou hast bestowed upon me, and in particular for having given me Thyself in this Sacrament, for having given me Thy most holy Mother Mary for my advocate, and for having called me to visit Thee in this church.

I now salute Thy most loving Heart, and this for three ends: first, in thanksgiving for this great gift; secondly, to make amends to Thee for all the outrages which Thou receivest in this Sacrament from all Thine enemies; thirdly, I intend by this visit to adore Thee in all the places on earth in which Thou art the least revered and the most abandoned.

My Jesus, I love Thee with my whole heart. I grieve for having hitherto so many times offended Thy infinite goodness. I purpose, by the help of Thy grace, never more to offend Thee; and at this moment, miserable as I am, I consecrate my whole being to Thee. I give Thee my entire will, all my affections and desires, and all that I have. From this day forward dispose of me and of all that belongs to me as it seems good to Thee. All that I ask of Thee and desire is Thy holy love, final perseverance, and the perfect accomplishment of Thy will.

I recommend to Thee the souls in purgatory, but especially those who had the greatest devotion to the most Blessed Sacrament and to the most blessed Virgin Mary; and I also recommend to Thee all poor sinners. My dear Saviour, I unite all my affections with the affections of Thy most loving Heart; and I offer them, thus united, to Thy Eternal Father, and beseech Him in Thy name to vouchsafe, for Thy love, to accept and grant them. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "litany_blessed_sacrament",
            title: "Litany of the Most Blessed Sacrament",
            latinTitle: "Litaniæ de Venerabili Sacramento",
            origin: "Traditional · 17th century",
            note: "Said before the Blessed Sacrament, in private devotion, at a visit or a Holy Hour.",
            english: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.
Christ, hear us. ℟. Christ, graciously hear us.

God the Father of Heaven, ℟. have mercy on us.
God the Son, Redeemer of the world,
God the Holy Spirit,
Holy Trinity, One God,

Living Bread, Who camest down from heaven, ℟. have mercy on us.
Hidden God and Saviour,
Corn of the elect,
Wine that bringeth forth virgins,
Fat bread and delight of kings,
Perpetual sacrifice,
Clean oblation,
Lamb without spot,
Most pure feast,
Food of angels,
Hidden manna,
Memorial of the wonders of God,
Supersubstantial Bread,
Word made flesh, dwelling in us,
Sacred Host,
Chalice of benediction,
Mystery of faith,

Most high and adorable Sacrament, ℟. have mercy on us.
Most holy of all sacrifices,
True propitiation for the living and the dead,
Heavenly antidote, by which we are preserved from sin,
Most wonderful of all miracles,
Most holy commemoration of the Passion of Christ,
Gift transcending all fulness,
Special memorial of divine love,
Abundance of divine bounty,
Most holy and august mystery,
Medicine of immortality,
Tremendous and life-giving Sacrament,
Bread made flesh by the omnipotence of the Word,
Unbloody sacrifice,
Our feast and our fellow-guest,
Sweetest banquet, at which the angels minister,
Sacrament of piety,
Bond of charity,
Priest and victim,
Spiritual sweetness tasted in its own fountain,
Refreshment of holy souls,
Viaticum of those who die in the Lord,
Pledge of future glory,

Be merciful, ℟. spare us, O Lord.
Be merciful, ℟. graciously hear us, O Lord.

From an unworthy reception of Thy Body and Blood, ℟. O Lord, deliver us.
From the lust of the flesh,
From the lust of the eyes,
From the pride of life,
From every occasion of sin,
Through that desire with which Thou didst desire to eat this Pasch with Thy disciples,
Through that profound humility with which Thou didst wash their feet,
Through that ardent charity with which Thou didst institute this divine Sacrament,
Through Thy Precious Blood, which Thou hast left us on the altar,
Through the five wounds of this Thy most holy Body, which Thou didst receive for us,

We sinners, ℟. we beseech Thee, hear us.
That Thou wouldst vouchsafe to preserve and increase our faith, reverence and devotion towards this admirable Sacrament,
That Thou wouldst vouchsafe to lead us, through a true confession of our sins, to a frequent reception of the Holy Eucharist,
That Thou wouldst vouchsafe to deliver us from all heresy, unbelief and blindness of heart,
That Thou wouldst vouchsafe to impart to us the precious and heavenly fruits of this most holy Sacrament,
That at the hour of our death Thou wouldst vouchsafe to strengthen and defend us with this heavenly Viaticum,
Son of God,

Lamb of God, Who takest away the sins of the world, ℟. spare us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. graciously hear us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. have mercy on us.

℣. Thou didst give them bread from heaven,
℟. Having in it all sweetness.

[Let us pray.]

O God, Who under a wonderful Sacrament hast left us a memorial of Thy Passion: grant us, we beseech Thee, so to venerate the sacred mysteries of Thy Body and Blood, that we may ever feel within us the fruit of Thy redemption: Who livest and reignest world without end.

℟. Amen.
""",
            latin: nil
        ),
    ]
}
