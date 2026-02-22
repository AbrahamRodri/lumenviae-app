//
//  TrueDevotionPrayers.swift
//  Lumen Viae
//
//  ═══════════════════════════════════════════════════════════════════════════
//  TRUE DEVOTION - EJACULATORY PRAYERS
//  ═══════════════════════════════════════════════════════════════════════════
//
//  Ejaculatory prayers from True Devotion to Mary, stored efficiently with
//  bilingual support. Each prayer is defined once with both English and Latin,
//  then formatted dynamically based on user preference.
//
//  ═══════════════════════════════════════════════════════════════════════════

import Foundation
import SwiftUI

// MARK: - True Devotion Prayers

enum TrueDevotionPrayers {

    /// All ejaculatory prayers from True Devotion to Mary
    static let prayers = BilingualSection(
        title: "Ejaculatory Prayers",
        icon: "flame.fill",
        items: [
            BilingualPrayer(
                title: "The Little Crown",
                content: BilingualText(
                    english: """
V. Grant me to praise thee, O Sacred Virgin.
R. Give me strength against thine enemies.
""",
                    latin: """
V. Dignare me laudare te, Virgo sacrata.
R. Da mihi virtutem contra hostes tuos.
"""
                )
            ),
            BilingualPrayer(
                title: "Totus Tuus",
                content: BilingualText(
                    english: "I am all Yours, and all that I have is Yours, O most loving Jesus, through Mary, Your most holy Mother.",
                    latin: "Totus Tuus ego sum, et omnia mea Tua sunt, O amantissime Jesu, per Mariam, Matrem Tuam sanctissimam."
                )
            ),
            BilingualPrayer(
                title: "O Jesus Living in Mary",
                content: BilingualText(
                    english: """
O Jesus living in Mary,
Come and live in Thy servants,
In the spirit of Thy holiness,
In the fullness of Thy might,
In the truth of Thy virtues,
In the perfection of Thy ways,
In the communion of Thy mysteries;
Subdue every hostile power
In Thy spirit, for the glory of the Father.
Amen.
""",
                    latin: """
O Jesu vivens in Maria,
Veni et vive in famulis tuis,
In spiritu sanctitatis tuae,
In plenitudine virtutis tuae,
In veritate virtutum tuarum,
In perfectione viarum tuarum,
In communione mysteriorum tuorum;
Domina omnem adversam potestatem
In Spiritu tuo, ad gloriam Patris.
Amen.
"""
                )
            ),
            BilingualPrayer(
                title: "Short Aspiration",
                content: BilingualText(
                    english: "Mary, my Mother and my Queen, I am all thine, and all that I have is thine.",
                    latin: "Maria, Mater mea et Regina mea, tota Tua sum, et omnia mea Tua sunt."
                )
            ),
            BilingualPrayer(
                title: "Morning Offering Through Mary",
                content: BilingualText(
                    english: "O Mary, I give thee my heart; form in it the heart of Jesus.",
                    latin: "O Maria, do tibi cor meum; forma in eo cor Jesu."
                )
            ),
            BilingualPrayer(
                title: "In Temptation",
                content: BilingualText(
                    english: """
O Mary, conceived without sin, pray for us who have recourse to thee.

My Mother, my confidence!
""",
                    latin: """
O Maria, sine labe concepta, ora pro nobis qui confugimus ad te.

Mater mea, fiducia mea!
"""
                )
            ),
            BilingualPrayer(
                title: "Throughout the Day",
                content: BilingualText(
                    english: """
All for thee, most Sacred Heart of Jesus, through the Immaculate Heart of Mary.

Jesus, Mary, Joseph, I love you; save souls!
""",
                    latin: """
Omnia pro te, Cor Jesu sacratissimum, per Cor Mariae Immaculatum.

Jesu, Maria, Joseph, vos amo; salvate animas!
"""
                )
            ),
            BilingualPrayer(
                title: "The Memorare (St. Bernard)",
                content: BilingualText(
                    english: "Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided.",
                    latin: "Memorare, O piissima Virgo Maria, non esse auditum a saeculo, quemquam ad tua currentem praesidia, tua implorantem auxilia, tua petentem suffragia, esse derelictum."
                )
            ),
            BilingualPrayer(
                title: "Before Holy Communion",
                content: BilingualText(
                    english: "O Mary, Mother of Jesus, make my heart like unto thine, that I may worthily receive thy Divine Son.",
                    latin: "O Maria, Mater Jesu, fac cor meum simile Tuo, ut digne recipiam Filium Tuum divinum."
                )
            ),
            BilingualPrayer(
                title: "During the Rosary",
                content: BilingualText(
                    english: "Hail Mary, Daughter of God the Father; Hail Mary, Mother of God the Son; Hail Mary, Spouse of God the Holy Spirit; Hail Mary, Temple of the Most Blessed Trinity.",
                    latin: "Ave Maria, Filia Dei Patris; Ave Maria, Mater Dei Filii; Ave Maria, Sponsa Spiritus Sancti; Ave Maria, Templum Sanctissimae Trinitatis."
                )
            )
        ]
    )
}
