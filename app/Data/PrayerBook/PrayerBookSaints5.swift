//
//  PrayerBookSaints5.swift
//  Lumen Viae
//
//  St Thomas Aquinas's prayer before study, and St Francis's prayer before the crucifix of San Damiano.
//  Sources: St Thomas Aquinas, "Creator ineffabilis" (Latin, as printed in the Roman Breviary's and Missal's
//  appendices of prayers and the Raccolta)
//  St Francis of Assisi, "Oratio ante crucifixum" (Latin, Opuscula S. P. Francisci, Quaracchi, 1904)
//  English: our own literal rendering from the Latin of St Thomas Aquinas and of St Francis
//

import Foundation

extension PrayerBookTexts {

    static let saints5: [BookPrayer] = [
        BookPrayer(
            id: "aquinas_before_study",
            title: "Prayer of St Thomas Aquinas before Study",
            latinTitle: "Creator ineffabilis",
            origin: "St Thomas Aquinas · 13th century",
            note: "Said before study, reading or any work of the mind, asking God for light to learn.",
            english: """
O Creator past all telling, who from the treasures of Thy wisdom didst appoint three hierarchies of Angels, and didst set them in wondrous order above the highest heaven, and didst dispose the parts of the universe most beautifully:

Thou, I say, who art called the true fount of light and wisdom, and the principle surpassing all, vouchsafe to pour upon the darkness of my understanding a ray of Thy brightness, taking from me the twofold darkness in which I was born, that is, sin and ignorance.

Thou who makest eloquent the tongues of little children, instruct my tongue, and pour upon my lips the grace of Thy blessing.

Give me keenness to understand, capacity to retain, method and ease in learning, subtlety to interpret, and abundant grace in speaking.

Order my beginning, direct my progress, and bring my ending to completion: Thou who art true God and man, who livest and reignest world without end. Amen.
""",
            latin: """
Creator ineffabilis, qui de thesauris sapientiae tuae tres Angelorum hierarchias designasti, et eas super caelum empyreum miro ordine collocasti, atque universi partes elegantissime distribuisti:

Tu, inquam, qui verus fons luminis et sapientiae diceris, ac supereminens principium, infundere digneris super intellectus mei tenebras tuae radium claritatis, duplices, in quibus natus sum, a me removens tenebras, peccatum scilicet et ignorantiam.

Tu, qui linguas infantium facis disertas, linguam meam erudias, atque in labiis meis gratiam tuae benedictionis infundas.

Da mihi intelligendi acumen, retinendi capacitatem, addiscendi modum et facilitatem, interpretandi subtilitatem, loquendi gratiam copiosam.

Ingressum instruas, progressum dirigas, egressum compleas: tu, qui es verus Deus et homo, qui vivis et regnas in saecula saeculorum. Amen.
"""
        ),
        BookPrayer(
            id: "st_francis_before_crucifix",
            title: "Prayer of St Francis before the Crucifix",
            latinTitle: "Summe, gloriose Deus",
            origin: "St Francis of Assisi · c. 1205",
            note: "Prayed by St Francis before the crucifix of San Damiano, and said before a crucifix to ask for light to know God's will.",
            english: """
Most high and glorious God,
enlighten the darkness of my heart,
and give me right faith, sure hope and perfect charity,
sense and knowledge, O Lord,
that I may fulfil Thy holy and true command. Amen.
""",
            latin: """
Summe, gloriose Deus,
illumina tenebras cordis mei,
et da mihi fidem rectam, spem certam et caritatem perfectam,
sensum et cognitionem, Domine,
ut faciam tuum sanctum et verax mandatum. Amen.
"""
        ),
    ]
}
