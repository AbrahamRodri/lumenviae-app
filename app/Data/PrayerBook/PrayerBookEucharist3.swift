//
//  PrayerBookEucharist3.swift
//  Lumen Viae
//
//  Prayers to the Holy Spirit.
//  Sources: Breathe in me: attributed to St Augustine (English our own literal rendering of the traditional prayer)
//  The Seven Gifts: the traditional prayer of the manuals (English our own literal rendering)
//  Cardinal Désiré-Joseph Mercier, "Le secret de la sainteté" (English: our own literal rendering from the French of Cardinal Mercier)
//

import Foundation

extension PrayerBookTexts {

    static let eucharist3: [BookPrayer] = [
        BookPrayer(
            id: "breathe_in_me",
            title: "Breathe in Me, O Holy Spirit",
            latinTitle: nil,
            origin: "Attributed to St Augustine",
            note: "A prayer to the Holy Spirit for holiness of thought, work, love and life.",
            english: """
Breathe within me, O Holy Spirit, that all my thoughts may be holy.
Move within me, O Holy Spirit, that my works too may be holy.
Draw my heart, O Holy Spirit, that I may love nothing but what is holy.
Make me strong, O Holy Spirit, to stand for all that is holy.
Keep me, O Holy Spirit, that I may be holy for ever. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "seven_gifts",
            title: "Prayer for the Seven Gifts of the Holy Spirit",
            latinTitle: nil,
            origin: "Traditional · the prayer manuals",
            note: "Asks for the seven gifts named in Isaias 11:2–3, often said in preparation for Confirmation and at Pentecost.",
            english: """
O Lord Jesus Christ, Who before Thou didst ascend into heaven didst promise to send the Holy Spirit to finish Thy work in the souls of Thy disciples, grant that the same Holy Spirit may perfect in me the work of Thy grace and Thy love.

Grant me the Spirit of Wisdom, that I may despise the passing things of this world and long only for the things that are eternal;
the Spirit of Understanding, to enlighten my mind with the light of Thy truth;
the Spirit of Counsel, that I may choose always the surest way of pleasing Thee;
the Spirit of Fortitude, that I may bear my cross with Thee and overcome every hindrance to my salvation;
the Spirit of Knowledge, that I may know Thee and know myself;
the Spirit of Piety, that I may find Thy service sweet;
and the Spirit of Fear, that I may be filled with loving reverence for Thee and dread above all to displease Thee.

Mark me, dear Lord, with the sign of Thy true disciples, and fill me in all things with Thy Spirit. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "secret_of_sanctity",
            title: "The Secret of Sanctity",
            latinTitle: nil,
            origin: "Cardinal Désiré-Joseph Mercier · early 20th century",
            note: "Cardinal Mercier counselled saying it for five minutes each day, in silence, as the secret of a holy and peaceful life.",
            english: """
O Holy Spirit, soul of my soul, I adore Thee.
Enlighten me, guide me, strengthen me, console me.
Tell me what I ought to do; give me Thy commands.
I promise to submit myself to all that Thou desirest of me, and to accept all that Thou permittest to befall me: only make known to me Thy will. Amen.
""",
            latin: nil
        ),
    ]
}
