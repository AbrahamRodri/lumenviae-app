//
//  PrayerBookOurLord1.swift
//  Lumen Viae
//
//  Short prayers to Our Lord and before the Blessed Sacrament.
//

import Foundation

extension PrayerBookTexts {

    static let ourLord1: [BookPrayer] = [
        BookPrayer(
            id: "jesus_prayer",
            title: "The Jesus Prayer",
            latinTitle: "Domine Iesu Christe, Fili Dei",
            origin: "The Desert Fathers · after Luke 18:13",
            note: "Said slowly and often through the day, in the words of the publican who stood afar off in the Temple.",
            english: """
Lord Jesus Christ, Son of God,
have mercy on me, a sinner.
""",
            latin: """
Domine Iesu Christe, Fili Dei,
miserere mei peccatoris.
"""
        ),
        BookPrayer(
            id: "o_sacrum_convivium",
            title: "O Sacred Banquet",
            latinTitle: "O sacrum convivium",
            origin: "St Thomas Aquinas · XIII century",
            note: "The antiphon at the Magnificat of Second Vespers of Corpus Christi, often sung at Benediction.",
            english: """
O sacred banquet,
in which Christ is received,
the memory of His Passion is renewed,
the mind is filled with grace,
and a pledge of future glory is given to us.
Alleluia.
""",
            latin: """
O sacrum convivium,
in quo Christus sumitur,
recolitur memoria passionis eius,
mens impletur gratia,
et futurae gloriae nobis pignus datur.
Alleluia.
"""
        ),
        BookPrayer(
            id: "st_richard",
            title: "Prayer of St Richard of Chichester",
            latinTitle: nil,
            origin: "St Richard of Chichester · XIII century",
            note: "The bishop's own prayer, which his confessor recorded him saying on his deathbed in 1253.",
            english: """
Thanks be to Thee, my Lord Jesus Christ, for all the benefits which Thou hast given me, for all the pains and insults which Thou hast borne for me. O most merciful Redeemer, Friend and Brother, may I know Thee more clearly, love Thee more dearly, and follow Thee more nearly, day by day. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "spiritual_communion",
            title: "Act of Spiritual Communion",
            latinTitle: nil,
            origin: "St Alphonsus Liguori · XVIII century",
            note: "Said by one who cannot receive Communion, at Mass or before the tabernacle, to receive Him in desire.",
            english: """
My Jesus, I believe that Thou art present in the Most Holy Sacrament. I love Thee above all things, and I desire to receive Thee into my soul. Since I cannot now receive Thee sacramentally, come at least spiritually into my heart. I embrace Thee as if Thou wert already there, and unite myself wholly to Thee. Never permit me to be separated from Thee. Amen.
""",
            latin: nil
        )
    ]
}
