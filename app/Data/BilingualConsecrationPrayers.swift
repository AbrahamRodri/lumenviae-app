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
Come, Holy Spirit, Creator blest,
and in our souls take up Thy rest;
come with Thy grace and heavenly aid
to fill the hearts which Thou hast made.
O comforter, to Thee we cry,
O heavenly gift of God Most High,
O fount of life and fire of love,
and sweet anointing from above.
Kindle our senses from above,
and make our hearts o'erflow with love;
with patience firm and virtue high
the weakness of our flesh supply.
Oh, may Thy grace on us bestow
the Father and the Son to know;
and Thee, through endless times confessed,
of both the eternal Spirit blest.
Amen.
""",
        latinContent: """
Veni, Creator Spiritus,
mentes tuorum visita,
imple superna gratia
quae tu creasti pectora.
Qui diceris Paraclitus,
altissimi donum Dei,
fons vivus, ignis, caritas,
et spiritalis unctio.
Accende lumen sensibus,
infunde amorem cordibus,
infirma nostri corporis
virtute firmans perpeti.
Da tuis fidelibus,
in te confidentibus,
sacrum septenarium,
da virtutum omnium.
Amen.
"""
    )

    static let aveMaris = BilingualConsecrationPrayer(
        id: "ave_maris_stella",
        englishTitle: "Hail, Star of the Sea",
        latinTitle: "Ave Maris Stella",
        englishContent: """
Hail, O Star of the ocean,
God's own Mother blest,
ever sinless Virgin,
gate of heav'nly rest.
Show thyself a Mother,
may the Word divine
born for us thine Infant
hear our prayers through thine.
Keep our life all spotless,
make our way secure
till we find in Jesus,
joy for evermore.
Amen.
""",
        latinContent: """
Ave, maris stella,
Dei Mater alma,
atque semper Virgo,
felix caeli porta.
Monstra te esse matrem,
sumat per te preces
qui pro nobis natus
tulit esse tuus.
Vitam praesta puram,
iter para tutum,
ut videntes Jesum
semper collaetemur.
Amen.
"""
    )

    static let magnificat = BilingualConsecrationPrayer(
        id: "magnificat",
        englishTitle: "The Canticle of Mary",
        latinTitle: "Magnificat",
        englishContent: """
My soul doth magnify the Lord.

And my spirit hath rejoiced in God my Savior.

Because He hath regarded the humility of his handmaid.

Because He that is mighty hath done great things to me.

And holy is His name.

Glory be to the Father, and to the Son, and to the Holy Spirit.

As it was in the beginning, is now, and ever shall be, world without end.

Amen.
""",
        latinContent: """
Magnificat anima mea Dominum.

Et exsultavit spiritus meus in Deo salutari meo.

Quia respexit humilitatem ancillae suae.

Quia fecit mihi magna qui potens est.

Et sanctum nomen eius.

Gloria Patri, et Filio, et Spiritui Sancto.

Sicut erat in principio, et nunc, et semper, et in saecula saeculorum.

Amen.
"""
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
