//
//  PrayerBookSaints4.swift
//  Lumen Viae
//
//  St Gertrude's offering for the holy souls, the St Benedict Medal's verses, and the antiphon to St Dominic.
//  Sources: St Gertrude: the offering attributed to St Gertrude the Great (13th century), as printed in older Catholic manuals; English: our own literal rendering.
//  St Benedict Medal: the Latin verses as struck on the medal (the Metten manuscript, 1415); English: our own literal rendering from the Latin.
//  O lumen Ecclesiæ: the Dominican Breviary's antiphon (Breviarium Ordinis Prædicatorum); English: our own literal rendering from the Latin.
//

import Foundation

extension PrayerBookTexts {

    static let saints4: [BookPrayer] = [
        BookPrayer(
            id: "st_gertrude",
            title: "St Gertrude's Offering for the Holy Souls",
            latinTitle: nil,
            origin: "Attributed to St Gertrude the Great · 13th century",
            note: "An offering of the Precious Blood for the souls in purgatory, said at any time and especially in November.",
            english: """
Eternal Father, I offer Thee the most Precious Blood of Thy Divine Son Jesus, together with all the Masses offered this day throughout the world, for all the holy souls in purgatory, for sinners in every place, for sinners in the universal Church, and for those of my own home and my own family. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_benedict_medal",
            title: "The Verses of the St Benedict Medal",
            latinTitle: "Crux sacra sit mihi lux",
            origin: "The St Benedict Medal · 15th century",
            note: "The verses whose first letters are struck round the cross on the St Benedict Medal, said against temptation and every evil.",
            english: """
May the holy Cross be my light;
let not the dragon be my guide.

Begone, Satan;
never counsel me to vanities.
Evil is the cup thou offerest;
drink thou thine own poison.
""",
            latin: """
Crux sacra sit mihi lux,
non draco sit mihi dux.

Vade retro, Satana,
numquam suade mihi vana.
Sunt mala quæ libas,
ipse venena bibas.
"""
        ),
        BookPrayer(
            id: "st_dominic_o_lumen",
            title: "O Light of the Church",
            latinTitle: "O lumen Ecclesiæ",
            origin: "The Dominican Breviary · 13th century",
            note: "The antiphon the Order of Preachers sings to St Dominic, its founder, at the close of Compline.",
            english: """
O light of the Church,
teacher of the truth,
rose of patience,
ivory of chastity,
the water of wisdom
thou hast poured freely;
preacher of grace,
join us to the blessed.
""",
            latin: """
O lumen Ecclésiæ,
doctor veritátis,
rosa patiéntiæ,
ebur castitátis,
aquam sapiéntiæ
propinásti grátis,
prædicátor grátiæ,
nos iunge beátis.
"""
        ),
    ]
}
