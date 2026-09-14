//
//  BilingualConsecrationPrayers.swift
//  Lumen Viae
//
//  Consecration prayers, each defined once with English and Latin versions.
//
//  Every prayer here is set the way a printed prayer book sets it, in
//  the small grammar `PrayerText` reads (DesignSystem/ReadingText):
//  ℣ ℟ ✠ in rubric red; a litany's response on the first line of each
//  group after its ℟, answered to every line beneath; a canticle's
//  verses pointed at the mediant with ` * `; "[Orémus.]" in brackets as
//  a rubric; prose as one line per paragraph. The Latin carries the
//  accents of the Liber Usualis, because these are chanted.
//
//  The English and the Latin of a prayer pair line for line — the same
//  count of lines, the blank lines in the same places — or the
//  bilingual modes fall back to two blocks. Keep them in step.
//

import Foundation
import SwiftUI

// MARK: - Bilingual Consecration Prayers

enum BilingualConsecrationPrayers {

    /// Every bilingual consecration prayer, keyed by id.
    ///
    /// Stored rather than rebuilt per call: the day overview asks for this
    /// while resolving its prayer list and again for the chant, and every
    /// `ConsecrationData.prayers(for:language:)` call reaches for it too,
    /// so a function here rebuilds the dictionary several times per render.
    static let allPrayers: [String: BilingualConsecrationPrayer] = [
        "veni_creator": veniCreator,
        "ave_maris_stella": aveMaris,
        "magnificat": magnificat,
        "glory_be": gloryBe,
        "litany_loreto": litanyOfLoreto,
        "litany_holy_name": litanyOfTheHolyName,
        "o_jesus_living_in_mary": oJesusLivingInMary
    ]

    // MARK: - Hymns

    static let veniCreator = BilingualConsecrationPrayer(
        id: "veni_creator",
        englishTitle: "Come, Creator Spirit",
        latinTitle: "Veni Creator Spiritus",
        englishContent: """
Come, Holy Ghost, Creator blest,
and in our souls take up Thy rest;
come with Thy grace and heavenly aid
to fill the hearts which Thou hast made.

O Comforter, to Thee we cry,
Thou heavenly gift of God most high,
Thou fount of life and fire of love,
and sweet anointing from above.

Thou in Thy sevenfold gifts art known;
Thou, finger of God's hand we own;
Thou, promise of the Father, Thou
Who dost the tongue with power endow.

Kindle our senses from above,
and make our hearts o'erflow with love;
with patience firm and virtue high
the weakness of our flesh supply.

Far from us drive the foe we dread,
and grant us Thy true peace instead;
so shall we not, with Thee for guide,
turn from the path of life aside.

Oh, may Thy grace on us bestow
the Father and the Son to know;
and Thee, through endless times confessed,
of both the eternal Spirit blest.

Now to the Father and the Son,
Who rose from death, be glory given,
with Thou, O holy Comforter,
henceforth by all in earth and heaven. Amen.
""",
        latinContent: """
Veni, Creátor Spíritus,
mentes tuórum vísita,
imple supérna grátia,
quæ tu creásti péctora.

Qui díceris Paráclitus,
altíssimi donum Dei,
fons vivus, ignis, cáritas,
et spiritális únctio.

Tu septifórmis múnere,
dígitus patérnæ déxteræ,
tu rite promíssum Patris,
sermóne ditans gúttura.

Accénde lumen sénsibus,
infúnde amórem córdibus,
infírma nostri córporis
virtúte firmans pérpeti.

Hostem repéllas lóngius,
pacémque dones prótinus:
ductóre sic te prævio
vitémus omne nóxium.

Per te sciámus da Patrem,
noscámus atque Fílium,
teque utriúsque Spíritum
credámus omni témpore.

Deo Patri sit glória,
et Fílio, qui a mórtuis
surréxit, ac Paráclito,
in sæculórum sæcula. Amen.
""",
        hasChantAudio: true
    )

    static let aveMaris = BilingualConsecrationPrayer(
        id: "ave_maris_stella",
        englishTitle: "Hail, Star of the Sea",
        latinTitle: "Ave Maris Stella",
        englishContent: """
Hail, O Star of the ocean,
God's own Mother blest,
ever sinless Virgin,
gate of heavenly rest.

Taking that sweet Ave,
which from Gabriel came,
peace confirm within us,
changing Eve's name.

Break the sinners' fetters,
make our blindness day,
chase all evils from us,
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
be the glory one. Amen.
""",
        latinContent: """
Ave, maris stella,
Dei Mater alma,
atque semper Virgo,
felix cæli porta.

Sumens illud Ave
Gabriélis ore,
funda nos in pace,
mutans Hevæ nomen.

Solve vincla reis,
profer lumen cæcis,
mala nostra pelle,
bona cuncta posce.

Monstra te esse matrem,
sumat per te preces,
qui pro nobis natus
tulit esse tuus.

Virgo singuláris,
inter omnes mitis,
nos culpis solútos
mites fac et castos.

Vitam præsta puram,
iter para tutum,
ut vidéntes Jesum
semper collætémur.

Sit laus Deo Patri,
summo Christo decus,
Spirítui Sancto,
tribus honor unus. Amen.
""",
        hasChantAudio: true
    )

    // MARK: - Canticle

    /// Pointed at the mediant, as the breviary sets it: each verse breaks
    /// at the ` * `, and the second half hangs in beneath the first.
    static let magnificat = BilingualConsecrationPrayer(
        id: "magnificat",
        englishTitle: "The Canticle of Mary",
        latinTitle: "Magnificat",
        englishContent: """
My soul * doth magnify the Lord.
And my spirit hath rejoiced * in God my Saviour.
Because He hath regarded the humility of His handmaid: * for behold from henceforth all generations shall call me blessed.
Because He that is mighty hath done great things to me: * and holy is His name.

And His mercy is from generation unto generations, * to them that fear Him.
He hath shewed might in His arm: * He hath scattered the proud in the conceit of their heart.
He hath put down the mighty from their seat, * and hath exalted the humble.
He hath filled the hungry with good things: * and the rich He hath sent empty away.

He hath received Israel His servant, * being mindful of His mercy.
As He spoke to our fathers, * to Abraham and to his seed for ever.

Glory be to the Father, and to the Son, * and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be, * world without end. Amen.
""",
        latinContent: """
Magníficat * ánima mea Dóminum.
Et exsultávit spíritus meus * in Deo salutári meo.
Quia respéxit humilitátem ancíllæ suæ: * ecce enim ex hoc beátam me dicent omnes generatiónes.
Quia fecit mihi magna qui potens est: * et sanctum nomen ejus.

Et misericórdia ejus a progénie in progénies * timéntibus eum.
Fecit poténtiam in bráchio suo: * dispérsit supérbos mente cordis sui.
Depósuit poténtes de sede, * et exaltávit húmiles.
Esuriéntes implévit bonis: * et dívites dimísit inánes.

Suscépit Israël púerum suum, * recordátus misericórdiæ suæ.
Sicut locútus est ad patres nostros, * Abraham et sémini ejus in sæcula.

Glória Patri, et Fílio, * et Spirítui Sancto.
Sicut erat in princípio, et nunc, et semper, * et in sæcula sæculórum. Amen.
""",
        hasChantAudio: true
    )

    // MARK: - Doxology

    static let gloryBe = BilingualConsecrationPrayer(
        id: "glory_be",
        englishTitle: "Glory Be",
        latinTitle: "Gloria Patri",
        englishContent: """
Glory be to the Father,
and to the Son,
and to the Holy Spirit.
As it was in the beginning,
is now, and ever shall be,
world without end. Amen.
""",
        latinContent: """
Glória Patri,
et Fílio,
et Spirítui Sancto.
Sicut erat in princípio,
et nunc, et semper,
et in sæcula sæculórum. Amen.
"""
    )

    // MARK: - Litanies

    /// The response is stated once at the head of each group, after its
    /// ℟, and is answered to every invocation beneath it — how every
    /// printed litany is set, and what keeps fifty lines a column of
    /// titles rather than a wall.
    static let litanyOfLoreto = BilingualConsecrationPrayer(
        id: "litany_loreto",
        englishTitle: "Litany of the Blessed Virgin Mary",
        latinTitle: "Litaniæ Lauretanæ",
        englishContent: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.
Christ, hear us. ℟. Christ, graciously hear us.

God the Father of Heaven, ℟. have mercy on us.
God the Son, Redeemer of the world,
God the Holy Ghost,
Holy Trinity, One God,

Holy Mary, ℟. pray for us.
Holy Mother of God,
Holy Virgin of virgins,

Mother of Christ, ℟. pray for us.
Mother of divine grace,
Mother most pure,
Mother most chaste,
Mother inviolate,
Mother undefiled,
Mother most amiable,
Mother most admirable,
Mother of good counsel,
Mother of our Creator,
Mother of our Saviour,
Mother of the Church,

Virgin most prudent, ℟. pray for us.
Virgin most venerable,
Virgin most renowned,
Virgin most powerful,
Virgin most merciful,
Virgin most faithful,

Mirror of justice, ℟. pray for us.
Seat of wisdom,
Cause of our joy,
Spiritual vessel,
Vessel of honor,
Singular vessel of devotion,
Mystical rose,
Tower of David,
Tower of ivory,
House of gold,
Ark of the covenant,
Gate of Heaven,
Morning star,

Health of the sick, ℟. pray for us.
Refuge of sinners,
Comforter of the afflicted,
Help of Christians,

Queen of angels, ℟. pray for us.
Queen of patriarchs,
Queen of prophets,
Queen of Apostles,
Queen of martyrs,
Queen of confessors,
Queen of virgins,
Queen of all saints,
Queen conceived without Original Sin,
Queen assumed into Heaven,
Queen of the most holy Rosary,
Queen of peace,

Lamb of God, Who takest away the sins of the world, ℟. spare us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. graciously hear us, O Lord.
Lamb of God, Who takest away the sins of the world, ℟. have mercy on us.

℣. Pray for us, O holy Mother of God,
℟. That we may be made worthy of the promises of Christ.

[Let us pray.]

Grant, we beseech Thee, O Lord God, unto us Thy servants, that we may rejoice in continual health of mind and body, and by the glorious intercession of Blessed Mary, ever virgin, may be delivered from present sadness, and enter into the joy of Thine eternal gladness. Through Christ Our Lord.

℟. Amen.
""",
        latinContent: """
Kýrie, eléison.
Christe, eléison.
Kýrie, eléison.
Christe, audi nos. ℟. Christe, exáudi nos.

Pater de cælis, Deus, ℟. miserére nobis.
Fili, Redémptor mundi, Deus,
Spíritus Sancte, Deus,
Sancta Trínitas, unus Deus,

Sancta María, ℟. ora pro nobis.
Sancta Dei Génetrix,
Sancta Virgo vírginum,

Mater Christi, ℟. ora pro nobis.
Mater divínæ grátiæ,
Mater puríssima,
Mater castíssima,
Mater invioláta,
Mater intemeráta,
Mater amábilis,
Mater admirábilis,
Mater boni consílii,
Mater Creatóris,
Mater Salvatóris,
Mater Ecclésiæ,

Virgo prudentíssima, ℟. ora pro nobis.
Virgo veneránda,
Virgo prædicánda,
Virgo potens,
Virgo clemens,
Virgo fidélis,

Spéculum justítiæ, ℟. ora pro nobis.
Sedes sapiéntiæ,
Causa nostræ lætítiæ,
Vas spirituále,
Vas honorábile,
Vas insígne devotiónis,
Rosa mýstica,
Turris Davídica,
Turris ebúrnea,
Domus áurea,
Fœderis arca,
Jánua cæli,
Stella matutína,

Salus infirmórum, ℟. ora pro nobis.
Refúgium peccatórum,
Consolátrix afflictórum,
Auxílium Christianórum,

Regína Angelórum, ℟. ora pro nobis.
Regína Patriarchárum,
Regína Prophetárum,
Regína Apostolórum,
Regína Mártyrum,
Regína Confessórum,
Regína Vírginum,
Regína Sanctórum ómnium,
Regína sine labe origináli concépta,
Regína in cælum assúmpta,
Regína sacratíssimi Rosárii,
Regína pacis,

Agnus Dei, qui tollis peccáta mundi, ℟. parce nobis, Dómine.
Agnus Dei, qui tollis peccáta mundi, ℟. exáudi nos, Dómine.
Agnus Dei, qui tollis peccáta mundi, ℟. miserére nobis.

℣. Ora pro nobis, sancta Dei Génetrix.
℟. Ut digni efficiámur promissiónibus Christi.

[Orémus.]

Concéde nos fámulos tuos, quæsumus, Dómine Deus, perpétua mentis et córporis sanitáte gaudére: et gloriósa beátæ Maríæ semper Vírginis intercessióne, a præsénti liberári tristítia, et ætérna pérfrui lætítia. Per Christum Dóminum nostrum.

℟. Amen.
"""
    )

    static let litanyOfTheHolyName = BilingualConsecrationPrayer(
        id: "litany_holy_name",
        englishTitle: "Litany of the Holy Name of Jesus",
        latinTitle: "Litaniæ Sanctíssimi Nóminis Jesu",
        englishContent: """
Lord, have mercy on us.
Christ, have mercy on us.
Lord, have mercy on us.
Jesus, hear us. ℟. Jesus, graciously hear us.

God the Father of Heaven, ℟. have mercy on us.
God the Son, Redeemer of the world,
God the Holy Ghost,
Holy Trinity, One God,

Jesus, Son of the living God, ℟. have mercy on us.
Jesus, splendor of the Father,
Jesus, brightness of eternal light,
Jesus, King of glory,
Jesus, sun of justice,
Jesus, Son of the Virgin Mary,

Jesus, most amiable, ℟. have mercy on us.
Jesus, most admirable,
Jesus, mighty God,
Jesus, Father of the world to come,
Jesus, angel of great counsel,
Jesus, most powerful,
Jesus, most patient,
Jesus, most obedient,
Jesus, meek and humble of heart,

Jesus, lover of chastity, ℟. have mercy on us.
Jesus, lover of us,
Jesus, God of peace,
Jesus, author of life,
Jesus, model of virtues,
Jesus, lover of souls,
Jesus, our God,

Jesus, our refuge, ℟. have mercy on us.
Jesus, Father of the poor,
Jesus, treasure of the faithful,
Jesus, Good Shepherd,
Jesus, true light,
Jesus, eternal wisdom,
Jesus, infinite goodness,
Jesus, our way and our life,

Jesus, joy of angels, ℟. have mercy on us.
Jesus, King of patriarchs,
Jesus, master of Apostles,
Jesus, teacher of Evangelists,
Jesus, strength of martyrs,
Jesus, light of confessors,
Jesus, purity of virgins,
Jesus, crown of all saints,

Be merciful, ℟. spare us, O Jesus.
Be merciful, ℟. graciously hear us, O Jesus.

From all evil, ℟. Jesus, deliver us.
From all sin,
From Thy wrath,
From the snares of the devil,
From the spirit of fornication,
From everlasting death,
From the neglect of Thine inspirations,

Through the mystery of Thy holy Incarnation, ℟. Jesus, deliver us.
Through Thy nativity,
Through Thine infancy,
Through Thy most divine life,
Through Thy labors,
Through Thine agony and Passion,
Through Thy cross and dereliction,
Through Thy sufferings,
Through Thy death and burial,
Through Thy Resurrection,
Through Thine Ascension,
Through Thine institution of the most Holy Eucharist,
Through Thy joys,
Through Thy glory,

Lamb of God, Who takest away the sins of the world, ℟. spare us, O Jesus.
Lamb of God, Who takest away the sins of the world, ℟. graciously hear us, O Jesus.
Lamb of God, Who takest away the sins of the world, ℟. have mercy on us, O Jesus.

Jesus, hear us. ℟. Jesus, graciously hear us.

[Let us pray.]

O Lord Jesus Christ, Who hast said: Ask and ye shall receive, seek and ye shall find, knock and it shall be opened unto you; grant, we beseech Thee, to us who ask the gift of Thy divine love, that we may ever love Thee with all our hearts, and in all our words and actions, and never cease from praising Thee.

Give us, O Lord, a perpetual fear and love of Thy holy Name; for Thou never failest to govern those whom Thou dost solidly establish in Thy love, Who livest and reignest world without end.

℟. Amen.
""",
        latinContent: """
Kýrie, eléison.
Christe, eléison.
Kýrie, eléison.
Jesu, audi nos. ℟. Jesu, exáudi nos.

Pater de cælis, Deus, ℟. miserére nobis.
Fili, Redémptor mundi, Deus,
Spíritus Sancte, Deus,
Sancta Trínitas, unus Deus,

Jesu, Fili Dei vivi, ℟. miserére nobis.
Jesu, splendor Patris,
Jesu, candor lucis ætérnæ,
Jesu, Rex glóriæ,
Jesu, sol justítiæ,
Jesu, Fili Maríæ Vírginis,

Jesu amábilis, ℟. miserére nobis.
Jesu admirábilis,
Jesu, Deus fortis,
Jesu, Pater futúri sæculi,
Jesu, magni consílii Ángele,
Jesu potentíssime,
Jesu patientíssime,
Jesu obedientíssime,
Jesu, mitis et húmilis corde,

Jesu, amátor castitátis, ℟. miserére nobis.
Jesu, amátor noster,
Jesu, Deus pacis,
Jesu, auctor vitæ,
Jesu, exémplar virtútum,
Jesu, zelátor animárum,
Jesu, Deus noster,

Jesu, refúgium nostrum, ℟. miserére nobis.
Jesu, pater páuperum,
Jesu, thesáurus fidélium,
Jesu, bone pastor,
Jesu, lux vera,
Jesu, sapiéntia ætérna,
Jesu, bónitas infiníta,
Jesu, via et vita nostra,

Jesu, gáudium Angelórum, ℟. miserére nobis.
Jesu, Rex Patriarchárum,
Jesu, Magíster Apostolórum,
Jesu, Doctor Evangelistárum,
Jesu, fortitúdo Mártyrum,
Jesu, lumen Confessórum,
Jesu, púritas Vírginum,
Jesu, coróna Sanctórum ómnium,

Propítius esto, ℟. parce nobis, Jesu.
Propítius esto, ℟. exáudi nos, Jesu.

Ab omni malo, ℟. líbera nos, Jesu.
Ab omni peccáto,
Ab ira tua,
Ab insídiis diáboli,
A spíritu fornicatiónis,
A morte perpétua,
A negléctu inspiratiónum tuárum,

Per mystérium sanctæ Incarnatiónis tuæ, ℟. líbera nos, Jesu.
Per nativitátem tuam,
Per infántiam tuam,
Per diviníssimam vitam tuam,
Per labóres tuos,
Per agoníam et passiónem tuam,
Per crucem et derelictiónem tuam,
Per languóres tuos,
Per mortem et sepultúram tuam,
Per resurrectiónem tuam,
Per ascensiónem tuam,
Per sanctíssimæ Eucharistíæ institutiónem tuam,
Per gáudia tua,
Per glóriam tuam,

Agnus Dei, qui tollis peccáta mundi, ℟. parce nobis, Jesu.
Agnus Dei, qui tollis peccáta mundi, ℟. exáudi nos, Jesu.
Agnus Dei, qui tollis peccáta mundi, ℟. miserére nobis, Jesu.

Jesu, audi nos. ℟. Jesu, exáudi nos.

[Orémus.]

Dómine Jesu Christe, qui dixísti: Pétite et accipiétis; quǽrite et inveniétis; pulsáte et aperiétur vobis: quæsumus, da nobis peténtibus diviníssimi tui amóris afféctum, ut te toto corde, ore et ópere diligámus, et a tua numquam laude cessémus.

Sancti Nóminis tui, Dómine, timórem páriter et amórem fac nos habére perpétuum: quia numquam tua gubernatióne destítuis, quos in soliditáte tuæ dilectiónis instítuis. Qui vivis et regnas in sæcula sæculórum.

℟. Amen.
"""
    )

    // MARK: - Prayer of Consecration

    static let oJesusLivingInMary = BilingualConsecrationPrayer(
        id: "o_jesus_living_in_mary",
        englishTitle: "O Jesus Living in Mary",
        latinTitle: "O Jesu Vivens in Maria",
        englishContent: """
O Jesus living in Mary,
come and live in Thy servants,
in the spirit of Thy holiness,
in the fullness of Thy might,
in the truth of Thy virtues,
in the perfection of Thy ways,
in the communion of Thy mysteries.
Subdue every hostile power
in Thy Spirit, for the glory of the Father. Amen.
""",
        latinContent: """
O Jesu vivens in María,
veni et vive in fámulis tuis,
in spíritu sanctitátis tuæ,
in plenitúdine virtútis tuæ,
in veritáte virtútum tuárum,
in perfectióne viárum tuárum,
in communióne mysteriórum tuórum.
Domináre omni advérsæ potestáti,
in Spíritu tuo, ad glóriam Patris. Amen.
"""
    )
}
