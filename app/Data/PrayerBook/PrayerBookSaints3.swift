//
//  PrayerBookSaints3.swift
//  Lumen Viae
//
//  Prayers to four saints much asked for help: St Anthony, St Jude, St Peregrine and St Anne.
//  Sources: English: our own renderings, in the book's register, of the traditional prayers
//  in their sense; no printed translation is reproduced.
//  St Anthony: rendered in sense from the traditional prayer to the Wonder-worker of Padua.
//  St Jude: rendered in sense from the traditional prayer to St Jude, Apostle and Martyr.
//  St Peregrine: rendered in sense from the traditional Servite prayer to St Peregrine Laziosi.
//  St Anne: rendered in sense from the Raccolta's (1910) prayers to St Anne.
//

import Foundation

extension PrayerBookTexts {

    static let saints3: [BookPrayer] = [
        BookPrayer(
            id: "st_anthony",
            title: "Prayer to St Anthony",
            latinTitle: nil,
            origin: "A traditional prayer · St Anthony of Padua, d. 1231",
            note: "Said to the Wonder-worker of Padua in any need, and above all for something lost.",
            english: """
O holy St Anthony, gentlest of saints, for the love thou didst bear to God and the charity thou didst show His creatures, thou wast given on earth the power to work wonders. Thy word was ready for all who came to thee in sorrow or in need, and the Lord answered it.

Trusting in this, I come to thee and beg thee to obtain for me what I ask.

[Here name the favour asked.]

If what I seek should need a miracle, thou art the saint of miracles.

O kind and loving St Anthony, whose heart was ever tender to men, speak my request to the Child Jesus, whom thou didst hold in thine arms, and my thanks shall be thine for ever. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_jude",
            title: "Prayer to St Jude",
            latinTitle: nil,
            origin: "A traditional prayer · St Jude Thaddeus, Apostle",
            note: "Said to the Apostle Jude, patron of things despaired of, when every other help seems gone.",
            english: """
O holy St Jude, Apostle and Martyr, kinsman of our Lord, great in virtue and rich in miracles, faithful helper of all who call on thee in need: to thee I come from the depth of my heart, and humbly ask thee, to whom God has given so great a power, to come to my aid.

Help me now in my present and urgent trouble.

[Here name the need.]

In return I promise to make thy name known, and to have thee honoured and invoked. Pray for me, that I may never lose hope. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_peregrine",
            title: "Prayer to St Peregrine",
            latinTitle: nil,
            origin: "A traditional Servite prayer · St Peregrine Laziosi, d. 1345",
            note: "Said for those who suffer from cancer or any grave illness, through the Servite friar whose own leg was healed before the Crucifix.",
            english: """
O glorious St Peregrine, who didst answer the call of Mary and leave the world to serve her Son in the Order of her Servants; who didst bear in patience a painful sickness, and wast healed by the hand of Christ reaching down from the Cross: look with pity on all who suffer.

Obtain for me, if it be God's will, relief from this illness, and grace to bear what I must bear with patience and with trust.

[Here name the one who is sick.]

Pray for us, that in health and in sickness we may love God, and at the last come to praise Him with thee for ever. Amen.
""",
            latin: nil
        ),
        BookPrayer(
            id: "st_anne",
            title: "Prayer to St Anne",
            latinTitle: nil,
            origin: "After the Raccolta · 1910",
            note: "Said to the mother of the Blessed Virgin, above all by mothers and grandmothers, and on her feast on July 26.",
            english: """
O good St Anne, mother of the Virgin Mary and grandmother of our Saviour, God chose thee to bring into the world her who was to be the Mother of His Son. Full of trust, I turn to thee and put myself under thy care.

Take my family into thy keeping. Teach us to love Jesus and Mary as thou didst love them, and obtain for us the grace we ask of thee now.

[Here name the favour asked.]

Be with us in life, and at the hour of death bring us to Jesus and Mary, that with thee we may praise God for ever. Amen.
""",
            latin: nil
        ),
    ]
}
