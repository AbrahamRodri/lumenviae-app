//
//  BilingualConsecrationPrayers.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  BILINGUAL CONSECRATION PRAYERS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Consecration prayers stored efficiently with bilingual support.
//  Each prayer is defined once with both English and Latin versions.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftUI

// MARK: - Bilingual Consecration Prayers

enum BilingualConsecrationPrayers {

    /// Get all bilingual consecration prayers
    static func allPrayers() -> [String: BilingualConsecrationPrayer] {
        [
            "veni_creator": veniCreator,
            "ave_maris_stella": aveMaris,
            "magnificat": magnificat,
            "glory_be": gloryBe
        ]
    }

    // MARK: - Individual Prayers

    static let veniCreator = BilingualConsecrationPrayer(
        id: "veni_creator",
        englishTitle: "Come, Creator Spirit",
        latinTitle: "Veni Creator Spiritus",
        englishContent: """
COME, Holy Spirit, Creator blest,
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
""",
        latinContent: """
VENI, Creator Spiritus,
mentes tuorum visita,
imple superna gratia
quae tu creasti pectora.

Qui diceris Paraclitus,
altissimi donum Dei,
fons vivus, ignis, caritas,
et spiritalis unctio.

Tu, septiformis munere,
digitus paternae dexterae,
Tu rite promissum Patris,
sermone ditans guttura.

Accende lumen sensibus:
infunde amorem cordibus:
infirma nostri corporis
virtute firmans perpeti.

Hostem repellas longius,
pacemque dones protinus:
ductore sic te praevio
vitemus omne noxium.

Per te sciamus da Patrem,
noscamus atque Filium;
Teque utriusque Spiritum
credamus omni tempore.

Deo Patri sit gloria,
et Filio, qui a mortuis
surrexit, ac Paraclito,
in saeculorum saecula.

Amen.
""",
        hasChantAudio: true
    )

    static let aveMaris = BilingualConsecrationPrayer(
        id: "ave_maris_stella",
        englishTitle: "Hail, Star of the Sea",
        latinTitle: "Ave Maris Stella",
        englishContent: """
HAIL, O Star of the ocean,
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
""",
        latinContent: """
Ave, maris stella,
Dei Mater alma,
atque semper Virgo,
felix caeli porta.

Sumens illud Ave
Gabrielis ore,
funda nos in pace,
mutans Hevae nomen.

Solve vincula reis,
profer lumen caecis
mala nostra pelle,
bona cuncta posce.

Monstra te esse matrem,
sumat per te preces
qui pro nobis natus
tulit esse tuus.

Virgo singularis,
inter omnes mitis,
nos culpis solutos,
mites fac et castos.

Vitam praesta puram,
iter para tutum:
ut videntes Iesum
semper collaetemur.

Sit laus Deo Patri,
summo Christo decus,
Spiritui Sancto,
tribus honor unus. 

Amen.
""",
        hasChantAudio: true
    )

    static let magnificat = BilingualConsecrationPrayer(
        id: "magnificat",
        englishTitle: "The Canticle of Mary",
        latinTitle: "Magnificat",
        englishContent: """
My soul doth magnify the Lord.

And my spirit hath rejoiced in God my Savior.

Because He hath regarded the humility of his handmaid:

For behold from henceforth all generations shall call me blessed.

Because He that is mighty hath done great things to me.

And holy is His name.

And His mercy is from generation unto generations, to them that fear Him.

He hath shewed might in His arm: He hath scattered the proud in the conceit of their heart.

He hath put down the mighty from their seat, and hath exalted the humble.

He hath filled the hungry with good things; and the rich He hath sent empty away.

He hath received Israel His servant, being mindful of His mercy:

As He spoke to our fathers, to Abraham and to his seed for ever.

Glory be to the Father, and to the Son, and to the Holy Spirit.

As it was in the beginning, is now, and ever shall be, world without end.

Amen.
""",
        latinContent: """
Magnificat anima mea Dominum.

Et exsultavit spiritus meus in Deo salutari meo.

Quia respexit humilitatem ancillae suae:

Ecce enim ex hoc beátam me dicent omnes generatiónes.

Quia fecit mihi magna qui potens est:

Et sanctum nomen eius.

Et misericórdia eius in progénies et progénies timéntibus eum.

Fécit poténtiam in bráchio suo: dispérsit supérbos mente cordis sui

Depósuit poténtes de sede: et exaltávit húmiles.

Esuriéntes implévit bonis: et dívites dimísit inánes.

Suscépit Ísrael púerum suum: recordátus misericórdiae suae.

Sicut locútus est ad patres nostros: Ábraham, et sémini eius in saecula.

Gloria Patri, et Filio, et Spiritui Sancto.

Sicut erat in principio, et nunc, et semper, et in saecula saeculorum.

Amen.
""",
        hasChantAudio: true
    )

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
world without end.

Amen.
""",
        latinContent: """
Gloria Patri,
et Filio,
et Spiritui Sancto.
Sicut erat in principio,
et nunc, et semper,
et in saecula saeculorum.

Amen.
"""
    )
}
