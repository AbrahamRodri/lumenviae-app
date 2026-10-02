//
//  PrayerBookJesus3.swift
//  Lumen Viae
//
//  The Precious Blood: its litany, its offering, and the Golden Arrow of reparation to the Holy Name.
//  Sources: Litaniae Pretiosissimi Sanguinis D.N.I.C., approved by St John XXIII (S. Congregation of Rites, 24 February 1960), the official Latin
//  The Raccolta (English edition, 1910), for the offering of the Precious Blood (its English, "wants" given as "needs")
//  Sr Marie of St Peter, Tours, 1843, the French of the Golden Arrow
//  English: our own literal rendering from the Latin of the 1960 litany and from the French of Sr Marie of St Peter
//

import Foundation

extension PrayerBookTexts {

    static let jesus3: [BookPrayer] = [
        BookPrayer(
            id: "litany_precious_blood",
            title: "Litany of the Most Precious Blood",
            latinTitle: "Litaniæ Pretiosissimi Sanguinis",
            origin: "Approved by St John XXIII · 1960",
            note: "Said especially through July, the month of the Precious Blood, whose feast falls on its first day.",
            english: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.
Christ, hear us. ℟. Christ, graciously hear us.

God the Father of Heaven, ℟. have mercy on us.
God the Son, Redeemer of the world,
God the Holy Spirit,
Holy Trinity, One God,

Blood of Christ, Only-begotten of the Eternal Father, ℟. save us.
Blood of Christ, Word of God made flesh,
Blood of Christ, of the New and Eternal Testament,
Blood of Christ, running down upon the earth in the Agony,
Blood of Christ, flowing forth in the Scourging,
Blood of Christ, streaming out in the Crowning with Thorns,
Blood of Christ, poured out upon the Cross,
Blood of Christ, price of our salvation,
Blood of Christ, without which there is no forgiveness,
Blood of Christ, in the Eucharist the drink and cleansing of souls,
Blood of Christ, river of mercy,
Blood of Christ, conqueror of demons,
Blood of Christ, strength of martyrs,
Blood of Christ, might of confessors,
Blood of Christ, bringing forth virgins,
Blood of Christ, stay of those in peril,
Blood of Christ, relief of those who labour,
Blood of Christ, solace in weeping,
Blood of Christ, hope of the penitent,
Blood of Christ, comfort of the dying,
Blood of Christ, peace and sweetness of hearts,
Blood of Christ, pledge of eternal life,
Blood of Christ, setting souls free from the pit of Purgatory,
Blood of Christ, most worthy of all glory and honour,

Lamb of God, Who takest away the sins of the world, ℟. spare us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. graciously hear us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. have mercy on us.

℣. Thou hast redeemed us, O Lord, in Thy Blood,
℟. And hast made us a kingdom for our God.

[Let us pray.]

Almighty and everlasting God, Who didst appoint Thine only-begotten Son to be the Redeemer of the world, and didst will to be appeased by His Blood: grant, we beseech Thee, that we may so venerate this price of our salvation, and by its power be so defended on earth from the evils of this present life, that we may rejoice in its everlasting fruit in heaven. Through the same Christ our Lord.

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

Sanguis Christi, Unigeniti Patris aeterni, ℟. salva nos.
Sanguis Christi, Verbi Dei incarnati,
Sanguis Christi, Novi et Aeterni Testamenti,
Sanguis Christi, in agonia decurrens in terram,
Sanguis Christi, in flagellatione profluens,
Sanguis Christi, in coronatione spinarum emanans,
Sanguis Christi, in Cruce effusus,
Sanguis Christi, pretium nostrae salutis,
Sanguis Christi, sine quo non fit remissio,
Sanguis Christi, in Eucharistia potus et lavacrum animarum,
Sanguis Christi, flumen misericordiae,
Sanguis Christi, victor daemonum,
Sanguis Christi, fortitudo martyrum,
Sanguis Christi, virtus confessorum,
Sanguis Christi, germinans virgines,
Sanguis Christi, robur periclitantium,
Sanguis Christi, levamen laborantium,
Sanguis Christi, in fletu solatium,
Sanguis Christi, spes poenitentium,
Sanguis Christi, solamen morientium,
Sanguis Christi, pax et dulcedo cordium,
Sanguis Christi, pignus vitae aeternae,
Sanguis Christi, animas liberans de lacu Purgatorii,
Sanguis Christi, omni gloria et honore dignissimus,

Agnus Dei, qui tollis peccata mundi, ℟. parce nobis, Domine.
Agnus Dei, qui tollis peccata mundi, ℟. exaudi nos, Domine.
Agnus Dei, qui tollis peccata mundi, ℟. miserere nobis.

℣. Redemisti nos, Domine, in sanguine tuo.
℟. Et fecisti nos Deo nostro regnum.

[Oremus.]

Omnipotens sempiterne Deus, qui unigenitum Filium tuum mundi Redemptorem constituisti, ac eius Sanguine placari voluisti: concede, quaesumus, salutis nostrae pretium ita venerari, atque a praesentis vitae malis eius virtute defendi in terris; ut fructu perpetuo laetemur in caelis. Per eundem Christum Dominum nostrum.

℟. Amen.
"""
        ),
        BookPrayer(
            id: "precious_blood_offering",
            title: "Offering of the Precious Blood",
            latinTitle: nil,
            origin: "The Raccolta · 1910",
            note: "A short offering that may be said at any hour, and is often said seven times together.",
            english: """
Eternal Father, I offer Thee the Most Precious Blood of Jesus Christ in satisfaction for my sins, and for the needs of Holy Church.

Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "golden_arrow",
            title: "The Golden Arrow",
            latinTitle: nil,
            origin: "Sr Marie of St Peter · 1843",
            note: "A prayer of praise in reparation for blasphemy against the Holy Name, given to a Carmelite of Tours.",
            english: """
May the most holy, most sacred, most adorable, most incomprehensible and unutterable Name of God be always praised, blessed, loved, adored and glorified, in heaven, on earth and under the earth, by all the creatures that have come forth from the hands of God, and by the Sacred Heart of our Lord Jesus Christ in the most holy Sacrament of the altar.

Amen.
""",
            latin: nil
        ),
    ]
}
