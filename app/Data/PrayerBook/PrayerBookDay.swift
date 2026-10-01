//
//  PrayerBookDay.swift
//  Lumen Viae
//
//  The Prayer Book's prayers through the day, to the angels and
//  saints, its litanies of St Joseph and of humility, and its short
//  prayers.
//

import Foundation

extension PrayerBookTexts {

    static let day: [BookPrayer] = [
        BookPrayer(
            id: "morning_offering",
            title: "The Morning Offering",
            latinTitle: nil,
            origin: "The Apostleship of Prayer · 19th century",
            note: "Said on waking, offering the whole day to God before it is begun.",
            english: """
O Jesus, through the Immaculate Heart of Mary, I offer Thee my prayers, works, joys and sufferings of this day, for all the intentions of Thy Sacred Heart, in union with the Holy Sacrifice of the Mass throughout the world, in reparation for my sins, for the intentions of all our associates, and in particular for the intention recommended this month by the Holy Father. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "grace_before",
            title: "Grace before Meals",
            latinTitle: "Benedic, Domine",
            origin: "The Hours of Prayer · the blessing at meals",
            note: "Said standing at table before the meal, with the Sign of the Cross.",
            english: """
Bless us, O Lord, and these Thy gifts,
which we are about to receive from Thy bounty,
through Christ our Lord. Amen.
""",
            latin: """
Benedic, Domine, nos et haec tua dona,
quae de tua largitate sumus sumpturi.
Per Christum Dominum nostrum. Amen.
"""
        ),
        BookPrayer(
            id: "grace_after",
            title: "Grace after Meals",
            latinTitle: "Agimus tibi gratias",
            origin: "The Hours of Prayer · the thanks after meals",
            note: "Said at the end of the meal, remembering those who have died.",
            english: """
We give Thee thanks, almighty God,
for all Thy benefits,
Who livest and reignest world without end. Amen.

℣. May the souls of the faithful departed, through the mercy of God, rest in peace.
℟. Amen.
""",
            latin: """
Agimus tibi gratias, omnipotens Deus,
pro universis beneficiis tuis,
qui vivis et regnas in saecula saeculorum. Amen.

℣. Fidelium animae, per misericordiam Dei, requiescant in pace.
℟. Amen.
"""
        ),
        BookPrayer(
            id: "angele_dei",
            title: "To One's Guardian Angel",
            latinTitle: "Angele Dei",
            origin: "Traditional · 11th century",
            note: "Said morning and night; among the first prayers a child learns.",
            english: """
Angel of God, my guardian dear,
to whom God's love commits me here,
ever this day be at my side,
to light and guard, to rule and guide. Amen.
""",
            latin: """
Angele Dei, qui custos es mei,
me, tibi commissum pietate superna,
hodie illumina, custodi,
rege et guberna. Amen.
"""
        ),
        BookPrayer(
            id: "visita_quaesumus",
            title: "Visit This House",
            latinTitle: "Visita, quæsumus",
            origin: "The Hours of Prayer · Bedtime Prayer (Compline)",
            note: "The prayer that ends the Church's Bedtime Prayer, asking the angels to guard the house through the night.",
            english: """
[Let us pray.]

Visit, we beseech Thee, O Lord, this dwelling, and drive far from it all snares of the enemy; let Thy holy angels dwell herein to preserve us in peace; and may Thy blessing be upon us always. Through our Lord Jesus Christ, Thy Son, Who liveth and reigneth with Thee in the unity of the Holy Ghost, God, world without end.

℟. Amen.
""",
            latin: """
[Oremus.]

Visita, quaesumus, Domine, habitationem istam, et omnes insidias inimici ab ea longe repelle: Angeli tui sancti habitent in ea, qui nos in pace custodiant; et benedictio tua sit super nos semper. Per Dominum nostrum Iesum Christum, Filium tuum, qui tecum vivit et regnat in unitate Spiritus Sancti, Deus, per omnia saecula saeculorum.

℟. Amen.
"""
        ),
        BookPrayer(
            id: "in_manus_tuas",
            title: "Into Thy Hands",
            latinTitle: "In manus tuas",
            origin: "The Hours of Prayer · Bedtime Prayer (Compline)",
            note: "A short call and answer from the Church's Bedtime Prayer, giving the night to God in Jesus's last words from the Cross.",
            english: """
℣. Into Thy hands, O Lord, I commend my spirit.
℟. Into Thy hands, O Lord, I commend my spirit.
℣. Thou hast redeemed us, O Lord, God of truth.
℟. I commend my spirit.
℣. Glory be to the Father, and to the Son, and to the Holy Spirit.
℟. Into Thy hands, O Lord, I commend my spirit.

℣. Keep us, O Lord, as the apple of Thine eye.
℟. Protect us under the shadow of Thy wings.
""",
            latin: """
℣. In manus tuas, Domine, commendo spiritum meum.
℟. In manus tuas, Domine, commendo spiritum meum.
℣. Redemisti nos, Domine, Deus veritatis.
℟. Commendo spiritum meum.
℣. Gloria Patri, et Filio, et Spiritui Sancto.
℟. In manus tuas, Domine, commendo spiritum meum.

℣. Custodi nos, Domine, ut pupillam oculi.
℟. Sub umbra alarum tuarum protege nos.
"""
        ),
        BookPrayer(
            id: "examen",
            title: "The Examen before Sleep",
            latinTitle: nil,
            origin: "After St Ignatius of Loyola",
            note: "Made each night at bedtime: a few quiet minutes looking back over the day, in five steps.",
            english: """
[Give thanks to God for the gifts of this day.]
I thank Thee, O my God, for all the benefits Thou hast bestowed on me this day.

[Ask for light to see the day as He sees it.]
Give me light, O Lord, to know my sins, and to see this day as Thou seest it.

[Go back over the day, hour by hour: what was done, said, thought, and left undone.]
Prove me, O God, and know my heart: examine me, and know my paths.

[Ask pardon for what was wrong.]
O God, be merciful to me a sinner.

[Resolve, with His grace, to amend tomorrow.]
Grant me, O Lord, the grace to amend my life, and to serve Thee better tomorrow. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "jmj",
            title: "Jesus, Mary and Joseph",
            latinTitle: nil,
            origin: "The Raccolta, an old Vatican prayer book",
            note: "Said at any hour, and asked for especially as the hour of death draws near.",
            english: """
Jesus, Mary and Joseph, I give you my heart and my soul.
Jesus, Mary and Joseph, assist me in my last agony.
Jesus, Mary and Joseph, may I breathe forth my soul in peace with you.
""",
            latin: nil
        ),
        BookPrayer(
            id: "sweet_heart",
            title: "Sweet Heart of Jesus",
            latinTitle: "Dulce Cor Iesu",
            origin: "The Raccolta, an old Vatican prayer book",
            note: "Two short petitions to the Hearts of Jesus and Mary, said in passing through the day.",
            english: """
Sweet Heart of Jesus, be my love.
Sweet Heart of Mary, be my salvation.
""",
            latin: """
Dulce Cor Iesu, esto amor meus.
Dulce Cor Mariae, esto salus mea.
"""
        ),
        BookPrayer(
            id: "jesus_meek",
            title: "Jesus, Meek and Humble of Heart",
            latinTitle: "Iesu, mitis et humilis Corde",
            origin: "The Raccolta, an old Vatican prayer book · after Matthew 11:29",
            note: "Our Lord's words of Himself, turned into a petition; it also closes the Litany of the Sacred Heart.",
            english: """
Jesus, meek and humble of heart,
make our hearts like unto Thine.
""",
            latin: """
Iesu, mitis et humilis Corde,
fac cor nostrum secundum Cor tuum.
"""
        ),
        BookPrayer(
            id: "my_jesus_mercy",
            title: "My Jesus, Mercy",
            latinTitle: "Iesu mi, misericordia",
            origin: "The Raccolta, an old Vatican prayer book",
            note: "Said in a breath, at any moment of the day and in time of temptation.",
            english: """
My Jesus, mercy.
""",
            latin: """
Iesu mi, misericordia.
"""
        ),
        BookPrayer(
            id: "pardon_prayer",
            title: "The Pardon Prayer",
            latinTitle: nil,
            origin: "The Angel of Peace at Fatima · 1916",
            note: "Taught to the three children, who said it three times with their foreheads bowed to the ground.",
            english: """
My God, I believe, I adore, I hope and I love Thee.
I ask pardon of Thee for those who do not believe,
do not adore, do not hope and do not love Thee.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_patrick_breastplate",
            title: "St Patrick's Breastplate",
            latinTitle: nil,
            origin: "Attributed to St Patrick · 5th century",
            note: "The heart of a longer prayer for protection, said on waking and before setting out.",
            english: """
Christ with me, Christ before me, Christ behind me,
Christ within me, Christ beneath me, Christ above me,
Christ at my right hand, Christ at my left,
Christ as I lie down, Christ as I sit, Christ as I rise,
Christ in the heart of all who think of me,
Christ in the mouth of all who speak of me,
Christ in every eye that looks on me,
Christ in every ear that hears me.
""",
            latin: nil
        ),
        BookPrayer(
            id: "nunc_dimittis",
            title: "The Canticle of Simeon",
            latinTitle: "Nunc dimittis",
            origin: "Luke 2:29–32 · Douay-Rheims",
            note: "Simeon's song on holding the Child Jesus in the Temple, sung every night at the Church's Bedtime Prayer (Compline).",
            english: """
Protect us, O Lord, while we are awake, and guard us while we sleep;
that we may watch with Christ, and rest in peace.

Now Thou dost dismiss Thy servant, O Lord, * according to Thy word in peace;
Because my eyes have seen * Thy salvation,
Which Thou hast prepared * before the face of all peoples:
A light to the revelation of the Gentiles, * and the glory of Thy people Israel.

Glory be to the Father, and to the Son, * and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be, * world without end. Amen.

Protect us, O Lord, while we are awake, and guard us while we sleep;
that we may watch with Christ, and rest in peace.
""",
            latin: """
Salva nos, Domine, vigilantes, custodi nos dormientes;
ut vigilemus cum Christo, et requiescamus in pace.

Nunc dimittis servum tuum, Domine, * secundum verbum tuum in pace:
Quia viderunt oculi mei * salutare tuum,
Quod parasti * ante faciem omnium populorum:
Lumen ad revelationem gentium, * et gloriam plebis tuae Israel.

Gloria Patri, et Filio, * et Spiritui Sancto.
Sicut erat in principio, et nunc, et semper, * et in saecula saeculorum. Amen.

Salva nos, Domine, vigilantes, custodi nos dormientes;
ut vigilemus cum Christo, et requiescamus in pace.
"""
        ),
        BookPrayer(
            id: "ad_te_beate_ioseph",
            title: "To Thee, O Blessed Joseph",
            latinTitle: "Ad te, beate Ioseph",
            origin: "Pope Leo XIII · 1889",
            note: "Written by Pope Leo XIII in a letter to the whole Church, to be said after the Rosary through October.",
            english: """
To thee, O blessed Joseph, do we have recourse in our tribulation, and having implored the help of thy most holy Spouse, we confidently invoke thy patronage also.

Through that charity which bound thee to the Immaculate Virgin Mother of God, and through the fatherly love with which thou didst embrace the Child Jesus, we humbly beseech thee graciously to regard the inheritance which Jesus Christ hath purchased by His Blood, and with thy power and strength to aid us in our necessities.

O most watchful Guardian of the Divine Family, defend the chosen children of Jesus Christ; O most loving father, ward off from us every contagion of error and corrupting influence; O our most mighty protector, be propitious to us and from heaven assist us in our struggle with the power of darkness; and as once thou didst rescue the Child Jesus from deadly peril, so now protect God's holy Church from the snares of the enemy and from all adversity; shield, too, each one of us by thy constant protection, so that, supported by thy example and thy aid, we may be able to live piously, to die holily, and to obtain eternal happiness in heaven. Amen.
""",
            latin: """
Ad te, beate Ioseph, in tribulatione nostra confugimus, atque, implorato Sponsae tuae sanctissimae auxilio, patrocinium quoque tuum fidenter exposcimus.

Per eam, quaesumus, quae te cum immaculata Virgine Dei Genitrice coniunxit, caritatem, perque paternum, quo Puerum Iesum amplexus es, amorem, supplices deprecamur, ut ad hereditatem, quam Iesus Christus acquisivit Sanguine suo, benignus respicias, ac necessitatibus nostris tua virtute et ope succurras.

Tuere, o Custos providentissime divinae Familiae, Iesu Christi sobolem electam; prohibe a nobis, amantissime Pater, omnem errorum ac corruptelarum luem; propitius nobis, sospitator noster fortissime, in hoc cum potestate tenebrarum certamine e caelo adesto; et sicut olim Puerum Iesum e summo eripuisti vitae discrimine, ita nunc Ecclesiam sanctam Dei ab hostilibus insidiis atque ab omni adversitate defende; nosque singulos perpetuo tege patrocinio, ut ad tui exemplar et ope tua suffulti, sancte vivere, pie emori, sempiternamque in caelis beatitudinem assequi possimus. Amen.
"""
        ),
        BookPrayer(
            id: "litany_of_humility",
            title: "Litany of Humility",
            latinTitle: nil,
            origin: "Attributed to Cardinal Rafael Merry del Val · 20th century",
            note: "Said slowly, one petition at a time, against the wish to be esteemed.",
            english: """
O Jesus, meek and humble of heart, ℟. hear me.

From the desire of being esteemed, ℟. deliver me, Jesus.
From the desire of being loved,
From the desire of being extolled,
From the desire of being honored,
From the desire of being praised,
From the desire of being preferred to others,
From the desire of being consulted,
From the desire of being approved,

From the fear of being humiliated, ℟. deliver me, Jesus.
From the fear of being despised,
From the fear of suffering rebukes,
From the fear of being calumniated,
From the fear of being forgotten,
From the fear of being ridiculed,
From the fear of being wronged,
From the fear of being suspected,

That others may be loved more than I, ℟. Jesus, grant me the grace to desire it.
That others may be esteemed more than I,
That, in the opinion of the world, others may increase and I may decrease,
That others may be chosen and I set aside,
That others may be praised and I unnoticed,
That others may be preferred to me in everything,
That others may become holier than I, provided that I may become as holy as I should,
""",
            latin: nil
        ),
        BookPrayer(
            id: "litany_st_joseph",
            title: "Litany of St Joseph",
            latinTitle: "Litaniæ Sancti Ioseph",
            origin: "Approved by Pope St Pius X · 1909",
            note: "Said especially on Wednesdays, the day given to St Joseph, and through March, his month.",
            english: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.
Christ, hear us. ℟. Christ, graciously hear us.

God the Father of Heaven, ℟. have mercy on us.
God the Son, Redeemer of the world,
God the Holy Ghost,
Holy Trinity, One God,

Holy Mary, ℟. pray for us.
St Joseph,
Renowned offspring of David,
Light of Patriarchs,

Spouse of the Mother of God, ℟. pray for us.
Chaste guardian of the Virgin,
Foster-father of the Son of God,
Diligent protector of Christ,
Head of the Holy Family,

Joseph most just, ℟. pray for us.
Joseph most chaste,
Joseph most prudent,
Joseph most strong,
Joseph most obedient,
Joseph most faithful,

Mirror of patience, ℟. pray for us.
Lover of poverty,
Model of artisans,
Glory of home life,
Guardian of virgins,
Pillar of families,

Solace of the wretched, ℟. pray for us.
Hope of the sick,
Patron of the dying,
Terror of demons,
Protector of Holy Church,

Lamb of God, Who takest away the sins of the world, ℟. spare us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. graciously hear us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. have mercy on us.

℣. He made him the lord of his house,
℟. And ruler of all his substance.

[Let us pray.]

O God, Who in Thine ineffable providence didst vouchsafe to choose blessed Joseph to be the spouse of Thy most holy Mother, grant, we beseech Thee, that we may be worthy to have him for our intercessor in heaven, whom we venerate as our protector on earth: Who livest and reignest world without end.

℟. Amen.
""",
            latin: """
Kyrie, eleison.
Christe, eleison.
Kyrie, eleison.
Christe, audi nos. ℟. Christe, exaudi nos.

Pater de caelis, Deus, ℟. miserere nobis.
Fili, Redemptor mundi, Deus,
Spiritus Sancte, Deus,
Sancta Trinitas, unus Deus,

Sancta Maria, ℟. ora pro nobis.
Sancte Ioseph,
Proles David inclyta,
Lumen Patriarcharum,

Dei Genitricis Sponse, ℟. ora pro nobis.
Custos pudice Virginis,
Filii Dei nutritie,
Christi defensor sedule,
Almae Familiae praeses,

Ioseph iustissime, ℟. ora pro nobis.
Ioseph castissime,
Ioseph prudentissime,
Ioseph fortissime,
Ioseph obedientissime,
Ioseph fidelissime,

Speculum patientiae, ℟. ora pro nobis.
Amator paupertatis,
Exemplar opificum,
Domesticae vitae decus,
Custos virginum,
Familiarum columen,

Solatium miserorum, ℟. ora pro nobis.
Spes aegrotantium,
Patrone morientium,
Terror daemonum,
Protector sanctae Ecclesiae,

Agnus Dei, qui tollis peccata mundi, ℟. parce nobis, Domine.
Agnus Dei, qui tollis peccata mundi, ℟. exaudi nos, Domine.
Agnus Dei, qui tollis peccata mundi, ℟. miserere nobis.

℣. Constituit eum dominum domus suae.
℟. Et principem omnis possessionis suae.

[Oremus.]

Deus, qui ineffabili providentia beatum Ioseph sanctissimae Genitricis tuae Sponsum eligere dignatus es: praesta, quaesumus; ut quem protectorem veneramur in terris, intercessorem habere mereamur in caelis: Qui vivis et regnas in saecula saeculorum.

℟. Amen.
"""
        ),
        BookPrayer(
            id: "benedictus",
            title: "The Canticle of Zachary",
            latinTitle: "Benedictus",
            origin: "Luke 1:68–79 · Douay-Rheims",
            note: "Zachary's song at the birth of his son John, sung every morning at the Church's Dawn Prayer (Lauds).",
            english: """
Blessed be the Lord God of Israel; * because He hath visited and wrought the redemption of His people:
And hath raised up an horn of salvation to us, * in the house of David His servant:
As He spoke by the mouth of His holy prophets, * who are from the beginning:
Salvation from our enemies, * and from the hand of all that hate us:

To perform mercy to our fathers, * and to remember His holy testament,
The oath, which He swore to Abraham our father, * that He would grant to us,
That being delivered from the hand of our enemies, * we may serve Him without fear,
In holiness and justice before Him, * all our days.

And thou, child, shalt be called the prophet of the Highest: * for thou shalt go before the face of the Lord to prepare His ways:
To give knowledge of salvation to His people, * unto the remission of their sins:
Through the bowels of the mercy of our God, * in which the Orient from on high hath visited us:
To enlighten them that sit in darkness, and in the shadow of death: * to direct our feet into the way of peace.

Glory be to the Father, and to the Son, * and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be, * world without end. Amen.
""",
            latin: """
Benedictus Dominus, Deus Israel: * quia visitavit, et fecit redemptionem plebis suae:
Et erexit cornu salutis nobis: * in domo David, pueri sui.
Sicut locutus est per os sanctorum, * qui a saeculo sunt, prophetarum eius:
Salutem ex inimicis nostris, * et de manu omnium, qui oderunt nos.

Ad faciendam misericordiam cum patribus nostris: * et memorari testamenti sui sancti.
Iusiurandum, quod iuravit ad Abraham patrem nostrum, * daturum se nobis:
Ut sine timore, de manu inimicorum nostrorum liberati, * serviamus illi.
In sanctitate et iustitia coram ipso, * omnibus diebus nostris.

Et tu, puer, Propheta Altissimi vocaberis: * praeibis enim ante faciem Domini parare vias eius:
Ad dandam scientiam salutis plebi eius: * in remissionem peccatorum eorum:
Per viscera misericordiae Dei nostri: * in quibus visitavit nos, oriens ex alto:
Illuminare his qui in tenebris, et in umbra mortis sedent: * ad dirigendos pedes nostros in viam pacis.

Gloria Patri, et Filio, * et Spiritui Sancto.
Sicut erat in principio, et nunc, et semper, * et in saecula saeculorum. Amen.
"""
        )
    ]
}
