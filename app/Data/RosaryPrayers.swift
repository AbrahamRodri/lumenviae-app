//
//  RosaryPrayers.swift
//  Lumen Viae
//
//  The prayers of the Rosary, English and Latin, in the order they are
//  said — what How to Pray teaches bead by bead — and `DevotionPrayers`,
//  the one place a prayer page finds any bundled prayer by its id.
//

import Foundation

enum RosaryPrayers {

    /// In the order they are said: the Rosary's eight, then the
    /// chaplet's two and the two optional closing prayers
    static let all: [BilingualConsecrationPrayer] = [
        BilingualConsecrationPrayer(
            id: "sign_of_cross",
            englishTitle: "The Sign of the Cross",
            latinTitle: "Signum Crucis",
            englishContent: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
            latinContent: "In nomine Patris, et Filii, et Spiritus Sancti. Amen."
        ),
        BilingualConsecrationPrayer(
            id: "apostles_creed",
            englishTitle: "The Apostles' Creed",
            latinTitle: "Symbolum Apostolorum",
            englishContent: """
I believe in God, the Father almighty, Creator of heaven and earth,
and in Jesus Christ, His only Son, our Lord,
who was conceived by the Holy Spirit, born of the Virgin Mary,
suffered under Pontius Pilate, was crucified, died and was buried;
He descended into hell;
on the third day He rose again from the dead;
He ascended into heaven, and is seated at the right hand of God the Father almighty;
from there He will come to judge the living and the dead.
I believe in the Holy Spirit,
the holy catholic Church, the communion of saints,
the forgiveness of sins, the resurrection of the body,
and life everlasting. Amen.
""",
            latinContent: """
Credo in Deum Patrem omnipotentem, Creatorem caeli et terrae,
et in Iesum Christum, Filium eius unicum, Dominum nostrum,
qui conceptus est de Spiritu Sancto, natus ex Maria Virgine,
passus sub Pontio Pilato, crucifixus, mortuus, et sepultus;
descendit ad inferos;
tertia die resurrexit a mortuis;
ascendit ad caelos, sedet ad dexteram Dei Patris omnipotentis;
inde venturus est iudicare vivos et mortuos.
Credo in Spiritum Sanctum,
sanctam Ecclesiam catholicam, sanctorum communionem,
remissionem peccatorum, carnis resurrectionem,
vitam aeternam. Amen.
"""
        ),
        BilingualConsecrationPrayer(
            id: "our_father",
            englishTitle: "The Our Father",
            latinTitle: "Pater Noster",
            englishContent: """
Our Father, who art in heaven,
hallowed be Thy name;
Thy kingdom come;
Thy will be done on earth as it is in heaven.
Give us this day our daily bread;
and forgive us our trespasses
as we forgive those who trespass against us;
and lead us not into temptation,
but deliver us from evil. Amen.
""",
            latinContent: """
Pater noster, qui es in caelis,
sanctificetur nomen tuum;
adveniat regnum tuum;
fiat voluntas tua, sicut in caelo et in terra.
Panem nostrum quotidianum da nobis hodie;
et dimitte nobis debita nostra,
sicut et nos dimittimus debitoribus nostris;
et ne nos inducas in tentationem,
sed libera nos a malo. Amen.
"""
        ),
        BilingualConsecrationPrayer(
            id: "hail_mary",
            englishTitle: "The Hail Mary",
            latinTitle: "Ave Maria",
            englishContent: """
Hail Mary, full of grace, the Lord is with thee;
blessed art thou among women,
and blessed is the fruit of thy womb, Jesus.
Holy Mary, Mother of God,
pray for us sinners,
now and at the hour of our death. Amen.
""",
            latinContent: """
Ave Maria, gratia plena, Dominus tecum;
benedicta tu in mulieribus,
et benedictus fructus ventris tui, Iesus.
Sancta Maria, Mater Dei,
ora pro nobis peccatoribus,
nunc et in hora mortis nostrae. Amen.
"""
        ),
        BilingualConsecrationPrayer(
            id: "glory_be",
            englishTitle: "The Glory Be",
            latinTitle: "Gloria Patri",
            englishContent: RosaryPrayerText.gloryBe.english,
            latinContent: RosaryPrayerText.gloryBe.latin
        ),
        BilingualConsecrationPrayer(
            id: "fatima_prayer",
            englishTitle: "The Fatima Prayer",
            latinTitle: "Oratio Fatimae",
            englishContent: RosaryPrayerText.fatimaPrayer.english,
            latinContent: RosaryPrayerText.fatimaPrayer.latin
        ),
        BilingualConsecrationPrayer(
            id: "hail_holy_queen",
            englishTitle: "Hail, Holy Queen",
            latinTitle: "Salve Regina",
            englishContent: """
Hail, holy Queen, Mother of mercy,
our life, our sweetness and our hope.
To thee do we cry, poor banished children of Eve.
To thee do we send up our sighs,
mourning and weeping in this valley of tears.
Turn, then, most gracious advocate,
thine eyes of mercy toward us,
and after this, our exile, show unto us the blessed fruit of thy womb, Jesus.
O clement, O loving, O sweet Virgin Mary.
Pray for us, O holy Mother of God,
that we may be made worthy of the promises of Christ.
""",
            latinContent: """
Salve, Regina, Mater misericordiae,
vita, dulcedo, et spes nostra, salve.
Ad te clamamus, exsules filii Hevae.
Ad te suspiramus,
gementes et flentes in hac lacrimarum valle.
Eia ergo, advocata nostra,
illos tuos misericordes oculos ad nos converte,
et Iesum, benedictum fructum ventris tui, nobis post hoc exsilium ostende.
O clemens, O pia, O dulcis Virgo Maria.
Ora pro nobis, sancta Dei Genetrix,
ut digni efficiamur promissionibus Christi.
"""
        ),
        BilingualConsecrationPrayer(
            id: "rosary_closing_prayer",
            englishTitle: "Closing Prayer",
            latinTitle: "Oratio",
            englishContent: """
[Let us pray.]
O God, whose only-begotten Son,
by His life, death and resurrection,
has purchased for us the rewards of eternal life;
grant, we beseech Thee,
that meditating upon these mysteries of the most holy Rosary of the Blessed Virgin Mary,
we may imitate what they contain
and obtain what they promise,
through the same Christ our Lord. Amen.
""",
            latinContent: """
[Oremus.]
Deus, cuius Unigenitus
per vitam, mortem et resurrectionem suam
nobis salutis aeternae praemia comparavit;
concede, quaesumus,
ut haec mysteria sacratissimo beatae Mariae Virginis Rosario recolentes,
et imitemur quod continent,
et quod promittunt assequamur.
Per eundem Christum Dominum nostrum. Amen.
"""
        ),

        // The chaplet of the Seven Sorrows opens with the Act of
        // Contrition and closes with its own prayer; the Memorare and the
        // Prayer to Saint Michael are said after the Rosary by those who
        // choose them in Settings. All four are recorded by the server
        // word for word, as the prayers above are.
        BilingualConsecrationPrayer(
            id: "act_of_contrition",
            englishTitle: "The Act of Contrition",
            latinTitle: "Actus Contritionis",
            englishContent: """
O my God, I am heartily sorry for having offended Thee,
and I detest all my sins because I dread the loss of heaven and the pains of hell;
but most of all because they offend Thee, my God,
Who art all good and deserving of all my love.
I firmly resolve, with the help of Thy grace,
to confess my sins, to do penance,
and to amend my life. Amen.
""",
            latinContent: """
Deus meus, ex toto corde paenitet me omnium meorum peccatorum,
eaque detestor, quia peccando, non solum poenas a Te iuste statutas promeritus sum,
sed praesertim quia offendi Te, summum bonum, ac dignum qui super omnia diligaris.
Ideo firmiter propono, adiuvante gratia Tua,
de cetero me non peccaturum peccandique occasiones proximas fugiturum. Amen.
"""
        ),
        BilingualConsecrationPrayer(
            id: "sorrows_closing_prayer",
            englishTitle: "Closing Prayer of the Seven Sorrows",
            latinTitle: "Oratio",
            englishContent: """
Pray for us, O most sorrowful Virgin,
that we may be made worthy of the promises of Christ.
[Let us pray.]
Lord Jesus, we now implore, both for the present and for the hour of our death,
the intercession of the most Blessed Virgin Mary, Thy Mother,
whose holy soul was pierced at the time of Thy Passion by a sword of grief.
Grant us this favor, O Savior of the world,
Who livest and reignest with the Father and the Holy Spirit,
world without end. Amen.
""",
            latinContent: """
Ora pro nobis, Virgo dolorosissima,
ut digni efficiamur promissionibus Christi.
[Oremus.]
Interveniat pro nobis, quaesumus, Domine Iesu Christe, nunc et in hora mortis nostrae,
apud tuam clementiam beata Virgo Maria, Mater tua,
cuius sacratissimam animam in hora tuae passionis doloris gladius pertransivit.
Per te, Iesu Christe, Salvator mundi,
qui cum Patre et Spiritu Sancto vivis et regnas in saecula saeculorum. Amen.
"""
        ),
        BilingualConsecrationPrayer(
            id: "memorare",
            englishTitle: "The Memorare",
            latinTitle: "Memorare",
            englishContent: """
Remember, O most gracious Virgin Mary,
that never was it known that anyone who fled to thy protection,
implored thy help, or sought thine intercession, was left unaided.
Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother;
to thee do I come, before thee I stand, sinful and sorrowful.
O Mother of the Word Incarnate, despise not my petitions,
but in thy mercy hear and answer me. Amen.
""",
            latinContent: """
Memorare, O piissima Virgo Maria,
non esse auditum a saeculo, quemquam ad tua currentem praesidia,
tua implorantem auxilia, tua petentem suffragia, esse derelictum.
Ego tali animatus confidentia, ad te, Virgo Virginum, Mater, curro,
ad te venio, coram te gemens peccator assisto.
Noli, Mater Verbi, verba mea despicere;
sed audi propitia et exaudi. Amen.
"""
        ),
        BilingualConsecrationPrayer(
            id: "st_michael_prayer",
            englishTitle: "Prayer to Saint Michael",
            latinTitle: "Oratio ad Sanctum Michaelem",
            englishContent: """
Saint Michael the Archangel, defend us in battle.
Be our safeguard against the wickedness and snares of the devil.
May God rebuke him, we humbly pray;
and do thou, O Prince of the heavenly hosts,
by the power of God, cast into hell Satan and all the evil spirits,
who prowl about the world seeking the ruin of souls. Amen.
""",
            latinContent: """
Sancte Michael Archangele, defende nos in proelio;
contra nequitiam et insidias diaboli esto praesidium.
Imperet illi Deus, supplices deprecamur:
tuque, Princeps militiae caelestis,
Satanam aliosque spiritus malignos, qui ad perditionem animarum pervagantur in mundo,
divina virtute in infernum detrude. Amen.
"""
        )
    ]
}

// MARK: - DevotionPrayers

enum DevotionPrayers {

    /// Any bundled prayer with a page of its own: the consecration's
    /// hymns and litanies, and the prayers of the Rosary.
    static func find(_ id: String) -> BilingualConsecrationPrayer? {
        RosaryPrayers.all.first { $0.id == id } ?? BilingualConsecrationPrayers.allPrayers[id]
    }
}
