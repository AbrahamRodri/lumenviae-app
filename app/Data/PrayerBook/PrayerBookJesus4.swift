//
//  PrayerBookJesus4.swift
//  Lumen Viae
//
//  The Chaplet of Divine Mercy, the Efficacious Novena to the Sacred
//  Heart, and the prayer to the Infant Jesus of Prague.
//  Sources: St Faustina Kowalska, Dzienniczek (Diary) 476, the Polish; English: our own literal rendering from the Polish of the Dzienniczek
//           The Efficacious Novena to the Sacred Heart, after St Margaret Mary, as said daily by St Padre Pio; Gospel words from the Douay-Rheims (Mt 7:7, Jn 16:23, Mt 24:35); English otherwise our own literal rendering of the traditional prayer
//           The prayer of Ven. Fr Cyril of the Mother of God (c. 1637); original not found; English: our own plain rendering of its sense as the 19th-century English manuals hand it down
//

import Foundation

extension PrayerBookTexts {

    static let jesus4: [BookPrayer] = [
        BookPrayer(
            id: "divine_mercy_chaplet",
            title: "The Chaplet of Divine Mercy",
            latinTitle: nil,
            origin: "St Faustina Kowalska · 1935",
            note: "Said on the beads of the Rosary, above all at three in the afternoon, the hour of Our Lord's death.",
            english: """
[Begin with the Sign of the Cross, the Our Father, the Hail Mary and the Apostles' Creed.]

[On each large bead:]
Eternal Father, I offer Thee the Body and Blood, Soul and Divinity of Thy dearest Son, our Lord Jesus Christ, in atonement for our sins and for those of the whole world.

[On each of the ten small beads:]
For the sake of His sorrowful Passion, have mercy on us and on the whole world.

[After the five decades, three times:]
Holy God, Holy Mighty One, Holy Immortal One, have mercy on us and on the whole world.
""",
            latin: nil
        ),
        BookPrayer(
            id: "efficacious_novena",
            title: "The Efficacious Novena to the Sacred Heart",
            latinTitle: nil,
            origin: "After St Margaret Mary Alacoque · said daily by St Padre Pio",
            note: "Said on nine days together for a grace much needed, resting each petition on a promise Our Lord made in the Gospel.",
            english: """
O my Jesus, Thou hast said: "Ask, and it shall be given you: seek, and you shall find: knock, and it shall be opened to you." Behold, I knock, I seek, I ask for the grace of [name the grace].

[Our Father, Hail Mary, Glory Be.]

Sacred Heart of Jesus, I place all my trust in Thee.

O my Jesus, Thou hast said: "Amen, amen I say to you: if you ask the Father any thing in my name, he will give it you." Behold, in Thy name I ask the Father for the grace of [name the grace].

[Our Father, Hail Mary, Glory Be.]

Sacred Heart of Jesus, I place all my trust in Thee.

O my Jesus, Thou hast said: "Heaven and earth shall pass, but my words shall not pass." Leaning on the infallibility of Thy holy words, I ask for the grace of [name the grace].

[Our Father, Hail Mary, Glory Be.]

Sacred Heart of Jesus, I place all my trust in Thee.

O Sacred Heart of Jesus, for whom it is impossible not to have compassion on the afflicted, have pity on us poor sinners, and grant us the grace which we ask of Thee, through the Sorrowful and Immaculate Heart of Mary, Thy tender Mother and ours.

[Hail, Holy Queen.]

St Joseph, foster father of Jesus, pray for us.
""",
            latin: nil
        ),
        BookPrayer(
            id: "infant_of_prague",
            title: "Prayer to the Infant Jesus of Prague",
            latinTitle: nil,
            origin: "Ven. Fr Cyril of the Mother of God · c. 1637",
            note: "Said before the image of the Child Jesus of Prague, in any need, and by many on the twenty-fifth of each month, in memory of His birth.",
            english: """
O Jesus, I flee to Thee, and through Thy Mother I pray Thee to help me in my need. For I firmly believe that Thy divinity can help me. I hope with confidence to obtain Thy holy grace. I love Thee with all my heart and all my soul. I am heartily sorry for my sins, and I beg Thee, O good Jesus, to give me strength to overcome them. I purpose never more to offend Thee, and I offer myself to Thee, to suffer all things patiently for Thee, to serve Thee faithfully, and to love my neighbour as myself for love of Thee.

O almighty Child Jesus, I implore Thee once more: help me in this need [name the need], that with Mary and Joseph I may possess Thee for ever, and with the holy angels adore Thee in heaven. Amen.
""",
            latin: nil
        ),
    ]
}
